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