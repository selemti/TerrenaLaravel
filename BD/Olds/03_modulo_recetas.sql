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