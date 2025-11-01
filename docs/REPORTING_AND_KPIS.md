# Política de Reportes y KPIs
Versión: 2025-10-27  
Estado: ACTIVO / OBLIGATORIO

## KPIs diarios por sucursal en `selemti`
- `venta_neta_total`
- `costo_teorico_total`
- `costo_real_total`
- `merma_valorada_total`
- `margen_bruto_pct`
- `top5_productos` con % margen
- `notas_operativas` (comentarios del gerente)

## Persistencia
- Usar tablas resumen `daily_sales_summary`, `daily_kpi_summary` (plan).  
- Generar procesos diarios (job ETL) para poblar datos.

## Exportación
- Todos los KPIs deben poder exportarse a Excel/CSV.  
- Integrar con panel gerencial (ver `docs/Produccion/PRODUMIX.md`, `docs/Produccion/PRODUCTION_FLOW.md`).

## Visibilidad
- Gerente de Sucursal: sólo ve su sucursal.  
- Dirección: acceso global.  
- Requiere permisos `can_view_recipe_dashboard` y `can_manage_produmix` según sección rol.

## Auditoría
- Cada consulta/exportación debe registrar user_id, timestamp y reporte generado (futuro).
- Enlazar con `docs/AUDIT_LOG_POLICY.md`.

## Actualizaciones Recientes
- 2025-12-06: se liberó el dashboard operativo (`docs/REPORTING_AND_KPIS_DASHBOARD_WEEK6.md`) con Livewire + Chart.js, exportación CSV/PDF y favoritos por usuario. Todos los KPIs listados arriba están cubiertos parcialmente; restan márgenes y notas operativas para fase 2.
