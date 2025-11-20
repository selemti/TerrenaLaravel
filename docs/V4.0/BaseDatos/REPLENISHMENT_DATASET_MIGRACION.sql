-- =====================================================================
-- DATASET MÍNIMO OPERATIVO PARA MOTOR DE REPLENISHMENT
-- Proyecto: Terrena V4.1
-- Fecha: 2025-11-17
-- Autor: Claude Code (Especialista BD)
-- =====================================================================
-- IMPORTANTE: Este script usa SOLO columnas/tablas que existen en BD real
-- Basado en: BD_SCHEMA_SELEMTI.sql y BD_SCHEMA_PUBLIC.sql
-- =====================================================================

BEGIN;

-- =====================================================================
-- SECCIÓN 1: CREAR SUCURSAL Y ALMACENES SI NO EXISTEN
-- =====================================================================

-- Verificar si existe sucursal ID 1 (si no, crear una básica)
DO $$
BEGIN
    -- Nota: La tabla de sucursales puede ser 'sucursales' o 'cat_sucursales'
    -- Verificamos si existe y creamos solo si no hay ninguna

    IF NOT EXISTS (SELECT 1 FROM selemti.almacen LIMIT 1) THEN
        -- Si no hay almacenes, asumimos que no hay sucursales tampoco
        RAISE NOTICE 'Creando almacén por defecto...';

        INSERT INTO selemti.almacen (id, sucursal_id, nombre, activo)
        VALUES
            ('ALM-CENTRAL', 1, 'Almacén Central', true),
            ('ALM-COCINA', 1, 'Almacén Cocina', true),
            ('ALM-BARRA', 1, 'Almacén Barra', true)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- =====================================================================
-- SECCIÓN 2: SELECCIONAR 3 ITEMS REALES EXISTENTES
-- =====================================================================
-- Nota: Usamos items que YA existen en selemti.items
-- Si la tabla está vacía, creamos 3 items de ejemplo

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM selemti.items LIMIT 1) THEN
        RAISE NOTICE 'Creando items de ejemplo...';

        INSERT INTO selemti.items
            (id, nombre, descripcion, categoria_id, unidad_medida, perishable,
             costo_promedio, activo, tipo)
        VALUES
            ('ITEM-001', 'Aceite Vegetal 1L', 'Aceite vegetal para cocina', 'CAT-ABARROTES', 'L', false, 45.50, true, 'MATERIA_PRIMA'),
            ('ITEM-002', 'Harina de Trigo 1KG', 'Harina de trigo para repostería', 'CAT-ABARROTES', 'KG', false, 25.00, true, 'MATERIA_PRIMA'),
            ('ITEM-003', 'Leche Entera 1L', 'Leche entera pasteurizada', 'CAT-LACTEOS', 'L', true, 22.50, true, 'MATERIA_PRIMA')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- Almacenar en variable temporal los 3 items seleccionados
CREATE TEMP TABLE temp_items_replenishment AS
SELECT id, nombre, unidad_medida, costo_promedio
FROM selemti.items
WHERE activo = true
LIMIT 3;

-- =====================================================================
-- SECCIÓN 3: INSERTAR POLÍTICAS DE STOCK (inv_stock_policy)
-- =====================================================================
-- Nota: Usa tabla inv_stock_policy (NO stock_policy)
-- Columnas: id, item_id, sucursal_id, min_qty, max_qty, reorder_qty, activo

INSERT INTO selemti.inv_stock_policy
    (item_id, sucursal_id, min_qty, max_qty, reorder_qty, activo, created_at, updated_at)
SELECT
    t.id,
    1::bigint,          -- sucursal_id (bigint)
    10.000000,          -- min_qty (numeric 18,6)
    50.000000,          -- max_qty
    15.000000,          -- reorder_qty
    true,               -- activo
    NOW(),              -- created_at
    NOW()               -- updated_at
FROM temp_items_replenishment t
ON CONFLICT DO NOTHING;

-- =====================================================================
-- SECCIÓN 4: INSERTAR MOVIMIENTOS DE INVENTARIO (mov_inv)
-- =====================================================================
-- Últimos 30 días: ENTRADAS, SALIDAS, CONSUMOS simulados
-- Columnas: id, ts, item_id, lote_id, cantidad, costo_unit, tipo,
--           ref_tipo, ref_id, sucursal_id, usuario_id

-- 4.1 ENTRADAS (últimos 30 días - 3 entradas por item)
INSERT INTO selemti.mov_inv
    (ts, item_id, lote_id, cantidad, qty_original, uom_original_id, costo_unit,
     tipo, ref_tipo, ref_id, sucursal_id, usuario_id, created_at)
SELECT
    NOW() - (i * INTERVAL '10 days'),  -- Hace 0, 10, 20 días
    t.id,
    NULL,                               -- lote_id (puede ser NULL)
    30.000000,                          -- cantidad entrada
    30.000000,                          -- qty_original
    NULL,                               -- uom_original_id
    t.costo_promedio,                   -- costo_unit
    'ENTRADA',                          -- tipo
    'RECEPCION',                        -- ref_tipo
    1000 + i,                           -- ref_id (simula ID de recepción)
    'SUC-1',                            -- sucursal_id (varchar 30)
    1,                                  -- usuario_id
    NOW() - (i * INTERVAL '10 days')
FROM temp_items_replenishment t
CROSS JOIN generate_series(0, 2) AS i;

-- 4.2 SALIDAS/CONSUMOS (últimos 30 días - diarios)
INSERT INTO selemti.mov_inv
    (ts, item_id, lote_id, cantidad, qty_original, uom_original_id, costo_unit,
     tipo, ref_tipo, ref_id, sucursal_id, usuario_id, created_at)
SELECT
    NOW() - (i * INTERVAL '1 day'),    -- Diario últimos 30 días
    t.id,
    NULL,
    -2.500000,                          -- cantidad negativa (consumo)
    -2.500000,
    NULL,
    t.costo_promedio,
    'SALIDA',                           -- tipo
    'CONSUMO_POS',                      -- ref_tipo
    2000 + i,                           -- ref_id
    'SUC-1',
    1,
    NOW() - (i * INTERVAL '1 day')
FROM temp_items_replenishment t
CROSS JOIN generate_series(0, 29) AS i;  -- 30 días

-- 4.3 AJUSTES (2 por item en el mes)
INSERT INTO selemti.mov_inv
    (ts, item_id, lote_id, cantidad, qty_original, uom_original_id, costo_unit,
     tipo, ref_tipo, ref_id, sucursal_id, usuario_id, created_at)
SELECT
    NOW() - (i * INTERVAL '15 days'),  -- Hace 0 y 15 días
    t.id,
    NULL,
    CASE WHEN i = 0 THEN 5.000000 ELSE -3.000000 END,  -- Ajuste positivo y negativo
    CASE WHEN i = 0 THEN 5.000000 ELSE -3.000000 END,
    NULL,
    t.costo_promedio,
    'AJUSTE',
    'CONTEO_FISICO',
    3000 + i,
    'SUC-1',
    1,
    NOW() - (i * INTERVAL '15 days')
FROM temp_items_replenishment t
CROSS JOIN generate_series(0, 1) AS i;

-- =====================================================================
-- SECCIÓN 5: INSERTAR CONSUMOS POS (inv_consumo_pos + det)
-- =====================================================================
-- Simula consumos procesados de POS últimos 7 días

-- 5.1 Crear tickets simulados en public.ticket si no existen
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.ticket WHERE id BETWEEN 90001 AND 90007) THEN
        RAISE NOTICE 'Creando tickets simulados para consumos POS...';

        INSERT INTO public.ticket
            (id, create_date, closing_date, paid, voided, sub_total, total_price,
             terminal_id, owner_id, status)
        SELECT
            90000 + i,
            NOW() - (i * INTERVAL '1 day'),
            NOW() - (i * INTERVAL '1 day') + INTERVAL '1 hour',
            true,
            false,
            150.00,
            150.00,
            101,  -- terminal_id (debe existir en public.terminal)
            1,    -- owner_id (usuario)
            'CLOSED'
        FROM generate_series(1, 7) AS i
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- 5.2 Insertar en inv_consumo_pos (cabecera)
INSERT INTO selemti.inv_consumo_pos
    (ticket_id, ticket_item_id, sucursal_id, terminal_id, estado,
     requiere_reproceso, procesado, fecha_proceso, revertido, created_at)
SELECT
    90000 + i,          -- ticket_id
    NULL,               -- ticket_item_id (puede ser NULL)
    1,                  -- sucursal_id (integer)
    101,                -- terminal_id (integer)
    'PROCESADO',        -- estado
    false,              -- requiere_reproceso
    true,               -- procesado
    NOW() - (i * INTERVAL '1 day') + INTERVAL '2 hours',  -- fecha_proceso
    false,              -- revertido
    NOW() - (i * INTERVAL '1 day')
FROM generate_series(1, 7) AS i
ON CONFLICT DO NOTHING;

-- 5.3 Insertar en inv_consumo_pos_det (detalle)
-- Para cada consumo, agregar 1-2 items consumidos
INSERT INTO selemti.inv_consumo_pos_det
    (consumo_id, mp_id, uom_id, cantidad, factor, origen,
     requiere_reproceso, procesado, fecha_proceso, revertido)
SELECT
    c.id,                                -- consumo_id (FK a inv_consumo_pos)
    CAST(SUBSTRING(t.id FROM '[0-9]+') AS INTEGER),  -- mp_id (extraer número del item_id)
    1,                                   -- uom_id (UOM base)
    2.500000,                            -- cantidad consumida
    1.000000,                            -- factor
    'RECETA',                            -- origen
    false,
    true,
    c.fecha_proceso,
    false
FROM selemti.inv_consumo_pos c
CROSS JOIN temp_items_replenishment t
WHERE c.ticket_id BETWEEN 90001 AND 90007
  AND c.procesado = true
LIMIT 14;  -- 2 items por cada uno de los 7 consumos

-- =====================================================================
-- SECCIÓN 6: VERIFICAR STOCK INICIAL (si existe tabla stock)
-- =====================================================================
-- Nota: Según auditoría, tabla 'stock' NO existe en BD
-- El sistema calcula stock desde mov_inv
-- Por lo tanto, OMITIMOS esta sección

-- =====================================================================
-- SECCIÓN 7: VALIDACIONES FINALES
-- =====================================================================

-- Limpiar tabla temporal
DROP TABLE IF EXISTS temp_items_replenishment;

-- Mostrar resumen de datos insertados
DO $$
DECLARE
    v_items_count INTEGER;
    v_policies_count INTEGER;
    v_movements_count INTEGER;
    v_consumos_count INTEGER;
    v_consumos_det_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_items_count FROM selemti.items WHERE activo = true;
    SELECT COUNT(*) INTO v_policies_count FROM selemti.inv_stock_policy;
    SELECT COUNT(*) INTO v_movements_count FROM selemti.mov_inv;
    SELECT COUNT(*) INTO v_consumos_count FROM selemti.inv_consumo_pos;
    SELECT COUNT(*) INTO v_consumos_det_count FROM selemti.inv_consumo_pos_det;

    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DATASET MÍNIMO OPERATIVO - RESUMEN';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Items activos: %', v_items_count;
    RAISE NOTICE 'Políticas de stock: %', v_policies_count;
    RAISE NOTICE 'Movimientos de inventario: %', v_movements_count;
    RAISE NOTICE 'Consumos POS (cabecera): %', v_consumos_count;
    RAISE NOTICE 'Consumos POS (detalle): %', v_consumos_det_count;
    RAISE NOTICE '========================================';
    RAISE NOTICE '';

    -- Validar que hay datos suficientes
    IF v_policies_count < 3 THEN
        RAISE WARNING 'Se esperaban al menos 3 políticas de stock';
    END IF;

    IF v_movements_count < 90 THEN
        RAISE WARNING 'Se esperaban al menos 90 movimientos (30 días x 3 items)';
    END IF;

    RAISE NOTICE 'Dataset mínimo operativo creado exitosamente.';
END $$;

COMMIT;

-- =====================================================================
-- CONSULTAS DE VALIDACIÓN
-- =====================================================================
-- Ejecutar estas consultas manualmente para verificar la carga

-- 1. Validar políticas de stock
SELECT
    item_id,
    sucursal_id,
    min_qty,
    max_qty,
    reorder_qty,
    activo
FROM selemti.inv_stock_policy
ORDER BY item_id;

-- 2. Validar movimientos por tipo
SELECT
    tipo,
    COUNT(*) as total_movimientos,
    SUM(cantidad) as cantidad_total
FROM selemti.mov_inv
GROUP BY tipo
ORDER BY tipo;

-- 3. Validar consumos POS
SELECT
    COUNT(DISTINCT c.id) as consumos_cabecera,
    COUNT(d.id) as lineas_detalle,
    SUM(d.cantidad) as cantidad_total_consumida
FROM selemti.inv_consumo_pos c
LEFT JOIN selemti.inv_consumo_pos_det d ON c.id = d.consumo_id;

-- 4. Validar stock calculado (últimos movimientos por item)
SELECT
    item_id,
    COUNT(*) as num_movimientos,
    SUM(cantidad) as stock_teorico,
    MIN(ts) as primer_movimiento,
    MAX(ts) as ultimo_movimiento
FROM selemti.mov_inv
GROUP BY item_id
ORDER BY item_id;

-- 5. Validar cobertura de datos (últimos 30 días)
SELECT
    DATE(ts) as fecha,
    COUNT(*) as movimientos_dia,
    SUM(CASE WHEN tipo = 'ENTRADA' THEN cantidad ELSE 0 END) as entradas,
    SUM(CASE WHEN tipo = 'SALIDA' THEN ABS(cantidad) ELSE 0 END) as salidas
FROM selemti.mov_inv
WHERE ts >= NOW() - INTERVAL '30 days'
GROUP BY DATE(ts)
ORDER BY fecha DESC;

-- =====================================================================
-- FIN DEL SCRIPT
-- =====================================================================
