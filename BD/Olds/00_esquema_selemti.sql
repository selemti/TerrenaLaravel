-- =====================================================
-- SCRIPT 00: CREACIÓN DE ESQUEMA Y PERMISOS
-- Base de datos: pos (PostgreSQL 9.5)
-- Esquema: selemti
-- =====================================================

\set ON_ERROR_STOP on

-- 1. CREAR ESQUEMA SI NO EXISTE
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'selemti') THEN
        CREATE SCHEMA selemti;
        RAISE NOTICE 'Esquema selemti creado exitosamente';
    ELSE
        RAISE NOTICE 'Esquema selemti ya existe';
    END IF;
END
$$;

-- 2. CREAR USUARIO DEDICADO
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'selemti_user') THEN
        CREATE USER selemti_user WITH PASSWORD 'selemti_password_2024';
        RAISE NOTICE 'Usuario selemti_user creado exitosamente';
    ELSE
        RAISE NOTICE 'Usuario selemti_user ya existe';
    END IF;
END
$$;

-- 3. OTORGAR PERMISOS
GRANT USAGE ON SCHEMA selemti TO selemti_user;
GRANT CREATE ON SCHEMA selemti TO selemti_user;

-- 4. PERMISOS DE LECTURA ENTRE ESQUEMAS
GRANT USAGE ON SCHEMA public TO selemti_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO selemti_user;

-- 5. CONFIGURAR SEARCH PATH
ALTER USER selemti_user SET search_path = 'selemti, public';

RAISE NOTICE 'Script 00 ejecutado exitosamente';