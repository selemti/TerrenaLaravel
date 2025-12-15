-- Reactivar todos los triggers en schema public
-- Tabla por tabla para evitar errores

DO $$
DECLARE
    table_rec RECORD;
    sql TEXT;
BEGIN
    -- Para cada tabla en schema public
    FOR table_rec IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY tablename
    LOOP
        -- Construir y ejecutar SQL para activar triggers
        sql := 'ALTER TABLE public.' || quote_ident(table_rec.tablename) || ' ENABLE TRIGGER ALL';
        BEGIN
            EXECUTE sql;
            RAISE NOTICE 'Triggers activados en: public.%', table_rec.tablename;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Error activando triggers en %: %', table_rec.tablename, SQLERRM;
        END;
    END LOOP;

    RAISE NOTICE 'Proceso completado';
END $$;