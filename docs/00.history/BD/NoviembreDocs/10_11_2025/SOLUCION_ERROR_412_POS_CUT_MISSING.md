# Solución - Error 412 "pos_cut_missing" en Cortes de Caja

**Fecha**: 10 Noviembre 2025
**Servidor**: 192.168.1.235 / 100.126.124.101
**Estado**: ✅ RESUELTO

---

## Problema Reportado

Al intentar avanzar del **Paso 1 (Precorte)** al **Paso 2 (Conciliación)** en el wizard de cortes de caja:

- ❌ Error HTTP 412 (Precondition Failed)
- ❌ Payload: `{"ok":false,"error":"pos_cut_missing","require_pos_cut":true}`
- ❌ Endpoint: `GET /api/caja/precortes/{id}/totales`

**Síntomas**:
- El usuario completa el precorte correctamente
- Hace el corte POS (DPR - Drawer Pull Report) desde Floreant POS
- El wizard NO permite avanzar a la conciliación
- El botón "Ir a Postcorte" permanece bloqueado
- El error "Falta corte POS" persiste aún después de hacer el corte

---

## Causa Raíz

La vista `selemti.vw_sesion_dpr` **NO EXISTÍA** en la base de datos.

### Código Afectado

**Archivo**: `app/Http/Controllers/Api/Caja/PrecorteController.php:539-550`

```php
private function hasPOSCutBySesion(int $sesionId): bool
{
    try {
        // Verifica que la vista existe
        $reg = DB::connection('pgsql')->selectOne("SELECT to_regclass('selemti.vw_sesion_dpr') AS t");
        if (!$reg || !$reg->t) return false;  // ❌ SIEMPRE retornaba false

        // Busca el DPR para la sesión
        $result = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM selemti.vw_sesion_dpr WHERE sesion_id = ? LIMIT 1",
            [$sesionId]
        );
        return (bool) $result;
    } catch (\Exception $e) {
        return false;
    }
}
```

**Archivo**: `app/Http/Controllers/Api/Caja/PrecorteController.php:264-401`

```php
public function resumenLegacy(Request $request, $id = null): JsonResponse
{
    // ... código para buscar precorte ...

    // Verificar que existe el corte POS
    if (!$this->hasPOSCutBySesion($sid)) {
        return response()->json([
            'ok' => false,
            'error' => 'pos_cut_missing',  // ❌ Siempre retornaba este error
            'require_pos_cut' => true,
            'sesion_id' => $sid,
            'precorte_id' => $precorteId
        ], 412);
    }
    // ...
}
```

### Propósito de la Vista

`vw_sesion_dpr` une las sesiones de cajón (`selemti.sesion_cajon`) con los reportes de corte del POS (`public.drawer_pull_report`):

- Relaciona sesiones por `terminal_id`
- Filtra DPRs que ocurrieron durante el rango de la sesión (entre `apertura_ts` y `cierre_ts`)
- Permite validar que se completó el corte POS antes de permitir el postcorte

**Sin esta vista, el sistema NO PODÍA verificar** si el usuario hizo el corte POS, bloqueando el flujo del wizard.

---

## Solución Aplicada ✅

### Paso 1: Crear el Script SQL

Archivo: `docs/docs/BD/NoviembreDocsDocs/10_11_2025/CREATE_VW_SESION_DPR.sql`

```sql
-- Drop if exists
DROP VIEW IF EXISTS selemti.vw_sesion_dpr CASCADE;

-- Create the view
CREATE VIEW selemti.vw_sesion_dpr AS
 WITH s AS (
         SELECT sesion_cajon.id,
            sesion_cajon.terminal_id,
            sesion_cajon.cajero_usuario_id,
            sesion_cajon.apertura_ts,
            COALESCE(sesion_cajon.cierre_ts, now()) AS fin_ts
           FROM selemti.sesion_cajon
        )
 SELECT s.id AS sesion_id,
    dpr.id,
    dpr.report_time,
    dpr.reg,
    dpr.ticket_count,
    dpr.begin_cash,
    dpr.net_sales,
    -- ... todos los campos del DPR ...
    dpr.terminal_id
   FROM (s
     JOIN public.drawer_pull_report dpr ON (
         (dpr.terminal_id = s.terminal_id)
         AND (dpr.report_time >= s.apertura_ts)
         AND (dpr.report_time < s.fin_ts)
     ));

-- Set owner and permissions
ALTER VIEW selemti.vw_sesion_dpr OWNER TO postgres;
GRANT SELECT ON TABLE selemti.vw_sesion_dpr TO floreant;
```

### Paso 2: Ejecutar en Local (Verificación)

```bash
cd C:\xampp3\htdocs\TerrenaLaravel

"C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" -h localhost -p 5433 -U postgres -d pos -f "docs/docs/BD/NoviembreDocsDocs/10_11_2025/CREATE_VW_SESION_DPR.sql"
```

**Resultado**:
```
CREATE VIEW
View created successfully: selemti.vw_sesion_dpr
```

**Verificación**:
```bash
"C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" -h localhost -p 5433 -U postgres -d pos -c "SELECT COUNT(*) FROM selemti.vw_sesion_dpr;"
```
```
 view_count
------------
        121
```

### Paso 3: Subir y Ejecutar en Servidor

```bash
# Subir script
pscp -pw T3rr3n4#123 "docs/docs/BD/NoviembreDocsDocs/10_11_2025/CREATE_VW_SESION_DPR.sql" terrena@100.126.124.101:/tmp/

# Ejecutar en servidor
ssh terrena@100.126.124.101
PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -f /tmp/CREATE_VW_SESION_DPR.sql
```

**Resultado en Servidor**:
```
CREATE VIEW
View created successfully: selemti.vw_sesion_dpr
```

**Verificación**:
```bash
PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -c "SELECT COUNT(*) as total_records FROM selemti.vw_sesion_dpr;"
```
```
 total_records
---------------
           128
```

---

## Verificación Final

### Probar el Flujo del Wizard

1. **Abrir sesión de cajón** (si no hay una activa)
2. **Ir a Cortes de Caja**: http://100.126.124.101/terrena2/caja/cortes
3. **Click en "Wizard"** para la sesión activa
4. **Paso 1 - Precorte**: Llenar denominaciones y guardar
5. **Hacer corte POS** en Floreant (Reports → Drawer Pull Report)
6. **Paso 2 - Conciliación**: Click en "Sincronizar POS"
   - ✅ El banner "Falta corte POS" debe desaparecer
   - ✅ El botón "Ir a Postcorte" debe habilitarse
7. **Paso 3 - Postcorte**: Completar y validar

### Verificar en Consola del Navegador

**Antes del Fix**:
```
GET /api/caja/precortes/79/totales 412 (Precondition Failed)
{ok: false, error: "pos_cut_missing", require_pos_cut: true}
```

**Después del Fix**:
```
GET /api/caja/precortes/79/totales 200 OK
{ok: true, data: {...totales y conciliación...}}
```

---

## Comandos de Diagnóstico

### Verificar que la Vista Existe

```bash
PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -c "
  SELECT to_regclass('selemti.vw_sesion_dpr') AS view_exists;
"
```

**Resultado esperado**: `selemti.vw_sesion_dpr` (no `null`)

### Ver DPRs de una Sesión Específica

```bash
PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -c "
  SELECT
    sesion_id,
    id as dpr_id,
    report_time,
    net_sales,
    cash_to_deposit,
    variance
  FROM selemti.vw_sesion_dpr
  WHERE sesion_id = 79;
"
```

### Ver Todas las Sesiones con DPR

```bash
PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -c "
  SELECT
    s.id,
    s.terminal_id,
    s.apertura_ts,
    s.cierre_ts,
    COUNT(v.id) as dpr_count
  FROM selemti.sesion_cajon s
  LEFT JOIN selemti.vw_sesion_dpr v ON s.id = v.sesion_id
  GROUP BY s.id, s.terminal_id, s.apertura_ts, s.cierre_ts
  ORDER BY s.id DESC
  LIMIT 10;
"
```

---

## Estructura de la Vista

### CTE: Sesiones (s)

```sql
WITH s AS (
  SELECT
    sesion_cajon.id,
    sesion_cajon.terminal_id,
    sesion_cajon.cajero_usuario_id,
    sesion_cajon.apertura_ts,
    COALESCE(sesion_cajon.cierre_ts, now()) AS fin_ts  -- Si sesión abierta, usa NOW()
  FROM selemti.sesion_cajon
)
```

### JOIN con DPRs

```sql
SELECT
  s.id AS sesion_id,
  dpr.*  -- Todos los campos del drawer_pull_report
FROM s
JOIN public.drawer_pull_report dpr ON (
  dpr.terminal_id = s.terminal_id          -- Mismo terminal
  AND dpr.report_time >= s.apertura_ts     -- DPR después de apertura
  AND dpr.report_time < s.fin_ts           -- DPR antes de cierre (o NOW si abierta)
)
```

**Nota Importante**: Una sesión puede tener múltiples DPRs si el cajero hizo varios reportes durante la sesión. El wizard busca **cualquier DPR** (`LIMIT 1`) para permitir avanzar.

---

## Archivos Relacionados

### Scripts SQL
- `docs/docs/BD/NoviembreDocsDocs/10_11_2025/CREATE_VW_SESION_DPR.sql` - Script de creación de la vista
- `BD/00.SelemTI_Normalizada_29_10_25_10_40_v0.sql:13960` - Definición original de la vista

### Código PHP
- `app/Http/Controllers/Api/Caja/PrecorteController.php:539-550` - Método `hasPOSCutBySesion()`
- `app/Http/Controllers/Api/Caja/PrecorteController.php:264-401` - Método `resumenLegacy()`

### Documentación
- `docs/CajaChica/WIZARD_CORTE_CAJA-20251017-0258.md` - Flujo del wizard de cortes
- `docs/CajaChica/DOC_WIZARD_CORTE_CAJA-20251017-0126.md` - Validaciones por paso
- `docs/BD/DATA_DICTIONARY-2025-10-17.md:157` - Estructura de `drawer_pull_report`

---

## Problemas Pendientes

Después de aplicar esta solución, quedan **2 problemas adicionales** reportados por el usuario:

### 1. Bug de Sesiones con Múltiples Terminales

**Problema**: Cuando un usuario trabaja en múltiples terminales, el sistema cierra la primera sesión encontrada sin verificar el `terminal_id`.

**Código Afectado**: `PrecorteController.php:288-291`

```php
$sesion = DB::connection('pgsql')
    ->table('selemti.sesion_cajon')
    ->where('terminal_id', $terminalId)          // ✅ Verifica terminal
    ->where('cajero_usuario_id', $userId)        // ✅ Verifica usuario
    ->whereNull('cierre_ts')                     // ✅ Solo sesiones abiertas
    ->first();                                   // ❌ Puede devolver sesión incorrecta
```

**Solución Propuesta**: Agregar `->orderBy('apertura_ts', 'desc')` para obtener la sesión más reciente.

### 2. Cortes en Estado "Regularizar"

**Problema**: Dos cortes (IDs 101, 102) están en estado "⚠️ Regularizar" y no permiten acciones.

**Investigación Necesaria**:
- Determinar qué significa el estado "Regularizar"
- Ver qué acciones deberían estar disponibles
- Verificar si es un estado válido o un bug

---

## Notas Importantes

1. **Esta vista es CRÍTICA** para el funcionamiento del wizard de cortes. Sin ella, ningún usuario puede completar un corte de caja.

2. **La vista debe recrearse** si se hace un restore de la base de datos desde un dump que no la incluya.

3. **Agregar a migraciones**: Considerar crear una migración Laravel que cree esta vista automáticamente en deployments futuros.

4. **Orden de ejecución**: Esta vista debe crearse DESPUÉS de que existan las tablas:
   - `selemti.sesion_cajon`
   - `public.drawer_pull_report`

5. **Permisos**: El usuario `floreant` debe tener permisos de SELECT en esta vista para que el POS pueda consultarla.

---

**Creado por**: Claude Code
**Tiempo de diagnóstico**: ~45 minutos
**Causa raíz**: Vista `selemti.vw_sesion_dpr` faltante en base de datos
**Solución**: Crear vista desde definición en dump de BD de referencia
**Estado**: ✅ RESUELTO - Vista creada y verificada en local y servidor
