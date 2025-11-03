-- =============================================================================
-- SCRIPT: 05_drop_tables_cash_fund_empty.sql
-- Fecha: 2025-11-02
-- Objetivo: Eliminar tablas duplicadas de Caja Chica que están vacías
-- =============================================================================

-- IMPORTANTE: Verificar qué tabla está usando el modelo CashFund ANTES de ejecutar
-- grep "protected \$table" app/Models/CashFund/CashFund.php

-- Verificación previa: Contar registros
SELECT
  'caja_fondo' as tabla,
  COUNT(*) as registros
FROM selemti.caja_fondo
UNION ALL
SELECT
  'cash_funds',
  COUNT(*)
FROM selemti.cash_funds
ORDER BY tabla;

-- Resultado esperado: 2 filas con 0 registros cada una

-- ADVERTENCIA: Verificar cuál tabla está siendo usada por el módulo CashFund
-- Opción 1: Si el modelo usa 'cash_fund_movements' (nuevo sistema), eliminar ambas vacías
-- Opción 2: Si el modelo usa alguna de estas, NO eliminar esa tabla

BEGIN;

-- Eliminar SOLO si ambas están vacías y NO son usadas por modelos activos
DROP TABLE IF EXISTS selemti.caja_fondo CASCADE;
DROP TABLE IF EXISTS selemti.cash_funds CASCADE;

COMMIT;

-- Verificación post-eliminación
SELECT tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename IN ('caja_fondo', 'cash_funds')
ORDER BY tablename;

-- Resultado esperado: 0 filas (ambas tablas eliminadas)

-- Verificar que las tablas del módulo CashFund activo permanecen
SELECT tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND (tablename LIKE 'cash_fund%' OR tablename LIKE 'caja_%')
ORDER BY tablename;

-- Resultado esperado: cash_fund_movements, cash_fund_settlements, cash_fund_arqueos, etc.
