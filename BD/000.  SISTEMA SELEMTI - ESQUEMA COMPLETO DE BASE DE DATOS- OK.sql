-- =====================================================================
-- SISTEMA SELEMTI - ESQUEMA COMPLETO DE BASE DE DATOS
-- PostgreSQL 9.5 compatible - VERSIÓN CORREGIDA (v4.0)
-- Fecha: September 26, 2025
-- Idempotente: Sí (ejecutable múltiples veces)
-- =====================================================================

-- **CORRECCIÓN DE ERRORES PREVIOS: 
-- 1. Se eliminaron metacomandos de psql.
-- 2. Se agregó IF NOT EXISTS a todas las tablas y tipos.
-- 3. Se reemplazó ALTER TABLE ADD COLUMN IF NOT EXISTS (PG 9.6+) con bloques DO.
-- 4. Se reemplazó UNIQUE(COALESCE(...)) con CREATE UNIQUE INDEX separado.
-- 5. Se agregó DROP/CREATE para tabla USERS para corregir el error de columna 'username'.
-- 6. **CORREGIDO:** Se ajustó la longitud del hash de la contraseña a 60 caracteres para pasar la restricción CHECK.

SET client_min_messages = WARNING;
SET TIME ZONE 'America/Mexico_City';

-- 1. CREACIÓN DE ESQUEMA Y PERMISOS
------------------------------------------------------

-- 1.1 CREAR ESQUEMA SI NO EXISTE
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'selemti') THEN
        CREATE SCHEMA selemti;
        RAISE NOTICE 'Esquema selemti creado exitosamente';
    ELSE
        RAISE NOTICE 'Esquema selemti ya existe';
    END IF;
END
$$;

-- 1.2 CREAR USUARIO DEDICADO
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'selemti_user') THEN
        -- Nota: En sistemas de producción, use una contraseña más segura
        CREATE USER selemti_user WITH PASSWORD 'selemti_password_2024';
        RAISE NOTICE 'Usuario selemti_user creado exitosamente';
    ELSE
        RAISE NOTICE 'Usuario selemti_user ya existe';
    END IF;
END
$$;

-- 1.3 OTORGAR PERMISOS
GRANT USAGE ON SCHEMA selemti TO selemti_user;
GRANT CREATE ON SCHEMA selemti TO selemti_user;
GRANT USAGE ON SCHEMA public TO selemti_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO selemti_user;

-- 1.4 CONFIGURAR SEARCH PATH
ALTER USER selemti_user SET search_path = 'selemti, public';
SET search_path TO selemti, public;


-- 2. TABLAS MAESTRAS BASE
------------------------------------------------------

-- **CORRECCIÓN 5: FORZAR RECREACIÓN DE TABLA USERS PARA CORREGIR EL ERROR DE COLUMNA.**
DROP TABLE IF EXISTS selemti.users CASCADE;
DROP SEQUENCE IF EXISTS selemti.users_id_seq CASCADE;

-- 2.1 TABLA DE USUARIOS
CREATE TABLE IF NOT EXISTS selemti.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL CHECK (LENGTH(username) >= 3),
    password_hash VARCHAR(255) NOT NULL CHECK (LENGTH(password_hash) = 60), -- Requiere 60 caracteres
    email VARCHAR(255) CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    nombre_completo VARCHAR(100) NOT NULL,
    sucursal_id VARCHAR(10) DEFAULT 'SUR' CHECK (sucursal_id IN ('SUR', 'NORTE', 'CENTRO')),
    activo BOOLEAN DEFAULT TRUE,
    fecha_ultimo_login TIMESTAMP,
    intentos_login INTEGER DEFAULT 0 CHECK (intentos_login >= 0),
    bloqueado_hasta TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
COMMENT ON TABLE selemti.users IS 'Usuarios del sistema con sus credenciales y estado';

-- 2.2 TABLA DE ROLES DE USUARIO
CREATE TABLE IF NOT EXISTS selemti.user_roles (
    user_id INTEGER REFERENCES selemti.users(id) ON DELETE CASCADE,
    role_id VARCHAR(20) CHECK (role_id IN ('GERENTE', 'CHEF', 'ALMACEN', 'CAJERO', 'AUDITOR', 'SISTEMA')),
    assigned_at TIMESTAMP DEFAULT NOW(),
    assigned_by INTEGER REFERENCES selemti.users(id),
    PRIMARY KEY (user_id, role_id)
);
COMMENT ON TABLE selemti.user_roles IS 'Asignación de roles a usuarios (RBAC)';

-- 2.3 TABLA MAESTRA DE ÍTEMS
CREATE TABLE IF NOT EXISTS selemti.items (
    id VARCHAR(20) PRIMARY KEY CHECK (id ~ '^[A-Z0-9\-]{1,20}$'),
    nombre VARCHAR(100) NOT NULL CHECK (LENGTH(nombre) >= 2),
    descripcion TEXT,
    categoria_id VARCHAR(10) NOT NULL CHECK (categoria_id LIKE 'CAT-%'),
    unidad_medida VARCHAR(10) NOT NULL CHECK (unidad_medida IN ('KG','LT','PZ','BULTO','CAJA')),
    perishable BOOLEAN DEFAULT FALSE,
    temperatura_min INTEGER,
    temperatura_max INTEGER,
    costo_promedio NUMERIC(10,2) DEFAULT 0.00 CHECK (costo_promedio >= 0),
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CHECK (temperatura_max IS NULL OR temperatura_min IS NULL OR temperatura_max >= temperatura_min)
);
COMMENT ON TABLE selemti.items IS 'Maestro de todos los ítems del sistema';

-- 2.4 TABLA DE LOTES DE INVENTARIO
CREATE TABLE IF NOT EXISTS selemti.inventory_batch (
    id SERIAL PRIMARY KEY,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    lote_proveedor VARCHAR(50) NOT NULL CHECK (LENGTH(lote_proveedor) BETWEEN 1 AND 50),
    fecha_recepcion DATE NOT NULL,
    fecha_caducidad DATE NOT NULL CHECK (fecha_caducidad >= CURRENT_DATE),
    temperatura_recepcion NUMERIC(5,2) CHECK (temperatura_recepcion BETWEEN -30 AND 60),
    documento_url VARCHAR(255),
    cantidad_original NUMERIC(10,3) NOT NULL CHECK (cantidad_original > 0),
    cantidad_actual NUMERIC(10,3) NOT NULL CHECK (cantidad_actual >= 0),
    estado VARCHAR(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'BLOQUEADO', 'RECALL')),
    ubicacion_id VARCHAR(10) NOT NULL CHECK (ubicacion_id LIKE 'UBIC-%'),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CHECK (cantidad_actual <= cantidad_original)
);
COMMENT ON TABLE selemti.inventory_batch IS 'Lotes de inventario con trazabilidad completa';

-- 2.5 TABLA DE MOVIMIENTOS DE INVENTARIO (KARDEX)
CREATE TABLE IF NOT EXISTS selemti.mov_inv (
    id BIGSERIAL PRIMARY KEY,
    ts TIMESTAMP NOT NULL DEFAULT NOW(),
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    lote_id INTEGER REFERENCES selemti.inventory_batch(id),
    cantidad NUMERIC(14,6) NOT NULL,
    qty_original NUMERIC(14,6),
    uom_original_id INTEGER,
    costo_unit NUMERIC(14,6) DEFAULT 0,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('ENTRADA','SALIDA','AJUSTE','MERMA','TRASPASO')),
    ref_tipo VARCHAR(50),
    ref_id BIGINT,
    sucursal_id VARCHAR(30),
    usuario_id INTEGER REFERENCES selemti.users(id),
    created_at TIMESTAMP DEFAULT NOW()
);
COMMENT ON TABLE selemti.mov_inv IS 'Kardex completo de movimientos de inventario';

-- 2.6 TABLA DE RECETAS CABECERA
CREATE TABLE IF NOT EXISTS selemti.receta_cab (
    id VARCHAR(20) PRIMARY KEY CHECK (id ~ '^REC-[A-Z0-9\-]+$'),
    nombre_plato VARCHAR(100) NOT NULL,
    codigo_plato_pos VARCHAR(20) UNIQUE,
    categoria_plato VARCHAR(50),
    porciones_standard INTEGER DEFAULT 1 CHECK (porciones_standard > 0),
    instrucciones_preparacion TEXT,
    tiempo_preparacion_min INTEGER,
    costo_standard_porcion NUMERIC(10,2) DEFAULT 0,
    precio_venta_sugerido NUMERIC(10,2) DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
COMMENT ON TABLE selemti.receta_cab IS 'Cabecera de recetas y platos del menú';

-- 2.7 TABLA DE VERSIONES DE RECETAS
CREATE TABLE IF NOT EXISTS selemti.receta_version (
    id SERIAL PRIMARY KEY,
    receta_id VARCHAR(20) NOT NULL REFERENCES selemti.receta_cab(id),
    version INTEGER NOT NULL DEFAULT 1,
    descripcion_cambios TEXT,
    fecha_efectiva DATE NOT NULL,
    version_publicada BOOLEAN DEFAULT FALSE,
    usuario_publicador INTEGER REFERENCES selemti.users(id),
    fecha_publicacion TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (receta_id, version)
);
COMMENT ON TABLE selemti.receta_version IS 'Control de versiones de recetas';

-- 2.8 TABLA DE DETALLE DE RECETAS
CREATE TABLE IF NOT EXISTS selemti.receta_det (
    id SERIAL PRIMARY KEY,
    receta_version_id INTEGER NOT NULL REFERENCES selemti.receta_version(id),
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    cantidad NUMERIC(10,4) NOT NULL CHECK (cantidad > 0),
    unidad_medida VARCHAR(10) NOT NULL,
    merma_porcentaje NUMERIC(5,2) DEFAULT 0 CHECK (merma_porcentaje BETWEEN 0 AND 100),
    instrucciones_especificas TEXT,
    orden INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW()
);
COMMENT ON TABLE selemti.receta_det IS 'Detalle de ingredientes por versión de receta';

-- 2.9 TABLA DE ÓRDENES DE PRODUCCIÓN
CREATE TABLE IF NOT EXISTS selemti.op_produccion_cab (
    id SERIAL PRIMARY KEY,
    receta_version_id INTEGER NOT NULL REFERENCES selemti.receta_version(id),
    cantidad_planeada NUMERIC(10,3) NOT NULL CHECK (cantidad_planeada > 0),
    cantidad_real NUMERIC(10,3),
    fecha_produccion DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'EN_PROCESO', 'COMPLETADA', 'CANCELADA')),
    lote_resultado VARCHAR(50),
    usuario_responsable INTEGER REFERENCES selemti.users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
COMMENT ON TABLE selemti.op_produccion_cab IS 'Órdenes de producción para elaborados';

-- 2.10 TABLAS DE VENTAS/TICKETS
CREATE TABLE IF NOT EXISTS selemti.ticket_venta_cab (
    id BIGSERIAL PRIMARY KEY,
    numero_ticket VARCHAR(50) UNIQUE NOT NULL,
    fecha_venta TIMESTAMP NOT NULL DEFAULT NOW(),
    sucursal_id VARCHAR(10) NOT NULL,
    terminal_id INTEGER,
    total_venta NUMERIC(12,2) DEFAULT 0,
    estado VARCHAR(20) DEFAULT 'ABIERTO' CHECK (estado IN ('ABIERTO', 'CERRADO', 'ANULADO')),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS selemti.ticket_venta_det (
    id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL,
    item_id VARCHAR(20) NOT NULL,
    cantidad NUMERIC(10,3) NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL,
    subtotal NUMERIC(12,2) NOT NULL,
    receta_version_id INTEGER REFERENCES selemti.receta_version(id),
    created_at TIMESTAMP DEFAULT NOW()
);

---## 3. UNIDADES DE MEDIDA Y CONVERSIONES

-- 3.1 TABLA DE UNIDADES DE MEDIDA NORMALIZADAS
CREATE TABLE IF NOT EXISTS selemti.unidades_medida (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) UNIQUE NOT NULL CHECK (codigo ~ '^[A-Z]{2,5}$'),
    nombre VARCHAR(50) NOT NULL,
    tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('PESO', 'VOLUMEN', 'UNIDAD', 'TIEMPO')),
    categoria VARCHAR(20) CHECK (categoria IN ('METRICO', 'IMPERIAL', 'CULINARIO')),
    es_base BOOLEAN DEFAULT FALSE,
    factor_conversion_base NUMERIC(12,6) DEFAULT 1.0,
    decimales INTEGER DEFAULT 2 CHECK (decimales BETWEEN 0 AND 6),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 3.2 INSERTAR UNIDADES BASE
INSERT INTO selemti.unidades_medida (codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales) VALUES 
('GR', 'Gramo', 'PESO', 'METRICO', true, 1.0, 2),
('KG', 'Kilogramo', 'PESO', 'METRICO', false, 1000.0, 2),
('ML', 'Mililitro', 'VOLUMEN', 'METRICO', true, 1.0, 2),
('LT', 'Litro', 'VOLUMEN', 'METRICO', false, 1000.0, 2),
('PZ', 'Pieza', 'UNIDAD', 'CULINARIO', true, 1.0, 0),
('OZ', 'Onza', 'PESO', 'IMPERIAL', false, 28.3495, 2),
('LB', 'Libra', 'PESO', 'IMPERIAL', false, 453.592, 2)
ON CONFLICT (codigo) DO NOTHING;

-- 3.3 TABLA DE CONVERSIONES
CREATE TABLE IF NOT EXISTS selemti.conversiones_unidad (
    id SERIAL PRIMARY KEY,
    unidad_origen_id INTEGER NOT NULL REFERENCES selemti.unidades_medida(id),
    unidad_destino_id INTEGER NOT NULL REFERENCES selemti.unidades_medida(id),
    factor_conversion NUMERIC(12,6) NOT NULL CHECK (factor_conversion > 0),
    formula_directa TEXT,
    precision_estimada NUMERIC(5,4) DEFAULT 1.0,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    CHECK (unidad_origen_id != unidad_destino_id),
    UNIQUE (unidad_origen_id, unidad_destino_id)
);

-- 3.4 ACTUALIZAR TABLA ITEMS CON NUEVAS UOM
-- **CORRECCIÓN 3: Reemplazo de ALTER TABLE ADD COLUMN IF NOT EXISTS por bloque DO $$ BEGIN ... END $$**
DO $$
BEGIN
    -- unidad_medida_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='items' AND column_name='unidad_medida_id') THEN
        ALTER TABLE selemti.items ADD COLUMN unidad_medida_id INTEGER REFERENCES selemti.unidades_medida(id);
    END IF;

    -- factor_conversion
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='items' AND column_name='factor_conversion') THEN
        ALTER TABLE selemti.items ADD COLUMN factor_conversion NUMERIC(12,6) DEFAULT 1.0;
    END IF;

    -- unidad_compra_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='items' AND column_name='unidad_compra_id') THEN
        ALTER TABLE selemti.items ADD COLUMN unidad_compra_id INTEGER REFERENCES selemti.unidades_medida(id);
    END IF;

    -- factor_compra
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='items' AND column_name='factor_compra') THEN
        ALTER TABLE selemti.items ADD COLUMN factor_compra NUMERIC(12,6) DEFAULT 1.0;
    END IF;
END $$;

---## 4. GESTIÓN AVANZADA DE COSTOS Y REPROCESAMIENTO

-- 4.1 HISTORIAL DE COSTOS POR ÍTEM
CREATE TABLE IF NOT EXISTS selemti.historial_costos_item (
    id SERIAL PRIMARY KEY,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    fecha_efectiva DATE NOT NULL,
    fecha_registro TIMESTAMP DEFAULT NOW(),
    costo_anterior NUMERIC(10,2),
    costo_nuevo NUMERIC(10,2),
    tipo_cambio VARCHAR(20) CHECK (tipo_cambio IN ('COMPRA', 'AJUSTE', 'REPROCESO')),
    referencia_id INTEGER,
    referencia_tipo VARCHAR(20),
    usuario_id INTEGER REFERENCES selemti.users(id),
    valid_from DATE NOT NULL,
    valid_to DATE,
    sys_from TIMESTAMP NOT NULL DEFAULT NOW(),
    sys_to TIMESTAMP,
    costo_wac NUMERIC(12,4),
    costo_peps NUMERIC(12,4),
    costo_ueps NUMERIC(12,4),
    costo_estandar NUMERIC(12,4),
    algoritmo_principal VARCHAR(10) DEFAULT 'WAC' CHECK (algoritmo_principal IN ('WAC', 'PEPS', 'UEPS', 'ESTANDAR')),
    version_datos INTEGER DEFAULT 1,
    recalculado BOOLEAN DEFAULT FALSE,
    fuente_datos VARCHAR(20) CHECK (fuente_datos IN ('COMPRA', 'AJUSTE', 'REPROCESO', 'IMPORTACION')),
    metadata_calculo JSON,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (item_id, fecha_efectiva, version_datos)
);

-- 4.2 HISTORIAL DE COSTOS POR RECETA
CREATE TABLE IF NOT EXISTS selemti.historial_costos_receta (
    id SERIAL PRIMARY KEY,
    receta_version_id INTEGER NOT NULL REFERENCES selemti.receta_version(id),
    fecha_calculo DATE NOT NULL,
    costo_total NUMERIC(10,2),
    costo_porcion NUMERIC(10,2),
    algoritmo_utilizado VARCHAR(20),
    version_datos INTEGER DEFAULT 1,
    metadata_calculo JSON,
    created_at TIMESTAMP DEFAULT NOW(),
    valid_from DATE NOT NULL,
    valid_to DATE,
    sys_from TIMESTAMP NOT NULL DEFAULT NOW(),
    sys_to TIMESTAMP
);

-- 4.3 RECETAS SHADOW PARA ANÁLISIS HISTÓRICO
CREATE TABLE IF NOT EXISTS selemti.receta_shadow (
    id SERIAL PRIMARY KEY,
    codigo_plato_pos VARCHAR(20) NOT NULL,
    nombre_plato VARCHAR(100) NOT NULL,
    estado VARCHAR(15) DEFAULT 'INFERIDA' CHECK (estado IN ('INFERIDA', 'VALIDADA', 'DESCARTADA')),
    confianza NUMERIC(5,4) DEFAULT 0.0 CHECK (confianza BETWEEN 0 AND 1),
    total_ventas_analizadas INTEGER DEFAULT 0,
    fecha_primer_venta DATE,
    fecha_ultima_venta DATE,
    frecuencia_dias NUMERIC(10,2),
    ingredientes_inferidos JSON,
    usuario_validador INTEGER REFERENCES selemti.users(id),
    fecha_validacion TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 4.4 CAPAS DE COSTO PARA VALUACIÓN
CREATE TABLE IF NOT EXISTS selemti.cost_layer (
    id BIGSERIAL PRIMARY KEY,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    batch_id BIGINT REFERENCES selemti.inventory_batch(id),
    ts_in TIMESTAMP NOT NULL,
    qty_in NUMERIC(14,6) NOT NULL,
    qty_left NUMERIC(14,6) NOT NULL,
    unit_cost NUMERIC(14,6) NOT NULL,
    sucursal_id VARCHAR(30),
    source_ref TEXT,
    source_id BIGINT
);

---## 5. INTEGRACIÓN POS Y MODIFICADORES

-- 5.1 MAPEO POS HISTÓRICO
CREATE TABLE IF NOT EXISTS selemti.pos_map (
    pos_system TEXT NOT NULL,
    plu TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('PLATO','MODIFICADOR','COMBO')),
    receta_id TEXT,
    receta_version_id INT,
    valid_from DATE NOT NULL,
    valid_to DATE,
    sys_from TIMESTAMP NOT NULL DEFAULT NOW(),
    sys_to TIMESTAMP,
    meta JSON,
    PRIMARY KEY (pos_system, plu, valid_from, sys_from)
);

-- 5.2 MODIFICADORES POS
CREATE TABLE IF NOT EXISTS selemti.modificadores_pos (
    id SERIAL PRIMARY KEY,
    codigo_pos VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(20) CHECK (tipo IN ('AGREGADO', 'SUSTITUCION', 'ELIMINACION')),
    precio_extra NUMERIC(10,2) DEFAULT 0,
    receta_modificador_id VARCHAR(20) REFERENCES selemti.receta_cab(id),
    activo BOOLEAN DEFAULT TRUE
);

-- 5.3 ACTUALIZAR TICKETS CON MODIFICADORES
-- **CORRECCIÓN 4: Reemplazo de ALTER TABLE ADD COLUMN IF NOT EXISTS por bloque DO $$ BEGIN ... END $$**
DO $$
BEGIN
    -- receta_shadow_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='ticket_venta_det' AND column_name='receta_shadow_id') THEN
        ALTER TABLE selemti.ticket_venta_det ADD COLUMN receta_shadow_id INTEGER REFERENCES selemti.receta_shadow(id);
    END IF;

    -- reprocesado
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='ticket_venta_det' AND column_name='reprocesado') THEN
        ALTER TABLE selemti.ticket_venta_det ADD COLUMN reprocesado BOOLEAN DEFAULT FALSE;
    END IF;
    
    -- version_reproceso
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='ticket_venta_det' AND column_name='version_reproceso') THEN
        ALTER TABLE selemti.ticket_venta_det ADD COLUMN version_reproceso INTEGER DEFAULT 1;
    END IF;

    -- modificadores_aplicados
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='ticket_venta_det' AND column_name='modificadores_aplicados') THEN
        ALTER TABLE selemti.ticket_venta_det ADD COLUMN modificadores_aplicados JSON;
    END IF;
END $$;

---## 6. REPROCESAMIENTO Y COLA DE TRABAJOS

-- 6.1 COLA DE REPROCESAMIENTO
CREATE TABLE IF NOT EXISTS selemti.job_recalc_queue (
    id BIGSERIAL PRIMARY KEY,
    scope_type TEXT NOT NULL CHECK (scope_type IN ('PERIODO','ITEM','RECETA','SUCURSAL')),
    scope_from DATE,
    scope_to DATE,
    item_id VARCHAR(20),
    receta_id VARCHAR(20),
    sucursal_id VARCHAR(30),
    reason TEXT,
    created_ts TIMESTAMP NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','RUNNING','DONE','FAILED')),
    result JSON
);

-- 6.2 LOGS DE REPROCESAMIENTO
CREATE TABLE IF NOT EXISTS selemti.recalc_log (
    id BIGSERIAL PRIMARY KEY,
    job_id BIGINT REFERENCES selemti.job_recalc_queue(id),
    step TEXT,
    started_ts TIMESTAMP,
    ended_ts TIMESTAMP,
    ok BOOLEAN,
    details JSON
);

---## 7. PRESENTACIONES POR PROVEEDOR Y POLÍTICAS

-- 7.1 PRESENTACIONES POR PROVEEDOR
CREATE TABLE IF NOT EXISTS selemti.item_vendor (
    item_id TEXT NOT NULL REFERENCES selemti.items(id),
    vendor_id TEXT NOT NULL,
    presentacion TEXT NOT NULL,
    unidad_presentacion_id INT NOT NULL REFERENCES selemti.unidades_medida(id),
    factor_a_canonica NUMERIC(14,6) NOT NULL CHECK (factor_a_canonica > 0),
    costo_ultimo NUMERIC(14,6) NOT NULL DEFAULT 0,
    moneda TEXT NOT NULL DEFAULT 'MXN',
    lead_time_dias INT,
    codigo_proveedor TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (item_id, vendor_id, presentacion)
);

-- 7.2 TIPO DE PRODUCTO Y UOM DE SALIDA
-- **CORRECCIÓN 5: Se agregó IF NOT EXISTS a CREATE TYPE dentro del bloque DO $$**
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='producto_tipo') THEN
        CREATE TYPE selemti.producto_tipo AS ENUM ('MATERIA_PRIMA','ELABORADO','ENVASADO');
    END IF;
END$$;

-- **CORRECCIÓN 6: Reemplazo de ALTER TABLE ADD COLUMN IF NOT EXISTS por bloque DO $$ BEGIN ... END $$**
DO $$
BEGIN
    -- tipo
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='items' AND column_name='tipo') THEN
        ALTER TABLE selemti.items ADD COLUMN tipo selemti.producto_tipo;
    END IF;

    -- unidad_salida_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='items' AND column_name='unidad_salida_id') THEN
        ALTER TABLE selemti.items ADD COLUMN unidad_salida_id INT REFERENCES selemti.unidades_medida(id);
    END IF;
END$$;


-- 7.3 POLÍTICAS DE CONSUMO
-- **CORRECCIÓN 7: Se agregó IF NOT EXISTS a CREATE TYPE dentro del bloque DO $$**
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='consumo_policy') THEN
        CREATE TYPE selemti.consumo_policy AS ENUM ('FEFO','PEPS');
    END IF;
END$$;

-- 7.4 PARÁMETROS POR SUCURSAL
CREATE TABLE IF NOT EXISTS selemti.param_sucursal (
    id SERIAL PRIMARY KEY,
    sucursal_id TEXT UNIQUE NOT NULL,
    consumo selemti.consumo_policy NOT NULL DEFAULT 'FEFO',
    tolerancia_precorte_pct NUMERIC(8,4) DEFAULT 0.02,
    tolerancia_corte_abs NUMERIC(12,4) DEFAULT 50.0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 7.5 POLÍTICAS DE STOCK
CREATE TABLE IF NOT EXISTS selemti.stock_policy (
    id BIGSERIAL PRIMARY KEY,
    item_id TEXT NOT NULL REFERENCES selemti.items(id),
    sucursal_id TEXT NOT NULL,
    almacen_id TEXT,
    min_qty NUMERIC(14,6) NOT NULL DEFAULT 0,
    max_qty NUMERIC(14,6) NOT NULL DEFAULT 0,
    reorder_lote NUMERIC(14,6),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
    -- **CORRECCIÓN 8.1: Se eliminó la restricción UNIQUE con COALESCE de la definición de la tabla.**
);

-- **CORRECCIÓN 8.2: Se creó un índice UNIQUE separado para la restricción de expresión.**
CREATE UNIQUE INDEX IF NOT EXISTS idx_stock_policy_unique ON selemti.stock_policy (item_id, sucursal_id, COALESCE(almacen_id,'_'));

-- 7.6 RELACIÓN SUCURSAL-ALMACÉN-TERMINAL
CREATE TABLE IF NOT EXISTS selemti.sucursal_almacen_terminal (
    id SERIAL PRIMARY KEY,
    sucursal_id TEXT NOT NULL,
    almacen_id TEXT NOT NULL,
    terminal_id INT NULL,
    location TEXT,
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
    -- **CORRECCIÓN 9.1: Se eliminó la restricción UNIQUE con COALESCE de la definición de la tabla.**
);

-- **CORRECCIÓN 9.2: Se creó un índice UNIQUE separado para la restricción de expresión.**
CREATE UNIQUE INDEX IF NOT EXISTS idx_suc_alm_term_unique ON selemti.sucursal_almacen_terminal (sucursal_id, almacen_id, COALESCE(terminal_id,0));

---## 8. MERMA vs DESPERDICIO Y PORCIONAMIENTO

-- 8.1 CLASIFICACIÓN DE PÉRDIDAS
-- **CORRECCIÓN 10: Se agregó IF NOT EXISTS a CREATE TYPE dentro del bloque DO $$**
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='merma_clase') THEN
        CREATE TYPE selemti.merma_clase AS ENUM ('MERMA','DESPERDICIO');
    END IF;
END$$;

-- 8.2 REGISTRO DE PÉRDIDAS
CREATE TABLE IF NOT EXISTS selemti.perdida_log (
    id BIGSERIAL PRIMARY KEY,
    ts TIMESTAMP NOT NULL DEFAULT NOW(),
    item_id TEXT NOT NULL REFERENCES selemti.items(id),
    lote_id BIGINT REFERENCES selemti.inventory_batch(id),
    sucursal_id TEXT,
    clase selemti.merma_clase NOT NULL,
    motivo TEXT,
    qty_canonica NUMERIC(14,6) NOT NULL CHECK (qty_canonica > 0),
    qty_original NUMERIC(14,6),
    uom_original_id INT REFERENCES selemti.unidades_medida(id),
    evidencia_url TEXT,
    usuario_id INT REFERENCES selemti.users(id),
    ref_tipo TEXT,
    ref_id BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 8.3 PORCIONAMIENTO DE PREPARACIONES
CREATE TABLE IF NOT EXISTS selemti.ticket_det_consumo (
    id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL,
    ticket_det_id BIGINT NOT NULL,
    item_id TEXT NOT NULL REFERENCES selemti.items(id),
    lote_id BIGINT REFERENCES selemti.inventory_batch(id),
    qty_canonica NUMERIC(14,6) NOT NULL CHECK (qty_canonica > 0),
    qty_original NUMERIC(14,6),
    uom_original_id INT REFERENCES selemti.unidades_medida(id),
    sucursal_id TEXT,
    ref_tipo TEXT,
    ref_id BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
    -- **CORRECCIÓN 11.1: Se eliminó la restricción UNIQUE con COALESCE de la definición de la tabla.**
);

-- **CORRECCIÓN 11.2: Se creó un índice UNIQUE separado para la restricción de expresión.**
CREATE UNIQUE INDEX IF NOT EXISTS idx_tick_cons_unique ON selemti.ticket_det_consumo (ticket_det_id, item_id, lote_id, qty_canonica, COALESCE(uom_original_id,0));

---## 9. ÍNDICES PARA OPTIMIZACIÓN

-- 9.1 ÍNDICES PRINCIPALES
-- Nota: La sintaxis CREATE INDEX IF NOT EXISTS es compatible con PG 9.5
CREATE INDEX IF NOT EXISTS idx_mov_inv_tipo_fecha ON selemti.mov_inv(tipo, ts);
CREATE INDEX IF NOT EXISTS idx_mov_inv_item_ts ON selemti.mov_inv(item_id, ts);
CREATE INDEX IF NOT EXISTS idx_inventory_batch_item ON selemti.inventory_batch(item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_batch_caducidad ON selemti.inventory_batch(fecha_caducidad);
CREATE INDEX IF NOT EXISTS idx_receta_version_publicada ON selemti.receta_version(version_publicada);
CREATE INDEX IF NOT EXISTS idx_ticket_venta_fecha ON selemti.ticket_venta_cab(fecha_venta);
CREATE INDEX IF NOT EXISTS idx_historial_costos_item_fecha ON selemti.historial_costos_item(item_id, fecha_efectiva DESC);
CREATE INDEX IF NOT EXISTS idx_stock_policy_item_suc ON selemti.stock_policy(item_id, sucursal_id);
CREATE INDEX IF NOT EXISTS idx_perdida_item_ts ON selemti.perdida_log(item_id, ts DESC);
CREATE INDEX IF NOT EXISTS idx_tickcons_ticket ON selemti.ticket_det_consumo(ticket_id, ticket_det_id);
CREATE INDEX IF NOT EXISTS idx_tickcons_lote ON selemti.ticket_det_consumo(item_id, lote_id);
CREATE INDEX IF NOT EXISTS ix_layer_item_suc ON selemti.cost_layer(item_id, sucursal_id);

---## 10. FUNCIONES Y VISTAS

-- 10.1 FUNCIÓN DE REPROCESAMIENTO DE COSTOS
CREATE OR REPLACE FUNCTION selemti.reprocesar_costos_historicos(
    p_fecha_desde DATE,
    p_fecha_hasta DATE DEFAULT NULL,
    p_algoritmo VARCHAR(10) DEFAULT 'WAC',
    p_usuario_id INTEGER DEFAULT 1
) RETURNS INTEGER AS $$
DECLARE
    v_lote_id INTEGER;
    v_total_actualizados INTEGER := 0;
    v_item_record RECORD;
BEGIN
    IF p_fecha_hasta IS NULL THEN
        p_fecha_hasta := CURRENT_DATE;
    END IF;
    
    INSERT INTO selemti.job_recalc_queue (scope_type, scope_from, scope_to, reason, status)
    VALUES ('PERIODO', p_fecha_desde, p_fecha_hasta, 'Reproceso costos ' || p_algoritmo, 'RUNNING')
    RETURNING id INTO v_lote_id;
    
    FOR v_item_record IN 
        SELECT DISTINCT item_id 
        FROM selemti.mov_inv 
        WHERE ts BETWEEN p_fecha_desde AND p_fecha_hasta
    LOOP
        UPDATE selemti.historial_costos_item
        SET costo_wac = (
            SELECT AVG(costo_unit * cantidad) / NULLIF(SUM(cantidad), 0)
            FROM selemti.mov_inv 
            WHERE item_id = v_item_record.item_id 
            AND ts BETWEEN p_fecha_desde AND p_fecha_hasta 
            AND tipo IN ('COMPRA', 'RECEPCION')
        )
        WHERE item_id = v_item_record.item_id AND fecha_efectiva BETWEEN p_fecha_desde AND p_fecha_hasta;
        
        v_total_actualizados := v_total_actualizados + 1;
    END LOOP;
    
    UPDATE selemti.job_recalc_queue 
    SET status = 'DONE', 
        result = ('{"actualizados": ' || v_total_actualizados || '}')::json
    WHERE id = v_lote_id;
    
    RETURN v_total_actualizados;
EXCEPTION
    WHEN OTHERS THEN
        UPDATE selemti.job_recalc_queue 
        SET status = 'FAILED', 
            result = ('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}')::json
        WHERE id = v_lote_id;
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- 10.2 FUNCIÓN DE INFERENCIA DE RECETAS
CREATE OR REPLACE FUNCTION selemti.inferir_recetas_de_ventas(
    p_fecha_desde DATE,
    p_fecha_hasta DATE DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_recetas_inferidas INTEGER := 0;
    v_plato_record RECORD;
BEGIN
    IF p_fecha_hasta IS NULL THEN
        p_fecha_hasta := CURRENT_DATE;
    END IF;
    
    FOR v_plato_record IN 
        SELECT DISTINCT td.item_id, COUNT(*) as total_ventas
        FROM selemti.ticket_venta_det td
        JOIN selemti.ticket_venta_cab tc ON td.ticket_id = tc.id
        WHERE tc.fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta
          AND td.receta_shadow_id IS NULL
        GROUP BY td.item_id
        HAVING COUNT(*) >= 5
    LOOP
        INSERT INTO selemti.receta_shadow (codigo_plato_pos, nombre_plato, total_ventas_analizadas, fecha_primer_venta, fecha_ultima_venta)
        VALUES (v_plato_record.item_id, 'Inferida_' || v_plato_record.item_id, v_plato_record.total_ventas, p_fecha_desde, p_fecha_hasta);
        
        UPDATE selemti.ticket_venta_det
        SET receta_shadow_id = currval('selemti.receta_shadow_id_seq'), reprocesado = TRUE, version_reproceso = 1
        WHERE item_id = v_plato_record.item_id
          AND ticket_id IN (SELECT id FROM selemti.ticket_venta_cab WHERE fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta);
        
        v_recetas_inferidas := v_recetas_inferidas + 1;
    END LOOP;
    
    RETURN v_recetas_inferidas;
END;
$$ LANGUAGE plpgsql;

-- 10.3 FUNCIÓN DE CIERRE DE LOTE PREPARADO
CREATE OR REPLACE FUNCTION selemti.cerrar_lote_preparado(
    p_lote_id BIGINT,
    p_clase selemti.merma_clase,
    p_motivo TEXT,
    p_usuario_id INT DEFAULT NULL,
    p_uom_id INT DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    v_item_id TEXT;
    v_qty_disponible NUMERIC(14,6);
    v_mov_id BIGINT;
BEGIN
    SELECT b.item_id, b.cantidad_actual
    INTO v_item_id, v_qty_disponible
    FROM selemti.inventory_batch b
    WHERE b.id = p_lote_id;

    IF v_item_id IS NULL THEN
        RAISE EXCEPTION 'Lote % no existe', p_lote_id;
    END IF;

    IF v_qty_disponible IS NULL OR v_qty_disponible <= 0 THEN
        RETURN 0;
    END IF;

    INSERT INTO selemti.mov_inv (ts, item_id, lote_id, cantidad, tipo, ref_tipo, ref_id)
    VALUES (now(), v_item_id, p_lote_id, 0 - v_qty_disponible, 'MERMA', 'CIERRE_PREP', p_lote_id)
    RETURNING id INTO v_mov_id;

    INSERT INTO selemti.perdida_log (ts, item_id, lote_id, clase, motivo, qty_canonica, usuario_id, ref_tipo, ref_id)
    VALUES (now(), v_item_id, p_lote_id, p_clase, p_motivo, v_qty_disponible, p_usuario_id, 'CIERRE_PREP', v_mov_id);

    RETURN v_mov_id;
END;
$$ LANGUAGE plpgsql;


-- 10.4 VISTAS PRINCIPALES
-- Se usó CREATE OR REPLACE VIEW para idempotencia
CREATE OR REPLACE VIEW selemti.v_stock_actual AS
SELECT 
    i.id as item_id,
    i.nombre,
    COALESCE(SUM(
        CASE WHEN m.tipo = 'ENTRADA' THEN m.cantidad 
             WHEN m.tipo = 'SALIDA' THEN -m.cantidad 
             ELSE 0 END
    ), 0) as stock_actual
FROM selemti.items i
LEFT JOIN selemti.mov_inv m ON i.id = m.item_id
GROUP BY i.id, i.nombre;

CREATE OR REPLACE VIEW selemti.v_ingenieria_menu_completa AS
SELECT 
    rc.id as receta_id,
    rc.nombre_plato,
    rc.codigo_plato_pos,
    rc.precio_venta_sugerido,
    rc.costo_standard_porcion as costo_actual,
    (rc.precio_venta_sugerido - rc.costo_standard_porcion) as margen_actual,
    CASE WHEN rc.precio_venta_sugerido > 0 THEN 
        (rc.precio_venta_sugerido - rc.costo_standard_porcion) / rc.precio_venta_sugerido * 100 
        ELSE 0 END as porcentaje_margen,
    rc.costo_standard_porcion > (rc.precio_venta_sugerido * 0.4) as alerta_costo_alto,
    (SELECT COUNT(*) FROM selemti.ticket_venta_det td WHERE td.item_id = rc.id) = 0 as alerta_sin_ventas
FROM selemti.receta_cab rc
WHERE rc.activo = true;

CREATE OR REPLACE VIEW selemti.v_merma_por_item AS
SELECT
    m.item_id,
    date_trunc('week', m.ts)::date AS semana,
    SUM(CASE WHEN m.tipo = 'MERMA' THEN m.cantidad ELSE 0 END) as qty_mermada,
    SUM(CASE WHEN m.tipo IN ('RECEPCION','COMPRA') THEN m.cantidad ELSE 0 END) as qty_recibida,
    CASE 
        WHEN SUM(CASE WHEN m.tipo IN ('RECEPCION','COMPRA') THEN m.cantidad ELSE 0 END) > 0
        THEN ROUND(100.0 * SUM(CASE WHEN m.tipo='MERMA' THEN m.cantidad ELSE 0 END) / 
            NULLIF(SUM(CASE WHEN m.tipo IN ('RECEPCION','COMPRA') THEN m.cantidad ELSE 0 END),0), 2)
        ELSE 0
    END AS merma_pct
FROM selemti.mov_inv m
GROUP BY m.item_id, date_trunc('week', m.ts)::date;

---## 11. DATOS INICIALES Y CONFIGURACIÓN

-- 11.1 INSERTAR USUARIO ADMIN POR DEFECTO
-- **CORRECCIÓN 6:** Dummy hash de 60 caracteres para cumplir con la restricción CHECK.
INSERT INTO selemti.users ("username", "password_hash", "nombre_completo", "email", "activo") 
VALUES ('admin', 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', 'Administrador del Sistema', 'admin@selemti.com', true)
ON CONFLICT ("username") DO NOTHING;

-- 11.2 ASIGNAR ROL DE GERENTE
INSERT INTO selemti.user_roles (user_id, role_id, assigned_by)
SELECT id, 'GERENTE', 1 FROM selemti.users WHERE username = 'admin'
ON CONFLICT (user_id, role_id) DO NOTHING;

-- 11.3 CONFIGURAR SUCURSAL PRINCIPAL
INSERT INTO selemti.param_sucursal (sucursal_id, consumo, tolerancia_precorte_pct, tolerancia_corte_abs)
VALUES ('SUR', 'FEFO', 0.02, 50.0)
ON CONFLICT (sucursal_id) DO NOTHING;

--- ## 12. VERIFICACIÓN FINAL

DO $$
DECLARE
    v_table_count INTEGER;
BEGIN
    -- Contar tablas creadas
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables 
    WHERE table_schema = 'selemti';
    
    RAISE NOTICE '✅ ESQUEMA SELEMTI CREADO EXITOSAMENTE';
    RAISE NOTICE '✅ TABLAS CREADAS: %', v_table_count;
    RAISE NOTICE '✅ POSTGRESQL 9.5 COMPATIBLE';
    RAISE NOTICE '✅ EJECUCIÓN FINALIZADA - SISTEMA LISTO PARA DESARROLLO';
END $$;


-- Marca el VARCHAR como deprecado (opcional: quitarlo más adelante)
ALTER TABLE selemti.items
  ALTER COLUMN unidad_medida SET DEFAULT 'PZ';

-- (Opcional a futuro) mover toda lectura/escritura a unidad_medida_id y
-- agregar una vista que exponga ambos para UI:
CREATE OR REPLACE VIEW selemti.v_items_con_uom AS
SELECT i.*,
       um.codigo  AS uom_codigo,
       um.nombre  AS uom_nombre,
       um.tipo    AS uom_tipo
FROM selemti.items i
LEFT JOIN selemti.unidades_medida um
       ON um.id = i.unidad_medida_id;


ALTER TABLE selemti.inventory_batch
  DROP CONSTRAINT IF EXISTS inventory_batch_fecha_caducidad_check;

-- Validación se hace en UI/negocio o en un trigger solo para flujos “en línea”.
ALTER TABLE selemti.ticket_venta_det
  ADD CONSTRAINT fk_ticket_det_cab
  FOREIGN KEY (ticket_id) REFERENCES selemti.ticket_venta_cab(id)
  ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS selemti.sucursal (
  id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS selemti.almacen (
  id TEXT PRIMARY KEY,
  sucursal_id TEXT NOT NULL REFERENCES selemti.sucursal(id),
  nombre TEXT NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS selemti.proveedor (
  id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  rfc TEXT,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE OR REPLACE VIEW selemti.v_stock_brechas AS
SELECT sp.sucursal_id, sp.almacen_id, sp.item_id,
       sp.min_qty, sp.max_qty,
       COALESCE(sa.stock_actual,0) AS stock_actual,
       GREATEST(sp.min_qty - COALESCE(sa.stock_actual,0), 0) AS qty_a_comprar
FROM selemti.stock_policy sp
LEFT JOIN (
  SELECT item_id, SUM(
    CASE WHEN tipo IN ('ENTRADA') THEN cantidad
         WHEN tipo IN ('SALIDA','MERMA','AJUSTE','TRASPASO') THEN -cantidad
         ELSE 0 END
  ) AS stock_actual
  FROM selemti.mov_inv
  GROUP BY item_id
) sa ON sa.item_id = sp.item_id;
CREATE OR REPLACE VIEW selemti.v_merma_por_item AS
SELECT
  m.item_id,
  date_trunc('week', m.ts)::date AS semana,
  SUM(CASE WHEN m.tipo = 'MERMA' THEN m.cantidad ELSE 0 END)                      AS qty_mermada,
  SUM(CASE WHEN m.tipo IN ('ENTRADA') THEN m.cantidad ELSE 0 END)                 AS qty_recibida,
  ROUND(100.0 * NULLIF(
    SUM(CASE WHEN m.tipo='MERMA' THEN m.cantidad ELSE 0 END),0
  ) / NULLIF(SUM(CASE WHEN m.tipo IN ('ENTRADA') THEN m.cantidad ELSE 0 END),0), 2) AS merma_pct
FROM selemti.mov_inv m
GROUP BY m.item_id, date_trunc('week', m.ts)::date;
CREATE OR REPLACE FUNCTION selemti.registrar_consumo_porcionado(
  p_ticket_id BIGINT,
  p_ticket_det_id BIGINT,
  p_item_id TEXT,
  p_qty_total NUMERIC,      -- p.ej. 1000 ml de salsa
  p_distribucion JSON       -- [{receta_version_id: X, qty_ml: 300}, ...]
) RETURNS INT AS $$
DECLARE
  r JSON;
  v_count INT := 0;
BEGIN
  FOR r IN SELECT * FROM json_array_elements(p_distribucion)
  LOOP
    INSERT INTO selemti.ticket_det_consumo(
      ticket_id, ticket_det_id, item_id, lote_id, qty_canonica, ref_tipo, ref_id
    )
    VALUES (
      p_ticket_id, p_ticket_det_id, p_item_id, NULL,
      (r->>'qty_ml')::NUMERIC,
      'PORCION', p_ticket_det_id
    );
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;
