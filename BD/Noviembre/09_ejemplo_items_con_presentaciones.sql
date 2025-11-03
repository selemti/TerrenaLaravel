-- =============================================================================
-- SCRIPT: 09_ejemplo_items_con_presentaciones.sql
-- Fecha: 2025-11-03
-- Objetivo: Ejemplos de alta de items con diferentes presentaciones de compra
-- =============================================================================
-- Ejemplos:
-- 1) Aceite de Soya Nutrioli 3 pzas de 946 ml
-- 2) Leche Deslactosada Member's Mark 12 pzas de 1 l c/u
-- 3) Producto Lácteo Nutri Deslactosada 12 pzas de 1.5 l
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1. CREAR CATEGORÍAS (Si no existen)
-- =============================================================================

INSERT INTO selemti.item_categories (nombre, descripcion, activo, created_at, updated_at)
VALUES
  ('Abarrotes', 'Productos de abarrotes y despensa', true, NOW(), NOW()),
  ('Lácteos', 'Productos lácteos y derivados', true, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 2. ALTA DE ITEMS CON PRESENTACIONES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- EJEMPLO 1: Aceite de Soya Nutrioli - 3 pzas de 946 ml
-- -----------------------------------------------------------------------------
-- Análisis:
--   - Se compra en PAQUETE de 3 unidades
--   - Cada unidad contiene 946 ml
--   - Unidad base: L (Litros)
--   - Factor de compra: 3 × 0.946 = 2.838 L por paquete

INSERT INTO selemti.items (
  id,
  nombre,
  descripcion,
  categoria_id,
  unidad_medida,          -- Legacy (aún usado en algunos reportes)
  unidad_medida_id,       -- Nueva: Unidad BASE (inventario)
  unidad_compra_id,       -- Nueva: Unidad de COMPRA
  factor_compra,          -- Factor: 1 unidad_compra = X unidades_base
  costo_promedio,
  activo,
  tipo,
  created_at,
  updated_at
) VALUES (
  'ACEITE-NUTRIOLI-01',                          -- ID único
  'Aceite de Soya Nutrioli',                     -- Nombre
  'Aceite vegetal de soya, presentación 3 pzas de 946 ml',  -- Descripción detallada
  'CAT-ABARR',                                   -- Categoría (max 10 chars, formato: CAT-%)
  'LT',                                          -- Legacy: LT
  2,                                             -- L (Litros) - ID de cat_unidades
  16,                                            -- PAQUETE - ID de cat_unidades
  2.838,                                         -- 1 PAQUETE = 2.838 L (3 × 0.946)
  150.00,                                        -- Costo promedio inicial
  true,                                          -- Activo
  'MATERIA_PRIMA',                               -- Tipo: MATERIA_PRIMA | ELABORADO | ENVASADO
  NOW(),
  NOW()
);

-- -----------------------------------------------------------------------------
-- EJEMPLO 2: Leche Deslactosada Member's Mark - 12 pzas de 1 l c/u
-- -----------------------------------------------------------------------------
-- Análisis:
--   - Se compra en CAJA de 12 unidades
--   - Cada unidad contiene 1 litro
--   - Unidad base: L
--   - Factor de compra: 12 × 1 = 12 L por caja

INSERT INTO selemti.items (
  id,
  nombre,
  descripcion,
  categoria_id,
  unidad_medida,
  unidad_medida_id,
  unidad_compra_id,
  factor_compra,
  perishable,             -- Es perecedero
  temperatura_min,        -- Temperatura mínima de almacenamiento
  temperatura_max,        -- Temperatura máxima
  costo_promedio,
  activo,
  tipo,
  created_at,
  updated_at
) VALUES (
  'LECHE-MEMBERS-01',
  'Leche Deslactosada Member''s Mark',          -- Nota: '' para escapar el apóstrofe
  'Leche deslactosada marca Member''s Mark, presentación 12 pzas de 1 l c/u',
  'CAT-LACT',                                    -- Categoría (max 10 chars)
  'LT',
  2,                                             -- L (Litros)
  12,                                            -- CAJA
  12.0,                                          -- 1 CAJA = 12 L (12 × 1)
  true,                                          -- Sí es perecedero
  2,                                             -- Min: 2°C
  8,                                             -- Max: 8°C
  220.00,                                        -- Costo promedio
  true,
  'MATERIA_PRIMA',                               -- Tipo: MATERIA_PRIMA | ELABORADO | ENVASADO
  NOW(),
  NOW()
);

-- -----------------------------------------------------------------------------
-- EJEMPLO 3: Producto Lácteo Nutri Deslactosada - 12 pzas de 1.5 l
-- -----------------------------------------------------------------------------
-- Análisis:
--   - Se compra en CAJA de 12 unidades
--   - Cada unidad contiene 1.5 litros
--   - Unidad base: L
--   - Factor de compra: 12 × 1.5 = 18 L por caja

INSERT INTO selemti.items (
  id,
  nombre,
  descripcion,
  categoria_id,
  unidad_medida,
  unidad_medida_id,
  unidad_compra_id,
  factor_compra,
  perishable,
  temperatura_min,
  temperatura_max,
  costo_promedio,
  activo,
  tipo,
  created_at,
  updated_at
) VALUES (
  'LECHE-NUTRI-01',
  'Producto Lácteo Nutri Deslactosada',
  'Producto lácteo deslactosado marca Nutri, presentación 12 pzas de 1.5 l',
  'CAT-LACT',                                    -- Categoría (max 10 chars)
  'LT',
  2,                                             -- L (Litros)
  12,                                            -- CAJA
  18.0,                                          -- 1 CAJA = 18 L (12 × 1.5)
  true,                                          -- Perecedero
  2,                                             -- Min: 2°C
  8,                                             -- Max: 8°C
  280.00,                                        -- Costo promedio
  true,
  'MATERIA_PRIMA',                               -- Tipo: MATERIA_PRIMA | ELABORADO | ENVASADO
  NOW(),
  NOW()
);

COMMIT;

-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================

SELECT
  i.id,
  i.nombre,
  ub.clave || ' (' || ub.nombre || ')' as unidad_base,
  uc.clave || ' (' || uc.nombre || ')' as unidad_compra,
  i.factor_compra,
  CASE
    WHEN i.factor_compra IS NOT NULL THEN
      '1 ' || uc.clave || ' = ' || i.factor_compra || ' ' || ub.clave
    ELSE
      'Sin conversión'
  END as conversion_texto,
  i.costo_promedio,
  CASE WHEN i.perishable THEN 'Sí' ELSE 'No' END as perecedero
FROM selemti.items i
LEFT JOIN selemti.cat_unidades ub ON i.unidad_medida_id = ub.id
LEFT JOIN selemti.cat_unidades uc ON i.unidad_compra_id = uc.id
WHERE i.id IN ('ACEITE-NUTRIOLI-01', 'LECHE-MEMBERS-01', 'LECHE-NUTRI-01')
ORDER BY i.id;

-- =============================================================================
-- EJEMPLO DE RECEPCIÓN DE COMPRA
-- =============================================================================
-- Cuando recibes una compra de estos productos, el sistema automáticamente
-- convierte la cantidad comprada a la unidad base usando factor_compra:
--
-- EJEMPLO: Recibes 5 CAJAS de Leche Member's Mark
--   - Cantidad recibida: 5 CAJAS
--   - Factor de compra: 12.0 L/CAJA
--   - Cantidad en inventario: 5 × 12.0 = 60 L
--
-- El inventario siempre se maneja en UNIDADES BASE (L, KG, PZ)
-- Las compras se registran en UNIDADES DE COMPRA (CAJA, PAQUETE, COSTAL)
-- Las recetas usan UNIDADES DE SALIDA/COCINA (ML, TAZA, PORCION)
--
-- FLUJO:
-- 1. COMPRA:    5 CAJAS × 12 L/CAJA = 60 L (se registra en mov_inv)
-- 2. INVENTARIO: 60 L disponibles (en unidad base)
-- 3. RECETA:    Requiere 500 ML (conversión: 500 ML = 0.5 L)
-- 4. CONSUMO:   Se descuentan 0.5 L del inventario
-- =============================================================================

SELECT
  'FLUJO DE EJEMPLO' as concepto,
  '1. Compra: 5 CAJAS × 12 L/CAJA = 60 L' as paso_1,
  '2. Inventario: 60 L en stock' as paso_2,
  '3. Receta: Requiere 500 ML (0.5 L)' as paso_3,
  '4. Después del consumo: 59.5 L en stock' as paso_4;
