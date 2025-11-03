-- =============================================================================
-- SCRIPT: 09b_ejemplo_items_simplificado.sql
-- Fecha: 2025-11-03
-- Objetivo: Ejemplos SIMPLIFICADOS (sin UOM avanzadas) para demostrar concepto
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1. CREAR CATEGORÍAS
-- =============================================================================

INSERT INTO selemti.item_categories (nombre, descripcion, activo, created_at, updated_at)
VALUES
  ('Abarrotes', 'Productos de abarrotes y despensa', true, NOW(), NOW()),
  ('Lácteos', 'Productos lácteos y derivados', true, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 2. ALTA DE ITEMS - VERSIÓN SIMPLIFICADA
-- =============================================================================
-- NOTA: Como unidades_medida_legacy está vacía, por ahora solo usamos
-- los campos básicos sin las FKs avanzadas

-- Ejemplo 1: Aceite Nutrioli (3 pzas × 946 ml = 2.838 L)
INSERT INTO selemti.items (
  id,
  nombre,
  descripcion,
  categoria_id,
  unidad_medida,
  costo_promedio,
  activo,
  tipo
) VALUES (
  'ACEITE-NUT-01',
  'Aceite de Soya Nutrioli',
  'Aceite vegetal 3 pzas × 946 ml (2.838 L total)',
  'CAT-ABARR',
  'LT',
  150.00,
  true,
  'MATERIA_PRIMA'
);

-- Ejemplo 2: Leche Member's Mark (12 pzas × 1 L = 12 L)
INSERT INTO selemti.items (
  id,
  nombre,
  descripcion,
  categoria_id,
  unidad_medida,
  costo_promedio,
  perishable,
  temperatura_min,
  temperatura_max,
  activo,
  tipo
) VALUES (
  'LECHE-MEM-01',
  'Leche Deslactosada Member''s Mark',
  'Leche deslactosada 12 pzas × 1 L (12 L total)',
  'CAT-LACT',
  'LT',
  220.00,
  true,
  2,
  8,
  true,
  'MATERIA_PRIMA'
);

-- Ejemplo 3: Leche Nutri (12 pzas × 1.5 L = 18 L)
INSERT INTO selemti.items (
  id,
  nombre,
  descripcion,
  categoria_id,
  unidad_medida,
  costo_promedio,
  perishable,
  temperatura_min,
  temperatura_max,
  activo,
  tipo
) VALUES (
  'LECHE-NUT-01',
  'Producto Lácteo Nutri Deslactosada',
  'Producto lácteo 12 pzas × 1.5 L (18 L total)',
  'CAT-LACT',
  'LT',
  280.00,
  true,
  2,
  8,
  true,
  'MATERIA_PRIMA'
);

COMMIT;

-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================

SELECT
  id,
  nombre,
  descripcion,
  unidad_medida,
  costo_promedio,
  CASE WHEN perishable THEN 'Sí' ELSE 'No' END as perecedero
FROM selemti.items
WHERE id IN ('ACEITE-NUT-01', 'LECHE-MEM-01', 'LECHE-NUT-01')
ORDER BY id;

-- =============================================================================
-- EXPLICACIÓN DEL CONCEPTO
-- =============================================================================
--
-- CÓMO FUNCIONARÍA CON EL SISTEMA COMPLETO DE UOM:
--
-- 1. COMPRA:
--    - Proveedor vende: "1 CAJA de Leche Member's Mark" a $220
--    - Sistema registra:
--      * Cantidad comprada: 1 CAJA
--      * Unidad de compra: CAJA (unidad_compra_id)
--      * Factor: 12.0 (factor_compra)
--      * Equivalencia: 1 CAJA = 12 L
--
-- 2. INVENTARIO (mov_inv):
--    - Se registra en UNIDAD BASE: 12 L
--    - Costo unitario: $220 / 12 L = $18.33/L
--    - Stock actual: 12 L
--
-- 3. RECETA:
--    - Chef especifica: "500 ML de leche"
--    - Unidad de salida: ML (unidad_salida_id)
--    - Factor de conversión: 1 ML = 0.001 L
--    - Cantidad en base: 500 × 0.001 = 0.5 L
--
-- 4. CONSUMO:
--    - Se descuentan 0.5 L del inventario
--    - Stock restante: 11.5 L
--    - Costo: 0.5 L × $18.33/L = $9.17
--
-- =============================================================================

SELECT
  '✅ Items creados exitosamente' as status,
  COUNT(*) as total_items
FROM selemti.items
WHERE id LIKE 'ACEITE-NUT%' OR id LIKE 'LECHE-%';
