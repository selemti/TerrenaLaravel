-- =====================================================================
-- Función: selemti.fn_confirmar_consumo_ticket (VERSIÓN EXTENDIDA)
-- =====================================================================
-- Confirma el consumo de un ticket y genera movimientos en inventario
-- Soporta flag de reproceso para tickets históricos
-- =====================================================================

CREATE OR REPLACE FUNCTION selemti.fn_confirmar_consumo_ticket(
    p_ticket_id BIGINT,
    p_es_reproceso BOOLEAN DEFAULT FALSE
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_consumo_id BIGINT;
    v_estado_actual TEXT;
    v_almacen_id INT;
    v_tipo_mov TEXT;
    v_ref_tipo TEXT;
    v_count_movs INT := 0;
    rec RECORD;
BEGIN
    -- 1. Verificar que existe el registro de consumo
    SELECT id, estado, almacen_id
    INTO v_consumo_id, v_estado_actual, v_almacen_id
    FROM selemti.inv_consumo_pos
    WHERE ticket_id = p_ticket_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró registro de consumo para ticket_id=%', p_ticket_id;
    END IF;

    -- 2. Verificar que no esté ya confirmado
    IF v_estado_actual = 'CONFIRMADO' THEN
        RAISE NOTICE 'El consumo del ticket % ya está confirmado', p_ticket_id;
        RETURN 'ALREADY_CONFIRMED';
    END IF;

    -- 3. Determinar el tipo de movimiento según el flag de reproceso
    IF p_es_reproceso THEN
        v_tipo_mov := 'AJUSTE_REPROCESO_POS';
        v_ref_tipo := 'POS_TICKET_REPROCESS';
    ELSE
        v_tipo_mov := 'VENTA_TEO';
        v_ref_tipo := 'POS_TICKET';
    END IF;

    -- 4. Generar movimientos de inventario desde los detalles del consumo
    FOR rec IN
        SELECT
            icpd.item_id,
            icpd.qty,
            icpd.uom,
            icpd.batch_id,
            icpd.costo_unitario,
            i.descripcion as item_desc
        FROM selemti.inv_consumo_pos_det icpd
        LEFT JOIN selemti.items i ON i.id = icpd.item_id
        WHERE icpd.consumo_id = v_consumo_id
        ORDER BY icpd.id
    LOOP
        -- Insertar movimiento negativo (salida de inventario)
        INSERT INTO selemti.mov_inv (
            item_id,
            batch_id,
            almacen_id,
            tipo,
            qty,
            uom,
            ref_tipo,
            ref_id,
            ts,
            meta
        ) VALUES (
            rec.item_id,
            rec.batch_id,
            v_almacen_id,
            v_tipo_mov,
            -1 * rec.qty,  -- Cantidad negativa (salida)
            rec.uom,
            v_ref_tipo,
            p_ticket_id,
            NOW(),
            jsonb_build_object(
                'ticket_id', p_ticket_id,
                'es_reproceso', p_es_reproceso,
                'item_desc', rec.item_desc,
                'costo_unitario', rec.costo_unitario
            )
        );

        v_count_movs := v_count_movs + 1;

    END LOOP;

    -- 5. Actualizar el estado del consumo a CONFIRMADO
    UPDATE selemti.inv_consumo_pos
    SET
        estado = 'CONFIRMADO',
        fecha_confirmacion = NOW(),
        updated_at = NOW()
    WHERE id = v_consumo_id;

    -- 6. Log de auditoría
    IF p_es_reproceso THEN
        RAISE NOTICE 'Consumo REPROCESADO para ticket % - % movimientos generados', p_ticket_id, v_count_movs;
    ELSE
        RAISE NOTICE 'Consumo confirmado para ticket % - % movimientos generados', p_ticket_id, v_count_movs;
    END IF;

    RETURN format('OK:%s', v_count_movs);

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al confirmar consumo ticket %: % - %',
            p_ticket_id, SQLERRM, SQLSTATE;
END;
$$;

-- =====================================================================
-- Comentarios
-- =====================================================================
COMMENT ON FUNCTION selemti.fn_confirmar_consumo_ticket(BIGINT, BOOLEAN) IS
'Confirma el consumo de un ticket y genera movimientos en selemti.mov_inv.
Si es_reproceso=true, usa tipo AJUSTE_REPROCESO_POS y ref_tipo POS_TICKET_REPROCESS.
Si es_reproceso=false, usa tipo VENTA_TEO y ref_tipo POS_TICKET (comportamiento normal).';

-- =====================================================================
-- Ejemplo de uso
-- =====================================================================
-- Confirmación normal (trigger automático):
-- SELECT selemti.fn_confirmar_consumo_ticket(12345, false);

-- Confirmación de reproceso histórico:
-- SELECT selemti.fn_confirmar_consumo_ticket(12345, true);
