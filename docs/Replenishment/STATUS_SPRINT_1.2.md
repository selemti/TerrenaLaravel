# 🧭 STATUS SPRINT 1.2 – Recepciones de Compra & Kardex

**Objetivo:**  
Registrar recepciones físicas de material comprado, validarlas y postearlas a `mov_inv` (Kardex) como movimientos INMUTABLES tipo `COMPRA`.  
Después de este sprint, el sistema ya "mete inventario real" cuando llega mercancía.

**Estado general:** ⬜ No iniciado  
**Fecha de arranque:** 2025-10-25  
**Contexto:** Sprint 1.1 (Sugerencias → Solicitud) está implementado a nivel código y API, pendiente solo la prueba operativa con datos reales (items/proveedores). No queremos bloquear 1.2 por eso.

---

## 🔄 Flujo que cubre este sprint

1. Existe una orden de compra (purchase_order) aprobada / enviada al proveedor.
2. El proveedor entrega físicamente mercancía en un almacén destino.
3. El almacenista crea una Recepción:
   - Cabecera (`recepcion_cab`): proveedor, almacén, fecha, referencia de PO.
   - Detalle (`recepcion_det`): item_id, qty_recibida, qty_ordenada, costo_unitario, uom.
   - Estado inicial: `EN_PROCESO`.
4. Se confirman cantidades → estado `VALIDADA`.
5. Se postea → estado `POSTEADA_A_INVENTARIO`.
   - Aquí se generan renglones en `selemti.mov_inv` con tipo `COMPRA`.
   - Esos renglones NO se editan ni se borran.
6. Recepción queda `CERRADA`.
7. Si hubo diferencias por arriba de la tolerancia configurada (`config('inventory.reception_tolerance_pct')`), se marca para revisión / aprobación adicional.

---

## 🧩 Alcance técnico Sprint 1.2

1. **Service nuevo:**  
   `app/Services/Inventory/ReceivingService.php`  
   Debe exponer (mínimo):
   - `createDraftReception($purchaseOrderId, $userId)`  
     Crea recepción EN_PROCESO a partir de una purchase_order.
   - `updateReceptionLines($recepcionId, [...lineItems...])`  
     Captura cantidades reales recibidas por item.
   - `validateReception($recepcionId, $userId)`  
     Pasa a VALIDADA.
   - `postToInventory($recepcionId, $userId)`  
     Genera `mov_inv` con tipo `COMPRA`, llena costos, cambia a POSTEADA_A_INVENTARIO y luego CERRADA.

   Nota: `postToInventory` es crítico. Este método es el que mete el inventario físicamente al sistema.

2. **Controlador API nuevo:**  
   `app/Http/Controllers/Purchasing/ReceivingController.php`  
   Endpoints REST (todas bajo `/api/purchasing/receptions`):
   - `POST /create-from-po/{purchase_order_id}`
   - `POST /{recepcion_id}/lines` (captura/actualiza cantidades físicas)
   - `POST /{recepcion_id}/validate`
   - `POST /{recepcion_id}/post` (esta hace el Kardex / mov_inv)
   Estos endpoints trabajan SOLO con recepción de compra. Transferencias y producción van en otros sprints.

3. **Rutas:**  
   Agregar en `routes/api.php` dentro del grupo `Route::prefix('purchasing')`:
   ```php
   Route::prefix('receptions')->group(function () {
       Route::post('/create-from-po/{purchase_order_id}', [ReceivingController::class, 'createFromPO']);
       Route::post('/{recepcion_id}/lines', [ReceivingController::class, 'setLines']);
       Route::post('/{recepcion_id}/validate', [ReceivingController::class, 'validateReception']);
       Route::post('/{recepcion_id}/post', [ReceivingController::class, 'postReception']);
   });
