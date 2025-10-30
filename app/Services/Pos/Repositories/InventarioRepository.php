<?php

namespace App\Services\Pos\Repositories;

use Illuminate\Support\Facades\DB;

class InventarioRepository
{
    /**
     * Obtiene los movimientos de inventario por ticket
     *
     * @param int $ticketId
     * @return array
     */
    public function getMovimientosByTicket(int $ticketId): array
    {
        $results = DB::connection('pgsql')
            ->table('selemti.mov_inv as mi')
            ->leftJoin('selemti.items as i', 'i.id', '=', 'mi.item_id')
            ->where('mi.ref_id', $ticketId)
            ->whereIn('mi.ref_tipo', ['POS_TICKET', 'POS_TICKET_REPROCESS', 'POS_TICKET_REV'])
            ->select([
                'mi.*',
                'i.descripcion as item_descripcion',
                'i.clave as item_clave',
            ])
            ->orderBy('mi.ts')
            ->get();

        return $results->map(fn ($mov) => (array) $mov)->toArray();
    }

    /**
     * Obtiene los movimientos agrupados por item
     *
     * @param int $ticketId
     * @return array
     */
    public function getMovimientosAgrupadosByTicket(int $ticketId): array
    {
        $results = DB::connection('pgsql')
            ->select("
                SELECT
                    mi.item_id,
                    i.descripcion as item_descripcion,
                    i.clave as item_clave,
                    mi.ref_tipo,
                    SUM(mi.qty) as total_qty,
                    mi.uom,
                    COUNT(*) as num_movimientos
                FROM selemti.mov_inv mi
                LEFT JOIN selemti.items i ON i.id = mi.item_id
                WHERE mi.ref_id = ?
                    AND mi.ref_tipo IN ('POS_TICKET', 'POS_TICKET_REPROCESS', 'POS_TICKET_REV')
                GROUP BY mi.item_id, i.descripcion, i.clave, mi.ref_tipo, mi.uom
                ORDER BY i.descripcion
            ", [$ticketId]);

        return array_map(fn ($row) => (array) $row, $results);
    }

    /**
     * Verifica si un item existe en el inventario
     *
     * @param int $itemId
     * @return bool
     */
    public function itemExists(int $itemId): bool
    {
        return DB::connection('pgsql')
            ->table('selemti.items')
            ->where('id', $itemId)
            ->exists();
    }

    /**
     * Obtiene información de un item
     *
     * @param int $itemId
     * @return array|null
     */
    public function getItemInfo(int $itemId): ?array
    {
        $result = DB::connection('pgsql')
            ->table('selemti.items')
            ->where('id', $itemId)
            ->first();

        return $result ? (array) $result : null;
    }

    /**
     * Obtiene el stock actual de un item en un almacén
     *
     * @param int $itemId
     * @param int $almacenId
     * @return float
     */
    public function getStockActual(int $itemId, int $almacenId): float
    {
        $result = DB::connection('pgsql')
            ->select("
                SELECT COALESCE(SUM(qty), 0) as stock
                FROM selemti.mov_inv
                WHERE item_id = ?
                    AND almacen_id = ?
            ", [$itemId, $almacenId]);

        return $result[0]->stock ?? 0.0;
    }
}
