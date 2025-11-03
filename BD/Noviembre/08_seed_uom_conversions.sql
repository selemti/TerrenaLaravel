-- =============================================================================
-- SCRIPT: 08_seed_uom_conversions.sql
-- Fecha: 2025-11-02
-- Objetivo: Crear conversiones UOM comunes entre unidades
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1. CONVERSIONES DE COCINA → BASE (Peso)
-- =============================================================================

-- Gramo → Kilogramo
INSERT INTO selemti.cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
SELECT
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'G'),
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'KG'),
  0.001,
  true,
  'global',
  'Conversión estándar: 1 gramo = 0.001 kg',
  NOW(), NOW();

-- Miligramo → Kilogramo
INSERT INTO selemti.cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
SELECT
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'MG'),
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'KG'),
  0.000001,
  true,
  'global',
  'Conversión estándar: 1 miligramo = 0.000001 kg',
  NOW(), NOW();

-- Pizca → Kilogramo (aproximado)
INSERT INTO selemti.cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
SELECT
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'PIZCA'),
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'KG'),
  0.0005,
  false,
  'global',
  'Aproximado: 1 pizca ≈ 0.5 gramos (0.0005 kg)',
  NOW(), NOW();

-- =============================================================================
-- 2. CONVERSIONES DE COCINA → BASE (Volumen)
-- =============================================================================

-- Mililitro → Litro
INSERT INTO selemti.cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
SELECT
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'ML'),
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'L'),
  0.001,
  true,
  'global',
  'Conversión estándar: 1 mililitro = 0.001 litros',
  NOW(), NOW();

-- Taza → Litro (estándar 240ml)
INSERT INTO selemti.cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
SELECT
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'TAZA'),
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'L'),
  0.240,
  true,
  'global',
  'Taza estándar: 1 taza = 240 ml = 0.240 litros',
  NOW(), NOW();

-- Cucharada → Litro (15ml)
INSERT INTO selemti.cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
SELECT
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'CUCH'),
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'L'),
  0.015,
  true,
  'global',
  'Cucharada estándar: 1 cucharada = 15 ml = 0.015 litros',
  NOW(), NOW();

-- Cucharadita → Litro (5ml)
INSERT INTO selemti.cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
SELECT
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'CUCHT'),
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'L'),
  0.005,
  true,
  'global',
  'Cucharadita estándar: 1 cucharadita = 5 ml = 0.005 litros',
  NOW(), NOW();

-- Vaso → Litro (250ml)
INSERT INTO selemti.cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
SELECT
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'VASO'),
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'L'),
  0.250,
  true,
  'global',
  'Vaso estándar: 1 vaso = 250 ml = 0.250 litros',
  NOW(), NOW();

-- =============================================================================
-- 3. CONVERSIONES BIDIRECCIONALES (Inversas automáticas)
-- =============================================================================
-- Nota: Las conversiones inversas se pueden calcular como 1/factor
-- Por ejemplo: Si 1 Gramo = 0.001 KG, entonces 1 KG = 1000 Gramos

-- Kilogramo → Gramo
INSERT INTO selemti.cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
SELECT
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'KG'),
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'G'),
  1000,
  true,
  'global',
  'Conversión inversa: 1 kg = 1000 gramos',
  NOW(), NOW();

-- Litro → Mililitro
INSERT INTO selemti.cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
SELECT
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'L'),
  (SELECT id FROM selemti.cat_unidades WHERE clave = 'ML'),
  1000,
  true,
  'global',
  'Conversión inversa: 1 litro = 1000 mililitros',
  NOW(), NOW();

COMMIT;

-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================

SELECT
  uo.clave || ' (' || uo.nombre || ')' as origen,
  ' → ',
  ud.clave || ' (' || ud.nombre || ')' as destino,
  c.factor,
  CASE WHEN c.is_exact THEN 'Exacta' ELSE 'Aproximada' END as tipo,
  c.notes as notas
FROM selemti.cat_uom_conversion c
JOIN selemti.cat_unidades uo ON c.origen_id = uo.id
JOIN selemti.cat_unidades ud ON c.destino_id = ud.id
ORDER BY ud.categoria, uo.categoria, c.factor;

-- Resumen
SELECT
  'Total conversiones creadas: ' || COUNT(*) as resultado
FROM selemti.cat_uom_conversion;
