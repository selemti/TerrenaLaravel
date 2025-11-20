<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Database optimization seeder for inventory operations
 *
 * This seeder adds missing indexes and optimizes queries for better performance
 */
class InventoryOptimizationSeeder extends Seeder
{
    public function run(): void
    {
        $this->addMissingIndexes();
        $this->updateViewForPerformance();
    }

    private function addMissingIndexes(): void
    {
        // TODO: this table (stock) does not exist in BD. Revisar diseño de Inventario.
        // Index for quick stock lookup by almacen and item (used in transfer approval)
        // if (! Schema::hasIndex('selemti.stock', ['almacen_id', 'item_id'])) {
        //     DB::connection('pgsql')->statement('CREATE INDEX CONCURRENTLY idx_stock_almacen_item ON selemti.stock (almacen_id, item_id)');
        // }

        // Index for mov_inv lookups by item, almacen, and reference
        if (! Schema::hasIndex('selemti.mov_inv', ['item_id', 'almacen_id', 'referencia_tipo', 'referencia_id'])) {
            DB::connection('pgsql')->statement('CREATE INDEX CONCURRENTLY idx_mov_inv_item_almacen_ref ON selemti.mov_inv (item_id, almacen_id, referencia_tipo, referencia_id)');
        }

        // Index for transfer lines lookups
        if (! Schema::hasIndex('selemti.transfer_det', ['transfer_id', 'item_id'])) {
            DB::connection('pgsql')->statement('CREATE INDEX CONCURRENTLY idx_transfer_det_transfer_item ON selemti.transfer_det (transfer_id, item_id)');
        }

        // Index for quick order filtering
        if (! Schema::hasIndex('selemti.transfer_cab', ['estado', 'origen_almacen_id', 'destino_almacen_id'])) {
            DB::connection('pgsql')->statement('CREATE INDEX CONCURRENTLY idx_transfer_cab_estado_almacenes ON selemti.transfer_cab (estado, origen_almacen_id, destino_almacen_id)');
        }

        // Index for inventory counts performance
        if (! Schema::hasIndex('selemti.inventario_conteos', ['estado', 'almacen_id', 'sucursal_id'])) {
            DB::connection('pgsql')->statement('CREATE INDEX CONCURRENTLY idx_inventario_conteos_estado_almacen ON selemti.inventario_conteos (estado, almacen_id, sucursal_id)');
        }

        // Index for inventory count lines
        if (! Schema::hasIndex('selemti.inventario_conteos_lineas', ['count_id', 'item_id'])) {
            DB::connection('pgsql')->statement('CREATE INDEX CONCURRENTLY idx_inventario_conteos_lineas_count_item ON selemti.inventario_conteos_lineas (count_id, item_id)');
        }

        // Index for recepciones performance
        if (! Schema::hasIndex('selemti.inv_receptions', ['estado', 'almacen_id', 'purchase_order_id'])) {
            DB::connection('pgsql')->statement('CREATE INDEX CONCURRENTLY idx_inv_receptions_estado_almacen_po ON selemti.inv_receptions (estado, almacen_id, purchase_order_id)');
        }

        // Index for recepcion lines
        if (! Schema::hasIndex('selemti.inv_reception_lines', ['reception_id', 'po_line_id'])) {
            DB::connection('pgsql')->statement('CREATE INDEX CONCURRENTLY idx_inv_reception_lines ON selemti.inv_reception_lines (reception_id, po_line_id)');
        }
    }

    /**
     * Creates optimized views for inventory operations
     */
    private function updateViewForPerformance(): void
    {
        // Create a kardex view that aggregates movement data efficiently
        DB::connection('pgsql')->statement('
            CREATE OR REPLACE VIEW selemti.vw_kardex_optimized AS
            SELECT
                mi.item_id,
                mi.sucursal_id,
                mi.ts,
                mi.tipo,
                mi.cantidad,
                mi.unidad_medida,
                mi.usuario_id,
                mi.ref_tipo,
                mi.ref_id,
                SUM(mi.cantidad) OVER (
                    PARTITION BY mi.item_id, mi.sucursal_id
                    ORDER BY mi.ts, mi.id
                    ROWS UNBOUNDED PRECEDING
                ) as saldo_acumulado,
                u.nombre as unidad_nombre,
                i.nombre as item_nombre,
                a.nombre as almacen_nombre
            FROM selemti.mov_inv mi
            LEFT JOIN selemti.items i ON mi.item_id = i.id
            LEFT JOIN selemti.cat_almacenes a ON mi.sucursal_id = a.id
            LEFT JOIN selemti.unidades_medida u ON mi.unidad_medida = u.codigo
        ');

        // TODO: this view (vw_stock_resumen_optimized) references table 'stock' which does not exist in BD. Revisar diseño de Inventario.
        // Create an inventory summary view optimized for queries
        // DB::connection('pgsql')->statement('
        //     CREATE OR REPLACE VIEW selemti.vw_stock_resumen_optimized AS
        //     SELECT
        //         s.item_id,
        //         s.almacen_id,
        //         s.cantidad_actual,
        //         s.fecha_ultima_actualizacion,
        //         i.nombre as item_nombre,
        //         i.clave as item_sku,
        //         i.tipo as item_tipo,
        //         a.nombre as almacen_nombre,
        //         a.codigo as almacen_codigo,
        //         c.nombre as categoria_nombre
        //     FROM selemti.stock s
        //     LEFT JOIN selemti.items i ON s.item_id = i.id
        //     LEFT JOIN selemti.cat_almacenes a ON s.almacen_id = a.id
        //     LEFT JOIN selemti.categorias c ON i.categoria_id = c.id
        // ');
    }
}
