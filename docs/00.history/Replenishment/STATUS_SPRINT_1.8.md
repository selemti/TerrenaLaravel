# 🧭 STATUS SPRINT 1.8 – Reportes y KPIs Operativos

Estado general: 🟨 En progreso  
Fecha: 2025-10-26

## 1. Rutas expuestas (Laravel)
- GET /api/reports/purchasing/late-po -> Reports\ReportsController@purchasingLatePO
- GET /api/reports/inventory/over-tolerance -> Reports\ReportsController@inventoryOverTolerance
- GET /api/reports/inventory/top-urgent -> Reports\ReportsController@inventoryTopUrgent

## 2. Backend
- `App\Http\Controllers\Reports\ReportsController` creado con métodos read-only que construyen query builders básicos (`purchase_orders`, `recepcion_det`, `purchase_suggestions`).
- Cada método responde `{ok, data}` y deja TODO de caching/snapshots; se planea protegerlos con `reports.view.*`.
- Rutas viven junto al grupo `/api/reports` existente, compartiendo namespace con los dashboards actuales.

## 3. Pendiente para cerrar sprint
- Definir policies/permisos y asegurar que sólo roles de dirección accedan a los endpoints.
- Completar queries con métricas reales (por proveedor, categoría, SLA).
- Añadir paginación/caching para no impactar producción.

## 4. Riesgos / Bloqueantes
- Dependemos de datos consistentes de recepciones y sugerencias; sin ellos los KPIs quedarán vacíos.
- Consultas sin índices podrían degradar rendimiento.
- Falta de snapshots diarios puede generar discrepancias históricas.

## 5. Siguiente paso inmediato
Implementar middleware/policies `reports.view.*` y optimizar queries con filtros por fecha.
