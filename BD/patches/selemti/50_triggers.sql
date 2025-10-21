-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql
BEGIN;
SET search_path = selemti, public;
DROP TRIGGER IF EXISTS trg_postcorte_after_insert ON postcorte;
CREATE TRIGGER trg_postcorte_after_insert AFTER INSERT ON postcorte FOR EACH ROW EXECUTE PROCEDURE fn_postcorte_after_insert();


DROP TRIGGER IF EXISTS trg_precorte_after_insert ON precorte;
CREATE TRIGGER trg_precorte_after_insert AFTER INSERT ON precorte FOR EACH ROW EXECUTE PROCEDURE fn_precorte_after_insert();


DROP TRIGGER IF EXISTS trg_precorte_after_update_aprobado ON precorte;
CREATE TRIGGER trg_precorte_after_update_aprobado AFTER UPDATE ON precorte FOR EACH ROW WHEN (((new.estatus = 'APROBADO'::text) AND (old.estatus IS DISTINCT FROM 'APROBADO'::text))) EXECUTE PROCEDURE fn_precorte_after_update_aprobado();


DROP TRIGGER IF EXISTS trg_precorte_efectivo_bi ON precorte_efectivo;
CREATE TRIGGER trg_precorte_efectivo_bi BEFORE INSERT OR UPDATE ON precorte_efectivo FOR EACH ROW EXECUTE PROCEDURE fn_precorte_efectivo_bi();


SET search_path = public, pg_catalog;

COMMIT;
