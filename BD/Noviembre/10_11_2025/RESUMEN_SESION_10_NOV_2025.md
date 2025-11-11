# Resumen de Sesión - 10 Noviembre 2025

**Duración**: ~3 horas
**Enfoque**: Resolución de problemas críticos en sistema de Cortes de Caja
**Estado Final**: ✅ 3 problemas resueltos, 1 en progreso

---

## Problemas Reportados Inicialmente

1. ✅ **Usuario soporte no ve todos los menús** (a pesar de tener permisos)
2. ✅ **Error 412 "pos_cut_missing"** al avanzar de Precorte a Conciliación
3. ✅ **Error 500** al intentar crear precorte
4. ⏳ **Cortes en estado "Regularizar"** no permiten acciones
5. 🔍 **Sesiones huérfanas** que nunca se cerraron (identificado, pendiente)

---

## Soluciones Implementadas

### 1. ✅ Menús Faltantes - RESUELTO

**Causa Raíz**: Assets de Vite desactualizados en el servidor (NO era problema de permisos/caché)

**Evidencia**:
- Console mostraba: `GET livewire.js 404 (Not Found)`
- Console mostraba: `[Terrena] Loaded 45 permissions from cache` ← Permisos SÍ cargaban
- Solo se veían menús básicos: Dashboard, Caja, Catálogos
- Faltaban: Inventario, Recetas, Compras, Reportes

**Solución Aplicada**:
```bash
# Local
npm run build

# Servidor
pscp -r public/build terrena@100.126.124.101:/var/www/kds/terrenaPos/public/
ssh terrena@100.126.124.101
php artisan livewire:publish --assets
ln -s vendor/livewire livewire  # en public/
php artisan view:clear && php artisan config:clear
```

**Resultado**: ✅ Usuario confirmó "excelente, quedo corregido"

**Archivos Creados**:
- `BD/Noviembre/10_11_2025/SOLUCION_CACHE_PERMISOS.md` (actualizado con nota sobre causa real)

---

### 2. ✅ Error 412 "pos_cut_missing" - RESUELTO

**Causa Raíz**: Vista `selemti.vw_sesion_dpr` NO EXISTÍA en la base de datos

**Impacto**: Bloqueaba TODOS los cortes en Paso 2 (Conciliación), imposibilitando avanzar a Postcorte

**Código Afectado**:
```php
// app/Http/Controllers/Api/Caja/PrecorteController.php:539-550
private function hasPOSCutBySesion(int $sesionId): bool
{
    $reg = DB::connection('pgsql')->selectOne("SELECT to_regclass('selemti.vw_sesion_dpr') AS t");
    if (!$reg || !$reg->t) return false;  // ❌ SIEMPRE retornaba false
    // ...
}

// PrecorteController.php:264-401
public function resumenLegacy(...) {
    if (!$this->hasPOSCutBySesion($sid)) {
        return response()->json([
            'ok' => false,
            'error' => 'pos_cut_missing',  // ❌ Error 412
            'require_pos_cut' => true
        ], 412);
    }
}
```

**Propósito de la Vista**:
- Une `selemti.sesion_cajon` con `public.drawer_pull_report` (DPR del POS)
- Valida que se hizo el corte POS antes de permitir postcorte
- Filtra DPRs por terminal_id y rango temporal (apertura_ts → cierre_ts)

**Solución Aplicada**:
```sql
-- Ver: BD/Noviembre/10_11_2025/CREATE_VW_SESION_DPR.sql
CREATE VIEW selemti.vw_sesion_dpr AS
 WITH s AS (
         SELECT id, terminal_id, cajero_usuario_id, apertura_ts,
                COALESCE(cierre_ts, now()) AS fin_ts
           FROM selemti.sesion_cajon
        )
 SELECT s.id AS sesion_id,
    dpr.*  -- Todos los campos del drawer_pull_report
   FROM s
     JOIN public.drawer_pull_report dpr ON (
         dpr.terminal_id = s.terminal_id
         AND dpr.report_time >= s.apertura_ts
         AND dpr.report_time < s.fin_ts
     );
```

**Verificación**:
- Local: 121 registros
- Servidor: 128 registros
- Vista funcional en ambos ambientes

**Archivos Creados**:
- `BD/Noviembre/10_11_2025/CREATE_VW_SESION_DPR.sql`
- `BD/Noviembre/10_11_2025/SOLUCION_ERROR_412_POS_CUT_MISSING.md`

---

### 3. ✅ Error 500 al Crear Precorte - RESUELTO

**Causa Raíz**: CHECK constraint de `sesion_cajon.estatus` NO incluía el estado 'EN_CORTE'

**Error Completo**:
```
SQLSTATE[23514]: Check violation: 7 ERROR: el nuevo registro para la relación «sesion_cajon»
viola la restricción «check» «sesion_cajon_estatus_check»
DETAIL: La fila que falla contiene (..., EN_CORTE, ...)
CONTEXT: sentencia SQL: «UPDATE selemti.sesion_cajon SET estatus = 'EN_CORTE' WHERE id = NEW.sesion_id»
función PL/pgSQL fn_precorte_after_insert() en la línea 3
```

**Problema**:
```sql
-- Constraint ANTES (solo 3 estados)
CHECK (estatus = ANY (ARRAY['ACTIVA', 'LISTO_PARA_CORTE', 'CERRADA']))

-- Trigger intenta hacer:
UPDATE selemti.sesion_cajon SET estatus = 'EN_CORTE'  -- ❌ No permitido!
```

**Solución Aplicada**:
```sql
-- BD/Noviembre/10_11_2025/FIX_SESION_CAJON_ESTATUS_CHECK.sql
ALTER TABLE selemti.sesion_cajon DROP CONSTRAINT sesion_cajon_estatus_check;

ALTER TABLE selemti.sesion_cajon
  ADD CONSTRAINT sesion_cajon_estatus_check
  CHECK (estatus = ANY (ARRAY['ACTIVA', 'LISTO_PARA_CORTE', 'EN_CORTE', 'CERRADA']));
```

**Resultado**: ✅ Precortes se crean correctamente ahora

**Archivos Creados**:
- `BD/Noviembre/10_11_2025/FIX_SESION_CAJON_ESTATUS_CHECK.sql`

---

### 4. ⏳ Estado "Regularizar" - EN PROGRESO (50% completado)

**Análisis del Problema**:

**¿Qué es "Regularizar"?**
- Estado UI que aparece cuando `sesion_cajon.skipped_precorte = true`
- Indica que la sesión se cerró en el POS **ANTES** de hacer el precorte
- Proceso fuera de lo normal que requiere supervisión

**Lógica Actual**:
```php
// CajasController.php:92-97
private function calcularEstado(..., bool $skipped): string
{
    if ($skipped) {
        return 'REGULARIZAR';  // Prioridad #1
    }
    // ... otros estados
}
```

**Casos Encontrados en Servidor**:
```sql
-- Sesión 162 (Terminal 102):
skipped_precorte = TRUE
postcorte.validado = TRUE    ✅ YA COMPLETO
estado UI: "Regularizar"

-- Sesión 163 (Terminal 101):
skipped_precorte = TRUE
postcorte.validado = FALSE   ❌ PENDIENTE
estado UI: "Regularizar"
```

**Decisión de Diseño**:

Opción acordada: **Flujo Híbrido de Aprobación**

1. Cajeros pueden completar wizard normalmente
2. Al validar postcorte con `skipped_precorte=true`:
   - NO se cierra la sesión automáticamente
   - Se marca `postcorte.requiere_aprobacion = true`
   - Se crea alerta para supervisores
3. Supervisor aprueba/rechaza desde vista dedicada
4. Solo después de aprobación se considera "cerrado"

**Solución Implementada (Base de Datos)**:

```sql
-- BD/Noviembre/10_11_2025/ADD_APROBACION_POSTCORTE.sql

-- Nuevas columnas en postcorte
ALTER TABLE selemti.postcorte ADD COLUMN requiere_aprobacion BOOLEAN DEFAULT FALSE;
ALTER TABLE selemti.postcorte ADD COLUMN aprobado_por INTEGER REFERENCES selemti.users(id);
ALTER TABLE selemti.postcorte ADD COLUMN aprobado_en TIMESTAMP WITH TIME ZONE;
ALTER TABLE selemti.postcorte ADD COLUMN motivo_irregular TEXT;
ALTER TABLE selemti.postcorte ADD COLUMN rechazado BOOLEAN DEFAULT FALSE;
ALTER TABLE selemti.postcorte ADD COLUMN motivo_rechazo TEXT;

-- Nueva tabla de alertas
CREATE TABLE selemti.alertas_cortes (
  id BIGSERIAL PRIMARY KEY,
  postcorte_id BIGINT REFERENCES selemti.postcorte(id) ON DELETE CASCADE,
  sesion_id BIGINT REFERENCES selemti.sesion_cajon(id) ON DELETE CASCADE,
  tipo VARCHAR(50) NOT NULL,  -- 'REQUIERE_APROBACION', 'APROBADO', 'RECHAZADO'
  destinatario_id INTEGER REFERENCES selemti.users(id),
  leida BOOLEAN DEFAULT FALSE,
  creada_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  leida_en TIMESTAMP WITH TIME ZONE
);
```

**Estado Actual**:
- ✅ Esquema de BD aplicado en local y servidor
- ✅ 1 postcorte marcado automáticamente como `requiere_aprobacion=true` (sesión 163)
- ⏳ Pendiente: Backend (Controllers, Routes, Services)
- ⏳ Pendiente: Frontend (Wizard modificado, Vista Aprobaciones, Alertas)
- ⏳ Pendiente: Permisos nuevos

**Archivos Creados**:
- `BD/Noviembre/10_11_2025/ADD_APROBACION_POSTCORTE.sql`
- `BD/Noviembre/10_11_2025/PLAN_REGULARIZACION_CORTES.md` ← **Plan completo de implementación**

---

### 5. 🔍 Sesiones Huérfanas - IDENTIFICADO

**Problema**: Sesiones que nunca se cerraron, permanecen en estado "Abierta" indefinidamente

**Ejemplos del Servidor**:
```
Terminal 201 (NB)       - Aldo Abraham    - 12:16 p.m. - Estado: Abierta
Terminal 301 (NB)       - JOSE HUESCA     - 12:16 p.m. - Estado: Abierta
Terminal 401 (ENTRADA)  - juan david      - 12:16 p.m. - Estado: Abierta
Terminal 201 (TORRE)    - Luis Ronaldo    - 12:16 p.m. - Estado: Abierta
Terminal 1091           - alejandro       - 12:16 p.m. - Estado: Abierta
```

**Causa Probable**:
- Sistema se quedó sin conexión / error al cerrar
- Cajero no completó el proceso de cierre
- Crash del POS / sistema

**Impacto**:
- Sesiones "fantasma" que contaminan la vista de cajas del día
- Pueden bloquear la apertura de nuevas sesiones en mismo terminal
- Datos históricos inconsistentes

**Solución Propuesta** (para implementar después):
- Crear herramienta de "Mantenimiento de Sesiones"
- Permitir:
  - Cerrar forzadamente sesiones antiguas
  - Marcar como "Cancelada" con motivo
  - Generar reporte de sesiones huérfanas
- Requiere permisos especiales (solo administradores)

**Estado**: 🔍 Identificado, documentado, pendiente de implementación

---

## Archivos SQL Creados

Todos en: `BD/Noviembre/10_11_2025/`

1. **CREATE_VW_SESION_DPR.sql** - Crea vista para validar DPR
2. **FIX_SESION_CAJON_ESTATUS_CHECK.sql** - Agrega estado 'EN_CORTE' al constraint
3. **ADD_APROBACION_POSTCORTE.sql** - Esquema para sistema de aprobación

**Estado**: ✅ Todos aplicados en LOCAL y SERVIDOR

---

## Documentación Creada

Todos en: `BD/Noviembre/10_11_2025/`

1. **SOLUCION_CACHE_PERMISOS.md** - Problema de menús (assets desactualizados)
2. **SOLUCION_ERROR_412_POS_CUT_MISSING.md** - Vista vw_sesion_dpr faltante
3. **PLAN_REGULARIZACION_CORTES.md** - Plan completo sistema de aprobación
4. **RESUMEN_SESION_10_NOV_2025.md** - Este documento

---

## Comandos Ejecutados en Servidor

```bash
# 1. Subir assets de Vite
pscp -r public/build terrena@100.126.124.101:/var/www/kds/terrenaPos/public/

# 2. Publicar assets de Livewire
ssh terrena@100.126.124.101
cd /var/www/kds/terrenaPos
php artisan livewire:publish --assets
cd public && ln -s vendor/livewire livewire

# 3. Limpiar cachés
php artisan view:clear
php artisan config:clear

# 4. Aplicar scripts SQL
pscp BD/Noviembre/10_11_2025/*.sql terrena@100.126.124.101:/tmp/
PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -f /tmp/CREATE_VW_SESION_DPR.sql
PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -f /tmp/FIX_SESION_CAJON_ESTATUS_CHECK.sql
PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -f /tmp/ADD_APROBACION_POSTCORTE.sql
```

---

## Queries de Verificación

### Verificar vista vw_sesion_dpr existe
```sql
SELECT to_regclass('selemti.vw_sesion_dpr') AS vista_existe;
-- Resultado esperado: selemti.vw_sesion_dpr
```

### Contar registros en vista
```sql
SELECT COUNT(*) as total_dprs FROM selemti.vw_sesion_dpr;
-- Local: 121 | Servidor: 128
```

### Verificar constraint de estatus
```sql
SELECT consrc
FROM pg_constraint
WHERE conrelid = 'selemti.sesion_cajon'::regclass
  AND conname = 'sesion_cajon_estatus_check';
-- Debe incluir: 'ACTIVA', 'LISTO_PARA_CORTE', 'EN_CORTE', 'CERRADA'
```

### Ver postcortes que requieren aprobación
```sql
SELECT
  p.id,
  p.sesion_id,
  s.terminal_id,
  p.validado,
  p.requiere_aprobacion,
  s.skipped_precorte
FROM selemti.postcorte p
JOIN selemti.sesion_cajon s ON p.sesion_id = s.id
WHERE p.requiere_aprobacion = TRUE;
-- Servidor: 1 registro (sesión 163)
```

### Listar sesiones huérfanas (abiertas hace más de 24 horas)
```sql
SELECT
  id,
  terminal_id,
  cajero_usuario_id,
  apertura_ts,
  estatus,
  NOW() - apertura_ts AS tiempo_abierta
FROM selemti.sesion_cajon
WHERE estatus = 'ACTIVA'
  AND apertura_ts < NOW() - INTERVAL '24 hours'
ORDER BY apertura_ts;
```

---

## Próximos Pasos (Orden Recomendado)

### Fase 1: Completar Sistema de Regularización

Seguir el plan en: `BD/Noviembre/10_11_2025/PLAN_REGULARIZACION_CORTES.md`

1. **Permisos** (database/seeders/PermissionsSeeder.php)
   - Agregar: `aprobar-cortes-irregulares`
   - Agregar: `rechazar-cortes-irregulares`
   - Agregar: `ver-alertas-cortes`
   - Asignar a rol "Super Admin"
   - Asignar a usuario `soporte@terrena.com`

2. **Backend - AlertasService** (app/Services/AlertasService.php)
   - Método: `crearAlertaAprobacion($postcorte)`
   - Método: `crearAlertaAprobado($postcorte)`
   - Método: `crearAlertaRechazado($postcorte)`
   - Método: `obtenerPendientes($userId)`
   - Método: `marcarLeida($alertaId)`

3. **Backend - PostcorteController** (modificar existente)
   - `create()`: Detectar skipped_precorte y marcar requiere_aprobacion
   - `update()`: NO cerrar sesión si requiere_aprobacion && !aprobado_por
   - `aprobar(Request, $id)`: Nuevo método
   - `rechazar(Request, $id)`: Nuevo método
   - `pendientesAprobacion()`: Nuevo método

4. **Backend - AlertasController** (crear nuevo)
   - `index()`: Listar alertas del usuario autenticado
   - `marcarLeida($id)`: Marcar alerta como leída

5. **Routes API** (routes/api.php)
   - `POST /api/caja/postcortes/{id}/aprobar`
   - `POST /api/caja/postcortes/{id}/rechazar`
   - `GET /api/caja/postcortes/pendientes-aprobacion`
   - `GET /api/caja/alertas`
   - `PUT /api/caja/alertas/{id}/marcar-leida`

6. **Frontend - Wizard** (resources/views/caja/_wizard_modals.php + public/assets/js/caja/wizard.js)
   - Detectar `skipped_precorte` en Paso 3
   - Mostrar banner de advertencia
   - Agregar campo `motivo_irregular`
   - Cambiar texto botón: "Enviar a Aprobación"
   - Manejar respuesta con `requiere_aprobacion: true`

7. **Frontend - Vista Aprobaciones** (resources/views/caja/aprobaciones.blade.php)
   - Tabla de postcortes pendientes
   - Botones: Ver Detalle | Aprobar | Rechazar
   - Modal de detalle completo
   - Modal de aprobación (con notas)
   - Modal de rechazo (con motivo obligatorio)

8. **Frontend - Sistema de Alertas**
   - Badge en menú con contador
   - Auto-refresh periódico
   - Notificaciones en header/navbar

9. **Routes Web** (routes/web.php)
   - `GET /caja/cortes/aprobaciones`
   - Agregar enlace en menú lateral

10. **Testing Completo**
    - Crear sesión con skipped_precorte
    - Completar wizard hasta postcorte
    - Verificar alerta creada
    - Aprobar desde vista
    - Verificar sesión cerrada

### Fase 2: Mantenimiento de Sesiones Huérfanas

**Diseño a definir**. Posibles funcionalidades:
- Vista de sesiones abiertas antiguas
- Botón "Cerrar Forzadamente" con justificación
- Estado adicional "CANCELADA"
- Reporte de sesiones problemáticas
- Permisos: `gestionar-sesiones-huerfanas`

---

## Métricas de la Sesión

- **Problemas resueltos**: 3 de 5
- **Scripts SQL creados**: 3
- **Documentos creados**: 4
- **Tablas modificadas**: 2 (postcorte, sesion_cajon)
- **Tablas creadas**: 1 (alertas_cortes)
- **Vistas creadas**: 1 (vw_sesion_dpr)
- **Líneas de documentación**: ~800+

---

## Notas Técnicas Importantes

### PostgreSQL 9.5 Limitaciones

```sql
-- ❌ NO soportado en PG 9.5
ALTER TABLE foo ADD COLUMN IF NOT EXISTS bar TEXT;

-- ✅ Usar en su lugar
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='foo' AND column_name='bar') THEN
    ALTER TABLE foo ADD COLUMN bar TEXT;
  END IF;
END
$$;
```

### Constraint CHECK States

El flujo de estados de `sesion_cajon` es:
```
ACTIVA → LISTO_PARA_CORTE → EN_CORTE → CERRADA
```

Asegurarse que el constraint permita TODOS estos estados.

### Trigger `fn_precorte_after_insert()`

Al insertar en `precorte`, automáticamente:
```sql
UPDATE selemti.sesion_cajon
SET estatus = 'EN_CORTE'
WHERE id = NEW.sesion_id
  AND estatus = 'LISTO_PARA_CORTE';
```

Este trigger es crítico para el flujo del wizard.

---

**Creado por**: Claude Code
**Fecha**: 2025-11-10
**Hora de finalización**: ~23:30
**Contexto preservado**: ✅ Para próxima sesión
