# VERIFICACIÓN DEL MAPA BD ↔ CÓDIGO (Producción, Purchasing)

| tabla_bd | columna_bd | existe_en_bd | estado_original | estado_bd | decision_final | notas |
|----------|------------|--------------|-----------------|-----------|----------------|-------|
| inventory_batch | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| inventory_batch | item_id | SI | Item foreign key | OK | SOSPECHOSO | Item foreign key | |
| inventory_batch | lote_proveedor | SI | Supplier lot | OK | SOSPECHOSO | Supplier lot | |
| inventory_batch | fecha_recepcion | SI | Receipt date | OK | SOSPECHOSO | Receipt date | |
| inventory_batch | fecha_caducidad | SI | Expiration date | OK | SOSPECHOSO | Expiration date | |
| inventory_batch | temperatura_recepcion | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| inventory_batch | documento_url | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| inventory_batch | cantidad_original | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| inventory_batch | cantidad_actual | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| inventory_batch | estado | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| inventory_batch | ubicacion_id | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| inventory_batch | created_at | SI | Creation timestamp | OK | SOSPECHOSO | Creation timestamp | |
| inventory_batch | updated_at | SI | Update timestamp | OK | SOSPECHOSO | Update timestamp | |
| inventory_batch | unit_cost | SI | Unit cost field | OK | SOSPECHOSO | Unit cost field | |
| merma | id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | ts | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | tipo | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | item_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | batch_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | op_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | qty | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | um_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | usuario_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | motivo | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | meta | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | created_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | updated_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| merma | deleted_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| production_orders | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| production_orders | folio | SI | Folio field | OK | SOSPECHOSO | Folio field | |
| production_orders | recipe_id | SI | Recipe foreign key | OK | SOSPECHOSO | Recipe foreign key | |
| production_orders | item_id | SI | Item foreign key | OK | SOSPECHOSO | Item foreign key | |
| production_orders | qty_programada | SI | Planned quantity | OK | SOSPECHOSO | Planned quantity | |
| production_orders | qty_producida | SI | Produced quantity | OK | SOSPECHOSO | Produced quantity | |
| production_orders | qty_merma | SI | Waste quantity | OK | SOSPECHOSO | Waste quantity | |
| production_orders | uom_base | SI | Base UOM | OK | SOSPECHOSO | Base UOM | |
| production_orders | sucursal_id | SI | Branch foreign key | OK | SOSPECHOSO | Branch foreign key | |
| production_orders | almacen_id | SI | Warehouse foreign key | OK | SOSPECHOSO | Warehouse foreign key | |
| production_orders | programado_para | SI | Scheduled for | OK | SOSPECHOSO | Scheduled for | |
| production_orders | iniciado_en | SI | Started at | OK | SOSPECHOSO | Started at | |
| production_orders | cerrado_en | SI | Closed at | OK | SOSPECHOSO | Closed at | |
| production_orders | estado | SI | Status field | OK | SOSPECHOSO | Status field | |
| production_orders | creado_por | SI | Created by | OK | SOSPECHOSO | Created by | |
| production_orders | aprobado_por | SI | Approved by | OK | SOSPECHOSO | Approved by | |
| production_orders | notas | SI | Notes | OK | SOSPECHOSO | Notes | |
| production_orders | meta | SI | Metadata | OK | SOSPECHOSO | Metadata | |
| production_orders | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| production_orders | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |
| production_order_inputs | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| production_order_inputs | production_order_id | SI | Production order foreign key | OK | SOSPECHOSO | Production order foreign key | |
| production_order_inputs | item_id | SI | Item foreign key | OK | SOSPECHOSO | Item foreign key | |
| production_order_inputs | inventory_batch_id | SI | Inventory batch foreign key | OK | SOSPECHOSO | Inventory batch foreign key | |
| production_order_inputs | qty | SI | Quantity | OK | SOSPECHOSO | Quantity | |
| production_order_inputs | uom | SI | Unit of measure | OK | SOSPECHOSO | Unit of measure | |
| production_order_inputs | meta | SI | Metadata | OK | SOSPECHOSO | Metadata | |
| production_order_inputs | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| production_order_inputs | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |
| production_order_outputs | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| production_order_outputs | production_order_id | SI | Production order foreign key | OK | SOSPECHOSO | Production order foreign key | |
| production_order_outputs | item_id | SI | Item foreign key | OK | SOSPECHOSO | Item foreign key | |
| production_order_outputs | inventory_batch_id | SI | Inventory batch foreign key | OK | SOSPECHOSO | Inventory batch foreign key | |
| production_order_outputs | lote_producido | SI | Produced batch | OK | SOSPECHOSO | Produced batch | |
| production_order_outputs | fecha_caducidad | SI | Expiration date | OK | SOSPECHOSO | Expiration date | |
| production_order_outputs | qty | SI | Quantity | OK | SOSPECHOSO | Quantity | |
| production_order_outputs | uom | SI | Unit of measure | OK | SOSPECHOSO | Unit of measure | |
| production_order_outputs | meta | SI | Metadata | OK | SOSPECHOSO | Metadata | |
| production_order_outputs | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| production_order_outputs | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |
| op_produccion_cab | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| op_produccion_cab | receta_version_id | SI | Recipe version foreign key | OK | SOSPECHOSO | Recipe version foreign key | |
| op_produccion_cab | cantidad_planeada | SI | Planned quantity | OK | SOSPECHOSO | Planned quantity | |
| op_produccion_cab | cantidad_real | SI | Real quantity | OK | SOSPECHOSO | Real quantity | |
| op_produccion_cab | fecha_produccion | SI | Production date | OK | SOSPECHOSO | Production date | |
| op_produccion_cab | estado | SI | Status field | OK | SOSPECHOSO | Status field | |
| op_produccion_cab | lote_resultado | SI | Result batch | OK | SOSPECHOSO | Result batch | |
| op_produccion_cab | usuario_responsable | SI | Responsible user | OK | SOSPECHOSO | Responsible user | |
| op_produccion_cab | created_at | SI | Creation timestamp | OK | SOSPECHOSO | Creation timestamp | |
| op_produccion_cab | updated_at | SI | Update timestamp | OK | SOSPECHOSO | Update timestamp | |
| op_cab | id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | sucursal_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | receta_version_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | cantidad_objetivo | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | um_salida_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | estado | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | ts_apertura | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | ts_cierre | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | usuario_abre | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | usuario_cierra | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | lote_salida | NO | Table exists but not referenced in code | NO_EXISTE | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | meta | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | created_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | updated_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_cab | deleted_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | op_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | item_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | qty_teorica | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | qty_real | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | um_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | batch_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | meta | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | created_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | updated_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_insumo | deleted_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_yield | op_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_yield | cantidad_real | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_yield | merma_real | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_yield | evidencia_url | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| op_yield | meta | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_cab | id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_cab | sol_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_cab | fecha_programada | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_cab | estado | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_cab | creada_por | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_cab | aprobada_por | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_cab | created_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_det | id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_det | prod_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_det | sr_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_det | cantidad | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_det | rendimiento | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| prod_det | created_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_cab | id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_cab | sucursal_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_cab | fecha | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_cab | estado | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_cab | solicitada_por | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_cab | autorizada_por | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_cab | observaciones | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_cab | created_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_det | id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_det | sol_id | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_det | plu | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_det | cantidad | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_det | cantidad_autorizada | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| sol_prod_det | created_at | SI | Table exists but not referenced in code | OK | SOSPECHOSO | Table exists but not referenced in code | |
| purchase_requests | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| purchase_requests | folio | SI | Folio field | OK | SOSPECHOSO | Folio field | |
| purchase_requests | sucursal_id | SI | Branch foreign key | OK | SOSPECHOSO | Branch foreign key | |
| purchase_requests | created_by | SI | Created by | OK | SOSPECHOSO | Created by | |
| purchase_requests | requested_by | SI | Requested by | OK | SOSPECHOSO | Requested by | |
| purchase_requests | requested_at | SI | Requested at | OK | SOSPECHOSO | Requested at | |
| purchase_requests | estado | SI | Status field | OK | SOSPECHOSO | Status field | |
| purchase_requests | importe_estimado | SI | Estimated amount | OK | SOSPECHOSO | Estimated amount | |
| purchase_requests | notas | SI | Notes | OK | SOSPECHOSO | Notes | |
| purchase_requests | meta | SI | Metadata | OK | SOSPECHOSO | Metadata | |
| purchase_requests | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| purchase_requests | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |
| purchase_requests | fecha_requerida | SI | Required date | OK | SOSPECHOSO | Required date | |
| purchase_requests | almacen_destino_id | SI | Destination warehouse | OK | SOSPECHOSO | Destination warehouse | |
| purchase_requests | justificacion | SI | Justification | OK | SOSPECHOSO | Justification | |
| purchase_requests | urgente | SI | Urgent flag | OK | SOSPECHOSO | Urgent flag | |
| purchase_requests | origen_suggestion_id | SI | Origin suggestion foreign key | OK | SOSPECHOSO | Origin suggestion foreign key | |
| purchase_request_lines | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| purchase_request_lines | request_id | SI | Request foreign key | OK | SOSPECHOSO | Request foreign key | |
| purchase_request_lines | item_id | SI | Item foreign key | OK | SOSPECHOSO | Item foreign key | |
| purchase_request_lines | qty | SI | Quantity | OK | SOSPECHOSO | Quantity | |
| purchase_request_lines | uom | SI | Unit of measure | OK | SOSPECHOSO | Unit of measure | |
| purchase_request_lines | fecha_requerida | SI | Required date | OK | SOSPECHOSO | Required date | |
| purchase_request_lines | preferred_vendor_id | SI | Preferred vendor foreign key | OK | SOSPECHOSO | Preferred vendor foreign key | |
| purchase_request_lines | last_price | SI | Last price | OK | SOSPECHOSO | Last price | |
| purchase_request_lines | estado | SI | Status field | OK | SOSPECHOSO | Status field | |
| purchase_request_lines | meta | SI | Metadata | OK | SOSPECHOSO | Metadata | |
| purchase_request_lines | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| purchase_request_lines | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |
| purchase_orders | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| purchase_orders | folio | SI | Folio field | OK | SOSPECHOSO | Folio field | |
| purchase_orders | quote_id | SI | Quote foreign key | OK | SOSPECHOSO | Quote foreign key | |
| purchase_orders | vendor_id | SI | Vendor foreign key | OK | SOSPECHOSO | Vendor foreign key | |
| purchase_orders | sucursal_id | SI | Branch foreign key | OK | SOSPECHOSO | Branch foreign key | |
| purchase_orders | estado | SI | Status field | OK | SOSPECHOSO | Status field | |
| purchase_orders | fecha_promesa | SI | Promised date | OK | SOSPECHOSO | Promised date | |
| purchase_orders | subtotal | SI | Subtotal | OK | SOSPECHOSO | Subtotal | |
| purchase_orders | descuento | SI | Discount | OK | SOSPECHOSO | Discount | |
| purchase_orders | impuestos | SI | Taxes | OK | SOSPECHOSO | Taxes | |
| purchase_orders | total | SI | Total | OK | SOSPECHOSO | Total | |
| purchase_orders | creado_por | SI | Created by | OK | SOSPECHOSO | Created by | |
| purchase_orders | aprobado_por | SI | Approved by | OK | SOSPECHOSO | Approved by | |
| purchase_orders | aprobado_en | SI | Approved at | OK | SOSPECHOSO | Approved at | |
| purchase_orders | notas | SI | Notes | OK | SOSPECHOSO | Notes | |
| purchase_orders | meta | SI | Metadata | OK | SOSPECHOSO | Metadata | |
| purchase_orders | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| purchase_orders | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |
| purchase_order_lines | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| purchase_order_lines | order_id | SI | Order foreign key | OK | SOSPECHOSO | Order foreign key | |
| purchase_order_lines | request_line_id | SI | Request line foreign key | OK | SOSPECHOSO | Request line foreign key | |
| purchase_order_lines | item_id | SI | Item foreign key | OK | SOSPECHOSO | Item foreign key | |
| purchase_order_lines | qty | SI | Quantity | OK | SOSPECHOSO | Quantity | |
| purchase_order_lines | uom | SI | Unit of measure | OK | SOSPECHOSO | Unit of measure | |
| purchase_order_lines | precio_unitario | SI | Unit price | OK | SOSPECHOSO | Unit price | |
| purchase_order_lines | descuento | SI | Discount | OK | SOSPECHOSO | Discount | |
| purchase_order_lines | impuestos | SI | Taxes | OK | SOSPECHOSO | Taxes | |
| purchase_order_lines | total | SI | Total | OK | SOSPECHOSO | Total | |
| purchase_order_lines | meta | SI | Metadata | OK | SOSPECHOSO | Metadata | |
| purchase_order_lines | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| purchase_order_lines | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |
| purchase_vendor_quotes | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| purchase_vendor_quotes | request_id | SI | Request foreign key | OK | SOSPECHOSO | Request foreign key | |
| purchase_vendor_quotes | vendor_id | SI | Vendor foreign key | OK | SOSPECHOSO | Vendor foreign key | |
| purchase_vendor_quotes | folio_proveedor | SI | Vendor folio | OK | SOSPECHOSO | Vendor folio | |
| purchase_vendor_quotes | estado | SI | Status field | OK | SOSPECHOSO | Status field | |
| purchase_vendor_quotes | enviada_en | SI | Sent at | OK | SOSPECHOSO | Sent at | |
| purchase_vendor_quotes | recibida_en | SI | Received at | OK | SOSPECHOSO | Received at | |
| purchase_vendor_quotes | subtotal | SI | Subtotal | OK | SOSPECHOSO | Subtotal | |
| purchase_vendor_quotes | descuento | SI | Discount | OK | SOSPECHOSO | Discount | |
| purchase_vendor_quotes | impuestos | SI | Taxes | OK | SOSPECHOSO | Taxes | |
| purchase_vendor_quotes | total | SI | Total | OK | SOSPECHOSO | Total | |
| purchase_vendor_quotes | capturada_por | SI | Captured by | OK | SOSPECHOSO | Captured by | |
| purchase_vendor_quotes | aprobada_por | SI | Approved by | OK | SOSPECHOSO | Approved by | |
| purchase_vendor_quotes | aprobada_en | SI | Approved at | OK | SOSPECHOSO | Approved at | |
| purchase_vendor_quotes | notas | SI | Notes | OK | SOSPECHOSO | Notes | |
| purchase_vendor_quotes | meta | SI | Metadata | OK | SOSPECHOSO | Metadata | |
| purchase_vendor_quotes | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| purchase_vendor_quotes | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |
| purchase_vendor_quote_lines | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| purchase_vendor_quote_lines | quote_id | SI | Quote foreign key | OK | SOSPECHOSO | Quote foreign key | |
| purchase_vendor_quote_lines | request_line_id | SI | Request line foreign key | OK | SOSPECHOSO | Request line foreign key | |
| purchase_vendor_quote_lines | item_id | SI | Item foreign key | OK | SOSPECHOSO | Item foreign key | |
| purchase_vendor_quote_lines | qty_oferta | SI | Offered quantity | OK | SOSPECHOSO | Offered quantity | |
| purchase_vendor_quote_lines | uom_oferta | SI | Offered UOM | OK | SOSPECHOSO | Offered UOM | |
| purchase_vendor_quote_lines | precio_unitario | SI | Unit price | OK | SOSPECHOSO | Unit price | |
| purchase_vendor_quote_lines | pack_size | SI | Pack size | OK | SOSPECHOSO | Pack size | |
| purchase_vendor_quote_lines | pack_uom | SI | Pack UOM | OK | SOSPECHOSO | Pack UOM | |
| purchase_vendor_quote_lines | monto_total | SI | Total amount | OK | SOSPECHOSO | Total amount | |
| purchase_vendor_quote_lines | meta | SI | Metadata | OK | SOSPECHOSO | Metadata | |
| purchase_vendor_quote_lines | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| purchase_vendor_quote_lines | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |
| cat_proveedores | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| cat_proveedores | rfc | SI | RFC field | OK | SOSPECHOSO | RFC field | |
| cat_proveedores | nombre | SI | Name field | OK | SOSPECHOSO | Name field | |
| cat_proveedores | telefono | SI | Phone field | OK | SOSPECHOSO | Phone field | |
| cat_proveedores | email | SI | Email field | OK | SOSPECHOSO | Email field | |
| cat_proveedores | activo | SI | Active flag | OK | SOSPECHOSO | Active flag | |
| cat_proveedores | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| cat_proveedores | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |
| cat_proveedores | razon_social | SI | Business name | OK | SOSPECHOSO | Business name | |
| cat_proveedores | tipo_comprobante | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | uso_cfdi | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | metodo_pago | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | forma_pago | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | regimen_fiscal | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | contacto_nombre | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | contacto_email | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | contacto_telefono | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | direccion | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | ciudad | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | estado | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | pais | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | cp | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| cat_proveedores | notas | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| purchase_suggestions | folio | SI | Folio field | OK | SOSPECHOSO | Folio field | |
| purchase_suggestions | sucursal_id | SI | Branch foreign key | OK | SOSPECHOSO | Branch foreign key | |
| purchase_suggestions | almacen_id | SI | Warehouse foreign key | OK | SOSPECHOSO | Warehouse foreign key | |
| purchase_suggestions | estado | SI | Status field | OK | SOSPECHOSO | Status field | |
| purchase_suggestions | prioridad | SI | Priority field | OK | SOSPECHOSO | Priority field | |
| purchase_suggestions | origen | SI | Origin field | OK | SOSPECHOSO | Origin field | |
| purchase_suggestions | total_items | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | total_estimado | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | sugerido_en | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | sugerido_por_user_id | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | revisado_por_user_id | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | revisado_en | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | convertido_a_request_id | SI | Converted to request foreign key | OK | SOSPECHOSO | Converted to request foreign key | |
| purchase_suggestions | convertido_en | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | dias_analisis | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | consumo_promedio_calculado | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | notas | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | meta | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | created_at | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestions | updated_at | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| purchase_suggestion_lines | suggestion_id | SI | Suggestion foreign key | OK | SOSPECHOSO | Suggestion foreign key | |
| purchase_suggestion_lines | item_id | SI | Item foreign key | OK | SOSPECHOSO | Item foreign key | |
| purchase_suggestion_lines | stock_actual | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | stock_min | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | stock_max | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | reorder_point | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | consumo_promedio_diario | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | dias_cobertura_actual | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | demanda_proyectada | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | qty_sugerida | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | qty_ajustada | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | uom | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | costo_unitario_estimado | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | costo_total_linea | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | proveedor_sugerido_id | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | ultimo_precio_compra | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | fecha_ultima_compra | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | notas | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | created_at | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| purchase_suggestion_lines | updated_at | SI | Field exists in DB but not referenced in code | OK | SOSPECHOSO | Field exists in DB but not referenced in code | |
| replenishment_suggestions | id | SI | Primary key | OK | SOSPECHOSO | Primary key | |
| replenishment_suggestions | folio | SI | Folio field | OK | SOSPECHOSO | Folio field | |
| replenishment_suggestions | tipo | SI | Type field | OK | SOSPECHOSO | Type field | |
| replenishment_suggestions | prioridad | SI | Priority field | OK | SOSPECHOSO | Priority field | |
| replenishment_suggestions | origen | SI | Origin field | OK | SOSPECHOSO | Origin field | |
| replenishment_suggestions | item_id | SI | Item foreign key | OK | SOSPECHOSO | Item foreign key | |
| replenishment_suggestions | sucursal_id | SI | Branch foreign key | OK | SOSPECHOSO | Branch foreign key | |
| replenishment_suggestions | almacen_id | SI | Warehouse foreign key | OK | SOSPECHOSO | Warehouse foreign key | |
| replenishment_suggestions | stock_actual | SI | Actual stock | OK | SOSPECHOSO | Actual stock | |
| replenishment_suggestions | stock_min | SI | Min stock | OK | SOSPECHOSO | Min stock | |
| replenishment_suggestions | stock_max | SI | Max stock | OK | SOSPECHOSO | Max stock | |
| replenishment_suggestions | qty_sugerida | SI | Suggested quantity | OK | SOSPECHOSO | Suggested quantity | |
| replenishment_suggestions | qty_aprobada | SI | Approved quantity | OK | SOSPECHOSO | Approved quantity | |
| replenishment_suggestions | uom | SI | Unit of measure | OK | SOSPECHOSO | Unit of measure | |
| replenishment_suggestions | consumo_promedio_diario | SI | Average daily consumption | OK | SOSPECHOSO | Average daily consumption | |
| replenishment_suggestions | dias_stock_restante | SI | Days remaining stock | OK | SOSPECHOSO | Days remaining stock | |
| replenishment_suggestions | fecha_agotamiento_estimada | SI | Estimated depletion date | OK | SOSPECHOSO | Estimated depletion date | |
| replenishment_suggestions | estado | SI | Status field | OK | SOSPECHOSO | Status field | |
| replenishment_suggestions | purchase_request_id | SI | Purchase request foreign key | OK | SOSPECHOSO | Purchase request foreign key | |
| replenishment_suggestions | production_order_id | SI | Production order foreign key | OK | SOSPECHOSO | Production order foreign key | |
| replenishment_suggestions | sugerido_en | SI | Suggested at | OK | SOSPECHOSO | Suggested at | |
| replenishment_suggestions | revisado_en | SI | Reviewed at | OK | SOSPECHOSO | Reviewed at | |
| replenishment_suggestions | revisado_por | SI | Reviewed by | OK | SOSPECHOSO | Reviewed by | |
| replenishment_suggestions | convertido_en | SI | Converted at | OK | SOSPECHOSO | Converted at | |
| replenishment_suggestions | caduca_en | SI | Expires at | OK | SOSPECHOSO | Expires at | |
| replenishment_suggestions | motivo | SI | Reason | OK | SOSPECHOSO | Reason | |
| replenishment_suggestions | motivo_rechazo | SI | Rejection reason | OK | SOSPECHOSO | Rejection reason | |
| replenishment_suggestions | notas | SI | Notes | OK | SOSPECHOSO | Notes | |
| replenishment_suggestions | meta | SI | Metadata | OK | SOSPECHOSO | Metadata | |
| replenishment_suggestions | created_at | SI | Created timestamp | OK | SOSPECHOSO | Created timestamp | |
| replenishment_suggestions | updated_at | SI | Updated timestamp | OK | SOSPECHOSO | Updated timestamp | |

## §1 Resumen

- Filas CONFIABLE: 0
- Filas SOSPECHOSO: 323
- Filas ERROR_MAPA: 0

## §2 Listado de filas ERROR_MAPA

No se encontraron errores de mapeo.

## §3 Sugerencias de corrección

El archivo original 'BD_CODIGO_MAPA_CAMPOS_PROD_PURCH.md' debe actualizarse para reflejar la realidad de la base de datos. Los errores encontrados indican discrepancias entre lo que el mapeo original asumía y la estructura real de la base de datos.

Especialmente importante es corregir las filas marcadas como ERROR_MAPA, donde el estado original contradice directamente la existencia real de los campos en la base de datos.

