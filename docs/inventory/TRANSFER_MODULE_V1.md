# Transferencias entre Almacenes - Backend v1.0

## Estados del Flujo
`SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA (+ CANCELADA)`

| Estado | Acción | Responsable | Comentarios |
|--------|--------|-------------|-------------|
| SOLICITADA | Crear transferencia | Creador (almacén origen) | Requiere líneas con `cantidad_solicitada` > 0 |
| APROBADA | Aprobar y reservar stock | Supervisor origen | Valida stock en `mov_inv` antes de aprobar |
| EN_TRANSITO | Despachar | Operador origen | Registra `guia` y `cantidad_despachada` |
| RECIBIDA | Registrar recepción | Operador destino | Permite variaciones por línea + observaciones |
| POSTEADA | Postear a inventario | Supervisor destino | Inserta movimientos `TRANSFER_OUT`/`TRANSFER_IN` |
| CANCELADA | Cancelar | Supervisor | No se implementó en esta iteración |

## Tablas Involucradas
- `selemti.transfer_cab`: cabecera (almacenes, usuarios, timestamps, estado).
- `selemti.transfer_det`: líneas con cantidades solicitadas/despachadas/recibidas.
- `selemti.mov_inv`: kardex donde se postean las transferencias.

## Artefactos Backend
- Modelos: `App\Models\Inventory\TransferHeader`, `TransferLine`.
- Migration: `2025_11_01_090000_complete_transfer_tables.php` (columnas, índices, constraint de estado).
- Servicio: `App\Services\Inventory\TransferService`.
- Controlador API: `App\Http\Controllers\Api\Inventory\TransferController`.
- Rutas: `routes/api.php` (`/api/inventory/transfers`).

## Métodos del Servicio
| Método | Entrada | Salida | Notas |
|--------|---------|--------|-------|
| `createTransfer($from, $to, $lines, $user)` | IDs de almacén, líneas | `['transfer_id' => int, 'status' => 'SOLICITADA']` | Valida origen ≠ destino y existencia de ítems |
| `approveTransfer($id, $user)` | Transferencia | Estado `APROBADA` | Revisa stock (`getStockDisponible`) |
| `markInTransit($id, $user, $guia)` | Transferencia | Estado `EN_TRANSITO` | Copia `cantidad_solicitada` → `cantidad_despachada` |
| `receiveTransfer($id, $receivedLines, $user)` | Transferencia | Estado `RECIBIDA` | Permite variaciones + observaciones |
| `postTransferToInventory($id, $user)` | Transferencia | Estado `POSTEADA` | Inserta dos movimientos por línea |

## Endpoints API
| Método | Ruta | Estado Requerido | Descripción |
|--------|------|------------------|-------------|
| POST | `/api/inventory/transfers` | - | Crear transferencia |
| POST | `/api/inventory/transfers/{id}/approve` | SOLICITADA | Aprobar y reservar |
| POST | `/api/inventory/transfers/{id}/ship` | APROBADA | Marcar en tránsito |
| POST | `/api/inventory/transfers/{id}/receive` | EN_TRANSITO | Registrar recepción |
| POST | `/api/inventory/transfers/{id}/post` | RECIBIDA | Postear a inventario |

## Tests Clave
- `tests/Feature/TransferServiceTest.php`: creación, stock insuficiente, transit, recepción, posting, estados inválidos.
- `tests/Feature/Inventory/PriceApiAuthTest.php`: autorización granular (usa `hasPermissionTo`).

## Pendientes
- Cancelación y reintentos parciales.
- UI para aprobar/despachar/recibir (coordinado con Livewire semana 2).
- Métricas de SLA (tiempo entre estados) en dashboard de inventario.

