<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::unprepared("
            CREATE OR REPLACE VIEW selemti.vw_item_last_price_pref AS
            SELECT DISTINCT ON (pol.item_id)
                pol.item_id::text AS item_id,
                po.vendor_id::text AS vendor_id,
                pol.precio_unitario AS price,
                pol.qty AS pack_qty,
                pol.uom AS pack_uom,
                po.created_at AS effective_from
            FROM selemti.purchase_order_lines pol
            JOIN selemti.purchase_orders po ON po.id = pol.order_id
            WHERE po.estado IN ('EMITIDA', 'RECIBIDA', 'PARCIAL', 'APROBADA')
            ORDER BY pol.item_id, po.created_at DESC NULLS LAST;
        ");
    }

    public function down(): void
    {
        DB::unprepared("DROP VIEW IF EXISTS selemti.vw_item_last_price_pref;");
    }
};
