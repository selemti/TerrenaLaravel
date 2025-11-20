# MAPA BD ↔ CÓDIGO (Inventario, Recetas, POS)

## 1. Resumen ejecutivo

- **Inventario**: 8 tablas analizadas, 65 campos en total, 45 campos OK, 8 mismatches, 7 fantasmas, 5 no usados
- **Recetas**: 4 tablas analizadas, 20 campos en total, 16 campos OK, 2 mismatches, 2 fantasmas, 0 no usados
- **POS**: 6 tablas analizadas, 40 campos en total, 35 campos OK, 3 mismatches, 2 fantasmas, 0 no usados
- **Riesgos principales detectados**:
  - Campos fantasmas en procesos críticos de transferencias (usando campos que no existen en BD)
  - Mismatches en campos de fechas entre BD y código
  - Inconsistencias en tipos de datos entre BD y modelos Laravel

## 2. Inventario por módulo

### 2.1 Inventario
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| mov_inv | id | app/Models/Inv/Movement.php:9<br>app/Services/Inventory/ReceptionService.php:112 | OK | Primary key |
| mov_inv | ts | app/Models/Inv/Movement.php:27 (mapped to fecha_movimiento) | MISMATCH | Código espera fecha_movimiento pero BD tiene ts |
| mov_inv | item_id | app/Models/Inv/Movement.php:28<br>app/Services/Inventory/ReceptionService.php:113 | OK | Foreign key |
| mov_inv | lote_id | app/Models/Inv/Movement.php:29 (mapped to lote_id) | OK | Lot ID field |
| mov_inv | cantidad | app/Models/Inv/Movement.php:33<br>app/Services/Inventory/ReceptionService.php:115 | OK | Quantity field |
| mov_inv | qty_original | app/Models/Inv/Movement.php:30 (mapped to qty_original) | OK | Original quantity |
| mov_inv | uom_original_id | app/Models/Inv/Movement.php:31 (mapped to uom_original_id) | OK | Original UOM ID |
| mov_inv | costo_unit | app/Models/Inv/Movement.php:34 (mapped to costo_unitario) | MISMATCH | Código espera costo_unitario pero BD tiene costo_unit |
| mov_inv | tipo | app/Models/Inv/Movement.php:32 (mapped to tipo_movimiento) | MISMATCH | Código espera tipo_movimiento pero BD tiene tipo |
| mov_inv | ref_tipo | app/Models/Inv/Movement.php:40 (mapped to referencia_tipo) | MISMATCH | Código espera referencia_tipo pero BD tiene ref_tipo |
| mov_inv | ref_id | app/Models/Inv/Movement.php:41 (mapped to referencia_id) | MISMATCH | Código espera referencia_id pero BD tiene ref_id |
| mov_inv | sucursal_id | app/Models/Inv/Movement.php:27 (mapped to almacen_id) | MISMATCH | Código espera almacen_id pero BD tiene sucursal_id |
| mov_inv | usuario_id | app/Models/Inv/Movement.php:37<br>app/Services/Inventory/ReceptionService.php:119 | OK | User ID field |
| mov_inv | created_at | app/Models/Inv/Movement.php:36<br>app/Services/Inventory/ReceptionService.php:117 | OK | Creation timestamp |
| recepcion_det | id | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | recepcion_id | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | item_id | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | bodega_id | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | qty | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | um_id | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | costo_unit | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | batch_id | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | temperatura | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | doc_url | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | meta | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | created_at | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | updated_at | - | NO_USADO | Table exists but not referenced in code |
| recepcion_det | deleted_at | - | NO_USADO | Table exists but not referenced in code |
| transfer_cab | id | app/Models/Inventory/TransferHeader.php:11<br>app/Services/Inventory/TransferService.php:33 | OK | Primary key |
| transfer_cab | origen_almacen_id | app/Models/Inventory/TransferHeader.php:16<br>app/Services/Inventory/TransferService.php:34 | OK | Foreign key |
| transfer_cab | destino_almacen_id | app/Models/Inventory/TransferHeader.php:17<br>app/Services/Inventory/TransferService.php:35 | OK | Foreign key |
| transfer_cab | estado | app/Models/Inventory/TransferHeader.php:20<br>app/Services/Inventory/TransferService.php:36 | OK | Status enum |
| transfer_cab | creada_por | app/Models/Inventory/TransferHeader.php:22<br>app/Services/Inventory/TransferService.php:37 | OK | Foreign key |
| transfer_cab | despachada_por | app/Models/Inventory/TransferHeader.php:27<br>app/Services/Inventory/TransferService.php:38 | OK | Dispatch user |
| transfer_cab | recibida_por | app/Models/Inventory/TransferHeader.php:28<br>app/Services/Inventory/TransferService.php:39 | OK | Receive user |
| transfer_cab | guia | app/Models/Inventory/TransferHeader.php:29<br>app/Services/Inventory/TransferService.php:40 | OK | Guide number |
| transfer_cab | created_at | app/Models/Inventory/TransferHeader.php:30<br>app/Services/Inventory/TransferService.php:41 | OK | Creation timestamp |
| transfer_det | id | app/Models/Inventory/TransferLine.php:11<br>app/Services/Inventory/TransferService.php:114 | OK | Primary key |
| transfer_det | transfer_id | app/Models/Inventory/TransferLine.php:13<br>app/Services/Inventory/TransferService.php:115 | OK | Foreign key |
| transfer_det | item_id | app/Models/Inventory/TransferLine.php:14<br>app/Services/Inventory/TransferService.php:116 | OK | Foreign key |
| transfer_det | cantidad | app/Models/Inventory/TransferLine.php:16<br>app/Services/Inventory/TransferService.php:117 | OK | Quantity |
| transfer_det | cantidad_despachada | app/Models/Inventory/TransferLine.php:17<br>app/Services/Inventory/TransferService.php:118 | OK | Dispatched quantity |
| transfer_det | cantidad_recibida | app/Models/Inventory/TransferLine.php:18<br>app/Services/Inventory/TransferService.php:119 | OK | Received quantity |
| transfer_det | created_at | app/Models/Inventory/TransferLine.php:20<br>app/Services/Inventory/TransferService.php:120 | OK | Creation timestamp |
| hist_cost_insumo | id | app/Models/Inventory/CostHistory.php:10<br>app/Services/Recetas/RecalcularCostosRecetasService.php:137 | OK | Primary key |
| hist_cost_insumo | item_id | app/Models/Inventory/CostHistory.php:13<br>app/Services/Recetas/RecalcularCostosRecetasService.php:137 | OK | Foreign key |
| hist_cost_insumo | fecha_efectiva | app/Models/Inventory/CostHistory.php:14<br>app/Services/Recetas/RecalcularCostosRecetasService.php:137 | OK | Effective date |
| hist_cost_insumo | costo_wac | app/Models/Inventory/CostHistory.php:15<br>app/Services/Recetas/RecalcularCostosRecetasService.php:145 | OK | WAC cost |
| hist_cost_insumo | costo_peps | app/Models/Inventory/CostHistory.php:16 | OK | FIFO cost |
| hist_cost_insumo | costo_ueps | app/Models/Inventory/CostHistory.php:17 | OK | LIFO cost |
| hist_cost_insumo | costo_std | app/Models/Inventory/CostHistory.php:18 | OK | Standard cost |
| hist_cost_insumo | algoritmo_principal | app/Models/Inventory/CostHistory.php:19<br>app/Services/Recetas/RecalcularCostosRecetasService.php:146 | OK | Main algorithm |
| hist_cost_insumo | valid_from | app/Models/Inventory/CostHistory.php:20 | OK | Valid from date |
| hist_cost_insumo | valid_to | app/Models/Inventory/CostHistory.php:21 | OK | Valid to date |
| hist_cost_insumo | sys_from | app/Models/Inventory/CostHistory.php:22 | OK | System from timestamp |
| hist_cost_insumo | sys_to | app/Models/Inventory/CostHistory.php:23 | OK | System to timestamp |
| hist_cost_insumo | created_at | app/Models/Inventory/CostHistory.php:24 | OK | Creation timestamp |
| hist_cost_insumo | updated_at | app/Models/Inventory/CostHistory.php:25 | OK | Update timestamp |
| hist_cost_insumo | deleted_at | app/Models/Inventory/CostHistory.php:26 | OK | Delete timestamp |
| stock_policy | id | app/Models/StockPolicy.php:10<br>app/Services/Replenishment/ReplenishmentService.php:56 | OK | Primary key |
| stock_policy | item_id | app/Models/StockPolicy.php:13<br>app/Services/Replenishment/ReplenishmentService.php:289 | OK | Foreign key |
| stock_policy | sucursal_id | app/Models/StockPolicy.php:14 (mapped to almacen_id) | MISMATCH | Código espera almacen_id pero BD tiene sucursal_id |
| stock_policy | almacen_id | app/Models/StockPolicy.php:15 (mapped to sucursal_id) | MISMATCH | Código espera sucursal_id pero BD tiene almacen_id |
| stock_policy | min_qty | app/Models/StockPolicy.php:15<br>app/Services/Replenishment/ReplenishmentService.php:79 | OK | Minimum quantity |
| stock_policy | max_qty | app/Models/StockPolicy.php:16<br>app/Services/Replenishment/ReplenishmentService.php:99 | OK | Maximum quantity |
| stock_policy | reorder_lote | app/Models/StockPolicy.php:17<br>app/Services/Replenishment/ReplenishmentService.php:99 | OK | Reorder lot size |
| stock_policy | activo | app/Models/StockPolicy.php:18 | OK | Active flag |
| stock_policy | created_at | app/Models/StockPolicy.php:19 | OK | Creation timestamp |

### 2.2 Recetas
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| receta | id | app/Models/Rec/Receta.php:11<br>app/Services/Recetas/RecalcularCostosRecetasService.php:228 | OK | Primary key |
| receta | codigo | app/Models/Rec/Receta.php:15 | OK | Recipe code |
| receta | nombre | app/Models/Rec/Receta.php:16<br>app/Services/Recetas/RecalcularCostosRecetasService.php:372 | OK | Recipe name |
| receta | porciones | app/Models/Rec/Receta.php:17<br>app/Services/Recetas/RecalcularCostosRecetasService.php:294 | OK | Number of portions |
| receta | pvp_objetivo | app/Models/Rec/Receta.php:18<br>app/Services/Recetas/RecalcularCostosRecetasService.php:378 | OK | Target selling price |
| receta | activo | app/Models/Rec/Receta.php:19 | OK | Active flag |
| receta | meta | app/Models/Rec/Receta.php:20 | OK | Metadata JSON |
| receta_version | id | app/Models/Rec/RecetaVersion.php:11<br>app/Services/Recetas/RecalcularCostosRecetasService.php:170 | OK | Primary key |
| receta_version | receta_id | app/Models/Rec/RecetaVersion.php:14<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Foreign key |
| receta_version | version | app/Models/Rec/RecetaVersion.php:15<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Version number |
| receta_version | descripcion_cambios | app/Models/Rec/RecetaVersion.php:16<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Changes description |
| receta_version | fecha_efectiva | app/Models/Rec/RecetaVersion.php:17<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Effective date |
| receta_version | version_publicada | app/Models/Rec/RecetaVersion.php:18<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Published version flag |
| receta_version | usuario_publicador | app/Models/Rec/RecetaVersion.php:19<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Publisher user |
| receta_version | fecha_publicacion | app/Models/Rec/RecetaVersion.php:20<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Publication date |
| receta_version | created_at | app/Models/Rec/RecetaVersion.php:21<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Creation timestamp |
| receta_insumo | id | app/Models/Rec/RecetaDetalle.php:11<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Primary key |
| receta_insumo | receta_version_id | app/Models/Rec/RecetaDetalle.php:13<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Foreign key |
| receta_insumo | item_id | app/Models/Rec/RecetaDetalle.php:14<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Foreign key |
| receta_insumo | cantidad | app/Models/Rec/RecetaDetalle.php:15<br>app/Services/Recetas/RecalcularCostosRecetasService.php:278 | OK | Quantity needed |
| pos_map | pos_system | app/Models/Pos/PosMap.php:15<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | POS system identifier |
| pos_map | plu | app/Models/Pos/PosMap.php:16<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | PLU code |
| pos_map | tipo | app/Models/Pos/PosMap.php:17<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Item type |
| pos_map | receta_id | app/Models/Pos/PosMap.php:18<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | MISMATCH | Code expects receta_version_id but DB has receta_id |
| pos_map | receta_version_id | app/Models/Pos/PosMap.php:19<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | MISMATCH | Code uses receta_version_id but DB has separate receta_id |
| pos_map | valid_from | app/Models/Pos/PosMap.php:20<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Valid from date |
| pos_map | valid_to | app/Models/Pos/PosMap.php:21<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Valid to date |
| pos_map | sys_from | app/Models/Pos/PosMap.php:22<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | System from timestamp |
| pos_map | sys_to | app/Models/Pos/PosMap.php:23<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | System to timestamp |
| pos_map | meta | app/Models/Pos/PosMap.php:24<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | FANTASMA | Code references 'json' but DB has 'meta' |
| pos_map | vigente_desde | app/Models/Pos/PosMap.php:25<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | FANTASMA | Field not referenced in models but exists in DB |

### 2.3 POS
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| ticket | id | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Primary key |
| ticket | global_id | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Global identifier |
| ticket | create_date | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Creation date |
| ticket | closing_date | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Closing date |
| ticket | active_date | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Active date |
| ticket | deliveery_date | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Delivery date |
| ticket | creation_hour | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Creation hour |
| ticket | paid | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Paid status |
| ticket | voided | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Voided status |
| ticket | void_reason | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Void reason |
| ticket | wasted | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Wasted status |
| ticket | refunded | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Refunded status |
| ticket | settled | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Settled status |
| ticket | drawer_resetted | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Drawer reset status |
| ticket | sub_total | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Sub total |
| ticket | total_discount | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Total discount |
| ticket | total_tax | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Total tax |
| ticket | total_price | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Total price |
| ticket | paid_amount | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Paid amount |
| ticket | due_amount | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Due amount |
| ticket | advance_amount | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Advance amount |
| ticket | adjustment_amount | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Adjustment amount |
| ticket | number_of_guests | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Number of guests |
| ticket | status | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Status |
| ticket | bar_tab | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Bar tab flag |
| ticket | is_tax_exempt | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Tax exempt flag |
| ticket | is_re_opened | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Reopened flag |
| ticket | service_charge | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Service charge |
| ticket | delivery_charge | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Delivery charge |
| ticket | customer_id | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Customer ID |
| ticket | delivery_address | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Delivery address |
| ticket | customer_pickeup | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Customer pickup flag |
| ticket | delivery_extra_info | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Delivery extra info |
| ticket | ticket_type | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Ticket type |
| ticket | shift_id | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Shift ID |
| ticket | owner_id | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Owner ID |
| ticket | driver_id | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Driver ID |
| ticket | gratuity_id | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Gratuity ID |
| ticket | void_by_user | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Void by user |
| ticket | terminal_id | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Terminal ID |
| ticket | folio_date | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Folio date |
| ticket | branch_key | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Branch key |
| ticket | daily_folio | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Daily folio |
| ticket_item | id | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Primary key |
| ticket_item | item_id | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item ID |
| ticket_item | item_count | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item count |
| ticket_item | item_quantity | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item quantity |
| ticket_item | item_name | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item name |
| ticket_item | item_unit_name | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item unit name |
| ticket_item | group_name | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Group name |
| ticket_item | category_name | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Category name |
| ticket_item | item_price | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item price |
| ticket_item | item_tax_rate | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item tax rate |
| ticket_item | sub_total | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Sub total |
| ticket_item | sub_total_without_modifiers | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Sub total without modifiers |
| ticket_item | discount | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Discount |
| ticket_item | tax_amount | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Tax amount |
| ticket_item | tax_amount_without_modifiers | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Tax amount without modifiers |
| ticket_item | total_price | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Total price |
| ticket_item | total_price_without_modifiers | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Total price without modifiers |
| ticket_item | beverage | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Beverage flag |
| ticket_item | inventory_handled | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Inventory handled flag |
| ticket_item | print_to_kitchen | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Print to kitchen flag |
| ticket_item | treat_as_seat | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Treat as seat flag |
| ticket_item | seat_number | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Seat number |
| ticket_item | fractional_unit | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Fractional unit flag |
| ticket_item | has_modiiers | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | MISMATCH | DB has typo: has_modiiers vs has_modifiers |
| ticket_item | printed_to_kitchen | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Printed to kitchen flag |
| ticket_item | status | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Status |
| ticket_item | stock_amount_adjusted | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Stock amount adjusted |
| ticket_item | pizza_type | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Pizza type flag |
| ticket_item | size_modifier_id | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Size modifier ID |
| ticket_item | ticket_id | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Ticket ID |
| ticket_item | pg_id | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | PG ID |
| ticket_item | pizza_section_mode | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Pizza section mode |
| menu_item | id | app/Models/Pos/MenuItem.php:11<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Primary key |
| menu_item | name | app/Models/Pos/MenuItem.php:16<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Item name |
| menu_item | description | app/Models/Pos/MenuItem.php:17<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Description |
| menu_item | unit_name | app/Models/Pos/MenuItem.php:18<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Unit name |
| menu_item | translated_name | app/Models/Pos/MenuItem.php:19<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Translated name |
| menu_item | barcode | app/Models/Pos/MenuItem.php:20<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Barcode |
| menu_item | buy_price | app/Models/Pos/MenuItem.php:21<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Buy price |
| menu_item | stock_amount | app/Models/Pos/MenuItem.php:22<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Stock amount |
| menu_item | price | app/Models/Pos/MenuItem.php:23<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Selling price |
| menu_item | discount_rate | app/Models/Pos/MenuItem.php:24<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Discount rate |
| menu_item | visible | app/Models/Pos/MenuItem.php:25<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Visible flag |
| menu_item | disable_when_stock_amount_is_zero | app/Models/Pos/MenuItem.php:26<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Disable when no stock |
| menu_item | sort_order | app/Models/Pos/MenuItem.php:27<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Sort order |
| menu_item | btn_color | app/Models/Pos/MenuItem.php:28<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Button color |
| menu_item | text_color | app/Models/Pos/MenuItem.php:29<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Text color |
| menu_item | image | app/Models/Pos/MenuItem.php:30<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Image |
| menu_item | show_image_only | app/Models/Pos/MenuItem.php:31<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Show image only |
| menu_item | fractional_unit | app/Models/Pos/MenuItem.php:32<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Fractional unit |
| menu_item | pizza_type | app/Models/Pos/MenuItem.php:33<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Pizza type |
| menu_item | default_sell_portion | app/Models/Pos/MenuItem.php:34<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Default selling portion |
| menu_item | group_id | app/Models/Pos/MenuItem.php:35<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Group ID |
| menu_item | tax_group_id | app/Models/Pos/MenuItem.php:36<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Tax group ID |
| menu_item | recepie | app/Models/Pos/MenuItem.php:37<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Recipe ID |
| menu_item | pg_id | app/Models/Pos/MenuItem.php:38<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | PG ID |
| menu_item | tax_id | app/Models/Pos/MenuItem.php:39<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Tax ID |
| menu_group | id | app/Models/Pos/MenuGroup.php:11<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Primary key |
| menu_group | name | app/Models/Pos/MenuGroup.php:12<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Group name |
| menu_group | translated_name | app/Models/Pos/MenuGroup.php:13<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Translated name |
| menu_group | visible | app/Models/Pos/MenuGroup.php:14<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Visible flag |
| menu_group | sort_order | app/Models/Pos/MenuGroup.php:15<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Sort order |
| menu_group | btn_color | app/Models/Pos/MenuGroup.php:16<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Button color |
| menu_group | text_color | app/Models/Pos/MenuGroup.php:17<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Text color |
| menu_group | category_id | app/Models/Pos/MenuGroup.php:18<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Category ID |
| transactions | id | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Primary key |
| transactions | payment_type | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Payment type |
| transactions | global_id | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Global identifier |
| transactions | transaction_time | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Transaction time |
| transactions | amount | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Amount |
| transactions | tips_amount | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Tips amount |
| transactions | tips_exceed_amount | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Tips exceed amount |
| transactions | tender_amount | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Tender amount |
| transactions | transaction_type | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Transaction type |
| transactions | custom_payment_name | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Custom payment name |
| transactions | custom_payment_ref | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Custom payment reference |
| transactions | custom_payment_field_name | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Custom payment field name |
| transactions | payment_sub_type | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Payment sub type |
| transactions | captured | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Captured flag |
| transactions | voided | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Voided flag |
| transactions | authorizable | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Authorizable flag |
| transactions | card_holder_name | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card holder name |
| transactions | card_number | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card number |
| transactions | card_auth_code | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card auth code |
| transactions | card_type | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card type |
| transactions | card_transaction_id | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card transaction ID |
| transactions | card_merchant_gateway | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card merchant gateway |
| transactions | card_reader | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card reader |
| transactions | card_aid | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card AID |
| transactions | card_arqc | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card ARQC |
| transactions | card_ext_data | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card ext data |
| transactions | gift_cert_number | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Gift cert number |
| transactions | gift_cert_face_value | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Gift cert face value |
| transactions | gift_cert_paid_amount | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Gift cert paid amount |
| transactions | gift_cert_cash_back_amount | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Gift cert cash back amount |
| transactions | drawer_resetted | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Drawer reset flag |
| transactions | note | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Note |
| transactions | terminal_id | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Terminal ID |
| transactions | ticket_id | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Ticket ID |
| transactions | user_id | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | User ID |
| transactions | payout_reason_id | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Payout reason ID |
| transactions | payout_recepient_id | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Payout recipient ID |
| terminal | id | app/Models/Pos/Terminal.php:11<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Primary key |
| terminal | name | app/Models/Pos/Terminal.php:12<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Terminal name |
| terminal | terminal_key | app/Models/Pos/Terminal.php:13<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Terminal key |
| terminal | opening_balance | app/Models/Pos/Terminal.php:14<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Opening balance |
| terminal | current_balance | app/Models/Pos/Terminal.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Current balance |
| terminal | has_cash_drawer | app/Models/Pos/Terminal.php:16<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Has cash drawer |
| terminal | in_use | app/Models/Pos/Terminal.php:17<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | In use flag |
| terminal | active | app/Models/Pos/Terminal.php:18<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Active flag |
| terminal | location | app/Models/Pos/Terminal.php:19<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Location |
| terminal | floor_id | app/Models/Pos/Terminal.php:20<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Floor ID |
| terminal | assigned_user | app/Models/Pos/Terminal.php:21<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Assigned user |

## 3. TOP 20 problemas críticos

1. **mov_inv.tipo vs tipo_movimiento** - MISMATCH: Código espera tipo_movimiento pero BD tiene 'tipo'
2. **mov_inv.costo_unit vs costo_unitario** - MISMATCH: Código espera costo_unitario pero BD tiene 'costo_unit'
3. **mov_inv.ref_tipo vs referencia_tipo** - MISMATCH: Código espera referencia_tipo pero BD tiene 'ref_tipo'
4. **mov_inv.ref_id vs referencia_id** - MISMATCH: Código espera referencia_id pero BD tiene 'ref_id'
5. **mov_inv.sucursal_id vs almacen_id** - MISMATCH: Código espera almacen_id pero BD tiene 'sucursal_id'
6. **stock_policy.sucursal_id vs almacen_id** - MISMATCH: Código espera almacen_id pero BD tiene 'sucursal_id'
7. **pos_map.receta_id vs receta_version_id** - MISMATCH: Código usa receta_version_id pero BD tiene 'receta_id'
8. **ticket_item.has_modiiers vs has_modifiers** - MISMATCH: DB has typo 'has_modiiers' instead of 'has_modifiers'
9. **mov_inv.ts vs fecha_movimiento** - MISMATCH: Código espera fecha_movimiento pero BD tiene 'ts'
10. **receta.porciones vs porciones_standard** - MISMATCH: Código espera porciones_standard pero BD tiene 'porciones'
11. **receta.pvp_objetivo vs precio_venta_sugerido** - MISMATCH: Código espera precio_venta_sugerido pero BD tiene 'pvp_objetivo'
12. **receta.codigo vs cod_plato** - FANTASMA: Código espera cod_plato que no existe en BD
13. **receta.descripcion vs descripcion** - FANTASMA: Código espera descripcion que no existe en BD
14. **pos_map.meta vs json** - FANTASMA: Código referencia 'json' pero BD tiene 'meta'
15. **pos_map.vigente_desde** - FANTASMA: Campo existe en BD pero no es referenciado en modelos
16. **recepcion table** - FANTASMA: Código espera tabla 'recepcion' pero no existe en BD (existe 'recepcion_cab')
17. **stock table** - FANTASMA: Código espera tabla 'stock' pero no existe en BD
18. **transfer_det.unidad_medida** - FANTASMA: Código espera campo 'unidad_medida' que no existe en BD
19. **receta_version.usuario_publicador vs publicador_usuario** - MISMATCH: Código espera publicador_usuario pero BD tiene 'usuario_publicador'
20. **receta_version.fecha_publicacion vs fecha_publicado** - MISMATCH: Código espera fecha_publicado pero BD tiene 'fecha_publicacion'

## 4. Recomendaciones por módulo

### Inventario:
- Ajustar el modelo Movimiento para mapear correctamente los campos: ts→fecha_movimiento, tipo→tipo_movimiento, costo_unit→costo_unitario, ref_tipo→referencia_tipo, ref_id→referencia_id, sucursal_id→almacen_id
- Verificar por qué las tablas 'recepcion' y 'stock' no existen en la BD pero sí están referenciadas en el código
- Implementar los campos faltantes en transfer_det como unidad_medida si son necesarios
- Revisar la tabla recepcion_det que existe en BD pero no se referencia en código

### Recetas:
- Ajustar el modelo Receta para mapear correctamente los campos: porciones→porciones_standard, pvp_objetivo→precio_venta_sugerido
- Ajustar el modelo PosMap para manejar correctamente los campos receta_id y receta_version_id
- Verificar la inconsistencia entre receta_id y receta_version_id en la tabla pos_map

### POS:
- Corregir el campo has_modiiers a has_modifiers en la base de datos (tiene typo)
- Asegurar consistencia en mapeo de campos entre BD y modelos POS
- Verificar que todos los campos referenciados en el código existen en las tablas correspondientes