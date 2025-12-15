-- Crear trigger para sincronización
CREATE TRIGGER trg_selemti_dah_ai
AFTER INSERT ON public.drawer_assigned_history
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_after_insert();