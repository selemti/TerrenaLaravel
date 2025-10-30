<?php

namespace App\Services\Pos\Repositories;

use Illuminate\Support\Facades\DB;

class ConsumoPosRepository
{
    /**
     * Obtiene el consumo por ticket con sus detalles
     *
     * @param int $ticketId
     * @return array
     */
    public function getConsumoByTicket(int $ticketId): array
    {
        $consumo = DB::connection('pgsql')
            ->table('selemti.inv_consumo_pos as icp')
            ->where('icp.ticket_id', $ticketId)
            ->first();

        if (!$consumo) {
            return [];
        }

        $detalles = DB::connection('pgsql')
            ->table('selemti.inv_consumo_pos_det as icpd')
            ->leftJoin('selemti.items as i', 'i.id', '=', 'icpd.item_id')
            ->where('icpd.consumo_id', $consumo->id)
            ->select([
                'icpd.*',
                'i.descripcion as item_descripcion',
                'i.es_empaque_to_go',
                'i.es_consumible_operativo',
            ])
            ->get();

        return [
            'header' => (array) $consumo,
            'detalles' => $detalles->map(fn ($det) => (array) $det)->toArray(),
        ];
    }

    /**
     * Obtiene el estado del consumo para un ticket
     *
     * @param int $ticketId
     * @return string|null "PENDIENTE" | "CONFIRMADO" | "ANULADO" | null
     */
    public function getEstadoConsumo(int $ticketId): ?string
    {
        $result = DB::connection('pgsql')
            ->table('selemti.inv_consumo_pos')
            ->where('ticket_id', $ticketId)
            ->value('estado');

        return $result;
    }

    /**
     * Verifica si existe un consumo para el ticket
     *
     * @param int $ticketId
     * @return bool
     */
    public function existeConsumo(int $ticketId): bool
    {
        return DB::connection('pgsql')
            ->table('selemti.inv_consumo_pos')
            ->where('ticket_id', $ticketId)
            ->exists();
    }

    /**
     * Verifica si existen movimientos de inventario para el ticket
     *
     * @param int $ticketId
     * @return bool
     */
    public function hasMovInvForTicket(int $ticketId): bool
    {
        return DB::connection('pgsql')
            ->table('selemti.mov_inv')
            ->whereIn('ref_tipo', ['POS_TICKET', 'POS_TICKET_REPROCESS'])
            ->where('ref_id', $ticketId)
            ->exists();
    }

    /**
     * Obtiene el conteo de movimientos de inventario por tipo
     *
     * @param int $ticketId
     * @return array
     */
    public function getMovInvCountByType(int $ticketId): array
    {
        $results = DB::connection('pgsql')
            ->table('selemti.mov_inv')
            ->select([
                'ref_tipo',
                DB::raw('COUNT(*) as count'),
            ])
            ->whereIn('ref_tipo', ['POS_TICKET', 'POS_TICKET_REPROCESS', 'POS_TICKET_REV'])
            ->where('ref_id', $ticketId)
            ->groupBy('ref_tipo')
            ->get();

        $counts = [
            'POS_TICKET' => 0,
            'POS_TICKET_REPROCESS' => 0,
            'POS_TICKET_REV' => 0,
        ];

        foreach ($results as $row) {
            $counts[$row->ref_tipo] = (int) $row->count;
        }

        return $counts;
    }

    /**
     * Verifica si faltan empaques to-go en el consumo
     *
     * @param int $ticketId
     * @return bool
     */
    public function faltanEmpaquesToGo(int $ticketId): bool
    {
        $consumo = $this->getConsumoByTicket($ticketId);

        if (empty($consumo)) {
            return false;
        }

        // TODO: Implementar lógica para detectar si el ticket requiere empaques
        // y verificar si están en los detalles del consumo
        // Por ahora retornamos false
        return false;
    }

    /**
     * Verifica si faltan consumibles operativos en el consumo
     *
     * @param int $ticketId
     * @return bool
     */
    public function faltanConsumiblesOperativos(int $ticketId): bool
    {
        $consumo = $this->getConsumoByTicket($ticketId);

        if (empty($consumo)) {
            return false;
        }

        // TODO: Implementar lógica para detectar si el ticket requiere consumibles
        // operativos y verificar si están en los detalles del consumo
        // Por ahora retornamos false
        return false;
    }
}
