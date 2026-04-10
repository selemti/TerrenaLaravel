# Módulo de Caja — Precorte / Postcorte / Conciliación
> Actualizado: Abril 2026

## Flujo General

```
Apertura sesión (SesionCajon)
        │
        ▼
Ventas en FloreantPOS (tickets, transacciones)
        │
        ▼
Precorte — totales por forma de pago del sistema
        │
        ├── Cajero declara montos físicos
        │
        ▼
Postcorte — comparación sistema vs declarado
        │
        ▼
Conciliación — diferencias, alertas, aprobación
```

---

## Tablas Involucradas

| Tabla | Schema | Descripción |
|-------|--------|------------|
| `drawer_assigned_history` | public | Asignación de cajones por turno |
| `transactions` | public | Pagos registrados en POS |
| `ticket` | public | Comandas/cierres |
| `coupon_and_discount` | public | Descuentos configurados ⚠️ |
| `sesion_cajon` | selemti | Sesión activa de cajón |
| `precorte` | selemti | Resumen pre-cierre |
| `postcorte` | selemti | Corte oficial |
| `formas_pago` | selemti | Catálogo formas de pago |

---

## Servicios

| Servicio | Archivo | Estado |
|----------|---------|--------|
| PrecorteService | `Services/Caja/PrecorteService.php` | ✅ |
| PostcorteService | `Services/Caja/PostcorteService.php` | ✅ |
| AlertasService | `Services/Caja/AlertasService.php` | ✅ |
| AnalyticsService | `Services/Caja/AnalyticsService.php` | ✅ |
| ConciliacionController | `Controllers/Api/Caja/ConciliacionController.php` | ✅ |

---

## Alertas del Sistema (AlertasService)

El módulo genera alertas automáticas para:
- Tickets abiertos sin cerrar
- Descuentos al 100%
- Anulaciones (voids)
- Reembolsos
- Diferencias entre sistema y declarado

---

## Bug Crítico: Descuentos en Reportes

**Problema:** El reporte Drawer Pull muestra el valor "100" por cada descuento aplicado, en lugar del monto real descontado del ticket.

**Causa raíz:**
- `coupon_and_discount.value` = porcentaje del descuento (ej. `100` para "100% off")
- `DrawerpullReportService.java:146` suma `discount2.getValue()` — esto suma el **porcentaje**, no el monto
- La columna correcta es `ticket.total_discount` (monto real ya calculado por Floreant)

**Fix pendiente:**
```java
// ANTES (incorrecto):
totalDiscountAmount += discount2.getValue();

// DESPUÉS (correcto):
totalDiscountAmount += ticket.getTotalDiscount();
```

Mismo patrón en `SalesExceptionReport.java:78`:
```java
// ANTES:
discountData.totalDiscount = discountData.totalDiscount + discount.getValue();
// DESPUÉS:
discountData.totalDiscount += ticket.getTotalDiscount();
```

---

## Bug Crítico: Postcorte con Campos NULL

**Problema:** `selemti.postcorte.total_ventas_brutas`, `total_descuentos_drawer`, `total_descuentos_reales` siempre son NULL.

**Causa:** El trigger `fn_postcorte_after_insert` no está calculando los valores correctamente.

**Fix pendiente:** Revisar y corregir el trigger en PostgreSQL. Las fuentes correctas son:
- `total_ventas_brutas` ← SUM de `transactions.amount` en el período de la sesión
- `total_descuentos_drawer` ← SUM de `ticket.total_discount` donde hay descuento Drawer Pull
- `total_descuentos_reales` ← SUM de `ticket.total_discount` de todos los tickets con descuento

---

## Vistas SQL de Precorte (Fuente: D:\Tavo\2025\UX\Cortes\V5\)

Las vistas de conciliación están definidas en SQL y deben existir en el schema `selemti`:
- `v_precorte_pagos` — totales por forma de pago del sistema
- `v_precorte_sistema` — resumen sistema
- `v_precorte_tarjetas` — detalle de tarjetas
- `v_precorte_custom_payments` — pagos personalizados
- `v_precorte_alertas` — alertas operativas
- `v_precorte_tickets_abiertos` — tickets sin cerrar

**SQL de referencia:** `D:\Tavo\2025\UX\Cortes\V5\precorte_pack_final_v3_consolidated_perfect_v16.sql` (última versión)

---

## Auth pendiente

Las rutas `/api/caja/*` tienen el middleware `auth:sanctum` **deshabilitado**.
Reactivar antes de ir a producción en `routes/api.php`.
