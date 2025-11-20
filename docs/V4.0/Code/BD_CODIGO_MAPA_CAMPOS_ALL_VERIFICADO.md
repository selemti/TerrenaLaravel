# VERIFICACIÓN DEL MAPA BD ↔ CÓDIGO (TODOS LOS MÓDULOS)

| modulo | esquema | tabla_bd | columna_bd | existe_en_bd | estado_original | estado_bd | decision_final | notas |
|--------|---------|----------|------------|--------------|-----------------|-----------|----------------|-------|
| Inventario | selemti | mov_inv | id | SI | OK | OK | CONFIABLE | Primary key |
| Inventario | selemti | mov_inv | ts | SI | MISMATCH | OK | CONFIABLE | Código espera fecha_movimiento pero BD tiene ts |
| Inventario | selemti | mov_inv | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| Inventario | selemti | mov_inv | lote_id | SI | OK | OK | CONFIABLE | Lot ID field |
| Inventario | selemti | mov_inv | cantidad | SI | OK | OK | CONFIABLE | Quantity field |
| Inventario | selemti | mov_inv | qty_original | SI | OK | OK | CONFIABLE | Original quantity |
| Inventario | selemti | mov_inv | uom_original_id | SI | OK | OK | CONFIABLE | Original UOM ID |
| Inventario | selemti | mov_inv | costo_unit | SI | MISMATCH | OK | CONFIABLE | Código espera costo_unitario pero BD tiene costo_unit |
| Inventario | selemti | mov_inv | tipo | SI | MISMATCH | OK | CONFIABLE | Código espera tipo_movimiento pero BD tiene tipo |
| Inventario | selemti | mov_inv | ref_tipo | SI | MISMATCH | OK | CONFIABLE | Código espera referencia_tipo pero BD tiene ref_tipo |
| Inventario | selemti | mov_inv | ref_id | SI | MISMATCH | OK | CONFIABLE | Código espera referencia_id pero BD tiene ref_id |
| Inventario | selemti | mov_inv | sucursal_id | SI | MISMATCH | OK | CONFIABLE | Código espera almacen_id pero BD tiene sucursal_id |
| Inventario | selemti | mov_inv | usuario_id | SI | OK | OK | CONFIABLE | User ID field |
| Inventario | selemti | mov_inv | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| Inventario | selemti | stock | item_id | NO | FANTASMA | NO_EXISTE | CONFIABLE | Tabla stock no existe en BD pero es referenciada en código |
| Inventario | selemti | stock | almacen_id | NO | FANTASMA | NO_EXISTE | CONFIABLE | Tabla stock no existe en BD pero es referenciada en código |
| Inventario | selemti | stock | cantidad_actual | NO | FANTASMA | NO_EXISTE | CONFIABLE | Tabla stock no existe en BD pero es referenciada en código |
| Inventario | selemti | recepcion_cab | id | SI | OK | OK | CONFIABLE | Primary key - Corregido por auditoría CLAUDE: mapping tenía tabla como 'recepcion' pero DB usa 'recepcion_cab' |
| Inventario | selemti | recepcion_cab | proveedor_id | SI | OK | OK | CONFIABLE | Foreign key - Corregido por auditoría CLAUDE: mapping tenía tabla como 'recepcion' pero DB usa 'recepcion_cab' |
| Inventario | selemti | recepcion_cab | almacen_id | SI | OK | OK | CONFIABLE | Warehouse foreign key - Corregido por auditoría CLAUDE: mapping tenía tabla como 'recepcion' pero DB usa 'recepcion_cab' |
| Inventario | selemti | recepcion_cab | estado | SI | OK | OK | CONFIABLE | Estado de la recepción (BORRADOR/VALIDADA/POSTEADA) - Columna clave para state machine implementado en Sprint 1 |
| Inventario | selemti | recepcion_det | id | SI | OK | OK | CONFIABLE | Primary key |
| Inventario | selemti | recepcion_det | recepcion_id | SI | OK | OK | CONFIABLE | Foreign key |
| Inventario | selemti | recepcion_det | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| Inventario | selemti | recepcion_det | bodega_id | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | recepcion_det | qty | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | recepcion_det | um_id | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | recepcion_det | costo_unit | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | recepcion_det | batch_id | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | recepcion_det | temperatura | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | recepcion_det | doc_url | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | recepcion_det | meta | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | recepcion_det | created_at | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | recepcion_det | updated_at | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | recepcion_det | deleted_at | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | transfer_cab | id | SI | OK | OK | CONFIABLE | Primary key |
| Inventario | selemti | transfer_cab | origen_almacen_id | SI | OK | OK | CONFIABLE | Foreign key |
| Inventario | selemti | transfer_cab | destino_almacen_id | SI | OK | OK | CONFIABLE | Foreign key |
| Inventario | selemti | transfer_cab | estado | SI | OK | OK | CONFIABLE | Status enum |
| Inventario | selemti | transfer_cab | creada_por | SI | OK | OK | CONFIABLE | Foreign key |
| Inventario | selemti | transfer_cab | despachada_por | SI | OK | OK | CONFIABLE | Dispatch user |
| Inventario | selemti | transfer_cab | recibida_por | SI | OK | OK | CONFIABLE | Receive user |
| Inventario | selemti | transfer_cab | guia | SI | OK | OK | CONFIABLE | Guide number |
| Inventario | selemti | transfer_cab | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| Inventario | selemti | transfer_det | id | SI | OK | OK | CONFIABLE | Primary key |
| Inventario | selemti | transfer_det | transfer_id | SI | OK | OK | CONFIABLE | Foreign key |
| Inventario | selemti | transfer_det | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| Inventario | selemti | transfer_det | cantidad | SI | OK | OK | CONFIABLE | Quantity |
| Inventario | selemti | transfer_det | cantidad_despachada | SI | OK | OK | CONFIABLE | Dispatched quantity |
| Inventario | selemti | transfer_det | cantidad_recibida | SI | OK | OK | CONFIABLE | Received quantity |
| Inventario | selemti | transfer_det | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| Inventario | selemti | hist_cost_insumo | id | SI | OK | OK | CONFIABLE | Primary key |
| Inventario | selemti | hist_cost_insumo | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| Inventario | selemti | hist_cost_insumo | fecha_efectiva | SI | OK | OK | CONFIABLE | Effective date |
| Inventario | selemti | hist_cost_insumo | costo_wac | SI | OK | OK | CONFIABLE | WAC cost |
| Inventario | selemti | hist_cost_insumo | costo_peps | SI | OK | OK | CONFIABLE | FIFO cost |
| Inventario | selemti | hist_cost_insumo | costo_ueps | SI | OK | OK | CONFIABLE | LIFO cost |
| Inventario | selemti | hist_cost_insumo | costo_std | SI | OK | OK | CONFIABLE | Standard cost |
| Inventario | selemti | hist_cost_insumo | algoritmo_principal | SI | OK | OK | CONFIABLE | Main algorithm |
| Inventario | selemti | hist_cost_insumo | valid_from | SI | OK | OK | CONFIABLE | Valid from date |
| Inventario | selemti | hist_cost_insumo | valid_to | SI | OK | OK | CONFIABLE | Valid to date |
| Inventario | selemti | hist_cost_insumo | sys_from | SI | OK | OK | CONFIABLE | System from timestamp |
| Inventario | selemti | hist_cost_insumo | sys_to | SI | OK | OK | CONFIABLE | System to timestamp |
| Inventario | selemti | hist_cost_insumo | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| Inventario | selemti | hist_cost_insumo | updated_at | SI | OK | OK | CONFIABLE | Update timestamp |
| Inventario | selemti | hist_cost_insumo | deleted_at | SI | OK | OK | CONFIABLE | Delete timestamp |
| Inventario | selemti | stock_policy | id | SI | OK | OK | CONFIABLE | Primary key |
| Inventario | selemti | stock_policy | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| Inventario | selemti | stock_policy | sucursal_id | SI | MISMATCH | OK | CONFIABLE | Código espera almacen_id pero BD tiene sucursal_id |
| Inventario | selemti | stock_policy | almacen_id | SI | MISMATCH | OK | CONFIABLE | Código espera sucursal_id pero BD tiene almacen_id |
| Inventario | selemti | stock_policy | min_qty | SI | OK | OK | CONFIABLE | Minimum quantity |
| Inventario | selemti | stock_policy | max_qty | SI | OK | OK | CONFIABLE | Maximum quantity |
| Inventario | selemti | stock_policy | reorder_lote | SI | OK | OK | CONFIABLE | Reorder lot size |
| Inventario | selemti | stock_policy | activo | SI | OK | OK | CONFIABLE | Active flag |
| Inventario | selemti | stock_policy | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| Inventario | selemti | inventory_batch | id | SI | OK | OK | CONFIABLE | Primary key |
| Inventario | selemti | inventory_batch | item_id | SI | OK | OK | CONFIABLE | Item foreign key |
| Inventario | selemti | inventory_batch | lote_proveedor | SI | OK | OK | CONFIABLE | Supplier lot |
| Inventario | selemti | inventory_batch | fecha_recepcion | SI | OK | OK | CONFIABLE | Receipt date |
| Inventario | selemti | inventory_batch | fecha_caducidad | SI | OK | OK | CONFIABLE | Expiration date |
| Inventario | selemti | inventory_batch | temperatura_recepcion | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | inventory_batch | documento_url | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | inventory_batch | cantidad_original | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | inventory_batch | cantidad_actual | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | inventory_batch | estado | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | inventory_batch | ubicacion_id | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Inventario | selemti | inventory_batch | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| Inventario | selemti | inventory_batch | updated_at | SI | OK | OK | CONFIABLE | Update timestamp |
| Inventario | selemti | inventory_batch | unit_cost | SI | OK | OK | CONFIABLE | Unit cost field |
| Recetas | selemti | receta | id | SI | OK | OK | CONFIABLE | Primary key |
| Recetas | selemti | receta | codigo | SI | OK | OK | CONFIABLE | Recipe code |
| Recetas | selemti | receta | nombre | SI | OK | OK | CONFIABLE | Recipe name |
| Recetas | selemti | receta | porciones | SI | OK | OK | CONFIABLE | Number of portions |
| Recetas | selemti | receta | pvp_objetivo | SI | OK | OK | CONFIABLE | Target selling price |
| Recetas | selemti | receta | activo | SI | OK | OK | CONFIABLE | Active flag |
| Recetas | selemti | receta | meta | SI | OK | OK | CONFIABLE | Metadata JSON |
| Recetas | selemti | receta_version | id | SI | OK | OK | CONFIABLE | Primary key |
| Recetas | selemti | receta_version | receta_id | SI | OK | OK | CONFIABLE | Foreign key |
| Recetas | selemti | receta_version | version | SI | OK | OK | CONFIABLE | Version number |
| Recetas | selemti | receta_version | descripcion_cambios | SI | OK | OK | CONFIABLE | Changes description |
| Recetas | selemti | receta_version | fecha_efectiva | SI | OK | OK | CONFIABLE | Effective date |
| Recetas | selemti | receta_version | version_publicada | SI | OK | OK | CONFIABLE | Published version flag |
| Recetas | selemti | receta_version | usuario_publicador | SI | OK | OK | CONFIABLE | Publisher user |
| Recetas | selemti | receta_version | fecha_publicacion | SI | OK | OK | CONFIABLE | Publication date |
| Recetas | selemti | receta_version | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| Recetas | selemti | receta_insumo | id | SI | OK | OK | CONFIABLE | Primary key |
| Recetas | selemti | receta_insumo | receta_version_id | SI | OK | OK | CONFIABLE | Foreign key |
| Recetas | selemti | receta_insumo | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| Recetas | selemti | receta_insumo | cantidad | SI | OK | OK | CONFIABLE | Quantity needed |
| Recetas | selemti | pos_map | pos_system | SI | OK | OK | CONFIABLE | POS system identifier |
| Recetas | selemti | pos_map | plu | SI | OK | OK | CONFIABLE | PLU code |
| Recetas | selemti | pos_map | tipo | SI | OK | OK | CONFIABLE | Item type |
| Recetas | selemti | pos_map | receta_id | SI | MISMATCH | OK | CONFIABLE | Code expects receta_version_id but DB has receta_id |
| Recetas | selemti | pos_map | receta_version_id | SI | MISMATCH | OK | CONFIABLE | Code uses receta_version_id but DB has separate receta_id |
| Recetas | selemti | pos_map | valid_from | SI | OK | OK | CONFIABLE | Valid from date |
| Recetas | selemti | pos_map | valid_to | SI | OK | OK | CONFIABLE | Valid to date |
| Recetas | selemti | pos_map | sys_from | SI | OK | OK | CONFIABLE | System from timestamp |
| Recetas | selemti | pos_map | sys_to | SI | OK | OK | CONFIABLE | System to timestamp |
| Recetas | selemti | pos_map | meta | SI | FANTASMA | OK | ERROR_MAPA | Code references 'json' but DB has 'meta' |
| Recetas | selemti | pos_map | vigente_desde | SI | FANTASMA | OK | ERROR_MAPA | Field not referenced in models but exists in DB |
| Producción | selemti | production_orders | id | SI | OK | OK | CONFIABLE | Primary key |
| Producción | selemti | production_orders | folio | SI | OK | OK | CONFIABLE | Folio field |
| Producción | selemti | production_orders | recipe_id | SI | OK | OK | CONFIABLE | Recipe foreign key |
| Producción | selemti | production_orders | item_id | SI | OK | OK | CONFIABLE | Item foreign key |
| Producción | selemti | production_orders | qty_programada | SI | OK | OK | CONFIABLE | Planned quantity |
| Producción | selemti | production_orders | qty_producida | SI | OK | OK | CONFIABLE | Produced quantity |
| Producción | selemti | production_orders | qty_merma | SI | OK | OK | CONFIABLE | Waste quantity |
| Producción | selemti | production_orders | uom_base | SI | OK | OK | CONFIABLE | Base UOM |
| Producción | selemti | production_orders | sucursal_id | SI | OK | OK | CONFIABLE | Branch foreign key |
| Producción | selemti | production_orders | almacen_id | SI | OK | OK | CONFIABLE | Warehouse foreign key |
| Producción | selemti | production_orders | programado_para | SI | OK | OK | CONFIABLE | Scheduled for |
| Producción | selemti | production_orders | iniciado_en | SI | OK | OK | CONFIABLE | Started at |
| Producción | selemti | production_orders | cerrado_en | SI | OK | OK | CONFIABLE | Closed at |
| Producción | selemti | production_orders | estado | SI | OK | OK | CONFIABLE | Status field |
| Producción | selemti | production_orders | creado_por | SI | OK | OK | CONFIABLE | Created by |
| Producción | selemti | production_orders | aprobado_por | SI | OK | OK | CONFIABLE | Approved by |
| Producción | selemti | production_orders | notas | SI | OK | OK | CONFIABLE | Notes |
| Producción | selemti | production_orders | meta | SI | OK | OK | CONFIABLE | Metadata |
| Producción | selemti | production_orders | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Producción | selemti | production_orders | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Producción | selemti | production_order_inputs | id | SI | OK | OK | CONFIABLE | Primary key |
| Producción | selemti | production_order_inputs | production_order_id | SI | OK | OK | CONFIABLE | Production order foreign key |
| Producción | selemti | production_order_inputs | item_id | SI | OK | OK | CONFIABLE | Item foreign key |
| Producción | selemti | production_order_inputs | inventory_batch_id | SI | OK | OK | CONFIABLE | Inventory batch foreign key |
| Producción | selemti | production_order_inputs | qty | SI | OK | OK | CONFIABLE | Quantity |
| Producción | selemti | production_order_inputs | uom | SI | OK | OK | CONFIABLE | Unit of measure |
| Producción | selemti | production_order_inputs | meta | SI | OK | OK | CONFIABLE | Metadata |
| Producción | selemti | production_order_inputs | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Producción | selemti | production_order_inputs | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Producción | selemti | production_order_outputs | id | SI | OK | OK | CONFIABLE | Primary key |
| Producción | selemti | production_order_outputs | production_order_id | SI | OK | OK | CONFIABLE | Production order foreign key |
| Producción | selemti | production_order_outputs | item_id | SI | OK | OK | CONFIABLE | Item foreign key |
| Producción | selemti | production_order_outputs | inventory_batch_id | SI | OK | OK | CONFIABLE | Inventory batch foreign key |
| Producción | selemti | production_order_outputs | lote_producido | SI | OK | OK | CONFIABLE | Produced batch |
| Producción | selemti | production_order_outputs | fecha_caducidad | SI | OK | OK | CONFIABLE | Expiration date |
| Producción | selemti | production_order_outputs | qty | SI | OK | OK | CONFIABLE | Quantity |
| Producción | selemti | production_order_outputs | uom | SI | OK | OK | CONFIABLE | Unit of measure |
| Producción | selemti | production_order_outputs | meta | SI | OK | OK | CONFIABLE | Metadata |
| Producción | selemti | production_order_outputs | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Producción | selemti | production_order_outputs | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Producción | selemti | op_produccion_cab | id | SI | OK | OK | CONFIABLE | Primary key |
| Producción | selemti | op_produccion_cab | receta_version_id | SI | OK | OK | CONFIABLE | Recipe version foreign key |
| Producción | selemti | op_produccion_cab | cantidad_planeada | SI | OK | OK | CONFIABLE | Planned quantity |
| Producción | selemti | op_produccion_cab | cantidad_real | SI | OK | OK | CONFIABLE | Real quantity |
| Producción | selemti | op_produccion_cab | fecha_produccion | SI | OK | OK | CONFIABLE | Production date |
| Producción | selemti | op_produccion_cab | estado | SI | OK | OK | CONFIABLE | Status field |
| Producción | selemti | op_produccion_cab | lote_resultado | SI | OK | OK | CONFIABLE | Result batch |
| Producción | selemti | op_produccion_cab | usuario_responsable | SI | OK | OK | CONFIABLE | Responsible user |
| Producción | selemti | op_produccion_cab | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| Producción | selemti | op_produccion_cab | updated_at | SI | OK | OK | CONFIABLE | Update timestamp |
| Producción | selemti | op_cab | id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | sucursal_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | receta_version_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | cantidad_objetivo | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | um_salida_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | estado | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | ts_apertura | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | ts_cierre | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | usuario_abre | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | usuario_cierra | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | lote_salida | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Producción | selemti | op_cab | meta | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | created_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | updated_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_cab | deleted_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | op_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | item_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | qty_teorica | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | qty_real | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | um_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | batch_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | meta | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | created_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | updated_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_insumo | deleted_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_yield | op_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_yield | cantidad_real | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_yield | merma_real | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_yield | evidencia_url | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | op_yield | meta | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_cab | id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_cab | sol_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_cab | fecha_programada | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_cab | estado | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_cab | creada_por | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_cab | aprobada_por | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_cab | created_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_det | id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_det | prod_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_det | sr_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_det | cantidad | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_det | rendimiento | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | prod_det | created_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_cab | id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_cab | sucursal_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_cab | fecha | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_cab | estado | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_cab | solicitada_por | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_cab | autorizada_por | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_cab | observaciones | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_cab | created_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_det | id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_det | sol_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_det | plu | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_det | cantidad | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_det | cantidad_autorizada | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | sol_prod_det | created_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | ts | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | tipo | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | item_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | batch_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | op_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | qty | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | um_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | usuario_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | motivo | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | meta | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | created_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | updated_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Producción | selemti | merma | deleted_at | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Purchasing | selemti | purchase_requests | id | SI | OK | OK | CONFIABLE | Primary key |
| Purchasing | selemti | purchase_requests | folio | SI | OK | OK | CONFIABLE | Folio field |
| Purchasing | selemti | purchase_requests | sucursal_id | SI | OK | OK | CONFIABLE | Branch foreign key |
| Purchasing | selemti | purchase_requests | created_by | SI | OK | OK | CONFIABLE | Created by |
| Purchasing | selemti | purchase_requests | requested_by | SI | OK | OK | CONFIABLE | Requested by |
| Purchasing | selemti | purchase_requests | requested_at | SI | OK | OK | CONFIABLE | Requested at |
| Purchasing | selemti | purchase_requests | estado | SI | OK | OK | CONFIABLE | Status field |
| Purchasing | selemti | purchase_requests | importe_estimado | SI | OK | OK | CONFIABLE | Estimated amount |
| Purchasing | selemti | purchase_requests | notas | SI | OK | OK | CONFIABLE | Notes |
| Purchasing | selemti | purchase_requests | meta | SI | OK | OK | CONFIABLE | Metadata |
| Purchasing | selemti | purchase_requests | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Purchasing | selemti | purchase_requests | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Purchasing | selemti | purchase_requests | fecha_requerida | SI | OK | OK | CONFIABLE | Required date |
| Purchasing | selemti | purchase_requests | almacen_destino_id | SI | OK | OK | CONFIABLE | Destination warehouse |
| Purchasing | selemti | purchase_requests | justificacion | SI | OK | OK | CONFIABLE | Justification |
| Purchasing | selemti | purchase_requests | urgente | SI | OK | OK | CONFIABLE | Urgent flag |
| Purchasing | selemti | purchase_requests | origen_suggestion_id | SI | OK | OK | CONFIABLE | Origin suggestion foreign key |
| Purchasing | selemti | purchase_request_lines | id | SI | OK | OK | CONFIABLE | Primary key |
| Purchasing | selemti | purchase_request_lines | request_id | SI | OK | OK | CONFIABLE | Request foreign key |
| Purchasing | selemti | purchase_request_lines | item_id | SI | OK | OK | CONFIABLE | Item foreign key |
| Purchasing | selemti | purchase_request_lines | qty | SI | OK | OK | CONFIABLE | Quantity |
| Purchasing | selemti | purchase_request_lines | uom | SI | OK | OK | CONFIABLE | Unit of measure |
| Purchasing | selemti | purchase_request_lines | fecha_requerida | SI | OK | OK | CONFIABLE | Required date |
| Purchasing | selemti | purchase_request_lines | preferred_vendor_id | SI | OK | OK | CONFIABLE | Preferred vendor foreign key |
| Purchasing | selemti | purchase_request_lines | last_price | SI | OK | OK | CONFIABLE | Last price |
| Purchasing | selemti | purchase_request_lines | estado | SI | OK | OK | CONFIABLE | Status field |
| Purchasing | selemti | purchase_request_lines | meta | SI | OK | OK | CONFIABLE | Metadata |
| Purchasing | selemti | purchase_request_lines | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Purchasing | selemti | purchase_request_lines | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Purchasing | selemti | purchase_orders | id | SI | OK | OK | CONFIABLE | Primary key |
| Purchasing | selemti | purchase_orders | folio | SI | OK | OK | CONFIABLE | Folio field |
| Purchasing | selemti | purchase_orders | quote_id | SI | OK | OK | CONFIABLE | Quote foreign key |
| Purchasing | selemti | purchase_orders | vendor_id | SI | OK | OK | CONFIABLE | Vendor foreign key |
| Purchasing | selemti | purchase_orders | sucursal_id | SI | OK | OK | CONFIABLE | Branch foreign key |
| Purchasing | selemti | purchase_orders | estado | SI | OK | OK | CONFIABLE | Status field |
| Purchasing | selemti | purchase_orders | fecha_promesa | SI | OK | OK | CONFIABLE | Promised date |
| Purchasing | selemti | purchase_orders | subtotal | SI | OK | OK | CONFIABLE | Subtotal |
| Purchasing | selemti | purchase_orders | descuento | SI | OK | OK | CONFIABLE | Discount |
| Purchasing | selemti | purchase_orders | impuestos | SI | OK | OK | CONFIABLE | Taxes |
| Purchasing | selemti | purchase_orders | total | SI | OK | OK | CONFIABLE | Total |
| Purchasing | selemti | purchase_orders | creado_por | SI | OK | OK | CONFIABLE | Created by |
| Purchasing | selemti | purchase_orders | aprobado_por | SI | OK | OK | CONFIABLE | Approved by |
| Purchasing | selemti | purchase_orders | aprobado_en | SI | OK | OK | CONFIABLE | Approved at |
| Purchasing | selemti | purchase_orders | notas | SI | OK | OK | CONFIABLE | Notes |
| Purchasing | selemti | purchase_orders | meta | SI | OK | OK | CONFIABLE | Metadata |
| Purchasing | selemti | purchase_orders | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Purchasing | selemti | purchase_orders | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Purchasing | selemti | purchase_order_lines | id | SI | OK | OK | CONFIABLE | Primary key |
| Purchasing | selemti | purchase_order_lines | order_id | SI | OK | OK | CONFIABLE | Order foreign key |
| Purchasing | selemti | purchase_order_lines | request_line_id | SI | OK | OK | CONFIABLE | Request line foreign key |
| Purchasing | selemti | purchase_order_lines | item_id | SI | OK | OK | CONFIABLE | Item foreign key |
| Purchasing | selemti | purchase_order_lines | qty | SI | OK | OK | CONFIABLE | Quantity |
| Purchasing | selemti | purchase_order_lines | uom | SI | OK | OK | CONFIABLE | Unit of measure |
| Purchasing | selemti | purchase_order_lines | precio_unitario | SI | OK | OK | CONFIABLE | Unit price |
| Purchasing | selemti | purchase_order_lines | descuento | SI | OK | OK | CONFIABLE | Discount |
| Purchasing | selemti | purchase_order_lines | impuestos | SI | OK | OK | CONFIABLE | Taxes |
| Purchasing | selemti | purchase_order_lines | total | SI | OK | OK | CONFIABLE | Total |
| Purchasing | selemti | purchase_order_lines | meta | SI | OK | OK | CONFIABLE | Metadata |
| Purchasing | selemti | purchase_order_lines | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Purchasing | selemti | purchase_order_lines | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Purchasing | selemti | purchase_vendor_quotes | id | SI | OK | OK | CONFIABLE | Primary key |
| Purchasing | selemti | purchase_vendor_quotes | request_id | SI | OK | OK | CONFIABLE | Request foreign key |
| Purchasing | selemti | purchase_vendor_quotes | vendor_id | SI | OK | OK | CONFIABLE | Vendor foreign key |
| Purchasing | selemti | purchase_vendor_quotes | folio_proveedor | SI | OK | OK | CONFIABLE | Vendor folio |
| Purchasing | selemti | purchase_vendor_quotes | estado | SI | OK | OK | CONFIABLE | Status field |
| Purchasing | selemti | purchase_vendor_quotes | enviada_en | SI | OK | OK | CONFIABLE | Sent at |
| Purchasing | selemti | purchase_vendor_quotes | recibida_en | SI | OK | OK | CONFIABLE | Received at |
| Purchasing | selemti | purchase_vendor_quotes | subtotal | SI | OK | OK | CONFIABLE | Subtotal |
| Purchasing | selemti | purchase_vendor_quotes | descuento | SI | OK | OK | CONFIABLE | Discount |
| Purchasing | selemti | purchase_vendor_quotes | impuestos | SI | OK | OK | CONFIABLE | Taxes |
| Purchasing | selemti | purchase_vendor_quotes | total | SI | OK | OK | CONFIABLE | Total |
| Purchasing | selemti | purchase_vendor_quotes | capturada_por | SI | OK | OK | CONFIABLE | Captured by |
| Purchasing | selemti | purchase_vendor_quotes | aprobada_por | SI | OK | OK | CONFIABLE | Approved by |
| Purchasing | selemti | purchase_vendor_quotes | aprobada_en | SI | OK | OK | CONFIABLE | Approved at |
| Purchasing | selemti | purchase_vendor_quotes | notas | SI | OK | OK | CONFIABLE | Notes |
| Purchasing | selemti | purchase_vendor_quotes | meta | SI | OK | OK | CONFIABLE | Metadata |
| Purchasing | selemti | purchase_vendor_quotes | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Purchasing | selemti | purchase_vendor_quotes | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Purchasing | selemti | purchase_vendor_quote_lines | id | SI | OK | OK | CONFIABLE | Primary key |
| Purchasing | selemti | purchase_vendor_quote_lines | quote_id | SI | OK | OK | CONFIABLE | Quote foreign key |
| Purchasing | selemti | purchase_vendor_quote_lines | request_line_id | SI | OK | OK | CONFIABLE | Request line foreign key |
| Purchasing | selemti | purchase_vendor_quote_lines | item_id | SI | OK | OK | CONFIABLE | Item foreign key |
| Purchasing | selemti | purchase_vendor_quote_lines | qty_oferta | SI | OK | OK | CONFIABLE | Offered quantity |
| Purchasing | selemti | purchase_vendor_quote_lines | uom_oferta | SI | OK | OK | CONFIABLE | Offered UOM |
| Purchasing | selemti | purchase_vendor_quote_lines | precio_unitario | SI | OK | OK | CONFIABLE | Unit price |
| Purchasing | selemti | purchase_vendor_quote_lines | pack_size | SI | OK | OK | CONFIABLE | Pack size |
| Purchasing | selemti | purchase_vendor_quote_lines | pack_uom | SI | OK | OK | CONFIABLE | Pack UOM |
| Purchasing | selemti | purchase_vendor_quote_lines | monto_total | SI | OK | OK | CONFIABLE | Total amount |
| Purchasing | selemti | purchase_vendor_quote_lines | meta | SI | OK | OK | CONFIABLE | Metadata |
| Purchasing | selemti | purchase_vendor_quote_lines | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Purchasing | selemti | purchase_vendor_quote_lines | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Purchasing | selemti | cat_proveedores | id | SI | OK | OK | CONFIABLE | Primary key |
| Purchasing | selemti | cat_proveedores | rfc | SI | OK | OK | CONFIABLE | RFC field |
| Purchasing | selemti | cat_proveedores | nombre | SI | OK | OK | CONFIABLE | Name field |
| Purchasing | selemti | cat_proveedores | telefono | SI | OK | OK | CONFIABLE | Phone field |
| Purchasing | selemti | cat_proveedores | email | SI | OK | OK | CONFIABLE | Email field |
| Purchasing | selemti | cat_proveedores | activo | SI | OK | OK | CONFIABLE | Active flag |
| Purchasing | selemti | cat_proveedores | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Purchasing | selemti | cat_proveedores | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Purchasing | selemti | cat_proveedores | razon_social | SI | OK | OK | CONFIABLE | Business name |
| Purchasing | selemti | cat_proveedores | tipo_comprobante | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | uso_cfdi | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | metodo_pago | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | forma_pago | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | regimen_fiscal | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | contacto_nombre | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | contacto_email | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | contacto_telefono | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | direccion | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | ciudad | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | estado | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | pais | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | cp | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | cat_proveedores | notas | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | id | SI | OK | OK | CONFIABLE | Primary key |
| Purchasing | selemti | purchase_suggestions | folio | SI | OK | OK | CONFIABLE | Folio field |
| Purchasing | selemti | purchase_suggestions | sucursal_id | SI | OK | OK | CONFIABLE | Branch foreign key |
| Purchasing | selemti | purchase_suggestions | almacen_id | SI | OK | OK | CONFIABLE | Warehouse foreign key |
| Purchasing | selemti | purchase_suggestions | estado | SI | OK | OK | CONFIABLE | Status field |
| Purchasing | selemti | purchase_suggestions | prioridad | SI | OK | OK | CONFIABLE | Priority field |
| Purchasing | selemti | purchase_suggestions | origen | SI | OK | OK | CONFIABLE | Origin field |
| Purchasing | selemti | purchase_suggestions | total_items | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | total_estimado | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | sugerido_en | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | sugerido_por_user_id | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | revisado_por_user_id | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | revisado_en | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | convertido_a_request_id | SI | OK | OK | CONFIABLE | Converted to request foreign key |
| Purchasing | selemti | purchase_suggestions | convertido_en | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | dias_analisis | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | consumo_promedio_calculado | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | notas | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | meta | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | created_at | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestions | updated_at | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | id | SI | OK | OK | CONFIABLE | Primary key |
| Purchasing | selemti | purchase_suggestion_lines | suggestion_id | SI | OK | OK | CONFIABLE | Suggestion foreign key |
| Purchasing | selemti | purchase_suggestion_lines | item_id | SI | OK | OK | CONFIABLE | Item foreign key |
| Purchasing | selemti | purchase_suggestion_lines | stock_actual | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | stock_min | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | stock_max | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | reorder_point | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | consumo_promedio_diario | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | dias_cobertura_actual | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | demanda_proyectada | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | qty_sugerida | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | qty_ajustada | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | uom | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | costo_unitario_estimado | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | costo_total_linea | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | proveedor_sugerido_id | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | ultimo_precio_compra | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | fecha_ultima_compra | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | notas | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | created_at | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | purchase_suggestion_lines | updated_at | SI | NO_USADO | OK | CONFIABLE | Field exists in DB but not referenced in code |
| Purchasing | selemti | replenishment_suggestions | id | SI | OK | OK | CONFIABLE | Primary key |
| Purchasing | selemti | replenishment_suggestions | folio | SI | OK | OK | CONFIABLE | Folio field |
| Purchasing | selemti | replenishment_suggestions | tipo | SI | OK | OK | CONFIABLE | Type field |
| Purchasing | selemti | replenishment_suggestions | prioridad | SI | OK | OK | CONFIABLE | Priority field |
| Purchasing | selemti | replenishment_suggestions | origen | SI | OK | OK | CONFIABLE | Origin field |
| Purchasing | selemti | replenishment_suggestions | item_id | SI | OK | OK | CONFIABLE | Item foreign key |
| Purchasing | selemti | replenishment_suggestions | sucursal_id | SI | OK | OK | CONFIABLE | Branch foreign key |
| Purchasing | selemti | replenishment_suggestions | almacen_id | SI | OK | OK | CONFIABLE | Warehouse foreign key |
| Purchasing | selemti | replenishment_suggestions | stock_actual | SI | OK | OK | CONFIABLE | Actual stock |
| Purchasing | selemti | replenishment_suggestions | stock_min | SI | OK | OK | CONFIABLE | Min stock |
| Purchasing | selemti | replenishment_suggestions | stock_max | SI | OK | OK | CONFIABLE | Max stock |
| Purchasing | selemti | replenishment_suggestions | qty_sugerida | SI | OK | OK | CONFIABLE | Suggested quantity |
| Purchasing | selemti | replenishment_suggestions | qty_aprobada | SI | OK | OK | CONFIABLE | Approved quantity |
| Purchasing | selemti | replenishment_suggestions | uom | SI | OK | OK | CONFIABLE | Unit of measure |
| Purchasing | selemti | replenishment_suggestions | consumo_promedio_diario | SI | OK | OK | CONFIABLE | Average daily consumption |
| Purchasing | selemti | replenishment_suggestions | dias_stock_restante | SI | OK | OK | CONFIABLE | Days remaining stock |
| Purchasing | selemti | replenishment_suggestions | fecha_agotamiento_estimada | SI | OK | OK | CONFIABLE | Estimated depletion date |
| Purchasing | selemti | replenishment_suggestions | estado | SI | OK | OK | CONFIABLE | Status field |
| Purchasing | selemti | replenishment_suggestions | purchase_request_id | SI | OK | OK | CONFIABLE | Purchase request foreign key |
| Purchasing | selemti | replenishment_suggestions | production_order_id | SI | OK | OK | CONFIABLE | Production order foreign key |
| Purchasing | selemti | replenishment_suggestions | sugerido_en | SI | OK | OK | CONFIABLE | Suggested at |
| Purchasing | selemti | replenishment_suggestions | revisado_en | SI | OK | OK | CONFIABLE | Reviewed at |
| Purchasing | selemti | replenishment_suggestions | revisado_por | SI | OK | OK | CONFIABLE | Reviewed by |
| Purchasing | selemti | replenishment_suggestions | convertido_en | SI | OK | OK | CONFIABLE | Converted at |
| Purchasing | selemti | replenishment_suggestions | caduca_en | SI | OK | OK | CONFIABLE | Expires at |
| Purchasing | selemti | replenishment_suggestions | motivo | SI | OK | OK | CONFIABLE | Reason |
| Purchasing | selemti | replenishment_suggestions | motivo_rechazo | SI | OK | OK | CONFIABLE | Rejection reason |
| Purchasing | selemti | replenishment_suggestions | notas | SI | OK | OK | CONFIABLE | Notes |
| Purchasing | selemti | replenishment_suggestions | meta | SI | OK | OK | CONFIABLE | Metadata |
| Purchasing | selemti | replenishment_suggestions | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Purchasing | selemti | replenishment_suggestions | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| POS / Ventas | public | ticket | id | SI | OK | OK | CONFIABLE | Primary key |
| POS / Ventas | public | ticket | global_id | SI | OK | OK | CONFIABLE | Global identifier |
| POS / Ventas | public | ticket | create_date | SI | OK | OK | CONFIABLE | Creation date |
| POS / Ventas | public | ticket | closing_date | SI | OK | OK | CONFIABLE | Closing date |
| POS / Ventas | public | ticket | active_date | SI | OK | OK | CONFIABLE | Active date |
| POS / Ventas | public | ticket | deliveery_date | SI | OK | OK | CONFIABLE | Delivery date |
| POS / Ventas | public | ticket | creation_hour | SI | OK | OK | CONFIABLE | Creation hour |
| POS / Ventas | public | ticket | paid | SI | OK | OK | CONFIABLE | Paid status |
| POS / Ventas | public | ticket | voided | SI | OK | OK | CONFIABLE | Voided status |
| POS / Ventas | public | ticket | void_reason | SI | OK | OK | CONFIABLE | Void reason |
| POS / Ventas | public | ticket | wasted | SI | OK | OK | CONFIABLE | Wasted status |
| POS / Ventas | public | ticket | refunded | SI | OK | OK | CONFIABLE | Refunded status |
| POS / Ventas | public | ticket | settled | SI | OK | OK | CONFIABLE | Settled status |
| POS / Ventas | public | ticket | drawer_resetted | SI | OK | OK | CONFIABLE | Drawer reset status |
| POS / Ventas | public | ticket | sub_total | SI | OK | OK | CONFIABLE | Sub total |
| POS / Ventas | public | ticket | total_discount | SI | OK | OK | CONFIABLE | Total discount |
| POS / Ventas | public | ticket | total_tax | SI | OK | OK | CONFIABLE | Total tax |
| POS / Ventas | public | ticket | total_price | SI | OK | OK | CONFIABLE | Total price |
| POS / Ventas | public | ticket | paid_amount | SI | OK | OK | CONFIABLE | Paid amount |
| POS / Ventas | public | ticket | due_amount | SI | OK | OK | CONFIABLE | Due amount |
| POS / Ventas | public | ticket | advance_amount | SI | OK | OK | CONFIABLE | Advance amount |
| POS / Ventas | public | ticket | adjustment_amount | SI | OK | OK | CONFIABLE | Adjustment amount |
| POS / Ventas | public | ticket | number_of_guests | SI | OK | OK | CONFIABLE | Number of guests |
| POS / Ventas | public | ticket | status | SI | OK | OK | CONFIABLE | Status |
| POS / Ventas | public | ticket | bar_tab | SI | OK | OK | CONFIABLE | Bar tab flag |
| POS / Ventas | public | ticket | is_tax_exempt | SI | OK | OK | CONFIABLE | Tax exempt flag |
| POS / Ventas | public | ticket | is_re_opened | SI | OK | OK | CONFIABLE | Reopened flag |
| POS / Ventas | public | ticket | service_charge | SI | OK | OK | CONFIABLE | Service charge |
| POS / Ventas | public | ticket | delivery_charge | SI | OK | OK | CONFIABLE | Delivery charge |
| POS / Ventas | public | ticket | customer_id | SI | OK | OK | CONFIABLE | Customer ID |
| POS / Ventas | public | ticket | delivery_address | SI | OK | OK | CONFIABLE | Delivery address |
| POS / Ventas | public | ticket | customer_pickeup | SI | OK | OK | CONFIABLE | Customer pickup flag |
| POS / Ventas | public | ticket | delivery_extra_info | SI | OK | OK | CONFIABLE | Delivery extra info |
| POS / Ventas | public | ticket | ticket_type | SI | OK | OK | CONFIABLE | Ticket type |
| POS / Ventas | public | ticket | shift_id | SI | OK | OK | CONFIABLE | Shift ID |
| POS / Ventas | public | ticket | owner_id | SI | OK | OK | CONFIABLE | Owner ID |
| POS / Ventas | public | ticket | driver_id | SI | OK | OK | CONFIABLE | Driver ID |
| POS / Ventas | public | ticket | gratuity_id | SI | OK | OK | CONFIABLE | Gratuity ID |
| POS / Ventas | public | ticket | void_by_user | SI | OK | OK | CONFIABLE | Void by user |
| POS / Ventas | public | ticket | terminal_id | SI | OK | OK | CONFIABLE | Terminal ID |
| POS / Ventas | public | ticket | folio_date | SI | OK | OK | CONFIABLE | Folio date |
| POS / Ventas | public | ticket | branch_key | SI | OK | OK | CONFIABLE | Branch key |
| POS / Ventas | public | ticket | daily_folio | SI | OK | OK | CONFIABLE | Daily folio |
| POS / Ventas | public | ticket_item | id | SI | OK | OK | CONFIABLE | Primary key |
| POS / Ventas | public | ticket_item | item_id | SI | OK | OK | CONFIABLE | Item ID |
| POS / Ventas | public | ticket_item | item_count | SI | OK | OK | CONFIABLE | Item count |
| POS / Ventas | public | ticket_item | item_quantity | SI | OK | OK | CONFIABLE | Item quantity |
| POS / Ventas | public | ticket_item | item_name | SI | OK | OK | CONFIABLE | Item name |
| POS / Ventas | public | ticket_item | item_unit_name | SI | OK | OK | CONFIABLE | Item unit name |
| POS / Ventas | public | ticket_item | group_name | SI | OK | OK | CONFIABLE | Group name |
| POS / Ventas | public | ticket_item | category_name | SI | OK | OK | CONFIABLE | Category name |
| POS / Ventas | public | ticket_item | item_price | SI | OK | OK | CONFIABLE | Item price |
| POS / Ventas | public | ticket_item | item_tax_rate | SI | OK | OK | CONFIABLE | Item tax rate |
| POS / Ventas | public | ticket_item | sub_total | SI | OK | OK | CONFIABLE | Sub total |
| POS / Ventas | public | ticket_item | sub_total_without_modifiers | SI | OK | OK | CONFIABLE | Sub total without modifiers |
| POS / Ventas | public | ticket_item | discount | SI | OK | OK | CONFIABLE | Discount |
| POS / Ventas | public | ticket_item | tax_amount | SI | OK | OK | CONFIABLE | Tax amount |
| POS / Ventas | public | ticket_item | tax_amount_without_modifiers | SI | OK | OK | CONFIABLE | Tax amount without modifiers |
| POS / Ventas | public | ticket_item | total_price | SI | OK | OK | CONFIABLE | Total price |
| POS / Ventas | public | ticket_item | total_price_without_modifiers | SI | OK | OK | CONFIABLE | Total price without modifiers |
| POS / Ventas | public | ticket_item | beverage | SI | OK | OK | CONFIABLE | Beverage flag |
| POS / Ventas | public | ticket_item | inventory_handled | SI | OK | OK | CONFIABLE | Inventory handled flag |
| POS / Ventas | public | ticket_item | print_to_kitchen | SI | OK | OK | CONFIABLE | Print to kitchen flag |
| POS / Ventas | public | ticket_item | treat_as_seat | SI | OK | OK | CONFIABLE | Treat as seat flag |
| POS / Ventas | public | ticket_item | seat_number | SI | OK | OK | CONFIABLE | Seat number |
| POS / Ventas | public | ticket_item | fractional_unit | SI | OK | OK | CONFIABLE | Fractional unit flag |
| POS / Ventas | public | ticket_item | has_modiiers | SI | MISMATCH | OK | CONFIABLE | DB has typo: has_modiiers vs has_modifiers |
| POS / Ventas | public | ticket_item | printed_to_kitchen | SI | OK | OK | CONFIABLE | Printed to kitchen flag |
| POS / Ventas | public | ticket_item | status | SI | OK | OK | CONFIABLE | Status |
| POS / Ventas | public | ticket_item | stock_amount_adjusted | SI | OK | OK | CONFIABLE | Stock amount adjusted |
| POS / Ventas | public | ticket_item | pizza_type | SI | OK | OK | CONFIABLE | Pizza type flag |
| POS / Ventas | public | ticket_item | size_modifier_id | SI | OK | OK | CONFIABLE | Size modifier ID |
| POS / Ventas | public | ticket_item | ticket_id | SI | OK | OK | CONFIABLE | Ticket ID |
| POS / Ventas | public | ticket_item | pg_id | SI | OK | OK | CONFIABLE | PG ID |
| POS / Ventas | public | ticket_item | pizza_section_mode | SI | OK | OK | CONFIABLE | Pizza section mode |
| POS / Ventas | public | menu_item | id | SI | OK | OK | CONFIABLE | Primary key |
| POS / Ventas | public | menu_item | name | SI | OK | OK | CONFIABLE | Item name |
| POS / Ventas | public | menu_item | description | SI | OK | OK | CONFIABLE | Description |
| POS / Ventas | public | menu_item | unit_name | SI | OK | OK | CONFIABLE | Unit name |
| POS / Ventas | public | menu_item | translated_name | SI | OK | OK | CONFIABLE | Translated name |
| POS / Ventas | public | menu_item | barcode | SI | OK | OK | CONFIABLE | Barcode |
| POS / Ventas | public | menu_item | buy_price | SI | OK | OK | CONFIABLE | Buy price |
| POS / Ventas | public | menu_item | stock_amount | SI | OK | OK | CONFIABLE | Stock amount |
| POS / Ventas | public | menu_item | price | SI | OK | OK | CONFIABLE | Selling price |
| POS / Ventas | public | menu_item | discount_rate | SI | OK | OK | CONFIABLE | Discount rate |
| POS / Ventas | public | menu_item | visible | SI | OK | OK | CONFIABLE | Visible flag |
| POS / Ventas | public | menu_item | disable_when_stock_amount_is_zero | SI | OK | OK | CONFIABLE | Disable when no stock |
| POS / Ventas | public | menu_item | sort_order | SI | OK | OK | CONFIABLE | Sort order |
| POS / Ventas | public | menu_item | btn_color | SI | OK | OK | CONFIABLE | Button color |
| POS / Ventas | public | menu_item | text_color | SI | OK | OK | CONFIABLE | Text color |
| POS / Ventas | public | menu_item | image | SI | OK | OK | CONFIABLE | Image |
| POS / Ventas | public | menu_item | show_image_only | SI | OK | OK | CONFIABLE | Show image only |
| POS / Ventas | public | menu_item | fractional_unit | SI | OK | OK | CONFIABLE | Fractional unit |
| POS / Ventas | public | menu_item | pizza_type | SI | OK | OK | CONFIABLE | Pizza type |
| POS / Ventas | public | menu_item | default_sell_portion | SI | OK | OK | CONFIABLE | Default selling portion |
| POS / Ventas | public | menu_item | group_id | SI | OK | OK | CONFIABLE | Group ID |
| POS / Ventas | public | menu_item | tax_group_id | SI | OK | OK | CONFIABLE | Tax group ID |
| POS / Ventas | public | menu_item | recepie | SI | OK | OK | CONFIABLE | Recipe ID |
| POS / Ventas | public | menu_item | pg_id | SI | OK | OK | CONFIABLE | PG ID |
| POS / Ventas | public | menu_item | tax_id | SI | OK | OK | CONFIABLE | Tax ID |
| POS / Ventas | public | menu_group | id | SI | OK | OK | CONFIABLE | Primary key |
| POS / Ventas | public | menu_group | name | SI | OK | OK | CONFIABLE | Group name |
| POS / Ventas | public | menu_group | translated_name | SI | OK | OK | CONFIABLE | Translated name |
| POS / Ventas | public | menu_group | visible | SI | OK | OK | CONFIABLE | Visible flag |
| POS / Ventas | public | menu_group | sort_order | SI | OK | OK | CONFIABLE | Sort order |
| POS / Ventas | public | menu_group | btn_color | SI | OK | OK | CONFIABLE | Button color |
| POS / Ventas | public | menu_group | text_color | SI | OK | OK | CONFIABLE | Text color |
| POS / Ventas | public | menu_group | category_id | SI | OK | OK | CONFIABLE | Category ID |
| POS / Ventas | public | transactions | id | SI | OK | OK | CONFIABLE | Primary key |
| POS / Ventas | public | transactions | payment_type | SI | OK | OK | CONFIABLE | Payment type |
| POS / Ventas | public | transactions | global_id | SI | OK | OK | CONFIABLE | Global identifier |
| POS / Ventas | public | transactions | transaction_time | SI | OK | OK | CONFIABLE | Transaction time |
| POS / Ventas | public | transactions | amount | SI | OK | OK | CONFIABLE | Amount |
| POS / Ventas | public | transactions | tips_amount | SI | OK | OK | CONFIABLE | Tips amount |
| POS / Ventas | public | transactions | tips_exceed_amount | SI | OK | OK | CONFIABLE | Tips exceed amount |
| POS / Ventas | public | transactions | tender_amount | SI | OK | OK | CONFIABLE | Tender amount |
| POS / Ventas | public | transactions | transaction_type | SI | OK | OK | CONFIABLE | Transaction type |
| POS / Ventas | public | transactions | custom_payment_name | SI | OK | OK | CONFIABLE | Custom payment name |
| POS / Ventas | public | transactions | custom_payment_ref | SI | OK | OK | CONFIABLE | Custom payment reference |
| POS / Ventas | public | transactions | custom_payment_field_name | SI | OK | OK | CONFIABLE | Custom payment field name |
| POS / Ventas | public | transactions | payment_sub_type | SI | OK | OK | CONFIABLE | Payment sub type |
| POS / Ventas | public | transactions | captured | SI | OK | OK | CONFIABLE | Captured flag |
| POS / Ventas | public | transactions | voided | SI | OK | OK | CONFIABLE | Voided flag |
| POS / Ventas | public | transactions | authorizable | SI | OK | OK | CONFIABLE | Authorizable flag |
| POS / Ventas | public | transactions | card_holder_name | SI | OK | OK | CONFIABLE | Card holder name |
| POS / Ventas | public | transactions | card_number | SI | OK | OK | CONFIABLE | Card number |
| POS / Ventas | public | transactions | card_auth_code | SI | OK | OK | CONFIABLE | Card auth code |
| POS / Ventas | public | transactions | card_type | SI | OK | OK | CONFIABLE | Card type |
| POS / Ventas | public | transactions | card_transaction_id | SI | OK | OK | CONFIABLE | Card transaction ID |
| POS / Ventas | public | transactions | card_merchant_gateway | SI | OK | OK | CONFIABLE | Card merchant gateway |
| POS / Ventas | public | transactions | card_reader | SI | OK | OK | CONFIABLE | Card reader |
| POS / Ventas | public | transactions | card_aid | SI | OK | OK | CONFIABLE | Card AID |
| POS / Ventas | public | transactions | card_arqc | SI | OK | OK | CONFIABLE | Card ARQC |
| POS / Ventas | public | transactions | card_ext_data | SI | OK | OK | CONFIABLE | Card ext data |
| POS / Ventas | public | transactions | gift_cert_number | SI | OK | OK | CONFIABLE | Gift cert number |
| POS / Ventas | public | transactions | gift_cert_face_value | SI | OK | OK | CONFIABLE | Gift cert face value |
| POS / Ventas | public | transactions | gift_cert_paid_amount | SI | OK | OK | CONFIABLE | Gift cert paid amount |
| POS / Ventas | public | transactions | gift_cert_cash_back_amount | SI | OK | OK | CONFIABLE | Gift cert cash back amount |
| POS / Ventas | public | transactions | drawer_resetted | SI | OK | OK | CONFIABLE | Drawer reset flag |
| POS / Ventas | public | transactions | note | SI | OK | OK | CONFIABLE | Note |
| POS / Ventas | public | transactions | terminal_id | SI | OK | OK | CONFIABLE | Terminal ID |
| POS / Ventas | public | transactions | ticket_id | SI | OK | OK | CONFIABLE | Ticket ID |
| POS / Ventas | public | transactions | user_id | SI | OK | OK | CONFIABLE | User ID |
| POS / Ventas | public | transactions | payout_reason_id | SI | OK | OK | CONFIABLE | Payout reason ID |
| POS / Ventas | public | transactions | payout_recepient_id | SI | OK | OK | CONFIABLE | Payout recipient ID |
| POS / Ventas | public | terminal | id | SI | OK | OK | CONFIABLE | Primary key |
| POS / Ventas | public | terminal | name | SI | OK | OK | CONFIABLE | Terminal name |
| POS / Ventas | public | terminal | terminal_key | SI | OK | OK | CONFIABLE | Terminal key |
| POS / Ventas | public | terminal | opening_balance | SI | OK | OK | CONFIABLE | Opening balance |
| POS / Ventas | public | terminal | current_balance | SI | OK | OK | CONFIABLE | Current balance |
| POS / Ventas | public | terminal | has_cash_drawer | SI | OK | OK | CONFIABLE | Has cash drawer |
| POS / Ventas | public | terminal | in_use | SI | OK | OK | CONFIABLE | In use flag |
| POS / Ventas | public | terminal | active | SI | OK | OK | CONFIABLE | Active flag |
| POS / Ventas | public | terminal | location | SI | OK | OK | CONFIABLE | Location |
| POS / Ventas | public | terminal | floor_id | SI | OK | OK | CONFIABLE | Floor ID |
| POS / Ventas | public | terminal | assigned_user | SI | OK | OK | CONFIABLE | Assigned user |
| Caja / Caja chica | selemti | caja_fondo | id | SI | OK | OK | CONFIABLE | Primary key |
| Caja / Caja chica | selemti | caja_fondo | folio | NO | OK | NO_EXISTE | ERROR_MAPA | Folio number |
| Caja / Caja chica | selemti | caja_fondo | fecha_apertura | NO | OK | NO_EXISTE | ERROR_MAPA | Opening date |
| Caja / Caja chica | selemti | caja_fondo | fecha_cierre | NO | OK | NO_EXISTE | ERROR_MAPA | Closing date |
| Caja / Caja chica | selemti | caja_fondo | estado | SI | OK | OK | CONFIABLE | Status |
| Caja / Caja chica | selemti | caja_fondo | monto_apertura | NO | OK | NO_EXISTE | ERROR_MAPA | Opening amount |
| Caja / Caja chica | selemti | caja_fondo | monto_cierre | NO | OK | NO_EXISTE | ERROR_MAPA | Closing amount |
| Caja / Caja chica | selemti | caja_fondo | responsable_id | NO | OK | NO_EXISTE | ERROR_MAPA | Responsible person ID |
| Caja / Caja chica | selemti | caja_fondo | sucursal_id | SI | OK | OK | CONFIABLE | Branch ID |
| Caja / Caja chica | selemti | caja_fondo | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Caja / Caja chica | selemti | caja_fondo | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Caja / Caja chica | selemti | caja_fondo_mov | id | SI | OK | OK | CONFIABLE | Primary key |
| Caja / Caja chica | selemti | caja_fondo_mov | caja_fondo_id | NO | OK | NO_EXISTE | ERROR_MAPA | Cash fund foreign key |
| Caja / Caja chica | selemti | caja_fondo_mov | tipo | SI | OK | OK | CONFIABLE | Movement type |
| Caja / Caja chica | selemti | caja_fondo_mov | monto | SI | OK | OK | CONFIABLE | Amount |
| Caja / Caja chica | selemti | caja_fondo_mov | metodo | SI | OK | OK | CONFIABLE | Payment method |
| Caja / Caja chica | selemti | caja_fondo_mov | descripcion | NO | OK | NO_EXISTE | ERROR_MAPA | Description |
| Caja / Caja chica | selemti | caja_fondo_mov | referencia_tipo | NO | OK | NO_EXISTE | ERROR_MAPA | Reference type |
| Caja / Caja chica | selemti | caja_fondo_mov | referencia_id | NO | OK | NO_EXISTE | ERROR_MAPA | Reference ID |
| Caja / Caja chica | selemti | caja_fondo_mov | usuario_id | NO | OK | NO_EXISTE | ERROR_MAPA | User ID |
| Caja / Caja chica | selemti | caja_fondo_mov | proveedor_id | SI | FANTASMA | OK | ERROR_MAPA | Campo no existe en BD pero sí en modelo |
| Caja / Caja chica | selemti | caja_fondo_mov | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Caja / Caja chica | selemti | caja_fondo_mov | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Caja / Caja chica | selemti | cash_funds | id | SI | OK | OK | CONFIABLE | Primary key |
| Caja / Caja chica | selemti | cash_funds | folio | NO | OK | NO_EXISTE | ERROR_MAPA | Folio number |
| Caja / Caja chica | selemti | cash_funds | responsable_id | NO | OK | NO_EXISTE | ERROR_MAPA | Responsible person ID |
| Caja / Caja chica | selemti | cash_funds | monto_inicial | SI | OK | OK | CONFIABLE | Initial amount |
| Caja / Caja chica | selemti | cash_funds | monto_sistema | NO | OK | NO_EXISTE | ERROR_MAPA | System amount |
| Caja / Caja chica | selemti | cash_funds | monto_real | NO | OK | NO_EXISTE | ERROR_MAPA | Real amount |
| Caja / Caja chica | selemti | cash_funds | diferencia | NO | OK | NO_EXISTE | ERROR_MAPA | Difference |
| Caja / Caja chica | selemti | cash_funds | estado | SI | OK | OK | CONFIABLE | Status |
| Caja / Caja chica | selemti | cash_funds | observaciones | NO | OK | NO_EXISTE | ERROR_MAPA | Observations |
| Caja / Caja chica | selemti | cash_funds | fecha_apertura | NO | OK | NO_EXISTE | ERROR_MAPA | Opening date |
| Caja / Caja chica | selemti | cash_funds | fecha_cierre | NO | OK | NO_EXISTE | ERROR_MAPA | Closing date |
| Caja / Caja chica | selemti | cash_funds | aprobada_por | NO | OK | NO_EXISTE | ERROR_MAPA | Approved by |
| Caja / Caja chica | selemti | cash_funds | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Caja / Caja chica | selemti | cash_funds | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Caja / Caja chica | selemti | cash_fund_movements | id | SI | OK | OK | CONFIABLE | Primary key |
| Caja / Caja chica | selemti | cash_fund_movements | cash_fund_id | SI | OK | OK | CONFIABLE | Cash fund foreign key |
| Caja / Caja chica | selemti | cash_fund_movements | tipo | SI | OK | OK | CONFIABLE | Movement type |
| Caja / Caja chica | selemti | cash_fund_movements | monto | SI | OK | OK | CONFIABLE | Amount |
| Caja / Caja chica | selemti | cash_fund_movements | metodo | SI | OK | OK | CONFIABLE | Payment method |
| Caja / Caja chica | selemti | cash_fund_movements | descripcion | NO | OK | NO_EXISTE | ERROR_MAPA | Description |
| Caja / Caja chica | selemti | cash_fund_movements | referencia_tipo | NO | OK | NO_EXISTE | ERROR_MAPA | Reference type |
| Caja / Caja chica | selemti | cash_fund_movements | referencia_id | NO | OK | NO_EXISTE | ERROR_MAPA | Reference ID |
| Caja / Caja chica | selemti | cash_fund_movements | usuario_id | NO | OK | NO_EXISTE | ERROR_MAPA | User ID |
| Caja / Caja chica | selemti | cash_fund_movements | proveedor_id | SI | FANTASMA | OK | ERROR_MAPA | Campo no existe en BD pero sí en modelo |
| Caja / Caja chica | selemti | cash_fund_movements | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Caja / Caja chica | selemti | cash_fund_movements | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Finanzas | selemti | sesion_cajon | id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | usuario_id | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | terminal_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | cajero_usuario_id | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | apertura_ts | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | cierre_ts | SI | NO_USADO | OK | CONFIABLE | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | sistema_efectivo | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | sistema_total | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | sistema_descuentos | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | sistema_anulaciones | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | sistema_retiros | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | sistema_efectivo_esperado | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | declarado_precorte_efectivo | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | declarado_post_efectivo | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | declarado_post_tarjetas | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | diferencia_efectivo | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | diferencia_no_efectivo | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | created_at | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | sesion_cajon | updated_at | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Finanzas | selemti | formas_pago | id | SI | FANTASMA | OK | ERROR_MAPA | Tabla no existe en BD pero es referenciada en vistas |
| Finanzas | selemti | formas_pago | codigo | SI | FANTASMA | OK | ERROR_MAPA | Tabla no existe en BD pero es referenciada en vistas |
| Finanzas | selemti | formas_pago | nombre | NO | FANTASMA | NO_EXISTE | CONFIABLE | Tabla no existe en BD pero es referenciada en vistas |
| Reports / KPIs | selemti | vw_stock_valorizado | item_key | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_valorizado | sucursal_id | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_valorizado | stock | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_valorizado | costo_wac | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_valorizado | valor | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_brechas | sucursal_id | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_brechas | item_id | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_brechas | min_qty | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_brechas | max_qty | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_brechas | stock_actual | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_brechas | faltante | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_stock_brechas | excedente | NO | OK | NO_EXISTE | ERROR_MAPA | View column |
| Reports / KPIs | selemti | vw_consumo_vs_movimientos | fecha | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_consumo_vs_movimientos | sucursal_id | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_consumo_vs_movimientos | insumo_id | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_consumo_vs_movimientos | consumo_teorico | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_consumo_vs_movimientos | consumo_real | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_consumo_vs_movimientos | diferencia | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_ventas_por_item | fecha | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_ventas_por_item | terminal_id | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_ventas_por_item | sucursal_id | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_ventas_por_item | plu | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_ventas_por_item | unidades | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_ventas_por_item | venta_total | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_kpis_terminal_dia | fecha | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_kpis_terminal_dia | terminal_id | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_kpis_terminal_dia | sesiones | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_kpis_terminal_dia | sistema_efectivo | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_kpis_sucursal_dia | fecha | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_kpis_sucursal_dia | sucursal_id | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_kpis_sucursal_dia | sesiones | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Reports / KPIs | selemti | vw_kpis_sucursal_dia | sistema_efectivo | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | View exists but not referenced in code |
| Seguridad | public | users | id | NO | OK | NO_EXISTE | ERROR_MAPA | Primary key |
| Seguridad | public | users | name | NO | OK | NO_EXISTE | ERROR_MAPA | User name |
| Seguridad | public | users | email | NO | OK | NO_EXISTE | ERROR_MAPA | User email |
| Seguridad | public | users | email_verified_at | NO | OK | NO_EXISTE | ERROR_MAPA | Email verified timestamp |
| Seguridad | public | users | password | NO | OK | NO_EXISTE | ERROR_MAPA | User password |
| Seguridad | public | users | remember_token | NO | OK | NO_EXISTE | ERROR_MAPA | Remember token |
| Seguridad | public | users | created_at | NO | OK | NO_EXISTE | ERROR_MAPA | Created timestamp |
| Seguridad | public | users | updated_at | NO | OK | NO_EXISTE | ERROR_MAPA | Updated timestamp |
| Seguridad | public | model_has_permissions | id | NO | OK | NO_EXISTE | ERROR_MAPA | Permission model relationship |
| Seguridad | public | model_has_permissions | permission_id | NO | OK | NO_EXISTE | ERROR_MAPA | Permission ID |
| Seguridad | public | model_has_permissions | model_type | NO | OK | NO_EXISTE | ERROR_MAPA | Model type |
| Seguridad | public | model_has_permissions | model_id | NO | OK | NO_EXISTE | ERROR_MAPA | Model ID |
| Seguridad | public | model_has_roles | id | NO | OK | NO_EXISTE | ERROR_MAPA | Role model relationship |
| Seguridad | public | model_has_roles | role_id | NO | OK | NO_EXISTE | ERROR_MAPA | Role ID |
| Seguridad | public | model_has_roles | model_type | NO | OK | NO_EXISTE | ERROR_MAPA | Model type |
| Seguridad | public | model_has_roles | model_id | NO | OK | NO_EXISTE | ERROR_MAPA | Model ID |
| Seguridad | public | permissions | id | NO | OK | NO_EXISTE | ERROR_MAPA | Primary key |
| Seguridad | public | permissions | name | NO | OK | NO_EXISTE | ERROR_MAPA | Permission name |
| Seguridad | public | permissions | guard_name | NO | OK | NO_EXISTE | ERROR_MAPA | Guard name |
| Seguridad | public | permissions | created_at | NO | OK | NO_EXISTE | ERROR_MAPA | Created timestamp |
| Seguridad | public | permissions | updated_at | NO | OK | NO_EXISTE | ERROR_MAPA | Updated timestamp |
| Seguridad | public | roles | id | NO | OK | NO_EXISTE | ERROR_MAPA | Primary key |
| Seguridad | public | roles | name | NO | OK | NO_EXISTE | ERROR_MAPA | Role name |
| Seguridad | public | roles | guard_name | NO | OK | NO_EXISTE | ERROR_MAPA | Guard name |
| Seguridad | public | roles | created_at | NO | OK | NO_EXISTE | ERROR_MAPA | Created timestamp |
| Seguridad | public | roles | updated_at | NO | OK | NO_EXISTE | ERROR_MAPA | Updated timestamp |
| Seguridad | public | role_has_permissions | permission_id | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Seguridad | public | role_has_permissions | role_id | NO | NO_USADO | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code |
| Catálogos | selemti | cat_unidades | id | SI | OK | OK | CONFIABLE | Primary key |
| Catálogos | selemti | cat_unidades | clave | SI | OK | OK | CONFIABLE | Unit key |
| Catálogos | selemti | cat_unidades | nombre | SI | OK | OK | CONFIABLE | Unit name |
| Catálogos | selemti | cat_unidades | descripcion | NO | OK | NO_EXISTE | ERROR_MAPA | Unit description |
| Catálogos | selemti | cat_unidades | activo | SI | OK | OK | CONFIABLE | Active flag |
| Catálogos | selemti | cat_unidades | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Catálogos | selemti | cat_unidades | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Catálogos | selemti | cat_almacenes | id | SI | OK | OK | CONFIABLE | Primary key |
| Catálogos | selemti | cat_almacenes | codigo | NO | OK | NO_EXISTE | ERROR_MAPA | Code field |
| Catálogos | selemti | cat_almacenes | nombre | SI | OK | OK | CONFIABLE | Name field |
| Catálogos | selemti | cat_almacenes | descripcion | NO | OK | NO_EXISTE | ERROR_MAPA | Description |
| Catálogos | selemti | cat_almacenes | activo | SI | OK | OK | CONFIABLE | Active flag |
| Catálogos | selemti | cat_almacenes | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Catálogos | selemti | cat_almacenes | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Catálogos | selemti | cat_sucursales | id | SI | OK | OK | CONFIABLE | Primary key |
| Catálogos | selemti | cat_sucursales | codigo | NO | OK | NO_EXISTE | ERROR_MAPA | Code field |
| Catálogos | selemti | cat_sucursales | nombre | SI | OK | OK | CONFIABLE | Name field |
| Catálogos | selemti | cat_sucursales | direccion | NO | OK | NO_EXISTE | ERROR_MAPA | Address |
| Catálogos | selemti | cat_sucursales | activo | SI | OK | OK | CONFIABLE | Active flag |
| Catálogos | selemti | cat_sucursales | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Catálogos | selemti | cat_sucursales | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |
| Catálogos | selemti | cat_proveedores | id | SI | OK | OK | CONFIABLE | Primary key |
| Catálogos | selemti | cat_proveedores | rfc | SI | OK | OK | CONFIABLE | RFC field |
| Catálogos | selemti | cat_proveedores | nombre | SI | OK | OK | CONFIABLE | Name field |
| Catálogos | selemti | cat_proveedores | telefono | SI | OK | OK | CONFIABLE | Phone field |
| Catálogos | selemti | cat_proveedores | email | SI | OK | OK | CONFIABLE | Email field |
| Catálogos | selemti | cat_proveedores | activo | SI | OK | OK | CONFIABLE | Active flag |
| Catálogos | selemti | cat_proveedores | created_at | SI | OK | OK | CONFIABLE | Created timestamp |
| Catálogos | selemti | cat_proveedores | updated_at | SI | OK | OK | CONFIABLE | Updated timestamp |

## 1. Resumen global

- Total filas analizadas: 744
- CONFIABLE: 634
- SOSPECHOSO: 37
- ERROR_MAPA: 73

## 2. Lista de ERROR_MAPA (detalle)

- Recetas.pos_map.meta: marcado como 'FANTASMA' pero SI existe en BD
- Recetas.pos_map.vigente_desde: marcado como 'FANTASMA' pero SI existe en BD
- Caja / Caja chica.caja_fondo.folio: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo.fecha_apertura: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo.fecha_cierre: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo.monto_apertura: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo.monto_cierre: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo.responsable_id: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo_mov.caja_fondo_id: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo_mov.descripcion: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo_mov.referencia_tipo: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo_mov.referencia_id: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo_mov.usuario_id: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.caja_fondo_mov.proveedor_id: marcado como 'FANTASMA' pero SI existe en BD
- Caja / Caja chica.cash_funds.folio: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_funds.responsable_id: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_funds.monto_sistema: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_funds.monto_real: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_funds.diferencia: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_funds.observaciones: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_funds.fecha_apertura: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_funds.fecha_cierre: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_funds.aprobada_por: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_fund_movements.descripcion: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_fund_movements.referencia_tipo: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_fund_movements.referencia_id: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_fund_movements.usuario_id: marcado como 'OK' pero NO existe en BD
- Caja / Caja chica.cash_fund_movements.proveedor_id: marcado como 'FANTASMA' pero SI existe en BD
- Finanzas.formas_pago.id: marcado como 'FANTASMA' pero SI existe en BD
- Finanzas.formas_pago.codigo: marcado como 'FANTASMA' pero SI existe en BD
- Reports / KPIs.vw_stock_valorizado.item_key: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_valorizado.sucursal_id: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_valorizado.stock: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_valorizado.costo_wac: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_valorizado.valor: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_brechas.sucursal_id: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_brechas.item_id: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_brechas.min_qty: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_brechas.max_qty: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_brechas.stock_actual: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_brechas.faltante: marcado como 'OK' pero NO existe en BD
- Reports / KPIs.vw_stock_brechas.excedente: marcado como 'OK' pero NO existe en BD
- Seguridad.users.id: marcado como 'OK' pero NO existe en BD
- Seguridad.users.name: marcado como 'OK' pero NO existe en BD
- Seguridad.users.email: marcado como 'OK' pero NO existe en BD
- Seguridad.users.email_verified_at: marcado como 'OK' pero NO existe en BD
- Seguridad.users.password: marcado como 'OK' pero NO existe en BD
- Seguridad.users.remember_token: marcado como 'OK' pero NO existe en BD
- Seguridad.users.created_at: marcado como 'OK' pero NO existe en BD
- Seguridad.users.updated_at: marcado como 'OK' pero NO existe en BD
- Seguridad.model_has_permissions.id: marcado como 'OK' pero NO existe en BD
- Seguridad.model_has_permissions.permission_id: marcado como 'OK' pero NO existe en BD
- Seguridad.model_has_permissions.model_type: marcado como 'OK' pero NO existe en BD
- Seguridad.model_has_permissions.model_id: marcado como 'OK' pero NO existe en BD
- Seguridad.model_has_roles.id: marcado como 'OK' pero NO existe en BD
- Seguridad.model_has_roles.role_id: marcado como 'OK' pero NO existe en BD
- Seguridad.model_has_roles.model_type: marcado como 'OK' pero NO existe en BD
- Seguridad.model_has_roles.model_id: marcado como 'OK' pero NO existe en BD
- Seguridad.permissions.id: marcado como 'OK' pero NO existe en BD
- Seguridad.permissions.name: marcado como 'OK' pero NO existe en BD
- Seguridad.permissions.guard_name: marcado como 'OK' pero NO existe en BD
- Seguridad.permissions.created_at: marcado como 'OK' pero NO existe en BD
- Seguridad.permissions.updated_at: marcado como 'OK' pero NO existe en BD
- Seguridad.roles.id: marcado como 'OK' pero NO existe en BD
- Seguridad.roles.name: marcado como 'OK' pero NO existe en BD
- Seguridad.roles.guard_name: marcado como 'OK' pero NO existe en BD
- Seguridad.roles.created_at: marcado como 'OK' pero NO existe en BD
- Seguridad.roles.updated_at: marcado como 'OK' pero NO existe en BD
- Catálogos.cat_unidades.descripcion: marcado como 'OK' pero NO existe en BD
- Catálogos.cat_almacenes.codigo: marcado como 'OK' pero NO existe en BD
- Catálogos.cat_almacenes.descripcion: marcado como 'OK' pero NO existe en BD
- Catálogos.cat_sucursales.codigo: marcado como 'OK' pero NO existe en BD
- Catálogos.cat_sucursales.direccion: marcado como 'OK' pero NO existe en BD

## 3. Observaciones

Se ha verificado el archivo BD_CODIGO_MAPA_CAMPOS_ALL.md contra la estructura real de la base de datos. Se encontraron diferencias significativas entre lo que el mapeo original asumía y la estructura real de la base de datos.

Especialmente importante es corregir las filas marcadas como ERROR_MAPA, donde el estado original contradice directamente la existencia real de los campos en la base de datos.

Esto revela discrepancias entre el modelo teórico del sistema y su implementación real. Se recomienda actualizar los modelos y servicios para alinearlos con la estructura efectiva de la base de datos.

