-- 2025_10_22_000003_triggers_pos.sql
-- Funciones de expansión/confirmación/reverso

CREATE OR REPLACE FUNCTION selemti.fn_expandir_receta(_ticket_id bigint) RETURNS void LANGUAGE plpgsql AS $$
DECLARE r record;
BEGIN
  FOR r IN (
    SELECT ti.id AS ticket_item_id, rd.insumo_id AS mp_id, rd.cantidad * ti.item_quantity AS qty,
           t.sucursal_id, t.terminal_id
    FROM public.ticket_item ti
    JOIN selemti.receta_detalle rd ON rd.plu = ti.item_id
    JOIN public.ticket t ON t.id = ti.ticket_id
    WHERE ti.ticket_id = _ticket_id
  ) LOOP
    INSERT INTO selemti.inv_consumo_pos(ticket_id, ticket_item_id, sucursal_id, terminal_id, estado)
      VALUES(_ticket_id, r.ticket_item_id, r.sucursal_id, r.terminal_id, 'PENDIENTE')
      ON CONFLICT (ticket_id, ticket_item_id) DO NOTHING;

    INSERT INTO selemti.inv_consumo_pos_det(consumo_id, mp_id, uom_id, cantidad, factor, origen)
      SELECT c.id, r.mp_id, NULL, r.qty, 1, 'RECETA'
      FROM selemti.inv_consumo_pos c
      WHERE c.ticket_id=_ticket_id AND c.ticket_item_id=r.ticket_item_id;
  END LOOP;
END;$$;

CREATE OR REPLACE FUNCTION selemti.fn_confirmar_consumo(_ticket_id bigint) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO selemti.mov_inv(fecha, tipo, sucursal_id, almacen_id, item_id, cantidad, referencia)
  SELECT now(), 'VENTA_TEO', t.sucursal_id, a.id, d.mp_id, SUM(d.cantidad), concat('TCK:', _ticket_id)
  FROM selemti.inv_consumo_pos_det d
  JOIN selemti.inv_consumo_pos c ON c.id = d.consumo_id AND c.ticket_id = _ticket_id AND c.estado='PENDIENTE'
  JOIN public.ticket t ON t.id = _ticket_id
  JOIN selemti.almacen a ON a.sucursal_id = t.sucursal_id AND a.es_principal = true
  GROUP BY t.sucursal_id, a.id, d.mp_id;

  UPDATE selemti.inv_consumo_pos SET estado='CONFIRMADO' WHERE ticket_id=_ticket_id AND estado='PENDIENTE';
END;$$;

CREATE OR REPLACE FUNCTION selemti.fn_reversar_consumo(_ticket_id bigint) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO selemti.mov_inv(fecha, tipo, sucursal_id, almacen_id, item_id, cantidad, referencia)
  SELECT now(), 'AJUSTE', t.sucursal_id, a.id, d.mp_id, SUM(d.cantidad), concat('REV TCK:', _ticket_id)
  FROM selemti.inv_consumo_pos_det d
  JOIN selemti.inv_consumo_pos c ON c.id = d.consumo_id AND c.ticket_id = _ticket_id AND c.estado='CONFIRMADO'
  JOIN public.ticket t ON t.id = _ticket_id
  JOIN selemti.almacen a ON a.sucursal_id = t.sucursal_id AND a.es_principal = true
  GROUP BY t.sucursal_id, a.id, d.mp_id;

  UPDATE selemti.inv_consumo_pos SET estado='ANULADO' WHERE ticket_id=_ticket_id AND estado='CONFIRMADO';
END;$$;

-- Trigger en ticket
DROP TRIGGER IF EXISTS trg_ticket_consumo ON public.ticket;
CREATE OR REPLACE FUNCTION public.trg_fn_ticket_consumo() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.paid = true AND NEW.voided = false AND (OLD.paid IS DISTINCT FROM NEW.paid OR OLD.voided IS DISTINCT FROM NEW.voided) THEN
    PERFORM selemti.fn_expandir_receta(NEW.id);
    PERFORM selemti.fn_confirmar_consumo(NEW.id);
  ELSIF NEW.voided = true AND (OLD.voided IS DISTINCT FROM NEW.voided) THEN
    PERFORM selemti.fn_reversar_consumo(NEW.id);
  END IF;
  RETURN NEW;
END;$$;

CREATE TRIGGER trg_ticket_consumo
AFTER UPDATE OF paid, voided ON public.ticket
FOR EACH ROW EXECUTE FUNCTION public.trg_fn_ticket_consumo();