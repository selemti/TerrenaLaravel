### 4. `docs/Replenishment/STATUS_SPRINT_1.6.md`

```md
# 🧭 STATUS SPRINT 1.6 – Transferencias Internas

**Objetivo:** Mover inventario entre sucursales / almacenes internos con trazabilidad y autorización.  
**Estado general:** 📋 Planificado  
**Fecha:** 2025-10-25  
**Esquema BD:** `selemti`

---

## 1. Flujo operativo
1. Sucursal A solicita traslado a Sucursal B.
2. Almacén central prepara envío.
3. Sucursal B recibe físicamente y confirma cantidades.
4. El sistema genera:
   - `mov_inv` NEGATIVO en origen (`tipo_mov='TRANSFER_OUT'`)
   - `mov_inv` POSITIVO en destino (`tipo_mov='TRANSFER_IN'`)

Estados:
`SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → CERRADA`

---

## 2. Permisos
- `inventory.transfers.create`
- `inventory.transfers.approve`
- `inventory.transfers.ship`
- `inventory.transfers.receive`
- `inventory.transfers.post`

---

## 3. Trabajo técnico Sprint 1.6

### 3.1 Nuevo servicio:
`app/Services/Inventory/TransferService.php`

Métodos stub esperados:
```php
createTransfer(int $fromAlmacenId, int $toAlmacenId, array $lines, int $userId): array
approveTransfer(int $transferId, int $userId): array
markInTransit(int $transferId, int $userId): array
receiveTransfer(int $transferId, array $receivedLines, int $userId): array
postTransferToInventory(int $transferId, int $userId): array // genera mov_inv +/- en ambos lados
3.2 Nuevo controlador:
app/Http/Controllers/Inventory/TransferController.php

Acciones REST para cada método del servicio, respuestas { ok, data, message }, y comentarios // TODO autorización con los permisos de arriba.

3.3 Rutas
Bajo /api/inventory/transfers/...

Ejemplos:

POST /api/inventory/transfers/create

POST /api/inventory/transfers/{transfer_id}/approve

POST /api/inventory/transfers/{transfer_id}/ship

POST /api/inventory/transfers/{transfer_id}/receive

POST /api/inventory/transfers/{transfer_id}/post

4. Criterio de cierre Sprint 1.6
TransferService creado con stubs.

TransferController creado.

Rutas creadas.

Sin lógica real de inventario aún (solo TODOs).