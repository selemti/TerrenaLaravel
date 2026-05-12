<?php

namespace App\Adapters\FloreantPos;

use App\Adapters\FloreantPos\Dtos\PosMenuModifierDto;
use App\Adapters\FloreantPos\Dtos\PosTicketDto;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Anti-Corruption Layer para FloreantPOS.
 *
 * Centraliza todas las lecturas al schema `public` (FloreantPOS).
 * NUNCA escribir en public.* — solo lectura.
 * Los servicios de negocio deben usar este adapter en lugar de
 * hacer DB::table('public.*') directamente.
 */
class FloreantPosAdapter
{
    protected string $connection = 'pgsql';

    /**
     * Obtiene IDs de tickets de un día que aún no tienen registro de consumo.
     * Usado por DailyCloseService para procesar consumo teórico.
     */
    public function getUnprocessedTicketIdsByDate(string $date): Collection
    {
        return DB::connection($this->connection)
            ->table('public.ticket as t')
            ->leftJoin('selemti.inv_consumo_pos as c', 'c.ticket_id', '=', 't.id')
            ->whereDate('t.creation_date', $date)
            ->whereNull('c.ticket_id')
            ->pluck('t.id');
    }

    /**
     * Obtiene tickets pagados y no anulados en un rango de fechas.
     * Usa closing_date como criterio de cierre.
     *
     * @return Collection<PosTicketDto>
     */
    public function getPaidTicketsByDateRange(string $startDate, string $endDate, ?int $terminalId = null): Collection
    {
        $query = DB::connection($this->connection)
            ->table('public.ticket as t')
            ->select('t.id', 't.creation_date', 't.paid_time', 't.closing_date',
                't.paid', 't.voided', 't.terminal_id', 't.total_discount')
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->whereBetween('t.closing_date', [$startDate, $endDate]);

        if ($terminalId !== null) {
            $query->where('t.terminal_id', $terminalId);
        }

        return $query->get()->map(fn ($row) => PosTicketDto::fromRow($row));
    }

    /**
     * Devuelve el group_id correcto de un modificador desde el maestro POS.
     * Usado por ModifierValidationService.
     */
    public function getModifierGroupId(int $modifierId): ?int
    {
        return DB::connection($this->connection)
            ->table('public.menu_modifier')
            ->where('id', $modifierId)
            ->value('group_id');
    }

    /**
     * Verifica si un item_id corresponde a un modificador registrado en el POS.
     */
    public function isModifier(int $itemId): bool
    {
        return DB::connection($this->connection)
            ->table('public.menu_modifier')
            ->where('id', $itemId)
            ->exists();
    }

    /**
     * Devuelve un modificador con su grupo ya resuelto.
     * Usado por ModifierValidationService y DemandCalculationService.
     */
    public function getModifierWithGroup(int $modifierId): ?PosMenuModifierDto
    {
        $row = DB::connection($this->connection)
            ->table('public.menu_modifier as mm')
            ->join('public.menu_modifier_group as mg', 'mg.id', '=', 'mm.group_id')
            ->where('mm.id', $modifierId)
            ->select('mm.id', 'mm.name', 'mg.id as group_id', 'mg.name as group_name')
            ->first();

        return $row ? PosMenuModifierDto::fromRow($row) : null;
    }

    /**
     * Obtiene demanda histórica de un modificador en un rango de fechas.
     * Usado por DemandCalculationService.
     */
    public function getModifierDemandByDateRange(int $modifierId, string $startDate, string $endDate): Collection
    {
        return DB::connection($this->connection)
            ->table('public.ticket as t')
            ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
            ->join('public.ticket_item_modifier as tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->join('public.menu_modifier as mm', 'mm.id', '=', 'tim.item_id')
            ->where('mm.id', $modifierId)
            ->whereBetween('t.closing_date', [$startDate, $endDate])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->selectRaw("
                SUM(tim.item_count) as total_units,
                COUNT(DISTINCT t.id) as total_tickets,
                AVG(tim.item_count) as avg_per_ticket,
                DATE_TRUNC('day', t.closing_date) as day
            ")
            ->groupBy('day')
            ->orderBy('day')
            ->get();
    }

    /**
     * Obtiene ventas por ítem de menú en un rango de fechas.
     * Usado por MenuEngineeringService.
     */
    public function getSalesByMenuItemInRange(string $startDate, string $endDate, array $filters = []): Collection
    {
        $query = DB::connection($this->connection)
            ->table('public.ticket_item as ti')
            ->selectRaw('mi.id as menu_item_id, mi.plu, mi.name, mi.category,
                SUM(ti.item_quantity) as units,
                SUM(ti.item_subtotal) as net_sales,
                AVG(ti.item_price) as avg_price')
            ->join('selemti.menu_item_sync_map as map', 'map.pos_identifier', '=', 'ti.item_id')
            ->join('selemti.menu_items as mi', 'mi.id', '=', 'map.menu_item_id')
            ->join('public.ticket as t', 't.id', '=', 'ti.ticket_id')
            ->whereBetween('t.paid_time', [$startDate, $endDate])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->groupBy('mi.id', 'mi.plu', 'mi.name', 'mi.category');

        if ($filters['category'] ?? null) {
            $query->where('mi.category', $filters['category']);
        }

        if ($filters['terminal_id'] ?? null) {
            $query->where('t.terminal_id', $filters['terminal_id']);
        }

        return $query->get();
    }
}
