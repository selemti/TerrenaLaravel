-- =============================================================================
-- SCRIPT: 07_seed_unidades_medida.sql
-- Fecha: 2025-11-02
-- Objetivo: Dar de alta unidades de medida categorizadas para el sistema
-- =============================================================================

-- NOTA: Este sistema usa 3 unidades BASE (kg, L, pz) y todas las demás
--       son conversiones UOM para facilitar el uso en diferentes contextos.

BEGIN;

-- =============================================================================
-- 1. UNIDADES BASE (Normalización de Inventario)
-- =============================================================================
-- Estas son las únicas unidades "reales" del inventario.
-- Todo se convierte a estas unidades para cálculos.

INSERT INTO selemti.cat_unidades (clave, nombre, categoria, activo, created_at, updated_at) VALUES
('KG',    'Kilogramo',  'BASE', true, NOW(), NOW()),
('L',     'Litro',      'BASE', true, NOW(), NOW()),
('PZ',    'Pieza',      'BASE', true, NOW(), NOW());

-- =============================================================================
-- 2. UNIDADES DE COCINA (Para Recetas)
-- =============================================================================
-- Unidades que usan los chefs al crear recetas.
-- Se convierten automáticamente a BASE para inventario.

INSERT INTO selemti.cat_unidades (clave, nombre, categoria, activo, created_at, updated_at) VALUES
('G',      'Gramo',           'COCINA', true, NOW(), NOW()),
('MG',     'Miligramo',       'COCINA', true, NOW(), NOW()),
('ML',     'Mililitro',       'COCINA', true, NOW(), NOW()),
('TAZA',   'Taza',            'COCINA', true, NOW(), NOW()),
('CUCH',   'Cucharada',       'COCINA', true, NOW(), NOW()),
('CUCHT',  'Cucharadita',     'COCINA', true, NOW(), NOW()),
('PIZCA',  'Pizca',           'COCINA', true, NOW(), NOW()),
('VASO',   'Vaso',            'COCINA', true, NOW(), NOW());

-- =============================================================================
-- 3. UNIDADES DE COMPRA (Empaques de Proveedores)
-- =============================================================================
-- Unidades en las que se compran los insumos.
-- Cada una tiene una conversión específica a BASE.

INSERT INTO selemti.cat_unidades (clave, nombre, categoria, activo, created_at, updated_at) VALUES
('CAJA',    'Caja',           'COMPRA', true, NOW(), NOW()),
('COSTAL',  'Costal',         'COMPRA', true, NOW(), NOW()),
('BOTELLA', 'Botella',        'COMPRA', true, NOW(), NOW()),
('GARRAFA', 'Garrafón',       'COMPRA', true, NOW(), NOW()),
('PAQUETE', 'Paquete',        'COMPRA', true, NOW(), NOW()),
('CHAROLA', 'Charola',        'COMPRA', true, NOW(), NOW()),
('BOLSA',   'Bolsa',          'COMPRA', true, NOW(), NOW()),
('BOTE',    'Bote',           'COMPRA', true, NOW(), NOW()),
('LATA',    'Lata',           'COMPRA', true, NOW(), NOW()),
('FRASCO',  'Frasco',         'COMPRA', true, NOW(), NOW());

-- =============================================================================
-- 4. UNIDADES DE PORCIÓN (Salida/Servicio)
-- =============================================================================
-- Unidades para servir/vender platillos.

INSERT INTO selemti.cat_unidades (clave, nombre, categoria, activo, created_at, updated_at) VALUES
('PORCION',  'Porción',       'PORCION', true, NOW(), NOW()),
('RACION',   'Ración',        'PORCION', true, NOW(), NOW()),
('REBANADA', 'Rebanada',      'PORCION', true, NOW(), NOW()),
('PLATO',    'Plato',         'PORCION', true, NOW(), NOW()),
('ORDEN',    'Orden',         'PORCION', true, NOW(), NOW());

COMMIT;

-- Verificar
SELECT
  categoria,
  COUNT(*) as total,
  STRING_AGG(clave, ', ' ORDER BY clave) as unidades
FROM selemti.cat_unidades
GROUP BY categoria
ORDER BY
  CASE categoria
    WHEN 'BASE' THEN 1
    WHEN 'COCINA' THEN 2
    WHEN 'COMPRA' THEN 3
    WHEN 'PORCION' THEN 4
    ELSE 5
  END;
