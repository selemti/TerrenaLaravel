# Sprint Recetas 1.2 - Dashboard de Control y Alertas

*Versión 1.0 — Octubre 2025*

## 🎯 Objetivo
Proporcionar al equipo de Costos y Operaciones una herramienta centralizada para monitorear la salud del sistema de recetas, identificar problemas de mapeo, gestionar el reprocesamiento de ventas y actuar sobre alertas críticas de inventario.

Este sprint se enfoca en la visibilidad y la capacidad de acción.

---

## 🛠️ Alcance Funcional

### 1.0 Dashboard de Mapeo POS ↔ Recetas

El dashboard será la pantalla principal y mostrará los siguientes indicadores clave (widgets):

-   **Widget 1: Estado del Mapeo de Productos**
    -   **Métrica Principal:** Porcentaje de `menu_items` activos que están correctamente mapeados a una receta.
    -   **Detalle:**
        -   Total de productos vendidos hoy.
        -   Número de productos vendidos sin receta.
        -   Lista de los 10 productos más vendidos sin receta (para priorizar el mapeo).
    -   **Acción:** Enlace directo para mapear los productos faltantes.

-   **Widget 2: Ventas Pendientes de Reproceso**
    -   **Métrica Principal:** Número total de `ticket_items` marcados con `requiere_reproceso = true`.
    -   **Detalle:**
        -   Agrupación por `menu_item`.
        -   Fecha de la venta más antigua y más reciente pendiente.
    -   **Acción:** Botón para iniciar el `ReprocessSalesJob` para los productos que ya han sido mapeados.

-   **Widget 3: Alertas del Sistema (`alert_events`)**
    -   **Métrica Principal:** Conteo de alertas abiertas por tipo.
    -   **Detalle:**
        -   `VENTA_SIN_RECETA`: Listado de ventas.
        -   `MODIFICADOR_SIN_RECETA`: Listado de modificadores.
        -   `STOCK_NEGATIVO_ERROR`: Alerta crítica si un reproceso o producción intenta llevar un insumo a stock negativo.
    -   **Acción:** Enlaces para resolver cada tipo de alerta (ej. "Mapear Receta", "Ver Lote Afectado").

---

## 2.0 Modelo de Datos / Tablas Involucradas

-   `menu_items`: Para identificar productos del POS.
-   `pos_map`: La tabla central del mapeo.
-   `ticket_items`: Para buscar ventas con `requiere_reproceso = true`.
-   `alert_events`: La fuente de datos para el widget de alertas.
-   `mov_inv`: Para rastrear el impacto de los reprocesos.
-   `inventory_batch`: Para verificar existencias antes de procesar.

---

## 3.0 Roles Operativos

-   **Analista de Costos:**
    -   Monitorea el dashboard diariamente.
    -   Responsable de mantener el porcentaje de mapeo > 99%.
    -   Ejecuta el reprocesamiento después de mapear productos.
    -   Investiga y resuelve alertas de stock.
-   **Gerente de Operaciones:**
    -   Supervisa los indicadores clave para asegurar la integridad del inventario.
    -   Utiliza la información para detectar problemas operativos (ej. un producto nuevo lanzado sin notificar a Costos).

> El botón **Reprocesar** solo está disponible para roles con permiso `can_reprocess_sales`. Caja y barista no tienen acceso a esta acción.

---

## 4.0 Entregables Sprint 1.2

-   **Livewire Component:** `RecipeControlDashboard.php`.
-   **Vista Blade:** `recipe-control-dashboard.blade.php`.
-   **Servicios de Backend:**
    -   `DashboardMetricsService`: Para calcular los KPIs.
    -   `AlertNotificationService`: Para agrupar y presentar las alertas.
-   **Ruta:** `/control/recetas` protegida por el permiso `view_recipe_dashboard`.
-   **Jobs:**
    -   `CheckUnmappedSalesJob` (ya definido, se asegura que alimente el dashboard).
    -   `ReprocessSalesJob` (ya definido, se invoca desde el dashboard).

*Versión 2.1 — Octubre 2025*