-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql
BEGIN;
SET search_path = selemti, public;
COMMENT ON FUNCTION fn_generar_postcorte(p_sesion_id bigint) IS 'Genera automáticamente el postcorte basado en el precorte y transacciones POS.';


COMMENT ON FUNCTION fn_postcorte_after_insert() IS 'Trigger: al crear un postcorte, marca la sesión como CERRADA.';


COMMENT ON FUNCTION fn_precorte_after_insert() IS 'Trigger: al crear un precorte, marca la sesión como EN_CORTE.';


COMMENT ON FUNCTION fn_precorte_after_update_aprobado() IS 'Trigger: al aprobar un precorte, genera el postcorte automáticamente.';


COMMENT ON TABLE conciliacion IS 'Registra el proceso de conciliación final después del postcorte.';


COMMENT ON COLUMN conciliacion.postcorte_id IS 'FK a postcorte (UNIQUE - solo una conciliación por postcorte).';


COMMENT ON COLUMN conciliacion.conciliado_por IS 'Usuario que realizó la conciliación (supervisor/gerente).';


COMMENT ON TABLE inventory_batch IS 'Lotes de inventario con trazabilidad completa.';


COMMENT ON TABLE items IS 'Maestro de todos los productos/insumos del sistema.';


COMMENT ON TABLE mov_inv IS 'Kardex completo de movimientos de inventario.';


COMMENT ON TABLE op_produccion_cab IS 'Cabecera de órdenes de producción.';


COMMENT ON TABLE receta_cab IS 'Cabecera de recetas y platos del menú.';


COMMENT ON TABLE receta_det IS 'Detalle de ingredientes por versión de receta.';


COMMENT ON TABLE receta_version IS 'Control de versiones de recetas.';


COMMENT ON TABLE user_roles IS 'Asignación de roles a usuarios.';


COMMENT ON TABLE users IS 'Usuarios del sistema con sus credenciales y estado.';


REVOKE ALL ON TABLE vw_sesion_dpr FROM PUBLIC;
REVOKE ALL ON TABLE vw_sesion_dpr FROM postgres;
GRANT ALL ON TABLE vw_sesion_dpr TO postgres;
GRANT SELECT ON TABLE vw_sesion_dpr TO floreant;


-- PostgreSQL database dump complete
COMMIT;
