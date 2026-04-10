# Módulo de Reportes
> Actualizado: Abril 2026

## Reportes Disponibles

### Reportes de Ventas (FloreantPOS → Laravel)

| Reporte | Ruta Web | API | Descripción |
|---------|---------|-----|------------|
| Sales Summary | `/reports/sales` | GET `/api/reports/sales/summary` | Resumen de ventas por período |
| Sales Mix | `/reports/sales/mix` | GET `/api/reports/sales/mix` | Distribución por producto/categoría |
| Drawer Pull | `/reports/sales/drawer` | GET `/api/reports/sales/drawer` | Reporte de cierre de cajón |
| Sales Exceptions | `/reports/sales/diagnostics` | GET `/api/reports/sales/diagnostics` | Descuentos, anulaciones, reembolsos |
| Sales Mods | `/reports/sales/mods` | GET `/api/reports/sales/mods` | Reporte de modificadores |
| Menu Usage | `/reports/menu/usage` | GET `/api/reports/menu/usage` | Uso del menú por producto |
| Open Tickets | `/reports/tickets/open` | GET `/api/reports/tickets/open` | Tickets abiertos sin cerrar |
| Products | `/reports/sales/products` | — | Reporte por producto |

### Reportes de KPIs

| KPI | Endpoint |
|-----|---------|
| KPIs por sucursal | GET `/api/reports/kpis/sucursal` |
| KPIs por terminal | GET `/api/reports/kpis/terminal` |
| Ventas por familia | GET `/api/reports/ventas/familia` |
| Ventas por hora | GET `/api/reports/ventas/hora` |
| Top productos | GET `/api/reports/ventas/top` |
| Ticket promedio | GET `/api/reports/ticket/promedio` |

### Reportes de Inventario/Compras

| Reporte | Endpoint |
|---------|---------|
| OC tardías | GET `/api/reports/purchasing/late-po` |
| Stock fuera de tolerancia | GET `/api/reports/inventory/over-tolerance` |
| Ítems urgentes | GET `/api/reports/inventory/top-urgent` |

---

## Servicios de Reportes

| Servicio | Líneas | Descripción |
|----------|--------|------------|
| ItemModsReportService | 1,056 | Reporte de modificadores (el más complejo) |
| SalesExceptionsReportService | 955 | Descuentos, anulaciones, reembolsos |
| ProductsReportService | 405 | Ventas por producto |
| ReportExportService | 281 | Exportación PDF/XLSX |
| MenuEngineeringService | 162 | Análisis de ingeniería de menú |

---

## Exportación

Todos los reportes de ventas soportan exportación:
- PDF: rutas con sufijo `/pdf`
- XLSX: rutas con sufijo `/xlsx`
- Usa DomPDF para PDF y Maatwebsite Excel para XLSX

---

## Acceso

Middleware: `auth:sanctum + permission:reports.view`

El reporte de modificadores y drawer pull requieren sincronización con FloreantPOS activa.

---

## Bug en Reporte de Descuentos (Drawer Pull / Exceptions)

Ver `04_MODULOS/CAJA.md` — sección "Bug Crítico: Descuentos en Reportes".

El bug afecta directamente:
- Drawer Pull Report: muestra suma de porcentajes en lugar de montos
- Sales Exceptions: mismo problema con descuentos aplicados

---

## Dashboard Ejecutivo (Pendiente)

El dashboard principal (`/dashboard`) necesita:
- Tablas `daily_sales_summary` y `daily_kpi_summary` (pendientes de crear)
- Job de cierre diario para poblarlas (`DailyCloseService` existe)
- Componente Livewire de visualización
