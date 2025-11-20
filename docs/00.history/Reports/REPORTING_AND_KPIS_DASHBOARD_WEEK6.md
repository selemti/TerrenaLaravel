# Dashboard de Reportes - Semana 6 (Diciembre 2025)

## Objetivo
Construir un tablero unificado con KPIs operativos, gráficas interactivas y exportaciones (CSV/PDF) para dirección y operaciones.

## Componentes Principales
- `app/Livewire/Reports/Dashboard.php`: KPIs, filtros y datasets para Chart.js.
- `app/Livewire/Reports/DrillDown.php`: navegación jerárquica (ticket → receta → insumos).
- `app/Models/Reports/ReportFavorite`: gestión de favoritos por usuario.
- `app/Services/Reports/ReportExportService`: generación de CSV (`StreamedResponse`) y PDF (DOMPDF pendiente para plantillas avanzadas).

## KPIs Calculados
1. Ventas Totales (POS `public.ticket`).
2. Producción Completada (`selemti.production_orders`).
3. Compras Recibidas (`selemti.recepcion_cab`).
4. Valor de Inventario (`selemti.vw_stock_valorizado`).
5. Merma Promedio (campo `merma_porcentaje`).
6. Costo Promedio de Recetas (`selemti.receta_cab`).
7. Rotación de Inventario (placeholder 45.5 días, pendiente fórmula final).
8. Eficiencia de Producción (produced/planned).

## Gráficas
| Tipo | Dataset | Fuente |
|------|---------|--------|
| Línea | Ventas por día | `public.ticket` (agrupado por fecha) |
| Barras horizontales | Top 10 productos vendidos | `public.ticket_item` |
| Pie | Mermas por categoría | `selemti.merma_log` |
| Barras | Stock por almacén | `selemti.vw_stock_valorizado` |
| Multi-línea | Costos por receta (últimos snapshots) | `selemti.recipe_cost_snapshots` |

## Exportaciones
- **CSV**: usa `response()->stream()` para escribir KPIs y datasets tabulares.
- **PDF**: pendiente integrar template Blade (`resources/views/reports/export.blade.php`).
- Acceso desde Dashboard: botones CSV/PDF en header.

## Favoritos
- Tabla `report_favorites` (user_id, slug, filtros, metadata, timestamps).
- Métodos Livewire: `toggleFavorite($slug)`, `isFavorite($slug)`.
- Almacena filtros seleccionados (dateRange, sucursal, etc.).

## Requisitos Técnicos
- Chart.js 4.x vía CDN.
- Bootstrap 5 para cards responsive.
- Tokens API en sesión (`session('api_token')`) para llamadas backend (si se requiere fetch desde front).

## Pendientes / Futuro
1. Completar PDF con layout corporativo.
2. KPI de productividad por sucursal.
3. Drill-down hasta insumo en inventario.
4. Integrar tiempo de respuesta promedio en Dashboard.
5. Programar cacheado (Redis) para KPIs pesados (>2s).

