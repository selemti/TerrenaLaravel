# PROMPT PARA QWEN - DIAGNÓSTICO REPORTES DE VENTAS (PARTE 1)

**Fecha**: 26 de noviembre de 2025
**Prioridad**: 🔥 CRÍTICA
**Tiempo estimado**: 4-6 horas

---

## CONTEXTO

El usuario reporta que **las cifras de ventas NO coinciden** entre:
- Dashboard principal (`/dashboard`)
- Diferentes reportes de ventas (`/reports/sales/*`)
- Valores reales en el POS (schema `public`)

**Base de datos**: PostgreSQL 9.5
**Schemas**:
- `public` - POS legacy Floreant (READ-ONLY en producción, tablas reales)
- `selemti` - Schema de trabajo (vistas materializadas y tablas custom)

**Credenciales**:
```
Host: localhost
Port: 5433
Database: pos
User: postgres
```

---

## TAREA URGENTE

Auditar **todas las vistas materializadas y fuentes de datos** relacionadas con reportes de ventas para identificar las **causas de las inconsistencias**.

---

## PASO 1: LISTAR VISTAS MATERIALIZADAS

Ejecuta este query para listar todas las vistas materializadas:

```sql
SELECT
  schemaname,
  matviewname,
  definition
FROM pg_matviews
WHERE schemaname IN ('public', 'selemti')
ORDER BY schemaname, matviewname;
```

**Documenta**:
- Nombre completo de cada vista
- Schema donde está
- Definición SQL (completa)

---

## PASO 2: VALIDAR VISTAS DE DASHBOARD

Estas son las vistas materializadas que usa el **Dashboard** (`/dashboard`):

1. `selemti.vw_dashboard_resumen_sucursal`
2. `selemti.vw_dashboard_resumen_terminal`
3. `selemti.vw_dashboard_ticket_base`
4. `selemti.vw_dashboard_ventas_hora`
5. `selemti.vw_dashboard_ventas_categorias`

Para **CADA UNA**, ejecuta y documenta:

### A. Obtener definición completa

```sql
SELECT definition
FROM pg_matviews
WHERE schemaname = 'selemti'
  AND matviewname = 'vw_dashboard_resumen_sucursal';
```

### B. Verificar última actualización

```sql
SELECT
  schemaname,
  matviewname,
  last_refresh
FROM pg_stat_user_tables
WHERE schemaname = 'selemti'
  AND relname LIKE 'vw_dashboard%';
```

**IMPORTANTE**: Si `last_refresh` es NULL o muy antigua (> 1 día), las vistas están **desactualizadas**.

### C. Identificar tablas origen

Analiza la definición SQL de cada vista y documenta:
- ¿Qué tablas usa? (`public.ticket`, `public.ticket_item`, etc.)
- ¿Está leyendo de `public` (datos reales) o de `selemti` (otras vistas)?
- ¿Qué joins hace?

### D. Validar lógica de filtrado

Busca en la definición SQL:
- ¿Filtra `voided = false`? ✅ o ❌
- ¿Filtra `paid = true`? ✅ o ❌
- ¿Usa `closing_date` o `created_at` para fechas?
- ¿Hay otros filtros importantes?

---

## PASO 3: COMPARAR TOTALES (HOY)

Ejecuta estas consultas para **HOY** y compara resultados:

### A. Total desde vista materializada

```sql
SELECT
  SUM(venta_total) AS total_vista,
  SUM(tickets) AS tickets_vista,
  COUNT(DISTINCT sucursal_id) AS sucursales
FROM selemti.vw_dashboard_resumen_sucursal
WHERE fecha = CURRENT_DATE;
```

### B. Total desde tabla real del POS

```sql
SELECT
  SUM(t.total) AS total_real,
  COUNT(DISTINCT t.id) AS tickets_real,
  COUNT(DISTINCT t.terminal_id) AS terminales
FROM public.ticket t
WHERE DATE(t.closing_date) = CURRENT_DATE
  AND t.paid = true
  AND t.voided = false;
```

### C. Calcular diferencia

```
Diferencia absoluta = |total_real - total_vista|
Diferencia porcentual = (diferencia_absoluta / total_real) * 100
```

**¿Coinciden?**
- ✅ Coinciden (diferencia < 1%)
- ⚠️ Diferencia menor (1% - 5%)
- ❌ Diferencia significativa (> 5%)

---

## PASO 4: COMPARAR TOTALES (ÚLTIMOS 7 DÍAS)

Repite la comparación para los últimos 7 días:

```sql
SELECT
  fecha,
  SUM(venta_total) AS total_vista,
  SUM(tickets) AS tickets_vista
FROM selemti.vw_dashboard_resumen_sucursal
WHERE fecha >= CURRENT_DATE - INTERVAL '6 days'
GROUP BY fecha
ORDER BY fecha;
```

```sql
SELECT
  DATE(t.closing_date) AS fecha,
  SUM(t.total) AS total_real,
  COUNT(DISTINCT t.id) AS tickets_real
FROM public.ticket t
WHERE DATE(t.closing_date) >= CURRENT_DATE - INTERVAL '6 days'
  AND t.paid = true
  AND t.voided = false
GROUP BY DATE(t.closing_date)
ORDER BY fecha;
```

**Documenta**: ¿La diferencia es consistente todos los días o solo algunos?

---

## PASO 5: IDENTIFICAR PROCESO DE REFRESH

Investiga cómo se actualizan las vistas:

### A. Buscar cron jobs

```bash
# En el servidor
crontab -l | grep -i refresh
crontab -l | grep -i dashboard
```

### B. Buscar funciones de refresh

```sql
SELECT
  proname,
  prosrc
FROM pg_proc
WHERE proname LIKE '%refresh%'
  OR proname LIKE '%dashboard%';
```

### C. Buscar triggers

```sql
SELECT
  tgname,
  tgrelid::regclass,
  pg_get_triggerdef(oid)
FROM pg_trigger
WHERE tgname LIKE '%refresh%'
  OR tgname LIKE '%dashboard%';
```

**Documenta**:
- ✅ Existe proceso automático de refresh → ¿Con qué frecuencia?
- ❌ NO existe proceso automático → **PROBLEMA IDENTIFICADO**

---

## PASO 6: REVISAR OTRAS FUENTES DE DATOS

El archivo `app/Http/Controllers/Api/ReportsController.php` tiene estos métodos:

1. `kpisSucursalDia()` → `selemti.vw_dashboard_resumen_sucursal`
2. `kpisTerminalDia()` → `selemti.vw_dashboard_resumen_terminal`
3. `ventasFamilia()` → `selemti.vw_dashboard_ventas_categorias`
4. `ventasPorHora()` → `selemti.vw_dashboard_ventas_hora`
5. `ventasTopProductos()` → `public.ticket_item` (tabla real, NO vista)
6. `ticketPromedio()` → `selemti.vw_dashboard_ticket_base`
7. `ventasDiarias()` → `selemti.vw_dashboard_resumen_sucursal`

**Valida**:
- ¿`ventasTopProductos()` usa la lógica correcta? (paid=true, voided=false)
- ¿Hay inconsistencia entre las vistas y las consultas directas?

---

## PASO 7: BUSCAR OTRAS VISTAS MATERIALIZADAS

Ejecuta:

```sql
SELECT
  schemaname,
  matviewname,
  definition
FROM pg_matviews
WHERE schemaname = 'selemti'
ORDER BY matviewname;
```

Documenta **TODAS** las vistas materializadas que existen, aunque no estén en la lista anterior.

---

## ENTREGABLE

Crea el archivo: **`docs/AUDIT/REPORTES_VENTAS_DIAGNOSTICO.md`**

Usa este formato:

```markdown
# Diagnóstico de Reportes de Ventas
**Fecha**: 26 de noviembre de 2025
**Auditor**: QWEN

---

## 1. VISTAS MATERIALIZADAS ENCONTRADAS

Total de vistas en `selemti`: [número]

### Lista completa:
1. selemti.vw_dashboard_resumen_sucursal
2. selemti.vw_dashboard_resumen_terminal
3. ... (todas las encontradas)

---

## 2. ANÁLISIS POR VISTA

### Vista: selemti.vw_dashboard_resumen_sucursal

**Última actualización**: 2025-11-20 08:00:00 (⚠️ 6 días desactualizada)

**Definición SQL**:
```sql
[SQL completo de la definición]
```

**Tablas origen**:
- public.ticket ✅
- public.ticket_item ✅

**Filtros aplicados**:
- paid = true ✅
- voided = false ✅
- Usa closing_date ✅

**Inconsistencia detectada**:
❌ Vista desactualizada desde hace 6 días

**Comparación de totales (HOY)**:
- Total en vista: $12,345.67
- Total en tabla real: $15,890.00
- Diferencia: $3,544.33 (28.7%) ❌ CRÍTICO

---

### Vista: selemti.vw_dashboard_resumen_terminal

[Mismo formato para cada vista]

---

## 3. COMPARACIÓN ÚLTIMOS 7 DÍAS

| Fecha | Total Vista | Total Real | Diferencia | % |
|-------|-------------|------------|------------|---|
| 2025-11-26 | $12,345 | $15,890 | $3,545 | 28.7% |
| 2025-11-25 | $11,200 | $11,200 | $0 | 0% |
| ... | ... | ... | ... | ... |

**Conclusión**: La diferencia solo aparece hoy, las vistas NO se refrescaron.

---

## 4. PROCESO DE REFRESH

**¿Existe proceso automático?** ❌ NO

**Detalles**:
- No se encontró cron job
- No se encontraron triggers
- No hay funciones de refresh automáticas

**PROBLEMA IDENTIFICADO**: Las vistas se deben refrescar **manualmente** y no se ha hecho.

---

## 5. OTRAS FUENTES DE DATOS

### ventasTopProductos()
- Lee directamente de `public.ticket_item` ✅
- Filtra correctamente (paid=true, voided=false) ✅
- NO tiene problemas de actualización

### Otros endpoints
[Listar problemas encontrados en otros endpoints]

---

## 6. RESUMEN DE PROBLEMAS ENCONTRADOS

### 🔴 CRÍTICO:
1. **Vistas materializadas desactualizadas** - Última actualización hace 6+ días
2. **NO existe proceso automático de refresh** - Se requiere ejecución manual
3. **Diferencia de 28.7%** entre vista y datos reales de HOY

### ⚠️ MODERADO:
[Si hay otros problemas menos críticos]

### ℹ️ INFORMATIVO:
[Observaciones adicionales]

---

## 7. RECOMENDACIONES

### INMEDIATO (hacer ahora):
1. **Refrescar todas las vistas materializadas**:
   ```sql
   REFRESH MATERIALIZED VIEW selemti.vw_dashboard_resumen_sucursal;
   REFRESH MATERIALIZED VIEW selemti.vw_dashboard_resumen_terminal;
   REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ticket_base;
   REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ventas_hora;
   REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ventas_categorias;
   ```

2. **Validar que totales coincidan después del refresh**

### CORTO PLAZO (siguiente fase):
3. **Crear función de refresh automático**
4. **Configurar cron job diario** (ejecutar a las 00:30 cada día)
5. **Agregar logging** para monitorear refreshes

### LARGO PLAZO (opcional):
6. Considerar reemplazar vistas materializadas por vistas regulares si el performance lo permite
7. Agregar índices adicionales en tablas `public.ticket` si es necesario

---

## 8. SCRIPT DE CORRECCIÓN

Ver archivo: `docs/AUDIT/REPORTES_VENTAS_CORRECCION.sql`

Este script contiene:
- Comandos de REFRESH
- Validaciones post-refresh
- Creación de función automática
- Configuración de cron job

---

**FIN DEL DIAGNÓSTICO**
```

---

## ARCHIVO ADICIONAL: SCRIPT DE CORRECCIÓN

También crea: **`docs/AUDIT/REPORTES_VENTAS_CORRECCION.sql`**

```sql
-- =====================================================
-- CORRECCIÓN DE REPORTES DE VENTAS
-- Fecha: 26-Nov-2025
-- =====================================================

-- PASO 1: REFRESCAR TODAS LAS VISTAS
REFRESH MATERIALIZED VIEW selemti.vw_dashboard_resumen_sucursal;
REFRESH MATERIALIZED VIEW selemti.vw_dashboard_resumen_terminal;
REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ticket_base;
REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ventas_hora;
REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ventas_categorias;

-- PASO 2: VALIDAR QUE LAS VISTAS FUERON REFRESCADAS
SELECT
  schemaname,
  matviewname,
  last_refresh
FROM pg_stat_user_tables
WHERE schemaname = 'selemti'
  AND relname LIKE 'vw_dashboard%'
ORDER BY matviewname;

-- PASO 3: VALIDAR TOTALES POST-REFRESH (HOY)
-- Vista
SELECT
  'VISTA' as fuente,
  SUM(venta_total) AS total,
  SUM(tickets) AS tickets
FROM selemti.vw_dashboard_resumen_sucursal
WHERE fecha = CURRENT_DATE;

-- Tabla real
SELECT
  'REAL' as fuente,
  SUM(t.total) AS total,
  COUNT(DISTINCT t.id) AS tickets
FROM public.ticket t
WHERE DATE(t.closing_date) = CURRENT_DATE
  AND t.paid = true
  AND t.voided = false;

-- PASO 4: CREAR FUNCIÓN DE REFRESH AUTOMÁTICO
CREATE OR REPLACE FUNCTION selemti.refresh_dashboard_views()
RETURNS void AS $$
BEGIN
  RAISE NOTICE 'Iniciando refresh de vistas dashboard...';

  REFRESH MATERIALIZED VIEW selemti.vw_dashboard_resumen_sucursal;
  RAISE NOTICE 'vw_dashboard_resumen_sucursal refreshed';

  REFRESH MATERIALIZED VIEW selemti.vw_dashboard_resumen_terminal;
  RAISE NOTICE 'vw_dashboard_resumen_terminal refreshed';

  REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ticket_base;
  RAISE NOTICE 'vw_dashboard_ticket_base refreshed';

  REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ventas_hora;
  RAISE NOTICE 'vw_dashboard_ventas_hora refreshed';

  REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ventas_categorias;
  RAISE NOTICE 'vw_dashboard_ventas_categorias refreshed';

  RAISE NOTICE 'Todas las vistas refreshed exitosamente a las %', NOW();
END;
$$ LANGUAGE plpgsql;

-- PASO 5: PROBAR LA FUNCIÓN
SELECT selemti.refresh_dashboard_views();

-- PASO 6: CONFIGURAR CRON JOB (ejecutar en servidor)
-- Agregar esta línea al crontab:
-- 30 0 * * * psql -h localhost -p 5433 -U postgres -d pos -c "SELECT selemti.refresh_dashboard_views();" >> /var/log/postgres/dashboard_refresh.log 2>&1

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================
```

---

## INSTRUCCIONES DE EJECUCIÓN

1. **Conectarte a PostgreSQL**:
   ```bash
   psql -h localhost -p 5433 -U postgres -d pos
   ```

2. **Ejecutar los queries** de diagnóstico paso por paso

3. **Documentar resultados** en el archivo markdown

4. **Crear el script SQL** con las correcciones

5. **Entregar ambos archivos** para validación de Claude

---

## TIEMPO ESTIMADO

- Paso 1-2: 1 hora
- Paso 3-4: 1.5 horas
- Paso 5-6: 1 hora
- Paso 7: 30 min
- Documentación: 1-2 horas

**Total**: 4-6 horas

---

**IMPORTANTE**: NO ejecutes las correcciones (PARTE 2) hasta que Claude valide este diagnóstico.

---

**FIN DEL PROMPT**
