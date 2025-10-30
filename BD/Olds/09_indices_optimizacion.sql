-- =====================================================
-- SCRIPT 09: ÍNDICES DE OPTIMIZACIÓN
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- ÍNDICES PARA MÓDULO INVENTARIO
CREATE INDEX idx_mov_inv_item_fecha ON selemti.mov_inv(item_id, fecha_movimiento);
CREATE INDEX idx_mov_inv_referencia ON selemti.mov_inv(referencia_tipo, referencia_id);
CREATE INDEX idx_mov_inv_batch ON selemti.mov_inv(inventory_batch_id);
CREATE INDEX idx_mov_inv_tipo_fecha ON selemti.mov_inv(tipo_movimiento, fecha_movimiento);
CREATE INDEX idx_mov_inv_salidas ON selemti.mov_inv(item_id, fecha_movimiento) WHERE tipo_movimiento = 'S';

CREATE INDEX idx_inventory_batch_item ON selemti.inventory_batch(item_id);
CREATE INDEX idx_inventory_batch_caducidad ON selemti.inventory_batch(fecha_caducidad);
CREATE INDEX idx_inventory_batch_estado ON selemti.inventory_batch(estado);
CREATE INDEX idx_inventory_batch_item_estado_caducidad ON selemti.inventory_batch(item_id, estado, fecha_caducidad);

CREATE INDEX idx_recepcion_det_lote ON selemti.recepcion_det(lote_proveedor, fecha_caducidad);
CREATE INDEX idx_recepcion_det_item ON selemti.recepcion_det(item_id);
CREATE INDEX idx_recepcion_det_recepcion ON selemti.recepcion_det(recepcion_id);

-- ÍNDICES PARA MÓDULO RECETAS
CREATE INDEX idx_receta_det_item ON selemti.receta_det(item_id);
CREATE INDEX idx_receta_det_orden ON selemti.receta_det(receta_id, orden_mezcla);

CREATE INDEX idx_op_produccion_receta ON selemti.op_produccion_cab(receta_id);
CREATE INDEX idx_op_produccion_fecha ON selemti.op_produccion_cab(fecha_produccion);
CREATE INDEX idx_op_produccion_estado ON selemti.op_produccion_cab(estado);

CREATE INDEX idx_op_det_op ON selemti.op_produccion_det(op_id);
CREATE INDEX idx_op_det_item ON selemti.op_produccion_det(item_id);
CREATE INDEX idx_op_det_batch ON selemti.op_produccion_det(inventory_batch_id);

-- ÍNDICES PARA MÓDULO VENTAS/KDS
CREATE INDEX idx_ticket_cab_fecha ON selemti.ticket_venta_cab(fecha_venta);
CREATE INDEX idx_ticket_cab_sucursal ON selemti.ticket_venta_cab(sucursal_id);
CREATE INDEX idx_ticket_cab_estado ON selemti.ticket_venta_cab(estado_ticket);
CREATE INDEX idx_ticket_cab_pos_id ON selemti.ticket_venta_cab(ticket_id_pos);

CREATE INDEX idx_ticket_det_ticket ON selemti.ticket_venta_det(ticket_id);
CREATE INDEX idx_ticket_det_item ON selemti.ticket_venta_det(item_id);
CREATE INDEX idx_ticket_det_estado ON selemti.ticket_venta_det(estado_item);
CREATE INDEX idx_ticket_det_estacion ON selemti.ticket_venta_det(estacion_asignada);

CREATE INDEX idx_kds_ordenes_estacion ON selemti.kds_ordenes(estacion_trabajo, estado_orden);
CREATE INDEX idx_kds_ordenes_estado ON selemti.kds_ordenes(estado_orden);
CREATE INDEX idx_kds_ordenes_ticket ON selemti.kds_ordenes(ticket_det_id);
CREATE INDEX idx_kds_ordenes_tiempo ON selemti.kds_ordenes(estacion_trabajo, orden_en_cola);

-- ÍNDICES PARA MÓDULO CAJA
CREATE INDEX idx_caja_movimientos_caja ON selemti.caja_movimientos(caja_id, fecha_movimiento);
CREATE INDEX idx_caja_movimientos_tipo ON selemti.caja_movimientos(tipo_movimiento);
CREATE INDEX idx_caja_movimientos_usuario ON selemti.caja_movimientos(usuario_id);

CREATE INDEX idx_caja_cierres_fecha ON selemti.caja_cierres(fecha_cierre);
CREATE INDEX idx_caja_cierres_usuario ON selemti.caja_cierres(usuario_cajero);
CREATE INDEX idx_caja_cierres_estado ON selemti.caja_cierres(estado_cierre);

-- ÍNDICES PARA MÓDULO APPCC
CREATE INDEX idx_appcc_registros_fecha ON selemti.appcc_registros(fecha_registro);
CREATE INDEX idx_appcc_registros_punto ON selemti.appcc_registros(punto_control_id);
CREATE INDEX idx_appcc_registros_cumple ON selemti.appcc_registros(cumple_limite);

CREATE INDEX idx_appcc_alertas_fecha ON selemti.appcc_alertas(fecha_alerta);
CREATE INDEX idx_appcc_alertas_estado ON selemti.appcc_alertas(estado_alerta);
CREATE INDEX idx_appcc_alertas_gravedad ON selemti.appcc_alertas(gravedad);

-- ÍNDICES PARA AUDITORÍA
CREATE INDEX idx_audit_log_timestamp ON selemti.audit_log(timestamp);
CREATE INDEX idx_audit_log_user_action ON selemti.audit_log(user_id, action_type);
CREATE INDEX idx_audit_log_table_record ON selemti.audit_log(table_name, record_id);

-- ÍNDICES PARA BÚSQUEDA DE TEXTO
CREATE INDEX idx_items_nombre_trgm ON selemti.items USING gin (nombre gin_trgm_ops);
CREATE INDEX idx_receta_cab_nombre ON selemti.receta_cab USING gin (nombre_plato gin_trgm_ops);

-- VISTAS PARA CONSULTAS FRECUENTES
CREATE OR REPLACE VIEW selemti.v_stock_actual AS
SELECT 
    item_id,
    ubicacion_id,
    SUM(CASE WHEN tipo_movimiento = 'E' THEN cantidad ELSE -cantidad END) as stock_actual
FROM selemti.mov_inv
GROUP BY item_id, ubicacion_id;

CREATE OR REPLACE VIEW selemti.v_stock_por_lote_fefo AS
SELECT 
    b.item_id,
    b.id as batch_id,
    b.lote_proveedor,
    b.fecha_caducidad,
    b.ubicacion_id,
    b.cantidad_actual as stock_lote,
    b.estado
FROM selemti.inventory_batch b
WHERE b.estado = 'ACTIVO' 
AND b.cantidad_actual > 0
ORDER BY b.fecha_caducidad ASC;

RAISE NOTICE 'Script 09 (Índices de optimización) ejecutado exitosamente';
RAISE NOTICE '✅ ESQUEMA SELETI COMPLETADO - 30 TABLAS CREADAS';