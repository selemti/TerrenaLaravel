# Reportes V4.0 · Módulo de Ventas y KPIs

## 1. Alcance

Documenta el módulo `/reports` vigente (web + API) basado en los controladores `App\Http\Controllers\Reports\*`, las vistas en `resources/views/reports` y el handbook `docs/Reports/README_REPORTES_ERP_V10.md`. Cubre reportes de Ventas (mix, cajón vs efectivo, diagnósticos, modificadores, detalle, resumen, balance, excepciones, journal) y utilidades adicionales (menu usage, tickets abiertos). Esto reemplaza los docs V9/V10 legacy al trabajar bajo V4.0.

## 2. Permisos y rutas

- **Middleware:** todas las rutas bajo `/reports` usan `auth` + `permission:reports.view`.  
- **Menu:** sidebar “Reportes” (ver `docs/Reports/MENU_REPORTES_AGREGADO_2025_11_04.md`) sólo aparece con ese permiso.
- **Rutas principales** (ver `routes/web.php:390-434`):

| Ruta | Controller@action | Descripción |
|------|-------------------|-------------|
| `/reports/sales` | `SalesReportController@index` | Landing (cards a cada reporte). |
| `/reports/sales/mix` (+ `export/xlsx|pdf`) | `SalesMixController@show` | Mix de ventas por forma de pago. |
| `/reports/sales/drawer` (+ export) | `SalesDrawerController@show` | Cajón vs efectivo. |
| `/reports/sales/diagnostics` (+ export) | `SalesDiagController@show` | Diagnósticos diarios. |
| `/reports/sales/mods` (+ export) | `SalesModsController@show` | Items + modificadores. |
| `/reports/sales/detail|summary|balance|exceptions|journal` (+ export pdf) | Controladores homónimos | Reportes Jasper-equivalents. |
| `/reports/menu/usage` (+ export pdf) | `MenuUsageController@show` | Uso del menú (coberturas). |
| `/reports/tickets/open` (+ export pdf) | `OpenTicketsController@show` | Tickets abiertos/pagados. |

Exportes usan `Maatwebsite\Excel` (XLSX) o PDF via `BaseReportController::renderPdf`.

## 3. Arquitectura del módulo

- **BaseReportController**: maneja filtros (`parseDateRange`, `parseBranch`), timezone (`America/Mexico_City`) y helpers (`renderPdf`).  
- **Drivers SQL**: cada reporte consulta funciones/vistas en `public`/`selemti` (ver `docs/Reports/README_REPORTES_ERP_V10.md`). Ej. `public.f_sales_mix_payment_on(:date)`, `public.f_diag_drawer_vs_cash_transactions_on(:date)`.  
- **Config**: `config/reports.php` define colores por sucursal/menu. Si no hay color, controllers usan fallback palettes.  
- **Exports**: ubicados en `app/Exports/Reports/*` (ej. `SalesMixExport`).  
- **Traits**: `App\Traits\Reports\ConfiguresReportConnection` asegura `search_path` correcto.

## 4. Vistas y componentes

- Todas las vistas (`resources/views/reports/...`) extienden `layouts.terrena`.  
- Se reutilizan componentes documentados en `docs/V4.0/Frontend/Componentes.md` (por ejemplo `<x-ui.compact-multi-select>` en `/reports/sales/mix`).  
- Cada vista incluye filtros (rangos de fecha, sucursal, severidad) y enlaces a exportes.  
- Breadcrumbs y KPIs se definen inline; hay CSS específico en cada vista (pendiente consolidarlo en assets comunes).

## 5. APIs públicas (JSON)

La mayoría de controladores exponen versión JSON para consumo de dashboards:

| Endpoint | Respuesta | Notas |
|----------|-----------|-------|
| `GET /reports/sales/mix` con `Accept: application/json` (o `SalesMixController@index`) | Totales por forma de pago (ver doc V10). |
| `GET /reports/sales/drawer?severity=CRITICAL` | Diferencias cajón vs efectivo. |
| `GET /reports/sales/diagnostics` | Conteo por severidad/vista. |
| `GET /reports/sales/mods` | Combinaciones ítems + modificadores. |
| Otros controllers tienen acciones `index()` para JSON (consultar cada archivo). |

Para acceso programático se usa Sanctum (`/session/api-token` en layout). Asegurar que los tokens tengan `reports.view`.

## 6. Reportes incluidos (resumen funcional)

| Reporte | Objetivo | Fuente SQL | Vista |
|---------|----------|------------|-------|
| Mix de ventas | Distribución por forma de pago y sucursal. | `f_sales_mix_payment_on` | `resources/views/reports/sales/mix.blade.php` |
| Cajón vs efectivo | Diferencias POS vs corte caja. | `f_diag_drawer_vs_cash_transactions_on` | `reports/sales/drawer.blade.php` |
| Diagnósticos diarios | Vista de chequeos (INFO/WARN/CRITICAL). | `f_daily_diagnostics_summary_on` | `reports/sales/diagnostics.blade.php` |
| Ítems + Modificadores | Ranking de mods e ingresos adicionales. | `f_item_mods_on` | `reports/sales/mods.blade.php` |
| Detalle, resumen, balance, excepciones, journal | Equivalentes Jasper (consultar controller). | Vistas `reports/sales/*.blade.php` | Layouts listos, datos reales en progreso. |
| Menu usage / Tickets abiertos | Métricas operativas complementarias. | Vistas dedicadas + PDF export. |

Para ejemplos de payload ver `docs/Reports/README_REPORTES_ERP_V10.md`.

## 7. Riesgos y pendientes

1. **Fuentes SQL**: las funciones `f_*` se mencionan en los docs; validar que existan en `public` y que la conexión `pgsql` tenga permisos.  
2. **Colores/branding**: varios colores están hardcodeados en las vistas; moverlos a `config/reports.php` o al design system.  
3. **Permisos granulares**: hoy todo `/reports` depende de `reports.view`. Si se requieren restricciones por reporte, agregar permisos específicos (`reports.sales.mix`, etc.) y actualizar el middleware.  
4. **Performance**: funciones que generan series por día (`generate_series`) deben cuidarse en rangos grandes; considerar límites o caching si se exponen a usuarios finales.  
5. **PDF/Excel**: asegúrate de que las rutas `export` comprueben permisos y validen parámetros (strings, listas de sucursales) para evitar abusos.

## 8. Checklist de modificación

- [ ] Confirmaste la función/vista SQL en la base real (`172.24.240.1` desde WSL).  
- [ ] Cualquier controlador nuevo hereda de `BaseReportController` y respeta los filtros documentados.  
- [ ] Actualizaste la vista correspondiente y usaste componentes/documentación del design system.  
- [ ] Exportes (XLSX/PDF) tienen rutas y permisos definidos.  
- [ ] Este archivo y `docs/Reports/README_REPORTES_ERP_V10.md` se actualizaron con la descripción del nuevo reporte o cambio.
