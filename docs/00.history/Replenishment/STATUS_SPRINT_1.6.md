# 🧭 STATUS SPRINT 1.6 – Transferencias Internas

Estado general: 🟨 En progreso  
Fecha: 2025-10-26

## 1. Rutas expuestas (Laravel)
- POST /api/inventory/transfers/create -> Inventory\TransferController@create
- POST /api/inventory/transfers/{transfer_id}/approve -> Inventory\TransferController@approve
- POST /api/inventory/transfers/{transfer_id}/ship -> Inventory\TransferController@ship
- POST /api/inventory/transfers/{transfer_id}/receive -> Inventory\TransferController@receive
- POST /api/inventory/transfers/{transfer_id}/post -> Inventory\TransferController@post

## 2. Backend
- `TransferService` implementa stubs para creación, aprobación, tránsito, recepción y posteo dual (TRANSFER_OUT/IN), con validación básica de IDs y conteo de líneas recibidas.
- `TransferController` inyecta el servicio, normaliza payloads (`lines`) y responde `{ok, data, message}`; cada acción ya incluye `TODO` de autorización `inventory.transfers.*`.
- Rutas viven bajo `/api/inventory/transfers`, alineadas al flujo `SOLICITADA → CERRADA`.

## 3. Pendiente para cerrar sprint
- Persistir cabecera/detalle de transferencias y el tracking logístico (transportista, guía).
- Generar movimientos `mov_inv` negativos/positivos y bloquear edición tras postear.
- Validar inventario disponible en origen antes de aprobar/enviar.

## 4. Riesgos / Bloqueantes
- Requiere catálogos de almacenes sincronizados entre sucursales.
- Si no se controla inventario disponible, se pueden autorizar transferencias sin stock real.
- Falta de policies y auditoría podría permitir movimientos no autorizados.

## 5. Siguiente paso inmediato
Persistir estados y detalle en `TransferService::createTransfer()` y `approveTransfer()` apuntando a tablas `transfer_cab/transfer_det`.
