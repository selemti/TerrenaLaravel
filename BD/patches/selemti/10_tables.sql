-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql
BEGIN;
SET search_path = selemti, public;
CREATE TABLE almacen (
    id text NOT NULL,
    sucursal_id text NOT NULL,
    nombre text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE almacen OWNER TO postgres;

CREATE TABLE bodega (
    id integer NOT NULL,
    sucursal_id text NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL
);


ALTER TABLE bodega OWNER TO postgres;

CREATE TABLE cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE cache OWNER TO postgres;

CREATE TABLE cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE cache_locks OWNER TO postgres;

CREATE TABLE cat_unidades (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE cat_unidades OWNER TO postgres;

CREATE TABLE conciliacion (
    id bigint NOT NULL,
    postcorte_id bigint NOT NULL,
    conciliado_por integer,
    conciliado_en timestamp with time zone DEFAULT now(),
    estatus text DEFAULT 'EN_REVISION'::text NOT NULL,
    notas text,
    CONSTRAINT conciliacion_estatus_check CHECK ((estatus = ANY (ARRAY['EN_REVISION'::text, 'CONCILIADO'::text, 'OBSERVADA'::text])))
);


ALTER TABLE conciliacion OWNER TO postgres;

CREATE TABLE conversiones_unidad (
    id integer NOT NULL,
    unidad_origen_id integer NOT NULL,
    unidad_destino_id integer NOT NULL,
    factor_conversion numeric(12,6) NOT NULL,
    formula_directa text,
    precision_estimada numeric(5,4) DEFAULT 1.0,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT conversiones_unidad_check CHECK ((unidad_origen_id <> unidad_destino_id)),
    CONSTRAINT conversiones_unidad_factor_conversion_check CHECK ((factor_conversion > (0)::numeric))
);


ALTER TABLE conversiones_unidad OWNER TO postgres;

CREATE TABLE cost_layer (
    id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    batch_id bigint,
    ts_in timestamp without time zone NOT NULL,
    qty_in numeric(14,6) NOT NULL,
    qty_left numeric(14,6) NOT NULL,
    unit_cost numeric(14,6) NOT NULL,
    sucursal_id character varying(30),
    source_ref text,
    source_id bigint
);


ALTER TABLE cost_layer OWNER TO postgres;

CREATE TABLE failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE failed_jobs OWNER TO postgres;

CREATE TABLE hist_cost_insumo (
    id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    fecha_efectiva date NOT NULL,
    costo_wac numeric(14,6),
    costo_peps numeric(14,6),
    costo_ueps numeric(14,6),
    costo_std numeric(14,6),
    algoritmo_principal text DEFAULT 'WAC'::text,
    valid_from date DEFAULT ('now'::text)::date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone
);


ALTER TABLE hist_cost_insumo OWNER TO postgres;

CREATE TABLE hist_cost_receta (
    id bigint NOT NULL,
    receta_version_id bigint NOT NULL,
    fecha_calculo date NOT NULL,
    costo_total numeric(14,6),
    costo_porcion numeric(14,6),
    algoritmo_utilizado text DEFAULT 'WAC'::text,
    valid_from date DEFAULT ('now'::text)::date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone
);


ALTER TABLE hist_cost_receta OWNER TO postgres;

CREATE TABLE historial_costos_item (
    id integer NOT NULL,
    item_id character varying(20) NOT NULL,
    fecha_efectiva date NOT NULL,
    fecha_registro timestamp without time zone DEFAULT now(),
    costo_anterior numeric(10,2),
    costo_nuevo numeric(10,2),
    tipo_cambio character varying(20),
    referencia_id integer,
    referencia_tipo character varying(20),
    usuario_id integer,
    valid_from date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone,
    costo_wac numeric(12,4),
    costo_peps numeric(12,4),
    costo_ueps numeric(12,4),
    costo_estandar numeric(12,4),
    algoritmo_principal character varying(10) DEFAULT 'WAC'::character varying,
    version_datos integer DEFAULT 1,
    recalculado boolean DEFAULT false,
    fuente_datos character varying(20),
    metadata_calculo json,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT historial_costos_item_algoritmo_principal_check CHECK (((algoritmo_principal)::text = ANY ((ARRAY['WAC'::character varying, 'PEPS'::character varying, 'UEPS'::character varying, 'ESTANDAR'::character varying])::text[]))),
    CONSTRAINT historial_costos_item_fuente_datos_check CHECK (((fuente_datos)::text = ANY ((ARRAY['COMPRA'::character varying, 'AJUSTE'::character varying, 'REPROCESO'::character varying, 'IMPORTACION'::character varying])::text[]))),
    CONSTRAINT historial_costos_item_tipo_cambio_check CHECK (((tipo_cambio)::text = ANY ((ARRAY['COMPRA'::character varying, 'AJUSTE'::character varying, 'REPROCESO'::character varying])::text[])))
);


ALTER TABLE historial_costos_item OWNER TO postgres;

CREATE TABLE historial_costos_receta (
    id integer NOT NULL,
    receta_version_id integer NOT NULL,
    fecha_calculo date NOT NULL,
    costo_total numeric(10,2),
    costo_porcion numeric(10,2),
    algoritmo_utilizado character varying(20),
    version_datos integer DEFAULT 1,
    metadata_calculo json,
    created_at timestamp without time zone DEFAULT now(),
    valid_from date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone
);


ALTER TABLE historial_costos_receta OWNER TO postgres;

CREATE TABLE insumo (
    id bigint NOT NULL,
    sku text,
    nombre text NOT NULL,
    um_id integer NOT NULL,
    perecible boolean DEFAULT false NOT NULL,
    merma_pct numeric(6,3) DEFAULT 0.000 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    meta jsonb
);


ALTER TABLE insumo OWNER TO postgres;

CREATE TABLE insumo_presentacion (
    id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    proveedor_id integer,
    um_compra_id integer NOT NULL,
    factor_a_um numeric(14,6) DEFAULT 1.0 NOT NULL,
    costo_ultimo numeric(14,6) DEFAULT 0.0 NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE insumo_presentacion OWNER TO postgres;

CREATE TABLE inventory_batch (
    id integer NOT NULL,
    item_id character varying(20) NOT NULL,
    lote_proveedor character varying(50) NOT NULL,
    fecha_recepcion date NOT NULL,
    fecha_caducidad date NOT NULL,
    temperatura_recepcion numeric(5,2),
    documento_url character varying(255),
    cantidad_original numeric(10,3) NOT NULL,
    cantidad_actual numeric(10,3) NOT NULL,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying,
    ubicacion_id character varying(10) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT inventory_batch_cantidad_actual_check CHECK ((cantidad_actual >= (0)::numeric)),
    CONSTRAINT inventory_batch_cantidad_original_check CHECK ((cantidad_original > (0)::numeric)),
    CONSTRAINT inventory_batch_check CHECK ((cantidad_actual <= cantidad_original)),
    CONSTRAINT inventory_batch_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'BLOQUEADO'::character varying, 'RECALL'::character varying])::text[]))),
    CONSTRAINT inventory_batch_lote_proveedor_check CHECK (((length((lote_proveedor)::text) >= 1) AND (length((lote_proveedor)::text) <= 50))),
    CONSTRAINT inventory_batch_temperatura_recepcion_check CHECK (((temperatura_recepcion >= ('-30'::integer)::numeric) AND (temperatura_recepcion <= (60)::numeric))),
    CONSTRAINT inventory_batch_ubicacion_id_check CHECK (((ubicacion_id)::text ~~ 'UBIC-%'::text))
);


ALTER TABLE inventory_batch OWNER TO postgres;

CREATE TABLE item_vendor (
    item_id text NOT NULL,
    vendor_id text NOT NULL,
    presentacion text NOT NULL,
    unidad_presentacion_id integer NOT NULL,
    factor_a_canonica numeric(14,6) NOT NULL,
    costo_ultimo numeric(14,6) DEFAULT 0 NOT NULL,
    moneda text DEFAULT 'MXN'::text NOT NULL,
    lead_time_dias integer,
    codigo_proveedor text,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT item_vendor_factor_a_canonica_check CHECK ((factor_a_canonica > (0)::numeric))
);


ALTER TABLE item_vendor OWNER TO postgres;

CREATE TABLE items (
    id character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    categoria_id character varying(10) NOT NULL,
    unidad_medida character varying(10) DEFAULT 'PZ'::character varying NOT NULL,
    perishable boolean DEFAULT false,
    temperatura_min integer,
    temperatura_max integer,
    costo_promedio numeric(10,2) DEFAULT 0.00,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    unidad_medida_id integer,
    factor_conversion numeric(12,6) DEFAULT 1.0,
    unidad_compra_id integer,
    factor_compra numeric(12,6) DEFAULT 1.0,
    tipo producto_tipo,
    unidad_salida_id integer,
    CONSTRAINT items_categoria_id_check CHECK (((categoria_id)::text ~~ 'CAT-%'::text)),
    CONSTRAINT items_check CHECK (((temperatura_max IS NULL) OR (temperatura_min IS NULL) OR (temperatura_max >= temperatura_min))),
    CONSTRAINT items_costo_promedio_check CHECK ((costo_promedio >= (0)::numeric)),
    CONSTRAINT items_id_check CHECK (((id)::text ~ '^[A-Z0-9\-]{1,20}$'::text)),
    CONSTRAINT items_nombre_check CHECK ((length((nombre)::text) >= 2)),
    CONSTRAINT items_unidad_medida_check CHECK (((unidad_medida)::text = ANY ((ARRAY['KG'::character varying, 'LT'::character varying, 'PZ'::character varying, 'BULTO'::character varying, 'CAJA'::character varying])::text[])))
);


ALTER TABLE items OWNER TO postgres;

CREATE TABLE job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE job_batches OWNER TO postgres;

CREATE TABLE job_recalc_queue (
    id bigint NOT NULL,
    scope_type text NOT NULL,
    scope_from date,
    scope_to date,
    item_id character varying(20),
    receta_id character varying(20),
    sucursal_id character varying(30),
    reason text,
    created_ts timestamp without time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'PENDING'::text NOT NULL,
    result json,
    CONSTRAINT job_recalc_queue_scope_type_check CHECK ((scope_type = ANY (ARRAY['PERIODO'::text, 'ITEM'::text, 'RECETA'::text, 'SUCURSAL'::text]))),
    CONSTRAINT job_recalc_queue_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'RUNNING'::text, 'DONE'::text, 'FAILED'::text])))
);


ALTER TABLE job_recalc_queue OWNER TO postgres;

CREATE TABLE jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE jobs OWNER TO postgres;

CREATE TABLE lote (
    id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    proveedor_id integer,
    codigo text,
    caducidad date,
    estado lote_estado DEFAULT 'ACTIVO'::lote_estado NOT NULL,
    creado_ts timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE lote OWNER TO postgres;

CREATE TABLE merma (
    id bigint NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    tipo merma_tipo NOT NULL,
    insumo_id bigint NOT NULL,
    lote_id bigint,
    op_id bigint,
    qty numeric(14,6) NOT NULL,
    um_id integer NOT NULL,
    usuario_id bigint,
    motivo text,
    meta jsonb
);


ALTER TABLE merma OWNER TO postgres;

CREATE TABLE migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE migrations OWNER TO postgres;

CREATE TABLE model_has_permissions (
    permission_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE model_has_permissions OWNER TO postgres;

CREATE TABLE model_has_roles (
    role_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE model_has_roles OWNER TO postgres;

CREATE TABLE modificadores_pos (
    id integer NOT NULL,
    codigo_pos character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    tipo character varying(20),
    precio_extra numeric(10,2) DEFAULT 0,
    receta_modificador_id character varying(20),
    activo boolean DEFAULT true,
    CONSTRAINT modificadores_pos_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['AGREGADO'::character varying, 'SUSTITUCION'::character varying, 'ELIMINACION'::character varying])::text[])))
);


ALTER TABLE modificadores_pos OWNER TO postgres;

CREATE TABLE mov_inv (
    id bigint NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    item_id character varying(20) NOT NULL,
    lote_id integer,
    cantidad numeric(14,6) NOT NULL,
    qty_original numeric(14,6),
    uom_original_id integer,
    costo_unit numeric(14,6) DEFAULT 0,
    tipo character varying(20) NOT NULL,
    ref_tipo character varying(50),
    ref_id bigint,
    sucursal_id character varying(30),
    usuario_id integer,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT mov_inv_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['ENTRADA'::character varying, 'SALIDA'::character varying, 'AJUSTE'::character varying, 'MERMA'::character varying, 'TRASPASO'::character varying])::text[])))
);


ALTER TABLE mov_inv OWNER TO postgres;

CREATE TABLE op_cab (
    id bigint NOT NULL,
    sucursal_id text NOT NULL,
    receta_version_id bigint NOT NULL,
    cantidad_objetivo numeric(14,6) NOT NULL,
    um_salida_id integer NOT NULL,
    estado op_estado DEFAULT 'ABIERTA'::op_estado NOT NULL,
    ts_apertura timestamp without time zone DEFAULT now() NOT NULL,
    ts_cierre timestamp without time zone,
    usuario_abre bigint,
    usuario_cierra bigint,
    lote_salida_id bigint,
    meta jsonb
);


ALTER TABLE op_cab OWNER TO postgres;

CREATE TABLE op_insumo (
    id bigint NOT NULL,
    op_id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    qty_teorica numeric(14,6) NOT NULL,
    qty_real numeric(14,6),
    um_id integer NOT NULL,
    lote_id bigint,
    meta jsonb
);


ALTER TABLE op_insumo OWNER TO postgres;

CREATE TABLE op_produccion_cab (
    id integer NOT NULL,
    receta_version_id integer NOT NULL,
    cantidad_planeada numeric(10,3) NOT NULL,
    cantidad_real numeric(10,3),
    fecha_produccion date NOT NULL,
    estado character varying(20) DEFAULT 'PENDIENTE'::character varying,
    lote_resultado character varying(50),
    usuario_responsable integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT op_produccion_cab_cantidad_planeada_check CHECK ((cantidad_planeada > (0)::numeric)),
    CONSTRAINT op_produccion_cab_estado_check CHECK (((estado)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'EN_PROCESO'::character varying, 'COMPLETADA'::character varying, 'CANCELADA'::character varying])::text[])))
);


ALTER TABLE op_produccion_cab OWNER TO postgres;

CREATE TABLE op_yield (
    op_id bigint NOT NULL,
    cantidad_real numeric(14,6) NOT NULL,
    merma_real numeric(14,6) DEFAULT 0 NOT NULL,
    evidencia_url text,
    meta jsonb
);


ALTER TABLE op_yield OWNER TO postgres;

CREATE TABLE param_sucursal (
    id integer NOT NULL,
    sucursal_id text NOT NULL,
    consumo consumo_policy DEFAULT 'FEFO'::consumo_policy NOT NULL,
    tolerancia_precorte_pct numeric(8,4) DEFAULT 0.02,
    tolerancia_corte_abs numeric(12,4) DEFAULT 50.0,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE param_sucursal OWNER TO postgres;

CREATE TABLE password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE password_reset_tokens OWNER TO postgres;

CREATE TABLE perdida_log (
    id bigint NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    item_id text NOT NULL,
    lote_id bigint,
    sucursal_id text,
    clase merma_clase NOT NULL,
    motivo text,
    qty_canonica numeric(14,6) NOT NULL,
    qty_original numeric(14,6),
    uom_original_id integer,
    evidencia_url text,
    usuario_id integer,
    ref_tipo text,
    ref_id bigint,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT perdida_log_qty_canonica_check CHECK ((qty_canonica > (0)::numeric))
);


ALTER TABLE perdida_log OWNER TO postgres;

CREATE TABLE permissions (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE permissions OWNER TO postgres;

CREATE TABLE pos_map (
    pos_system text NOT NULL,
    plu text NOT NULL,
    tipo text NOT NULL,
    receta_id text,
    receta_version_id integer,
    valid_from date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone,
    meta json,
    vigente_desde timestamp without time zone,
    CONSTRAINT pos_map_tipo_check CHECK ((tipo = ANY (ARRAY['PLATO'::text, 'MODIFICADOR'::text, 'COMBO'::text])))
);


ALTER TABLE pos_map OWNER TO postgres;

CREATE TABLE proveedor (
    id text NOT NULL,
    nombre text NOT NULL,
    rfc text,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE proveedor OWNER TO postgres;

CREATE TABLE recalc_log (
    id bigint NOT NULL,
    job_id bigint,
    step text,
    started_ts timestamp without time zone,
    ended_ts timestamp without time zone,
    ok boolean,
    details json
);


ALTER TABLE recalc_log OWNER TO postgres;

CREATE TABLE recepcion_cab (
    id bigint NOT NULL,
    sucursal_id text NOT NULL,
    proveedor_id integer,
    oc_ref text,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    usuario_id bigint,
    meta jsonb
);


ALTER TABLE recepcion_cab OWNER TO postgres;

CREATE TABLE recepcion_det (
    id bigint NOT NULL,
    recepcion_id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    bodega_id integer NOT NULL,
    qty numeric(14,6) NOT NULL,
    um_id integer NOT NULL,
    costo_unit numeric(14,6) NOT NULL,
    lote_id bigint,
    temperatura numeric(6,2),
    doc_url text,
    meta jsonb
);


ALTER TABLE recepcion_det OWNER TO postgres;

CREATE TABLE receta (
    id bigint NOT NULL,
    codigo text,
    nombre text NOT NULL,
    porciones numeric(12,4) DEFAULT 1.0 NOT NULL,
    pvp_objetivo numeric(12,4),
    activo boolean DEFAULT true NOT NULL,
    meta jsonb
);


ALTER TABLE receta OWNER TO postgres;

CREATE TABLE receta_cab (
    id character varying(20) NOT NULL,
    nombre_plato character varying(100) NOT NULL,
    codigo_plato_pos character varying(20),
    categoria_plato character varying(50),
    porciones_standard integer DEFAULT 1,
    instrucciones_preparacion text,
    tiempo_preparacion_min integer,
    costo_standard_porcion numeric(10,2) DEFAULT 0,
    precio_venta_sugerido numeric(10,2) DEFAULT 0,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT receta_cab_id_check CHECK (((id)::text ~ '^REC-[A-Z0-9\-]+$'::text)),
    CONSTRAINT receta_cab_porciones_standard_check CHECK ((porciones_standard > 0))
);


ALTER TABLE receta_cab OWNER TO postgres;

CREATE TABLE receta_det (
    id integer NOT NULL,
    receta_version_id integer NOT NULL,
    item_id character varying(20) NOT NULL,
    cantidad numeric(10,4) NOT NULL,
    unidad_medida character varying(10) NOT NULL,
    merma_porcentaje numeric(5,2) DEFAULT 0,
    instrucciones_especificas text,
    orden integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT receta_det_cantidad_check CHECK ((cantidad > (0)::numeric)),
    CONSTRAINT receta_det_merma_porcentaje_check CHECK (((merma_porcentaje >= (0)::numeric) AND (merma_porcentaje <= (100)::numeric)))
);


ALTER TABLE receta_det OWNER TO postgres;

CREATE TABLE receta_insumo (
    id bigint NOT NULL,
    receta_version_id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    cantidad numeric(14,6) NOT NULL
);


ALTER TABLE receta_insumo OWNER TO postgres;

CREATE TABLE receta_shadow (
    id integer NOT NULL,
    codigo_plato_pos character varying(20) NOT NULL,
    nombre_plato character varying(100) NOT NULL,
    estado character varying(15) DEFAULT 'INFERIDA'::character varying,
    confianza numeric(5,4) DEFAULT 0.0,
    total_ventas_analizadas integer DEFAULT 0,
    fecha_primer_venta date,
    fecha_ultima_venta date,
    frecuencia_dias numeric(10,2),
    ingredientes_inferidos json,
    usuario_validador integer,
    fecha_validacion timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT receta_shadow_confianza_check CHECK (((confianza >= (0)::numeric) AND (confianza <= (1)::numeric))),
    CONSTRAINT receta_shadow_estado_check CHECK (((estado)::text = ANY ((ARRAY['INFERIDA'::character varying, 'VALIDADA'::character varying, 'DESCARTADA'::character varying])::text[])))
);


ALTER TABLE receta_shadow OWNER TO postgres;

CREATE TABLE receta_version (
    id integer NOT NULL,
    receta_id character varying(20) NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    descripcion_cambios text,
    fecha_efectiva date NOT NULL,
    version_publicada boolean DEFAULT false,
    usuario_publicador integer,
    fecha_publicacion timestamp without time zone,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE receta_version OWNER TO postgres;

CREATE TABLE rol (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL
);


ALTER TABLE rol OWNER TO postgres;

CREATE TABLE role_has_permissions (
    permission_id bigint NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE role_has_permissions OWNER TO postgres;

CREATE TABLE roles (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE roles OWNER TO postgres;

CREATE TABLE sessions (
    id character varying(255) NOT NULL,
    user_id bigint,
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


ALTER TABLE sessions OWNER TO postgres;

CREATE TABLE stock_policy (
    id bigint NOT NULL,
    item_id text NOT NULL,
    sucursal_id text NOT NULL,
    almacen_id text,
    min_qty numeric(14,6) DEFAULT 0 NOT NULL,
    max_qty numeric(14,6) DEFAULT 0 NOT NULL,
    reorder_lote numeric(14,6),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE stock_policy OWNER TO postgres;

CREATE TABLE sucursal (
    id text NOT NULL,
    nombre text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE sucursal OWNER TO postgres;

CREATE TABLE sucursal_almacen_terminal (
    id integer NOT NULL,
    sucursal_id text NOT NULL,
    almacen_id text NOT NULL,
    terminal_id integer,
    location text,
    descripcion text,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE sucursal_almacen_terminal OWNER TO postgres;

CREATE TABLE ticket_det_consumo (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    ticket_det_id bigint NOT NULL,
    item_id text NOT NULL,
    lote_id bigint,
    qty_canonica numeric(14,6) NOT NULL,
    qty_original numeric(14,6),
    uom_original_id integer,
    sucursal_id text,
    ref_tipo text,
    ref_id bigint,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT ticket_det_consumo_qty_canonica_check CHECK ((qty_canonica > (0)::numeric))
);


ALTER TABLE ticket_det_consumo OWNER TO postgres;

CREATE TABLE ticket_venta_cab (
    id bigint NOT NULL,
    numero_ticket character varying(50) NOT NULL,
    fecha_venta timestamp without time zone DEFAULT now() NOT NULL,
    sucursal_id character varying(10) NOT NULL,
    terminal_id integer,
    total_venta numeric(12,2) DEFAULT 0,
    estado character varying(20) DEFAULT 'ABIERTO'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT ticket_venta_cab_estado_check CHECK (((estado)::text = ANY ((ARRAY['ABIERTO'::character varying, 'CERRADO'::character varying, 'ANULADO'::character varying])::text[])))
);


ALTER TABLE ticket_venta_cab OWNER TO postgres;

CREATE TABLE ticket_venta_det (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    cantidad numeric(10,3) NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    receta_version_id integer,
    created_at timestamp without time zone DEFAULT now(),
    receta_shadow_id integer,
    reprocesado boolean DEFAULT false,
    version_reproceso integer DEFAULT 1,
    modificadores_aplicados json,
    CONSTRAINT ticket_venta_det_cantidad_check CHECK ((cantidad > (0)::numeric))
);


ALTER TABLE ticket_venta_det OWNER TO postgres;

CREATE TABLE traspaso_cab (
    id bigint NOT NULL,
    from_bodega_id integer NOT NULL,
    to_bodega_id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    usuario_id bigint,
    meta jsonb
);


ALTER TABLE traspaso_cab OWNER TO postgres;

CREATE TABLE traspaso_det (
    id bigint NOT NULL,
    traspaso_id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    lote_id bigint,
    qty numeric(14,6) NOT NULL,
    um_id integer NOT NULL
);


ALTER TABLE traspaso_det OWNER TO postgres;

CREATE TABLE unidad_medida (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    tipo text NOT NULL,
    es_base boolean DEFAULT false NOT NULL,
    factor_a_base numeric(14,6) DEFAULT 1.0 NOT NULL,
    decimales integer DEFAULT 2 NOT NULL,
    CONSTRAINT unidad_medida_tipo_check CHECK ((tipo = ANY (ARRAY['PESO'::text, 'VOLUMEN'::text, 'UNIDAD'::text, 'TIEMPO'::text])))
);


ALTER TABLE unidad_medida OWNER TO postgres;

CREATE TABLE unidades_medida (
    id integer NOT NULL,
    codigo character varying(10) NOT NULL,
    nombre character varying(50) NOT NULL,
    tipo character varying(10) NOT NULL,
    categoria character varying(20),
    es_base boolean DEFAULT false,
    factor_conversion_base numeric(12,6) DEFAULT 1.0,
    decimales integer DEFAULT 2,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT unidades_medida_categoria_check CHECK (((categoria)::text = ANY ((ARRAY['METRICO'::character varying, 'IMPERIAL'::character varying, 'CULINARIO'::character varying])::text[]))),
    CONSTRAINT unidades_medida_codigo_check CHECK (((codigo)::text ~ '^[A-Z]{2,5}$'::text)),
    CONSTRAINT unidades_medida_decimales_check CHECK (((decimales >= 0) AND (decimales <= 6))),
    CONSTRAINT unidades_medida_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['PESO'::character varying, 'VOLUMEN'::character varying, 'UNIDAD'::character varying, 'TIEMPO'::character varying])::text[])))
);


ALTER TABLE unidades_medida OWNER TO postgres;

CREATE TABLE uom_conversion (
    id integer NOT NULL,
    origen_id integer NOT NULL,
    destino_id integer NOT NULL,
    factor numeric(14,6) NOT NULL,
    CONSTRAINT uom_conversion_check CHECK ((origen_id <> destino_id)),
    CONSTRAINT uom_conversion_factor_check CHECK ((factor > (0)::numeric))
);


ALTER TABLE uom_conversion OWNER TO postgres;

CREATE TABLE user_roles (
    user_id integer NOT NULL,
    role_id character varying(20) NOT NULL,
    assigned_at timestamp without time zone DEFAULT now(),
    assigned_by integer,
    CONSTRAINT user_roles_role_id_check CHECK (((role_id)::text = ANY ((ARRAY['GERENTE'::character varying, 'CHEF'::character varying, 'ALMACEN'::character varying, 'CAJERO'::character varying, 'AUDITOR'::character varying, 'SISTEMA'::character varying])::text[])))
);


ALTER TABLE user_roles OWNER TO postgres;

CREATE TABLE users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    email character varying(255),
    nombre_completo character varying(100) NOT NULL,
    sucursal_id character varying(10) DEFAULT 'SUR'::character varying,
    activo boolean DEFAULT true,
    fecha_ultimo_login timestamp without time zone,
    intentos_login integer DEFAULT 0,
    bloqueado_hasta timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT users_email_check CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)),
    CONSTRAINT users_intentos_login_check CHECK ((intentos_login >= 0)),
    CONSTRAINT users_password_hash_check CHECK ((length((password_hash)::text) = 60)),
    CONSTRAINT users_sucursal_id_check CHECK (((sucursal_id)::text = ANY ((ARRAY['SUR'::character varying, 'NORTE'::character varying, 'CENTRO'::character varying])::text[]))),
    CONSTRAINT users_username_check CHECK ((length((username)::text) >= 3))
);


ALTER TABLE users OWNER TO postgres;

CREATE TABLE usuario (
    id bigint NOT NULL,
    username text NOT NULL,
    nombre text NOT NULL,
    email text,
    rol_id integer NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    password_hash text,
    floreant_user_id integer,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE usuario OWNER TO postgres;

ALTER TABLE ONLY auditoria ALTER COLUMN id SET DEFAULT nextval('auditoria_id_seq'::regclass);


ALTER TABLE ONLY bodega ALTER COLUMN id SET DEFAULT nextval('bodega_id_seq'::regclass);


ALTER TABLE ONLY cat_unidades ALTER COLUMN id SET DEFAULT nextval('cat_unidades_id_seq'::regclass);


ALTER TABLE ONLY conciliacion ALTER COLUMN id SET DEFAULT nextval('conciliacion_id_seq'::regclass);


ALTER TABLE ONLY conversiones_unidad ALTER COLUMN id SET DEFAULT nextval('conversiones_unidad_id_seq'::regclass);


ALTER TABLE ONLY cost_layer ALTER COLUMN id SET DEFAULT nextval('cost_layer_id_seq'::regclass);


ALTER TABLE ONLY failed_jobs ALTER COLUMN id SET DEFAULT nextval('failed_jobs_id_seq'::regclass);


ALTER TABLE ONLY formas_pago ALTER COLUMN id SET DEFAULT nextval('formas_pago_id_seq'::regclass);


ALTER TABLE ONLY hist_cost_insumo ALTER COLUMN id SET DEFAULT nextval('hist_cost_insumo_id_seq'::regclass);


ALTER TABLE ONLY hist_cost_receta ALTER COLUMN id SET DEFAULT nextval('hist_cost_receta_id_seq'::regclass);


ALTER TABLE ONLY historial_costos_item ALTER COLUMN id SET DEFAULT nextval('historial_costos_item_id_seq'::regclass);


ALTER TABLE ONLY historial_costos_receta ALTER COLUMN id SET DEFAULT nextval('historial_costos_receta_id_seq'::regclass);


ALTER TABLE ONLY insumo ALTER COLUMN id SET DEFAULT nextval('insumo_id_seq'::regclass);


ALTER TABLE ONLY insumo_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_presentacion_id_seq'::regclass);


ALTER TABLE ONLY inventory_batch ALTER COLUMN id SET DEFAULT nextval('inventory_batch_id_seq'::regclass);


ALTER TABLE ONLY job_recalc_queue ALTER COLUMN id SET DEFAULT nextval('job_recalc_queue_id_seq'::regclass);


ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


ALTER TABLE ONLY lote ALTER COLUMN id SET DEFAULT nextval('lote_id_seq'::regclass);


ALTER TABLE ONLY merma ALTER COLUMN id SET DEFAULT nextval('merma_id_seq'::regclass);


ALTER TABLE ONLY migrations ALTER COLUMN id SET DEFAULT nextval('migrations_id_seq'::regclass);


ALTER TABLE ONLY modificadores_pos ALTER COLUMN id SET DEFAULT nextval('modificadores_pos_id_seq'::regclass);


ALTER TABLE ONLY mov_inv ALTER COLUMN id SET DEFAULT nextval('mov_inv_id_seq'::regclass);


ALTER TABLE ONLY op_cab ALTER COLUMN id SET DEFAULT nextval('op_cab_id_seq'::regclass);


ALTER TABLE ONLY op_insumo ALTER COLUMN id SET DEFAULT nextval('op_insumo_id_seq'::regclass);


ALTER TABLE ONLY op_produccion_cab ALTER COLUMN id SET DEFAULT nextval('op_produccion_cab_id_seq'::regclass);


ALTER TABLE ONLY param_sucursal ALTER COLUMN id SET DEFAULT nextval('param_sucursal_id_seq'::regclass);


ALTER TABLE ONLY perdida_log ALTER COLUMN id SET DEFAULT nextval('perdida_log_id_seq'::regclass);


ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);


ALTER TABLE ONLY postcorte ALTER COLUMN id SET DEFAULT nextval('postcorte_id_seq'::regclass);


ALTER TABLE ONLY precorte ALTER COLUMN id SET DEFAULT nextval('precorte_id_seq'::regclass);


ALTER TABLE ONLY precorte_efectivo ALTER COLUMN id SET DEFAULT nextval('precorte_efectivo_id_seq'::regclass);


ALTER TABLE ONLY precorte_otros ALTER COLUMN id SET DEFAULT nextval('precorte_otros_id_seq'::regclass);


ALTER TABLE ONLY recalc_log ALTER COLUMN id SET DEFAULT nextval('recalc_log_id_seq'::regclass);


ALTER TABLE ONLY recepcion_cab ALTER COLUMN id SET DEFAULT nextval('recepcion_cab_id_seq'::regclass);


ALTER TABLE ONLY recepcion_det ALTER COLUMN id SET DEFAULT nextval('recepcion_det_id_seq'::regclass);


ALTER TABLE ONLY receta ALTER COLUMN id SET DEFAULT nextval('receta_id_seq'::regclass);


ALTER TABLE ONLY receta_det ALTER COLUMN id SET DEFAULT nextval('receta_det_id_seq'::regclass);


ALTER TABLE ONLY receta_insumo ALTER COLUMN id SET DEFAULT nextval('receta_insumo_id_seq'::regclass);


ALTER TABLE ONLY receta_shadow ALTER COLUMN id SET DEFAULT nextval('receta_shadow_id_seq'::regclass);


ALTER TABLE ONLY receta_version ALTER COLUMN id SET DEFAULT nextval('receta_version_id_seq'::regclass);


ALTER TABLE ONLY rol ALTER COLUMN id SET DEFAULT nextval('rol_id_seq'::regclass);


ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


ALTER TABLE ONLY sesion_cajon ALTER COLUMN id SET DEFAULT nextval('sesion_cajon_id_seq'::regclass);


ALTER TABLE ONLY stock_policy ALTER COLUMN id SET DEFAULT nextval('stock_policy_id_seq'::regclass);


ALTER TABLE ONLY sucursal_almacen_terminal ALTER COLUMN id SET DEFAULT nextval('sucursal_almacen_terminal_id_seq'::regclass);


ALTER TABLE ONLY ticket_det_consumo ALTER COLUMN id SET DEFAULT nextval('ticket_det_consumo_id_seq'::regclass);


ALTER TABLE ONLY ticket_venta_cab ALTER COLUMN id SET DEFAULT nextval('ticket_venta_cab_id_seq'::regclass);


ALTER TABLE ONLY ticket_venta_det ALTER COLUMN id SET DEFAULT nextval('ticket_venta_det_id_seq'::regclass);


ALTER TABLE ONLY traspaso_cab ALTER COLUMN id SET DEFAULT nextval('traspaso_cab_id_seq'::regclass);


ALTER TABLE ONLY traspaso_det ALTER COLUMN id SET DEFAULT nextval('traspaso_det_id_seq'::regclass);


ALTER TABLE ONLY unidad_medida ALTER COLUMN id SET DEFAULT nextval('unidad_medida_id_seq'::regclass);


ALTER TABLE ONLY unidades_medida ALTER COLUMN id SET DEFAULT nextval('unidades_medida_id_seq'::regclass);


ALTER TABLE ONLY uom_conversion ALTER COLUMN id SET DEFAULT nextval('uom_conversion_id_seq'::regclass);


ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


ALTER TABLE ONLY usuario ALTER COLUMN id SET DEFAULT nextval('usuario_id_seq'::regclass);


SET search_path = public, pg_catalog;

COMMIT;
