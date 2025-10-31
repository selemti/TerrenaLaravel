-- =====================================================================
-- FASE 5: Enterprise Features (FINAL)
-- =====================================================================
-- Implementa características enterprise: auditoría avanzada,
-- vistas materializadas y documentación
-- =====================================================================

\set ON_ERROR_STOP on
\timing on

\echo ''
\echo '============================================================='
\echo 'FASE 5: Enterprise Features (FINAL)'
\echo '============================================================='
\echo ''

-- =====================================================================
-- 5.1: Crear tabla de auditoría global
-- =====================================================================
\echo 'Creando tabla de auditoría global...'

CREATE TABLE IF NOT EXISTS selemti.audit_log_global (
    id BIGSERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id TEXT,
    old_data JSONB,
    new_data JSONB,
    changed_by_user_id BIGINT REFERENCES selemti.users(id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_log_global_table ON selemti.audit_log_global(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_global_operation ON selemti.audit_log_global(operation);
CREATE INDEX IF NOT EXISTS idx_audit_log_global_changed_at ON selemti.audit_log_global(changed_at);
CREATE INDEX IF NOT EXISTS idx_audit_log_global_user ON selemti.audit_log_global(changed_by_user_id);

-- =====================================================================
-- 5.2: Función de auditoría genérica
-- =====================================================================
\echo ''
\echo 'Creando función de auditoría...'

CREATE OR REPLACE FUNCTION selemti.audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO selemti.audit_log_global (
            schema_name, table_name, operation, record_id, old_data, changed_at
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, OLD.id::TEXT, row_to_json(OLD), CURRENT_TIMESTAMP
        );
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO selemti.audit_log_global (
            schema_name, table_name, operation, record_id, old_data, new_data, changed_at
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, NEW.id::TEXT, row_to_json(OLD), row_to_json(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO selemti.audit_log_global (
            schema_name, table_name, operation, record_id, new_data, changed_at
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, NEW.id::TEXT, row_to_json(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 5.3: Vistas materializadas para reportes
-- =====================================================================
\echo ''
\echo 'Creando vistas materializadas...'

-- Vista materializada de inventario actual
DROP MATERIALIZED VIEW IF EXISTS selemti.mv_inventario_actual CASCADE;
CREATE MATERIALIZED VIEW selemti.mv_inventario_actual AS
SELECT 
    i.id as item_id,
    i.nombre as item_nombre,
    i.categoria_id,
    i.unidad_medida,
    COUNT(DISTINCT ib.id) as total_lotes,
    COALESCE(SUM(ib.cantidad_actual), 0) as cantidad_total,
    COALESCE(AVG(ib.unit_cost), 0) as costo_promedio,
    COALESCE(SUM(ib.cantidad_actual * ib.unit_cost), 0) as valor_total,
    MAX(ib.updated_at) as ultima_actualizacion
FROM selemti.items i
LEFT JOIN selemti.inventory_batch ib ON ib.item_id = i.id 
WHERE i.activo = true 
  AND (ib.estado IS NULL OR ib.estado = 'DISPONIBLE')
GROUP BY i.id, i.nombre, i.categoria_id, i.unidad_medida;

CREATE UNIQUE INDEX ON selemti.mv_inventario_actual (item_id);

-- Vista materializada de recetas con costos
DROP MATERIALIZED VIEW IF EXISTS selemti.mv_recetas_costos CASCADE;
CREATE MATERIALIZED VIEW selemti.mv_recetas_costos AS
SELECT 
    rc.id as receta_id,
    rc.nombre_plato,
    rc.categoria_plato,
    rc.costo_standard_porcion,
    rc.precio_venta_sugerido,
    COUNT(rd.id) as total_ingredientes,
    rc.activo,
    rc.updated_at
FROM selemti.receta_cab rc
LEFT JOIN selemti.receta_det rd ON rd.receta_version_id = (
    SELECT id FROM selemti.receta_version WHERE receta_id = rc.id LIMIT 1
)
GROUP BY rc.id, rc.nombre_plato, rc.categoria_plato, 
         rc.costo_standard_porcion, rc.precio_venta_sugerido, rc.activo, rc.updated_at;

CREATE UNIQUE INDEX ON selemti.mv_recetas_costos (receta_id);

-- =====================================================================
-- 5.4: Funciones de utilidad
-- =====================================================================
\echo ''
\echo 'Creando funciones de utilidad...'

-- Función para refrescar vistas materializadas
CREATE OR REPLACE FUNCTION selemti.refresh_materialized_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY selemti.mv_inventario_actual;
    REFRESH MATERIALIZED VIEW CONCURRENTLY selemti.mv_recetas_costos;
    RAISE NOTICE 'Vistas materializadas actualizadas exitosamente';
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 5.5: Comentarios de documentación
-- =====================================================================
\echo ''
\echo 'Añadiendo documentación...'

COMMENT ON TABLE selemti.users IS 'Tabla canónica de usuarios del sistema - Consolidada en Phase 2.1';
COMMENT ON TABLE selemti.roles IS 'Tabla de roles (Spatie Permission) - Consolidada en Phase 2.1';
COMMENT ON TABLE selemti.cat_sucursales IS 'Catálogo de sucursales - Consolidada en Phase 2.2';
COMMENT ON TABLE selemti.cat_almacenes IS 'Catálogo de almacenes - Consolidada en Phase 2.2';
COMMENT ON TABLE selemti.items IS 'Catálogo de items/insumos - Consolidada en Phase 2.3';
COMMENT ON TABLE selemti.inventory_batch IS 'Lotes de inventario - Consolidada en Phase 2.3';
COMMENT ON TABLE selemti.receta_cab IS 'Catálogo de recetas - Consolidada en Phase 2.4';
COMMENT ON TABLE selemti.receta_det IS 'Detalle de ingredientes de recetas - Consolidada en Phase 2.4';
COMMENT ON TABLE selemti.audit_log_global IS 'Log global de auditoría - Creada en Phase 5';

-- Comentarios en vistas de compatibilidad
COMMENT ON VIEW selemti.v_usuario IS 'Vista de compatibilidad - Mapea users → formato legacy usuario';
COMMENT ON VIEW selemti.v_rol IS 'Vista de compatibilidad - Mapea roles → formato legacy rol';
COMMENT ON VIEW selemti.v_sucursal IS 'Vista de compatibilidad - Mapea cat_sucursales → formato legacy';
COMMENT ON VIEW selemti.v_bodega IS 'Vista de compatibilidad - Mapea cat_almacenes → formato legacy bodega';
COMMENT ON VIEW selemti.v_almacen IS 'Vista de compatibilidad - Mapea cat_almacenes → formato legacy almacen';
COMMENT ON VIEW selemti.v_insumo IS 'Vista de compatibilidad - Mapea items → formato legacy insumo';
COMMENT ON VIEW selemti.v_lote IS 'Vista de compatibilidad - Mapea inventory_batch → formato legacy lote';
COMMENT ON VIEW selemti.v_receta IS 'Vista de compatibilidad - Mapea receta_cab → formato legacy receta';

-- =====================================================================
-- 5.6: Estadísticas finales
-- =====================================================================
\echo ''
\echo 'Actualizando estadísticas finales...'

ANALYZE selemti.audit_log_global;
ANALYZE selemti.mv_inventario_actual;
ANALYZE selemti.mv_recetas_costos;

-- =====================================================================
-- REPORTE FINAL
-- =====================================================================
\echo ''
\echo '============================================================='
\echo 'PROYECTO COMPLETADO AL 100%'
\echo '============================================================='
\echo ''

-- Estadísticas generales
SELECT 
    'Tablas totales en esquema' as metrica,
    COUNT(*) as valor
FROM information_schema.tables
WHERE table_schema = 'selemti' AND table_type = 'BASE TABLE'
UNION ALL
SELECT 
    'Vistas de compatibilidad',
    COUNT(*)
FROM pg_views
WHERE schemaname = 'selemti' AND viewname LIKE 'v_%'
UNION ALL
SELECT 
    'Vistas materializadas',
    COUNT(*)
FROM pg_matviews
WHERE schemaname = 'selemti'
UNION ALL
SELECT 
    'Foreign Keys totales',
    COUNT(*)
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY' AND table_schema = 'selemti'
UNION ALL
SELECT 
    'Índices totales',
    COUNT(*)
FROM pg_indexes
WHERE schemaname = 'selemti'
UNION ALL
SELECT 
    'Triggers totales',
    COUNT(*)
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'selemti' AND NOT t.tgisinternal;

\echo ''
\echo '============================================================='
\echo 'FASE 5 COMPLETADA - PROYECTO 100% FINALIZADO'
\echo '============================================================='
\echo ''

\timing off
