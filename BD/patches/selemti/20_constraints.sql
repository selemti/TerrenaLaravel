-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql
BEGIN;
SET search_path = selemti, public;
ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_pkey PRIMARY KEY (id);


ALTER TABLE ONLY auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_pkey PRIMARY KEY (id);


ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_codigo_key UNIQUE (sucursal_id, codigo);


ALTER TABLE ONLY cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


ALTER TABLE ONLY cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_pkey PRIMARY KEY (id);


ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_pkey PRIMARY KEY (id);


ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_key UNIQUE (postcorte_id);


ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_pkey PRIMARY KEY (id);


ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_unidad_destino_id_key UNIQUE (unidad_origen_id, unidad_destino_id);


ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_pkey PRIMARY KEY (id);


ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


ALTER TABLE ONLY formas_pago
    ADD CONSTRAINT formas_pago_pkey PRIMARY KEY (id);


ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_pkey PRIMARY KEY (id);


ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_pkey PRIMARY KEY (id);


ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fecha_efectiva_version_datos_key UNIQUE (item_id, fecha_efectiva, version_datos);


ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_pkey PRIMARY KEY (id);


ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_pkey PRIMARY KEY (id);


ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_pkey PRIMARY KEY (id);


ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_pkey PRIMARY KEY (id);


ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_sku_key UNIQUE (sku);


ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_pkey PRIMARY KEY (id);


ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_pkey PRIMARY KEY (item_id, vendor_id, presentacion);


ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


ALTER TABLE ONLY job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


ALTER TABLE ONLY job_recalc_queue
    ADD CONSTRAINT job_recalc_queue_pkey PRIMARY KEY (id);


ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);


ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_pkey PRIMARY KEY (id);


ALTER TABLE ONLY migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_codigo_pos_key UNIQUE (codigo_pos);


ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_pkey PRIMARY KEY (id);


ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_pkey PRIMARY KEY (id);


ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_pkey PRIMARY KEY (id);


ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_pkey PRIMARY KEY (id);


ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_pkey PRIMARY KEY (id);


ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_pkey PRIMARY KEY (op_id);


ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_pkey PRIMARY KEY (id);


ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_sucursal_id_key UNIQUE (sucursal_id);


ALTER TABLE ONLY password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_pkey PRIMARY KEY (id);


ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


ALTER TABLE ONLY pos_map
    ADD CONSTRAINT pos_map_pkey PRIMARY KEY (pos_system, plu, valid_from, sys_from);


ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_pkey PRIMARY KEY (id);


ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_pkey PRIMARY KEY (id);


ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_pkey PRIMARY KEY (id);


ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_pkey PRIMARY KEY (id);


ALTER TABLE ONLY proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_pkey PRIMARY KEY (id);


ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_pkey PRIMARY KEY (id);


ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_pkey PRIMARY KEY (id);


ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_codigo_plato_pos_key UNIQUE (codigo_plato_pos);


ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_pkey PRIMARY KEY (id);


ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_codigo_key UNIQUE (codigo);


ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_pkey PRIMARY KEY (id);


ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_pkey PRIMARY KEY (id);


ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_insumo_id_key UNIQUE (receta_version_id, insumo_id);


ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


ALTER TABLE ONLY receta_shadow
    ADD CONSTRAINT receta_shadow_pkey PRIMARY KEY (id);


ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_pkey PRIMARY KEY (id);


ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_version_key UNIQUE (receta_id, version);


ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_pkey PRIMARY KEY (id);


ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key UNIQUE (terminal_id, cajero_usuario_id, apertura_ts);


ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_pkey PRIMARY KEY (id);


ALTER TABLE ONLY sucursal_almacen_terminal
    ADD CONSTRAINT sucursal_almacen_terminal_pkey PRIMARY KEY (id);


ALTER TABLE ONLY sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id);


ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_pkey PRIMARY KEY (id);


ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_numero_ticket_key UNIQUE (numero_ticket);


ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_pkey PRIMARY KEY (id);


ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_pkey PRIMARY KEY (id);


ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_pkey PRIMARY KEY (id);


ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_pkey PRIMARY KEY (id);


ALTER TABLE ONLY unidad_medida
    ADD CONSTRAINT unidad_medida_codigo_key UNIQUE (codigo);


ALTER TABLE ONLY unidad_medida
    ADD CONSTRAINT unidad_medida_pkey PRIMARY KEY (id);


ALTER TABLE ONLY unidades_medida
    ADD CONSTRAINT unidades_medida_codigo_key UNIQUE (codigo);


ALTER TABLE ONLY unidades_medida
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id);


ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_origen_id_destino_id_key UNIQUE (origen_id, destino_id);


ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_pkey PRIMARY KEY (id);


ALTER TABLE ONLY postcorte
    ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);


ALTER TABLE ONLY precorte
    ADD CONSTRAINT uq_precorte_sesion_id UNIQUE (sesion_id);


ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


SET search_path = public, pg_catalog;

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES postcorte(id) ON DELETE CASCADE;


ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_destino_id_fkey FOREIGN KEY (unidad_destino_id) REFERENCES unidades_medida(id);


ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_fkey FOREIGN KEY (unidad_origen_id) REFERENCES unidades_medida(id);


ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT fk_ticket_det_cab FOREIGN KEY (ticket_id) REFERENCES ticket_venta_cab(id) ON DELETE CASCADE;


ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_um_compra_id_fkey FOREIGN KEY (um_compra_id) REFERENCES unidad_medida(id);


ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_unidad_presentacion_id_fkey FOREIGN KEY (unidad_presentacion_id) REFERENCES unidades_medida(id);


ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_compra_id_fkey FOREIGN KEY (unidad_compra_id) REFERENCES unidades_medida(id);


ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_medida_id_fkey FOREIGN KEY (unidad_medida_id) REFERENCES unidades_medida(id);


ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_salida_id_fkey FOREIGN KEY (unidad_salida_id) REFERENCES unidades_medida(id);


ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_receta_modificador_id_fkey FOREIGN KEY (receta_modificador_id) REFERENCES receta_cab(id);


ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_um_salida_id_fkey FOREIGN KEY (um_salida_id) REFERENCES unidad_medida(id);


ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_usuario_abre_fkey FOREIGN KEY (usuario_abre) REFERENCES usuario(id);


ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_usuario_cierra_fkey FOREIGN KEY (usuario_cierra) REFERENCES usuario(id);


ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida(id);


ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_job_id_fkey FOREIGN KEY (job_id) REFERENCES job_recalc_queue(id);


ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_bodega_id_fkey FOREIGN KEY (bodega_id) REFERENCES bodega(id);


ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_recepcion_id_fkey FOREIGN KEY (recepcion_id) REFERENCES recepcion_cab(id) ON DELETE CASCADE;


ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES receta_cab(id);


ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida(id);


ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_shadow_id_fkey FOREIGN KEY (receta_shadow_id) REFERENCES receta_shadow(id);


ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_from_bodega_id_fkey FOREIGN KEY (from_bodega_id) REFERENCES bodega(id);


ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_to_bodega_id_fkey FOREIGN KEY (to_bodega_id) REFERENCES bodega(id);


ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_traspaso_id_fkey FOREIGN KEY (traspaso_id) REFERENCES traspaso_cab(id) ON DELETE CASCADE;


ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_destino_id_fkey FOREIGN KEY (destino_id) REFERENCES unidad_medida(id);


ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_origen_id_fkey FOREIGN KEY (origen_id) REFERENCES unidad_medida(id);


ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES rol(id);


COMMIT;
