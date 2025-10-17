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