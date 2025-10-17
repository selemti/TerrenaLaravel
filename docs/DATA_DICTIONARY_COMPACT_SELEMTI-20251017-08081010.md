Data Dictionary (Compact) — selemti

Fecha: 2025-10-17 08:41

search_path sesión: selemti, public

## selemti.almacen — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: text, no
  - sucursal_id: text, no
  - nombre: text, no
  - activo: boolean, no
- FKs detalle
  - sucursal_id ? selemti.sucursal

## selemti.auditoria — ~ 8 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - quien: integer, yes
  - que: text, no
  - payload: jsonb, yes
  - creado_en: timestamp with time zone, no

## selemti.cache — ~ 0 filas

- Flags: sin_timestamps

- PK: key
- FKs: N/A
- Columnas (nombre: tipo, null)
  - key: character varying, no
  - value: text, no
  - expiration: integer, no

## selemti.cache_locks — ~ 0 filas

- Flags: sin_timestamps

- PK: key
- FKs: N/A
- Columnas (nombre: tipo, null)
  - key: character varying, no
  - owner: character varying, no
  - expiration: integer, no

## selemti.cat_unidades — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - created_at: timestamp without time zone, yes
  - updated_at: timestamp without time zone, yes

## selemti.conversiones_unidad — ~ 0 filas

- PK: id
- FKs: 2
- Columnas (nombre: tipo, null)
  - id: integer, no
  - unidad_origen_id: integer, no
  - unidad_destino_id: integer, no
  - factor_conversion: numeric, no
  - formula_directa: text, yes
  - precision_estimada: numeric, yes
  - activo: boolean, yes
  - created_at: timestamp without time zone, yes
- FKs detalle
  - unidad_destino_id ? selemti.unidades_medida
  - unidad_origen_id ? selemti.unidades_medida

## selemti.cost_layer — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 2
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - item_id: character varying, no
  - batch_id: bigint, yes
  - ts_in: timestamp without time zone, no
  - qty_in: numeric, no
  - qty_left: numeric, no
  - unit_cost: numeric, no
  - sucursal_id: character varying, yes
  - source_ref: text, yes
  - source_id: bigint, yes
- FKs detalle
  - item_id ? selemti.items
  - batch_id ? selemti.inventory_batch

## selemti.failed_jobs — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - uuid: character varying, no
  - connection: text, no
  - queue: text, no
  - payload: text, no
  - exception: text, no
  - failed_at: timestamp without time zone, no

## selemti.formas_pago — ~ 13 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - codigo: text, no
  - payment_type: text, yes
  - transaction_type: text, yes
  - payment_sub_type: text, yes
  - custom_name: text, yes
  - custom_ref: text, yes
  - activo: boolean, no
  - prioridad: integer, no
  - creado_en: timestamp with time zone, no

## selemti.historial_costos_item — ~ 0 filas

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - item_id: character varying, no
  - fecha_efectiva: date, no
  - fecha_registro: timestamp without time zone, yes
  - costo_anterior: numeric, yes
  - costo_nuevo: numeric, yes
  - tipo_cambio: character varying, yes
  - referencia_id: integer, yes
  - referencia_tipo: character varying, yes
  - usuario_id: integer, yes
  - valid_from: date, no
  - valid_to: date, yes
  - sys_from: timestamp without time zone, no
  - sys_to: timestamp without time zone, yes
  - costo_wac: numeric, yes
  - costo_peps: numeric, yes
  - costo_ueps: numeric, yes
  - costo_estandar: numeric, yes
  - algoritmo_principal: character varying, yes
  - version_datos: integer, yes
  - recalculado: boolean, yes
  - fuente_datos: character varying, yes
  - metadata_calculo: json, yes
  - created_at: timestamp without time zone, yes
- FKs detalle
  - item_id ? selemti.items

## selemti.historial_costos_receta — ~ 0 filas

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - receta_version_id: integer, no
  - fecha_calculo: date, no
  - costo_total: numeric, yes
  - costo_porcion: numeric, yes
  - algoritmo_utilizado: character varying, yes
  - version_datos: integer, yes
  - metadata_calculo: json, yes
  - created_at: timestamp without time zone, yes
  - valid_from: date, no
  - valid_to: date, yes
  - sys_from: timestamp without time zone, no
  - sys_to: timestamp without time zone, yes
- FKs detalle
  - receta_version_id ? selemti.receta_version

## selemti.inventory_batch — ~ 0 filas

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - item_id: character varying, no
  - lote_proveedor: character varying, no
  - fecha_recepcion: date, no
  - fecha_caducidad: date, no
  - temperatura_recepcion: numeric, yes
  - documento_url: character varying, yes
  - cantidad_original: numeric, no
  - cantidad_actual: numeric, no
  - estado: character varying, yes
  - ubicacion_id: character varying, no
  - created_at: timestamp without time zone, yes
  - updated_at: timestamp without time zone, yes
- FKs detalle
  - item_id ? selemti.items

## selemti.item_vendor — ~ 0 filas

- PK: item_id, vendor_id, presentacion
- FKs: 2
- Columnas (nombre: tipo, null)
  - item_id: text, no
  - vendor_id: text, no
  - presentacion: text, no
  - unidad_presentacion_id: integer, no
  - factor_a_canonica: numeric, no
  - costo_ultimo: numeric, no
  - moneda: text, no
  - lead_time_dias: integer, yes
  - codigo_proveedor: text, yes
  - activo: boolean, no
  - created_at: timestamp without time zone, no
- FKs detalle
  - item_id ? selemti.items
  - unidad_presentacion_id ? selemti.unidades_medida

## selemti.items — ~ 0 filas

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: character varying, no
  - nombre: character varying, no
  - descripcion: text, yes
  - categoria_id: character varying, no
  - unidad_medida: character varying, no
  - perishable: boolean, yes
  - temperatura_min: integer, yes
  - temperatura_max: integer, yes
  - costo_promedio: numeric, yes
  - activo: boolean, yes
  - created_at: timestamp without time zone, yes
  - updated_at: timestamp without time zone, yes
  - unidad_medida_id: integer, yes
  - factor_conversion: numeric, yes
  - unidad_compra_id: integer, yes
  - factor_compra: numeric, yes
  - tipo: USER-DEFINED, yes
  - unidad_salida_id: integer, yes
- FKs detalle
  - unidad_medida_id ? selemti.unidades_medida
  - unidad_compra_id ? selemti.unidades_medida
  - unidad_salida_id ? selemti.unidades_medida

## selemti.job_batches — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: character varying, no
  - name: character varying, no
  - total_jobs: integer, no
  - pending_jobs: integer, no
  - failed_jobs: integer, no
  - failed_job_ids: text, no
  - options: text, yes
  - cancelled_at: integer, yes
  - created_at: integer, no
  - finished_at: integer, yes

## selemti.job_recalc_queue — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - scope_type: text, no
  - scope_from: date, yes
  - scope_to: date, yes
  - item_id: character varying, yes
  - receta_id: character varying, yes
  - sucursal_id: character varying, yes
  - reason: text, yes
  - created_ts: timestamp without time zone, no
  - status: text, no
  - result: json, yes

## selemti.jobs — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - queue: character varying, no
  - payload: text, no
  - attempts: smallint, no
  - reserved_at: integer, yes
  - available_at: integer, no
  - created_at: integer, no

## selemti.migrations — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - migration: character varying, no
  - batch: integer, no

## selemti.model_has_permissions — ~ 0 filas

- Flags: sin_timestamps

- PK: permission_id, model_id, model_type
- FKs: 1
- Columnas (nombre: tipo, null)
  - permission_id: bigint, no
  - model_type: character varying, no
  - model_id: bigint, no
- FKs detalle
  - permission_id ? selemti.permissions

## selemti.model_has_roles — ~ 0 filas

- Flags: sin_timestamps

- PK: role_id, model_id, model_type
- FKs: 1
- Columnas (nombre: tipo, null)
  - role_id: bigint, no
  - model_type: character varying, no
  - model_id: bigint, no
- FKs detalle
  - role_id ? selemti.roles

## selemti.modificadores_pos — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - codigo_pos: character varying, no
  - nombre: character varying, no
  - tipo: character varying, yes
  - precio_extra: numeric, yes
  - receta_modificador_id: character varying, yes
  - activo: boolean, yes
- FKs detalle
  - receta_modificador_id ? selemti.receta_cab

## selemti.mov_inv — ~ 0 filas

- PK: id
- FKs: 2
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - ts: timestamp without time zone, no
  - item_id: character varying, no
  - lote_id: integer, yes
  - cantidad: numeric, no
  - qty_original: numeric, yes
  - uom_original_id: integer, yes
  - costo_unit: numeric, yes
  - tipo: character varying, no
  - ref_tipo: character varying, yes
  - ref_id: bigint, yes
  - sucursal_id: character varying, yes
  - usuario_id: integer, yes
  - created_at: timestamp without time zone, yes
- FKs detalle
  - item_id ? selemti.items
  - lote_id ? selemti.inventory_batch

## selemti.op_produccion_cab — ~ 0 filas

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - receta_version_id: integer, no
  - cantidad_planeada: numeric, no
  - cantidad_real: numeric, yes
  - fecha_produccion: date, no
  - estado: character varying, yes
  - lote_resultado: character varying, yes
  - usuario_responsable: integer, yes
  - created_at: timestamp without time zone, yes
  - updated_at: timestamp without time zone, yes
- FKs detalle
  - receta_version_id ? selemti.receta_version

## selemti.param_sucursal — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - sucursal_id: text, no
  - consumo: USER-DEFINED, no
  - tolerancia_precorte_pct: numeric, yes
  - tolerancia_corte_abs: numeric, yes
  - created_at: timestamp without time zone, no
  - updated_at: timestamp without time zone, no

## selemti.password_reset_tokens — ~ 0 filas

- PK: email
- FKs: N/A
- Columnas (nombre: tipo, null)
  - email: character varying, no
  - token: character varying, no
  - created_at: timestamp without time zone, yes

## selemti.perdida_log — ~ 0 filas

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - ts: timestamp without time zone, no
  - item_id: text, no
  - lote_id: bigint, yes
  - sucursal_id: text, yes
  - clase: USER-DEFINED, no
  - motivo: text, yes
  - qty_canonica: numeric, no
  - qty_original: numeric, yes
  - uom_original_id: integer, yes
  - evidencia_url: text, yes
  - usuario_id: integer, yes
  - ref_tipo: text, yes
  - ref_id: bigint, yes
  - created_at: timestamp without time zone, no
- FKs detalle
  - lote_id ? selemti.inventory_batch
  - uom_original_id ? selemti.unidades_medida
  - item_id ? selemti.items

## selemti.permissions — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - name: character varying, no
  - guard_name: character varying, no
  - created_at: timestamp without time zone, yes
  - updated_at: timestamp without time zone, yes

## selemti.pos_map — ~ 0 filas

- Flags: sin_timestamps

- PK: pos_system, plu, valid_from, sys_from
- FKs: N/A
- Columnas (nombre: tipo, null)
  - pos_system: text, no
  - plu: text, no
  - tipo: text, no
  - receta_id: text, yes
  - receta_version_id: integer, yes
  - valid_from: date, no
  - valid_to: date, yes
  - sys_from: timestamp without time zone, no
  - sys_to: timestamp without time zone, yes
  - meta: json, yes

## selemti.postcorte — ~ 4 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - sesion_id: bigint, no
  - sistema_efectivo_esperado: numeric, no
  - declarado_efectivo: numeric, no
  - diferencia_efectivo: numeric, no
  - veredicto_efectivo: text, no
  - sistema_tarjetas: numeric, no
  - declarado_tarjetas: numeric, no
  - diferencia_tarjetas: numeric, no
  - veredicto_tarjetas: text, no
  - creado_en: timestamp with time zone, no
  - creado_por: integer, yes
  - notas: text, yes
  - sistema_transferencias: numeric, no
  - declarado_transferencias: numeric, no
  - diferencia_transferencias: numeric, no
  - veredicto_transferencias: text, no
  - validado: boolean, no
  - validado_por: integer, yes
  - validado_en: timestamp with time zone, yes
- FKs detalle
  - sesion_id ? selemti.sesion_cajon

## selemti.precorte — ~ 4 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - sesion_id: bigint, no
  - declarado_efectivo: numeric, no
  - declarado_otros: numeric, no
  - estatus: text, no
  - creado_en: timestamp with time zone, no
  - creado_por: integer, yes
  - ip_cliente: inet, yes
  - notas: text, yes
- FKs detalle
  - sesion_id ? selemti.sesion_cajon

## selemti.precorte_efectivo — ~ 26 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - precorte_id: bigint, no
  - denominacion: numeric, no
  - cantidad: integer, no
  - subtotal: numeric, no
- FKs detalle
  - precorte_id ? selemti.precorte

## selemti.precorte_otros — ~ 8 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - precorte_id: bigint, no
  - tipo: text, no
  - monto: numeric, no
  - referencia: text, yes
  - evidencia_url: text, yes
  - notas: text, yes
  - creado_en: timestamp with time zone, no
- FKs detalle
  - precorte_id ? selemti.precorte

## selemti.proveedor — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: text, no
  - nombre: text, no
  - rfc: text, yes
  - activo: boolean, no

## selemti.recalc_log — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - job_id: bigint, yes
  - step: text, yes
  - started_ts: timestamp without time zone, yes
  - ended_ts: timestamp without time zone, yes
  - ok: boolean, yes
  - details: json, yes
- FKs detalle
  - job_id ? selemti.job_recalc_queue

## selemti.receta_cab — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: character varying, no
  - nombre_plato: character varying, no
  - codigo_plato_pos: character varying, yes
  - categoria_plato: character varying, yes
  - porciones_standard: integer, yes
  - instrucciones_preparacion: text, yes
  - tiempo_preparacion_min: integer, yes
  - costo_standard_porcion: numeric, yes
  - precio_venta_sugerido: numeric, yes
  - activo: boolean, yes
  - created_at: timestamp without time zone, yes
  - updated_at: timestamp without time zone, yes

## selemti.receta_det — ~ 0 filas

- PK: id
- FKs: 2
- Columnas (nombre: tipo, null)
  - id: integer, no
  - receta_version_id: integer, no
  - item_id: character varying, no
  - cantidad: numeric, no
  - unidad_medida: character varying, no
  - merma_porcentaje: numeric, yes
  - instrucciones_especificas: text, yes
  - orden: integer, yes
  - created_at: timestamp without time zone, yes
- FKs detalle
  - item_id ? selemti.items
  - receta_version_id ? selemti.receta_version

## selemti.receta_shadow — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - codigo_plato_pos: character varying, no
  - nombre_plato: character varying, no
  - estado: character varying, yes
  - confianza: numeric, yes
  - total_ventas_analizadas: integer, yes
  - fecha_primer_venta: date, yes
  - fecha_ultima_venta: date, yes
  - frecuencia_dias: numeric, yes
  - ingredientes_inferidos: json, yes
  - usuario_validador: integer, yes
  - fecha_validacion: timestamp without time zone, yes
  - created_at: timestamp without time zone, yes
  - updated_at: timestamp without time zone, yes

## selemti.receta_version — ~ 0 filas

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - receta_id: character varying, no
  - version: integer, no
  - descripcion_cambios: text, yes
  - fecha_efectiva: date, no
  - version_publicada: boolean, yes
  - usuario_publicador: integer, yes
  - fecha_publicacion: timestamp without time zone, yes
  - created_at: timestamp without time zone, yes
- FKs detalle
  - receta_id ? selemti.receta_cab

## selemti.role_has_permissions — ~ 0 filas

- Flags: sin_timestamps

- PK: permission_id, role_id
- FKs: 2
- Columnas (nombre: tipo, null)
  - permission_id: bigint, no
  - role_id: bigint, no
- FKs detalle
  - role_id ? selemti.roles
  - permission_id ? selemti.permissions

## selemti.roles — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - name: character varying, no
  - guard_name: character varying, no
  - created_at: timestamp without time zone, yes
  - updated_at: timestamp without time zone, yes

## selemti.sesion_cajon — ~ 8 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - sucursal: text, yes
  - terminal_id: integer, no
  - terminal_nombre: text, yes
  - cajero_usuario_id: integer, no
  - apertura_ts: timestamp with time zone, no
  - cierre_ts: timestamp with time zone, yes
  - estatus: text, no
  - opening_float: numeric, no
  - closing_float: numeric, yes
  - dah_evento_id: integer, yes
  - skipped_precorte: boolean, no

## selemti.sessions — ~ 3 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: character varying, no
  - user_id: bigint, yes
  - ip_address: character varying, yes
  - user_agent: text, yes
  - payload: text, no
  - last_activity: integer, no

## selemti.stock_policy — ~ 0 filas

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - item_id: text, no
  - sucursal_id: text, no
  - almacen_id: text, yes
  - min_qty: numeric, no
  - max_qty: numeric, no
  - reorder_lote: numeric, yes
  - activo: boolean, no
  - created_at: timestamp without time zone, no
- FKs detalle
  - item_id ? selemti.items

## selemti.sucursal — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: text, no
  - nombre: text, no
  - activo: boolean, no

## selemti.sucursal_almacen_terminal — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - sucursal_id: text, no
  - almacen_id: text, no
  - terminal_id: integer, yes
  - location: text, yes
  - descripcion: text, yes
  - activo: boolean, no
  - created_at: timestamp without time zone, no

## selemti.ticket_det_consumo — ~ 0 filas

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - ticket_id: bigint, no
  - ticket_det_id: bigint, no
  - item_id: text, no
  - lote_id: bigint, yes
  - qty_canonica: numeric, no
  - qty_original: numeric, yes
  - uom_original_id: integer, yes
  - sucursal_id: text, yes
  - ref_tipo: text, yes
  - ref_id: bigint, yes
  - created_at: timestamp without time zone, no
- FKs detalle
  - uom_original_id ? selemti.unidades_medida
  - item_id ? selemti.items
  - lote_id ? selemti.inventory_batch

## selemti.ticket_venta_cab — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - numero_ticket: character varying, no
  - fecha_venta: timestamp without time zone, no
  - sucursal_id: character varying, no
  - terminal_id: integer, yes
  - total_venta: numeric, yes
  - estado: character varying, yes
  - created_at: timestamp without time zone, yes

## selemti.ticket_venta_det — ~ 0 filas

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: bigint, no
  - ticket_id: bigint, no
  - item_id: character varying, no
  - cantidad: numeric, no
  - precio_unitario: numeric, no
  - subtotal: numeric, no
  - receta_version_id: integer, yes
  - created_at: timestamp without time zone, yes
  - receta_shadow_id: integer, yes
  - reprocesado: boolean, yes
  - version_reproceso: integer, yes
  - modificadores_aplicados: json, yes
- FKs detalle
  - receta_version_id ? selemti.receta_version
  - ticket_id ? selemti.ticket_venta_cab
  - receta_shadow_id ? selemti.receta_shadow

## selemti.unidades_medida — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - codigo: character varying, no
  - nombre: character varying, no
  - tipo: character varying, no
  - categoria: character varying, yes
  - es_base: boolean, yes
  - factor_conversion_base: numeric, yes
  - decimales: integer, yes
  - created_at: timestamp without time zone, yes

## selemti.user_roles — ~ 0 filas

- Flags: sin_timestamps

- PK: user_id, role_id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - user_id: integer, no
  - role_id: character varying, no
  - assigned_at: timestamp without time zone, yes
  - assigned_by: integer, yes

## selemti.users — ~ 0 filas

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - username: character varying, no
  - password_hash: character varying, no
  - email: character varying, yes
  - nombre_completo: character varying, no
  - sucursal_id: character varying, yes
  - activo: boolean, yes
  - fecha_ultimo_login: timestamp without time zone, yes
  - intentos_login: integer, yes
  - bloqueado_hasta: timestamp without time zone, yes
  - created_at: timestamp without time zone, yes
  - updated_at: timestamp without time zone, yes

## selemti.v_ingenieria_menu_completa — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - receta_id: character varying, yes
  - nombre_plato: character varying, yes
  - codigo_plato_pos: character varying, yes
  - precio_venta_sugerido: numeric, yes
  - costo_actual: numeric, yes
  - margen_actual: numeric, yes
  - porcentaje_margen: numeric, yes
  - alerta_costo_alto: boolean, yes
  - alerta_sin_ventas: boolean, yes

## selemti.v_items_con_uom — ~ 0 filas

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: character varying, yes
  - nombre: character varying, yes
  - descripcion: text, yes
  - categoria_id: character varying, yes
  - unidad_medida: character varying, yes
  - perishable: boolean, yes
  - temperatura_min: integer, yes
  - temperatura_max: integer, yes
  - costo_promedio: numeric, yes
  - activo: boolean, yes
  - created_at: timestamp without time zone, yes
  - updated_at: timestamp without time zone, yes
  - unidad_medida_id: integer, yes
  - factor_conversion: numeric, yes
  - unidad_compra_id: integer, yes
  - factor_compra: numeric, yes
  - tipo: USER-DEFINED, yes
  - unidad_salida_id: integer, yes
  - uom_codigo: character varying, yes
  - uom_nombre: character varying, yes
  - uom_tipo: character varying, yes

## selemti.v_merma_por_item — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - item_id: character varying, yes
  - semana: date, yes
  - qty_mermada: numeric, yes
  - qty_recibida: numeric, yes
  - merma_pct: numeric, yes

## selemti.v_stock_actual — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - item_id: character varying, yes
  - nombre: character varying, yes
  - stock_actual: numeric, yes

## selemti.v_stock_brechas — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - sucursal_id: text, yes
  - almacen_id: text, yes
  - item_id: text, yes
  - min_qty: numeric, yes
  - max_qty: numeric, yes
  - stock_actual: numeric, yes
  - qty_a_comprar: numeric, yes

## selemti.vw_anulaciones_por_terminal_dia — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - terminal_id: integer, yes
  - fecha: date, yes
  - anulaciones_total: numeric, yes

## selemti.vw_conciliacion_efectivo — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - sesion_id: bigint, yes
  - opening_float: numeric, yes
  - cash_in: numeric, yes
  - cash_out: numeric, yes
  - cash_refund: numeric, yes
  - sistema_efectivo_esperado: numeric, yes
  - declarado_efectivo: numeric, yes
  - diferencia_efectivo: numeric, yes

## selemti.vw_conciliacion_sesion — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - sesion_id: bigint, yes
  - sistema_efectivo_esperado: numeric, yes
  - declarado_efectivo: numeric, yes
  - diferencia_efectivo: numeric, yes
  - veredicto_efectivo: text, yes
  - sys_credito: numeric, yes
  - sys_debito: numeric, yes
  - sys_transfer: numeric, yes
  - sys_custom: numeric, yes
  - sys_gift: numeric, yes
  - decl_credito: numeric, yes
  - decl_debito: numeric, yes
  - decl_transfer: numeric, yes
  - decl_custom: numeric, yes
  - decl_gift: numeric, yes
  - sistema_no_efectivo: numeric, yes
  - total_descuentos: numeric, yes
  - begin_cash: double precision, yes
  - cash_receipt_amount: double precision, yes
  - credit_card_receipt_amount: double precision, yes
  - debit_card_receipt_amount: double precision, yes
  - pay_out_amount: double precision, yes
  - drawer_bleed_amount: double precision, yes
  - refund_amount: double precision, yes
  - totaldiscountamount: double precision, yes
  - totalvoid: double precision, yes
  - drawer_accountable: double precision, yes
  - cash_to_deposit: double precision, yes
  - variance: double precision, yes
  - report_time: timestamp without time zone, yes
  - sys_cash: numeric, yes
  - sys_total_tarjetas: numeric, yes
  - decl_total_tarjetas: numeric, yes
  - diferencia_tarjetas: numeric, yes

## selemti.vw_conciliacion_tarjetas — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - sesion_id: bigint, yes
  - sys_credito: numeric, yes
  - sys_debito: numeric, yes
  - sys_transfer: numeric, yes
  - sys_custom: numeric, yes
  - sys_gift: numeric, yes
  - sys_total_tarjetas: numeric, yes
  - decl_credito: numeric, yes
  - decl_debito: numeric, yes
  - decl_transfer: numeric, yes
  - decl_custom: numeric, yes
  - decl_gift: numeric, yes
  - decl_total_tarjetas: numeric, yes
  - diferencia_tarjetas: numeric, yes

## selemti.vw_descuentos_por_terminal_dia — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - terminal_id: integer, yes
  - fecha: date, yes
  - descuentos_ticket: numeric, yes
  - descuentos_items: numeric, yes
  - descuentos_100: numeric, yes
  - descuentos_parciales: numeric, yes
  - total_descuentos: numeric, yes

## selemti.vw_fast_tickets — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, yes
  - terminal_id: integer, yes
  - owner_id: integer, yes
  - create_date: timestamp without time zone, yes
  - closing_date: timestamp without time zone, yes
  - status: character varying, yes
  - total_discount: double precision, yes
  - total_price: double precision, yes

## selemti.vw_fast_tx — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - terminal_id: integer, yes
  - user_id: integer, yes
  - transaction_time: timestamp without time zone, yes
  - payment_type: character varying, yes
  - transaction_type: character varying, yes
  - payment_sub_type: character varying, yes
  - custom_payment_name: character varying, yes
  - custom_payment_ref: character varying, yes
  - amount: double precision, yes
  - voided: boolean, yes

## selemti.vw_pagos_por_terminal_dia — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - terminal_id: integer, yes
  - fecha: date, yes
  - efectivo: numeric, yes
  - credito: numeric, yes
  - debito: numeric, yes
  - transfer: numeric, yes
  - gift: numeric, yes
  - custom: numeric, yes
  - total_tarjetas: numeric, yes

## selemti.vw_resumen_conciliacion_terminal_dia — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - terminal_id: integer, yes
  - fecha: date, yes
  - ventas_netas: numeric, yes
  - efectivo: numeric, yes
  - credito: numeric, yes
  - debito: numeric, yes
  - transfer: numeric, yes
  - custom: numeric, yes
  - gift: numeric, yes
  - total_tarjetas: numeric, yes
  - descuentos_ticket: numeric, yes
  - descuentos_items: numeric, yes
  - descuentos_100: numeric, yes
  - descuentos_parciales: numeric, yes
  - total_descuentos: numeric, yes
  - anulaciones_total: numeric, yes

## selemti.vw_sesion_descuentos — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - sesion_id: bigint, yes
  - descuentos: numeric, yes

## selemti.vw_sesion_dpr — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - sesion_id: bigint, yes
  - id: integer, yes
  - report_time: timestamp without time zone, yes
  - reg: character varying, yes
  - ticket_count: integer, yes
  - begin_cash: double precision, yes
  - net_sales: double precision, yes
  - sales_tax: double precision, yes
  - cash_tax: double precision, yes
  - total_revenue: double precision, yes
  - gross_receipts: double precision, yes
  - giftcertreturncount: integer, yes
  - giftcertreturnamount: double precision, yes
  - giftcertchangeamount: double precision, yes
  - cash_receipt_no: integer, yes
  - cash_receipt_amount: double precision, yes
  - credit_card_receipt_no: integer, yes
  - credit_card_receipt_amount: double precision, yes
  - debit_card_receipt_no: integer, yes
  - debit_card_receipt_amount: double precision, yes
  - refund_receipt_count: integer, yes
  - refund_amount: double precision, yes
  - receipt_differential: double precision, yes
  - cash_back: double precision, yes
  - cash_tips: double precision, yes
  - charged_tips: double precision, yes
  - tips_paid: double precision, yes
  - tips_differential: double precision, yes
  - pay_out_no: integer, yes
  - pay_out_amount: double precision, yes
  - drawer_bleed_no: integer, yes
  - drawer_bleed_amount: double precision, yes
  - drawer_accountable: double precision, yes
  - cash_to_deposit: double precision, yes
  - variance: double precision, yes
  - delivery_charge: double precision, yes
  - totalvoidwst: double precision, yes
  - totalvoid: double precision, yes
  - totaldiscountcount: integer, yes
  - totaldiscountamount: double precision, yes
  - totaldiscountsales: double precision, yes
  - totaldiscountguest: integer, yes
  - totaldiscountpartysize: integer, yes
  - totaldiscountchecksize: integer, yes
  - totaldiscountpercentage: double precision, yes
  - totaldiscountratio: double precision, yes
  - user_id: integer, yes
  - terminal_id: integer, yes

## selemti.vw_sesion_reembolsos_efectivo — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - sesion_id: bigint, yes
  - reembolsos_efectivo: numeric, yes

## selemti.vw_sesion_retiros — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - sesion_id: bigint, yes
  - retiros: numeric, yes

## selemti.vw_sesion_ventas — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - sesion_id: bigint, yes
  - codigo_fp: text, yes
  - monto: numeric, yes

