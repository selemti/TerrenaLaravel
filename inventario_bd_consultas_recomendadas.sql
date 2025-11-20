-- ============================================================================
-- CONSULTAS RECOMENDADAS PARA SCHEMA SELEMTI - INVENTARIO
-- ============================================================================
-- Generado: 2025-11-17
-- Estas consultas optimizan operaciones comunes del módulo de inventario
-- ============================================================================

-- PARTE 1: CONSULTAS DE ITEMS Y CATEGORÍAS
-- ============================================================================

-- 1.1 Ver todos los items activos con su categoría y UOMs
SELECT
    i.id,
    i.nombre,
    i.item_code,
    ic.nombre as categoria,
    u_base.nombre as uom_base,
    u_compra.nombre as uom_compra,
    u_salida.nombre as uom_salida,
    i.costo_promedio,
    i.es_producible,
    i.es_consumible_operativo,
    i.es_empaque_to_go,
    i.perishable
FROM selemti.items i
LEFT JOIN selemti.item_categories ic ON i.category_id = ic.id
LEFT JOIN selemti.unidades_medida_legacy u_base ON i.unidad_medida_id = u_base.id
LEFT JOIN selemti.unidades_medida_legacy u_compra ON i.unidad_compra_id = u_compra.id
LEFT JOIN selemti.unidades_medida_legacy u_salida ON i.unidad_salida_id = u_salida.id
WHERE i.activo = true
ORDER BY ic.nombre, i.nombre;

-- 1.2 Items con stock bajo (para replenishment)
SELECT
    sp.id,
    i.id as item_id,
    i.nombre as item_nombre,
    sp.min_qty,
    sp.max_qty,
    sp.reorder_lote,
    u.nombre as uom_base
FROM selemti.stock_policy sp
JOIN selemti.items i ON sp.item_id = i.id
LEFT JOIN selemti.unidades_medida_legacy u ON i.unidad_medida_id = u.id
WHERE sp.activo = true
ORDER BY sp.sucursal_id, i.nombre;

-- 1.3 Validar conversiones de unidades disponibles
SELECT
    cu.id,
    u_o.codigo as unidad_origen,
    u_o.nombre as nombre_origen,
    u_d.codigo as unidad_destino,
    u_d.nombre as nombre_destino,
    cu.factor_conversion,
    cu.precision_estimada,
    cu.activo
FROM selemti.conversiones_unidad_legacy cu
JOIN selemti.unidades_medida_legacy u_o ON cu.unidad_origen_id = u_o.id
JOIN selemti.unidades_medida_legacy u_d ON cu.unidad_destino_id = u_d.id
WHERE cu.activo = true
ORDER BY u_o.nombre, u_d.nombre;

-- PARTE 2: CONSULTAS DE KARDEX (mov_inv)
-- ============================================================================

-- 2.1 Movimientos de un item en un período (optimizado con índices)
SELECT
    m.id,
    m.ts,
    m.tipo,
    m.cantidad,
    m.qty_original,
    u.nombre as uom_original,
    m.costo_unit,
    m.ref_tipo,
    m.ref_id,
    l.codigo as lote_codigo,
    l.caducidad
FROM selemti.mov_inv m
LEFT JOIN selemti.unidades_medida_legacy u ON m.uom_original_id = u.id
LEFT JOIN selemti.lote l ON m.lote_id = l.id
WHERE m.item_id = ?
  AND m.ts >= ? AND m.ts < ?
ORDER BY m.ts DESC;

-- 2.2 Balance de inventario por item (FIFO/LIFO)
SELECT
    i.id,
    i.nombre,
    COALESCE(SUM(CASE WHEN m.tipo = 'ENTRADA' THEN m.cantidad ELSE 0 END), 0) as entradas,
    COALESCE(SUM(CASE WHEN m.tipo = 'SALIDA' THEN m.cantidad ELSE 0 END), 0) as salidas,
    COALESCE(SUM(CASE WHEN m.tipo = 'AJUSTE' THEN m.cantidad ELSE 0 END), 0) as ajustes,
    COALESCE(SUM(m.cantidad), 0) as balance_total,
    u.nombre as uom
FROM selemti.items i
LEFT JOIN selemti.mov_inv m ON i.id = m.item_id
LEFT JOIN selemti.unidades_medida_legacy u ON i.unidad_medida_id = u.id
WHERE i.activo = true
GROUP BY i.id, i.nombre, u.nombre
ORDER BY i.nombre;

-- 2.3 Movimientos por tipo y período
SELECT
    m.tipo,
    COUNT(*) as cantidad_movimientos,
    SUM(m.cantidad) as cantidad_total,
    AVG(m.costo_unit) as costo_promedio,
    MIN(m.ts) as primer_movimiento,
    MAX(m.ts) as ultimo_movimiento
FROM selemti.mov_inv m
WHERE m.ts >= ? AND m.ts < ?
GROUP BY m.tipo
ORDER BY m.tipo;

-- 2.4 Movimientos asociados a una referencia (ej: recepción específica)
SELECT
    m.id,
    m.ts,
    i.nombre as item,
    m.cantidad,
    m.costo_unit,
    m.ref_tipo,
    m.ref_id,
    u.nombre as uom
FROM selemti.mov_inv m
JOIN selemti.items i ON m.item_id = i.id
LEFT JOIN selemti.unidades_medida_legacy u ON m.uom_original_id = u.id
WHERE m.ref_tipo = ? AND m.ref_id = ?
ORDER BY m.ts DESC;

-- PARTE 3: CONSULTAS DE RECEPCIONES
-- ============================================================================

-- 3.1 Recepciones pendientes o recientes
SELECT
    r.id,
    r.numero_recepcion,
    r.fecha_recepcion,
    r.ts,
    r.estado,
    r.total_canonico,
    r.total_presentaciones,
    r.almacen_id,
    COUNT(rd.id) as lineas,
    SUM(rd.qty) as cantidad_total
FROM selemti.recepcion_cab r
LEFT JOIN selemti.recepcion_det rd ON r.id = rd.recepcion_id AND rd.deleted_at IS NULL
WHERE r.deleted_at IS NULL
  AND r.ts >= ? AND r.ts < ?
GROUP BY r.id, r.numero_recepcion, r.fecha_recepcion, r.ts, r.estado,
         r.total_canonico, r.total_presentaciones, r.almacen_id
ORDER BY r.ts DESC;

-- 3.2 Detalle de una recepción específica
SELECT
    rd.id,
    i.nombre as item,
    i.id as item_id,
    rd.qty as cantidad,
    u.nombre as uom,
    rd.costo_unit,
    rd.qty * rd.costo_unit as subtotal,
    l.codigo as lote_codigo,
    l.caducidad,
    l.estado as lote_estado,
    rd.temperatura,
    rd.meta
FROM selemti.recepcion_det rd
JOIN selemti.items i ON rd.item_id = i.id
LEFT JOIN selemti.unidades_medida_legacy u ON rd.um_id = u.id
LEFT JOIN selemti.lote l ON rd.batch_id = l.id
WHERE rd.recepcion_id = ?
  AND rd.deleted_at IS NULL
ORDER BY i.nombre;

-- 3.3 Costo promedio ponderado por item (desde recepciones)
SELECT
    i.id,
    i.nombre,
    SUM(rd.qty) as cantidad_recibida,
    AVG(rd.costo_unit) as costo_promedio,
    SUM(rd.qty * rd.costo_unit) / NULLIF(SUM(rd.qty), 0) as costo_ponderado,
    MAX(r.ts) as ultima_recepcion
FROM selemti.recepcion_det rd
JOIN selemti.items i ON rd.item_id = i.id
JOIN selemti.recepcion_cab r ON rd.recepcion_id = r.id
WHERE r.deleted_at IS NULL
  AND rd.deleted_at IS NULL
  AND r.ts >= ? AND r.ts < ?
GROUP BY i.id, i.nombre
ORDER BY i.nombre;

-- PARTE 4: CONSULTAS DE LOTES/BATCHES
-- ============================================================================

-- 4.1 Lotes vencidos o próximos a vencer
SELECT
    l.id,
    i.nombre as item,
    l.codigo as lote_codigo,
    l.caducidad,
    l.estado,
    l.creado_ts,
    CURRENT_DATE - l.caducidad as dias_vencido,
    COUNT(m.id) as movimientos_relacionados
FROM selemti.lote l
JOIN selemti.items i ON l.item_id = i.id
LEFT JOIN selemti.mov_inv m ON l.id = m.lote_id
WHERE l.estado = 'ACTIVO'
  AND l.caducidad IS NOT NULL
  AND l.caducidad <= CURRENT_DATE + INTERVAL '30 days'
GROUP BY l.id, i.nombre, l.codigo, l.caducidad, l.estado, l.creado_ts
ORDER BY l.caducidad ASC;

-- 4.2 Stock vigente por lote (para FIFO)
SELECT
    l.id,
    i.nombre as item,
    l.codigo as lote_codigo,
    l.caducidad,
    COALESCE(SUM(m.cantidad), 0) as saldo_lote,
    u.nombre as uom
FROM selemti.lote l
JOIN selemti.items i ON l.item_id = i.id
LEFT JOIN selemti.mov_inv m ON l.id = m.lote_id
LEFT JOIN selemti.unidades_medida_legacy u ON i.unidad_medida_id = u.id
WHERE l.estado = 'ACTIVO'
GROUP BY l.id, i.nombre, l.codigo, l.caducidad, u.nombre
HAVING COALESCE(SUM(m.cantidad), 0) > 0
ORDER BY l.caducidad ASC;

-- PARTE 5: CONSULTAS DE CONTEOS DE INVENTARIO
-- ============================================================================

-- 5.1 Conteos recientes y su estado
SELECT
    ic.id,
    ic.folio,
    ic.estado,
    ic.programado_para,
    ic.iniciado_en,
    ic.cerrado_en,
    ic.almacen_id,
    ic.sucursal_id,
    ic.total_items,
    ic.total_variacion,
    COUNT(icl.id) as lineas_contadas
FROM selemti.inventory_counts ic
LEFT JOIN selemti.inventory_count_lines icl ON ic.id = icl.inventory_count_id
WHERE ic.estado IN ('BORRADOR', 'EN_PROGRESO', 'COMPLETADO')
GROUP BY ic.id, ic.folio, ic.estado, ic.programado_para, ic.iniciado_en,
         ic.cerrado_en, ic.almacen_id, ic.sucursal_id, ic.total_items, ic.total_variacion
ORDER BY ic.programado_para DESC NULLS LAST, ic.iniciado_en DESC NULLS LAST;

-- 5.2 Variaciones detectadas en un conteo
SELECT
    icl.id,
    i.nombre as item,
    icl.qty_teorica,
    icl.qty_contada,
    icl.qty_variacion,
    ROUND((icl.qty_variacion / NULLIF(icl.qty_teorica, 0) * 100)::numeric, 2) as porcentaje_variacion,
    icl.motivo,
    u.nombre as uom
FROM selemti.inventory_count_lines icl
JOIN selemti.items i ON icl.item_id = i.id
LEFT JOIN selemti.unidades_medida_legacy u ON icl.uom::integer = u.id
WHERE icl.inventory_count_id = ?
  AND icl.qty_variacion != 0
ORDER BY ABS(icl.qty_variacion) DESC;

-- 5.3 Resumen de variaciones por categoría
SELECT
    ic.nombre as categoria,
    COUNT(icl.id) as items_contados,
    SUM(CASE WHEN icl.qty_variacion > 0 THEN 1 ELSE 0 END) as sobrantes,
    SUM(CASE WHEN icl.qty_variacion < 0 THEN 1 ELSE 0 END) as faltantes,
    SUM(icl.qty_variacion) as variacion_total,
    AVG(ABS(icl.qty_variacion)) as variacion_promedio
FROM selemti.inventory_count_lines icl
JOIN selemti.items i ON icl.item_id = i.id
LEFT JOIN selemti.item_categories ic ON i.category_id = ic.id
WHERE icl.inventory_count_id = ?
GROUP BY ic.id, ic.nombre
ORDER BY variacion_total DESC;

-- PARTE 6: CONSULTAS DE TRANSFERENCIAS
-- ============================================================================

-- 6.1 Transferencias pendientes
SELECT
    t.id,
    t.guia,
    t.estado,
    t.created_at,
    a_orig.nombre as almacen_origen,
    a_dest.nombre as almacen_destino,
    COUNT(td.id) as items_cantidad
FROM selemti.transfer_cab t
LEFT JOIN selemti.almacen a_orig ON t.origen_almacen_id = a_orig.id
LEFT JOIN selemti.almacen a_dest ON t.destino_almacen_id = a_dest.id
LEFT JOIN selemti.transfer_det td ON t.id = td.transfer_id
WHERE t.estado IN ('CREADA', 'DESPACHADA')
GROUP BY t.id, t.guia, t.estado, t.created_at, a_orig.nombre, a_dest.nombre
ORDER BY t.created_at DESC;

-- 6.2 Detalle de una transferencia
SELECT
    td.id,
    i.nombre as item,
    td.cantidad as cantidad_original,
    td.cantidad_despachada,
    td.cantidad_recibida,
    COALESCE(td.cantidad_despachada, 0) - COALESCE(td.cantidad_recibida, 0) as pendiente_recibir
FROM selemti.transfer_det td
JOIN selemti.items i ON td.item_id = i.id
WHERE td.transfer_id = ?
ORDER BY i.nombre;

-- PARTE 7: CONSULTAS DE AUDITORÍA Y ANÁLISIS
-- ============================================================================

-- 7.1 Productos que no tienen movimientos en 30 días
SELECT
    i.id,
    i.nombre,
    i.item_code,
    ic.nombre as categoria,
    COALESCE(MAX(m.ts), i.updated_at) as ultimo_movimiento,
    CURRENT_TIMESTAMP - COALESCE(MAX(m.ts), i.updated_at) as tiempo_sin_movimiento
FROM selemti.items i
LEFT JOIN selemti.mov_inv m ON i.id = m.item_id
LEFT JOIN selemti.item_categories ic ON i.category_id = ic.id
WHERE i.activo = true
GROUP BY i.id, i.nombre, i.item_code, ic.nombre, i.updated_at
HAVING COALESCE(MAX(m.ts), i.updated_at) < CURRENT_TIMESTAMP - INTERVAL '30 days'
ORDER BY ultimo_movimiento DESC;

-- 7.2 Items con problemas de UOM (inconsistencias)
SELECT
    i.id,
    i.nombre,
    i.unidad_medida as uom_varchar,
    i.unidad_medida_id as uom_id_base,
    i.unidad_compra_id,
    i.unidad_salida_id,
    u_base.codigo as codigo_base,
    u_compra.codigo as codigo_compra,
    u_salida.codigo as codigo_salida
FROM selemti.items i
LEFT JOIN selemti.unidades_medida_legacy u_base ON i.unidad_medida_id = u_base.id
LEFT JOIN selemti.unidades_medida_legacy u_compra ON i.unidad_compra_id = u_compra.id
LEFT JOIN selemti.unidades_medida_legacy u_salida ON i.unidad_salida_id = u_salida.id
WHERE (i.unidad_medida IS NOT NULL AND i.unidad_medida != 'PZ')
   OR (i.unidad_medida_id IS NULL)
   OR (i.unidad_compra_id IS NULL)
   OR (i.unidad_salida_id IS NULL)
ORDER BY i.nombre;

-- 7.3 Items sin categoría asignada
SELECT
    i.id,
    i.nombre,
    i.item_code,
    i.categoria_id,
    i.category_id
FROM selemti.items i
WHERE (i.category_id IS NULL OR i.category_id = 0)
   AND i.activo = true
ORDER BY i.nombre;

-- PARTE 8: CONSULTAS PARA REPORTES
-- ============================================================================

-- 8.1 Reporte de recepción por proveedor
SELECT
    --p.id as proveedor_id,
    --p.nombre as proveedor,
    SUM(rd.qty) as cantidad_total,
    COUNT(DISTINCT r.id) as numero_recepciones,
    MIN(r.ts) as primer_recepcion,
    MAX(r.ts) as ultima_recepcion,
    SUM(rd.qty * rd.costo_unit) as total_costo
FROM selemti.recepcion_det rd
JOIN selemti.recepcion_cab r ON rd.recepcion_id = r.id
WHERE r.deleted_at IS NULL
  AND rd.deleted_at IS NULL
  AND r.ts >= ? AND r.ts < ?
GROUP BY r.proveedor_id
ORDER BY total_costo DESC;

-- 8.2 Movimientos por sucursal y período
SELECT
    m.sucursal_id,
    m.tipo as tipo_movimiento,
    COUNT(*) as numero_movimientos,
    SUM(m.cantidad) as cantidad_movida,
    AVG(m.costo_unit) as costo_promedio
FROM selemti.mov_inv m
WHERE m.ts >= ? AND m.ts < ?
GROUP BY m.sucursal_id, m.tipo
ORDER BY m.sucursal_id, m.tipo;

-- 8.3 Items por valor de costo (ABC)
SELECT
    i.id,
    i.nombre,
    i.costo_promedio,
    COALESCE(SUM(m.cantidad), 0) as cantidad_stock,
    COALESCE(SUM(m.cantidad), 0) * i.costo_promedio as valor_total,
    CASE
        WHEN COALESCE(SUM(m.cantidad), 0) * i.costo_promedio >= (
            SELECT PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY COALESCE(SUM(m.cantidad), 0) * i.costo_promedio)
            FROM selemti.mov_inv m2
            JOIN selemti.items i2 ON m2.item_id = i2.id
            WHERE m2.ts <= CURRENT_TIMESTAMP
        ) THEN 'A'
        WHEN COALESCE(SUM(m.cantidad), 0) * i.costo_promedio >= (
            SELECT PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY COALESCE(SUM(m.cantidad), 0) * i.costo_promedio)
            FROM selemti.mov_inv m2
            JOIN selemti.items i2 ON m2.item_id = i2.id
            WHERE m2.ts <= CURRENT_TIMESTAMP
        ) THEN 'B'
        ELSE 'C'
    END as categoria_abc
FROM selemti.items i
LEFT JOIN selemti.mov_inv m ON i.id = m.item_id AND m.ts <= CURRENT_TIMESTAMP
WHERE i.activo = true
GROUP BY i.id, i.nombre, i.costo_promedio
ORDER BY valor_total DESC;

-- ============================================================================
-- PARTE 9: VISTA CONSOLIDADA RECOMENDADA
-- ============================================================================
-- Crear esta vista para facilitar queries comunes

CREATE OR REPLACE VIEW selemti.v_inventario_consolidado AS
SELECT
    i.id as item_id,
    i.nombre as item_nombre,
    i.item_code,
    ic.nombre as categoria,
    u.nombre as uom,
    i.costo_promedio,
    i.perishable,
    i.es_producible,
    COALESCE(SUM(m.cantidad), 0) as stock_disponible,
    sp.min_qty,
    sp.max_qty,
    CASE
        WHEN COALESCE(SUM(m.cantidad), 0) < sp.min_qty THEN 'BAJO'
        WHEN COALESCE(SUM(m.cantidad), 0) > sp.max_qty THEN 'EXCESO'
        ELSE 'NORMAL'
    END as estado_stock,
    COUNT(DISTINCT l.id) as num_lotes_activos,
    MIN(l.caducidad) as proximo_vencimiento
FROM selemti.items i
LEFT JOIN selemti.item_categories ic ON i.category_id = ic.id
LEFT JOIN selemti.unidades_medida_legacy u ON i.unidad_medida_id = u.id
LEFT JOIN selemti.mov_inv m ON i.id = m.item_id
LEFT JOIN selemti.stock_policy sp ON i.id = sp.item_id
LEFT JOIN selemti.lote l ON i.id = l.item_id AND l.estado = 'ACTIVO'
WHERE i.activo = true
GROUP BY i.id, i.nombre, i.item_code, ic.nombre, u.nombre, i.costo_promedio,
         i.perishable, i.es_producible, sp.min_qty, sp.max_qty;

-- ============================================================================
-- PARAMETROS PARA QUERIES (? debe reemplazarse con valores reales)
-- ============================================================================
-- ? = item_id (varchar)
-- ? = fecha_inicio (timestamp)
-- ? = fecha_fin (timestamp)
-- ? = recepcion_id (bigint)
-- ? = conteo_id (bigint)
-- ? = transferencia_id (bigint)
-- ============================================================================
