-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql
BEGIN;
SET search_path = selemti, public;
ALTER SEQUENCE bodega_id_seq OWNED BY bodega.id;


ALTER SEQUENCE cat_unidades_id_seq OWNED BY cat_unidades.id;


ALTER SEQUENCE conciliacion_id_seq OWNED BY conciliacion.id;


ALTER SEQUENCE conversiones_unidad_id_seq OWNED BY conversiones_unidad.id;


ALTER SEQUENCE cost_layer_id_seq OWNED BY cost_layer.id;


ALTER SEQUENCE failed_jobs_id_seq OWNED BY failed_jobs.id;


ALTER SEQUENCE hist_cost_insumo_id_seq OWNED BY hist_cost_insumo.id;


ALTER SEQUENCE hist_cost_receta_id_seq OWNED BY hist_cost_receta.id;


ALTER SEQUENCE historial_costos_item_id_seq OWNED BY historial_costos_item.id;


ALTER SEQUENCE historial_costos_receta_id_seq OWNED BY historial_costos_receta.id;


ALTER SEQUENCE insumo_id_seq OWNED BY insumo.id;


ALTER SEQUENCE insumo_presentacion_id_seq OWNED BY insumo_presentacion.id;


ALTER SEQUENCE inventory_batch_id_seq OWNED BY inventory_batch.id;


ALTER SEQUENCE job_recalc_queue_id_seq OWNED BY job_recalc_queue.id;


ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


ALTER SEQUENCE lote_id_seq OWNED BY lote.id;


ALTER SEQUENCE merma_id_seq OWNED BY merma.id;


ALTER SEQUENCE migrations_id_seq OWNED BY migrations.id;


ALTER SEQUENCE modificadores_pos_id_seq OWNED BY modificadores_pos.id;


ALTER SEQUENCE mov_inv_id_seq OWNED BY mov_inv.id;


ALTER SEQUENCE op_cab_id_seq OWNED BY op_cab.id;


ALTER SEQUENCE op_insumo_id_seq OWNED BY op_insumo.id;


ALTER SEQUENCE op_produccion_cab_id_seq OWNED BY op_produccion_cab.id;


ALTER SEQUENCE param_sucursal_id_seq OWNED BY param_sucursal.id;


ALTER SEQUENCE perdida_log_id_seq OWNED BY perdida_log.id;


ALTER SEQUENCE permissions_id_seq OWNED BY permissions.id;


ALTER SEQUENCE recalc_log_id_seq OWNED BY recalc_log.id;


ALTER SEQUENCE recepcion_cab_id_seq OWNED BY recepcion_cab.id;


ALTER SEQUENCE recepcion_det_id_seq OWNED BY recepcion_det.id;


ALTER SEQUENCE receta_det_id_seq OWNED BY receta_det.id;


ALTER SEQUENCE receta_id_seq OWNED BY receta.id;


ALTER SEQUENCE receta_insumo_id_seq OWNED BY receta_insumo.id;


ALTER SEQUENCE receta_shadow_id_seq OWNED BY receta_shadow.id;


ALTER SEQUENCE receta_version_id_seq OWNED BY receta_version.id;


ALTER SEQUENCE rol_id_seq OWNED BY rol.id;


ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


ALTER SEQUENCE stock_policy_id_seq OWNED BY stock_policy.id;


ALTER SEQUENCE sucursal_almacen_terminal_id_seq OWNED BY sucursal_almacen_terminal.id;


ALTER SEQUENCE ticket_det_consumo_id_seq OWNED BY ticket_det_consumo.id;


ALTER SEQUENCE ticket_venta_cab_id_seq OWNED BY ticket_venta_cab.id;


ALTER SEQUENCE ticket_venta_det_id_seq OWNED BY ticket_venta_det.id;


ALTER SEQUENCE traspaso_cab_id_seq OWNED BY traspaso_cab.id;


ALTER SEQUENCE traspaso_det_id_seq OWNED BY traspaso_det.id;


ALTER SEQUENCE unidad_medida_id_seq OWNED BY unidad_medida.id;


ALTER SEQUENCE unidades_medida_id_seq OWNED BY unidades_medida.id;


ALTER SEQUENCE uom_conversion_id_seq OWNED BY uom_conversion.id;


ALTER SEQUENCE users_id_seq OWNED BY users.id;


ALTER SEQUENCE usuario_id_seq OWNED BY usuario.id;


COMMIT;
