-- =====================================================
-- SCRIPT 00: CREACIÓN DE ESQUEMA Y PERMISOS
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

COMMENT ON TABLE selemti.user_roles IS 'Asignación de roles a usuarios (RBAC)';

-- 3. TABLA MAESTRA DE ÍTEMS
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

COMMENT ON TABLE selemti.items IS 'Maestro de todos los ítems del sistema (insumos, productos terminados, categorías, ubicaciones)';

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

COMMENT ON TABLE selemti.mov_inv IS 'Kardex - Libro mayor de inventario. Cada movimiento genera un registro aquí';

-- 6. TABLA DE AUDITORÍA
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

COMMENT ON TABLE selemti.audit_log IS 'Registro completo de auditoría para cumplimiento APPCC y seguridad';

-- 7. TABLA DE CÓDIGOS DE ERROR
CREATE TABLE selemti.error_codes (
    code VARCHAR(10) PRIMARY KEY CHECK (code ~ '^[A-Z]{3}-[0-9]{3}$'),
    category VARCHAR(20) NOT NULL CHECK (category IN ('VALIDATION', 'BUSINESS', 'SECURITY', 'SYSTEM', 'INTEGRATION')),
    severity VARCHAR(10) NOT NULL CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    message_template TEXT NOT NULL,
    description TEXT,
    recovery_instructions TEXT
);

-- INSERTAR CÓDIGOS DE ERROR ESTÁNDAR
INSERT INTO selemti.error_codes VALUES 
('INV-001', 'BUSINESS', 'HIGH', 'Stock insuficiente para el ítem %s. Stock actual: %s, requerido: %s', 'Intento de movimiento que causaría stock negativo', 'Verificar inventario físico o recibir mercancía'),
('INV-002', 'BUSINESS', 'CRITICAL', 'Lote %s está bloqueado por motivo: %s', 'Intento de usar lote con estado BLOQUEADO o RECALL', 'Contactar al auditor APPCC para liberar el lote'),
('SEC-001', 'SECURITY', 'HIGH', 'Intento de acceso no autorizado al recurso %s por usuario %s', 'Violación de control de acceso RBAC', 'Verificar asignación de roles y permisos');

RAISE NOTICE 'Script 01 (Tablas maestras) ejecutado exitosamente';

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

-- =====================================================
-- SCRIPT 03: MÓDULO DE RECETAS/PRODUCCIÓN (6 TABLAS)
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- SECUENCIAS PARA RECETAS/PRODUCCIÓN
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

COMMENT ON TABLE selemti.receta_cab IS 'Maestro de recetas/platos del menú del restaurante';

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

RAISE NOTICE 'Script 03 (Módulo Recetas - 6 tablas) ejecutado exitosamente';


-- =====================================================
-- SCRIPT 04: MÓDULO DE VENTAS/KDS (5 TABLAS)
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
('COCINA_CALIENTE', 'Cocina Caliente', 'Preparación de platos que requieren cocción', 'Área principal cocina', NULL, 10, 15, true, NULL, NOW(), NOW()),
('COCINA_FRIA', 'Cocina Fría', 'Preparación de ensaladas y entradas frías', 'Área refrigerada cocina', NULL, 8, 10, true, NULL, NOW(), NOW()),
('BARRA', 'Barra', 'Preparación de bebidas y cocteles', 'Barra principal', NULL, 12, 8, true, NULL, NOW(), NOW()),
('POSTRES', 'Postres', 'Preparación de postres y dulces', 'Área postres', NULL, 6, 12, true, NULL, NOW(), NOW()),
('PANADERIA', 'Panadería', 'Preparación de pan y repostería', 'Área hornos', NULL, 5, 20, true, NULL, NOW(), NOW());

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

RAISE NOTICE 'Script 04 (Módulo Ventas/KDS - 5 tablas) ejecutado exitosamente';


-- =====================================================
-- SCRIPT 05: MÓDULO DE CAJA (3 TABLAS)
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

RAISE NOTICE 'Script 05 (Módulo Caja - 3 tablas) ejecutado exitosamente';


-- =====================================================
-- SCRIPT 06: MÓDULO APPCC (4 TABLAS)
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

-- INSERTAR PUNTOS DE CONTROL APPCC BÁSICOS
INSERT INTO selemti.appcc_puntos_control VALUES 
(1, 'PCC-RECEP-001', 'Recepción Productos Perecederos', 'RECEPCION', 'Crecimiento bacteriano', 'BIOLOGICO', 'Control de temperatura', 'Temperatura <= 4°C para productos refrigerados', 'CADA LOTE', 'Personal Almacén', 'Rechazar lote y notificar al proveedor', true, 1, NOW(), NULL, NOW(), NOW()),
(2, 'PCC-ALM-001', 'Almacenamiento Refrigerado', 'ALMACENAMIENTO', 'Crecimiento bacteriano', 'BIOLOGICO', 'Control temperatura neveras', 'Temperatura entre 0°C y 4°C', 'CADA 4 HORAS', 'Personal Cocina', 'Ajustar temperatura y verificar productos', true, 1, NOW(), NULL, NOW(), NOW()),
(3, 'PCC-COC-001', 'Cocción de Alimentos', 'COCCION', 'Supervivencia de microorganismos', 'BIOLOGICO', 'Control temperatura interna', 'Temperatura interna >= 75°C por 2 minutos', 'CADA BATCH', 'Chef', 'Extender tiempo de cocción', true, 1, NOW(), NULL, NOW(), NOW());

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

RAISE NOTICE 'Script 06 (Módulo APPCC - 4 tablas) ejecutado exitosamente';

-- =====================================================
-- SCRIPT 07: MÓDULO DE CONFIGURACIÓN (4 TABLAS)
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

-- INSERTAR PARÁMETROS CRÍTICOS DEL SISTEMA
INSERT INTO selemti.parametros_sistema VALUES 
(1, 'INV_TOLERANCIA_DIFERENCIA', 'Tolerancia para diferencias de inventario', '0.05', 'NUMERICO', 'INVENTARIO', 'Tolerancia permitida para diferencias en conteos físicos (5%)', '0.05', true, false, NULL, NOW(), NOW()),
(2, 'CAJA_TOLERANCIA_EFECTIVO', 'Tolerancia para diferencias de efectivo', '50.00', 'NUMERICO', 'CAJA', 'Tolerancia en pesos para diferencias de caja sin requerir aprobación', '50.00', true, false, NULL, NOW(), NOW()),
(3, 'APPCC_FRECUENCIA_MONITOREO', 'Frecuencia de monitoreo APPCC', '4', 'NUMERICO', 'APPCC', 'Horas entre monitoreos de puntos críticos', '4', true, true, NULL, NOW(), NOW()),
(4, 'KDS_TIEMPO_MAX_PREPARACION', 'Tiempo máximo de preparación', '30', 'NUMERICO', 'VENTAS', 'Tiempo máximo en minutos para preparación de platos', '30', true, false, NULL, NOW(), NOW()),
(5, 'SISTEMA_MODO_MANTENIMIENTO', 'Modo mantenimiento del sistema', 'false', 'BOOLEANO', 'GENERAL', 'Activa el modo mantenimiento del sistema', 'false', true, true, NULL, NOW(), NOW()),
(6, 'INV_POLITICA_CONSUMO', 'Política de consumo de inventario', 'FEFO', 'TEXTO', 'INVENTARIO', 'Política por defecto para consumo de inventario (FEFO/PEPS)', 'FEFO', true, false, NULL, NOW(), NOW());

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
    
    CHECK (rfc IS NULL OR rfc ~ '^[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}$')
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

-- INSERTAR UBICACIONES BÁSICAS
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

-- INSERTAR CATEGORÍAS BÁSICAS
INSERT INTO selemti.categorias_items VALUES 
('CAT-PROTEINA', 'Proteínas', 'Carnes, pescados, aves', 'INSUMO', NULL, '1101', 5.0, 7, true, NOW(), NOW()),
('CAT-LACTEO', 'Lácteos', 'Leche, queso, yogurt', 'INSUMO', NULL, '1102', 3.0, 10, true, NOW(), NOW()),
('CAT-VERDURA', 'Verduras', 'Verduras frescas', 'INSUMO', NULL, '1103', 8.0, 5, true, NOW(), NOW()),
('CAT-BEBIDA', 'Bebidas', 'Refrescos, jugos, agua', 'INSUMO', NULL, '1104', 1.0, 30, true, NOW(), NOW()),
('CAT-MENU', 'Platos del Menú', 'Productos terminados para venta', 'PRODUCTO_TERMINADO', NULL, '2101', 2.0, 1, true, NOW(), NOW());

RAISE NOTICE 'Script 07 (Módulo Configuración - 4 tablas) ejecutado exitosamente';


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
('chef.juan', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'Juan Pérez - Chef', 'SUR', true),
('almacen.maria', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'María García - Almacén', 'SUR', true),
('caja.carlos', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'Carlos López - Cajero', 'SUR', true);

INSERT INTO selemti.user_roles (user_id, role_id, assigned_by) VALUES 
(2, 'CHEF', 1),
(3, 'ALMACEN', 1),
(4, 'CAJERO', 1);

-- 4. INSERTAR ÍTEMS DE EJEMPLO (MATERIAS PRIMAS)
INSERT INTO selemti.items (id, nombre, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max) VALUES 
('PROT-POLLO-PECHUGA-1KG', 'Pechuga de Pollo', 'CAT-PROTEINA', 'KG', true, 0, 4),
('PROT-SALMON-FRESCO-1KG', 'Salmón Fresco', 'CAT-PROTEINA', 'KG', true, -2, 2),
('VERD-LECHUGA-ROMA-1KG', 'Lechuga Romana', 'CAT-VERDURA', 'KG', true, 1, 4),
('VERD-TOMATE-ROJO-1KG', 'Tomate Rojo', 'CAT-VERDURA', 'KG', true, 10, 15),
('LACT-QUESO-MOZZARELLA-1KG', 'Queso Mozzarella', 'CAT-LACTEO', 'KG', true, 2, 6),
('BEBID-AGUA-1LT', 'Agua Purificada', 'CAT-BEBIDA', 'LT', false, NULL, NULL);

-- 5. INSERTAR RECETAS DE EJEMPLO
INSERT INTO selemti.receta_cab (id, codigo_plato_pos, nombre_plato, categoria_cocina, tipo_preparacion, tiempo_preparacion_min, rendimiento_porciones, nivel_dificultad, activo, usuario_creador, costo_standard_porcion, precio_venta_sugerido) VALUES 
('REC-CEVICHE-CLASICO', 'CEV-001', 'Ceviche Clásico', 'PLATO_FUERTE', 'FRIA', 20, 4, 'MEDIA', true, 1, 45.00, 180.00),
('REC-ENSALADA-CESAR', 'ENS-001', 'Ensalada César', 'ENTRADA', 'FRIA', 15, 2, 'BAJA', true, 1, 35.00, 120.00);

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
('PROV-CARNICOS-LA-PALMA', 'Cárnicos La Palma', 'ALIMENTOS', 'A', true),
('PROV-PESCADOS-FRESCOS', 'Pescados Frescos del Pacífico', 'ALIMENTOS', 'A', true),
('PROV-HORTALIZAS-ORGANICAS', 'Hortalizas Orgánicas', 'ALIMENTOS', 'B', true);

RAISE NOTICE 'Script 08 (Datos iniciales) ejecutado exitosamente';


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