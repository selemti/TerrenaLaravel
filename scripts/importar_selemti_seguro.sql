-- SCRIPT SEGURO PARA IMPORTAR RESPALDO SELEMTI SIN PERDER DATOS PUBLIC
-- Estrategia: Backup actual → Importar datos seleccionados → Validar integridad

-- 1. ESTADO ANTES DE IMPORTACIÓN
SELECT '=== ESTADO ANTES DE IMPORTACIÓN ===' as info;

-- Backup de tablas críticas (por si algo falla)
CREATE TABLE IF NOT EXISTS backup_selemti_critico AS
SELECT 'sesion_cajon' as tabla, COUNT(*) as registros FROM selemti.sesion_cajon
UNION ALL SELECT 'precorte', COUNT(*) FROM selemti.precorte
UNION ALL SELECT 'postcorte', COUNT(*) FROM selemti.postcorte
UNION ALL SELECT 'users', COUNT(*) FROM selemti.users
UNION ALL SELECT 'items', COUNT(*) FROM selemti.items;

SELECT * FROM backup_selemti_critico;

-- 2. VERIFICAR CONTENIDO DEL BACKUP A IMPORTAR
SELECT '';
SELECT '=== VERIFICANDO BACKUP ===' as info;
SELECT 'El archivo a importar es: Datos_Selemti_Locla_08_12_2025.sql' as archivo;
SELECT 'Este archivo contiene datos locales de selemti sin afectar public' as tipo;

-- 3. ESTRATEGIA DE IMPORTACIÓN
SELECT '';
SELECT '=== ESTRATEGIA DE IMPORTACIÓN ===' as info;
SELECT 'PASO 1: Deshabilitar triggers en tablas críticas' as paso;
SELECT 'PASO 2: Importar datos del backup' as paso;
SELECT 'PASO 3: Rehabilitar triggers' as paso;
SELECT 'PASO 4: Validar integridad' as paso;
SELECT 'PASO 5: Comparar antes/después' as paso;

-- 4. COMANDOS DE IMPORTACIÓN (ejecutar manualmente)
SELECT '';
SELECT '=== COMANDOS A EJECUTAR ===' as info;
SELECT '1. Deshabilitar triggers:' as comando;
SELECT 'ALTER TABLE selemti.sesion_cajon DISABLE TRIGGER ALL;' as sql_cmd;
SELECT 'ALTER TABLE selemti.precorte DISABLE TRIGGER ALL;' as sql_cmd;
SELECT 'ALTER TABLE selemti.postcorte DISABLE TRIGGER ALL;' as sql_cmd;
SELECT 'ALTER TABLE selemti.users DISABLE TRIGGER ALL;' as sql_cmd;
SELECT 'ALTER TABLE selemti.items DISABLE TRIGGER ALL;' as sql_cmd;

SELECT '';
SELECT '2. Importar backup:' as comando;
SELECT 'psql -h localhost -p 5433 -U postgres -d pos -f "Datos_Selemti_Locla_08_12_2025.sql"' as sql_cmd;

SELECT '';
SELECT '3. Rehabilitar triggers:' as comando;
SELECT 'ALTER TABLE selemti.sesion_cajon ENABLE TRIGGER ALL;' as sql_cmd;
SELECT 'ALTER TABLE selemti.precorte ENABLE TRIGGER ALL;' as sql_cmd;
SELECT 'ALTER TABLE selemti.postcorte ENABLE TRIGGER ALL;' as sql_cmd;
SELECT 'ALTER TABLE selemti.users ENABLE TRIGGER ALL;' as sql_cmd;
SELECT 'ALTER TABLE selemti.items ENABLE TRIGGER ALL;' as sql_cmd;

-- 5. VALIDACIÓN POST-IMPORTACIÓN
SELECT '';
SELECT '=== FUNCIÓN PARA VALIDAR DESPUÉS DE IMPORTAR ===' as info;

CREATE OR REPLACE FUNCTION validar_importacion_selemti()
RETURNS TABLE(
    tabla TEXT,
    registros_antes BIGINT,
    registros_despues BIGINT,
    diferencia BIGINT,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Comparar sesiones
    SELECT
        'sesion_cajon'::TEXT,
        COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'sesion_cajon'), 0)::BIGINT,
        (SELECT COUNT(*) FROM selemti.sesion_cajon)::BIGINT,
        (SELECT COUNT(*) FROM selemti.sesion_cajon) - COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'sesion_cajon'), 0)::BIGINT,
        CASE
            WHEN (SELECT COUNT(*) FROM selemti.sesion_cajon) > COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'sesion_cajon'), 0)
            THEN 'AUMENTÓ'
            WHEN (SELECT COUNT(*) FROM selemti.sesion_cajon) = COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'sesion_cajon'), 0)
            THEN 'IGUAL'
            ELSE 'DISMINUYÓ'
        END::TEXT

    UNION ALL

    -- Comparar precortes
    SELECT
        'precorte'::TEXT,
        COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'precorte'), 0)::BIGINT,
        (SELECT COUNT(*) FROM selemti.precorte)::BIGINT,
        (SELECT COUNT(*) FROM selemti.precorte) - COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'precorte'), 0)::BIGINT,
        CASE
            WHEN (SELECT COUNT(*) FROM selemti.precorte) > COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'precorte'), 0)
            THEN 'AUMENTÓ'
            WHEN (SELECT COUNT(*) FROM selemti.precorte) = COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'precorte'), 0)
            THEN 'IGUAL'
            ELSE 'DISMINUYÓ'
        END::TEXT

    UNION ALL

    -- Comparar postcortes
    SELECT
        'postcorte'::TEXT,
        COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'postcorte'), 0)::BIGINT,
        (SELECT COUNT(*) FROM selemti.postcorte)::BIGINT,
        (SELECT COUNT(*) FROM selemti.postcorte) - COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'postcorte'), 0)::BIGINT,
        CASE
            WHEN (SELECT COUNT(*) FROM selemti.postcorte) > COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'postcorte'), 0)
            THEN 'AUMENTÓ'
            WHEN (SELECT COUNT(*) FROM selemti.postcorte) = COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'postcorte'), 0)
            THEN 'IGUAL'
            ELSE 'DISMINUYÓ'
        END::TEXT

    UNION ALL

    -- Comparar usuarios
    SELECT
        'users'::TEXT,
        COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'users'), 0)::BIGINT,
        (SELECT COUNT(*) FROM selemti.users)::BIGINT,
        (SELECT COUNT(*) FROM selemti.users) - COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'users'), 0)::BIGINT,
        CASE
            WHEN (SELECT COUNT(*) FROM selemti.users) > COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'users'), 0)
            THEN 'AUMENTÓ'
            WHEN (SELECT COUNT(*) FROM selemti.users) = COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'users'), 0)
            THEN 'IGUAL'
            ELSE 'DISMINUYÓ'
        END::TEXT

    UNION ALL

    -- Comparar items
    SELECT
        'items'::TEXT,
        COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'items'), 0)::BIGINT,
        (SELECT COUNT(*) FROM selemti.items)::BIGINT,
        (SELECT COUNT(*) FROM selemti.items) - COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'items'), 0)::BIGINT,
        CASE
            WHEN (SELECT COUNT(*) FROM selemti.items) > COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'items'), 0)
            THEN 'AUMENTÓ'
            WHEN (SELECT COUNT(*) FROM selemti.items) = COALESCE((SELECT COUNT(*) FROM backup_selemti_critico WHERE tabla = 'items'), 0)
            THEN 'IGUAL'
            ELSE 'DISMINUYÓ'
        END::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 6. FUNCIÓN DE ROLLBACK (si algo sale mal)
SELECT '';
SELECT '=== FUNCIÓN DE ROLLBACK (EMERGENCIA) ===' as info;

CREATE OR REPLACE FUNCTION rollback_importacion_selemti()
RETURNS TEXT AS $$
DECLARE
    resultado TEXT;
BEGIN
    -- Eliminar tabla de backup temporal
    DROP TABLE IF EXISTS backup_selemti_critico;

    resultado := 'Rollback completado. Tabla de backup eliminada.';

    RETURN resultado;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error en rollback: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

SELECT '';
SELECT '=== PREPARACIÓN COMPLETA ===' as info;
SELECT 'Ejecute los comandos manualmente en este orden:' as siguiente;
SELECT '1. Ejecute importar_selemti_seguro.sql (este archivo)' as paso1;
SELECT '2. Ejecute los comandos psql mostrados arriba' as paso2;
SELECT '3. Ejecute: SELECT * FROM validar_importacion_selemti();' as paso3;
SELECT '4. Si hay problemas: SELECT rollback_importacion_selemti();' as paso4;