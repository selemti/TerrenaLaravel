-- =============================================================================
-- REFACTORIZACIÓN FINAL: fn_expandir_consumo_ticket (v2.4)
-- SOPORTE: Recursividad Logística + Stock-Aware + Modificadores (Full Mappings)
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
    INSERT INTO selemti.inv_consumo_pos (ticket_id, ticket_item_id, sucursal_id, terminal_id, estado, created_at)
    SELECT DISTINCT
        ti.ticket_id,
        ti.id,
        COALESCE(s.id, 1), -- Mapeo de sucursal
        t.terminal_id,
        'PENDIENTE',
        now()
    FROM public.ticket_item ti
    JOIN public.ticket t ON t.id = ti.ticket_id
    LEFT JOIN selemti.cat_sucursales s ON s.clave = t.branch_key OR s.clave = 'SUC01'
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
        -- Limpiar expansión previa
        DELETE FROM selemti.inv_consumo_pos_det WHERE consumo_id = v_ticket_item.consumo_id;

        -- 2.1 EXPLOSIÓN RECURSIVA (BASE + MODIFICADORES)
        INSERT INTO selemti.inv_consumo_pos_det (consumo_id, mp_id, uom_id, cantidad, factor, origen)
        WITH RECURSIVE explosion AS (
                SELECT 
                    rc.id as recipe_id,
                    1.0::numeric as qty_multiplier,
                    'BASE' as path_type,
                    rc.id as origin_id
                FROM selemti.receta_cab rc
                WHERE rc.codigo_plato_pos = v_ticket_item.pos_item_id::text
                
                UNION ALL
                
                SELECT 
                    rc.id as recipe_id,
                    tim.item_count::numeric as qty_multiplier,
                    'MOD' as path_type,
                    tim.item_id::text as origin_id
                FROM public.ticket_item_modifier tim
                JOIN selemti.modificadores_pos mp ON mp.codigo_pos = 'MOD-' || LPAD(tim.item_id::text, 5, '0')
                JOIN selemti.receta_cab rc ON rc.id = mp.receta_modificador_id
                WHERE tim.ticket_item_id = v_ticket_item.ticket_item_id
        ),
        bom_recursive AS (
            SELECT 
                rd.item_id,
                rd.cantidad * e.qty_multiplier as total_qty,
                rd.unidad_medida,
                1 as level,
                e.path_type,
                e.origin_id
            FROM explosion e
            JOIN selemti.receta_version rv ON rv.receta_id = e.recipe_id AND rv.version_publicada = true
            JOIN selemti.receta_det rd ON rd.receta_version_id = rv.id
            
            UNION ALL
            
            SELECT 
                sub_rd.item_id,
                sub_rd.cantidad * b.total_qty as total_qty,
                sub_rd.unidad_medida,
                b.level + 1,
                b.path_type,
                b.origin_id
            FROM bom_recursive b
            JOIN selemti.receta_cab rc ON rc.id = b.item_id
            JOIN selemti.receta_version rv ON rv.receta_id = rc.id AND rv.version_publicada = true
            JOIN selemti.receta_det sub_rd ON sub_rd.receta_version_id = rv.id
            WHERE b.level < 5
              AND NOT EXISTS (
                  SELECT 1 FROM selemti.v_stock_actual s WHERE s.item_id = b.item_id AND s.stock_actual > 0
              )
        )
        SELECT 
            v_ticket_item.consumo_id,
            COALESCE(substring(b.item_id from '[0-9]+')::integer, 0), -- mp_id numérico (hack compatible)
            COALESCE(u.id, 3), -- uom_id (fallback PZ)
            b.total_qty * v_ticket_item.item_quantity,
            1,
            'AUTO_' || b.path_type
        FROM bom_recursive b
        LEFT JOIN selemti.cat_unidades u ON u.clave = b.unidad_medida
        WHERE 
            NOT EXISTS (SELECT 1 FROM selemti.receta_cab r WHERE r.id = b.item_id AND r.activo = true)
            OR EXISTS (SELECT 1 FROM selemti.v_stock_actual s WHERE s.item_id = b.item_id AND s.stock_actual > 0);

    END LOOP;

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'EXPAND_RECURSIVE_2026_FINAL_V2_4', jsonb_build_object('ts', now()));
END;
$function$;
