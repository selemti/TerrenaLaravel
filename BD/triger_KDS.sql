-- Canal: kds_event
-- Requiere PostgreSQL >= 9.4 (usas 9.5, OK)

-- 1) Función de notificación
CREATE OR REPLACE FUNCTION public.kds_notify()
RETURNS trigger AS
$$
DECLARE
  v_ticket_id INT;
  v_pg_id     INT;
  v_item_id   INT;
  v_status    TEXT;
  v_total     INT;
  v_ready     INT;
  v_done      INT;
  v_type      TEXT;
BEGIN
  /*
    Esta función se dispara desde:
    - kitchen_ticket_item (insert/update status)
    - ticket_item        (insert/update status)
  */

  IF TG_TABLE_NAME = 'kitchen_ticket_item' THEN
    -- Cambios en cocina
    v_item_id := COALESCE(NEW.ticket_item_id, NEW.id);
    SELECT ti.ticket_id, ti.pg_id
      INTO v_ticket_id, v_pg_id
    FROM ticket_item ti
    WHERE ti.id = v_item_id;

    v_status := UPPER(COALESCE(NEW.status,''));
    v_type   := CASE WHEN TG_OP = 'INSERT' THEN 'item_upsert' ELSE 'item_status' END;

    PERFORM pg_notify(
      'kds_event',
      json_build_object(
        'type',      v_type,
        'ticket_id', v_ticket_id,
        'pg',        v_pg_id,
        'item_id',   v_item_id,
        'status',    v_status,
        'ts',        now()
      )::text
    );

  ELSIF TG_TABLE_NAME = 'ticket_item' THEN
    -- Nuevos ítems o actualizaciones de estado en ticket_item
    v_item_id   := NEW.id;
    v_ticket_id := NEW.ticket_id;
    v_pg_id     := NEW.pg_id;
    v_status    := UPPER(COALESCE(NEW.status,''));

    IF TG_OP = 'INSERT' THEN
      v_type := 'item_insert';
    ELSE
      v_type := 'item_status';
    END IF;

    PERFORM pg_notify(
      'kds_event',
      json_build_object(
        'type',      v_type,
        'ticket_id', v_ticket_id,
        'pg',        v_pg_id,
        'item_id',   v_item_id,
        'status',    v_status,
        'ts',        now()
      )::text
    );
  END IF;

  -- Si tenemos contexto de ticket y área (pg), verificamos agregados
  IF v_ticket_id IS NOT NULL AND v_pg_id IS NOT NULL THEN
    SELECT
      COUNT(*) AS total,
      COUNT(*) FILTER (
        WHERE UPPER(COALESCE(kti.status, ti.status, '')) IN ('READY','DONE')
      ) AS ready,
      COUNT(*) FILTER (
        WHERE UPPER(COALESCE(kti.status, ti.status, '')) = 'DONE'
      ) AS done
    INTO v_total, v_ready, v_done
    FROM ticket_item ti
    LEFT JOIN kitchen_ticket_item kti ON kti.ticket_item_id = ti.id
    WHERE ti.ticket_id = v_ticket_id
      AND ti.pg_id     = v_pg_id;

    -- Todos listos (READY o DONE)
    IF v_total > 0 AND v_total = v_ready THEN
      PERFORM pg_notify(
        'kds_event',
        json_build_object(
          'type',      'ticket_all_ready',
          'ticket_id', v_ticket_id,
          'pg',        v_pg_id,
          'ts',        now()
        )::text
      );
    END IF;

    -- Todos terminados (DONE) -> usado por voz-events.php
    IF v_total > 0 AND v_total = v_done THEN
      PERFORM pg_notify(
        'kds_event',
        json_build_object(
          'type',      'ticket_all_done',
          'ticket_id', v_ticket_id,
          'pg',        v_pg_id,
          'ts',        now()
        )::text
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2) Triggers (se rehacen por si existen)

-- kitchen_ticket_item: insert + update de status
DROP TRIGGER IF EXISTS trg_kds_notify_kti ON public.kitchen_ticket_item;
CREATE TRIGGER trg_kds_notify_kti
AFTER INSERT OR UPDATE OF status ON public.kitchen_ticket_item
FOR EACH ROW
EXECUTE PROCEDURE public.kds_notify();

-- ticket_item: insert (aparecer al instante en KDS) + update de status (por si Floreant escribe ahí)
DROP TRIGGER IF EXISTS trg_kds_notify_ti ON public.ticket_item;
CREATE TRIGGER trg_kds_notify_ti
AFTER INSERT OR UPDATE OF status ON public.ticket_item
FOR EACH ROW
EXECUTE PROCEDURE public.kds_notify();
