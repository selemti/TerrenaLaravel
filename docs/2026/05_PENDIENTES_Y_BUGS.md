# Pendientes y Bugs — TerrenaLaravel
> Actualizado: Abril 2026 | Rama: work/inicio-limpio-abril-2026

## Bugs Críticos (bloquean operación)

### BUG-01: Descuentos en Reportes FloreantPOS
- **Prioridad:** 🔴 CRÍTICO
- **Archivos:** 
  - `FloreantPOS 1.5/.../DrawerpullReportService.java:146`
  - `FloreantPOS 1.5/.../SalesExceptionReport.java:78`
- **Síntoma:** Drawer Pull Report muestra "100" por cada descuento en lugar del monto real
- **Causa:** `discount.getValue()` retorna el porcentaje, no el monto. Usar `ticket.getTotalDiscount()`
- **Impacto:** Cortes de caja no cuadran, reportes gerenciales incorrectos

### BUG-02: Postcorte — Campos NULL
- **Prioridad:** 🔴 CRÍTICO
- **Tabla:** `selemti.postcorte`
- **Campos:** `total_ventas_brutas`, `total_descuentos_drawer`, `total_descuentos_reales`
- **Causa:** Trigger `fn_postcorte_after_insert` no calcula los valores
- **Impacto:** Conciliación incompleta, imposible cuadrar cortes

### BUG-03: Auth deshabilitado en `/api/caja/*`
- **Prioridad:** 🔴 CRÍTICO (seguridad)
- **Archivo:** `routes/api.php` — grupo `/api/caja/`
- **Causa:** Middleware `auth:sanctum` removido durante desarrollo
- **Fix:** Reactivar antes de producción

---

## Funcionalidades Faltantes

### FEAT-01: UI del Módulo de Producción
- **Prioridad:** 🟡 ALTA
- **Estado:** API completa (`/api/production/batch/*`), sin frontend
- **Necesario:** 4 componentes Livewire:
  - `ProductionOrdersIndex` — lista de órdenes
  - `ProductionOrderCreate` — crear/planear lote
  - `ProductionOrderDetail` — ver detalle
  - `ProductionOrderCapture` — capturar producción real
- **Carpeta destino:** `app/Livewire/Production/`

### FEAT-02: UI de Kardex
- **Prioridad:** 🟡 ALTA
- **Estado:** API `GET /api/inventory/items/{id}/kardex` funciona, sin vista
- **Necesario:** Componente `app/Livewire/Inventory/KardexView.php` + vista blade

### FEAT-03: Dashboard Ejecutivo con KPIs diarios
- **Prioridad:** 🟡 MEDIA
- **Estado:** `DailyCloseService` existe, tablas resumen no creadas
- **Necesario:**
  - Migración para `daily_sales_summary` y `daily_kpi_summary`
  - Job que las pueble en cierre nocturno
  - Componente dashboard con gráficas (ventas vs costo vs margen)

### FEAT-04: Dashboard de Stock Visual
- **Prioridad:** 🟡 MEDIA
- **Estado:** API de stock funciona, sin vista consolidada
- **Necesario:** Vista con niveles de stock, alertas, brechas vs punto de reorden

---

## Deuda Técnica

### DEBT-01: Modelos Duplicados
- **Prioridad:** 🟢 BAJA
- `app/Models/Inv/Item.php` vs `app/Models/Inventory/Item.php`
- `app/Models/Caja/Postcorte.php` vs `app/Models/Core/PostCorte.php`
- `app/Models/Caja/SesionCajon.php` vs `app/Models/Core/SesionCaja.php`
- **Acción:** Consolidar en los namespaces nuevos, deprecar los de `Inv/` y `Core/`

### DEBT-02: PosConsumptionService en 3 Namespaces
- **Prioridad:** 🟢 BAJA
- `Services/Pos/PosConsumptionService.php` (461L — principal)
- `Services/Inventory/PosConsumptionService.php` (51L — thin wrapper)
- `Services/Operations/PosConsumptionService.php` (107L — wrapper de operaciones)
- **Acción:** Consolidar en uno solo, eliminar wrappers redundantes

### DEBT-03: Modelos de Compras en Raíz y Subcarpeta
- `app/Models/PurchaseOrder.php` (raíz) vs `app/Models/Purchasing/PurchaseRequest.php` (subcarpeta)
- **Acción:** Mover todos a `app/Models/Purchasing/`

### DEBT-04: Rutas Legacy
- `routes/api.php` contiene grupo `/api/legacy/*` con endpoints PHP-style
- **Acción:** Documentar dependientes y eliminar cuando no haya referencias

### DEBT-05: AuditLogService incompleto
- `app/Services/Audit/AuditLogService.php` — solo 39 líneas, scaffolding básico
- **Acción:** Implementar o usar el AuditLog model directamente

---

## Tests Faltantes

| Módulo | Estado |
|--------|--------|
| ReceivingService | ❌ sin tests |
| TransferService | ❌ sin tests |
| ProductionService | ❌ sin tests |
| ReturnService | ❌ sin tests |
| PrecorteService | ❌ sin tests |
| Reportes (parcial) | ⚠️ algunos tests |

---

## Orden de Trabajo Recomendado

| # | Tarea | Impacto | Esfuerzo |
|---|-------|---------|---------|
| 1 | BUG-01: Fix descuentos Java | Alto | Bajo (2 líneas) |
| 2 | BUG-02: Fix trigger postcorte | Alto | Medio (SQL) |
| 3 | BUG-03: Reactivar auth sanctum | Alto (seguridad) | Bajo (1 línea) |
| 4 | FEAT-01: UI Producción | Medio | Alto (4 componentes) |
| 5 | FEAT-02: UI Kardex | Medio | Bajo (1 componente) |
| 6 | FEAT-03: Dashboard KPIs | Medio | Medio |
| 7 | FEAT-04: Stock Dashboard | Medio | Medio |
| 8 | DEBT-01: Consolidar modelos | Bajo | Medio |
| 9 | DEBT-02: Consolidar PosConsumption | Bajo | Bajo |
