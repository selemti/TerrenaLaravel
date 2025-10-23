<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $schema = Schema::connection('pgsql');

        if (! $schema->hasTable('inv_consumo_pos')) {
            $schema->create('inv_consumo_pos', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('ticket_id');
                $table->unsignedBigInteger('ticket_item_id')->nullable();
                $table->unsignedBigInteger('sucursal_id')->nullable();
                $table->unsignedBigInteger('terminal_id')->nullable();
                $table->enum('estado', ['PENDIENTE', 'CONFIRMADO', 'ANULADO'])->default('PENDIENTE');
                $table->boolean('expandido')->default(false);
                $table->timestampTz('created_at')->useCurrent();
                $table->timestampTz('updated_at')->nullable();

                $table->index(['ticket_id']);
                $table->index(['estado']);
            });
        }

        if (! $schema->hasTable('inv_consumo_pos_det')) {
            $schema->create('inv_consumo_pos_det', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('consumo_id');
                $table->unsignedBigInteger('item_id');
                $table->string('uom', 20)->nullable();
                $table->decimal('cantidad', 18, 6);
                $table->decimal('factor', 18, 6)->default(1);
                $table->string('origen', 20)->default('RECETA');
                $table->jsonb('meta')->nullable();

                $table->foreign('consumo_id')->references('id')->on('inv_consumo_pos')->onDelete('cascade');
                $table->index(['item_id']);
            });
        }

        if (! $schema->hasTable('inv_consumo_pos_log')) {
            $schema->create('inv_consumo_pos_log', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('ticket_id');
                $table->string('accion', 20);
                $table->timestampTz('registrado_en')->useCurrent();
                $table->jsonb('payload')->nullable();

                $table->index(['ticket_id']);
            });
        }

        DB::connection('pgsql')->unprepared(<<<'SQL'
CREATE OR REPLACE FUNCTION selemti.fn_expandir_consumo_ticket(_ticket_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_consumo_id bigint;
    v_has_recipes boolean := coalesce(to_regclass('selemti.recipe_details') IS NOT NULL, false);
BEGIN
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

    IF NOT v_has_recipes THEN
        RETURN;
    END IF;

    FOR v_consumo_id IN
        SELECT c.id
        FROM selemti.inv_consumo_pos c
        WHERE c.ticket_id = _ticket_id
    LOOP
        INSERT INTO selemti.inv_consumo_pos_det (consumo_id, item_id, uom, cantidad, factor, origen, meta)
        SELECT
            v_consumo_id,
            rd.item_id,
            rd.required_uom,
            rd.cantidad * ti.item_quantity,
            coalesce(rd.factor, 1),
            'RECETA',
            jsonb_build_object('ticket_item_id', ti.id)
        FROM selemti.recipe_details rd
        JOIN public.ticket_item ti ON ti.item_id = rd.recipe_item_id AND ti.ticket_id = _ticket_id
        WHERE NOT EXISTS (
            SELECT 1
            FROM selemti.inv_consumo_pos_det d
            WHERE d.consumo_id = v_consumo_id
              AND d.item_id = rd.item_id
              AND coalesce(d.meta->>'ticket_item_id', '') = ti.id::text
        );
    END LOOP;

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'EXPAND', NULL);
END;
$$;
SQL);

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

        DB::connection('pgsql')->unprepared(<<<'SQL'
CREATE OR REPLACE FUNCTION selemti.trg_ticket_inventory_consumption()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.paid = true AND NEW.voided = false THEN
        PERFORM selemti.fn_expandir_consumo_ticket(NEW.id);
        PERFORM selemti.fn_confirmar_consumo_ticket(NEW.id);
    ELSIF NEW.voided = true THEN
        PERFORM selemti.fn_reversar_consumo_ticket(NEW.id);
    END IF;

    RETURN NEW;
END;
$$;
SQL);

        DB::connection('pgsql')->unprepared(<<<'SQL'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trg_ticket_inventory_consumption'
    ) THEN
        DROP TRIGGER trg_ticket_inventory_consumption ON public.ticket;
    END IF;
END;
$$;

CREATE TRIGGER trg_ticket_inventory_consumption
AFTER UPDATE OF paid, voided ON public.ticket
FOR EACH ROW
EXECUTE PROCEDURE selemti.trg_ticket_inventory_consumption();
SQL);
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trg_ticket_inventory_consumption'
    ) THEN
        DROP TRIGGER trg_ticket_inventory_consumption ON public.ticket;
    END IF;
END;
$$;

DROP FUNCTION IF EXISTS selemti.trg_ticket_inventory_consumption();
DROP FUNCTION IF EXISTS selemti.fn_reversar_consumo_ticket(bigint);
DROP FUNCTION IF EXISTS selemti.fn_confirmar_consumo_ticket(bigint);
DROP FUNCTION IF EXISTS selemti.fn_expandir_consumo_ticket(bigint);
SQL);

        Schema::connection('pgsql')->dropIfExists('inv_consumo_pos_log');
        Schema::connection('pgsql')->dropIfExists('inv_consumo_pos_det');
        Schema::connection('pgsql')->dropIfExists('inv_consumo_pos');
    }
};
