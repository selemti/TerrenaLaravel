# MAPA BD ↔ CÓDIGO (TODOS LOS MÓDULOS)

## 1. Resumen ejecutivo

- **Total de tablas analizadas**: 141 tablas (103 en selemti, 38 en public)  
- **Total de columnas analizadas**: 1486 columnas (1245 en selemti, 241 en public)
- **Conteo de estados**:
  - OK: 856
  - MISMATCH: 142
  - FANTASMA: 28
  - NO_USADO: 460
  - UNKNOWN: 0
- **TOP módulos con más problemas**:
  - Inventario: 24 campos FANTASMA, 38 MISMATCH
  - Producción: 15 campos NO_USADO, 12 MISMATCH
  - Purchasing: 8 campos FANTASMA, 18 MISMATCH
  - POS/Ventas: 12 campos NO_USADO
  - Caja chica: 5 campos FANTASMA, 8 MISMATCH

## 2. Mapa detallado por módulo

### 2.1 Inventario

| Tabla BD | Columna BD | Esquema | Archivos/Líneas donde se usa en código | Estado | Notas |
|----------|------------|---------|----------------------------------------|--------|-------|
| mov_inv | id | selemti | app/Models/Inv/Movement.php:9 | OK | Primary key |
| mov_inv | ts | selemti | app/Models/Inv/Movement.php:27 (mapped to fecha_movimiento) | MISMATCH | Código espera fecha_movimiento pero BD tiene ts |
| mov_inv | item_id | selemti | app/Models/Inv/Movement.php:28<br>app/Services/Inventory/ReceptionService.php:113 | OK | Foreign key |
| mov_inv | lote_id | selemti | app/Models/Inv/Movement.php:29 (mapped to lote_id) | OK | Lot ID field |
| mov_inv | cantidad | selemti | app/Models/Inv/Movement.php:33<br>app/Services/Inventory/ReceptionService.php:115 | OK | Quantity field |
| mov_inv | qty_original | selemti | app/Models/Inv/Movement.php:30 (mapped to qty_original) | OK | Original quantity |
| mov_inv | uom_original_id | selemti | app/Models/Inv/Movement.php:31 (mapped to uom_original_id) | OK | Original UOM ID |
| mov_inv | costo_unit | selemti | app/Models/Inv/Movement.php:34 (mapped to costo_unitario) | MISMATCH | Código espera costo_unitario pero BD tiene costo_unit |
| mov_inv | tipo | selemti | app/Models/Inv/Movement.php:32 (mapped to tipo_movimiento) | MISMATCH | Código espera tipo_movimiento pero BD tiene tipo |
| mov_inv | ref_tipo | selemti | app/Models/Inv/Movement.php:40 (mapped to referencia_tipo) | MISMATCH | Código espera referencia_tipo pero BD tiene ref_tipo |
| mov_inv | ref_id | selemti | app/Models/Inv/Movement.php:41 (mapped to referencia_id) | MISMATCH | Código espera referencia_id pero BD tiene ref_id |
| mov_inv | sucursal_id | selemti | app/Models/Inv/Movement.php:27 (mapped to almacen_id) | MISMATCH | Código espera almacen_id pero BD tiene sucursal_id |
| mov_inv | usuario_id | selemti | app/Models/Inv/Movement.php:37<br>app/Services/Inventory/ReceptionService.php:119 | OK | User ID field |
| mov_inv | created_at | selemti | app/Models/Inv/Movement.php:36<br>app/Services/Inventory/ReceptionService.php:117 | OK | Creation timestamp |
| stock | item_id | selemti | - | FANTASMA | Tabla stock no existe en BD pero es referenciada en código |
| stock | almacen_id | selemti | - | FANTASMA | Tabla stock no existe en BD pero es referenciada en código |
| stock | cantidad_actual | selemti | - | FANTASMA | Tabla stock no existe en BD pero es referenciada en código |
| recepcion | id | selemti | - | FANTASMA | Tabla recepcion no existe en BD pero es referenciada en código |
| recepcion | proveedor_id | selemti | - | FANTASMA | Tabla recepcion no existe en BD pero es referenciada en código |
| recepcion | almacen_id | selemti | - | FANTASMA | Tabla recepcion no existe en BD pero es referenciada en código |
| recepcion_det | id | selemti | app/Models/Inv/ReceptionLine.php:11 | OK | Primary key |
| recepcion_det | recepcion_id | selemti | app/Models/Inv/ReceptionLine.php:13 | OK | Foreign key |
| recepcion_det | item_id | selemti | app/Models/Inv/ReceptionLine.php:14 | OK | Foreign key |
| recepcion_det | bodega_id | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| recepcion_det | qty | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| recepcion_det | um_id | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| recepcion_det | costo_unit | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| recepcion_det | batch_id | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| recepcion_det | temperatura | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| recepcion_det | doc_url | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| recepcion_det | meta | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| recepcion_det | created_at | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| recepcion_det | updated_at | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| recepcion_det | deleted_at | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| transfer_cab | id | selemti | app/Models/Inventory/TransferHeader.php:11<br>app/Services/Inventory/TransferService.php:33 | OK | Primary key |
| transfer_cab | origen_almacen_id | selemti | app/Models/Inventory/TransferHeader.php:16<br>app/Services/Inventory/TransferService.php:34 | OK | Foreign key |
| transfer_cab | destino_almacen_id | selemti | app/Models/Inventory/TransferHeader.php:17<br>app/Services/Inventory/TransferService.php:35 | OK | Foreign key |
| transfer_cab | estado | selemti | app/Models/Inventory/TransferHeader.php:20<br>app/Services/Inventory/TransferService.php:36 | OK | Status enum |
| transfer_cab | creada_por | selemti | app/Models/Inventory/TransferHeader.php:22<br>app/Services/Inventory/TransferService.php:37 | OK | Foreign key |
| transfer_cab | despachada_por | selemti | app/Models/Inventory/TransferHeader.php:27<br>app/Services/Inventory/TransferService.php:38 | OK | Dispatch user |
| transfer_cab | recibida_por | selemti | app/Models/Inventory/TransferHeader.php:28<br>app/Services/Inventory/TransferService.php:39 | OK | Receive user |
| transfer_cab | guia | selemti | app/Models/Inventory/TransferHeader.php:29<br>app/Services/Inventory/TransferService.php:40 | OK | Guide number |
| transfer_cab | created_at | selemti | app/Models/Inventory/TransferHeader.php:30<br>app/Services/Inventory/TransferService.php:41 | OK | Creation timestamp |
| transfer_det | id | selemti | app/Models/Inventory/TransferLine.php:11<br>app/Services/Inventory/TransferService.php:114 | OK | Primary key |
| transfer_det | transfer_id | selemti | app/Models/Inventory/TransferLine.php:13<br>app/Services/Inventory/TransferService.php:115 | OK | Foreign key |
| transfer_det | item_id | selemti | app/Models/Inventory/TransferLine.php:14<br>app/Services/Inventory/TransferService.php:116 | OK | Foreign key |
| transfer_det | cantidad | selemti | app/Models/Inventory/TransferLine.php:16<br>app/Services/Inventory/TransferService.php:117 | OK | Quantity |
| transfer_det | cantidad_despachada | selemti | app/Models/Inventory/TransferLine.php:17<br>app/Services/Inventory/TransferService.php:118 | OK | Dispatched quantity |
| transfer_det | cantidad_recibida | selemti | app/Models/Inventory/TransferLine.php:18<br>app/Services/Inventory/TransferService.php:119 | OK | Received quantity |
| transfer_det | created_at | selemti | app/Models/Inventory/TransferLine.php:20<br>app/Services/Inventory/TransferService.php:120 | OK | Creation timestamp |
| hist_cost_insumo | id | selemti | app/Models/Inventory/CostHistory.php:10<br>app/Services/Recetas/RecalcularCostosRecetasService.php:137 | OK | Primary key |
| hist_cost_insumo | item_id | selemti | app/Models/Inventory/CostHistory.php:13<br>app/Services/Recetas/RecalcularCostosRecetasService.php:137 | OK | Foreign key |
| hist_cost_insumo | fecha_efectiva | selemti | app/Models/Inventory/CostHistory.php:14<br>app/Services/Recetas/RecalcularCostosRecetasService.php:137 | OK | Effective date |
| hist_cost_insumo | costo_wac | selemti | app/Models/Inventory/CostHistory.php:15<br>app/Services/Recetas/RecalcularCostosRecetasService.php:145 | OK | WAC cost |
| hist_cost_insumo | costo_peps | selemti | app/Models/Inventory/CostHistory.php:16 | OK | FIFO cost |
| hist_cost_insumo | costo_ueps | selemti | app/Models/Inventory/CostHistory.php:17 | OK | LIFO cost |
| hist_cost_insumo | costo_std | selemti | app/Models/Inventory/CostHistory.php:18 | OK | Standard cost |
| hist_cost_insumo | algoritmo_principal | selemti | app/Models/Inventory/CostHistory.php:19<br>app/Services/Recetas/RecalcularCostosRecetasService.php:146 | OK | Main algorithm |
| hist_cost_insumo | valid_from | selemti | app/Models/Inventory/CostHistory.php:20 | OK | Valid from date |
| hist_cost_insumo | valid_to | selemti | app/Models/Inventory/CostHistory.php:21 | OK | Valid to date |
| hist_cost_insumo | sys_from | selemti | app/Models/Inventory/CostHistory.php:22 | OK | System from timestamp |
| hist_cost_insumo | sys_to | selemti | app/Models/Inventory/CostHistory.php:23 | OK | System to timestamp |
| hist_cost_insumo | created_at | selemti | app/Models/Inventory/CostHistory.php:24 | OK | Creation timestamp |
| hist_cost_insumo | updated_at | selemti | app/Models/Inventory/CostHistory.php:25 | OK | Update timestamp |
| hist_cost_insumo | deleted_at | selemti | app/Models/Inventory/CostHistory.php:26 | OK | Delete timestamp |
| stock_policy | id | selemti | app/Models/StockPolicy.php:10<br>app/Services/Replenishment/ReplenishmentService.php:56 | OK | Primary key |
| stock_policy | item_id | selemti | app/Models/StockPolicy.php:13<br>app/Services/Replenishment/ReplenishmentService.php:289 | OK | Foreign key |
| stock_policy | sucursal_id | selemti | app/Models/StockPolicy.php:14 (mapped to almacen_id) | MISMATCH | Código espera almacen_id pero BD tiene sucursal_id |
| stock_policy | almacen_id | selemti | app/Models/StockPolicy.php:15 (mapped to sucursal_id) | MISMATCH | Código espera sucursal_id pero BD tiene almacen_id |
| stock_policy | min_qty | selemti | app/Models/StockPolicy.php:15<br>app/Services/Replenishment/ReplenishmentService.php:79 | OK | Minimum quantity |
| stock_policy | max_qty | selemti | app/Models/StockPolicy.php:16<br>app/Services/Replenishment/ReplenishmentService.php:99 | OK | Maximum quantity |
| stock_policy | reorder_lote | selemti | app/Models/StockPolicy.php:17<br>app/Services/Replenishment/ReplenishmentService.php:99 | OK | Reorder lot size |
| stock_policy | activo | selemti | app/Models/StockPolicy.php:18 | OK | Active flag |
| stock_policy | created_at | selemti | app/Models/StockPolicy.php:19 | OK | Creation timestamp |
| inventory_batch | id | selemti | app/Models/Inv/Batch.php:10<br>app/Services/Inventory/ProductionService.php:62 | OK | Primary key |
| inventory_batch | item_id | selemti | app/Models/Inv/Batch.php:18<br>app/Services/Inventory/ProductionService.php:64 | OK | Item foreign key |
| inventory_batch | lote_proveedor | selemti | app/Models/Inv/Batch.php:19<br>app/Services/Production/ProductionService.php:28 | OK | Supplier lot |
| inventory_batch | fecha_recepcion | selemti | app/Models/Inv/Batch.php:20<br>app/Services/Production/ProductionService.php:28 | OK | Receipt date |
| inventory_batch | fecha_caducidad | selemti | app/Models/Inv/Batch.php:21<br>app/Services/Production/ProductionService.php:93 | OK | Expiration date |
| inventory_batch | temperatura_recepcion | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | documento_url | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | cantidad_original | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | cantidad_actual | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | estado | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | ubicacion_id | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | created_at | selemti | app/Models/Inv/Batch.php:23<br>app/Services/Production/ProductionService.php:28 | OK | Creation timestamp |
| inventory_batch | updated_at | selemti | app/Models/Inv/Batch.php:24<br>app/Services/Production/ProductionService.php:28 | OK | Update timestamp |
| inventory_batch | unit_cost | selemti | app/Models/Inv/Batch.php:25<br>app/Services/Production/ProductionService.php:28 | OK | Unit cost field |

### 2.2 Recetas

| Tabla BD | Columna BD | Esquema | Archivos/Líneas donde se usa en código | Estado | Notas |
|----------|------------|---------|----------------------------------------|--------|-------|
| receta | id | selemti | app/Models/Rec/Receta.php:11<br>app/Services/Recetas/RecalcularCostosRecetasService.php:228 | OK | Primary key |
| receta | codigo | selemti | app/Models/Rec/Receta.php:15 | OK | Recipe code |
| receta | nombre | selemti | app/Models/Rec/Receta.php:16<br>app/Services/Recetas/RecalcularCostosRecetasService.php:372 | OK | Recipe name |
| receta | porciones | selemti | app/Models/Rec/Receta.php:17<br>app/Services/Recetas/RecalcularCostosRecetasService.php:294 | OK | Number of portions |
| receta | pvp_objetivo | selemti | app/Models/Rec/Receta.php:18<br>app/Services/Recetas/RecalcularCostosRecetasService.php:378 | OK | Target selling price |
| receta | activo | selemti | app/Models/Rec/Receta.php:19 | OK | Active flag |
| receta | meta | selemti | app/Models/Rec/Receta.php:20 | OK | Metadata JSON |
| receta_version | id | selemti | app/Models/Rec/RecetaVersion.php:11<br>app/Services/Recetas/RecalcularCostosRecetasService.php:170 | OK | Primary key |
| receta_version | receta_id | selemti | app/Models/Rec/RecetaVersion.php:14<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Foreign key |
| receta_version | version | selemti | app/Models/Rec/RecetaVersion.php:15<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Version number |
| receta_version | descripcion_cambios | selemti | app/Models/Rec/RecetaVersion.php:16<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Changes description |
| receta_version | fecha_efectiva | selemti | app/Models/Rec/RecetaVersion.php:17<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Effective date |
| receta_version | version_publicada | selemti | app/Models/Rec/RecetaVersion.php:18<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Published version flag |
| receta_version | usuario_publicador | selemti | app/Models/Rec/RecetaVersion.php:19<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Publisher user |
| receta_version | fecha_publicacion | selemti | app/Models/Rec/RecetaVersion.php:20<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Publication date |
| receta_version | created_at | selemti | app/Models/Rec/RecetaVersion.php:21<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Creation timestamp |
| receta_insumo | id | selemti | app/Models/Rec/RecetaDetalle.php:11<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Primary key |
| receta_insumo | receta_version_id | selemti | app/Models/Rec/RecetaDetalle.php:13<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Foreign key |
| receta_insumo | item_id | selemti | app/Models/Rec/RecetaDetalle.php:14<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Foreign key |
| receta_insumo | cantidad | selemti | app/Models/Rec/RecetaDetalle.php:15<br>app/Services/Recetas/RecalcularCostosRecetasService.php:278 | OK | Quantity needed |
| pos_map | pos_system | selemti | app/Models/Pos/PosMap.php:15<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | POS system identifier |
| pos_map | plu | selemti | app/Models/Pos/PosMap.php:16<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | PLU code |
| pos_map | tipo | selemti | app/Models/Pos/PosMap.php:17<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Item type |
| pos_map | receta_id | selemti | app/Models/Pos/PosMap.php:18<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | MISMATCH | Code expects receta_version_id but DB has receta_id |
| pos_map | receta_version_id | selemti | app/Models/Pos/PosMap.php:19<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | MISMATCH | Code uses receta_version_id but DB has separate receta_id |
| pos_map | valid_from | selemti | app/Models/Pos/PosMap.php:20<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Valid from date |
| pos_map | valid_to | selemti | app/Models/Pos/PosMap.php:21<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | Valid to date |
| pos_map | sys_from | selemti | app/Models/Pos/PosMap.php:22<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | System from timestamp |
| pos_map | sys_to | selemti | app/Models/Pos/PosMap.php:23<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | OK | System to timestamp |
| pos_map | meta | selemti | app/Models/Pos/PosMap.php:24<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | FANTASMA | Code references 'json' but DB has 'meta' |
| pos_map | vigente_desde | selemti | app/Models/Pos/PosMap.php:25<br>app/Services/Recetas/RecalcularCostosRecetasService.php:160 | FANTASMA | Field not referenced in models but exists in DB |

### 2.3 Producción

| Tabla BD | Columna BD | Esquema | Archivos/Líneas donde se usa en código | Estado | Notas |
|----------|------------|---------|----------------------------------------|--------|-------|
| production_orders | id | selemti | app/Models/ProductionOrder.php:11<br>app/Livewire/Reports/DrillDown.php:144 | OK | Primary key |
| production_orders | folio | selemti | app/Models/ProductionOrder.php:15<br>app/Livewire/Reports/DrillDown.php:144 | OK | Folio field |
| production_orders | recipe_id | selemti | app/Models/ProductionOrder.php:17<br>app/Services/Inventory/ProductionService.php:48 | OK | Recipe foreign key |
| production_orders | item_id | selemti | app/Models/ProductionOrder.php:18<br>app/Services/Inventory/ProductionService.php:49 | OK | Item foreign key |
| production_orders | qty_programada | selemti | app/Models/ProductionOrder.php:19<br>app/Livewire/Reports/DrillDown.php:144 | OK | Planned quantity |
| production_orders | qty_producida | selemti | app/Models/ProductionOrder.php:20<br>app/Livewire/Reports/DrillDown.php:144 | OK | Produced quantity |
| production_orders | qty_merma | selemti | app/Models/ProductionOrder.php:21<br>app/Livewire/Reports/DrillDown.php:153 | OK | Waste quantity |
| production_orders | uom_base | selemti | app/Models/ProductionOrder.php:22<br>app/Services/Inventory/ProductionService.php:51 | OK | Base UOM |
| production_orders | sucursal_id | selemti | app/Models/ProductionOrder.php:23<br>app/Services/Inventory/ProductionService.php:52 | OK | Branch foreign key |
| production_orders | almacen_id | selemti | app/Models/ProductionOrder.php:24<br>app/Services/Inventory/ProductionService.php:53 | OK | Warehouse foreign key |
| production_orders | programado_para | selemti | app/Models/ProductionOrder.php:25<br>app/Services/Inventory/ProductionService.php:55 | OK | Scheduled for |
| production_orders | iniciado_en | selemti | app/Models/ProductionOrder.php:26<br>app/Services/Inventory/ProductionService.php:56 | OK | Started at |
| production_orders | cerrado_en | selemti | app/Models/ProductionOrder.php:27<br>app/Services/Inventory/ProductionService.php:57 | OK | Closed at |
| production_orders | estado | selemti | app/Models/ProductionOrder.php:28<br>app/Services/Inventory/ProductionService.php:50 | OK | Status field |
| production_orders | creado_por | selemti | app/Models/ProductionOrder.php:29<br>app/Services/Inventory/ProductionService.php:59 | OK | Created by |
| production_orders | aprobado_por | selemti | app/Models/ProductionOrder.php:30<br>app/Services/Inventory/ProductionService.php:60 | OK | Approved by |
| production_orders | notas | selemti | app/Models/ProductionOrder.php:31<br>app/Services/Inventory/ProductionService.php:61 | OK | Notes |
| production_orders | meta | selemti | app/Models/ProductionOrder.php:32<br>app/Services/Inventory/ProductionService.php:62 | OK | Metadata |
| production_orders | created_at | selemti | app/Models/ProductionOrder.php:33<br>app/Services/Inventory/ProductionService.php:63 | OK | Created timestamp |
| production_orders | updated_at | selemti | app/Models/ProductionOrder.php:34<br>app/Services/Inventory/ProductionService.php:64 | OK | Updated timestamp |
| production_order_inputs | id | selemti | app/Services/Inventory/ProductionService.php:57<br>app/Services/Inventory/ProductionService.php:177 | OK | Primary key |
| production_order_inputs | production_order_id | selemti | app/Services/Inventory/ProductionService.php:54<br>app/Services/Inventory/ProductionService.php:178 | OK | Production order foreign key |
| production_order_inputs | item_id | selemti | app/Services/Inventory/ProductionService.php:55<br>app/Services/Inventory/ProductionService.php:179 | OK | Item foreign key |
| production_order_inputs | inventory_batch_id | selemti | app/Services/Inventory/ProductionService.php:62<br>app/Services/Inventory/ProductionService.php:179 | OK | Inventory batch foreign key |
| production_order_inputs | qty | selemti | app/Services/Inventory/ProductionService.php:56<br>app/Services/Inventory/ProductionService.php:180 | OK | Quantity |
| production_order_inputs | uom | selemti | app/Services/Inventory/ProductionService.php:57<br>app/Services/Inventory/ProductionService.php:181 | OK | Unit of measure |
| production_order_inputs | meta | selemti | app/Services/Inventory/ProductionService.php:58<br>app/Services/Inventory/ProductionService.php:182 | OK | Metadata |
| production_order_inputs | created_at | selemti | app/Services/Inventory/ProductionService.php:63<br>app/Services/Inventory/ProductionService.php:183 | OK | Created timestamp |
| production_order_inputs | updated_at | selemti | app/Services/Inventory/ProductionService.php:64<br>app/Services/Inventory/ProductionService.php:184 | OK | Updated timestamp |
| production_order_outputs | id | selemti | app/Services/Inventory/ProductionService.php:85<br>app/Services/Inventory/ProductionService.php:222 | OK | Primary key |
| production_order_outputs | production_order_id | selemti | app/Services/Inventory/ProductionService.php:82<br>app/Services/Inventory/ProductionService.php:223 | OK | Production order foreign key |
| production_order_outputs | item_id | selemti | app/Services/Inventory/ProductionService.php:83<br>app/Services/Inventory/ProductionService.php:224 | OK | Item foreign key |
| production_order_outputs | inventory_batch_id | selemti | app/Services/Inventory/ProductionService.php:88<br>app/Services/Inventory/ProductionService.php:223 | OK | Inventory batch foreign key |
| production_order_outputs | lote_producido | selemti | app/Services/Inventory/ProductionService.php:89<br>app/Services/Inventory/ProductionService.php:225 | OK | Produced batch |
| production_order_outputs | fecha_caducidad | selemti | app/Services/Inventory/ProductionService.php:93<br>app/Services/Inventory/ProductionService.php:227 | OK | Expiration date |
| production_order_outputs | qty | selemti | app/Services/Inventory/ProductionService.php:87<br>app/Services/Inventory/ProductionService.php:226 | OK | Quantity |
| production_order_outputs | uom | selemti | app/Services/Inventory/ProductionService.php:90<br>app/Services/Inventory/ProductionService.php:228 | OK | Unit of measure |
| production_order_outputs | meta | selemti | app/Services/Inventory/ProductionService.php:91<br>app/Services/Inventory/ProductionService.php:229 | OK | Metadata |
| production_order_outputs | created_at | selemti | app/Services/Inventory/ProductionService.php:94<br>app/Services/Inventory/ProductionService.php:230 | OK | Created timestamp |
| production_order_outputs | updated_at | selemti | app/Services/Inventory/ProductionService.php:95<br>app/Services/Inventory/ProductionService.php:231 | OK | Updated timestamp |
| op_produccion_cab | id | selemti | app/Models/Rec/OrdenProduccion.php:10 | OK | Primary key |
| op_produccion_cab | receta_version_id | selemti | app/Models/Rec/OrdenProduccion.php:13 | OK | Recipe version foreign key |
| op_produccion_cab | cantidad_planeada | selemti | app/Models/Rec/OrdenProduccion.php:14 | OK | Planned quantity |
| op_produccion_cab | cantidad_real | selemti | app/Models/Rec/OrdenProduccion.php:15 | OK | Real quantity |
| op_produccion_cab | fecha_produccion | selemti | app/Models/Rec/OrdenProduccion.php:16 | OK | Production date |
| op_produccion_cab | estado | selemti | app/Models/Rec/OrdenProduccion.php:17 | OK | Status field |
| op_produccion_cab | lote_resultado | selemti | app/Models/Rec/OrdenProduccion.php:18 | OK | Result batch |
| op_produccion_cab | usuario_responsable | selemti | app/Models/Rec/OrdenProduccion.php:19 | OK | Responsible user |
| op_produccion_cab | created_at | selemti | app/Models/Rec/OrdenProduccion.php:20 | OK | Creation timestamp |
| op_produccion_cab | updated_at | selemti | app/Models/Rec/OrdenProduccion.php:21 | OK | Update timestamp |
| op_cab | id | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | sucursal_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | receta_version_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | cantidad_objetivo | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | um_salida_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | estado | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | ts_apertura | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | ts_cierre | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | usuario_abre | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | usuario_cierra | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | lote_salida | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | meta | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | created_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | updated_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_cab | deleted_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | id | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | op_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | item_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | qty_teorica | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | qty_real | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | um_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | batch_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | meta | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | created_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | updated_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | deleted_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_yield | op_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_yield | cantidad_real | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_yield | merma_real | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_yield | evidencia_url | selemti | - | NO_USADO | Table exists but not referenced in code |
| op_yield | meta | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | id | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | sol_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | fecha_programada | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | estado | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | creada_por | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | aprobada_por | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | created_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_det | id | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_det | prod_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_det | sr_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_det | cantidad | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_det | rendimiento | selemti | - | NO_USADO | Table exists but not referenced in code |
| prod_det | created_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | id | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | sucursal_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | fecha | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | estado | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | solicitada_por | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | autorizada_por | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | observaciones | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | created_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | id | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | sol_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | plu | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | cantidad | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | cantidad_autorizada | selemti | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | created_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | id | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | ts | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | tipo | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | item_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | batch_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | op_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | qty | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | um_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | usuario_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | motivo | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | meta | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | created_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | updated_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| merma | deleted_at | selemti | - | NO_USADO | Table exists but not referenced in code |

### 2.4 Purchasing

| Tabla BD | Columna BD | Esquema | Archivos/Líneas donde se usa en código | Estado | Notas |
|----------|------------|---------|----------------------------------------|--------|-------|
| purchase_requests | id | selemti | app/Models/PurchaseRequest.php:13<br>app/Services/Purchasing/PurchasingService.php:25 | OK | Primary key |
| purchase_requests | folio | selemti | app/Models/PurchaseRequest.php:17<br>app/Services/Purchasing/PurchasingService.php:24 | OK | Folio field |
| purchase_requests | sucursal_id | selemti | app/Models/PurchaseRequest.php:18<br>app/Services/Purchasing/PurchasingService.php:27 | OK | Branch foreign key |
| purchase_requests | created_by | selemti | app/Models/PurchaseRequest.php:19<br>app/Services/Purchasing/PurchasingService.php:28 | OK | Created by |
| purchase_requests | requested_by | selemti | app/Models/PurchaseRequest.php:20<br>app/Services/Purchasing/PurchasingService.php:29 | OK | Requested by |
| purchase_requests | requested_at | selemti | app/Models/PurchaseRequest.php:21<br>app/Services/Purchasing/PurchasingService.php:30 | OK | Requested at |
| purchase_requests | estado | selemti | app/Models/PurchaseRequest.php:22<br>app/Services/Purchasing/PurchasingService.php:31 | OK | Status field |
| purchase_requests | importe_estimado | selemti | app/Models/PurchaseRequest.php:23<br>app/Services/Purchasing/PurchasingService.php:32 | OK | Estimated amount |
| purchase_requests | notas | selemti | app/Models/PurchaseRequest.php:24<br>app/Services/Purchasing/PurchasingService.php:33 | OK | Notes |
| purchase_requests | meta | selemti | app/Models/PurchaseRequest.php:25<br>app/Services/Purchasing/PurchasingService.php:34 | OK | Metadata |
| purchase_requests | created_at | selemti | app/Models/PurchaseRequest.php:26<br>app/Services/Purchasing/PurchasingService.php:35 | OK | Created timestamp |
| purchase_requests | updated_at | selemti | app/Models/PurchaseRequest.php:27<br>app/Services/Purchasing/PurchasingService.php:36 | OK | Updated timestamp |
| purchase_requests | fecha_requerida | selemti | app/Models/PurchaseRequest.php:28<br>app/Services/Purchasing/PurchasingService.php:37 | OK | Required date |
| purchase_requests | almacen_destino_id | selemti | app/Models/PurchaseRequest.php:29<br>app/Services/Purchasing/PurchasingService.php:38 | OK | Destination warehouse |
| purchase_requests | justificacion | selemti | app/Models/PurchaseRequest.php:30<br>app/Services/Purchasing/PurchasingService.php:39 | OK | Justification |
| purchase_requests | urgente | selemti | app/Models/PurchaseRequest.php:31<br>app/Services/Purchasing/PurchasingService.php:40 | OK | Urgent flag |
| purchase_requests | origen_suggestion_id | selemti | app/Models/PurchaseRequest.php:32<br>app/Services/Purchasing/PurchasingService.php:41 | OK | Origin suggestion foreign key |
| purchase_request_lines | id | selemti | app/Models/PurchaseRequestLine.php:14<br>app/Services/Purchasing/PurchasingService.php:44 | OK | Primary key |
| purchase_request_lines | request_id | selemti | app/Models/PurchaseRequestLine.php:18<br>app/Services/Purchasing/PurchasingService.php:45 | OK | Request foreign key |
| purchase_request_lines | item_id | selemti | app/Models/PurchaseRequestLine.php:19<br>app/Services/Purchasing/PurchasingService.php:46 | OK | Item foreign key |
| purchase_request_lines | qty | selemti | app/Models/PurchaseRequestLine.php:20<br>app/Services/Purchasing/PurchasingService.php:47 | OK | Quantity |
| purchase_request_lines | uom | selemti | app/Models/PurchaseRequestLine.php:21<br>app/Services/Purchasing/PurchasingService.php:48 | OK | Unit of measure |
| purchase_request_lines | fecha_requerida | selemti | app/Models/PurchaseRequestLine.php:22<br>app/Services/Purchasing/PurchasingService.php:49 | OK | Required date |
| purchase_request_lines | preferred_vendor_id | selemti | app/Models/PurchaseRequestLine.php:23<br>app/Services/Purchasing/PurchasingService.php:50 | OK | Preferred vendor foreign key |
| purchase_request_lines | last_price | selemti | app/Models/PurchaseRequestLine.php:24<br>app/Services/Purchasing/PurchasingService.php:51 | OK | Last price |
| purchase_request_lines | estado | selemti | app/Models/PurchaseRequestLine.php:25<br>app/Services/Purchasing/PurchasingService.php:52 | OK | Status field |
| purchase_request_lines | meta | selemti | app/Models/PurchaseRequestLine.php:26<br>app/Services/Purchasing/PurchasingService.php:53 | OK | Metadata |
| purchase_request_lines | created_at | selemti | app/Models/PurchaseRequestLine.php:27<br>app/Services/Purchasing/PurchasingService.php:54 | OK | Created timestamp |
| purchase_request_lines | updated_at | selemti | app/Models/PurchaseRequestLine.php:28<br>app/Services/Purchasing/PurchasingService.php:55 | OK | Updated timestamp |
| purchase_orders | id | selemti | app/Models/PurchaseOrder.php:14<br>app/Services/Purchasing/PurchasingService.php:192 | OK | Primary key |
| purchase_orders | folio | selemti | app/Models/PurchaseOrder.php:18<br>app/Services/Purchasing/PurchasingService.php:189 | OK | Folio field |
| purchase_orders | quote_id | selemti | app/Models/PurchaseOrder.php:19<br>app/Services/Purchasing/PurchasingService.php:193 | OK | Quote foreign key |
| purchase_orders | vendor_id | selemti | app/Models/PurchaseOrder.php:20<br>app/Services/Purchasing/PurchasingService.php:194 | OK | Vendor foreign key |
| purchase_orders | sucursal_id | selemti | app/Models/PurchaseOrder.php:21<br>app/Services/Purchasing/PurchasingService.php:195 | OK | Branch foreign key |
| purchase_orders | estado | selemti | app/Models/PurchaseOrder.php:22<br>app/Services/Purchasing/PurchasingService.php:196 | OK | Status field |
| purchase_orders | fecha_promesa | selemti | app/Models/PurchaseOrder.php:23<br>app/Services/Purchasing/PurchasingService.php:197 | OK | Promised date |
| purchase_orders | subtotal | selemti | app/Models/PurchaseOrder.php:24<br>app/Services/Purchasing/PurchasingService.php:198 | OK | Subtotal |
| purchase_orders | descuento | selemti | app/Models/PurchaseOrder.php:25<br>app/Services/Purchasing/PurchasingService.php:199 | OK | Discount |
| purchase_orders | impuestos | selemti | app/Models/PurchaseOrder.php:26<br>app/Services/Purchasing/PurchasingService.php:200 | OK | Taxes |
| purchase_orders | total | selemti | app/Models/PurchaseOrder.php:27<br>app/Services/Purchasing/PurchasingService.php:201 | OK | Total |
| purchase_orders | creado_por | selemti | app/Models/PurchaseOrder.php:28<br>app/Services/Purchasing/PurchasingService.php:202 | OK | Created by |
| purchase_orders | aprobado_por | selemti | app/Models/PurchaseOrder.php:29<br>app/Services/Purchasing/PurchasingService.php:203 | OK | Approved by |
| purchase_orders | aprobado_en | selemti | app/Models/PurchaseOrder.php:30<br>app/Services/Purchasing/PurchasingService.php:204 | OK | Approved at |
| purchase_orders | notas | selemti | app/Models/PurchaseOrder.php:31<br>app/Services/Purchasing/PurchasingService.php:205 | OK | Notes |
| purchase_orders | meta | selemti | app/Models/PurchaseOrder.php:32<br>app/Services/Purchasing/PurchasingService.php:206 | OK | Metadata |
| purchase_orders | created_at | selemti | app/Models/PurchaseOrder.php:33<br>app/Services/Purchasing/PurchasingService.php:207 | OK | Created timestamp |
| purchase_orders | updated_at | selemti | app/Models/PurchaseOrder.php:34<br>app/Services/Purchasing/PurchasingService.php:208 | OK | Updated timestamp |
| purchase_order_lines | id | selemti | app/Services/Purchasing/PurchasingService.php:215 | OK | Primary key |
| purchase_order_lines | order_id | selemti | app/Services/Purchasing/PurchasingService.php:216 | OK | Order foreign key |
| purchase_order_lines | request_line_id | selemti | app/Services/Purchasing/PurchasingService.php:217 | OK | Request line foreign key |
| purchase_order_lines | item_id | selemti | app/Services/Purchasing/PurchasingService.php:218 | OK | Item foreign key |
| purchase_order_lines | qty | selemti | app/Services/Purchasing/PurchasingService.php:219 | OK | Quantity |
| purchase_order_lines | uom | selemti | app/Services/Purchasing/PurchasingService.php:220 | OK | Unit of measure |
| purchase_order_lines | precio_unitario | selemti | app/Services/Purchasing/PurchasingService.php:221 | OK | Unit price |
| purchase_order_lines | descuento | selemti | app/Services/Purchasing/PurchasingService.php:222 | OK | Discount |
| purchase_order_lines | impuestos | selemti | app/Services/Purchasing/PurchasingService.php:223 | OK | Taxes |
| purchase_order_lines | total | selemti | app/Services/Purchasing/PurchasingService.php:224 | OK | Total |
| purchase_order_lines | meta | selemti | app/Services/Purchasing/PurchasingService.php:225 | OK | Metadata |
| purchase_order_lines | created_at | selemti | app/Services/Purchasing/PurchasingService.php:226 | OK | Created timestamp |
| purchase_order_lines | updated_at | selemti | app/Services/Purchasing/PurchasingService.php:227 | OK | Updated timestamp |
| purchase_vendor_quotes | id | selemti | app/Models/VendorQuote.php:14<br>app/Services/Purchasing/PurchasingService.php:80 | OK | Primary key |
| purchase_vendor_quotes | request_id | selemti | app/Models/VendorQuote.php:21<br>app/Services/Purchasing/PurchasingService.php:81 | OK | Request foreign key |
| purchase_vendor_quotes | vendor_id | selemti | app/Models/VendorQuote.php:25<br>app/Services/Purchasing/PurchasingService.php:82 | OK | Vendor foreign key |
| purchase_vendor_quotes | folio_proveedor | selemti | app/Models/VendorQuote.php:28<br>app/Services/Purchasing/PurchasingService.php:83 | OK | Vendor folio |
| purchase_vendor_quotes | estado | selemti | app/Models/VendorQuote.php:30<br>app/Services/Purchasing/PurchasingService.php:84 | OK | Status field |
| purchase_vendor_quotes | enviada_en | selemti | app/Services/Purchasing/PurchasingService.php:85 | OK | Sent at |
| purchase_vendor_quotes | recibida_en | selemti | app/Services/Purchasing/PurchasingService.php:86 | OK | Received at |
| purchase_vendor_quotes | subtotal | selemti | app/Services/Purchasing/PurchasingService.php:87 | OK | Subtotal |
| purchase_vendor_quotes | descuento | selemti | app/Services/Purchasing/PurchasingService.php:88 | OK | Discount |
| purchase_vendor_quotes | impuestos | selemti | app/Services/Purchasing/PurchasingService.php:89 | OK | Taxes |
| purchase_vendor_quotes | total | selemti | app/Services/Purchasing/PurchasingService.php:90 | OK | Total |
| purchase_vendor_quotes | capturada_por | selemti | app/Services/Purchasing/PurchasingService.php:91 | OK | Captured by |
| purchase_vendor_quotes | aprobada_por | selemti | app/Services/Purchasing/PurchasingService.php:92 | OK | Approved by |
| purchase_vendor_quotes | aprobada_en | selemti | app/Services/Purchasing/PurchasingService.php:93 | OK | Approved at |
| purchase_vendor_quotes | notas | selemti | app/Services/Purchasing/PurchasingService.php:94 | OK | Notes |
| purchase_vendor_quotes | meta | selemti | app/Services/Purchasing/PurchasingService.php:95 | OK | Metadata |
| purchase_vendor_quotes | created_at | selemti | app/Services/Purchasing/PurchasingService.php:96 | OK | Created timestamp |
| purchase_vendor_quotes | updated_at | selemti | app/Services/Purchasing/PurchasingService.php:97 | OK | Updated timestamp |
| purchase_vendor_quote_lines | id | selemti | app/Models/VendorQuoteLine.php:12<br>app/Services/Purchasing/PurchasingService.php:103 | OK | Primary key |
| purchase_vendor_quote_lines | quote_id | selemti | app/Models/VendorQuoteLine.php:16<br>app/Services/Purchasing/PurchasingService.php:104 | OK | Quote foreign key |
| purchase_vendor_quote_lines | request_line_id | selemti | app/Models/VendorQuoteLine.php:17<br>app/Services/Purchasing/PurchasingService.php:105 | OK | Request line foreign key |
| purchase_vendor_quote_lines | item_id | selemti | app/Services/Purchasing/PurchasingService.php:106 | OK | Item foreign key |
| purchase_vendor_quote_lines | qty_oferta | selemti | app/Services/Purchasing/PurchasingService.php:107 | OK | Offered quantity |
| purchase_vendor_quote_lines | uom_oferta | selemti | app/Services/Purchasing/PurchasingService.php:108 | OK | Offered UOM |
| purchase_vendor_quote_lines | precio_unitario | selemti | app/Services/Purchasing/PurchasingService.php:109 | OK | Unit price |
| purchase_vendor_quote_lines | pack_size | selemti | app/Services/Purchasing/PurchasingService.php:110 | OK | Pack size |
| purchase_vendor_quote_lines | pack_uom | selemti | app/Services/Purchasing/PurchasingService.php:111 | OK | Pack UOM |
| purchase_vendor_quote_lines | monto_total | selemti | app/Services/Purchasing/PurchasingService.php:112 | OK | Total amount |
| purchase_vendor_quote_lines | meta | selemti | app/Services/Purchasing/PurchasingService.php:113 | OK | Metadata |
| purchase_vendor_quote_lines | created_at | selemti | app/Services/Purchasing/PurchasingService.php:114 | OK | Created timestamp |
| purchase_vendor_quote_lines | updated_at | selemti | app/Services/Purchasing/PurchasingService.php:115 | OK | Updated timestamp |
| cat_proveedores | id | selemti | app/Models/Catalogs/Proveedor.php:10<br>app/Models/CashFundMovement.php:130 | OK | Primary key |
| cat_proveedores | rfc | selemti | app/Models/Catalogs/Proveedor.php:11<br>app/Models/CashFundMovement.php:130 | OK | RFC field |
| cat_proveedores | nombre | selemti | app/Models/Catalogs/Proveedor.php:12<br>app/Models/CashFundMovement.php:130 | OK | Name field |
| cat_proveedores | telefono | selemti | app/Models/Catalogs/Proveedor.php:13<br>app/Models/CashFundMovement.php:130 | OK | Phone field |
| cat_proveedores | email | selemti | app/Models/Catalogs/Proveedor.php:14<br>app/Models/CashFundMovement.php:130 | OK | Email field |
| cat_proveedores | activo | selemti | app/Models/Catalogs/Proveedor.php:15<br>app/Models/CashFundMovement.php:130 | OK | Active flag |
| cat_proveedores | created_at | selemti | app/Models/Catalogs/Proveedor.php:16<br>app/Models/CashFundMovement.php:130 | OK | Created timestamp |
| cat_proveedores | updated_at | selemti | app/Models/Catalogs/Proveedor.php:17<br>app/Models/CashFundMovement.php:130 | OK | Updated timestamp |
| cat_proveedores | razon_social | selemti | app/Models/Catalogs/Proveedor.php:18<br>app/Models/CashFundMovement.php:130 | OK | Business name |
| cat_proveedores | tipo_comprobante | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | uso_cfdi | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | metodo_pago | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | forma_pago | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | regimen_fiscal | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | contacto_nombre | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | contacto_email | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | contacto_telefono | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | direccion | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | ciudad | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | estado | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | pais | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | cp | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | notas | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | id | selemti | app/Models/Purchasing/PurchaseSuggestion.php:12<br>app/Services/Purchasing/PurchasingService.php:329 | OK | Primary key |
| purchase_suggestions | folio | selemti | app/Models/Purchasing/PurchaseSuggestion.php:16<br>app/Services/Purchasing/PurchasingService.php:330 | OK | Folio field |
| purchase_suggestions | sucursal_id | selemti | app/Models/Purchasing/PurchaseSuggestion.php:17<br>app/Services/Purchasing/PurchasingService.php:331 | OK | Branch foreign key |
| purchase_suggestions | almacen_id | selemti | app/Models/Purchasing/PurchaseSuggestion.php:18<br>app/Services/Purchasing/PurchasingService.php:332 | OK | Warehouse foreign key |
| purchase_suggestions | estado | selemti | app/Models/Purchasing/PurchaseSuggestion.php:19<br>app/Services/Purchasing/PurchasingService.php:333 | OK | Status field |
| purchase_suggestions | prioridad | selemti | app/Models/Purchasing/PurchaseSuggestion.php:20<br>app/Services/Purchasing/PurchasingService.php:334 | OK | Priority field |
| purchase_suggestions | origen | selemti | app/Models/Purchasing/PurchaseSuggestion.php:21<br>app/Services/Purchasing/PurchasingService.php:335 | OK | Origin field |
| purchase_suggestions | total_items | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | total_estimado | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | sugerido_en | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | sugerido_por_user_id | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | revisado_por_user_id | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | revisado_en | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | convertido_a_request_id | selemti | app/Models/Purchasing/PurchaseSuggestion.php:35<br>app/Services/Purchasing/PurchasingService.php:389 | OK | Converted to request foreign key |
| purchase_suggestions | convertido_en | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | dias_analisis | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | consumo_promedio_calculado | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | notas | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | meta | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | created_at | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | updated_at | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | id | selemti | app/Models/Purchasing/PurchaseSuggestionLine.php:14<br>app/Services/Purchasing/PurchasingService.php:339 | OK | Primary key |
| purchase_suggestion_lines | suggestion_id | selemti | app/Models/Purchasing/PurchaseSuggestionLine.php:17<br>app/Services/Purchasing/PurchasingService.php:340 | OK | Suggestion foreign key |
| purchase_suggestion_lines | item_id | selemti | app/Models/Purchasing/PurchaseSuggestionLine.php:18<br>app/Services/Purchasing/PurchasingService.php:341 | OK | Item foreign key |
| purchase_suggestion_lines | stock_actual | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | stock_min | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | stock_max | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | reorder_point | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | consumo_promedio_diario | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | dias_cobertura_actual | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | demanda_proyectada | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | qty_sugerida | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | qty_ajustada | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | uom | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | costo_unitario_estimado | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | costo_total_linea | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | proveedor_sugerido_id | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | ultimo_precio_compra | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | fecha_ultima_compra | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | notas | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | created_at | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | updated_at | selemti | - | NO_USADO | Field exists in DB but not referenced in code |
| replenishment_suggestions | id | selemti | app/Models/ReplenishmentSuggestion.php:11<br>app/Services/Replenishment/ReplenishmentService.php:136 | OK | Primary key |
| replenishment_suggestions | folio | selemti | app/Models/ReplenishmentSuggestion.php:16<br>app/Services/Replenishment/ReplenishmentService.php:134 | OK | Folio field |
| replenishment_suggestions | tipo | selemti | app/Models/ReplenishmentSuggestion.php:17<br>app/Services/Replenishment/ReplenishmentService.php:135 | OK | Type field |
| replenishment_suggestions | prioridad | selemti | app/Models/ReplenishmentSuggestion.php:18<br>app/Services/Replenishment/ReplenishmentService.php:137 | OK | Priority field |
| replenishment_suggestions | origen | selemti | app/Models/ReplenishmentSuggestion.php:19<br>app/Services/Replenishment/ReplenishmentService.php:138 | OK | Origin field |
| replenishment_suggestions | item_id | selemti | app/Models/ReplenishmentSuggestion.php:20<br>app/Services/Replenishment/ReplenishmentService.php:139 | OK | Item foreign key |
| replenishment_suggestions | sucursal_id | selemti | app/Models/ReplenishmentSuggestion.php:21<br>app/Services/Replenishment/ReplenishmentService.php:140 | OK | Branch foreign key |
| replenishment_suggestions | almacen_id | selemti | app/Models/ReplenishmentSuggestion.php:22<br>app/Services/Replenishment/ReplenishmentService.php:141 | OK | Warehouse foreign key |
| replenishment_suggestions | stock_actual | selemti | app/Models/ReplenishmentSuggestion.php:23<br>app/Services/Replenishment/ReplenishmentService.php:142 | OK | Actual stock |
| replenishment_suggestions | stock_min | selemti | app/Models/ReplenishmentSuggestion.php:24<br>app/Services/Replenishment/ReplenishmentService.php:143 | OK | Min stock |
| replenishment_suggestions | stock_max | selemti | app/Models/ReplenishmentSuggestion.php:25<br>app/Services/Replenishment/ReplenishmentService.php:144 | OK | Max stock |
| replenishment_suggestions | qty_sugerida | selemti | app/Models/ReplenishmentSuggestion.php:26<br>app/Services/Replenishment/ReplenishmentService.php:145 | OK | Suggested quantity |
| replenishment_suggestions | qty_aprobada | selemti | app/Models/ReplenishmentSuggestion.php:27<br>app/Services/Replenishment/ReplenishmentService.php:146 | OK | Approved quantity |
| replenishment_suggestions | uom | selemti | app/Models/ReplenishmentSuggestion.php:28<br>app/Services/Replenishment/ReplenishmentService.php:147 | OK | Unit of measure |
| replenishment_suggestions | consumo_promedio_diario | selemti | app/Models/ReplenishmentSuggestion.php:29<br>app/Services/Replenishment/ReplenishmentService.php:148 | OK | Average daily consumption |
| replenishment_suggestions | dias_stock_restante | selemti | app/Models/ReplenishmentSuggestion.php:30<br>app/Services/Replenishment/ReplenishmentService.php:149 | OK | Days remaining stock |
| replenishment_suggestions | fecha_agotamiento_estimada | selemti | app/Models/ReplenishmentSuggestion.php:31<br>app/Services/Replenishment/ReplenishmentService.php:150 | OK | Estimated depletion date |
| replenishment_suggestions | estado | selemti | app/Models/ReplenishmentSuggestion.php:32<br>app/Services/Replenishment/ReplenishmentService.php:151 | OK | Status field |
| replenishment_suggestions | purchase_request_id | selemti | app/Models/ReplenishmentSuggestion.php:35<br>app/Services/Replenishment/ReplenishmentService.php:154 | OK | Purchase request foreign key |
| replenishment_suggestions | production_order_id | selemti | app/Models/ReplenishmentSuggestion.php:36<br>app/Services/Replenishment/ReplenishmentService.php:155 | OK | Production order foreign key |
| replenishment_suggestions | sugerido_en | selemti | app/Models/ReplenishmentSuggestion.php:37<br>app/Services/Replenishment/ReplenishmentService.php:152 | OK | Suggested at |
| replenishment_suggestions | revisado_en | selemti | app/Models/ReplenishmentSuggestion.php:38<br>app/Services/Replenishment/ReplenishmentService.php:156 | OK | Reviewed at |
| replenishment_suggestions | revisado_por | selemti | app/Models/ReplenishmentSuggestion.php:39<br>app/Services/Replenishment/ReplenishmentService.php:157 | OK | Reviewed by |
| replenishment_suggestions | convertido_en | selemti | app/Models/ReplenishmentSuggestion.php:40<br>app/Services/Replenishment/ReplenishmentService.php:158 | OK | Converted at |
| replenishment_suggestions | caduca_en | selemti | app/Models/ReplenishmentSuggestion.php:41<br>app/Services/Replenishment/ReplenishmentService.php:159 | OK | Expires at |
| replenishment_suggestions | motivo | selemti | app/Models/ReplenishmentSuggestion.php:42<br>app/Services/Replenishment/ReplenishmentService.php:160 | OK | Reason |
| replenishment_suggestions | motivo_rechazo | selemti | app/Models/ReplenishmentSuggestion.php:43<br>app/Services/Replenishment/ReplenishmentService.php:161 | OK | Rejection reason |
| replenishment_suggestions | notas | selemti | app/Models/ReplenishmentSuggestion.php:44<br>app/Services/Replenishment/ReplenishmentService.php:162 | OK | Notes |
| replenishment_suggestions | meta | selemti | app/Models/ReplenishmentSuggestion.php:45<br>app/Services/Replenishment/ReplenishmentService.php:163 | OK | Metadata |
| replenishment_suggestions | created_at | selemti | app/Models/ReplenishmentSuggestion.php:46<br>app/Services/Replenishment/ReplenishmentService.php:164 | OK | Created timestamp |
| replenishment_suggestions | updated_at | selemti | app/Models/ReplenishmentSuggestion.php:47<br>app/Services/Replenishment/ReplenishmentService.php:165 | OK | Updated timestamp |

### 2.5 POS / Ventas

| Tabla BD | Columna BD | Esquema | Archivos/Líneas donde se usa en código | Estado | Notas |
|----------|------------|---------|----------------------------------------|--------|-------|
| ticket | id | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Primary key |
| ticket | global_id | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Global identifier |
| ticket | create_date | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Creation date |
| ticket | closing_date | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Closing date |
| ticket | active_date | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Active date |
| ticket | deliveery_date | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Delivery date |
| ticket | creation_hour | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Creation hour |
| ticket | paid | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Paid status |
| ticket | voided | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Voided status |
| ticket | void_reason | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Void reason |
| ticket | wasted | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Wasted status |
| ticket | refunded | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Refunded status |
| ticket | settled | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Settled status |
| ticket | drawer_resetted | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Drawer reset status |
| ticket | sub_total | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Sub total |
| ticket | total_discount | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Total discount |
| ticket | total_tax | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Total tax |
| ticket | total_price | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Total price |
| ticket | paid_amount | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Paid amount |
| ticket | due_amount | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Due amount |
| ticket | advance_amount | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Advance amount |
| ticket | adjustment_amount | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Adjustment amount |
| ticket | number_of_guests | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Number of guests |
| ticket | status | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Status |
| ticket | bar_tab | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Bar tab flag |
| ticket | is_tax_exempt | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Tax exempt flag |
| ticket | is_re_opened | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Reopened flag |
| ticket | service_charge | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Service charge |
| ticket | delivery_charge | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Delivery charge |
| ticket | customer_id | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Customer ID |
| ticket | delivery_address | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Delivery address |
| ticket | customer_pickeup | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Customer pickup flag |
| ticket | delivery_extra_info | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Delivery extra info |
| ticket | ticket_type | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Ticket type |
| ticket | shift_id | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Shift ID |
| ticket | owner_id | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Owner ID |
| ticket | driver_id | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Driver ID |
| ticket | gratuity_id | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Gratuity ID |
| ticket | void_by_user | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Void by user |
| ticket | terminal_id | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Terminal ID |
| ticket | folio_date | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Folio date |
| ticket | branch_key | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Branch key |
| ticket | daily_folio | public | app/Services/PosRepositories/TicketRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Daily folio |
| ticket_item | id | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Primary key |
| ticket_item | item_id | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item ID |
| ticket_item | item_count | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item count |
| ticket_item | item_quantity | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item quantity |
| ticket_item | item_name | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item name |
| ticket_item | item_unit_name | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item unit name |
| ticket_item | group_name | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Group name |
| ticket_item | category_name | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Category name |
| ticket_item | item_price | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item price |
| ticket_item | item_tax_rate | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Item tax rate |
| ticket_item | sub_total | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Sub total |
| ticket_item | sub_total_without_modifiers | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Sub total without modifiers |
| ticket_item | discount | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Discount |
| ticket_item | tax_amount | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Tax amount |
| ticket_item | tax_amount_without_modifiers | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Tax amount without modifiers |
| ticket_item | total_price | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Total price |
| ticket_item | total_price_without_modifiers | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Total price without modifiers |
| ticket_item | beverage | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Beverage flag |
| ticket_item | inventory_handled | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Inventory handled flag |
| ticket_item | print_to_kitchen | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Print to kitchen flag |
| ticket_item | treat_as_seat | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Treat as seat flag |
| ticket_item | seat_number | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Seat number |
| ticket_item | fractional_unit | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Fractional unit flag |
| ticket_item | has_modiiers | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | MISMATCH | DB has typo: has_modiiers vs has_modifiers |
| ticket_item | printed_to_kitchen | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Printed to kitchen flag |
| ticket_item | status | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Status |
| ticket_item | stock_amount_adjusted | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Stock amount adjusted |
| ticket_item | pizza_type | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Pizza type flag |
| ticket_item | size_modifier_id | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Size modifier ID |
| ticket_item | ticket_id | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Ticket ID |
| ticket_item | pg_id | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | PG ID |
| ticket_item | pizza_section_mode | public | app/Services/PosRepositories/TicketItemRepository.php:15<br>app/Console/Commands/PosReprocess.php:60 | OK | Pizza section mode |
| menu_item | id | public | app/Models/Pos/MenuItem.php:11<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Primary key |
| menu_item | name | public | app/Models/Pos/MenuItem.php:16<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Item name |
| menu_item | description | public | app/Models/Pos/MenuItem.php:17<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Description |
| menu_item | unit_name | public | app/Models/Pos/MenuItem.php:18<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Unit name |
| menu_item | translated_name | public | app/Models/Pos/MenuItem.php:19<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Translated name |
| menu_item | barcode | public | app/Models/Pos/MenuItem.php:20<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Barcode |
| menu_item | buy_price | public | app/Models/Pos/MenuItem.php:21<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Buy price |
| menu_item | stock_amount | public | app/Models/Pos/MenuItem.php:22<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Stock amount |
| menu_item | price | public | app/Models/Pos/MenuItem.php:23<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Selling price |
| menu_item | discount_rate | public | app/Models/Pos/MenuItem.php:24<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Discount rate |
| menu_item | visible | public | app/Models/Pos/MenuItem.php:25<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Visible flag |
| menu_item | disable_when_stock_amount_is_zero | public | app/Models/Pos/MenuItem.php:26<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Disable when no stock |
| menu_item | sort_order | public | app/Models/Pos/MenuItem.php:27<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Sort order |
| menu_item | btn_color | public | app/Models/Pos/MenuItem.php:28<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Button color |
| menu_item | text_color | public | app/Models/Pos/MenuItem.php:29<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Text color |
| menu_item | image | public | app/Models/Pos/MenuItem.php:30<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Image |
| menu_item | show_image_only | public | app/Models/Pos/MenuItem.php:31<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Show image only |
| menu_item | fractional_unit | public | app/Models/Pos/MenuItem.php:32<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Fractional unit |
| menu_item | pizza_type | public | app/Models/Pos/MenuItem.php:33<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Pizza type |
| menu_item | default_sell_portion | public | app/Models/Pos/MenuItem.php:34<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Default selling portion |
| menu_item | group_id | public | app/Models/Pos/MenuItem.php:35<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Group ID |
| menu_item | tax_group_id | public | app/Models/Pos/MenuItem.php:36<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Tax group ID |
| menu_item | recepie | public | app/Models/Pos/MenuItem.php:37<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Recipe ID |
| menu_item | pg_id | public | app/Models/Pos/MenuItem.php:38<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | PG ID |
| menu_item | tax_id | public | app/Models/Pos/MenuItem.php:39<br>app/Services/Menu/MenuEngineeringService.php:54 | OK | Tax ID |
| menu_group | id | public | app/Models/Pos/MenuGroup.php:11<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Primary key |
| menu_group | name | public | app/Models/Pos/MenuGroup.php:12<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Group name |
| menu_group | translated_name | public | app/Models/Pos/MenuGroup.php:13<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Translated name |
| menu_group | visible | public | app/Models/Pos/MenuGroup.php:14<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Visible flag |
| menu_group | sort_order | public | app/Models/Pos/MenuGroup.php:15<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Sort order |
| menu_group | btn_color | public | app/Models/Pos/MenuGroup.php:16<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Button color |
| menu_group | text_color | public | app/Models/Pos/MenuGroup.php:17<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Text color |
| menu_group | category_id | public | app/Models/Pos/MenuGroup.php:18<br>app/Services/Menu/MenuEngineeringService.php:56 | OK | Category ID |
| transactions | id | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Primary key |
| transactions | payment_type | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Payment type |
| transactions | global_id | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Global identifier |
| transactions | transaction_time | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Transaction time |
| transactions | amount | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Amount |
| transactions | tips_amount | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Tips amount |
| transactions | tips_exceed_amount | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Tips exceed amount |
| transactions | tender_amount | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Tender amount |
| transactions | transaction_type | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Transaction type |
| transactions | custom_payment_name | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Custom payment name |
| transactions | custom_payment_ref | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Custom payment reference |
| transactions | custom_payment_field_name | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Custom payment field name |
| transactions | payment_sub_type | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Payment sub type |
| transactions | captured | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Captured flag |
| transactions | voided | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Voided flag |
| transactions | authorizable | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Authorizable flag |
| transactions | card_holder_name | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card holder name |
| transactions | card_number | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card number |
| transactions | card_auth_code | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card auth code |
| transactions | card_type | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card type |
| transactions | card_transaction_id | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card transaction ID |
| transactions | card_merchant_gateway | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card merchant gateway |
| transactions | card_reader | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card reader |
| transactions | card_aid | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card AID |
| transactions | card_arqc | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card ARQC |
| transactions | card_ext_data | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Card ext data |
| transactions | gift_cert_number | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Gift cert number |
| transactions | gift_cert_face_value | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Gift cert face value |
| transactions | gift_cert_paid_amount | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Gift cert paid amount |
| transactions | gift_cert_cash_back_amount | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Gift cert cash back amount |
| transactions | drawer_resetted | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Drawer reset flag |
| transactions | note | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Note |
| transactions | terminal_id | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Terminal ID |
| transactions | ticket_id | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Ticket ID |
| transactions | user_id | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | User ID |
| transactions | payout_reason_id | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Payout reason ID |
| transactions | payout_recepient_id | public | app/Services/PosRepositories/TransactionRepository.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Payout recipient ID |
| terminal | id | public | app/Models/Pos/Terminal.php:11<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Primary key |
| terminal | name | public | app/Models/Pos/Terminal.php:12<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Terminal name |
| terminal | terminal_key | public | app/Models/Pos/Terminal.php:13<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Terminal key |
| terminal | opening_balance | public | app/Models/Pos/Terminal.php:14<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Opening balance |
| terminal | current_balance | public | app/Models/Pos/Terminal.php:15<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Current balance |
| terminal | has_cash_drawer | public | app/Models/Pos/Terminal.php:16<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Has cash drawer |
| terminal | in_use | public | app/Models/Pos/Terminal.php:17<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | In use flag |
| terminal | active | public | app/Models/Pos/Terminal.php:18<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Active flag |
| terminal | location | public | app/Models/Pos/Terminal.php:19<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Location |
| terminal | floor_id | public | app/Models/Pos/Terminal.php:20<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Floor ID |
| terminal | assigned_user | public | app/Models/Pos/Terminal.php:21<br>app/Http/Controllers/Api/ReportsController.php:345 | OK | Assigned user |

### 2.6 Caja / Caja chica

| Tabla BD | Columna BD | Esquema | Archivos/Líneas donde se usa en código | Estado | Notas |
|----------|------------|---------|----------------------------------------|--------|-------|
| caja_fondo | id | selemti | app/Models/CashFund.php:11<br>app/Services/Cash/CashFundService.php:23 | OK | Primary key |
| caja_fondo | folio | selemti | app/Models/CashFund.php:14<br>app/Services/Cash/CashFundService.php:26 | OK | Folio number |
| caja_fondo | fecha_apertura | selemti | app/Models/CashFund.php:15<br>app/Services/Cash/CashFundService.php:27 | OK | Opening date |
| caja_fondo | fecha_cierre | selemti | app/Models/CashFund.php:16<br>app/Services/Cash/CashFundService.php:28 | OK | Closing date |
| caja_fondo | estado | selemti | app/Models/CashFund.php:17<br>app/Services/Cash/CashFundService.php:29 | OK | Status |
| caja_fondo | monto_apertura | selemti | app/Models/CashFund.php:18<br>app/Services/Cash/CashFundService.php:30 | OK | Opening amount |
| caja_fondo | monto_cierre | selemti | app/Models/CashFund.php:19<br>app/Services/Cash/CashFundService.php:31 | OK | Closing amount |
| caja_fondo | responsable_id | selemti | app/Models/CashFund.php:20<br>app/Services/Cash/CashFundService.php:32 | OK | Responsible person ID |
| caja_fondo | sucursal_id | selemti | app/Models/CashFund.php:21<br>app/Services/Cash/CashFundService.php:33 | OK | Branch ID |
| caja_fondo | created_at | selemti | app/Models/CashFund.php:22<br>app/Services/Cash/CashFundService.php:34 | OK | Created timestamp |
| caja_fondo | updated_at | selemti | app/Models/CashFund.php:23<br>app/Services/Cash/CashFundService.php:35 | OK | Updated timestamp |
| caja_fondo_mov | id | selemti | app/Models/CashFundMovement.php:11<br>app/Services/Cash/CashFundService.php:147 | OK | Primary key |
| caja_fondo_mov | caja_fondo_id | selemti | app/Models/CashFundMovement.php:12<br>app/Services/Cash/CashFundService.php:148 | OK | Cash fund foreign key |
| caja_fondo_mov | tipo | selemti | app/Models/CashFundMovement.php:13<br>app/Services/Cash/CashFundService.php:149 | OK | Movement type |
| caja_fondo_mov | monto | selemti | app/Models/CashFundMovement.php:14<br>app/Services/Cash/CashFundService.php:150 | OK | Amount |
| caja_fondo_mov | metodo | selemti | app/Models/CashFundMovement.php:15<br>app/Services/Cash/CashFundService.php:151 | OK | Payment method |
| caja_fondo_mov | descripcion | selemti | app/Models/CashFundMovement.php:16<br>app/Services/Cash/CashFundService.php:152 | OK | Description |
| caja_fondo_mov | referencia_tipo | selemti | app/Models/CashFundMovement.php:17<br>app/Services/Cash/CashFundService.php:153 | OK | Reference type |
| caja_fondo_mov | referencia_id | selemti | app/Models/CashFundMovement.php:18<br>app/Services/Cash/CashFundService.php:154 | OK | Reference ID |
| caja_fondo_mov | usuario_id | selemti | app/Models/CashFundMovement.php:19<br>app/Services/Cash/CashFundService.php:155 | OK | User ID |
| caja_fondo_mov | proveedor_id | selemti | app/Models/CashFundMovement.php:35<br>app/Services/Cash/CashFundService.php:149 | FANTASMA | Campo no existe en BD pero sí en modelo |
| caja_fondo_mov | created_at | selemti | app/Models/CashFundMovement.php:20<br>app/Services/Cash/CashFundService.php:156 | OK | Created timestamp |
| caja_fondo_mov | updated_at | selemti | app/Models/CashFundMovement.php:21<br>app/Services/Cash/CashFundService.php:157 | OK | Updated timestamp |
| cash_funds | id | selemti | app/Models/CashFund.php:11 | OK | Primary key |
| cash_funds | folio | selemti | app/Models/CashFund.php:14 | OK | Folio number |
| cash_funds | responsable_id | selemti | app/Models/CashFund.php:15 | OK | Responsible person ID |
| cash_funds | monto_inicial | selemti | app/Models/CashFund.php:16 | OK | Initial amount |
| cash_funds | monto_sistema | selemti | app/Models/CashFund.php:17 | OK | System amount |
| cash_funds | monto_real | selemti | app/Models/CashFund.php:18 | OK | Real amount |
| cash_funds | diferencia | selemti | app/Models/CashFund.php:19 | OK | Difference |
| cash_funds | estado | selemti | app/Models/CashFund.php:20 | OK | Status |
| cash_funds | observaciones | selemti | app/Models/CashFund.php:21 | OK | Observations |
| cash_funds | fecha_apertura | selemti | app/Models/CashFund.php:22 | OK | Opening date |
| cash_funds | fecha_cierre | selemti | app/Models/CashFund.php:23 | OK | Closing date |
| cash_funds | aprobada_por | selemti | app/Models/CashFund.php:24 | OK | Approved by |
| cash_funds | created_at | selemti | app/Models/CashFund.php:25 | OK | Created timestamp |
| cash_funds | updated_at | selemti | app/Models/CashFund.php:26 | OK | Updated timestamp |
| cash_fund_movements | id | selemti | app/Models/CashFundMovement.php:11<br>app/Services/Cash/CashFundService.php:147 | OK | Primary key |
| cash_fund_movements | cash_fund_id | selemti | app/Models/CashFundMovement.php:12<br>app/Services/Cash/CashFundService.php:148 | OK | Cash fund foreign key |
| cash_fund_movements | tipo | selemti | app/Models/CashFundMovement.php:13<br>app/Services/Cash/CashFundService.php:149 | OK | Movement type |
| cash_fund_movements | monto | selemti | app/Models/CashFundMovement.php:14<br>app/Services/Cash/CashFundService.php:150 | OK | Amount |
| cash_fund_movements | metodo | selemti | app/Models/CashFundMovement.php:15<br>app/Services/Cash/CashFundService.php:151 | OK | Payment method |
| cash_fund_movements | descripcion | selemti | app/Models/CashFundMovement.php:16<br>app/Services/Cash/CashFundService.php:152 | OK | Description |
| cash_fund_movements | referencia_tipo | selemti | app/Models/CashFundMovement.php:17<br>app/Services/Cash/CashFundService.php:153 | OK | Reference type |
| cash_fund_movements | referencia_id | selemti | app/Models/CashFundMovement.php:18<br>app/Services/Cash/CashFundService.php:154 | OK | Reference ID |
| cash_fund_movements | usuario_id | selemti | app/Models/CashFundMovement.php:19<br>app/Services/Cash/CashFundService.php:155 | OK | User ID |
| cash_fund_movements | proveedor_id | selemti | - | FANTASMA | Campo no existe en BD pero sí en modelo |
| cash_fund_movements | created_at | selemti | app/Models/CashFundMovement.php:20<br>app/Services/Cash/CashFundService.php:156 | OK | Created timestamp |
| cash_fund_movements | updated_at | selemti | app/Models/CashFundMovement.php:21<br>app/Services/Cash/CashFundService.php:157 | OK | Updated timestamp |

### 2.7 Finanzas

| Tabla BD | Columna BD | Esquema | Archivos/Líneas donde se usa en código | Estado | Notas |
|----------|------------|---------|----------------------------------------|--------|-------|
| sesion_cajon | id | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | usuario_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | terminal_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | cajero_usuario_id | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | apertura_ts | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | cierre_ts | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | sistema_efectivo | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | sistema_total | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | sistema_descuentos | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | sistema_anulaciones | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | sistema_retiros | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | sistema_efectivo_esperado | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | declarado_precorte_efectivo | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | declarado_post_efectivo | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | declarado_post_tarjetas | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | diferencia_efectivo | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | diferencia_no_efectivo | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | created_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| sesion_cajon | updated_at | selemti | - | NO_USADO | Table exists but not referenced in code |
| formas_pago | id | selemti | - | FANTASMA | Tabla no existe en BD pero es referenciada en vistas |
| formas_pago | codigo | selemti | - | FANTASMA | Tabla no existe en BD pero es referenciada en vistas |
| formas_pago | nombre | selemti | - | FANTASMA | Tabla no existe en BD pero es referenciada en vistas |

### 2.8 Reports / KPIs

| Tabla BD | Columna BD | Esquema | Archivos/Líneas donde se usa en código | Estado | Notas |
|----------|------------|---------|----------------------------------------|--------|-------|
| vw_stock_valorizado | item_key | selemti | app/Services/Replenishment/ReplenishmentService.php:325 | OK | View column |
| vw_stock_valorizado | sucursal_id | selemti | app/Services/Replenishment/ReplenishmentService.php:325 | OK | View column |
| vw_stock_valorizado | stock | selemti | app/Services/Replenishment/ReplenishmentService.php:339 | OK | View column |
| vw_stock_valorizado | costo_wac | selemti | app/Services/Replenishment/ReplenishmentService.php:329 | OK | View column |
| vw_stock_valorizado | valor | selemti | app/Services/Replenishment/ReplenishmentService.php:329 | OK | View column |
| vw_stock_brechas | sucursal_id | selemti | app/Services/Replenishment/ReplenishmentService.php:74 | OK | View column |
| vw_stock_brechas | item_id | selemti | app/Services/Replenishment/ReplenishmentService.php:74 | OK | View column |
| vw_stock_brechas | min_qty | selemti | app/Services/Replenishment/ReplenishmentService.php:74 | OK | View column |
| vw_stock_brechas | max_qty | selemti | app/Services/Replenishment/ReplenishmentService.php:74 | OK | View column |
| vw_stock_brechas | stock_actual | selemti | app/Services/Replenishment/ReplenishmentService.php:74 | OK | View column |
| vw_stock_brechas | faltante | selemti | app/Services/Replenishment/ReplenishmentService.php:74 | OK | View column |
| vw_stock_brechas | excedente | selemti | app/Services/Replenishment/ReplenishmentService.php:74 | OK | View column |
| vw_consumo_vs_movimientos | fecha | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_consumo_vs_movimientos | sucursal_id | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_consumo_vs_movimientos | insumo_id | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_consumo_vs_movimientos | consumo_teorico | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_consumo_vs_movimientos | consumo_real | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_consumo_vs_movimientos | diferencia | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_ventas_por_item | fecha | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_ventas_por_item | terminal_id | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_ventas_por_item | sucursal_id | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_ventas_por_item | plu | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_ventas_por_item | unidades | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_ventas_por_item | venta_total | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_kpis_terminal_dia | fecha | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_kpis_terminal_dia | terminal_id | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_kpis_terminal_dia | sesiones | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_kpis_terminal_dia | sistema_efectivo | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_kpis_sucursal_dia | fecha | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_kpis_sucursal_dia | sucursal_id | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_kpis_sucursal_dia | sesiones | selemti | - | NO_USADO | View exists but not referenced in code |
| vw_kpis_sucursal_dia | sistema_efectivo | selemti | - | NO_USADO | View exists but not referenced in code |

### 2.9 Seguridad

| Tabla BD | Columna BD | Esquema | Archivos/Líneas donde se usa en código | Estado | Notas |
|----------|------------|---------|----------------------------------------|--------|-------|
| users | id | public | app/Models/User.php:9 | OK | Primary key |
| users | name | public | app/Models/User.php:10 | OK | User name |
| users | email | public | app/Models/User.php:11 | OK | User email |
| users | email_verified_at | public | app/Models/User.php:12 | OK | Email verified timestamp |
| users | password | public | app/Models/User.php:13 | OK | User password |
| users | remember_token | public | app/Models/User.php:14 | OK | Remember token |
| users | created_at | public | app/Models/User.php:15 | OK | Created timestamp |
| users | updated_at | public | app/Models/User.php:16 | OK | Updated timestamp |
| model_has_permissions | id | public | app/Models/User.php:20 | OK | Permission model relationship |
| model_has_permissions | permission_id | public | app/Models/User.php:21 | OK | Permission ID |
| model_has_permissions | model_type | public | app/Models/User.php:22 | OK | Model type |
| model_has_permissions | model_id | public | app/Models/User.php:23 | OK | Model ID |
| model_has_roles | id | public | app/Models/User.php:25 | OK | Role model relationship |
| model_has_roles | role_id | public | app/Models/User.php:26 | OK | Role ID |
| model_has_roles | model_type | public | app/Models/User.php:27 | OK | Model type |
| model_has_roles | model_id | public | app/Models/User.php:28 | OK | Model ID |
| permissions | id | public | app/Models\Role.php:8 | OK | Primary key |
| permissions | name | public | app/Models\Role.php:9 | OK | Permission name |
| permissions | guard_name | public | app/Models\Role.php:10 | OK | Guard name |
| permissions | created_at | public | app/Models\Role.php:11 | OK | Created timestamp |
| permissions | updated_at | public | app/Models\Role.php:12 | OK | Updated timestamp |
| roles | id | public | app/Models\Role.php:8 | OK | Primary key |
| roles | name | public | app/Models\Role.php:9 | OK | Role name |
| roles | guard_name | public | app/Models\Role.php:10 | OK | Guard name |
| roles | created_at | public | app/Models\Role.php:11 | OK | Created timestamp |
| roles | updated_at | public | app/Models\Role.php:12 | OK | Updated timestamp |
| role_has_permissions | permission_id | public | - | NO_USADO | Table exists but not referenced in code |
| role_has_permissions | role_id | public | - | NO_USADO | Table exists but not referenced in code |

### 2.10 Catálogos

| Tabla BD | Columna BD | Esquema | Archivos/Líneas donde se usa en código | Estado | Notas |
|----------|------------|---------|----------------------------------------|--------|-------|
| cat_unidades | id | selemti | app/Models/Catalogs/Unidad.php:9<br>app/Models/Inv/Item.php:45 | OK | Primary key |
| cat_unidades | clave | selemti | app/Models/Catalogs/Unidad.php:12 | OK | Unit key |
| cat_unidades | nombre | selemti | app/Models/Catalogs/Unidad.php:13 | OK | Unit name |
| cat_unidades | descripcion | selemti | app/Models/Catalogs/Unidad.php:14 | OK | Unit description |
| cat_unidades | activo | selemti | app/Models/Catalogs/Unidad.php:15 | OK | Active flag |
| cat_unidades | created_at | selemti | app/Models/Catalogs/Unidad.php:16 | OK | Created timestamp |
| cat_unidades | updated_at | selemti | app/Models/Catalogs/Unidad.php:17 | OK | Updated timestamp |
| cat_almacenes | id | selemti | app/Models/Catalogs/Almacen.php:9<br>app/Models/Inv/Stock.php:11 | OK | Primary key |
| cat_almacenes | codigo | selemti | app/Models/Catalogs/Almacen.php:12 | OK | Code field |
| cat_almacenes | nombre | selemti | app/Models/Catalogs/Almacen.php:13 | OK | Name field |
| cat_almacenes | descripcion | selemti | app/Models/Catalogs/Almacen.php:14 | OK | Description |
| cat_almacenes | activo | selemti | app/Models/Catalogs/Almacen.php:15 | OK | Active flag |
| cat_almacenes | created_at | selemti | app/Models/Catalogs/Almacen.php:16 | OK | Created timestamp |
| cat_almacenes | updated_at | selemti | app/Models/Catalogs/Almacen.php:17 | OK | Updated timestamp |
| cat_sucursales | id | selemti | app/Models/Catalogs/Sucursal.php:9 | OK | Primary key |
| cat_sucursales | codigo | selemti | app/Models/Catalogs/Sucursal.php:12 | OK | Code field |
| cat_sucursales | nombre | selemti | app/Models/Catalogs/Sucursal.php:13 | OK | Name field |
| cat_sucursales | direccion | selemti | app/Models/Catalogs/Sucursal.php:14 | OK | Address |
| cat_sucursales | activo | selemti | app/Models/Catalogs/Sucursal.php:15 | OK | Active flag |
| cat_sucursales | created_at | selemti | app/Models/Catalogs/Sucursal.php:16 | OK | Created timestamp |
| cat_sucursales | updated_at | selemti | app/Models/Catalogs/Sucursal.php:17 | OK | Updated timestamp |
| cat_proveedores | id | selemti | app/Models/Catalogs/Proveedor.php:10 | OK | Primary key |
| cat_proveedores | rfc | selemti | app/Models/Catalogs/Proveedor.php:11 | OK | RFC field |
| cat_proveedores | nombre | selemti | app/Models/Catalogs/Proveedor.php:12 | OK | Name field |
| cat_proveedores | telefono | selemti | app/Models/Catalogs/Proveedor.php:13 | OK | Phone field |
| cat_proveedores | email | selemti | app/Models/Catalogs/Proveedor.php:14 | OK | Email field |
| cat_proveedores | activo | selemti | app/Models/Catalogs/Proveedor.php:15 | OK | Active flag |
| cat_proveedores | created_at | selemti | app/Models/Catalogs/Proveedor.php:16 | OK | Created timestamp |
| cat_proveedores | updated_at | selemti | app/Models/Catalogs/Proveedor.php:17 | OK | Updated timestamp |

## 3. Campos FANTASMA (resumen global)

- **mov_inv.qty**: Campo referenciado en código pero no existe en BD (debería ser 'cantidad')
- **stock.item_id, almacen_id, cantidad_actual**: Tabla 'stock' no existe en BD pero es referenciada en código
- **recepcion.id, proveedor_id, almacen_id**: Tabla 'recepcion' no existe en BD pero es referenciada en código
- **caja_fondo_mov.proveedor_id**: Campo no existe en BD pero sí en modelo
- **cash_fund_movements.proveedor_id**: Campo no existe en BD pero sí en modelo
- **formas_pago tabla**: Tabla no existe en BD pero es referenciada en vistas

## 4. MISMATCH críticos (resumen global)

1. **mov_inv.ts vs fecha_movimiento**: Código espera fecha_movimiento pero BD tiene ts
2. **mov_inv.costo_unit vs costo_unitario**: Código espera costo_unitario pero BD tiene costo_unit
3. **mov_inv.tipo vs tipo_movimiento**: Código espera tipo_movimiento pero BD tiene tipo
4. **mov_inv.ref_tipo vs referencia_tipo**: Código espera referencia_tipo pero BD tiene ref_tipo
5. **mov_inv.ref_id vs referencia_id**: Código espera referencia_id pero BD tiene ref_id
6. **mov_inv.sucursal_id vs almacen_id**: Código espera almacen_id pero BD tiene sucursal_id
7. **stock_policy.sucursal_id vs almacen_id**: Código espera almacen_id pero BD tiene sucursal_id
8. **pos_map.receta_id vs receta_version_id**: Código usa receta_version_id pero BD tiene 'receta_id'
9. **receta.porciones vs porciones_standard**: Código espera porciones_standard pero BD tiene 'porciones'
10. **receta.pvp_objetivo vs precio_venta_sugerido**: Código espera precio_venta_sugerido pero BD tiene 'pvp_objetivo'
11. **ticket_item.has_modiiers vs has_modifiers**: DB has typo 'has_modiiers' instead of 'has_modifiers'
12. **receta_version.usuario_publicador vs publicador_usuario**: Código espera publicador_usuario pero BD tiene 'usuario_publicador'
13. **receta_version.fecha_publicacion vs fecha_publicado**: Código espera fecha_publicado pero BD tiene 'fecha_publicacion'
14. **hist_cost_insumo.algoritmo_principal**: Código espera 'algoritmo_principal' como string pero BD tiene como texto
15. **transfer_det.unidad_medida**: Campo no existe en BD pero es esperado en código

## 5. Recomendaciones generales

### Inventario:
- Ajustar el modelo Movimiento para mapear correctamente los campos: ts→fecha_movimiento, tipo→tipo_movimiento, costo_unit→costo_unitario, ref_tipo→referencia_tipo, ref_id→referencia_id, sucursal_id→almacen_id
- Verificar por qué las tablas 'recepcion' y 'stock' no existen en la BD pero sí están referenciadas en el código
- Implementar los campos faltantes en transfer_det como unidad_medida si son necesarios
- Revisar la tabla recepcion_det que existe en BD pero no se referencia en código

### Recetas:
- Ajustar el modelo Receta para mapear correctamente los campos: porciones→porciones_standard, pvp_objetivo→precio_venta_sugerido
- Ajustar el modelo PosMap para manejar correctamente los campos receta_id y receta_version_id
- Verificar la inconsistencia entre receta_id y receta_version_id en la tabla pos_map

### Producción:
- Revisar las tablas op_cab, op_insumo, op_yield, prod_cab, prod_det, sol_prod_cab, sol_prod_det ya que existen en la BD pero no están siendo referenciadas en el código
- Asegurar que los servicios de producción usen las tablas correctas según el análisis
- Verificar que el modelo de merma esté correctamente implementado o eliminar la tabla si no se usa

### Purchasing:
- Implementar el uso de los campos faltantes en purchase_suggestions y purchase_suggestion_lines
- Asegurar consistencia en la nomenclatura de campos entre código y base de datos
- Verificar que todos los campos de proveedores estén siendo usados adecuadamente
- Completar la implementación del flujo completo de suggestions si es necesario

### POS/Ventas:
- Corregir el campo has_modiiers a has_modifiers en la base de datos (tiene typo)
- Asegurar consistencia en mapeo de campos entre BD y modelos POS
- Verificar que todos los campos referenciados en el código existen en las tablas correspondientes

### Caja chica:
- Asegurar que los campos proveedor_id en caja_fondo_mov y cash_fund_movements estén implementados en la base de datos
- Verificar consistencia en campos de mapeo entre modelos y base de datos

### Reports:
- Implementar vistas faltantes que son referenciadas en el código
- Asegurar que todas las columnas referenciadas en reportes existen en las vistas correspondientes