### 3. `docs/Replenishment/STATUS_SPRINT_1.5.md`

```md
# 🧭 STATUS SPRINT 1.5 – Devoluciones a Proveedor

**Objetivo:** Poder devolver material al proveedor después de la recepción, generar salida de inventario y documentar nota de crédito.  
**Estado general:** 📋 Planificado  
**Fecha:** 2025-10-25  
**Esquema BD:** `selemti`

---

## 1. Punto de partida
- Ya tenemos recepción posteada a inventario (entrada tipo COMPRA).
- Falta el flujo inverso: devolver parte del material al proveedor.

---

## 2. Reglas de negocio

### 2.1 Estados de devolución
`BORRADOR → APROBADA → EN_TRANSITO → RECIBIDA_PROVEEDOR → NOTA_CREDITO → CERRADA`

### 2.2 Impacto inventario
- Mientras está `EN_TRANSITO` no tocamos inventario.
- Cuando el proveedor confirma `RECIBIDA_PROVEEDOR`:
  - generar `mov_inv` con `qty` NEGATIVA
  - `tipo_mov = 'DEVOLUCION_PROVEEDOR'`
  - inmutable (misma regla que recepción posteada)

### 2.3 Nota de crédito
- En estado `NOTA_CREDITO`:
  - capturar `folio_nota_credito`, `monto`, `fecha`
  - esta info va directo a conciliación con proveedor

---

## 3. Trabajo técnico Sprint 1.5

### 3.1 Nuevo servicio:
`app/Services/Purchasing/ReturnService.php`

Métodos stub (solo firmas + phpdoc + TODO, sin SQL real):
```php
createDraftReturn(int $purchaseOrderId, int $userId): array
approveReturn(int $returnId, int $userId): array
markShipped(int $returnId, array $trackingInfo, int $userId): array
confirmVendorReceived(int $returnId, int $userId): array
postInventoryAdjustment(int $returnId, int $userId): array // genera mov_inv negativo
attachCreditNote(int $returnId, array $notaCreditoData, int $userId): array
3.2 Nuevo controlador:
app/Http/Controllers/Purchasing/ReturnController.php

Acciones REST que llamen cada método del servicio y devuelvan { ok, data, message }.
Debe tener // TODO autorización con permisos del tipo:

purchasing.returns.create

purchasing.returns.approve

purchasing.returns.post

purchasing.returns.credit_note

3.3 Rutas
Bajo:
/api/purchasing/returns/...

Ejemplos:

POST /api/purchasing/returns/create-from-po/{purchase_order_id}

POST /api/purchasing/returns/{return_id}/approve

POST /api/purchasing/returns/{return_id}/ship

POST /api/purchasing/returns/{return_id}/confirm

POST /api/purchasing/returns/{return_id}/post

POST /api/purchasing/returns/{return_id}/credit-note

4. Criterio de cierre Sprint 1.5
Servicio ReturnService creado con TODOS los métodos stub.

Controlador ReturnController creado.

Rutas registradas.

TODAVÍA SIN lógica de negocio real (solo documentación, parámetros, y placeholders).