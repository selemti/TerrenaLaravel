<?php

namespace App\Services\Pos\Repositories;

use Illuminate\Support\Facades\DB;

class TicketRepository
{
    /**
     * Obtiene el header del ticket desde public.ticket
     *
     * @param int $ticketId
     * @return array|null
     */
    public function getTicketHeader(int $ticketId): ?array
    {
        $result = DB::connection('pgsql')
            ->table('public.ticket')
            ->where('id', $ticketId)
            ->first();

        return $result ? (array) $result : null;
    }

    /**
     * Obtiene los items del ticket desde public.ticket_item
     *
     * @param int $ticketId
     * @return array
     */
    public function getTicketItems(int $ticketId): array
    {
        $results = DB::connection('pgsql')
            ->table('public.ticket_item')
            ->where('ticket_id', $ticketId)
            ->get();

        return $results->map(fn ($item) => (array) $item)->toArray();
    }

    /**
     * Obtiene los modificadores de los items del ticket
     * desde public.ticket_item_modifier y selemti.ticket_item_modifiers
     *
     * @param int $ticketId
     * @return array
     */
    public function getTicketItemModifiers(int $ticketId): array
    {
        // Primero intentamos desde la tabla pública
        $publicModifiers = DB::connection('pgsql')
            ->select("
                SELECT
                    tim.ticket_item_id,
                    tim.modifier_type,
                    tim.name as modifier_name,
                    tim.extra_price,
                    COALESCE(tim.quantity, 1) as quantity,
                    tim.name as pos_code
                FROM public.ticket_item_modifier tim
                INNER JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
                WHERE ti.ticket_id = ?
                ORDER BY tim.ticket_item_id, tim.id
            ", [$ticketId]);

        // Luego intentamos desde selemti si existe
        $selemtiModifiers = [];
        try {
            $selemtiModifiers = DB::connection('pgsql')
                ->select("
                    SELECT
                        stim.ticket_item_id,
                        stim.modifier_type,
                        stim.modifier_name,
                        stim.extra_price,
                        COALESCE(stim.quantity, 1) as quantity,
                        stim.pos_code
                    FROM selemti.ticket_item_modifiers stim
                    INNER JOIN public.ticket_item ti ON ti.id = stim.ticket_item_id
                    WHERE ti.ticket_id = ?
                    ORDER BY stim.ticket_item_id, stim.id
                ", [$ticketId]);
        } catch (\Exception $e) {
            // Si la tabla no existe, continuamos solo con public
        }

        // Combinamos ambos resultados
        $allModifiers = array_merge(
            array_map(fn ($row) => (array) $row, $publicModifiers),
            array_map(fn ($row) => (array) $row, $selemtiModifiers)
        );

        return $allModifiers;
    }

    /**
     * Obtiene información completa del ticket con items y modificadores
     *
     * @param int $ticketId
     * @return array
     */
    public function getTicketComplete(int $ticketId): array
    {
        $header = $this->getTicketHeader($ticketId);
        if (!$header) {
            return [];
        }

        $items = $this->getTicketItems($ticketId);
        $modifiers = $this->getTicketItemModifiers($ticketId);

        // Agrupar modificadores por ticket_item_id
        $modifiersByItem = [];
        foreach ($modifiers as $modifier) {
            $itemId = $modifier['ticket_item_id'];
            if (!isset($modifiersByItem[$itemId])) {
                $modifiersByItem[$itemId] = [];
            }
            $modifiersByItem[$itemId][] = $modifier;
        }

        // Agregar modificadores a cada item
        foreach ($items as &$item) {
            $item['modifiers'] = $modifiersByItem[$item['id']] ?? [];
        }

        return [
            'header' => $header,
            'items' => $items,
        ];
    }

    /**
     * Verifica si el ticket está pagado
     *
     * @param int $ticketId
     * @return bool
     */
    public function isTicketPaid(int $ticketId): bool
    {
        $ticket = $this->getTicketHeader($ticketId);
        return $ticket && ($ticket['paid'] ?? false);
    }

    /**
     * Verifica si el ticket está anulado/voided
     *
     * @param int $ticketId
     * @return bool
     */
    public function isTicketVoided(int $ticketId): bool
    {
        $ticket = $this->getTicketHeader($ticketId);
        return $ticket && ($ticket['voided'] ?? false);
    }

    /**
     * Obtiene tickets pagados de las últimas N horas
     *
     * @param int $hours
     * @param int $limit
     * @return array
     */
    public function getTicketsPaidLastHours(int $hours = 24, int $limit = 50): array
    {
        $results = DB::connection('pgsql')
            ->select("
                SELECT
                    t.id,
                    t.daily_folio,
                    t.create_date,
                    t.total_amount,
                    t.paid,
                    t.voided,
                    t.branch_key
                FROM public.ticket t
                WHERE t.paid = true
                    AND t.voided = false
                    AND t.create_date >= NOW() - INTERVAL '{$hours} hours'
                ORDER BY t.create_date DESC
                LIMIT ?
            ", [$limit]);

        return array_map(fn ($row) => (array) $row, $results);
    }
}
