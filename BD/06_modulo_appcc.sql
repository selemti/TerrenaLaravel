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