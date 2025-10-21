-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql
BEGIN;
SET search_path = selemti, public;
CREATE INDEX idx_historial_costos_item_fecha ON historial_costos_item USING btree (item_id, fecha_efectiva DESC);


CREATE INDEX idx_inventory_batch_caducidad ON inventory_batch USING btree (fecha_caducidad);


CREATE INDEX idx_inventory_batch_item ON inventory_batch USING btree (item_id);


CREATE INDEX idx_mov_inv_item_ts ON mov_inv USING btree (item_id, ts);


CREATE INDEX idx_mov_inv_tipo_fecha ON mov_inv USING btree (tipo, ts);


CREATE INDEX idx_perdida_item_ts ON perdida_log USING btree (item_id, ts DESC);


CREATE INDEX idx_postcorte_sesion_id ON postcorte USING btree (sesion_id);


CREATE INDEX idx_precorte_efectivo_precorte_id ON precorte_efectivo USING btree (precorte_id);


CREATE INDEX idx_precorte_otros_precorte_id ON precorte_otros USING btree (precorte_id);


CREATE INDEX idx_receta_version_publicada ON receta_version USING btree (version_publicada);


CREATE INDEX idx_sesion_cajon_terminal_apertura ON sesion_cajon USING btree (terminal_id, apertura_ts);


CREATE INDEX idx_stock_policy_item_suc ON stock_policy USING btree (item_id, sucursal_id);


CREATE UNIQUE INDEX idx_stock_policy_unique ON stock_policy USING btree (item_id, sucursal_id, (COALESCE(almacen_id, '_'::text)));


CREATE UNIQUE INDEX idx_suc_alm_term_unique ON sucursal_almacen_terminal USING btree (sucursal_id, almacen_id, (COALESCE(terminal_id, 0)));


CREATE UNIQUE INDEX idx_tick_cons_unique ON ticket_det_consumo USING btree (ticket_det_id, item_id, lote_id, qty_canonica, (COALESCE(uom_original_id, 0)));


CREATE INDEX idx_tickcons_lote ON ticket_det_consumo USING btree (item_id, lote_id);


CREATE INDEX idx_tickcons_ticket ON ticket_det_consumo USING btree (ticket_id, ticket_det_id);


CREATE INDEX idx_ticket_venta_fecha ON ticket_venta_cab USING btree (fecha_venta);


CREATE INDEX ix_fp_codigo ON formas_pago USING btree (codigo);


CREATE INDEX ix_hist_cost_insumo ON hist_cost_insumo USING btree (insumo_id, fecha_efectiva DESC);


CREATE INDEX ix_hist_cost_receta ON hist_cost_receta USING btree (receta_version_id, fecha_calculo);


CREATE INDEX ix_ib_item_caduc ON inventory_batch USING btree (item_id, fecha_caducidad);


CREATE INDEX ix_layer_item ON cost_layer USING btree (item_id, ts_in);


CREATE INDEX ix_layer_item_suc ON cost_layer USING btree (item_id, sucursal_id);


CREATE INDEX ix_lote_cad ON lote USING btree (caducidad);


CREATE INDEX ix_lote_insumo ON lote USING btree (insumo_id);


CREATE INDEX ix_mov_item_id ON mov_inv USING btree (item_id);


CREATE INDEX ix_mov_item_ts ON mov_inv USING btree (item_id, ts DESC);


CREATE INDEX ix_mov_ref ON mov_inv USING btree (ref_tipo, ref_id);


CREATE INDEX ix_mov_sucursal ON mov_inv USING btree (sucursal_id);


CREATE INDEX ix_mov_tipo ON mov_inv USING btree (tipo);


CREATE INDEX ix_mov_ts ON mov_inv USING btree (ts);


CREATE INDEX ix_pm_plu ON pos_map USING btree (plu);


CREATE INDEX ix_pos_map_plu ON pos_map USING btree (pos_system, plu, vigente_desde);


CREATE INDEX ix_ri_insumo ON receta_insumo USING btree (insumo_id);


CREATE INDEX ix_ri_rv ON receta_insumo USING btree (receta_version_id);


CREATE INDEX ix_rv_id ON receta_version USING btree (id);


CREATE INDEX ix_sp_item_suc ON stock_policy USING btree (item_id, sucursal_id);


CREATE INDEX jobs_queue_index ON jobs USING btree (queue);


CREATE INDEX model_has_permissions_model_id_model_type_index ON model_has_permissions USING btree (model_id, model_type);


CREATE INDEX model_has_roles_model_id_model_type_index ON model_has_roles USING btree (model_id, model_type);


CREATE INDEX sessions_last_activity_index ON sessions USING btree (last_activity);


CREATE INDEX sessions_user_id_index ON sessions USING btree (user_id);


CREATE UNIQUE INDEX ux_hist_cost_insumo ON hist_cost_insumo USING btree (insumo_id, fecha_efectiva, (COALESCE(valid_to, '9999-12-31'::date)));


SET search_path = public, pg_catalog;

COMMIT;
