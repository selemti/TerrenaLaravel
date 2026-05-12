# Backlog Técnico: Fase 1 - Saneamiento de Ingresos (SSOT)

## Tarea 1: Auditoría y Aislamiento (Paso 1 - COMPLETADO)
- [x] Mapear usos de `ticket.total_discount` en `app/`.
- [x] Mapear usos de `ticket.total_discount` en `resources/views`.
- [x] Identificar lógica de cálculo manual de descuentos en Services (`app/Services/Reports`).

## Tarea 2: Fuente de Verdad Paralela (Paso 2 - COMPLETADO)
- [x] **Sub-tarea 2.1:** Crear un `SalesResolutionService` que implemente el método `getNetLiquidation(ticket_id)`.
- [x] **Sub-tarea 2.2:** La lógica interna de este método debe usar `public.transactions` para obtener el flujo neta de dinero.
- [x] **Sub-tarea 2.3 (Normalización BUG-04):** Implementar dentro del Service la lógica que detecta si un descuento del 100% en `ticket_discount` / `coupon_and_discount` es porcentual para forzar el neto a 0.00.

## Tarea 3: Dashboard de Validación (Paso 3 - COMPLETADO)
- [x] **Sub-tarea 3.1:** Crear un comando Artisan `audit:canonical-sales` que recorra los tickets del día y compare el `total_price - total_discount` (Legacy) vs `SalesResolutionService::getNetLiquidation` (Canon).
- [x] **Sub-tarea 3.2:** Reportar desviaciones en una tabla de consola, marcando los casos donde el canon corrigió al legacy.

## Tarea 4: Switch-over Controlado (Paso 4 - EN PROGRESO)
- [x] **Sub-tarea 4.1:** Intervenir `app/Traits/Reports/ConfiguresReportConnection.php` para inyectar un toggle de "Modo Canon".
- [x] **Sub-tarea 4.2A (Lectura):** Migrar reportes administrativos (`SalesSummaryController`, `SalesExceptionsReportService`, `ProductsReportService`).
- [x] **Sub-tarea 4.2B (Operación):** Migrar `CajaController` y `TicketManagementController`.
- [ ] **Sub-tarea 4.3:** Validación final en entorno Staging con data real sincronizada e inyección de `?mode=canon`.

## Tarea 5: Limpieza Social (Pase final)
- [ ] Marcar columnas legacy como `@deprecated` en los modelos Eloquent.
- [ ] Documentar en el manual técnico el nuevo flujo de resolución de ventas.
