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