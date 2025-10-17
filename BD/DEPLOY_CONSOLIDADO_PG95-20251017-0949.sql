-- DEPLOY CONSOLIDADO PG95
-- Fecha: 10/17/2025 09:49:04
SET client_min_messages TO warning;
SET search_path TO selemti, public;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'selemti') THEN EXECUTE 'CREATE SCHEMA selemti'; END IF; END $$;

\n-- BEGIN 00_esquema_selemti.sql\n
-- =====================================================
-- SCRIPT 00: CREACIÃ“N DE ESQUEMA Y PERMISOS
-- Base de datos: pos (PostgreSQL 9.5)
-- Esquema: selemti
-- =====================================================

\set ON_ERROR_STOP on

-- 1. CREAR ESQUEMA SI NO EXISTE
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

-- 2. CREAR USUARIO DEDICADO
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'selemti_user') THEN
        CREATE USER selemti_user WITH PASSWORD 'selemti_password_2024';
        RAISE NOTICE 'Usuario selemti_user creado exitosamente';
    ELSE
        RAISE NOTICE 'Usuario selemti_user ya existe';
    END IF;
END
$$;

-- 3. OTORGAR PERMISOS
GRANT USAGE ON SCHEMA selemti TO selemti_user;
GRANT CREATE ON SCHEMA selemti TO selemti_user;

-- 4. PERMISOS DE LECTURA ENTRE ESQUEMAS
GRANT USAGE ON SCHEMA public TO selemti_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO selemti_user;

-- 5. CONFIGURAR SEARCH PATH
ALTER USER selemti_user SET search_path = 'selemti, public';

RAISE NOTICE 'Script 00 ejecutado exitosamente';
\n-- END 00_esquema_selemti.sql\n
\n-- BEGIN 01_tablas_maestras.sql\n
-- =====================================================
-- SCRIPT 01: TABLAS MAESTRAS BASE
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- 1. TABLA DE USUARIOS
CREATE TABLE selemti.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL CHECK (LENGTH(username) >= 3),
    password_hash VARCHAR(255) NOT NULL CHECK (LENGTH(password_hash) = 60),
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

-- 2. TABLA DE ROLES DE USUARIO
CREATE TABLE selemti.user_roles (
    user_id INTEGER REFERENCES selemti.users(id) ON DELETE CASCADE,
    role_id VARCHAR(20) CHECK (role_id IN ('GERENTE', 'CHEF', 'ALMACEN', 'CAJERO', 'AUDITOR', 'SISTEMA')),
    assigned_at TIMESTAMP DEFAULT NOW(),
    assigned_by INTEGER REFERENCES selemti.users(id),
    PRIMARY KEY (user_id, role_id)
);

COMMENT ON TABLE selemti.user_roles IS 'AsignaciÃ³n de roles a usuarios (RBAC)';

-- 3. TABLA MAESTRA DE ÃTEMS
CREATE TABLE selemti.items (
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

COMMENT ON TABLE selemti.items IS 'Maestro de todos los Ã­tems del sistema (insumos, productos terminados, categorÃ­as, ubicaciones)';

-- 4. TABLA DE LOTES DE INVENTARIO
CREATE TABLE selemti.inventory_batch (
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

COMMENT ON TABLE selemti.inventory_batch IS 'Control de lotes para trazabilidad APPCC';

-- 5. TABLA DE MOVIMIENTOS DE INVENTARIO (KARDEX)
CREATE TABLE selemti.mov_inv (
    id SERIAL PRIMARY KEY,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    inventory_batch_id INTEGER REFERENCES selemti.inventory_batch(id),
    tipo_movimiento CHAR(1) NOT NULL CHECK (tipo_movimiento IN ('E', 'S')),
    cantidad NUMERIC(10,3) NOT NULL CHECK (cantidad > 0),
    costo_unitario NUMERIC(10,2) NOT NULL CHECK (costo_unitario >= 0),
    fecha_movimiento TIMESTAMP NOT NULL DEFAULT NOW(),
    referencia_tipo VARCHAR(20) NOT NULL CHECK (referencia_tipo IN ('RECEPCION', 'VENTA', 'AJUSTE', 'TRASPASO', 'PRODUCCION', 'MERMA', 'INICIAL')),
    referencia_id INTEGER NOT NULL CHECK (referencia_id > 0),
    ubicacion_id VARCHAR(10) NOT NULL CHECK (ubicacion_id LIKE 'UBIC-%'),
    usuario_id INTEGER NOT NULL CHECK (usuario_id > 0),
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (CASE 
        WHEN (SELECT perishable FROM selemti.items WHERE id = item_id) = true 
        THEN inventory_batch_id IS NOT NULL 
        ELSE TRUE 
    END)
);

COMMENT ON TABLE selemti.mov_inv IS 'Kardex - Libro mayor de inventario. Cada movimiento genera un registro aquÃ­';

-- 6. TABLA DE AUDITORÃA
CREATE TABLE selemti.audit_log (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT NOW(),
    user_id INTEGER REFERENCES selemti.users(id),
    action_type VARCHAR(20) NOT NULL CHECK (action_type IN ('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'APPROVE', 'REJECT')),
    table_name VARCHAR(50) NOT NULL,
    record_id VARCHAR(100),
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN NOT NULL,
    error_message TEXT
);

COMMENT ON TABLE selemti.audit_log IS 'Registro completo de auditorÃ­a para cumplimiento APPCC y seguridad';

-- 7. TABLA DE CÃ“DIGOS DE ERROR
CREATE TABLE selemti.error_codes (
    code VARCHAR(10) PRIMARY KEY CHECK (code ~ '^[A-Z]{3}-[0-9]{3}$'),
    category VARCHAR(20) NOT NULL CHECK (category IN ('VALIDATION', 'BUSINESS', 'SECURITY', 'SYSTEM', 'INTEGRATION')),
    severity VARCHAR(10) NOT NULL CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    message_template TEXT NOT NULL,
    description TEXT,
    recovery_instructions TEXT
);

-- INSERTAR CÃ“DIGOS DE ERROR ESTÃNDAR
INSERT INTO selemti.error_codes VALUES 
('INV-001', 'BUSINESS', 'HIGH', 'Stock insuficiente para el Ã­tem %s. Stock actual: %s, requerido: %s', 'Intento de movimiento que causarÃ­a stock negativo', 'Verificar inventario fÃ­sico o recibir mercancÃ­a'),
('INV-002', 'BUSINESS', 'CRITICAL', 'Lote %s estÃ¡ bloqueado por motivo: %s', 'Intento de usar lote con estado BLOQUEADO o RECALL', 'Contactar al auditor APPCC para liberar el lote'),
('SEC-001', 'SECURITY', 'HIGH', 'Intento de acceso no autorizado al recurso %s por usuario %s', 'ViolaciÃ³n de control de acceso RBAC', 'Verificar asignaciÃ³n de roles y permisos');

RAISE NOTICE 'Script 01 (Tablas maestras) ejecutado exitosamente';
\n-- END 01_tablas_maestras.sql\n
\n-- BEGIN 02_modulo_inventario.sql\n
-- =====================================================
-- SCRIPT 02: MÃ“DULO DE INVENTARIO (8 TABLAS)
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
    proveedor_id VARCHAR(20) NOT NULL, -- FK se agregarÃ¡ despuÃ©s de crear tabla proveedores
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

RAISE NOTICE 'Script 02 (MÃ³dulo Inventario - 8 tablas) ejecutado exitosamente';
\n-- END 02_modulo_inventario.sql\n
\n-- BEGIN 03_modulo_recetas.sql\n
-- =====================================================
-- SCRIPT 03: MÃ“DULO DE RECETAS/PRODUCCIÃ“N (6 TABLAS)
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- SECUENCIAS PARA RECETAS/PRODUCCIÃ“N
CREATE SEQUENCE selemti.op_daily_seq START WITH 1 INCREMENT BY 1;

-- 9. RECETA_CAB
CREATE TABLE selemti.receta_cab (
    id VARCHAR(20) PRIMARY KEY CHECK (id ~ '^REC-[A-Z0-9\-]{1,15}$'),
    codigo_plato_pos VARCHAR(20) UNIQUE NOT NULL,
    nombre_plato VARCHAR(100) NOT NULL,
    categoria_cocina VARCHAR(20) CHECK (categoria_cocina IN ('ENTRADA', 'PLATO_FUERTE', 'POSTRE', 'BEBIDA', 'ACOMPANAMIENTO', 'BOCADILLO')),
    tipo_preparacion VARCHAR(20) CHECK (tipo_preparacion IN ('FRIA', 'CALIENTE', 'MIXTA')),
    tiempo_preparacion_min INTEGER CHECK (tiempo_preparacion_min > 0),
    rendimiento_porciones INTEGER NOT NULL CHECK (rendimiento_porciones > 0),
    instrucciones_generales TEXT,
    alergenos TEXT,
    nivel_dificultad VARCHAR(10) CHECK (nivel_dificultad IN ('BAJA', 'MEDIA', 'ALTA')),
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT NOW(),
    usuario_creador INTEGER REFERENCES selemti.users(id),
    version_actual INTEGER DEFAULT 1,
    costo_standard_porcion NUMERIC(8,2) CHECK (costo_standard_porcion >= 0),
    precio_venta_sugerido NUMERIC(8,2) CHECK (precio_venta_sugerido >= 0),
    
    CHECK (precio_venta_sugerido >= costo_standard_porcion)
);

COMMENT ON TABLE selemti.receta_cab IS 'Maestro de recetas/platos del menÃº del restaurante';

-- 10. RECETA_DET
CREATE TABLE selemti.receta_det (
    receta_id VARCHAR(20) NOT NULL REFERENCES selemti.receta_cab(id) ON DELETE CASCADE,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    tipo_componente VARCHAR(10) CHECK (tipo_componente IN ('INGREDIENTE', 'SUB_RECETA')),
    cantidad_bruta NUMERIC(10,3) NOT NULL CHECK (cantidad_bruta > 0),
    porcentaje_merma NUMERIC(5,2) DEFAULT 0 CHECK (porcentaje_merma BETWEEN 0 AND 99.99),
    cantidad_neta NUMERIC(10,3) NOT NULL,
    orden_mezcla INTEGER NOT NULL CHECK (orden_mezcla > 0),
    tipo_medida VARCHAR(10) CHECK (tipo_medida IN ('PESO', 'VOLUMEN', 'UNIDAD')),
    instrucciones_preparacion TEXT,
    tiempo_coccion_min INTEGER CHECK (tiempo_coccion_min >= 0),
    temperatura_coccion NUMERIC(5,2) CHECK (temperatura_coccion BETWEEN 0 AND 300),
    equipo_requerido VARCHAR(100),
    punto_control_calidad TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    PRIMARY KEY (receta_id, item_id, tipo_componente),
    
    CHECK (CASE 
        WHEN tipo_componente = 'SUB_RECETA' 
        THEN EXISTS (SELECT 1 FROM selemti.receta_cab WHERE id = item_id) 
        ELSE TRUE 
    END)
);

COMMENT ON TABLE selemti.receta_det IS 'Detalle de ingredientes y sub-recetas que componen una receta';

-- 11. OP_PRODUCCION_CAB
CREATE TABLE selemti.op_produccion_cab (
    id SERIAL PRIMARY KEY,
    numero_op VARCHAR(20) UNIQUE NOT NULL DEFAULT 'OP-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD-') || LPAD(NEXTVAL('selemti.op_daily_seq')::TEXT, 4, '0'),
    receta_id VARCHAR(20) NOT NULL REFERENCES selemti.receta_cab(id),
    fecha_produccion DATE NOT NULL DEFAULT CURRENT_DATE,
    turno VARCHAR(10) NOT NULL CHECK (turno IN ('MATUTINO', 'VESPERTINO', 'NOCTURNO')),
    cantidad_planeada INTEGER NOT NULL CHECK (cantidad_planeada > 0),
    cantidad_real INTEGER CHECK (cantidad_real > 0),
    estado VARCHAR(15) DEFAULT 'PLANEADA' CHECK (estado IN ('PLANEADA', 'EN_PRODUCCION', 'SUSPENDIDA', 'COMPLETADA', 'CANCELADA')),
    estacion_trabajo VARCHAR(20) CHECK (estacion_trabajo IN ('COCINA_CALIENTE', 'COCINA_FRIA', 'BARRA', 'POSTRES', 'PANADERIA')),
    usuario_solicitante INTEGER REFERENCES selemti.users(id),
    usuario_produccion INTEGER REFERENCES selemti.users(id),
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
    rendimiento_real NUMERIC(5,2) CHECK (rendimiento_real BETWEEN 0 AND 200),
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CHECK (CASE WHEN estado = 'COMPLETADA' THEN cantidad_real IS NOT NULL AND fecha_fin IS NOT NULL ELSE TRUE END),
    CHECK (CASE WHEN estado = 'EN_PRODUCCION' THEN fecha_inicio IS NOT NULL ELSE TRUE END)
);

-- 12. OP_PRODUCCION_DET
CREATE TABLE selemti.op_produccion_det (
    id SERIAL PRIMARY KEY,
    op_id INTEGER NOT NULL REFERENCES selemti.op_produccion_cab(id) ON DELETE CASCADE,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    inventory_batch_id INTEGER REFERENCES selemti.inventory_batch(id),
    cantidad_teorica NUMERIC(10,3) NOT NULL CHECK (cantidad_teorica > 0),
    cantidad_real NUMERIC(10,3) CHECK (cantidad_real >= 0),
    diferencia NUMERIC(10,3),
    porcentaje_merma_real NUMERIC(5,2),
    costo_teorico NUMERIC(10,2) CHECK (costo_teorico >= 0),
    costo_real NUMERIC(10,2) CHECK (costo_real >= 0),
    motivo_diferencia VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (CASE 
        WHEN (SELECT perishable FROM selemti.items WHERE id = item_id) = true 
        THEN inventory_batch_id IS NOT NULL 
        ELSE TRUE 
    END)
);

-- 13. MERMA_PROCESO
CREATE TABLE selemti.merma_proceso (
    id SERIAL PRIMARY KEY,
    fecha_merma DATE NOT NULL DEFAULT CURRENT_DATE,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    inventory_batch_id INTEGER REFERENCES selemti.inventory_batch(id),
    op_id INTEGER REFERENCES selemti.op_produccion_cab(id),
    tipo_merma VARCHAR(20) NOT NULL CHECK (tipo_merma IN ('PREPARACION', 'COCCION', 'PORTIONING', 'ALMACENAMIENTO', 'DURANTE_SERVICIO')),
    cantidad_merma NUMERIC(10,3) NOT NULL CHECK (cantidad_merma > 0),
    costo_merma NUMERIC(10,2) CHECK (costo_merma >= 0),
    motivo VARCHAR(100) NOT NULL CHECK (LENGTH(motivo) >= 5),
    accion_correctiva TEXT,
    usuario_registro INTEGER REFERENCES selemti.users(id),
    aprobado_por INTEGER REFERENCES selemti.users(id),
    estado VARCHAR(15) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'APROBADO', 'RECHAZADO')),
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (CASE WHEN estado = 'APROBADO' THEN aprobado_por IS NOT NULL ELSE TRUE END),
    CHECK (CASE 
        WHEN (SELECT perishable FROM selemti.items WHERE id = item_id) = true 
        THEN inventory_batch_id IS NOT NULL 
        ELSE TRUE 
    END)
);

-- 14. RENDIMIENTO_RECETA
CREATE TABLE selemti.rendimiento_receta (
    id SERIAL PRIMARY KEY,
    receta_id VARCHAR(20) NOT NULL REFERENCES selemti.receta_cab(id),
    fecha_produccion DATE NOT NULL,
    op_id INTEGER REFERENCES selemti.op_produccion_cab(id),
    cantidad_planeada INTEGER NOT NULL CHECK (cantidad_planeada > 0),
    cantidad_real INTEGER NOT NULL CHECK (cantidad_real > 0),
    rendimiento_porcentaje NUMERIC(5,2) NOT NULL CHECK (rendimiento_porcentaje BETWEEN 0 AND 200),
    costo_teorico_total NUMERIC(10,2) CHECK (costo_teorico_total >= 0),
    costo_real_total NUMERIC(10,2) CHECK (costo_real_total >= 0),
    variacion_costo NUMERIC(10,2),
    motivo_variacion VARCHAR(100),
    usuario_responsable INTEGER REFERENCES selemti.users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE (receta_id, fecha_produccion, op_id)
);

RAISE NOTICE 'Script 03 (MÃ³dulo Recetas - 6 tablas) ejecutado exitosamente';
\n-- END 03_modulo_recetas.sql\n
\n-- BEGIN 04_modulo_ventas.sql\n
-- =====================================================
-- SCRIPT 04: MÃ“DULO DE VENTAS/KDS (5 TABLAS)
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- 15. TICKET_VENTA_CAB
CREATE TABLE selemti.ticket_venta_cab (
    id SERIAL PRIMARY KEY,
    ticket_id_pos VARCHAR(50) UNIQUE NOT NULL,
    fecha_venta TIMESTAMP NOT NULL,
    sucursal_id VARCHAR(10) NOT NULL CHECK (sucursal_id IN ('SUR', 'NORTE', 'CENTRO')),
    numero_mesa VARCHAR(10),
    tipo_servicio VARCHAR(15) CHECK (tipo_servicio IN ('MESA', 'MOSTRADOR', 'DOMICILIO', 'LLEVAR')),
    numero_comensales INTEGER CHECK (numero_comensales > 0),
    total_venta NUMERIC(12,2) NOT NULL CHECK (total_venta >= 0),
    estado_ticket VARCHAR(15) DEFAULT 'PENDIENTE' CHECK (estado_ticket IN ('PENDIENTE', 'EN_PREPARACION', 'LISTO', 'ENTREGADO', 'CANCELADO')),
    tiempo_preparacion_min INTEGER CHECK (tiempo_preparacion_min >= 0),
    tiempo_espera_min INTEGER CHECK (tiempo_espera_min >= 0),
    usuario_creador INTEGER REFERENCES selemti.users(id),
    fecha_sincronizacion TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (LENGTH(ticket_id_pos) >= 5),
    CHECK (fecha_venta <= CURRENT_TIMESTAMP)
);

-- 16. TICKET_VENTA_DET
CREATE TABLE selemti.ticket_venta_det (
    id SERIAL PRIMARY KEY,
    ticket_id INTEGER NOT NULL REFERENCES selemti.ticket_venta_cab(id) ON DELETE CASCADE,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    receta_id VARCHAR(20) REFERENCES selemti.receta_cab(id),
    cantidad NUMERIC(10,3) NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),
    total_linea NUMERIC(12,2) NOT NULL,
    instrucciones_especiales TEXT,
    estado_item VARCHAR(15) DEFAULT 'PENDIENTE' CHECK (estado_item IN ('PENDIENTE', 'EN_PREPARACION', 'LISTO', 'ENTREGADO', 'CANCELADO')),
    tiempo_preparacion_item_min INTEGER CHECK (tiempo_preparacion_item_min >= 0),
    estacion_asignada VARCHAR(20) CHECK (estacion_asignada IN ('COCINA_CALIENTE', 'COCINA_FRIA', 'BARRA', 'POSTRES')),
    usuario_preparador INTEGER REFERENCES selemti.users(id),
    fecha_preparacion_inicio TIMESTAMP,
    fecha_preparacion_fin TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (fecha_preparacion_fin IS NULL OR fecha_preparacion_fin >= fecha_preparacion_inicio),
    CHECK (CASE WHEN estado_item = 'LISTO' THEN fecha_preparacion_fin IS NOT NULL ELSE TRUE END)
);

-- 17. KDS_ORDENES
CREATE TABLE selemti.kds_ordenes (
    id SERIAL PRIMARY KEY,
    ticket_det_id INTEGER NOT NULL REFERENCES selemti.ticket_venta_det(id) ON DELETE CASCADE,
    estacion_trabajo VARCHAR(20) NOT NULL CHECK (estacion_trabajo IN ('COCINA_CALIENTE', 'COCINA_FRIA', 'BARRA', 'POSTRES', 'PANADERIA')),
    prioridad VARCHAR(10) DEFAULT 'NORMAL' CHECK (prioridad IN ('BAJA', 'NORMAL', 'ALTA', 'URGENTE')),
    estado_orden VARCHAR(15) DEFAULT 'PENDIENTE' CHECK (estado_orden IN ('PENDIENTE', 'ASIGNADA', 'EN_PREPARACION', 'LISTO', 'ENTREGADO', 'CANCELADO')),
    tiempo_estimado_min INTEGER CHECK (tiempo_estimado_min > 0),
    tiempo_real_min INTEGER CHECK (tiempo_real_min >= 0),
    orden_en_cola INTEGER CHECK (orden_en_cola > 0),
    usuario_asignado INTEGER REFERENCES selemti.users(id),
    fecha_asignacion TIMESTAMP,
    fecha_inicio_preparacion TIMESTAMP,
    fecha_listo TIMESTAMP,
    fecha_entrega TIMESTAMP,
    alerta_tiempo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (fecha_inicio_preparacion IS NULL OR fecha_inicio_preparacion >= fecha_asignacion),
    CHECK (fecha_listo IS NULL OR fecha_listo >= fecha_inicio_preparacion),
    CHECK (fecha_entrega IS NULL OR fecha_entrega >= fecha_listo)
);

-- 18. KDS_ESTACIONES
CREATE TABLE selemti.kds_estaciones (
    codigo_estacion VARCHAR(20) PRIMARY KEY CHECK (codigo_estacion IN ('COCINA_CALIENTE', 'COCINA_FRIA', 'BARRA', 'POSTRES', 'PANADERIA')),
    nombre_estacion VARCHAR(50) NOT NULL,
    descripcion TEXT,
    ubicacion_fisica VARCHAR(100),
    usuario_responsable INTEGER REFERENCES selemti.users(id),
    capacidad_maxima_ordenes INTEGER NOT NULL CHECK (capacidad_maxima_ordenes > 0),
    tiempo_promedio_preparacion_min INTEGER CHECK (tiempo_promedio_preparacion_min > 0),
    activa BOOLEAN DEFAULT TRUE,
    ip_display VARCHAR(15),
    ultima_actividad TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- INSERTAR ESTACIONES POR DEFECTO
INSERT INTO selemti.kds_estaciones VALUES 
('COCINA_CALIENTE', 'Cocina Caliente', 'PreparaciÃ³n de platos que requieren cocciÃ³n', 'Ãrea principal cocina', NULL, 10, 15, true, NULL, NOW(), NOW()),
('COCINA_FRIA', 'Cocina FrÃ­a', 'PreparaciÃ³n de ensaladas y entradas frÃ­as', 'Ãrea refrigerada cocina', NULL, 8, 10, true, NULL, NOW(), NOW()),
('BARRA', 'Barra', 'PreparaciÃ³n de bebidas y cocteles', 'Barra principal', NULL, 12, 8, true, NULL, NOW(), NOW()),
('POSTRES', 'Postres', 'PreparaciÃ³n de postres y dulces', 'Ãrea postres', NULL, 6, 12, true, NULL, NOW(), NOW()),
('PANADERIA', 'PanaderÃ­a', 'PreparaciÃ³n de pan y reposterÃ­a', 'Ãrea hornos', NULL, 5, 20, true, NULL, NOW(), NOW());

-- 19. KDS_TIEMPOS
CREATE TABLE selemti.kds_tiempos (
    id SERIAL PRIMARY KEY,
    fecha_metricas DATE NOT NULL DEFAULT CURRENT_DATE,
    estacion_trabajo VARCHAR(20) NOT NULL REFERENCES selemti.kds_estaciones(codigo_estacion),
    total_ordenes INTEGER NOT NULL CHECK (total_ordenes >= 0),
    ordenes_completadas INTEGER NOT NULL CHECK (ordenes_completadas >= 0 AND ordenes_completadas <= total_ordenes),
    tiempo_promedio_preparacion_min NUMERIC(6,2) CHECK (tiempo_promedio_preparacion_min >= 0),
    tiempo_maximo_preparacion_min INTEGER CHECK (tiempo_maximo_preparacion_min >= 0),
    ordenes_con_retraso INTEGER CHECK (ordenes_con_retraso >= 0 AND ordenes_con_retraso <= total_ordenes),
    porcentaje_cumplimiento_tiempo NUMERIC(5,2) CHECK (porcentaje_cumplimiento_tiempo BETWEEN 0 AND 100),
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE (fecha_metricas, estacion_trabajo),
    CHECK (ordenes_completadas <= total_ordenes),
    CHECK (ordenes_con_retraso <= ordenes_completadas)
);

RAISE NOTICE 'Script 04 (MÃ³dulo Ventas/KDS - 5 tablas) ejecutado exitosamente';
\n-- END 04_modulo_ventas.sql\n
\n-- BEGIN 05_modulo_caja.sql\n
-- =====================================================
-- SCRIPT 05: MÃ“DULO DE CAJA (3 TABLAS)
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- 20. CAJA_MOVIMIENTOS
CREATE TABLE selemti.caja_movimientos (
    id SERIAL PRIMARY KEY,
    caja_id VARCHAR(10) NOT NULL CHECK (caja_id IN ('CAJA1', 'CAJA2', 'CAJA3')),
    fecha_movimiento TIMESTAMP NOT NULL DEFAULT NOW(),
    tipo_movimiento VARCHAR(15) NOT NULL CHECK (tipo_movimiento IN ('APERTURA', 'VENTA', 'GASTO', 'RETIRO', 'DEPOSITO', 'CIERRE')),
    descripcion VARCHAR(200) NOT NULL CHECK (LENGTH(descripcion) >= 5),
    monto NUMERIC(12,2) NOT NULL CHECK (monto != 0),
    metodo_pago VARCHAR(20) CHECK (metodo_pago IN ('EFECTIVO', 'TARJETA_DEBITO', 'TARJETA_CREDITO', 'TRANSFERENCIA', 'VALES')),
    referencia VARCHAR(50),
    usuario_id INTEGER NOT NULL REFERENCES selemti.users(id),
    sucursal_id VARCHAR(10) NOT NULL CHECK (sucursal_id IN ('SUR', 'NORTE', 'CENTRO')),
    estado VARCHAR(15) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'CANCELADO', 'AJUSTADO')),
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (CASE WHEN tipo_movimiento = 'VENTA' THEN referencia IS NOT NULL ELSE TRUE END),
    CHECK (CASE WHEN tipo_movimiento IN ('GASTO', 'RETIRO') THEN monto < 0 ELSE TRUE END),
    CHECK (CASE WHEN tipo_movimiento IN ('APERTURA', 'VENTA', 'DEPOSITO') THEN monto > 0 ELSE TRUE END)
);

-- 21. CAJA_CIERRES
CREATE TABLE selemti.caja_cierres (
    id SERIAL PRIMARY KEY,
    caja_id VARCHAR(10) NOT NULL CHECK (caja_id IN ('CAJA1', 'CAJA2', 'CAJA3')),
    fecha_cierre DATE NOT NULL DEFAULT CURRENT_DATE,
    turno VARCHAR(10) NOT NULL CHECK (turno IN ('MATUTINO', 'VESPERTINO', 'NOCTURNO')),
    usuario_cajero INTEGER NOT NULL REFERENCES selemti.users(id),
    usuario_supervisor INTEGER REFERENCES selemti.users(id),
    saldo_inicial NUMERIC(12,2) NOT NULL CHECK (saldo_inicial >= 0),
    total_ventas_efectivo NUMERIC(12,2) CHECK (total_ventas_efectivo >= 0),
    total_ventas_tarjeta NUMERIC(12,2) CHECK (total_ventas_tarjeta >= 0),
    total_otros_ingresos NUMERIC(12,2) CHECK (total_otros_ingresos >= 0),
    total_gastos NUMERIC(12,2) CHECK (total_gastos >= 0),
    total_retiros NUMERIC(12,2) CHECK (total_retiros >= 0),
    efectivo_declarado NUMERIC(12,2) CHECK (efectivo_declarado >= 0),
    diferencia_efectivo NUMERIC(12,2),
    estado_cierre VARCHAR(15) DEFAULT 'PENDIENTE' CHECK (estado_cierre IN ('PENDIENTE', 'APROBADO', 'RECHAZADO', 'AJUSTADO')),
    motivo_diferencia TEXT,
    fecha_aprobacion TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE (caja_id, fecha_cierre, turno),
    CHECK (CASE WHEN ABS(diferencia_efectivo) > 50 THEN motivo_diferencia IS NOT NULL ELSE TRUE END),
    CHECK (CASE WHEN estado_cierre = 'APROBADO' THEN usuario_supervisor IS NOT NULL ELSE TRUE END)
);

-- 22. CAJA_DIFERENCIAS
CREATE TABLE selemti.caja_diferencias (
    id SERIAL PRIMARY KEY,
    cierre_id INTEGER NOT NULL REFERENCES selemti.caja_cierres(id) ON DELETE CASCADE,
    tipo_diferencia VARCHAR(15) NOT NULL CHECK (tipo_diferencia IN ('SOBRANTE', 'FALTANTE', 'GASTO_NO_REGISTRADO', 'INGRESO_NO_REGISTRADO')),
    monto_diferencia NUMERIC(10,2) NOT NULL CHECK (monto_diferencia != 0),
    descripcion_detallada TEXT NOT NULL CHECK (LENGTH(descripcion_detallada) >= 10),
    accion_correctiva TEXT,
    usuario_responsable INTEGER REFERENCES selemti.users(id),
    estado_resolucion VARCHAR(15) DEFAULT 'PENDIENTE' CHECK (estado_resolucion IN ('PENDIENTE', 'RESUELTO', 'JUSTIFICADO', 'IRRECUPERABLE')),
    fecha_resolucion TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (CASE 
        WHEN tipo_diferencia IN ('SOBRANTE', 'INGRESO_NO_REGISTRADO') THEN monto_diferencia > 0 
        WHEN tipo_diferencia IN ('FALTANTE', 'GASTO_NO_REGISTRADO') THEN monto_diferencia < 0 
        ELSE TRUE 
    END)
);

RAISE NOTICE 'Script 05 (MÃ³dulo Caja - 3 tablas) ejecutado exitosamente';
\n-- END 05_modulo_caja.sql\n
\n-- BEGIN 06_modulo_appcc.sql\n
-- =====================================================
-- SCRIPT 06: MÃ“DULO APPCC (4 TABLAS)
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- 23. APPCC_PUNTOS_CONTROL
CREATE TABLE selemti.appcc_puntos_control (
    id SERIAL PRIMARY KEY,
    codigo_punto VARCHAR(20) UNIQUE NOT NULL CHECK (codigo_punto ~ '^PCC-[A-Z0-9\-]{1,15}$'),
    nombre_punto VARCHAR(100) NOT NULL,
    proceso VARCHAR(50) NOT NULL CHECK (proceso IN ('RECEPCION', 'ALMACENAMIENTO', 'PREPARACION', 'COCCION', 'ENFRIAMIENTO', 'REGENERACION', 'SERVICIO')),
    peligro_identificado VARCHAR(100) NOT NULL CHECK (LENGTH(peligro_identificado) >= 5),
    tipo_peligro VARCHAR(20) NOT NULL CHECK (tipo_peligro IN ('BIOLOGICO', 'QUIMICO', 'FISICO', 'ALERGENOS')),
    medida_control VARCHAR(200) NOT NULL,
    limite_critico VARCHAR(100) NOT NULL,
    frecuencia_monitoreo VARCHAR(50) NOT NULL,
    responsable_monitoreo VARCHAR(50) NOT NULL,
    accion_correctiva TEXT NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    usuario_creador INTEGER REFERENCES selemti.users(id),
    fecha_creacion TIMESTAMP DEFAULT NOW(),
    fecha_revision TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (fecha_revision IS NULL OR fecha_revision >= fecha_creacion)
);

-- INSERTAR PUNTOS DE CONTROL APPCC BÃSICOS
INSERT INTO selemti.appcc_puntos_control VALUES 
(1, 'PCC-RECEP-001', 'RecepciÃ³n Productos Perecederos', 'RECEPCION', 'Crecimiento bacteriano', 'BIOLOGICO', 'Control de temperatura', 'Temperatura <= 4Â°C para productos refrigerados', 'CADA LOTE', 'Personal AlmacÃ©n', 'Rechazar lote y notificar al proveedor', true, 1, NOW(), NULL, NOW(), NOW()),
(2, 'PCC-ALM-001', 'Almacenamiento Refrigerado', 'ALMACENAMIENTO', 'Crecimiento bacteriano', 'BIOLOGICO', 'Control temperatura neveras', 'Temperatura entre 0Â°C y 4Â°C', 'CADA 4 HORAS', 'Personal Cocina', 'Ajustar temperatura y verificar productos', true, 1, NOW(), NULL, NOW(), NOW()),
(3, 'PCC-COC-001', 'CocciÃ³n de Alimentos', 'COCCION', 'Supervivencia de microorganismos', 'BIOLOGICO', 'Control temperatura interna', 'Temperatura interna >= 75Â°C por 2 minutos', 'CADA BATCH', 'Chef', 'Extender tiempo de cocciÃ³n', true, 1, NOW(), NULL, NOW(), NOW());

-- 24. APPCC_REGISTROS
CREATE TABLE selemti.appcc_registros (
    id SERIAL PRIMARY KEY,
    punto_control_id INTEGER NOT NULL REFERENCES selemti.appcc_puntos_control(id),
    fecha_registro DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_registro TIME NOT NULL DEFAULT CURRENT_TIME,
    valor_medido VARCHAR(50) NOT NULL,
    cumple_limite BOOLEAN NOT NULL,
    observaciones TEXT,
    usuario_registrador INTEGER NOT NULL REFERENCES selemti.users(id),
    evidencia_fotografica_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE (punto_control_id, fecha_registro, hora_registro),
    CHECK (hora_registro BETWEEN '06:00:00' AND '23:00:00')
);

-- 25. APPCC_ALERTAS
CREATE TABLE selemti.appcc_alertas (
    id SERIAL PRIMARY KEY,
    punto_control_id INTEGER NOT NULL REFERENCES selemti.appcc_puntos_control(id),
    registro_id INTEGER REFERENCES selemti.appcc_registros(id),
    fecha_alerta TIMESTAMP NOT NULL DEFAULT NOW(),
    tipo_alerta VARCHAR(20) NOT NULL CHECK (tipo_alerta IN ('LIMITE_EXCEDIDO', 'REGISTRO_FALTANTE', 'EQUIPO_FALLADO')),
    gravedad VARCHAR(10) NOT NULL CHECK (gravedad IN ('BAJA', 'MEDIA', 'ALTA', 'CRITICA')),
    descripcion_alerta TEXT NOT NULL CHECK (LENGTH(descripcion_alerta) >= 10),
    accion_tomada TEXT,
    usuario_responsable INTEGER REFERENCES selemti.users(id),
    estado_alerta VARCHAR(15) DEFAULT 'PENDIENTE' CHECK (estado_alerta IN ('PENDIENTE', 'EN_PROCESO', 'RESUELTA', 'ESCALADA')),
    fecha_resolucion TIMESTAMP,
    tiempo_resolucion_min INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (fecha_resolucion IS NULL OR fecha_resolucion >= fecha_alerta),
    CHECK (CASE WHEN estado_alerta = 'RESUELTA' THEN fecha_resolucion IS NOT NULL AND accion_tomada IS NOT NULL ELSE TRUE END)
);

-- 26. APPCC_ACCIONES
CREATE TABLE selemti.appcc_acciones (
    id SERIAL PRIMARY KEY,
    alerta_id INTEGER NOT NULL REFERENCES selemti.appcc_alertas(id) ON DELETE CASCADE,
    descripcion_accion TEXT NOT NULL CHECK (LENGTH(descripcion_accion) >= 10),
    tipo_accion VARCHAR(20) NOT NULL CHECK (tipo_accion IN ('CORRECTIVA', 'PREVENTIVA', 'MEJORA')),
    usuario_asignado INTEGER NOT NULL REFERENCES selemti.users(id),
    fecha_limite DATE NOT NULL CHECK (fecha_limite >= CURRENT_DATE),
    fecha_completado TIMESTAMP,
    estado_accion VARCHAR(15) DEFAULT 'PENDIENTE' CHECK (estado_accion IN ('PENDIENTE', 'EN_PROGRESO', 'COMPLETADA', 'CANCELADA')),
    evidencia_url VARCHAR(500),
    eficacia_verificada BOOLEAN DEFAULT FALSE,
    fecha_verificacion TIMESTAMP,
    usuario_verificador INTEGER REFERENCES selemti.users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (fecha_completado IS NULL OR fecha_completado >= created_at),
    CHECK (fecha_verificacion IS NULL OR fecha_verificacion >= fecha_completado),
    CHECK (CASE WHEN eficacia_verificada = true THEN fecha_verificacion IS NOT NULL AND usuario_verificador IS NOT NULL ELSE TRUE END)
);

RAISE NOTICE 'Script 06 (MÃ³dulo APPCC - 4 tablas) ejecutado exitosamente';
\n-- END 06_modulo_appcc.sql\n
\n-- BEGIN 07_modulo_configuracion.sql\n
-- =====================================================
-- SCRIPT 07: MÃ“DULO DE CONFIGURACIÃ“N (4 TABLAS)
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- 27. PARAMETROS_SISTEMA
CREATE TABLE selemti.parametros_sistema (
    id SERIAL PRIMARY KEY,
    codigo_parametro VARCHAR(50) UNIQUE NOT NULL CHECK (LENGTH(codigo_parametro) >= 3),
    nombre_parametro VARCHAR(100) NOT NULL,
    valor_parametro TEXT NOT NULL,
    tipo_dato VARCHAR(10) NOT NULL CHECK (tipo_dato IN ('TEXTO', 'NUMERICO', 'BOOLEANO', 'FECHA', 'JSON')),
    modulo VARCHAR(20) NOT NULL CHECK (modulo IN ('INVENTARIO', 'RECETAS', 'VENTAS', 'CAJA', 'APPCC', 'GENERAL')),
    descripcion TEXT NOT NULL,
    valor_por_defecto TEXT,
    editable BOOLEAN DEFAULT TRUE,
    requiere_reinicio BOOLEAN DEFAULT FALSE,
    usuario_ultima_modificacion INTEGER REFERENCES selemti.users(id),
    fecha_ultima_modificacion TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (CASE 
        WHEN tipo_dato = 'NUMERICO' THEN valor_parametro ~ '^-?[0-9]+(\.[0-9]+)?$'
        WHEN tipo_dato = 'BOOLEANO' THEN valor_parametro IN ('true', 'false', '1', '0')
        WHEN tipo_dato = 'FECHA' THEN valor_parametro ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        ELSE TRUE 
    END)
);

-- INSERTAR PARÃMETROS CRÃTICOS DEL SISTEMA
INSERT INTO selemti.parametros_sistema VALUES 
(1, 'INV_TOLERANCIA_DIFERENCIA', 'Tolerancia para diferencias de inventario', '0.05', 'NUMERICO', 'INVENTARIO', 'Tolerancia permitida para diferencias en conteos fÃ­sicos (5%)', '0.05', true, false, NULL, NOW(), NOW()),
(2, 'CAJA_TOLERANCIA_EFECTIVO', 'Tolerancia para diferencias de efectivo', '50.00', 'NUMERICO', 'CAJA', 'Tolerancia en pesos para diferencias de caja sin requerir aprobaciÃ³n', '50.00', true, false, NULL, NOW(), NOW()),
(3, 'APPCC_FRECUENCIA_MONITOREO', 'Frecuencia de monitoreo APPCC', '4', 'NUMERICO', 'APPCC', 'Horas entre monitoreos de puntos crÃ­ticos', '4', true, true, NULL, NOW(), NOW()),
(4, 'KDS_TIEMPO_MAX_PREPARACION', 'Tiempo mÃ¡ximo de preparaciÃ³n', '30', 'NUMERICO', 'VENTAS', 'Tiempo mÃ¡ximo en minutos para preparaciÃ³n de platos', '30', true, false, NULL, NOW(), NOW()),
(5, 'SISTEMA_MODO_MANTENIMIENTO', 'Modo mantenimiento del sistema', 'false', 'BOOLEANO', 'GENERAL', 'Activa el modo mantenimiento del sistema', 'false', true, true, NULL, NOW(), NOW()),
(6, 'INV_POLITICA_CONSUMO', 'PolÃ­tica de consumo de inventario', 'FEFO', 'TEXTO', 'INVENTARIO', 'PolÃ­tica por defecto para consumo de inventario (FEFO/PEPS)', 'FEFO', true, false, NULL, NOW(), NOW());

-- 28. PROVEEDORES
CREATE TABLE selemti.proveedores (
    codigo VARCHAR(20) PRIMARY KEY CHECK (codigo ~ '^PROV-[A-Z0-9\-]{1,15}$'),
    nombre VARCHAR(100) NOT NULL,
    rfc VARCHAR(13) CHECK (LENGTH(rfc) = 13 OR rfc IS NULL),
    direccion TEXT,
    telefono VARCHAR(15),
    email VARCHAR(100) CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    contacto_principal VARCHAR(100),
    tipo_proveedor VARCHAR(20) CHECK (tipo_proveedor IN ('ALIMENTOS', 'BEBIDAS', 'LIMPIEZA', 'EQUIPO', 'SERVICIO')),
    categoria_calidad VARCHAR(10) CHECK (categoria_calidad IN ('A', 'B', 'C', 'SUSPENDIDO')),
    plazo_entrega_dias INTEGER CHECK (plazo_entrega_dias > 0),
    condiciones_pago VARCHAR(50),
    activo BOOLEAN DEFAULT TRUE,
    fecha_alta DATE DEFAULT CURRENT_DATE,
    fecha_ultima_compra DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (rfc IS NULL OR rfc ~ '^[A-Z&Ã‘]{3,4}[0-9]{6}[A-Z0-9]{3}$')
);

-- 29. UBICACIONES
CREATE TABLE selemti.ubicaciones (
    codigo VARCHAR(10) PRIMARY KEY CHECK (codigo LIKE 'UBIC-%'),
    nombre VARCHAR(50) NOT NULL,
    tipo_ubicacion VARCHAR(20) NOT NULL CHECK (tipo_ubicacion IN ('BODEGA', 'REFRIGERADOR', 'CONGELADOR', 'ALACENA', 'BARRA', 'COCINA', 'MOSTRADOR')),
    sucursal VARCHAR(10) NOT NULL CHECK (sucursal IN ('SUR', 'NORTE', 'CENTRO')),
    temperatura_ideal NUMERIC(5,2),
    capacidad_maxima_kg NUMERIC(10,3),
    responsable INTEGER REFERENCES selemti.users(id),
    activa BOOLEAN DEFAULT TRUE,
    ubicacion_padre VARCHAR(10) REFERENCES selemti.ubicaciones(codigo),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (ubicacion_padre IS NULL OR ubicacion_padre != codigo)
);

-- INSERTAR UBICACIONES BÃSICAS
INSERT INTO selemti.ubicaciones VALUES 
('UBIC-BODEGA1', 'Bodega Principal', 'BODEGA', 'SUR', 18.0, 1000.0, NULL, true, NULL, NOW(), NOW()),
('UBIC-REFRIG1', 'Refrigerador Carnes', 'REFRIGERADOR', 'SUR', 4.0, 200.0, NULL, true, NULL, NOW(), NOW()),
('UBIC-CONGEL1', 'Congelador Pescados', 'CONGELADOR', 'SUR', -18.0, 150.0, NULL, true, NULL, NOW(), NOW()),
('UBIC-BARRA', 'Barra Principal', 'BARRA', 'SUR', 8.0, 50.0, NULL, true, NULL, NOW(), Now());

-- 30. CATEGORIAS_ITEMS
CREATE TABLE selemti.categorias_items (
    codigo VARCHAR(10) PRIMARY KEY CHECK (codigo LIKE 'CAT-%'),
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    tipo_categoria VARCHAR(20) NOT NULL CHECK (tipo_categoria IN ('INSUMO', 'PRODUCTO_TERMINADO', 'MATERIAL', 'SERVICIO')),
    categoria_padre VARCHAR(10) REFERENCES selemti.categorias_items(codigo),
    cuenta_contable VARCHAR(20),
    porcentaje_merma_esperado NUMERIC(5,2) DEFAULT 0 CHECK (porcentaje_merma_esperado BETWEEN 0 AND 100),
    vida_util_dias INTEGER CHECK (vida_util_dias > 0),
    activa BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (categoria_padre IS NULL OR categoria_padre != codigo)
);

-- INSERTAR CATEGORÃAS BÃSICAS
INSERT INTO selemti.categorias_items VALUES 
('CAT-PROTEINA', 'ProteÃ­nas', 'Carnes, pescados, aves', 'INSUMO', NULL, '1101', 5.0, 7, true, NOW(), NOW()),
('CAT-LACTEO', 'LÃ¡cteos', 'Leche, queso, yogurt', 'INSUMO', NULL, '1102', 3.0, 10, true, NOW(), NOW()),
('CAT-VERDURA', 'Verduras', 'Verduras frescas', 'INSUMO', NULL, '1103', 8.0, 5, true, NOW(), NOW()),
('CAT-BEBIDA', 'Bebidas', 'Refrescos, jugos, agua', 'INSUMO', NULL, '1104', 1.0, 30, true, NOW(), NOW()),
('CAT-MENU', 'Platos del MenÃº', 'Productos terminados para venta', 'PRODUCTO_TERMINADO', NULL, '2101', 2.0, 1, true, NOW(), NOW());

RAISE NOTICE 'Script 07 (MÃ³dulo ConfiguraciÃ³n - 4 tablas) ejecutado exitosamente';
\n-- END 07_modulo_configuracion.sql\n
\n-- BEGIN 08_datos_iniciales.sql\n
-- =====================================================
-- SCRIPT 08: DATOS INICIALES DEL SISTEMA
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- 1. CREAR USUARIO ADMINISTRADOR INICIAL
INSERT INTO selemti.users (username, password_hash, email, nombre_completo, sucursal_id, activo) VALUES 
('admin', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'admin@restaurante.com', 'Administrador del Sistema', 'SUR', true);

-- 2. ASIGNAR ROLES AL ADMINISTRADOR
INSERT INTO selemti.user_roles (user_id, role_id, assigned_by) VALUES 
(1, 'GERENTE', 1),
(1, 'CHEF', 1),
(1, 'ALMACEN', 1),
(1, 'CAJERO', 1),
(1, 'AUDITOR', 1);

-- 3. CREAR USUARIOS DE EJEMPLO POR ROL
INSERT INTO selemti.users (username, password_hash, nombre_completo, sucursal_id, activo) VALUES 
('chef.juan', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'Juan PÃ©rez - Chef', 'SUR', true),
('almacen.maria', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'MarÃ­a GarcÃ­a - AlmacÃ©n', 'SUR', true),
('caja.carlos', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'Carlos LÃ³pez - Cajero', 'SUR', true);

INSERT INTO selemti.user_roles (user_id, role_id, assigned_by) VALUES 
(2, 'CHEF', 1),
(3, 'ALMACEN', 1),
(4, 'CAJERO', 1);

-- 4. INSERTAR ÃTEMS DE EJEMPLO (MATERIAS PRIMAS)
INSERT INTO selemti.items (id, nombre, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max) VALUES 
('PROT-POLLO-PECHUGA-1KG', 'Pechuga de Pollo', 'CAT-PROTEINA', 'KG', true, 0, 4),
('PROT-SALMON-FRESCO-1KG', 'SalmÃ³n Fresco', 'CAT-PROTEINA', 'KG', true, -2, 2),
('VERD-LECHUGA-ROMA-1KG', 'Lechuga Romana', 'CAT-VERDURA', 'KG', true, 1, 4),
('VERD-TOMATE-ROJO-1KG', 'Tomate Rojo', 'CAT-VERDURA', 'KG', true, 10, 15),
('LACT-QUESO-MOZZARELLA-1KG', 'Queso Mozzarella', 'CAT-LACTEO', 'KG', true, 2, 6),
('BEBID-AGUA-1LT', 'Agua Purificada', 'CAT-BEBIDA', 'LT', false, NULL, NULL);

-- 5. INSERTAR RECETAS DE EJEMPLO
INSERT INTO selemti.receta_cab (id, codigo_plato_pos, nombre_plato, categoria_cocina, tipo_preparacion, tiempo_preparacion_min, rendimiento_porciones, nivel_dificultad, activo, usuario_creador, costo_standard_porcion, precio_venta_sugerido) VALUES 
('REC-CEVICHE-CLASICO', 'CEV-001', 'Ceviche ClÃ¡sico', 'PLATO_FUERTE', 'FRIA', 20, 4, 'MEDIA', true, 1, 45.00, 180.00),
('REC-ENSALADA-CESAR', 'ENS-001', 'Ensalada CÃ©sar', 'ENTRADA', 'FRIA', 15, 2, 'BAJA', true, 1, 35.00, 120.00);

-- 6. INSERTAR DETALLES DE RECETAS
INSERT INTO selemti.receta_det (receta_id, item_id, tipo_componente, cantidad_bruta, porcentaje_merma, cantidad_neta, orden_mezcla, tipo_medida) VALUES 
('REC-CEVICHE-CLASICO', 'PROT-SALMON-FRESCO-1KG', 'INGREDIENTE', 0.500, 10.00, 0.450, 1, 'PESO'),
('REC-CEVICHE-CLASICO', 'VERD-LECHUGA-ROMA-1KG', 'INGREDIENTE', 0.200, 5.00, 0.190, 2, 'PESO'),
('REC-ENSALADA-CESAR', 'VERD-LECHUGA-ROMA-1KG', 'INGREDIENTE', 0.300, 5.00, 0.285, 1, 'PESO'),
('REC-ENSALADA-CESAR', 'LACT-QUESO-MOZZARELLA-1KG', 'INGREDIENTE', 0.100, 2.00, 0.098, 2, 'PESO');

-- 7. ACTUALIZAR FOREIGN KEYS PENDIENTES
-- Actualizar recepcion_cab con referencia a proveedores
UPDATE selemti.recepcion_cab SET proveedor_id = 'PROV-CARNICOS-LA-PALMA' WHERE proveedor_id IS NOT NULL;

-- 8. CREAR PROVEEDORES DE EJEMPLO
INSERT INTO selemti.proveedores (codigo, nombre, tipo_proveedor, categoria_calidad, activo) VALUES 
('PROV-CARNICOS-LA-PALMA', 'CÃ¡rnicos La Palma', 'ALIMENTOS', 'A', true),
('PROV-PESCADOS-FRESCOS', 'Pescados Frescos del PacÃ­fico', 'ALIMENTOS', 'A', true),
('PROV-HORTALIZAS-ORGANICAS', 'Hortalizas OrgÃ¡nicas', 'ALIMENTOS', 'B', true);

RAISE NOTICE 'Script 08 (Datos iniciales) ejecutado exitosamente';
\n-- END 08_datos_iniciales.sql\n
\n-- BEGIN 09_indices_optimizacion.sql\n
-- =====================================================
-- SCRIPT 09: ÃNDICES DE OPTIMIZACIÃ“N
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- ÃNDICES PARA MÃ“DULO INVENTARIO
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

-- ÃNDICES PARA MÃ“DULO RECETAS
CREATE INDEX idx_receta_det_item ON selemti.receta_det(item_id);
CREATE INDEX idx_receta_det_orden ON selemti.receta_det(receta_id, orden_mezcla);

CREATE INDEX idx_op_produccion_receta ON selemti.op_produccion_cab(receta_id);
CREATE INDEX idx_op_produccion_fecha ON selemti.op_produccion_cab(fecha_produccion);
CREATE INDEX idx_op_produccion_estado ON selemti.op_produccion_cab(estado);

CREATE INDEX idx_op_det_op ON selemti.op_produccion_det(op_id);
CREATE INDEX idx_op_det_item ON selemti.op_produccion_det(item_id);
CREATE INDEX idx_op_det_batch ON selemti.op_produccion_det(inventory_batch_id);

-- ÃNDICES PARA MÃ“DULO VENTAS/KDS
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

-- ÃNDICES PARA MÃ“DULO CAJA
CREATE INDEX idx_caja_movimientos_caja ON selemti.caja_movimientos(caja_id, fecha_movimiento);
CREATE INDEX idx_caja_movimientos_tipo ON selemti.caja_movimientos(tipo_movimiento);
CREATE INDEX idx_caja_movimientos_usuario ON selemti.caja_movimientos(usuario_id);

CREATE INDEX idx_caja_cierres_fecha ON selemti.caja_cierres(fecha_cierre);
CREATE INDEX idx_caja_cierres_usuario ON selemti.caja_cierres(usuario_cajero);
CREATE INDEX idx_caja_cierres_estado ON selemti.caja_cierres(estado_cierre);

-- ÃNDICES PARA MÃ“DULO APPCC
CREATE INDEX idx_appcc_registros_fecha ON selemti.appcc_registros(fecha_registro);
CREATE INDEX idx_appcc_registros_punto ON selemti.appcc_registros(punto_control_id);
CREATE INDEX idx_appcc_registros_cumple ON selemti.appcc_registros(cumple_limite);

CREATE INDEX idx_appcc_alertas_fecha ON selemti.appcc_alertas(fecha_alerta);
CREATE INDEX idx_appcc_alertas_estado ON selemti.appcc_alertas(estado_alerta);
CREATE INDEX idx_appcc_alertas_gravedad ON selemti.appcc_alertas(gravedad);

-- ÃNDICES PARA AUDITORÃA
CREATE INDEX idx_audit_log_timestamp ON selemti.audit_log(timestamp);
CREATE INDEX idx_audit_log_user_action ON selemti.audit_log(user_id, action_type);
CREATE INDEX idx_audit_log_table_record ON selemti.audit_log(table_name, record_id);

-- ÃNDICES PARA BÃšSQUEDA DE TEXTO
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

RAISE NOTICE 'Script 09 (Ãndices de optimizaciÃ³n) ejecutado exitosamente';
RAISE NOTICE 'âœ… ESQUEMA SELETI COMPLETADO - 30 TABLAS CREADAS';
\n-- END 09_indices_optimizacion.sql\n
\n-- BEGIN 010.delta_full_plus.sql\n
/* ======================================================================
   010.delta_full_plus.sql
   Selemti - Deltas finales de modelo para operaciÃ³n multi-UOM, elaborados,
   traspasos, stock policies y mermas. PG â‰¥ 9.5
   ====================================================================== */

SET client_min_messages = WARNING;
SET TIME ZONE 'America/Mexico_City';

/* Asegurar esquema y search_path */
CREATE SCHEMA IF NOT EXISTS selemti;
SET search_path TO selemti, public;

/* --------------------------------------------------------------
   A) UOM original en movimientos (fidelidad operativa)
   -------------------------------------------------------------- */
-- Se asume que selemti.unidades_medida ya existe (GR, ML, PZ, etc.)

-- Kardex: cantidad en canÃ³nica ya existe (cantidad/qty). Agregamos
-- qty_original + uom_original_id para preservar la UOM de la transacciÃ³n.
ALTER TABLE IF EXISTS selemti.mov_inv
  ADD COLUMN IF NOT EXISTS qty_original NUMERIC(14,6),
  ADD COLUMN IF NOT EXISTS uom_original_id INT REFERENCES selemti.unidades_medida(id);

-- Ãndices Ãºtiles (si no existen)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_movinv_item_ts' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_movinv_item_ts ON selemti.mov_inv (item_id, ts);
  END IF;
END$$;

/* --------------------------------------------------------------
   B) Presentaciones por proveedor (compra caja/saco/etc.)
   -------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS selemti.item_vendor (
  item_id            TEXT        NOT NULL,
  vendor_id          TEXT        NOT NULL,
  presentacion       TEXT        NOT NULL,   -- "caja 12x1L", "saco 25kg"
  unidad_presentacion_id INT     NOT NULL REFERENCES selemti.unidades_medida(id), -- PZ
  factor_a_canonica  NUMERIC(14,6) NOT NULL CHECK (factor_a_canonica > 0),        -- p.ej. 12000 ML/PZ
  costo_ultimo       NUMERIC(14,6) NOT NULL DEFAULT 0,
  moneda             TEXT        NOT NULL DEFAULT 'MXN',
  lead_time_dias     INT,
  codigo_proveedor   TEXT,
  activo             BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at         TIMESTAMP   NOT NULL DEFAULT now(),
  PRIMARY KEY (item_id, vendor_id, presentacion)
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_item_vendor_item' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_item_vendor_item ON selemti.item_vendor(item_id);
  END IF;
END$$;

/* --------------------------------------------------------------
   C) Tipo de producto y UOM de salida (elaborados)
   -------------------------------------------------------------- */
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='producto_tipo') THEN
    CREATE TYPE selemti.producto_tipo AS ENUM ('MATERIA_PRIMA','ELABORADO','ENVASADO');
  END IF;
END$$;

-- items: tipologÃ­a + UOM de salida (para recetas/OP)
ALTER TABLE IF EXISTS selemti.items
  ADD COLUMN IF NOT EXISTS tipo selemti.producto_tipo,
  ADD COLUMN IF NOT EXISTS unidad_salida_id INT REFERENCES selemti.unidades_medida(id);

/* --------------------------------------------------------------
   D) PolÃ­ticas de consumo por sucursal (FEFO default / PEPS opcional)
   -------------------------------------------------------------- */
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='consumo_policy') THEN
    CREATE TYPE selemti.consumo_policy AS ENUM ('FEFO','PEPS');
  END IF;
END$$;

-- ParametrizaciÃ³n a nivel sucursal (si la tabla no existe, se crea mÃ­nima)
CREATE TABLE IF NOT EXISTS selemti.param_sucursal (
  id             SERIAL PRIMARY KEY,
  sucursal_id    TEXT UNIQUE NOT NULL,
  consumo        selemti.consumo_policy NOT NULL DEFAULT 'FEFO',
  tolerancia_precorte_pct NUMERIC(8,4) DEFAULT 0.02,
  tolerancia_corte_abs    NUMERIC(12,4) DEFAULT 50.0,
  created_at     TIMESTAMP NOT NULL DEFAULT now(),
  updated_at     TIMESTAMP NOT NULL DEFAULT now()
);

/* --------------------------------------------------------------
   E) PolÃ­ticas de stock (mÃ­n/max y alertas)
   -------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS selemti.stock_policy (
  id             BIGSERIAL PRIMARY KEY,
  item_id        TEXT NOT NULL,
  sucursal_id    TEXT NOT NULL,
  almacen_id     TEXT,                 -- opcional si manejas multi-almacÃ©n por sucursal
  min_qty        NUMERIC(14,6) NOT NULL DEFAULT 0,
  max_qty        NUMERIC(14,6) NOT NULL DEFAULT 0,
  reorder_lote   NUMERIC(14,6),        -- cantidad sugerida por OC
  activo         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (item_id, sucursal_id, COALESCE(almacen_id,'_'))
);

/* --------------------------------------------------------------
   F) RelaciÃ³n sucursalâ€“almacÃ©nâ€“terminal (Floreant)
   -------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS selemti.sucursal_almacen_terminal (
  id           SERIAL PRIMARY KEY,
  sucursal_id  TEXT        NOT NULL,
  almacen_id   TEXT        NOT NULL,             -- catÃ¡logo propio p.ej. "ALM-PRIN"
  terminal_id  INT         NULL,                 -- FK a public.terminal(id) si existe
  location     TEXT,                             
  descripcion  TEXT,
  activo       BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMP   NOT NULL DEFAULT now(),
  UNIQUE (sucursal_id, almacen_id, COALESCE(terminal_id,0))
);

/* --------------------------------------------------------------
   G) Modificadores POS con receta + JSONB en tickets
   -------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS selemti.modificadores_pos (
  id                 SERIAL PRIMARY KEY,
  codigo_pos         VARCHAR(40) UNIQUE NOT NULL,
  nombre             VARCHAR(120) NOT NULL,
  tipo               VARCHAR(20)  NOT NULL CHECK (tipo IN ('AGREGADO','SUSTITUCION','ELIMINACION')),
  precio_extra       NUMERIC(12,4) NOT NULL DEFAULT 0,
  receta_modificador_id TEXT,              -- id de receta del modificador (segÃºn tu catÃ¡logo)
  activo             BOOLEAN NOT NULL DEFAULT TRUE,
  created_at         TIMESTAMP NOT NULL DEFAULT now()
);

-- ticket_venta_det: capturar los modificadores aplicados por lÃ­nea
ALTER TABLE IF EXISTS selemti.ticket_venta_det
  ADD COLUMN IF NOT EXISTS modificadores_aplicados JSONB;

/* --------------------------------------------------------------
   H) Vista de mermas por Ã­tem (operativa semanal)
   -------------------------------------------------------------- */
CREATE OR REPLACE VIEW selemti.v_merma_por_item AS
SELECT
  m.item_id,
  date_trunc('week', m.ts)::date AS semana,
  SUM(CASE WHEN m.tipo = 'MERMA' THEN m.cantidad ELSE 0 END)                AS qty_mermada,  -- en canÃ³nica
  SUM(CASE WHEN m.tipo IN ('RECEPCION','COMPRA') THEN m.cantidad ELSE 0 END) AS qty_recibida,
  CASE 
    WHEN SUM(CASE WHEN m.tipo IN ('RECEPCION','COMPRA') THEN m.cantidad ELSE 0 END) > 0
    THEN ROUND(
      100.0 * SUM(CASE WHEN m.tipo='MERMA' THEN m.cantidad ELSE 0 END) /
      NULLIF(SUM(CASE WHEN m.tipo IN ('RECEPCION','COMPRA') THEN m.cantidad ELSE 0 END),0)
    , 2)
    ELSE 0
  END AS merma_pct
FROM selemti.mov_inv m
GROUP BY 1,2;

/* --------------------------------------------------------------
   I) Reglas sugeridas para traspasos de elaborados
   (documental: se registran dos mov_inv correlacionados por ref)
   -------------------------------------------------------------- */
-- No requiere nuevas tablas si ya se usa mov_inv + inventory_batch.
-- RecomendaciÃ³n: en tus servicios, registrar:
--  - salida en origen: ref_tipo='TRASPASO', ref_id=<id_traspaso>, batch_id=<lote_elaborado>
--  - entrada en destino: ref_tipo='TRASPASO', ref_id=<mismo id>, batch_id=<mismo lote>
--  - qty en canÃ³nica y qty_original/uom_original segÃºn UI (p.ej., PZ)

/* --------------------------------------------------------------
   J) Guardas e Ã­ndices complementarios (seguridad y performance)
   -------------------------------------------------------------- */
-- Ãndice para polÃ­ticas de stock lookup
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_stock_policy_item_suc' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_stock_policy_item_suc ON selemti.stock_policy(item_id, sucursal_id);
  END IF;
END$$;

-- Ãndice para modificadores en tickets (consulta por llave)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_ticketdet_mods_gin' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_ticketdet_mods_gin ON selemti.ticket_venta_det 
    USING GIN (modificadores_aplicados);
  END IF;
END$$;

/* --------------------------------------------------------------
   K) Defaults razonables / semillas mÃ­nimas (opcional)
   -------------------------------------------------------------- */
-- FEFO como default para sucursal "PRINCIPAL" si no existe
INSERT INTO selemti.param_sucursal (sucursal_id, consumo)
SELECT 'PRINCIPAL', 'FEFO'
WHERE NOT EXISTS (SELECT 1 FROM selemti.param_sucursal WHERE sucursal_id='PRINCIPAL');

/* ======================================================================
   FIN 010.delta_full_plus.sql
   - Compatibilidad PG 9.5
   - No usa particiones ni funciones avanzadas de versiÃ³n posterior.
   - Ejecutable mÃºltiples veces sin romper consistencia.
   ====================================================================== */

\n-- END 010.delta_full_plus.sql\n
\n-- BEGIN 011.delta_merma_desperdicio_porciones.sql\n
/* ======================================================================
   011.delta_merma_desperdicio_porciones.sql
   Complemento: Merma vs Desperdicio + Porcionamiento de preparaciones
   Compatibilidad: PostgreSQL 9.5, idempotente
   Supone: esquema selemti, OP/lotes internos, mov_inv y ticket_venta_* existentes
   ====================================================================== */

SET client_min_messages = WARNING;
SET TIME ZONE 'America/Mexico_City';
SET search_path TO selemti, public;

/* --------------------------------------------------------------
   1) ClasificaciÃ³n de pÃ©rdida: MERMA vs DESPERDICIO
   -------------------------------------------------------------- */
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='merma_clase') THEN
    CREATE TYPE selemti.merma_clase AS ENUM ('MERMA','DESPERDICIO');
  END IF;
END$$;

-- Tabla de pÃ©rdidas (operativa), enlazada al kardex (opcional en tu flujo).
-- Permite justificar salida por caducidad/proceso/servicio y evidenciarla.
CREATE TABLE IF NOT EXISTS selemti.perdida_log (
  id              BIGSERIAL PRIMARY KEY,
  ts              TIMESTAMP NOT NULL DEFAULT now(),
  item_id         TEXT      NOT NULL,
  lote_id         BIGINT,
  sucursal_id     TEXT,
  clase           selemti.merma_clase NOT NULL,     -- MERMA (aprovechable/esperable) o DESPERDICIO (no aprovechable)
  motivo          TEXT,                              -- texto libre: caducidad, sobrante servicio, contaminaciÃ³n, etc.
  qty_canonica    NUMERIC(14,6) NOT NULL CHECK (qty_canonica > 0),
  qty_original    NUMERIC(14,6),
  uom_original_id INT REFERENCES selemti.unidades_medida(id),
  evidencia_url   TEXT,                              -- foto/acta
  usuario_id      INT,
  ref_tipo        TEXT,                              -- p.ej. 'CIERRE_PREP'
  ref_id          BIGINT,
  created_at      TIMESTAMP NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_perdida_item_ts' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_perdida_item_ts ON selemti.perdida_log(item_id, ts DESC);
  END IF;
END$$;

/* --------------------------------------------------------------
   2) Porcionamiento de preparaciones: registro por ticket/plato
   -------------------------------------------------------------- */
-- Detalle de consumo por ticket (grano fino): quÃ© lote/preparaciÃ³n se usÃ³,
-- cuÃ¡nta cantidad (en canÃ³nica y original) y a quÃ© ticket_item se aplicÃ³.
CREATE TABLE IF NOT EXISTS selemti.ticket_det_consumo (
  id                  BIGSERIAL PRIMARY KEY,
  ticket_id           BIGINT     NOT NULL,           -- FK a ticket_venta_cab (lÃ³gico)
  ticket_det_id       BIGINT     NOT NULL,           -- FK a ticket_venta_det (lÃ³gico)
  item_id             TEXT       NOT NULL,           -- insumo o preparado consumido
  lote_id             BIGINT,                        -- lote especÃ­fico (incluye lotes internos de OP)
  qty_canonica        NUMERIC(14,6) NOT NULL CHECK (qty_canonica > 0),
  qty_original        NUMERIC(14,6),
  uom_original_id     INT REFERENCES selemti.unidades_medida(id),
  sucursal_id         TEXT,
  ref_tipo            TEXT,                          -- 'VENTA','OP','SERVICIO'
  ref_id              BIGINT,
  created_at          TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (ticket_det_id, item_id, lote_id, qty_canonica, COALESCE(uom_original_id,0))
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_tickcons_ticket' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_tickcons_ticket ON selemti.ticket_det_consumo (ticket_id, ticket_det_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_tickcons_lote' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_tickcons_lote ON selemti.ticket_det_consumo (item_id, lote_id);
  END IF;
END$$;

/* --------------------------------------------------------------
   3) Cierre de lote preparado (remanente â†’ merma o desperdicio)
   -------------------------------------------------------------- */
-- Al finalizar el turno/dÃ­a o al vencimiento, registra el remanente de una
-- preparaciÃ³n (lote interno) como salida + log de pÃ©rdida con clase.
-- Esta funciÃ³n no hace cÃ¡lculos de FEFO/PEPS, asume lote explÃ­cito.
CREATE OR REPLACE FUNCTION selemti.cerrar_lote_preparado(
  p_lote_id       BIGINT,
  p_clase         selemti.merma_clase,      -- 'MERMA' o 'DESPERDICIO'
  p_motivo        TEXT,
  p_usuario_id    INT DEFAULT NULL,
  p_uom_id        INT DEFAULT NULL          -- si envÃ­as qty_original/uom
) RETURNS BIGINT AS $$
DECLARE
  v_item_id        TEXT;
  v_qty_disponible NUMERIC(14,6);
  v_mov_id         BIGINT;
BEGIN
  -- Disponibilidad del lote (en canÃ³nica)
  SELECT b.item_id,
         COALESCE(SUM(CASE WHEN m.signo IS NULL THEN 0 ELSE m.signo * m.cantidad END),0)
  INTO   v_item_id, v_qty_disponible
  FROM   selemti.inventory_batch b
  LEFT JOIN selemti.v_kardex_por_lote m ON m.lote_id = b.id        -- o suma de mov_inv por lote
  WHERE  b.id = p_lote_id
  GROUP  BY b.item_id;

  IF v_item_id IS NULL THEN
    RAISE EXCEPTION 'Lote % no existe', p_lote_id;
  END IF;

  IF v_qty_disponible IS NULL OR v_qty_disponible <= 0 THEN
    RETURN 0; -- nada que cerrar
  END IF;

  -- 3.1) Registrar salida en kardex (MERMA operativa)
  INSERT INTO selemti.mov_inv (
    ts, item_id, lote_id, cantidad, qty_original, uom_original_id,
    tipo, ref_tipo, ref_id, sucursal_id
  )
  VALUES (
    now(), v_item_id, p_lote_id, 0 - v_qty_disponible, NULL, p_uom_id,
    'MERMA', 'CIERRE_PREP', p_lote_id, NULL
  )
  RETURNING id INTO v_mov_id;

  -- 3.2) Log de pÃ©rdida con clase (MERMA/DESPERDICIO)
  INSERT INTO selemti.perdida_log (
    ts, item_id, lote_id, clase, motivo, qty_canonica, uom_original_id,
    usuario_id, ref_tipo, ref_id
  ) VALUES (
    now(), v_item_id, p_lote_id, p_clase, p_motivo, v_qty_disponible, p_uom_id,
    p_usuario_id, 'CIERRE_PREP', v_mov_id
  );

  RETURN v_mov_id;
END;
$$ LANGUAGE plpgsql;

/* --------------------------------------------------------------
   4) Vistas KPI: Merma vs Desperdicio y Rendimiento de preparaciÃ³n
   -------------------------------------------------------------- */
-- 4.1) KPI por semana y clase (MERMA/DESPERDICIO)
CREATE OR REPLACE VIEW selemti.v_perdida_clase_semana AS
SELECT
  item_id,
  date_trunc('week', ts)::date AS semana,
  clase,
  SUM(qty_canonica) AS qty_canonica
FROM selemti.perdida_log
GROUP BY 1,2,3;

-- 4.2) Rendimiento de preparaciÃ³n: usa OP (teÃ³rico) vs entregado (real) y consumo registrado
-- Nota: ajusta nombres de tablas de OP/lotes internos segÃºn tu esquema.
-- Este es un esqueleto que asume:
--   - selemti.op_produccion (id, receta_id, qty_planeada, qty_real, lote_resultado_id, ts_cierre)
--   - v_kardex_por_lote suma mov_inv por lote.
CREATE OR REPLACE VIEW selemti.v_rendimiento_preparacion AS
SELECT
  op.id                       AS op_id,
  op.receta_id,
  op.lote_resultado_id        AS lote_id,
  op.qty_planeada,
  op.qty_real,
  (CASE WHEN op.qty_planeada IS NULL OR op.qty_planeada=0 THEN NULL
        ELSE ROUND(100.0 * op.qty_real / op.qty_planeada, 2) END) AS rendimiento_pct,
  kardex.saldo_final_canonica AS saldo_lote_canonica,
  (CASE WHEN op.qty_real IS NULL OR op.qty_real=0 THEN NULL
        ELSE ROUND(100.0 * kardex.saldo_final_canonica / op.qty_real, 2) END) AS sobrante_pct
FROM selemti.op_produccion op
LEFT JOIN (
  SELECT
    lote_id,
    SUM(CASE WHEN signo IS NULL THEN 0 ELSE signo * cantidad END) AS saldo_final_canonica
  FROM selemti.v_kardex_por_lote   -- o arma una suma de mov_inv por lote
  GROUP BY lote_id
) kardex ON kardex.lote_id = op.lote_resultado_id;

/* --------------------------------------------------------------
   5) Vista de porciones por ticket (para preparaciones compartidas)
   -------------------------------------------------------------- */
CREATE OR REPLACE VIEW selemti.v_porciones_por_ticket AS
SELECT
  tdc.ticket_id,
  tdc.ticket_det_id,
  tdc.item_id       AS insumo_preparado,
  tdc.lote_id,
  SUM(tdc.qty_canonica) AS qty_total_canonica,
  COUNT(*)              AS usos
FROM selemti.ticket_det_consumo tdc
GROUP BY 1,2,3,4;

/* ======================================================================
   FIN 011.delta_merma_desperdicio_porciones.sql
   ====================================================================== */

\n-- END 011.delta_merma_desperdicio_porciones.sql\n
\n-- BEGIN precorte.sql\n
CREATE TABLE pc_precorte (
    id                bigserial PRIMARY KEY,
    terminal_id       integer NOT NULL REFERENCES public.terminal(id),
    terminal_location text NOT NULL,
    cashier_user_id   integer NOT NULL REFERENCES public.users(auto_id),
    from_ts           timestamptz NOT NULL,
    to_ts             timestamptz NOT NULL,
    opening_cash      numeric(12,2) DEFAULT 0,
    system_sales      numeric(12,2) DEFAULT 0,
    system_cash_exp   numeric(12,2) DEFAULT 0,
    system_card_exp   numeric(12,2) DEFAULT 0,
    system_other_exp  numeric(12,2) DEFAULT 0,
    counted_cash      numeric(12,2) DEFAULT 0,
    declared_card     numeric(12,2) DEFAULT 0,
    declared_other    numeric(12,2) DEFAULT 0,
    cash_diff         numeric(12,2) DEFAULT 0,
    card_diff         numeric(12,2) DEFAULT 0,
    other_diff        numeric(12,2) DEFAULT 0,
    discounts_cnt     integer DEFAULT 0,
    voids_cnt         integer DEFAULT 0,
    refunds_cnt       integer DEFAULT 0,
    open_tickets_cnt  integer DEFAULT 0,
    tips_cash         numeric(12,2) DEFAULT 0,
    tips_card         numeric(12,2) DEFAULT 0,
    notes             text,
    warnings          jsonb DEFAULT '[]'::jsonb,
    status            text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'PRINTED')),
    created_at        timestamptz NOT NULL DEFAULT now(),
    created_by        integer NOT NULL REFERENCES public.users(auto_id),
    submitted_at      timestamptz,
    submitted_by      integer REFERENCES public.users(auto_id),
    approved_at       timestamptz,
    approved_by       integer REFERENCES public.users(auto_id),
    CONSTRAINT unique_precorte UNIQUE (terminal_id, cashier_user_id, from_ts, to_ts, status)
);

CREATE TABLE pc_precorte_cash_count (
    id          bigserial PRIMARY KEY,
    precorte_id bigint NOT NULL REFERENCES pc_precorte(id) ON DELETE CASCADE,
    denom       numeric(8,2) NOT NULL,
    qty         integer NOT NULL,
    subtotal    numeric(12,2) ,
    other_denom numeric(8,2),
    other_desc  text
);

CREATE TABLE pc_precorte_payments (
    id           bigserial PRIMARY KEY,
    precorte_id  bigint NOT NULL REFERENCES pc_precorte(id) ON DELETE CASCADE,
    method       text NOT NULL CHECK (method IN ('CASH', 'DEBIT_CARD', 'CREDIT_CARD', 'GIFT_CARD', 'TRANSFER', 'OTHER')),
    brand        text CHECK (brand IN ('VISA', 'MASTERCARD', 'AMEX', 'OTHER', NULL)),
    terminal_ext text,
    amount       numeric(12,2) NOT NULL
);

CREATE TABLE pc_precorte_adjustments (
    id           bigserial PRIMARY KEY,
    precorte_id  bigint NOT NULL REFERENCES pc_precorte(id) ON DELETE CASCADE,
    kind         text NOT NULL CHECK (kind IN ('FALTANTE', 'SOBRANTE', 'ERROR', 'MERMAS', 'PAYOUT', 'DROP', 'NOSALE')),
    description  text,
    amount       numeric(12,2) NOT NULL DEFAULT 0
);

CREATE TABLE pc_precorte_audit (
    id           bigserial PRIMARY KEY,
    precorte_id  bigint NOT NULL REFERENCES pc_precorte(id) ON DELETE CASCADE,
    at           timestamptz NOT NULL DEFAULT now(),
    actor_user   integer NOT NULL REFERENCES public.users(auto_id),
    action       text NOT NULL CHECK (action IN ('CREATE', 'UPDATE', 'SUBMIT', 'APPROVE', 'REJECT', 'PRINT')),
    details      jsonb
);

-- Ãndices recomendados
CREATE INDEX idx_pc_precorte_terminal ON pc_precorte (terminal_id, from_ts, to_ts);
CREATE INDEX idx_pc_precorte_cashier ON pc_precorte (cashier_user_id, from_ts, to_ts);
CREATE INDEX idx_pc_precorte_warnings ON pc_precorte USING GIN (warnings);

-- Vistas SQL adaptadas al esquema del dump
CREATE VIEW vw_precorte_sales AS
SELECT
    t.terminal_id,
    t.owner_id AS cashier_user_id,
    t.branch_key AS terminal_location,
    SUM(t.total_amount) AS total_sales,
    SUM(t.discount) AS total_discounts,
    SUM(t.tip_amount) AS total_tips,
    COUNT(*) FILTER (WHERE t.voided = true) AS voids_cnt,
    COUNT(*) FILTER (WHERE t.total_amount < 0 OR t.ticket_type = 'REFUND') AS refunds_cnt,
    COUNT(*) FILTER (WHERE t.closed = false OR t.paid = false) AS open_tickets_cnt
FROM public.ticket t
WHERE t.create_date AT TIME ZONE 'America/Mexico_City' >= $1
    AND t.create_date AT TIME ZONE 'America/Mexico_City' < $2
    AND (t.voided = false OR t.voided IS NULL)
GROUP BY t.terminal_id, t.owner_id, t.branch_key;

CREATE VIEW vw_precorte_payments AS
SELECT
    tr.terminal_id,
    tr.user_id AS cashier_user_id,
    t.branch_key AS terminal_location,
    tr.transaction_type AS method,
    tr.card_type AS brand,
    SUM(tr.amount) AS amount,
    SUM(CASE WHEN tr.transaction_type = 'CASH' THEN tr.tip_amount ELSE 0 END) AS tips_cash,
    SUM(CASE WHEN tr.transaction_type IN ('CREDIT_CARD', 'DEBIT_CARD') THEN tr.tip_amount ELSE 0 END) AS tips_card
FROM public.transactions tr
JOIN public.ticket t ON t.id = tr.ticket_id
WHERE t.create_date AT TIME ZONE 'America/Mexico_City' >= $1
    AND t.create_date AT TIME ZONE 'America/Mexico_City' < $2
    AND (t.voided = false OR t.voided IS NULL)
GROUP BY tr.terminal_id, tr.user_id, t.branch_key, tr.transaction_type, tr.card_type;

CREATE VIEW vw_precorte_discounts AS
SELECT
    t.terminal_id,
    t.owner_id AS cashier_user_id,
    t.branch_key AS terminal_location,
    COUNT(*) AS discounts_cnt,
    SUM(ti.discount_amount) AS discounts_amount
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE t.create_date AT TIME ZONE 'America/Mexico_City' >= $1
    AND t.create_date AT TIME ZONE 'America/Mexico_City' < $2
    AND (t.voided = false OR t.voided IS NULL)
    AND ti.discount_amount > 0
GROUP BY t.terminal_id, t.owner_id, t.branch_key;

CREATE VIEW vw_precorte_voids AS
SELECT
    t.terminal_id,
    t.owner_id AS cashier_user_id,
    t.branch_key AS terminal_location,
    COUNT(*) AS voids_cnt,
    SUM(ti.unit_price * ti.item_count) AS voids_amount
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE t.create_date AT TIME ZONE 'America/Mexico_City' >= $1
    AND t.create_date AT TIME ZONE 'America/Mexico_City' < $2
    AND (t.voided = false OR t.voided IS NULL)
    AND ti.voided = true
GROUP BY t.terminal_id, t.owner_id, t.branch_key;
\n-- END precorte.sql\n
\n-- BEGIN Triger_corte_final.sql\n
-- ===========================================
--  SELEM POS â€” Despliegue auxiliar (v0.1)
--  Compatibilidad: PostgreSQL 9.5+
--  Objetivo: conciliaciÃ³n por sesiÃ³n de cajÃ³n
--  Autor: Tavo+ChatGPT
-- ===========================================

-- ===========================================
-- 0) DIAGNÃ“STICO (opcional pero recomendado)
--    Esto NO crea objetos; imprime cÃ³mo se llaman
--    las columnas relevantes para alinear mapeos.
-- ===========================================
DO $diag$
DECLARE
  tx_time_col TEXT;
  tx_amt_col  TEXT;
  tx_pay_col  TEXT;
  tx_type_col TEXT;
  tk_close_col TEXT;
  dah_assign_col TEXT;
  dah_release_col TEXT;
  term_balance_col TEXT;
BEGIN
  RAISE NOTICE '=== DIAGNÃ“STICO DE ESQUEMA (transactions) ===';
  SELECT column_name INTO tx_time_col
    FROM information_schema.columns
   WHERE table_name='transactions'
     AND column_name IN ('tx_time','transaction_time','created','date','time','paid_time')
   ORDER BY CASE column_name
              WHEN 'tx_time' THEN 1
              WHEN 'transaction_time' THEN 2
              WHEN 'created' THEN 3
              WHEN 'date' THEN 4
              WHEN 'time' THEN 5
              WHEN 'paid_time' THEN 6
            END
   LIMIT 1;
  SELECT column_name INTO tx_amt_col
    FROM information_schema.columns
   WHERE table_name='transactions'
     AND column_name IN ('amount','total','value','amt')
   LIMIT 1;
  SELECT column_name INTO tx_pay_col
    FROM information_schema.columns
   WHERE table_name='transactions'
     AND column_name IN ('payment_type','tender_type','pay_type','method','payment_code')
   LIMIT 1;
  SELECT column_name INTO tx_type_col
    FROM information_schema.columns
   WHERE table_name='transactions'
     AND column_name IN ('transaction_type','type','txn_type')
   LIMIT 1;

  RAISE NOTICE 'transactions: tiempo=% , monto=% , payment=% , txn_type=%',
               COALESCE(tx_time_col,'(NO ENCONTRADO)'),
               COALESCE(tx_amt_col,'(NO ENCONTRADO)'),
               COALESCE(tx_pay_col,'(NO ENCONTRADO)'),
               COALESCE(tx_type_col,'(NO ENCONTRADO)');

  RAISE NOTICE '=== DIAGNÃ“STICO DE ESQUEMA (ticket) ===';
  SELECT column_name INTO tk_close_col
    FROM information_schema.columns
   WHERE table_name='ticket'
     AND column_name IN ('closed_time','close_time','paid_time','modified_time','update_time')
   LIMIT 1;
  RAISE NOTICE 'ticket: closed_time=%', COALESCE(tk_close_col,'(NO ENCONTRADO)');

  RAISE NOTICE '=== DIAGNÃ“STICO DE ESQUEMA (drawer_assigned_history) ===';
  SELECT column_name INTO dah_assign_col
    FROM information_schema.columns
   WHERE table_name='drawer_assigned_history'
     AND column_name IN ('assigned_time','assigned_at','created','start_time')
   LIMIT 1;
  SELECT column_name INTO dah_release_col
    FROM information_schema.columns
   WHERE table_name='drawer_assigned_history'
     AND column_name IN ('released_time','released_at','end_time','closed')
   LIMIT 1;
  RAISE NOTICE 'drawer_assigned_history: assigned=% , released=%',
               COALESCE(dah_assign_col,'(NO ENCONTRADO)'),
               COALESCE(dah_release_col,'(NO ENCONTRADO)');

  RAISE NOTICE '=== DIAGNÃ“STICO DE ESQUEMA (terminal) ===';
  SELECT column_name INTO term_balance_col
    FROM information_schema.columns
   WHERE table_name='terminal'
     AND column_name IN ('current_balance','opening_balance','balance')
   LIMIT 1;
  RAISE NOTICE 'terminal: current_balance=%', COALESCE(term_balance_col,'(NO ENCONTRADO)');
END
$diag$;

-- ===========================================
-- 1) PARÃMETROS (ajusta SOLO si tu esquema difiere)
--    Si el diagnÃ³stico anterior te dio otros nombres,
--    cÃ¡mbialos aquÃ­ para que todo funcione.
-- ===========================================
DO $params$
BEGIN
  -- Mapa de columnas de transactions
  PERFORM set_config('selempos.tx_time_col',  'tx_time',            true);
  PERFORM set_config('selempos.tx_amount_col','amount',             true);
  PERFORM set_config('selempos.tx_pay_col',   'payment_type',       true);
  PERFORM set_config('selempos.tx_type_col',  'transaction_type',   true);

  -- ticket cerrado
  PERFORM set_config('selempos.ticket_closed_col','closed_time',    true);

  -- drawer_assigned_history tiempos
  PERFORM set_config('selempos.dah_assigned_col','assigned_time',   true);
  PERFORM set_config('selempos.dah_released_col','released_time',   true);

  -- terminal balance
  PERFORM set_config('selempos.terminal_balance_col','current_balance', true);
END
$params$;

-- Helper para referenciar columnas configuradas
CREATE OR REPLACE FUNCTION selempos_col(name TEXT)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
  SELECT current_setting(name,true)
$$;

-- ===========================================
-- 2) ESQUEMA AUXILIAR
-- ===========================================
CREATE SCHEMA IF NOT EXISTS selempos;

-- SesiÃ³n de cajÃ³n (ventana de tiempo + snapshot opening_float)
CREATE TABLE IF NOT EXISTS selempos.selempos_drawer_session (
  id BIGSERIAL PRIMARY KEY,
  terminal_id INTEGER NOT NULL,
  cashier_user_id INTEGER NOT NULL,
  drawer_assigned_history_id BIGINT,
  opened_at TIMESTAMPTZ NOT NULL,
  closed_at TIMESTAMPTZ,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE','READY_FOR_CUT','CUT_DONE','POSTCUT_DONE')) DEFAULT 'ACTIVE',
  opening_float NUMERIC(12,2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by INTEGER,
  CONSTRAINT ux_selempos_session UNIQUE (terminal_id, cashier_user_id, opened_at)
);
CREATE INDEX IF NOT EXISTS ix_selempos_session_terminal ON selempos.selempos_drawer_session(terminal_id, opened_at);
CREATE INDEX IF NOT EXISTS ix_selempos_session_cashier  ON selempos.selempos_drawer_session(cashier_user_id, opened_at);

-- Precorte (declarado)
CREATE TABLE IF NOT EXISTS selempos.selempos_precorte (
  id BIGSERIAL PRIMARY KEY,
  session_id BIGINT NOT NULL REFERENCES selempos.selempos_drawer_session(id) ON DELETE CASCADE,
  declared_cash NUMERIC(12,2) NOT NULL DEFAULT 0,
  declared_other NUMERIC(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL CHECK (status IN ('PENDING','SUBMITTED','APPROVED','REJECTED')) DEFAULT 'PENDING',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by INTEGER,
  client_ip INET
);

-- Detalle de efectivo por denominaciÃ³n (opcional)
CREATE TABLE IF NOT EXISTS selempos.selempos_precorte_cash (
  id BIGSERIAL PRIMARY KEY,
  precorte_id BIGINT NOT NULL REFERENCES selempos.selempos_precorte(id) ON DELETE CASCADE,
  denom NUMERIC(12,2) NOT NULL,
  qty   INTEGER NOT NULL,
  subtotal NUMERIC(12,2) 
);

-- Postcorte (conciliaciÃ³n final)
CREATE TABLE IF NOT EXISTS selempos.selempos_postcorte (
  id BIGSERIAL PRIMARY KEY,
  session_id BIGINT NOT NULL REFERENCES selempos.selempos_drawer_session(id) ON DELETE CASCADE,
  declared_cash_final  NUMERIC(12,2) NOT NULL DEFAULT 0,
  declared_cards_final NUMERIC(12,2) NOT NULL DEFAULT 0,
  system_cash          NUMERIC(12,2) NOT NULL DEFAULT 0,
  system_cards         NUMERIC(12,2) NOT NULL DEFAULT 0,
  diff_cash            NUMERIC(12,2) NOT NULL DEFAULT 0,
  diff_cards           NUMERIC(12,2) NOT NULL DEFAULT 0,
  closed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by INTEGER
);

-- Mapa de formas de pago (ajustable a tu transactions)
CREATE TABLE IF NOT EXISTS selempos.selempos_payment_map (
  code TEXT PRIMARY KEY,     -- 'CASH','DEBIT','CREDIT','TRANSFER'
  match_expr TEXT NOT NULL   -- valor en transactions.(payment_type o transaction_type)
);
INSERT INTO selempos.selempos_payment_map(code, match_expr) VALUES
('CASH','CASH'),
('DEBIT','DEBIT'),
('CREDIT','CREDIT'),
('TRANSFER','TRANSFER')
ON CONFLICT DO NOTHING;

-- AuditorÃ­a simple
CREATE TABLE IF NOT EXISTS selempos.selempos_audit (
  id BIGSERIAL PRIMARY KEY,
  who INTEGER,
  what TEXT,
  payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ===========================================
-- 3) VISTAS DE TOTALES POR SESIÃ“N
-- ===========================================
-- 3.1 ventas por forma de pago en ventana de sesiÃ³n
CREATE OR REPLACE VIEW selempos.selempos_vw_session_sales AS
WITH base AS (
  SELECT
    s.id AS session_id,
    t.(SELECT selempos_col('selempos.tx_amount_col'))::TEXT::NUMERIC AS amount,
    pm.code AS payment_code
  FROM selempos.selempos_drawer_session s
  JOIN transactions t
    ON t.(SELECT selempos_col('selempos.tx_time_col')) >= s.opened_at
   AND t.(SELECT selempos_col('selempos.tx_time_col')) < COALESCE(s.closed_at, now())
   AND t.terminal_id = s.terminal_id
   AND t.user_id     = s.cashier_user_id
  JOIN selempos.selempos_payment_map pm
    ON (t.(SELECT selempos_col('selempos.tx_pay_col'))  = pm.match_expr
     OR  t.(SELECT selempos_col('selempos.tx_type_col')) = pm.match_expr)
)
SELECT session_id, payment_code, SUM(amount) AS amount
FROM base
GROUP BY session_id, payment_code;

-- 3.2 descuentos (ajusta si tus descuentos estÃ¡n en otras tablas)
-- Si tus descuentos viven en ticket_discount/ticket_item_discount con timestamp y user/terminal:
CREATE OR REPLACE VIEW selempos.selempos_vw_session_discounts AS
SELECT s.id AS session_id, COALESCE(SUM(d.amount),0) AS discounts
FROM selempos.selempos_drawer_session s
LEFT JOIN ticket_discount d
  ON d.created_at >= s.opened_at
 AND d.created_at <  COALESCE(s.closed_at, now())
 AND d.terminal_id = s.terminal_id
 AND d.user_id     = s.cashier_user_id
GROUP BY s.id;

-- 3.3 anulaciones/devoluciones (VOID/REFUND) sobre ticket
CREATE OR REPLACE VIEW selempos.selempos_vw_session_voids AS
SELECT s.id AS session_id,
       COALESCE(SUM(CASE WHEN tk.status IN ('VOID','REFUND') THEN tk.total ELSE 0 END),0) AS void_total
FROM selempos.selempos_drawer_session s
LEFT JOIN ticket tk
  ON tk.(SELECT selempos_col('selempos.ticket_closed_col')) >= s.opened_at
 AND tk.(SELECT selempos_col('selempos.ticket_closed_col')) <  COALESCE(s.closed_at, now())
 AND tk.terminal_id = s.terminal_id
 AND tk.owner_id    = s.cashier_user_id
GROUP BY s.id;

-- 3.4 retiros/egresos (payouts/expenses) en ventana
CREATE OR REPLACE VIEW selempos.selempos_vw_session_payouts AS
SELECT s.id AS session_id, COALESCE(SUM(t.(SELECT selempos_col('selempos.tx_amount_col'))::TEXT::NUMERIC),0) AS payouts
FROM selempos.selempos_drawer_session s
JOIN transactions t
  ON t.(SELECT selempos_col('selempos.tx_time_col')) >= s.opened_at
 AND t.(SELECT selempos_col('selempos.tx_time_col')) <  COALESCE(s.closed_at, now())
 AND t.terminal_id = s.terminal_id
 AND t.user_id     = s.cashier_user_id
WHERE t.(SELECT selempos_col('selempos.tx_type_col')) IN ('PAYOUT','EXPENSE')
GROUP BY s.id;

-- 3.5 devoluciones EN EFECTIVO (si aplica)
CREATE OR REPLACE VIEW selempos.selempos_vw_session_cash_refunds AS
SELECT s.id AS session_id,
       COALESCE(SUM(t.(SELECT selempos_col('selempos.tx_amount_col'))::TEXT::NUMERIC),0) AS cash_refunds
FROM selempos.selempos_drawer_session s
JOIN transactions t
  ON t.(SELECT selempos_col('selempos.tx_time_col')) >= s.opened_at
 AND t.(SELECT selempos_col('selempos.tx_time_col')) <  COALESCE(s.closed_at, now())
 AND t.terminal_id = s.terminal_id
 AND t.user_id     = s.cashier_user_id
WHERE (t.(SELECT selempos_col('selempos.tx_type_col')) IN ('REFUND','RETURN') OR t.status='REFUND')
  AND (t.(SELECT selempos_col('selempos.tx_pay_col')) = 'CASH' OR t.(SELECT selempos_col('selempos.tx_type_col')) = 'CASH')
GROUP BY s.id;

-- 3.6 balance sintetizado con esperado en caja
CREATE OR REPLACE VIEW selempos.selempos_vw_session_balance AS
SELECT
  s.id AS session_id,
  s.terminal_id,
  s.cashier_user_id,
  s.opened_at,
  s.closed_at,
  s.status,
  s.opening_float,
  COALESCE(SUM(CASE WHEN sales.payment_code='CASH' THEN sales.amount END),0) AS sys_cash,
  COALESCE(SUM(CASE WHEN sales.payment_code IN ('DEBIT','CREDIT','TRANSFER') THEN sales.amount END),0) AS sys_non_cash,
  COALESCE(vd.discounts,0)  AS sys_discounts,
  COALESCE(vv.void_total,0) AS sys_voids,
  COALESCE(vp.payouts,0)    AS sys_payouts,
  COALESCE(vcr.cash_refunds,0) AS sys_cash_refunds,
  ( s.opening_float
    + COALESCE(SUM(CASE WHEN sales.payment_code='CASH' THEN sales.amount END),0)
    - COALESCE(vp.payouts,0)
    - COALESCE(vcr.cash_refunds,0)
  ) AS sys_expected_cash
FROM selempos.selempos_drawer_session s
LEFT JOIN selempos.selempos_vw_session_sales       sales ON sales.session_id = s.id
LEFT JOIN selempos.selempos_vw_session_discounts   vd    ON vd.session_id    = s.id
LEFT JOIN selempos.selempos_vw_session_voids       vv    ON vv.session_id    = s.id
LEFT JOIN selempos.selempos_vw_session_payouts     vp    ON vp.session_id    = s.id
LEFT JOIN selempos.selempos_vw_session_cash_refunds vcr  ON vcr.session_id   = s.id
GROUP BY s.id, s.terminal_id, s.cashier_user_id, s.opened_at, s.closed_at, s.status,
         s.opening_float, vd.discounts, vv.void_total, vp.payouts, vcr.cash_refunds;

-- ===========================================
-- 4) TRIGGERS DE SINCRONIZACIÃ“N CON ASIGNACIÃ“N DE CAJÃ“N
--    Al asignar: crea sesiÃ³n y toma snapshot de terminal.current_balance
--    Al liberar: cierra ventana y avanza estado
-- ===========================================
CREATE OR REPLACE FUNCTION selempos.selempos_fn_on_drawer_assigned_ins()
RETURNS TRIGGER LANGUAGE plpgsql AS
$$
DECLARE
  v_opening NUMERIC(12,2) := 0;
  v_exists  BIGINT;
  v_assigned_col TEXT := current_setting('selempos.dah_assigned_col', true);
  v_bal_col      TEXT := current_setting('selempos.terminal_balance_col', true);
  v_assigned_ts  TIMESTAMPTZ;
  v_sql TEXT;
BEGIN
  -- obtener assigned_time (columna parametrizada)
  v_sql := format('SELECT ($1).%I::timestamptz', v_assigned_col);
  EXECUTE v_sql USING NEW INTO v_assigned_ts;

  -- snapshot del fondo en terminal.current_balance (columna parametrizada)
  v_sql := format('SELECT COALESCE(%I,0)::numeric FROM terminal WHERE id = $1', v_bal_col);
  EXECUTE v_sql INTO v_opening USING NEW.terminal_id;

  -- evitar duplicados por reintentos
  SELECT s.id INTO v_exists
  FROM selempos.selempos_drawer_session s
  WHERE s.terminal_id      = NEW.terminal_id
    AND s.cashier_user_id  = NEW.user_id
    AND s.opened_at        = COALESCE(v_assigned_ts, now());

  IF v_exists IS NULL THEN
    INSERT INTO selempos.selempos_drawer_session(
      terminal_id, cashier_user_id, drawer_assigned_history_id,
      opened_at, status, opening_float, created_by
    )
    VALUES (
      NEW.terminal_id, NEW.user_id, NEW.id,
      COALESCE(v_assigned_ts, now()), 'ACTIVE', v_opening, NEW.user_id
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_selempos_drawer_assigned_ins ON drawer_assigned_history;
CREATE TRIGGER trg_selempos_drawer_assigned_ins
AFTER INSERT ON drawer_assigned_history
FOR EACH ROW EXECUTE FUNCTION selempos.selempos_fn_on_drawer_assigned_ins();

-- Cierre de sesiÃ³n al liberar cajÃ³n
CREATE OR REPLACE FUNCTION selempos.selempos_fn_on_drawer_assigned_upd()
RETURNS TRIGGER LANGUAGE plpgsql AS
$$
DECLARE
  v_released_col TEXT := current_setting('selempos.dah_released_col', true);
  v_released_ts  TIMESTAMPTZ;
  v_sql TEXT;
BEGIN
  IF NEW IS DISTINCT FROM OLD THEN
    v_sql := format('SELECT ($1).%I::timestamptz', v_released_col);
    EXECUTE v_sql USING NEW INTO v_released_ts;

    IF v_released_ts IS NOT NULL THEN
      UPDATE selempos.selempos_drawer_session s
      SET closed_at = v_released_ts,
          status = CASE WHEN s.status='ACTIVE' THEN 'READY_FOR_CUT' ELSE s.status END
      WHERE s.drawer_assigned_history_id = NEW.id
        AND s.closed_at IS NULL;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_selempos_drawer_assigned_upd ON drawer_assigned_history;
CREATE TRIGGER trg_selempos_drawer_assigned_upd
AFTER UPDATE ON drawer_assigned_history
FOR EACH ROW EXECUTE FUNCTION selempos.selempos_fn_on_drawer_assigned_upd();

-- ===========================================
-- 5) COMPROBACIONES RÃPIDAS
-- ===========================================
-- Â¿Sesiones activas?
-- SELECT * FROM selempos.selempos_drawer_session ORDER BY id DESC LIMIT 20;

-- Â¿Balance por sesiÃ³n?
-- SELECT * FROM selempos.selempos_vw_session_balance ORDER BY session_id DESC LIMIT 20;

-- ===========================================
-- FIN
-- ===========================================

\n-- END Triger_corte_final.sql\n
\n-- BEGIN triger_KDS.sql\n
-- Canal: kds_event
-- Requiere PostgreSQL >= 9.4 (usas 9.5, OK)

-- 1) FunciÃ³n de notificaciÃ³n
CREATE OR REPLACE FUNCTION public.kds_notify()
RETURNS trigger AS
$$
DECLARE
  v_ticket_id INT;
  v_pg_id     INT;
  v_item_id   INT;
  v_status    TEXT;
  v_total     INT;
  v_ready     INT;
  v_done      INT;
  v_type      TEXT;
BEGIN
  /*
    Esta funciÃ³n se dispara desde:
    - kitchen_ticket_item (insert/update status)
    - ticket_item        (insert/update status)
  */

  IF TG_TABLE_NAME = 'kitchen_ticket_item' THEN
    -- Cambios en cocina
    v_item_id := COALESCE(NEW.ticket_item_id, NEW.id);
    SELECT ti.ticket_id, ti.pg_id
      INTO v_ticket_id, v_pg_id
    FROM ticket_item ti
    WHERE ti.id = v_item_id;

    v_status := UPPER(COALESCE(NEW.status,''));
    v_type   := CASE WHEN TG_OP = 'INSERT' THEN 'item_upsert' ELSE 'item_status' END;

    PERFORM pg_notify(
      'kds_event',
      json_build_object(
        'type',      v_type,
        'ticket_id', v_ticket_id,
        'pg',        v_pg_id,
        'item_id',   v_item_id,
        'status',    v_status,
        'ts',        now()
      )::text
    );

  ELSIF TG_TABLE_NAME = 'ticket_item' THEN
    -- Nuevos Ã­tems o actualizaciones de estado en ticket_item
    v_item_id   := NEW.id;
    v_ticket_id := NEW.ticket_id;
    v_pg_id     := NEW.pg_id;
    v_status    := UPPER(COALESCE(NEW.status,''));

    IF TG_OP = 'INSERT' THEN
      v_type := 'item_insert';
    ELSE
      v_type := 'item_status';
    END IF;

    PERFORM pg_notify(
      'kds_event',
      json_build_object(
        'type',      v_type,
        'ticket_id', v_ticket_id,
        'pg',        v_pg_id,
        'item_id',   v_item_id,
        'status',    v_status,
        'ts',        now()
      )::text
    );
  END IF;

  -- Si tenemos contexto de ticket y Ã¡rea (pg), verificamos agregados
  IF v_ticket_id IS NOT NULL AND v_pg_id IS NOT NULL THEN
    SELECT
      COUNT(*) AS total,
      COUNT(*) FILTER (
        WHERE UPPER(COALESCE(kti.status, ti.status, '')) IN ('READY','DONE')
      ) AS ready,
      COUNT(*) FILTER (
        WHERE UPPER(COALESCE(kti.status, ti.status, '')) = 'DONE'
      ) AS done
    INTO v_total, v_ready, v_done
    FROM ticket_item ti
    LEFT JOIN kitchen_ticket_item kti ON kti.ticket_item_id = ti.id
    WHERE ti.ticket_id = v_ticket_id
      AND ti.pg_id     = v_pg_id;

    -- Todos listos (READY o DONE)
    IF v_total > 0 AND v_total = v_ready THEN
      PERFORM pg_notify(
        'kds_event',
        json_build_object(
          'type',      'ticket_all_ready',
          'ticket_id', v_ticket_id,
          'pg',        v_pg_id,
          'ts',        now()
        )::text
      );
    END IF;

    -- Todos terminados (DONE) -> usado por voz-events.php
    IF v_total > 0 AND v_total = v_done THEN
      PERFORM pg_notify(
        'kds_event',
        json_build_object(
          'type',      'ticket_all_done',
          'ticket_id', v_ticket_id,
          'pg',        v_pg_id,
          'ts',        now()
        )::text
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2) Triggers (se rehacen por si existen)

-- kitchen_ticket_item: insert + update de status
DROP TRIGGER IF EXISTS trg_kds_notify_kti ON public.kitchen_ticket_item;
CREATE TRIGGER trg_kds_notify_kti
AFTER INSERT OR UPDATE OF status ON public.kitchen_ticket_item
FOR EACH ROW
EXECUTE PROCEDURE public.kds_notify();

-- ticket_item: insert (aparecer al instante en KDS) + update de status (por si Floreant escribe ahÃ­)
DROP TRIGGER IF EXISTS trg_kds_notify_ti ON public.ticket_item;
CREATE TRIGGER trg_kds_notify_ti
AFTER INSERT OR UPDATE OF status ON public.ticket_item
FOR EACH ROW
EXECUTE PROCEDURE public.kds_notify();

\n-- END triger_KDS.sql\n
\n-- BEGIN selemti_hotfix_pg95_v2.sql\n

-- =====================================================================
--  Selemti Â· Hotfix PG 9.5 Compat v2 (post-deploy)
--  - Crea tablas faltantes: alert_cfg, merma_policy, ui_prefs
--  - Rehace vistas con tipos estables (drop + create)
--  - Ajusta UNIQUE con Ã­ndices parciales
--  - Reinstala trigger de recepciÃ³n_det si aplica
--  Idempotente para PG 9.5
-- =====================================================================

-- 0) Guard: esquema
CREATE SCHEMA IF NOT EXISTS selemti;

-- 1) Tablas faltantes (si no existen)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='alert_cfg'
  ) THEN
    EXECUTE $SQL$
      CREATE TABLE selemti.alert_cfg (
        id BIGSERIAL PRIMARY KEY,
        metric_key TEXT NOT NULL,
        defaults JSONB NOT NULL,
        scope JSONB
      );
    $SQL$;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='merma_policy'
  ) THEN
    EXECUTE $SQL$
      CREATE TABLE selemti.merma_policy (
        id           BIGSERIAL PRIMARY KEY,
        sucursal_id  INT NULL REFERENCES public.inventory_location(id),
        categoria    selemti.merma_categoria NOT NULL,
        th_warn      NUMERIC(14,2) NOT NULL DEFAULT 0,
        th_block     NUMERIC(14,2) NOT NULL DEFAULT 0,
        aut_req      selemti.nivel_aut NOT NULL DEFAULT 'SUPERVISOR',
        enabled      BOOLEAN NOT NULL DEFAULT TRUE
      );
    $SQL$;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='ui_prefs'
  ) THEN
    EXECUTE $SQL$
      CREATE TABLE selemti.ui_prefs (
        id           BIGSERIAL PRIMARY KEY,
        sucursal_id  INT NULL REFERENCES public.inventory_location(id),
        key          TEXT NOT NULL,
        value_json   JSONB NOT NULL
      );
    $SQL$;
  END IF;
END $$;

-- 2) Ãndices Ãºnicos parciales (sustituyen constraints no soportadas)
-- alert_cfg
DO $$
BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS uq_alert_cfg_metric_null_scope
    ON selemti.alert_cfg(metric_key)
    WHERE scope IS NULL;

  CREATE UNIQUE INDEX IF NOT EXISTS uq_alert_cfg_metric_scope
    ON selemti.alert_cfg(metric_key, scope)
    WHERE scope IS NOT NULL;
END $$;

-- merma_policy
DO $$
BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS uq_merma_policy_categoria_global
    ON selemti.merma_policy(categoria)
    WHERE sucursal_id IS NULL;

  CREATE UNIQUE INDEX IF NOT EXISTS uq_merma_policy_sucursal_categoria
    ON selemti.merma_policy(sucursal_id, categoria)
    WHERE sucursal_id IS NOT NULL;
END $$;

-- ui_prefs
DO $$
BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS uq_ui_prefs_key_global
    ON selemti.ui_prefs(key)
    WHERE sucursal_id IS NULL;

  CREATE UNIQUE INDEX IF NOT EXISTS uq_ui_prefs_sucursal_key
    ON selemti.ui_prefs(sucursal_id, key)
    WHERE sucursal_id IS NOT NULL;
END $$;

-- 3) Vistas (drop + create para evitar conflictos de tipo en PG 9.5)
-- 3.1 vw_bom_menu_item
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema='selemti' AND table_name='vw_bom_menu_item') THEN
    EXECUTE 'DROP VIEW selemti.vw_bom_menu_item';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='menu_item')
     AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='recepie')
     AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='recepie_item') THEN
    EXECUTE $SQL$
      CREATE VIEW selemti.vw_bom_menu_item AS
      SELECT
        mi.id               AS menu_item_id,
        mi.name::TEXT       AS menu_item_name,
        r.id                AS recepie_id,
        ri.inventory_item   AS inventory_item_id,
        ri.percentage::NUMERIC(14,6) AS percentage
      FROM public.menu_item mi
      JOIN public.recepie r       ON r.id = mi.recepie
      JOIN public.recepie_item ri ON ri.recepie_id = r.id;
    $SQL$;
  ELSE
    -- Si no existen tablas pÃºblicas, dejar vista vacÃ­a compatible
    EXECUTE $SQL$
      CREATE VIEW selemti.vw_bom_menu_item AS
      SELECT NULL::INT AS menu_item_id, NULL::TEXT AS menu_item_name,
             NULL::INT AS recepie_id, NULL::INT AS inventory_item_id,
             NULL::NUMERIC(14,6) AS percentage
      WHERE FALSE;
    $SQL$;
  END IF;
END $$;

-- 3.2 vw_conversion_sugerida â€” corregir ORDER BY para DISTINCT ON
DROP VIEW IF EXISTS selemti.vw_conversion_sugerida;
CREATE VIEW selemti.vw_conversion_sugerida AS
SELECT DISTINCT ON (ct.item_id, COALESCE(ct.vendor_id,-1), ct.presentacion)
  ct.item_id, ct.vendor_id, ct.presentacion,
  ct.unidad_presentacion_id, ct.unidad_canonica, ct.factor_a_canonica, ct.preferred
FROM selemti.conversion_template ct
WHERE ct.activo = TRUE
ORDER BY ct.item_id, COALESCE(ct.vendor_id,-1), ct.presentacion, ct.preferred DESC, ct.id DESC;

-- 4) Trigger recepcion_det (por si fallÃ³ antes)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='recepcion_det') THEN
    DROP TRIGGER IF EXISTS trg_recepcion_det_check ON selemti.recepcion_det;
    CREATE TRIGGER trg_recepcion_det_check
    BEFORE INSERT OR UPDATE ON selemti.recepcion_det
    FOR EACH ROW EXECUTE PROCEDURE selemti.trg_recepcion_det_check();
  END IF;
END $$;

-- =====================================================================
--  FIN HOTFIX v2
-- =====================================================================

\n-- END selemti_hotfix_pg95_v2.sql\n
\n-- BEGIN selemti_post_hotfix_checks_v2.sql\n

-- Checks v2
SELECT 'alert_cfg_exists' AS check, EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='alert_cfg'
) AS ok;

SELECT 'merma_policy_exists' AS check, EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='merma_policy'
) AS ok;

SELECT 'ui_prefs_exists' AS check, EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='ui_prefs'
) AS ok;

SELECT 'vw_bom_menu_item_ok' AS check, pg_get_viewdef('selemti.vw_bom_menu_item'::regclass) ILIKE '%name::text%' 
  AND pg_get_viewdef('selemti.vw_bom_menu_item'::regclass) ILIKE '%percentage::numeric%' AS ok;

SELECT 'vw_conv_ok_order' AS check, pg_get_viewdef('selemti.vw_conversion_sugerida'::regclass) ILIKE '%ORDER BY ct.item_id, COALESCE(ct.vendor_id,-1), ct.presentacion, ct.preferred DESC, ct.id DESC%' AS ok;

-- Unique partials present
SELECT 'uq_alert_cfg_metric_null_scope' AS check, EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='uq_alert_cfg_metric_null_scope'
) AS ok;

SELECT 'uq_merma_policy_sucursal_categoria' AS check, EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='uq_merma_policy_sucursal_categoria'
) AS ok;

SELECT 'uq_ui_prefs_sucursal_key' AS check, EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='uq_ui_prefs_sucursal_key'
) AS ok;

\n-- END selemti_post_hotfix_checks_v2.sql\n

-- Compat PG95: trigger para subtotal en pc_precorte_cash_count
DO $$ BEGIN
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='pc_precorte_cash_count') THEN
  EXECUTE $$
    CREATE OR REPLACE FUNCTION public.pc_precorte_cash_count_biu() RETURNS trigger AS $$
    BEGIN NEW.subtotal := NEW.denom * NEW.qty; RETURN NEW; END; $$ LANGUAGE plpgsql;
  $$;
  EXECUTE $$
    DO $$ BEGIN
    BEGIN CREATE TRIGGER pc_precorte_cash_count_biu BEFORE INSERT OR UPDATE ON public.pc_precorte_cash_count
      FOR EACH ROW EXECUTE FUNCTION public.pc_precorte_cash_count_biu();
    EXCEPTION WHEN duplicate_object THEN NULL; END; END $$;
  $$;
END IF;
END $$;
