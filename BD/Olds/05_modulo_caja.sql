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