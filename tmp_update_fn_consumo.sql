-- =============================================================================
-- REFACTORIZACIÓN: fn_expandir_consumo_ticket
-- SOPORTE: Ítems Base + Modificadores (Explosión Jerárquica 2026)
-- =============================================================================

CREATE OR REPLACE FUNCTION selemti.fn_expandir_consumo_ticket(_ticket_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_consumo_id bigint;
    v_ticket_item record;
BEGIN
    -- 1. Crear registros maestros de consumo si no existen
    INSERT INTO selemti.inv_consumo_pos (ticket_id, ticket_item_id, sucursal_id, terminal_id, estado, expandido, created_at)
    SELECT DISTINCT
        ti.ticket_id,
        ti.id,
        t.sucursal_id,
        t.terminal_id,
        'PENDIENTE',
        true,
        now()
    FROM public.ticket_item ti
    JOIN public.ticket t ON t.id = ti.ticket_id
    WHERE ti.ticket_id = _ticket_id
      AND NOT EXISTS (
            SELECT 1
            FROM selemti.inv_consumo_pos c
            WHERE c.ticket_item_id = ti.id
        );

    -- 2. Procesar cada ítem del ticket
    FOR v_ticket_item IN
        SELECT c.id as consumo_id, ti.id as ticket_item_id, ti.item_id as pos_item_id, ti.item_quantity
        FROM selemti.inv_consumo_pos c
        JOIN public.ticket_item ti ON ti.id = c.ticket_item_id
        WHERE c.ticket_id = _ticket_id
    LOOP
        -- 2.1 EXPLOSIÓN ÍTEM BASE
        INSERT INTO selemti.inv_consumo_pos_det (consumo_id, item_id, uom, cantidad, factor, origen, meta)
        SELECT
            v_ticket_item.consumo_id,
            rd.item_id,
            rd.unidad_medida,
            rd.cantidad * v_ticket_item.item_quantity * (1 + coalesce(rd.merma_porcentaje, 0)/100),
            1, -- Factor por defecto
            'RECETA_BASE',
            jsonb_build_object('pos_id', v_ticket_item.pos_item_id)
        FROM selemti.receta_cab rc
        JOIN selemti.receta_version rv ON rv.receta_id = rc.id AND rv.version_publicada = true
        JOIN selemti.receta_det rd ON rd.receta_version_id = rv.id
        WHERE rc.codigo_plato_pos = v_ticket_item.pos_item_id::text
          AND NOT EXISTS (
            SELECT 1 FROM selemti.inv_consumo_pos_det d 
            WHERE d.consumo_id = v_ticket_item.consumo_id AND d.item_id = rd.item_id AND d.origen = 'REC_BASE'
          );

        -- 2.2 EXPLOSIÓN MODIFICADORES
        INSERT INTO selemti.inv_consumo_pos_det (consumo_id, item_id, uom, cantidad, factor, origen, meta)
        SELECT
            v_ticket_item.consumo_id,
            rd.item_id,
            rd.unidad_medida,
            rd.cantidad * (tim.item_count * v_ticket_item.item_quantity) * (1 + coalesce(rd.merma_porcentaje, 0)/100),
            1,
            'RECETA_MODIFICADOR',
            jsonb_build_object('modifier_id', tim.item_id, 'modifier_name', tim.modifier_name)
        FROM public.ticket_item_modifier tim
        JOIN selemti.modificadores_pos mp ON mp.codigo_pos = 'MOD-' || LPAD(tim.item_id::text, 5, '0')
        JOIN selemti.receta_cab rc ON rc.id = mp.receta_modificador_id
        JOIN selemti.receta_version rv ON rv.receta_id = rc.id AND rv.version_publicada = true
        JOIN selemti.receta_det rd ON rd.receta_version_id = rv.id
        WHERE tim.ticket_item_id = v_ticket_item.ticket_item_id;

    END LOOP;

    -- 3. Log de expansión
    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'EXPAND_HIERARCHICAL', jsonb_build_object('timestamp', now()));
END;
$function$;
