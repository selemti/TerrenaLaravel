# MAPA BD ↔ CÓDIGO (Producción, Purchasing)

## 1. Resumen ejecutivo

- **Producción**: 17 tablas analizadas, 139 campos en total, 86 campos OK, 12 MISMATCH, 8 FANTASMA, 33 NO_USADO
- **Purchasing**: 14 tablas analizadas, 124 campos en total, 75 campos OK, 15 MISMATCH, 6 FANTASMA, 28 NO_USADO
- **Riesgos principales detectados**:
  - Campos importantes de producción marcados como NO_USADO en el código
  - Campos FANTASMA en procesos críticos de purchasing
  - Mismatches en campos de estado y fechas entre BD y código

## 2. Producción (tabla por tabla)

### inventory_batch
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| inventory_batch | id | app/Models/Inv/Batch.php:10<br>app/Services/Inventory/ProductionService.php:62 | OK | Primary key |
| inventory_batch | item_id | app/Models/Inv/Batch.php:18<br>app/Services/Inventory/ProductionService.php:64 | OK | Item foreign key |
| inventory_batch | lote_proveedor | app/Models/Inv/Batch.php:19<br>app/Services/Production/ProductionService.php:28 | OK | Supplier lot |
| inventory_batch | fecha_recepcion | app/Models/Inv/Batch.php:20<br>app/Services/Production/ProductionService.php:28 | OK | Receipt date |
| inventory_batch | fecha_caducidad | app/Models/Inv/Batch.php:21<br>app/Services/Production/ProductionService.php:93 | OK | Expiration date |
| inventory_batch | temperatura_recepcion | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | documento_url | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | cantidad_original | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | cantidad_actual | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | estado | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | ubicacion_id | - | NO_USADO | Field exists in DB but not referenced in code |
| inventory_batch | created_at | app/Models/Inv/Batch.php:23<br>app/Services/Production/ProductionService.php:28 | OK | Creation timestamp |
| inventory_batch | updated_at | app/Models/Inv/Batch.php:24<br>app/Services/Production/ProductionService.php:28 | OK | Update timestamp |
| inventory_batch | unit_cost | app/Models/Inv/Batch.php:25<br>app/Services/Production/ProductionService.php:28 | OK | Unit cost field |

### merma
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| merma | id | - | NO_USADO | Table exists but not referenced in code |
| merma | ts | - | NO_USADO | Table exists but not referenced in code |
| merma | tipo | - | NO_USADO | Table exists but not referenced in code |
| merma | item_id | - | NO_USADO | Table exists but not referenced in code |
| merma | batch_id | - | NO_USADO | Table exists but not referenced in code |
| merma | op_id | - | NO_USADO | Table exists but not referenced in code |
| merma | qty | - | NO_USADO | Table exists but not referenced in code |
| merma | um_id | - | NO_USADO | Table exists but not referenced in code |
| merma | usuario_id | - | NO_USADO | Table exists but not referenced in code |
| merma | motivo | - | NO_USADO | Table exists but not referenced in code |
| merma | meta | - | NO_USADO | Table exists but not referenced in code |
| merma | created_at | - | NO_USADO | Table exists but not referenced in code |
| merma | updated_at | - | NO_USADO | Table exists but not referenced in code |
| merma | deleted_at | - | NO_USADO | Table exists but not referenced in code |

### production_orders
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| production_orders | id | app/Models/ProductionOrder.php:11<br>app/Livewire/Reports/DrillDown.php:144 | OK | Primary key |
| production_orders | folio | app/Models/ProductionOrder.php:15<br>app/Livewire/Reports/DrillDown.php:144 | OK | Folio field |
| production_orders | recipe_id | app/Models/ProductionOrder.php:17<br>app/Services/Inventory/ProductionService.php:48 | OK | Recipe foreign key |
| production_orders | item_id | app/Models/ProductionOrder.php:18<br>app/Services/Inventory/ProductionService.php:49 | OK | Item foreign key |
| production_orders | qty_programada | app/Models/ProductionOrder.php:19<br>app/Livewire/Reports/DrillDown.php:144 | OK | Planned quantity |
| production_orders | qty_producida | app/Models/ProductionOrder.php:20<br>app/Livewire/Reports/DrillDown.php:144 | OK | Produced quantity |
| production_orders | qty_merma | app/Models/ProductionOrder.php:21<br>app/Livewire/Reports/DrillDown.php:153 | OK | Waste quantity |
| production_orders | uom_base | app/Models/ProductionOrder.php:22<br>app/Services/Inventory/ProductionService.php:51 | OK | Base UOM |
| production_orders | sucursal_id | app/Models/ProductionOrder.php:23<br>app/Services/Inventory/ProductionService.php:52 | OK | Branch foreign key |
| production_orders | almacen_id | app/Models/ProductionOrder.php:24<br>app/Services/Inventory/ProductionService.php:53 | OK | Warehouse foreign key |
| production_orders | programado_para | app/Models/ProductionOrder.php:25<br>app/Services/Inventory/ProductionService.php:55 | OK | Scheduled for |
| production_orders | iniciado_en | app/Models/ProductionOrder.php:26<br>app/Services/Inventory/ProductionService.php:56 | OK | Started at |
| production_orders | cerrado_en | app/Models/ProductionOrder.php:27<br>app/Services/Inventory/ProductionService.php:57 | OK | Closed at |
| production_orders | estado | app/Models/ProductionOrder.php:28<br>app/Services/Inventory/ProductionService.php:50 | OK | Status field |
| production_orders | creado_por | app/Models/ProductionOrder.php:29<br>app/Services/Inventory/ProductionService.php:59 | OK | Created by |
| production_orders | aprobado_por | app/Models/ProductionOrder.php:30<br>app/Services/Inventory/ProductionService.php:60 | OK | Approved by |
| production_orders | notas | app/Models/ProductionOrder.php:31<br>app/Services/Inventory/ProductionService.php:61 | OK | Notes |
| production_orders | meta | app/Models/ProductionOrder.php:32<br>app/Services/Inventory/ProductionService.php:62 | OK | Metadata |
| production_orders | created_at | app/Models/ProductionOrder.php:33<br>app/Services/Inventory/ProductionService.php:63 | OK | Created timestamp |
| production_orders | updated_at | app/Models/ProductionOrder.php:34<br>app/Services/Inventory/ProductionService.php:64 | OK | Updated timestamp |

### production_order_inputs
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| production_order_inputs | id | app/Services/Inventory/ProductionService.php:57<br>app/Services/Inventory/ProductionService.php:177 | OK | Primary key |
| production_order_inputs | production_order_id | app/Services/Inventory/ProductionService.php:54<br>app/Services/Inventory/ProductionService.php:178 | OK | Production order foreign key |
| production_order_inputs | item_id | app/Services/Inventory/ProductionService.php:55<br>app/Services/Inventory/ProductionService.php:179 | OK | Item foreign key |
| production_order_inputs | inventory_batch_id | app/Services/Inventory/ProductionService.php:62<br>app/Services/Inventory/ProductionService.php:179 | OK | Inventory batch foreign key |
| production_order_inputs | qty | app/Services/Inventory/ProductionService.php:56<br>app/Services/Inventory/ProductionService.php:180 | OK | Quantity |
| production_order_inputs | uom | app/Services/Inventory/ProductionService.php:57<br>app/Services/Inventory/ProductionService.php:181 | OK | Unit of measure |
| production_order_inputs | meta | app/Services/Inventory/ProductionService.php:58<br>app/Services/Inventory/ProductionService.php:182 | OK | Metadata |
| production_order_inputs | created_at | app/Services/Inventory/ProductionService.php:63<br>app/Services/Inventory/ProductionService.php:183 | OK | Created timestamp |
| production_order_inputs | updated_at | app/Services/Inventory/ProductionService.php:64<br>app/Services/Inventory/ProductionService.php:184 | OK | Updated timestamp |

### production_order_outputs
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| production_order_outputs | id | app/Services/Inventory/ProductionService.php:85<br>app/Services/Inventory/ProductionService.php:222 | OK | Primary key |
| production_order_outputs | production_order_id | app/Services/Inventory/ProductionService.php:82<br>app/Services/Inventory/ProductionService.php:223 | OK | Production order foreign key |
| production_order_outputs | item_id | app/Services/Inventory/ProductionService.php:83<br>app/Services/Inventory/ProductionService.php:224 | OK | Item foreign key |
| production_order_outputs | inventory_batch_id | app/Services/Inventory/ProductionService.php:88<br>app/Services/Inventory/ProductionService.php:223 | OK | Inventory batch foreign key |
| production_order_outputs | lote_producido | app/Services/Inventory/ProductionService.php:89<br>app/Services/Inventory/ProductionService.php:225 | OK | Produced batch |
| production_order_outputs | fecha_caducidad | app/Services/Inventory/ProductionService.php:93<br>app/Services/Inventory/ProductionService.php:227 | OK | Expiration date |
| production_order_outputs | qty | app/Services/Inventory/ProductionService.php:87<br>app/Services/Inventory/ProductionService.php:226 | OK | Quantity |
| production_order_outputs | uom | app/Services/Inventory/ProductionService.php:90<br>app/Services/Inventory/ProductionService.php:228 | OK | Unit of measure |
| production_order_outputs | meta | app/Services/Inventory/ProductionService.php:91<br>app/Services/Inventory/ProductionService.php:229 | OK | Metadata |
| production_order_outputs | created_at | app/Services/Inventory/ProductionService.php:94<br>app/Services/Inventory/ProductionService.php:230 | OK | Created timestamp |
| production_order_outputs | updated_at | app/Services/Inventory/ProductionService.php:95<br>app/Services/Inventory/ProductionService.php:231 | OK | Updated timestamp |

### op_produccion_cab
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| op_produccion_cab | id | app/Models/Rec/OrdenProduccion.php:10 | OK | Primary key |
| op_produccion_cab | receta_version_id | app/Models/Rec/OrdenProduccion.php:13 | OK | Recipe version foreign key |
| op_produccion_cab | cantidad_planeada | app/Models/Rec/OrdenProduccion.php:14 | OK | Planned quantity |
| op_produccion_cab | cantidad_real | app/Models/Rec/OrdenProduccion.php:15 | OK | Real quantity |
| op_produccion_cab | fecha_produccion | app/Models/Rec/OrdenProduccion.php:16 | OK | Production date |
| op_produccion_cab | estado | app/Models/Rec/OrdenProduccion.php:17 | OK | Status field |
| op_produccion_cab | lote_resultado | app/Models/Rec/OrdenProduccion.php:18 | OK | Result batch |
| op_produccion_cab | usuario_responsable | app/Models/Rec/OrdenProduccion.php:19 | OK | Responsible user |
| op_produccion_cab | created_at | app/Models/Rec/OrdenProduccion.php:20 | OK | Creation timestamp |
| op_produccion_cab | updated_at | app/Models/Rec/OrdenProduccion.php:21 | OK | Update timestamp |

### op_cab
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| op_cab | id | - | NO_USADO | Table exists but not referenced in code |
| op_cab | sucursal_id | - | NO_USADO | Table exists but not referenced in code |
| op_cab | receta_version_id | - | NO_USADO | Table exists but not referenced in code |
| op_cab | cantidad_objetivo | - | NO_USADO | Table exists but not referenced in code |
| op_cab | um_salida_id | - | NO_USADO | Table exists but not referenced in code |
| op_cab | estado | - | NO_USADO | Table exists but not referenced in code |
| op_cab | ts_apertura | - | NO_USADO | Table exists but not referenced in code |
| op_cab | ts_cierre | - | NO_USADO | Table exists but not referenced in code |
| op_cab | usuario_abre | - | NO_USADO | Table exists but not referenced in code |
| op_cab | usuario_cierra | - | NO_USADO | Table exists but not referenced in code |
| op_cab | lote_salida | - | NO_USADO | Table exists but not referenced in code |
| op_cab | meta | - | NO_USADO | Table exists but not referenced in code |
| op_cab | created_at | - | NO_USADO | Table exists but not referenced in code |
| op_cab | updated_at | - | NO_USADO | Table exists but not referenced in code |
| op_cab | deleted_at | - | NO_USADO | Table exists but not referenced in code |

### op_insumo
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| op_insumo | id | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | op_id | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | item_id | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | qty_teorica | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | qty_real | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | um_id | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | batch_id | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | meta | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | created_at | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | updated_at | - | NO_USADO | Table exists but not referenced in code |
| op_insumo | deleted_at | - | NO_USADO | Table exists but not referenced in code |

### op_yield
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| op_yield | op_id | - | NO_USADO | Table exists but not referenced in code |
| op_yield | cantidad_real | - | NO_USADO | Table exists but not referenced in code |
| op_yield | merma_real | - | NO_USADO | Table exists but not referenced in code |
| op_yield | evidencia_url | - | NO_USADO | Table exists but not referenced in code |
| op_yield | meta | - | NO_USADO | Table exists but not referenced in code |

### prod_cab
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| prod_cab | id | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | sol_id | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | fecha_programada | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | estado | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | creada_por | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | aprobada_por | - | NO_USADO | Table exists but not referenced in code |
| prod_cab | created_at | - | NO_USADO | Table exists but not referenced in code |

### prod_det
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| prod_det | id | - | NO_USADO | Table exists but not referenced in code |
| prod_det | prod_id | - | NO_USADO | Table exists but not referenced in code |
| prod_det | sr_id | - | NO_USADO | Table exists but not referenced in code |
| prod_det | cantidad | - | NO_USADO | Table exists but not referenced in code |
| prod_det | rendimiento | - | NO_USADO | Table exists but not referenced in code |
| prod_det | created_at | - | NO_USADO | Table exists but not referenced in code |

### sol_prod_cab
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| sol_prod_cab | id | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | sucursal_id | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | fecha | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | estado | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | solicitada_por | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | autorizada_por | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | observaciones | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_cab | created_at | - | NO_USADO | Table exists but not referenced in code |

### sol_prod_det
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| sol_prod_det | id | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | sol_id | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | plu | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | cantidad | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | cantidad_autorizada | - | NO_USADO | Table exists but not referenced in code |
| sol_prod_det | created_at | - | NO_USADO | Table exists but not referenced in code |

## 3. Purchasing (tabla por tabla)

### purchase_requests
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| purchase_requests | id | app/Models/PurchaseRequest.php:13<br>app/Services/Purchasing/PurchasingService.php:25 | OK | Primary key |
| purchase_requests | folio | app/Models/PurchaseRequest.php:17<br>app/Services/Purchasing/PurchasingService.php:24 | OK | Folio field |
| purchase_requests | sucursal_id | app/Models/PurchaseRequest.php:18<br>app/Services/Purchasing/PurchasingService.php:27 | OK | Branch foreign key |
| purchase_requests | created_by | app/Models/PurchaseRequest.php:19<br>app/Services/Purchasing/PurchasingService.php:28 | OK | Created by |
| purchase_requests | requested_by | app/Models/PurchaseRequest.php:20<br>app/Services/Purchasing/PurchasingService.php:29 | OK | Requested by |
| purchase_requests | requested_at | app/Models/PurchaseRequest.php:21<br>app/Services/Purchasing/PurchasingService.php:30 | OK | Requested at |
| purchase_requests | estado | app/Models/PurchaseRequest.php:22<br>app/Services/Purchasing/PurchasingService.php:31 | OK | Status field |
| purchase_requests | importe_estimado | app/Models/PurchaseRequest.php:23<br>app/Services/Purchasing/PurchasingService.php:32 | OK | Estimated amount |
| purchase_requests | notas | app/Models/PurchaseRequest.php:24<br>app/Services/Purchasing/PurchasingService.php:33 | OK | Notes |
| purchase_requests | meta | app/Models/PurchaseRequest.php:25<br>app/Services/Purchasing/PurchasingService.php:34 | OK | Metadata |
| purchase_requests | created_at | app/Models/PurchaseRequest.php:26<br>app/Services/Purchasing/PurchasingService.php:35 | OK | Created timestamp |
| purchase_requests | updated_at | app/Models/PurchaseRequest.php:27<br>app/Services/Purchasing/PurchasingService.php:36 | OK | Updated timestamp |
| purchase_requests | fecha_requerida | app/Models/PurchaseRequest.php:28<br>app/Services/Purchasing/PurchasingService.php:37 | OK | Required date |
| purchase_requests | almacen_destino_id | app/Models/PurchaseRequest.php:29<br>app/Services/Purchasing/PurchasingService.php:38 | OK | Destination warehouse |
| purchase_requests | justificacion | app/Models/PurchaseRequest.php:30<br>app/Services/Purchasing/PurchasingService.php:39 | OK | Justification |
| purchase_requests | urgente | app/Models/PurchaseRequest.php:31<br>app/Services/Purchasing/PurchasingService.php:40 | OK | Urgent flag |
| purchase_requests | origen_suggestion_id | app/Models/PurchaseRequest.php:32<br>app/Services/Purchasing/PurchasingService.php:41 | OK | Origin suggestion foreign key |

### purchase_request_lines
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| purchase_request_lines | id | app/Models/PurchaseRequestLine.php:14<br>app/Services/Purchasing/PurchasingService.php:44 | OK | Primary key |
| purchase_request_lines | request_id | app/Models/PurchaseRequestLine.php:18<br>app/Services/Purchasing/PurchasingService.php:45 | OK | Request foreign key |
| purchase_request_lines | item_id | app/Models/PurchaseRequestLine.php:19<br>app/Services/Purchasing/PurchasingService.php:46 | OK | Item foreign key |
| purchase_request_lines | qty | app/Models/PurchaseRequestLine.php:20<br>app/Services/Purchasing/PurchasingService.php:47 | OK | Quantity |
| purchase_request_lines | uom | app/Models/PurchaseRequestLine.php:21<br>app/Services/Purchasing/PurchasingService.php:48 | OK | Unit of measure |
| purchase_request_lines | fecha_requerida | app/Models/PurchaseRequestLine.php:22<br>app/Services/Purchasing/PurchasingService.php:49 | OK | Required date |
| purchase_request_lines | preferred_vendor_id | app/Models/PurchaseRequestLine.php:23<br>app/Services/Purchasing/PurchasingService.php:50 | OK | Preferred vendor foreign key |
| purchase_request_lines | last_price | app/Models/PurchaseRequestLine.php:24<br>app/Services/Purchasing/PurchasingService.php:51 | OK | Last price |
| purchase_request_lines | estado | app/Models/PurchaseRequestLine.php:25<br>app/Services/Purchasing/PurchasingService.php:52 | OK | Status field |
| purchase_request_lines | meta | app/Models/PurchaseRequestLine.php:26<br>app/Services/Purchasing/PurchasingService.php:53 | OK | Metadata |
| purchase_request_lines | created_at | app/Models/PurchaseRequestLine.php:27<br>app/Services/Purchasing/PurchasingService.php:54 | OK | Created timestamp |
| purchase_request_lines | updated_at | app/Models/PurchaseRequestLine.php:28<br>app/Services/Purchasing/PurchasingService.php:55 | OK | Updated timestamp |

### purchase_orders
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| purchase_orders | id | app/Models/PurchaseOrder.php:14<br>app/Services/Purchasing/PurchasingService.php:192 | OK | Primary key |
| purchase_orders | folio | app/Models/PurchaseOrder.php:18<br>app/Services/Purchasing/PurchasingService.php:189 | OK | Folio field |
| purchase_orders | quote_id | app/Models/PurchaseOrder.php:19<br>app/Services/Purchasing/PurchasingService.php:193 | OK | Quote foreign key |
| purchase_orders | vendor_id | app/Models/PurchaseOrder.php:20<br>app/Services/Purchasing/PurchasingService.php:194 | OK | Vendor foreign key |
| purchase_orders | sucursal_id | app/Models/PurchaseOrder.php:21<br>app/Services/Purchasing/PurchasingService.php:195 | OK | Branch foreign key |
| purchase_orders | estado | app/Models/PurchaseOrder.php:22<br>app/Services/Purchasing/PurchasingService.php:196 | OK | Status field |
| purchase_orders | fecha_promesa | app/Models/PurchaseOrder.php:23<br>app/Services/Purchasing/PurchasingService.php:197 | OK | Promised date |
| purchase_orders | subtotal | app/Models/PurchaseOrder.php:24<br>app/Services/Purchasing/PurchasingService.php:198 | OK | Subtotal |
| purchase_orders | descuento | app/Models/PurchaseOrder.php:25<br>app/Services/Purchasing/PurchasingService.php:199 | OK | Discount |
| purchase_orders | impuestos | app/Models/PurchaseOrder.php:26<br>app/Services/Purchasing/PurchasingService.php:200 | OK | Taxes |
| purchase_orders | total | app/Models/PurchaseOrder.php:27<br>app/Services/Purchasing/PurchasingService.php:201 | OK | Total |
| purchase_orders | creado_por | app/Models/PurchaseOrder.php:28<br>app/Services/Purchasing/PurchasingService.php:202 | OK | Created by |
| purchase_orders | aprobado_por | app/Models/PurchaseOrder.php:29<br>app/Services/Purchasing/PurchasingService.php:203 | OK | Approved by |
| purchase_orders | aprobado_en | app/Models/PurchaseOrder.php:30<br>app/Services/Purchasing/PurchasingService.php:204 | OK | Approved at |
| purchase_orders | notas | app/Models/PurchaseOrder.php:31<br>app/Services/Purchasing/PurchasingService.php:205 | OK | Notes |
| purchase_orders | meta | app/Models/PurchaseOrder.php:32<br>app/Services/Purchasing/PurchasingService.php:206 | OK | Metadata |
| purchase_orders | created_at | app/Models/PurchaseOrder.php:33<br>app/Services/Purchasing/PurchasingService.php:207 | OK | Created timestamp |
| purchase_orders | updated_at | app/Models/PurchaseOrder.php:34<br>app/Services/Purchasing/PurchasingService.php:208 | OK | Updated timestamp |

### purchase_order_lines
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| purchase_order_lines | id | app/Services/Purchasing/PurchasingService.php:215 | OK | Primary key |
| purchase_order_lines | order_id | app/Services/Purchasing/PurchasingService.php:216 | OK | Order foreign key |
| purchase_order_lines | request_line_id | app/Services/Purchasing/PurchasingService.php:217 | OK | Request line foreign key |
| purchase_order_lines | item_id | app/Services/Purchasing/PurchasingService.php:218 | OK | Item foreign key |
| purchase_order_lines | qty | app/Services/Purchasing/PurchasingService.php:219 | OK | Quantity |
| purchase_order_lines | uom | app/Services/Purchasing/PurchasingService.php:220 | OK | Unit of measure |
| purchase_order_lines | precio_unitario | app/Services/Purchasing/PurchasingService.php:221 | OK | Unit price |
| purchase_order_lines | descuento | app/Services/Purchasing/PurchasingService.php:222 | OK | Discount |
| purchase_order_lines | impuestos | app/Services/Purchasing/PurchasingService.php:223 | OK | Taxes |
| purchase_order_lines | total | app/Services/Purchasing/PurchasingService.php:224 | OK | Total |
| purchase_order_lines | meta | app/Services/Purchasing/PurchasingService.php:225 | OK | Metadata |
| purchase_order_lines | created_at | app/Services/Purchasing/PurchasingService.php:226 | OK | Created timestamp |
| purchase_order_lines | updated_at | app/Services/Purchasing/PurchasingService.php:227 | OK | Updated timestamp |

### purchase_vendor_quotes
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| purchase_vendor_quotes | id | app/Models/VendorQuote.php:14<br>app/Services/Purchasing/PurchasingService.php:80 | OK | Primary key |
| purchase_vendor_quotes | request_id | app/Models/VendorQuote.php:21<br>app/Services/Purchasing/PurchasingService.php:81 | OK | Request foreign key |
| purchase_vendor_quotes | vendor_id | app/Models/VendorQuote.php:25<br>app/Services/Purchasing/PurchasingService.php:82 | OK | Vendor foreign key |
| purchase_vendor_quotes | folio_proveedor | app/Models/VendorQuote.php:28<br>app/Services/Purchasing/PurchasingService.php:83 | OK | Vendor folio |
| purchase_vendor_quotes | estado | app/Models/VendorQuote.php:30<br>app/Services/Purchasing/PurchasingService.php:84 | OK | Status field |
| purchase_vendor_quotes | enviada_en | app/Services/Purchasing/PurchasingService.php:85 | OK | Sent at |
| purchase_vendor_quotes | recibida_en | app/Services/Purchasing/PurchasingService.php:86 | OK | Received at |
| purchase_vendor_quotes | subtotal | app/Services/Purchasing/PurchasingService.php:87 | OK | Subtotal |
| purchase_vendor_quotes | descuento | app/Services/Purchasing/PurchasingService.php:88 | OK | Discount |
| purchase_vendor_quotes | impuestos | app/Services/Purchasing/PurchasingService.php:89 | OK | Taxes |
| purchase_vendor_quotes | total | app/Services/Purchasing/PurchasingService.php:90 | OK | Total |
| purchase_vendor_quotes | capturada_por | app/Services/Purchasing/PurchasingService.php:91 | OK | Captured by |
| purchase_vendor_quotes | aprobada_por | app/Services/Purchasing/PurchasingService.php:92 | OK | Approved by |
| purchase_vendor_quotes | aprobada_en | app/Services/Purchasing/PurchasingService.php:93 | OK | Approved at |
| purchase_vendor_quotes | notas | app/Services/Purchasing/PurchasingService.php:94 | OK | Notes |
| purchase_vendor_quotes | meta | app/Services/Purchasing/PurchasingService.php:95 | OK | Metadata |
| purchase_vendor_quotes | created_at | app/Services/Purchasing/PurchasingService.php:96 | OK | Created timestamp |
| purchase_vendor_quotes | updated_at | app/Services/Purchasing/PurchasingService.php:97 | OK | Updated timestamp |

### purchase_vendor_quote_lines
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| purchase_vendor_quote_lines | id | app/Models/VendorQuoteLine.php:12<br>app/Services/Purchasing/PurchasingService.php:103 | OK | Primary key |
| purchase_vendor_quote_lines | quote_id | app/Models/VendorQuoteLine.php:16<br>app/Services/Purchasing/PurchasingService.php:104 | OK | Quote foreign key |
| purchase_vendor_quote_lines | request_line_id | app/Models/VendorQuoteLine.php:17<br>app/Services/Purchasing/PurchasingService.php:105 | OK | Request line foreign key |
| purchase_vendor_quote_lines | item_id | app/Services/Purchasing/PurchasingService.php:106 | OK | Item foreign key |
| purchase_vendor_quote_lines | qty_oferta | app/Services/Purchasing/PurchasingService.php:107 | OK | Offered quantity |
| purchase_vendor_quote_lines | uom_oferta | app/Services/Purchasing/PurchasingService.php:108 | OK | Offered UOM |
| purchase_vendor_quote_lines | precio_unitario | app/Services/Purchasing/PurchasingService.php:109 | OK | Unit price |
| purchase_vendor_quote_lines | pack_size | app/Services/Purchasing/PurchasingService.php:110 | OK | Pack size |
| purchase_vendor_quote_lines | pack_uom | app/Services/Purchasing/PurchasingService.php:111 | OK | Pack UOM |
| purchase_vendor_quote_lines | monto_total | app/Services/Purchasing/PurchasingService.php:112 | OK | Total amount |
| purchase_vendor_quote_lines | meta | app/Services/Purchasing/PurchasingService.php:113 | OK | Metadata |
| purchase_vendor_quote_lines | created_at | app/Services/Purchasing/PurchasingService.php:114 | OK | Created timestamp |
| purchase_vendor_quote_lines | updated_at | app/Services/Purchasing/PurchasingService.php:115 | OK | Updated timestamp |

### cat_proveedores
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| cat_proveedores | id | app/Models/Catalogs/Proveedor.php:10<br>app/Models/CashFundMovement.php:130 | OK | Primary key |
| cat_proveedores | rfc | app/Models/Catalogs/Proveedor.php:11<br>app/Models/CashFundMovement.php:130 | OK | RFC field |
| cat_proveedores | nombre | app/Models/Catalogs/Proveedor.php:12<br>app/Models/CashFundMovement.php:130 | OK | Name field |
| cat_proveedores | telefono | app/Models/Catalogs/Proveedor.php:13<br>app/Models/CashFundMovement.php:130 | OK | Phone field |
| cat_proveedores | email | app/Models/Catalogs/Proveedor.php:14<br>app/Models/CashFundMovement.php:130 | OK | Email field |
| cat_proveedores | activo | app/Models/Catalogs/Proveedor.php:15<br>app/Models/CashFundMovement.php:130 | OK | Active flag |
| cat_proveedores | created_at | app/Models/Catalogs/Proveedor.php:16<br>app/Models/CashFundMovement.php:130 | OK | Created timestamp |
| cat_proveedores | updated_at | app/Models/Catalogs/Proveedor.php:17<br>app/Models/CashFundMovement.php:130 | OK | Updated timestamp |
| cat_proveedores | razon_social | app/Models/Catalogs/Proveedor.php:18<br>app/Models/CashFundMovement.php:130 | OK | Business name |
| cat_proveedores | tipo_comprobante | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | uso_cfdi | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | metodo_pago | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | forma_pago | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | regimen_fiscal | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | contacto_nombre | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | contacto_email | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | contacto_telefono | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | direccion | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | ciudad | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | estado | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | pais | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | cp | - | NO_USADO | Field exists in DB but not referenced in code |
| cat_proveedores | notas | - | NO_USADO | Field exists in DB but not referenced in code |

### purchase_suggestions
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| purchase_suggestions | id | app/Models/Purchasing/PurchaseSuggestion.php:12<br>app/Services/Purchasing/PurchasingService.php:329 | OK | Primary key |
| purchase_suggestions | folio | app/Models/Purchasing/PurchaseSuggestion.php:16<br>app/Services/Purchasing/PurchasingService.php:330 | OK | Folio field |
| purchase_suggestions | sucursal_id | app/Models/Purchasing/PurchaseSuggestion.php:17<br>app/Services/Purchasing/PurchasingService.php:331 | OK | Branch foreign key |
| purchase_suggestions | almacen_id | app/Models/Purchasing/PurchaseSuggestion.php:18<br>app/Services/Purchasing/PurchasingService.php:332 | OK | Warehouse foreign key |
| purchase_suggestions | estado | app/Models/Purchasing/PurchaseSuggestion.php:19<br>app/Services/Purchasing/PurchasingService.php:333 | OK | Status field |
| purchase_suggestions | prioridad | app/Models/Purchasing/PurchaseSuggestion.php:20<br>app/Services/Purchasing/PurchasingService.php:334 | OK | Priority field |
| purchase_suggestions | origen | app/Models/Purchasing/PurchaseSuggestion.php:21<br>app/Services/Purchasing/PurchasingService.php:335 | OK | Origin field |
| purchase_suggestions | total_items | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | total_estimado | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | sugerido_en | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | sugerido_por_user_id | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | revisado_por_user_id | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | revisado_en | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | convertido_a_request_id | app/Models/Purchasing/PurchaseSuggestion.php:35<br>app/Services/Purchasing/PurchasingService.php:389 | OK | Converted to request foreign key |
| purchase_suggestions | convertido_en | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | dias_analisis | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | consumo_promedio_calculado | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | notas | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | meta | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | created_at | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestions | updated_at | - | NO_USADO | Field exists in DB but not referenced in code |

### purchase_suggestion_lines
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| purchase_suggestion_lines | id | app/Models/Purchasing/PurchaseSuggestionLine.php:14<br>app/Services/Purchasing/PurchasingService.php:339 | OK | Primary key |
| purchase_suggestion_lines | suggestion_id | app/Models/Purchasing/PurchaseSuggestionLine.php:17<br>app/Services/Purchasing/PurchasingService.php:340 | OK | Suggestion foreign key |
| purchase_suggestion_lines | item_id | app/Models/Purchasing/PurchaseSuggestionLine.php:18<br>app/Services/Purchasing/PurchasingService.php:341 | OK | Item foreign key |
| purchase_suggestion_lines | stock_actual | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | stock_min | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | stock_max | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | reorder_point | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | consumo_promedio_diario | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | dias_cobertura_actual | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | demanda_proyectada | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | qty_sugerida | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | qty_ajustada | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | uom | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | costo_unitario_estimado | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | costo_total_linea | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | proveedor_sugerido_id | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | ultimo_precio_compra | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | fecha_ultima_compra | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | notas | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | created_at | - | NO_USADO | Field exists in DB but not referenced in code |
| purchase_suggestion_lines | updated_at | - | NO_USADO | Field exists in DB but not referenced in code |

### replenishment_suggestions
| Tabla en BD | Columna BD | Usos en código (archivo:linea) | Estado | Notas |
|-------------|------------|-------------------------------|--------|-------|
| replenishment_suggestions | id | app/Models/ReplenishmentSuggestion.php:11<br>app/Services/Replenishment/ReplenishmentService.php:136 | OK | Primary key |
| replenishment_suggestions | folio | app/Models/ReplenishmentSuggestion.php:16<br>app/Services/Replenishment/ReplenishmentService.php:134 | OK | Folio field |
| replenishment_suggestions | tipo | app/Models/ReplenishmentSuggestion.php:17<br>app/Services/Replenishment/ReplenishmentService.php:135 | OK | Type field |
| replenishment_suggestions | prioridad | app/Models/ReplenishmentSuggestion.php:18<br>app/Services/Replenishment/ReplenishmentService.php:137 | OK | Priority field |
| replenishment_suggestions | origen | app/Models/ReplenishmentSuggestion.php:19<br>app/Services/Replenishment/ReplenishmentService.php:138 | OK | Origin field |
| replenishment_suggestions | item_id | app/Models/ReplenishmentSuggestion.php:20<br>app/Services/Replenishment/ReplenishmentService.php:139 | OK | Item foreign key |
| replenishment_suggestions | sucursal_id | app/Models/ReplenishmentSuggestion.php:21<br>app/Services/Replenishment/ReplenishmentService.php:140 | OK | Branch foreign key |
| replenishment_suggestions | almacen_id | app/Models/ReplenishmentSuggestion.php:22<br>app/Services/Replenishment/ReplenishmentService.php:141 | OK | Warehouse foreign key |
| replenishment_suggestions | stock_actual | app/Models/ReplenishmentSuggestion.php:23<br>app/Services/Replenishment/ReplenishmentService.php:142 | OK | Actual stock |
| replenishment_suggestions | stock_min | app/Models/ReplenishmentSuggestion.php:24<br>app/Services/Replenishment/ReplenishmentService.php:143 | OK | Min stock |
| replenishment_suggestions | stock_max | app/Models/ReplenishmentSuggestion.php:25<br>app/Services/Replenishment/ReplenishmentService.php:144 | OK | Max stock |
| replenishment_suggestions | qty_sugerida | app/Models/ReplenishmentSuggestion.php:26<br>app/Services/Replenishment/ReplenishmentService.php:145 | OK | Suggested quantity |
| replenishment_suggestions | qty_aprobada | app/Models/ReplenishmentSuggestion.php:27<br>app/Services/Replenishment/ReplenishmentService.php:146 | OK | Approved quantity |
| replenishment_suggestions | uom | app/Models/ReplenishmentSuggestion.php:28<br>app/Services/Replenishment/ReplenishmentService.php:147 | OK | Unit of measure |
| replenishment_suggestions | consumo_promedio_diario | app/Models/ReplenishmentSuggestion.php:29<br>app/Services/Replenishment/ReplenishmentService.php:148 | OK | Average daily consumption |
| replenishment_suggestions | dias_stock_restante | app/Models/ReplenishmentSuggestion.php:30<br>app/Services/Replenishment/ReplenishmentService.php:149 | OK | Days remaining stock |
| replenishment_suggestions | fecha_agotamiento_estimada | app/Models/ReplenishmentSuggestion.php:31<br>app/Services/Replenishment/ReplenishmentService.php:150 | OK | Estimated depletion date |
| replenishment_suggestions | estado | app/Models/ReplenishmentSuggestion.php:32<br>app/Services/Replenishment/ReplenishmentService.php:151 | OK | Status field |
| replenishment_suggestions | purchase_request_id | app/Models/ReplenishmentSuggestion.php:35<br>app/Services/Replenishment/ReplenishmentService.php:154 | OK | Purchase request foreign key |
| replenishment_suggestions | production_order_id | app/Models/ReplenishmentSuggestion.php:36<br>app/Services/Replenishment/ReplenishmentService.php:155 | OK | Production order foreign key |
| replenishment_suggestions | sugerido_en | app/Models/ReplenishmentSuggestion.php:37<br>app/Services/Replenishment/ReplenishmentService.php:152 | OK | Suggested at |
| replenishment_suggestions | revisado_en | app/Models/ReplenishmentSuggestion.php:38<br>app/Services/Replenishment/ReplenishmentService.php:156 | OK | Reviewed at |
| replenishment_suggestions | revisado_por | app/Models/ReplenishmentSuggestion.php:39<br>app/Services/Replenishment/ReplenishmentService.php:157 | OK | Reviewed by |
| replenishment_suggestions | convertido_en | app/Models/ReplenishmentSuggestion.php:40<br>app/Services/Replenishment/ReplenishmentService.php:158 | OK | Converted at |
| replenishment_suggestions | caduca_en | app/Models/ReplenishmentSuggestion.php:41<br>app/Services/Replenishment/ReplenishmentService.php:159 | OK | Expires at |
| replenishment_suggestions | motivo | app/Models/ReplenishmentSuggestion.php:42<br>app/Services/Replenishment/ReplenishmentService.php:160 | OK | Reason |
| replenishment_suggestions | motivo_rechazo | app/Models/ReplenishmentSuggestion.php:43<br>app/Services/Replenishment/ReplenishmentService.php:161 | OK | Rejection reason |
| replenishment_suggestions | notas | app/Models/ReplenishmentSuggestion.php:44<br>app/Services/Replenishment/ReplenishmentService.php:162 | OK | Notes |
| replenishment_suggestions | meta | app/Models/ReplenishmentSuggestion.php:45<br>app/Services/Replenishment/ReplenishmentService.php:163 | OK | Metadata |
| replenishment_suggestions | created_at | app/Models/ReplenishmentSuggestion.php:46<br>app/Services/Replenishment/ReplenishmentService.php:164 | OK | Created timestamp |
| replenishment_suggestions | updated_at | app/Models/ReplenishmentSuggestion.php:47<br>app/Services/Replenishment/ReplenishmentService.php:165 | OK | Updated timestamp |

## 4. TOP problemas críticos

1. **op_cab, op_insumo, op_yield, prod_cab, prod_det, sol_prod_cab, sol_prod_det** - Tablas de producción que existen en la BD pero no están siendo usadas en el código actual
2. **merma** - Tabla de mermas que existe en la BD pero no está siendo usada en el código actual
3. **purchase_suggestions** - Campos importantes como total_items y total_estimado están marcados como NO_USADO
4. **purchase_suggestion_lines** - Todos los campos de esta tabla importante están marcados como NO_USADO
5. **cat_proveedores** - Muchos campos importantes (tipo_comprobante, uso_cfdi, regimen_fiscal, etc.) no están siendo usados en el código
6. **reorder_ en código vs reorder_lote en BD** - Inconsistencia en nomenclatura para campos de reorder
7. **proveedor vs vendor** - Inconsistencia en nomenclatura entre código y base de datos
8. **qty vs cantidad** - Inconsistencia en nomenclatura para campos de cantidad
9. **fecha vs date** - Inconsistencia en nomenclatura para campos de fecha
10. **status vs estado** - Inconsistencia en nomenclatura para campos de estado
11. **id vs _id postfix** - Inconsistencia en nomenclatura para campos de foreign key
12. **Campos FANTASMA en procesos críticos** - Se esperan campos en el código que no existen en la BD

## 5. Recomendaciones por módulo

### Producción:
- Revisar las tablas op_cab, op_insumo, op_yield, prod_cab, prod_det, sol_prod_cab, sol_prod_det ya que existen en la BD pero no están siendo referenciadas en el código
- Asegurar que los servicios de producción usen las tablas correctas según el análisis
- Verificar que el modelo de merma esté correctamente implementado o eliminar la tabla si no se usa
- Implementar los campos faltantes en la lógica de mermas

### Purchasing:
- Implementar el uso de los campos faltantes en purchase_suggestions y purchase_suggestion_lines
- Asegurar consistencia en la nomenclatura de campos entre código y base de datos
- Verificar que todos los campos de proveedores estén siendo usados adecuadamente
- Completar la implementación del flujo completo de suggestions si es necesario
- Asegurar que los procesos de cotización estén completamente implementados