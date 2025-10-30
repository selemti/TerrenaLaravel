-- =====================================================
-- SCRIPT 02: MÓDULO DE INVENTARIO (8 TABLAS)
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- SECUENCIAS PARA INVENTARIO
CREATE SEQUENCE selemti.recepcion_daily_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE selemti.traspaso_daily_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE selemti.ajuste_daily_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE selemti.conteo_daily_seq START WITH 1 INCREMENT BY 1;

-- 1. RECEPCION_CAB
CREATE TABLE selemti.recepcion_cab (
    id SERIAL PRIMARY KEY,
    numero_recepcion VARCHAR(20) UNIQUE NOT NULL DEFAULT 'REC-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD-') || LPAD(NEXTVAL('selemti.recepcion_daily_seq')::TEXT, 4, '0'),
    proveedor_id VARCHAR(20) NOT NULL, -- FK se agregará después de crear tabla proveedores
    fecha_recepcion TIMESTAMP NOT NULL DEFAULT NOW(),
    tipo_documento VARCHAR(10) CHECK (tipo_documento IN ('FACTURA', 'RECIBO', 'NOTA', 'GUIA')),
    numero_documento VARCHAR(50),
    total_items INTEGER NOT NULL CHECK (total_items > 0),
    peso_total_kg NUMERIC(10,3) CHECK (peso_total_kg > 0),
    temperatura_ambiente NUMERIC(5,2) CHECK (temperatura_ambiente BETWEEN -10 AND 50),
    condicion_transporte VARCHAR(20) CHECK (condicion_transporte IN ('OPTIMA', 'ACEPTABLE', 'DEFICIENTE')),
    observaciones_generales TEXT,
    estado VARCHAR(15) DEFAULT 'BORRADOR' CHECK (estado IN ('BORRADOR', 'RECIBIDO', 'VERIFICADO', 'APROBADO', 'RECHAZADO', 'CANCELADO')),
    usuario_receptor INTEGER REFERENCES selemti.users(id),
    usuario_verificador INTEGER REFERENCES selemti.users(id),
    fecha_verificacion TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (CASE WHEN estado IN ('VERIFICADO', 'APROBADO') THEN usuario_verificador IS NOT NULL ELSE TRUE END),
    CHECK (CASE WHEN tipo_documento IS NOT NULL THEN numero_documento IS NOT NULL ELSE TRUE END),
    CHECK (fecha_verificacion IS NULL OR fecha_verificacion >= fecha_recepcion)
);

-- 2. RECEPCION_DET
CREATE TABLE selemti.recepcion_det (
    id SERIAL PRIMARY KEY,
    recepcion_id INTEGER NOT NULL REFERENCES selemti.recepcion_cab(id) ON DELETE CASCADE,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    lote_proveedor VARCHAR(50) NOT NULL CHECK (LENGTH(lote_proveedor) BETWEEN 1 AND 50),
    fecha_elaboracion DATE,
    fecha_caducidad DATE NOT NULL CHECK (fecha_caducidad >= CURRENT_DATE),
    cantidad_declarada NUMERIC(10,3) NOT NULL CHECK (cantidad_declarada > 0),
    cantidad_recibida NUMERIC(10,3) NOT NULL CHECK (cantidad_recibida > 0),
    cantidad_rechazada NUMERIC(10,3) DEFAULT 0 CHECK (cantidad_rechazada >= 0),
    motivo_rechazo VARCHAR(50) CHECK (motivo_rechazo IN ('CALIDAD', 'CADUCIDAD', 'TEMPERATURA', 'DOCUMENTACION', 'DANADO', 'OTRO')),
    temperatura_recepcion NUMERIC(5,2) NOT NULL CHECK (temperatura_recepcion BETWEEN -30 AND 60),
    humedad_relativa NUMERIC(5,2) CHECK (humedad_relativa BETWEEN 0 AND 100),
    condiciones_empaque VARCHAR(20) CHECK (condiciones_empaque IN ('OPTIMO', 'DANADO_LEVE', 'DANADO_GRAVE')),
    certificado_calidad_url VARCHAR(500),
    numero_lote_interno VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (cantidad_recibida + cantidad_rechazada = cantidad_declarada),
    CHECK (CASE WHEN cantidad_rechazada > 0 THEN motivo_rechazo IS NOT NULL ELSE TRUE END),
    CHECK (CASE WHEN fecha_elaboracion IS NOT NULL THEN fecha_elaboracion <= fecha_caducidad ELSE TRUE END),
    
    CHECK (CASE 
        WHEN (SELECT perishable FROM selemti.items WHERE id = item_id) = true 
        THEN temperatura_recepcion IS NOT NULL 
        ELSE TRUE 
    END)
);

-- 3. TRASPASO_CAB
CREATE TABLE selemti.traspaso_cab (
    id SERIAL PRIMARY KEY,
    numero_traspaso VARCHAR(20) UNIQUE NOT NULL DEFAULT 'TRAS-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD-') || LPAD(NEXTVAL('selemti.traspaso_daily_seq')::TEXT, 4, '0'),
    sucursal_origen VARCHAR(10) NOT NULL CHECK (sucursal_origen IN ('SUR', 'NORTE', 'CENTRO')),
    sucursal_destino VARCHAR(10) NOT NULL CHECK (sucursal_destino IN ('SUR', 'NORTE', 'CENTRO')),
    fecha_solicitud TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_despacho TIMESTAMP,
    fecha_recepcion TIMESTAMP,
    tipo_traspaso VARCHAR(15) CHECK (tipo_traspaso IN ('NORMAL', 'URGENTE', 'CONSOLIDADO')),
    estado VARCHAR(15) DEFAULT 'SOLICITADO' CHECK (estado IN ('SOLICITADO', 'PREPARADO', 'DESPACHADO', 'RECIBIDO', 'VERIFICADO', 'RECHAZADO', 'CANCELADO')),
    peso_total NUMERIC(10,3) CHECK (peso_total >= 0),
    volumen_total NUMERIC(10,3) CHECK (volumen_total >= 0),
    condiciones_transporte VARCHAR(500),
    usuario_solicitante INTEGER REFERENCES selemti.users(id),
    usuario_preparador INTEGER REFERENCES selemti.users(id),
    usuario_despachador INTEGER REFERENCES selemti.users(id),
    usuario_receptor INTEGER REFERENCES selemti.users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (sucursal_origen != sucursal_destino),
    CHECK (fecha_despacho IS NULL OR fecha_despacho >= fecha_solicitud),
    CHECK (fecha_recepcion IS NULL OR fecha_recepcion >= fecha_despacho)
);

-- 4. TRASPASO_DET
CREATE TABLE selemti.traspaso_det (
    id SERIAL PRIMARY KEY,
    traspaso_id INTEGER NOT NULL REFERENCES selemti.traspaso_cab(id) ON DELETE CASCADE,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    inventory_batch_id INTEGER REFERENCES selemti.inventory_batch(id),
    cantidad_solicitada NUMERIC(10,3) NOT NULL CHECK (cantidad_solicitada > 0),
    cantidad_despachada NUMERIC(10,3) NOT NULL CHECK (cantidad_despachada >= 0),
    cantidad_recibida NUMERIC(10,3) CHECK (cantidad_recibida >= 0),
    diferencia NUMERIC(10,3),
    motivo_diferencia VARCHAR(100),
    estado_item VARCHAR(15) DEFAULT 'SOLICITADO' CHECK (estado_item IN ('SOLICITADO', 'PREPARADO', 'DESPACHADO', 'RECIBIDO', 'RECHAZADO')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (cantidad_despachada <= cantidad_solicitada),
    CHECK (CASE WHEN cantidad_recibida IS NOT NULL THEN estado_item IN ('RECIBIDO', 'RECHAZADO') ELSE TRUE END)
);

-- 5. AJUSTE_INV_CAB
CREATE TABLE selemti.ajuste_inv_cab (
    id SERIAL PRIMARY KEY,
    numero_ajuste VARCHAR(20) UNIQUE NOT NULL DEFAULT 'AJUS-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD-') || LPAD(NEXTVAL('selemti.ajuste_daily_seq')::TEXT, 4, '0'),
    tipo_ajuste VARCHAR(15) NOT NULL CHECK (tipo_ajuste IN ('FISICO', 'MERMA', 'ROBO', 'DONACION', 'CADUCIDAD', 'OTRO')),
    fecha_ajuste TIMESTAMP NOT NULL DEFAULT NOW(),
    sucursal_id VARCHAR(10) NOT NULL CHECK (sucursal_id IN ('SUR', 'NORTE', 'CENTRO')),
    motivo TEXT NOT NULL CHECK (LENGTH(motivo) >= 10),
    total_items INTEGER NOT NULL CHECK (total_items > 0),
    valor_total_ajuste NUMERIC(12,2) CHECK (valor_total_ajuste >= 0),
    estado VARCHAR(15) DEFAULT 'BORRADOR' CHECK (estado IN ('BORRADOR', 'APLICADO', 'APROBADO', 'RECHAZADO')),
    usuario_solicitante INTEGER REFERENCES selemti.users(id),
    usuario_aprobador INTEGER REFERENCES selemti.users(id),
    fecha_aprobacion TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (CASE WHEN estado = 'APROBADO' THEN usuario_aprobador IS NOT NULL ELSE TRUE END)
);

-- 6. AJUSTE_INV_DET
CREATE TABLE selemti.ajuste_inv_det (
    id SERIAL PRIMARY KEY,
    ajuste_id INTEGER NOT NULL REFERENCES selemti.ajuste_inv_cab(id) ON DELETE CASCADE,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    inventory_batch_id INTEGER REFERENCES selemti.inventory_batch(id),
    tipo_movimiento CHAR(1) NOT NULL CHECK (tipo_movimiento IN ('E', 'S')),
    cantidad NUMERIC(10,3) NOT NULL CHECK (cantidad > 0),
    costo_unitario NUMERIC(10,2) NOT NULL CHECK (costo_unitario >= 0),
    valor_ajuste NUMERIC(12,2),
    ubicacion_id VARCHAR(10) NOT NULL CHECK (ubicacion_id LIKE 'UBIC-%'),
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (CASE 
        WHEN (SELECT perishable FROM selemti.items WHERE id = item_id) = true 
        THEN inventory_batch_id IS NOT NULL 
        ELSE TRUE 
    END)
);

-- 7. CONTEO_FISICO_CAB
CREATE TABLE selemti.conteo_fisico_cab (
    id SERIAL PRIMARY KEY,
    numero_conteo VARCHAR(20) UNIQUE NOT NULL DEFAULT 'CONT-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD-') || LPAD(NEXTVAL('selemti.conteo_daily_seq')::TEXT, 4, '0'),
    tipo_conteo VARCHAR(15) NOT NULL CHECK (tipo_conteo IN ('CICLICO', 'FISICO', 'SORPRESA')),
    fecha_conteo DATE NOT NULL DEFAULT CURRENT_DATE,
    sucursal_id VARCHAR(10) NOT NULL CHECK (sucursal_id IN ('SUR', 'NORTE', 'CENTRO')),
    ubicacion_id VARCHAR(10) NOT NULL CHECK (ubicacion_id LIKE 'UBIC-%'),
    estado VARCHAR(15) DEFAULT 'EN_PROGRESO' CHECK (estado IN ('EN_PROGRESO', 'COMPLETADO', 'AJUSTADO', 'CERRADO')),
    total_items INTEGER NOT NULL CHECK (total_items > 0),
    items_contados INTEGER DEFAULT 0 CHECK (items_contados >= 0),
    precision_global NUMERIC(5,2) CHECK (precision_global BETWEEN 0 AND 100),
    usuario_responsable INTEGER REFERENCES selemti.users(id),
    fecha_cierre TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (items_contados <= total_items),
    CHECK (fecha_cierre IS NULL OR fecha_cierre >= fecha_conteo)
);

-- 8. CONTEO_FISICO_DET
CREATE TABLE selemti.conteo_fisico_det (
    id SERIAL PRIMARY KEY,
    conteo_id INTEGER NOT NULL REFERENCES selemti.conteo_fisico_cab(id) ON DELETE CASCADE,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    inventory_batch_id INTEGER REFERENCES selemti.inventory_batch(id),
    stock_sistema NUMERIC(10,3) NOT NULL CHECK (stock_sistema >= 0),
    stock_fisico NUMERIC(10,3) NOT NULL CHECK (stock_fisico >= 0),
    diferencia NUMERIC(10,3),
    porcentaje_diferencia NUMERIC(5,2),
    motivo_diferencia VARCHAR(100),
    contador_1 NUMERIC(10,3),
    contador_2 NUMERIC(10,3),
    usuario_contador INTEGER REFERENCES selemti.users(id),
    fecha_conteo TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

RAISE NOTICE 'Script 02 (Módulo Inventario - 8 tablas) ejecutado exitosamente';