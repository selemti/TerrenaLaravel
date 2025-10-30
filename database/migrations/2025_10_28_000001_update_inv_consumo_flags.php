<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
CREATE OR REPLACE FUNCTION selemti.fn_confirmar_consumo_ticket(_ticket_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_sucursal bigint;
    v_almacen bigint;
    v_has_mov boolean := coalesce(to_regclass('selemti.mov_inv') IS NOT NULL, false);
BEGIN
    IF NOT v_has_mov THEN
        RETURN;
    END IF;

    SELECT t.sucursal_id INTO v_sucursal
    FROM public.ticket t
    WHERE t.id = _ticket_id;

    IF v_sucursal IS NULL THEN
        RETURN;
    END IF;

    SELECT a.id INTO v_almacen
    FROM selemti.cat_almacenes a
    WHERE a.sucursal_id = v_sucursal AND COALESCE(a.es_principal, false) = true
    ORDER BY a.id
    LIMIT 1;

    IF v_almacen IS NULL THEN
        RETURN;
    END IF;

    INSERT INTO selemti.mov_inv
        (item_id, inventory_batch_id, tipo, qty, uom, sucursal_id, sucursal_dest, almacen_id, ref_tipo, ref_id, user_id, ts, meta, notas, created_at, updated_at)
    SELECT
        d.item_id,
        NULL,
        'VENTA_TEO',
        SUM(d.cantidad),
        COALESCE(d.uom, 'UN'),
        v_sucursal::text,
        NULL,
        v_almacen::text,
        'POS_TICKET',
        _ticket_id,
        NULL,
        now(),
        jsonb_build_object('ticket_id', _ticket_id),
        NULL,
        now(),
        now()
    FROM selemti.inv_consumo_pos_det d
    JOIN selemti.inv_consumo_pos c ON c.id = d.consumo_id
    WHERE c.ticket_id = _ticket_id AND c.estado = 'PENDIENTE'
    GROUP BY d.item_id, d.uom;

    UPDATE selemti.inv_consumo_pos
    SET estado = 'CONFIRMADO',
        requiere_reproceso = false,
        procesado = true,
        fecha_proceso = now(),
        updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = 'PENDIENTE';

    UPDATE selemti.inv_consumo_pos_det
    SET requiere_reproceso = false,
        procesado = true,
        fecha_proceso = now(),
        updated_at = now()
    WHERE consumo_id IN (
        SELECT id FROM selemti.inv_consumo_pos WHERE ticket_id = _ticket_id
    );

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'CONFIRM', NULL);
END;
$$;
SQL);

        DB::connection('pgsql')->unprepared(<<<'SQL'
CREATE OR REPLACE FUNCTION selemti.fn_reversar_consumo_ticket(_ticket_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_sucursal bigint;
    v_almacen bigint;
    v_has_mov boolean := coalesce(to_regclass('selemti.mov_inv') IS NOT NULL, false);
BEGIN
    IF NOT v_has_mov THEN
        RETURN;
    END IF;

    SELECT t.sucursal_id INTO v_sucursal
    FROM public.ticket t
    WHERE t.id = _ticket_id;

    IF v_sucursal IS NULL THEN
        RETURN;
    END IF;

    SELECT a.id INTO v_almacen
    FROM selemti.cat_almacenes a
    WHERE a.sucursal_id = v_sucursal AND COALESCE(a.es_principal, false) = true
    ORDER BY a.id
    LIMIT 1;

    IF v_almacen IS NULL THEN
        RETURN;
    END IF;

    INSERT INTO selemti.mov_inv
        (item_id, inventory_batch_id, tipo, qty, uom, sucursal_id, sucursal_dest, almacen_id, ref_tipo, ref_id, user_id, ts, meta, notas, created_at, updated_at)
    SELECT
        d.item_id,
        NULL,
        'AJUSTE',
        SUM(d.cantidad),
        COALESCE(d.uom, 'UN'),
        v_sucursal::text,
        NULL,
        v_almacen::text,
        'POS_TICKET_REV',
        _ticket_id,
        NULL,
        now(),
        jsonb_build_object('ticket_id', _ticket_id),
        NULL,
        now(),
        now()
    FROM selemti.inv_consumo_pos_det d
    JOIN selemti.inv_consumo_pos c ON c.id = d.consumo_id
    WHERE c.ticket_id = _ticket_id AND c.estado = 'CONFIRMADO'
    GROUP BY d.item_id, d.uom;

    UPDATE selemti.inv_consumo_pos
    SET estado = 'ANULADO',
        requiere_reproceso = true,
        procesado = false,
        fecha_proceso = NULL,
        updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = 'CONFIRMADO';

    UPDATE selemti.inv_consumo_pos_det
    SET requiere_reproceso = true,
        procesado = false,
        fecha_proceso = NULL,
        updated_at = now()
    WHERE consumo_id IN (
        SELECT id FROM selemti.inv_consumo_pos WHERE ticket_id = _ticket_id
    );

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'REVERSE', NULL);
END;
$$;
SQL);
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
CREATE OR REPLACE FUNCTION selemti.fn_confirmar_consumo_ticket(_ticket_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_sucursal bigint;
    v_almacen bigint;
    v_has_mov boolean := coalesce(to_regclass('selemti.mov_inv') IS NOT NULL, false);
BEGIN
    IF NOT v_has_mov THEN
        RETURN;
    END IF;

    SELECT t.sucursal_id INTO v_sucursal
    FROM public.ticket t
    WHERE t.id = _ticket_id;

    IF v_sucursal IS NULL THEN
        RETURN;
    END IF;

    SELECT a.id INTO v_almacen
    FROM selemti.cat_almacenes a
    WHERE a.sucursal_id = v_sucursal AND COALESCE(a.es_principal, false) = true
    ORDER BY a.id
    LIMIT 1;

    IF v_almacen IS NULL THEN
        RETURN;
    END IF;

    INSERT INTO selemti.mov_inv
        (item_id, inventory_batch_id, tipo, qty, uom, sucursal_id, sucursal_dest, almacen_id, ref_tipo, ref_id, user_id, ts, meta, notas, created_at, updated_at)
    SELECT
        d.item_id,
        NULL,
        'VENTA_TEO',
        SUM(d.cantidad),
        COALESCE(d.uom, 'UN'),
        v_sucursal::text,
        NULL,
        v_almacen::text,
        'POS_TICKET',
        _ticket_id,
        NULL,
        now(),
        jsonb_build_object('ticket_id', _ticket_id),
        NULL,
        now(),
        now()
    FROM selemti.inv_consumo_pos_det d
    JOIN selemti.inv_consumo_pos c ON c.id = d.consumo_id
    WHERE c.ticket_id = _ticket_id AND c.estado = 'PENDIENTE'
    GROUP BY d.item_id, d.uom;

    UPDATE selemti.inv_consumo_pos
    SET estado = 'CONFIRMADO', updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = 'PENDIENTE';

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'CONFIRM', NULL);
END;
$$;
SQL);

        DB::connection('pgsql')->unprepared(<<<'SQL'
CREATE OR REPLACE FUNCTION selemti.fn_reversar_consumo_ticket(_ticket_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_sucursal bigint;
    v_almacen bigint;
    v_has_mov boolean := coalesce(to_regclass('selemti.mov_inv') IS NOT NULL, false);
BEGIN
    IF NOT v_has_mov THEN
        RETURN;
    END IF;

    SELECT t.sucursal_id INTO v_sucursal
    FROM public.ticket t
    WHERE t.id = _ticket_id;

    IF v_sucursal IS NULL THEN
        RETURN;
    END IF;

    SELECT a.id INTO v_almacen
    FROM selemti.cat_almacenes a
    WHERE a.sucursal_id = v_sucursal AND COALESCE(a.es_principal, false) = true
    ORDER BY a.id
    LIMIT 1;

    IF v_almacen IS NULL THEN
        RETURN;
    END IF;

    INSERT INTO selemti.mov_inv
        (item_id, inventory_batch_id, tipo, qty, uom, sucursal_id, sucursal_dest, almacen_id, ref_tipo, ref_id, user_id, ts, meta, notas, created_at, updated_at)
    SELECT
        d.item_id,
        NULL,
        'AJUSTE',
        SUM(d.cantidad),
        COALESCE(d.uom, 'UN'),
        v_sucursal::text,
        NULL,
        v_almacen::text,
        'POS_TICKET_REV',
        _ticket_id,
        NULL,
        now(),
        jsonb_build_object('ticket_id', _ticket_id),
        NULL,
        now(),
        now()
    FROM selemti.inv_consumo_pos_det d
    JOIN selemti.inv_consumo_pos c ON c.id = d.consumo_id
    WHERE c.ticket_id = _ticket_id AND c.estado = 'CONFIRMADO'
    GROUP BY d.item_id, d.uom;

    UPDATE selemti.inv_consumo_pos
    SET estado = 'ANULADO', updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = 'CONFIRMADO';

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'REVERSE', NULL);
END;
$$;
SQL);
    }
};
