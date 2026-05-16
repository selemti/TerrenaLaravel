<?php

namespace App\Adapters\FloreantPos;

use App\Adapters\FloreantPos\Dtos\PosMenuModifierDto;
use App\Adapters\FloreantPos\Dtos\PosTicketDto;
use Carbon\Carbon;
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

    // -----------------------------------------------------------------------
    // Catalog queries
    // -----------------------------------------------------------------------

    /**
     * Devuelve categorías del menú FloreantPOS para API.
     * Usado por CatalogsController.
     */
    public function getMenuCategories(bool $visibleOnly = true): Collection
    {
        $query = DB::connection($this->connection)
            ->table('public.menu_category')
            ->select([
                DB::raw("'CAT-' || id::text as id"),
                'name',
                'translated_name',
                'visible',
                'beverage',
                'sort_order',
            ])
            ->orderBy('sort_order')
            ->orderBy('name');

        if ($visibleOnly) {
            $query->where('visible', true);
        }

        return $query->get();
    }

    /**
     * Devuelve terminales activas del POS.
     * Usado por SalesModsController.
     */
    public function getEnabledTerminals(): Collection
    {
        return DB::connection($this->connection)
            ->table('public.terminal')
            ->select('id', 'name')
            ->where('enabled', true)
            ->orderBy('id')
            ->get();
    }

    /**
     * Devuelve razones de anulación del POS.
     * Usado por TicketManagementController.
     */
    public function getVoidReasons(): Collection
    {
        return DB::connection($this->connection)
            ->table('public.void_reasons')
            ->orderBy('id')
            ->pluck('reason_text', 'id');
    }

    // -----------------------------------------------------------------------
    // User queries
    // -----------------------------------------------------------------------

    /**
     * Devuelve datos de usuario POS indexados por auto_id.
     * Usado por CortesHistoricoController para resolver nombre de cajero.
     */
    public function getPosUsersByAutoIds(array $autoIds): Collection
    {
        if (empty($autoIds)) {
            return collect();
        }

        return DB::connection($this->connection)
            ->table('public.users')
            ->whereIn('auto_id', $autoIds)
            ->select('auto_id', 'user_id', 'first_name', 'last_name')
            ->get()
            ->keyBy('auto_id');
    }

    // -----------------------------------------------------------------------
    // Ticket queries
    // -----------------------------------------------------------------------

    /**
     * Devuelve un ticket por su ID.
     * Usado por SalesResolutionService y AuditCanonicalSales.
     */
    public function getTicketById(int $id): ?object
    {
        return DB::connection($this->connection)
            ->table('public.ticket')
            ->where('id', $id)
            ->select('id', 'sub_total', 'total_price', 'total_discount', 'folio_date')
            ->first();
    }

    /**
     * Devuelve tickets con descuentos > 0 en una fecha, para auditoría.
     * Usado por AuditCanonicalSales.
     */
    public function getTicketsWithDiscountsByDate(string $date, int $limit): Collection
    {
        return DB::connection($this->connection)
            ->table('public.ticket')
            ->where('voided', false)
            ->whereDate('folio_date', $date)
            ->where('total_discount', '>', 0)
            ->orderBy('id', 'desc')
            ->limit($limit)
            ->get();
    }

    /**
     * Devuelve tickets de una sesión para un terminal en un rango de fechas.
     * Usado por CortesHistoricoController.
     */
    public function getTicketsByTerminalAndDateRange(
        int $terminalId,
        string $fromTs,
        ?string $toTs,
        int $limit = 100
    ): Collection {
        return DB::connection($this->connection)
            ->table('public.ticket as t')
            ->where('t.terminal_id', $terminalId)
            ->whereDate('t.create_date', '>=', $fromTs)
            ->where(function ($q) use ($toTs) {
                $q->whereNull('t.closing_date')
                    ->orWhereDate('t.closing_date', '<=', $toTs ?? now());
            })
            ->select('t.id', 't.create_date', 't.closing_date', 't.total_price', 't.paid', 't.voided', 't.status')
            ->orderBy('t.create_date')
            ->limit($limit)
            ->get();
    }

    // -----------------------------------------------------------------------
    // Discount / transaction queries
    // -----------------------------------------------------------------------

    /**
     * Suma de transacciones efectivas para un ticket.
     * Usado por SalesResolutionService.
     */
    public function getEffectiveTransactionSum(int $ticketId): float
    {
        return (float) DB::connection($this->connection)
            ->table('public.transactions as tx')
            ->where('tx.ticket_id', $ticketId)
            ->where(function ($q) {
                $q->where('tx.voided', false)->orWhereNull('tx.voided');
            })
            ->whereIn(DB::raw("UPPER(COALESCE(tx.transaction_type, ''))"), ['CREDIT', 'DEBIT'])
            ->whereNotIn(DB::raw("UPPER(COALESCE(tx.payment_type, ''))"), ['REFUND', 'VOID_TRANS', 'REFUND_CARD'])
            ->where('tx.amount', '>', 0)
            ->sum('tx.amount');
    }

    /**
     * Descuentos a nivel de ticket.
     * Usado por SalesResolutionService.
     */
    public function getTicketDiscounts(int $ticketId): Collection
    {
        return DB::connection($this->connection)
            ->table('public.ticket_discount as td')
            ->select('td.type', 'td.value', 'td.name')
            ->where('td.ticket_id', $ticketId)
            ->get();
    }

    /**
     * Descuentos a nivel de ítem para un ticket.
     * Usado por SalesResolutionService.
     */
    public function getTicketItemDiscounts(int $ticketId): Collection
    {
        return DB::connection($this->connection)
            ->table('public.ticket_item as ti')
            ->join('public.ticket_item_discount as tid', 'tid.ticket_itemid', '=', 'ti.id')
            ->select('tid.type', 'tid.value', 'tid.amount', 'ti.sub_total as item_sub_total')
            ->where('ti.ticket_id', $ticketId)
            ->get();
    }

    // -----------------------------------------------------------------------
    // Report bulk queries
    // -----------------------------------------------------------------------

    /**
     * Tickets con datos financieros para el reporte de excepciones.
     * Usado por SalesExceptionsReportService::fetchTickets().
     */
    public function fetchExceptionTickets(Carbon $start, Carbon $end, array $branches, array $terminals): Collection
    {
        $discountExpression = <<<'SQL'
            GREATEST(
                0,
                LEAST(
                    COALESCE(
                        t.total_discount,
                        (
                            SELECT SUM(
                                COALESCE(
                                    NULLIF(to_jsonb(ti)->>'discount_amount', '')::numeric,
                                    COALESCE(ti.discount, 0)
                                )
                            )
                            FROM public.ticket_item ti
                            WHERE ti.ticket_id = t.id
                        ),
                        COALESCE(t.sub_total, 0) - COALESCE(t.total_price, 0),
                        0
                    ),
                    COALESCE(t.sub_total, t.total_price, 0)
                )
            )::numeric(14,2)
        SQL;

        $dateColumnExpr = 'COALESCE(t.folio_date, t.closing_date::date, t.create_date::date)';

        $query = DB::connection($this->connection)
            ->table('public.ticket as t')
            ->selectRaw("
                t.id AS ticket_id,
                {$dateColumnExpr} AS folio_date,
                UPPER(COALESCE(t.branch_key, 'SIN_SUCURSAL')) AS branch_key,
                t.terminal_id,
                COALESCE(t.paid, FALSE) AS paid_flag,
                COALESCE(t.voided, FALSE) AS voided_flag,
                COALESCE(t.settled, FALSE) AS settled_flag,
                COALESCE(t.wasted, FALSE) AS wasted_flag,
                COALESCE(t.refunded, FALSE) AS refunded_flag,
                COALESCE(t.is_re_opened, FALSE) AS reopened_flag,
                COALESCE(t.status, '') AS ticket_status,
                COALESCE(t.ticket_type, '') AS ticket_type,
                COALESCE(t.daily_folio, 0) AS daily_folio,
                COALESCE(t.sub_total, 0)::numeric(14,2) AS gross_total,
                COALESCE(t.total_price, 0)::numeric(14,2) AS net_total_raw,
                COALESCE(t.sub_total, 0)::numeric(14,2) AS sub_total,
                COALESCE(t.total_tax, 0)::numeric(14,2) AS total_tax,
                COALESCE(t.service_charge, 0)::numeric(14,2) AS service_charge,
                COALESCE(t.delivery_charge, 0)::numeric(14,2) AS delivery_charge,
                COALESCE(t.paid_amount, 0)::numeric(14,2) AS paid_amount_flag,
                {$discountExpression} AS discount_total
            ")
            ->whereRaw("{$dateColumnExpr} BETWEEN ? AND ?", [$start->toDateString(), $end->toDateString()]);

        if (! empty($branches)) {
            $query->whereIn(DB::raw("UPPER(COALESCE(t.branch_key, ''))"), $branches);
        }

        if (! empty($terminals)) {
            $query->whereIn('t.terminal_id', $terminals);
        }

        return collect($query->orderBy('folio_date')->orderBy('t.id')->get());
    }

    /**
     * Resumen de pagos agrupado por ticket_id.
     * Usado por SalesExceptionsReportService::loadPaymentSummary().
     */
    public function loadPaymentSummaryByTicketIds(Collection $ticketIds): Collection
    {
        if ($ticketIds->isEmpty()) {
            return collect();
        }

        return DB::connection($this->connection)
            ->table('public.transactions as tx')
            ->select('tx.ticket_id')
            ->selectRaw("SUM(CASE WHEN COALESCE(tx.voided,FALSE)=FALSE AND UPPER(COALESCE(tx.transaction_type,'')) IN ('CREDIT','DEBIT') AND UPPER(COALESCE(tx.payment_type,'')) NOT IN ('REFUND','VOID_TRANS','REFUND_CARD') AND COALESCE(tx.amount,0)>0 THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric(14,2) AS payment_total")
            ->selectRaw("SUM(CASE WHEN COALESCE(tx.voided,FALSE)=FALSE AND UPPER(COALESCE(tx.transaction_type,'')) IN ('CREDIT','DEBIT') AND UPPER(COALESCE(tx.payment_type,'')) NOT IN ('REFUND','VOID_TRANS','REFUND_CARD') AND COALESCE(tx.amount,0)<0 THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric(14,2) AS payment_adjustment_total")
            ->selectRaw("SUM(CASE WHEN COALESCE(tx.voided,FALSE)=FALSE AND UPPER(COALESCE(tx.payment_type,'')) IN ('REFUND','REFUND_CARD') THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric(14,2) AS refund_total")
            ->selectRaw("SUM(CASE WHEN COALESCE(tx.voided,FALSE)=FALSE AND UPPER(COALESCE(tx.payment_type,''))='VOID_TRANS' THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric(14,2) AS void_total")
            ->selectRaw('SUM(CASE WHEN COALESCE(tx.voided,FALSE)=FALSE THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric(14,2) AS recorded_total')
            ->selectRaw('SUM(CASE WHEN COALESCE(tx.voided,FALSE)=FALSE THEN 1 ELSE 0 END) AS tx_count')
            ->selectRaw("SUM(CASE WHEN COALESCE(tx.voided,FALSE)=FALSE AND UPPER(COALESCE(tx.transaction_type,'')) IN ('CREDIT','DEBIT') AND UPPER(COALESCE(tx.payment_type,'')) NOT IN ('REFUND','VOID_TRANS','REFUND_CARD') AND COALESCE(tx.amount,0)>0 THEN 1 ELSE 0 END) AS payment_positive_count")
            ->selectRaw("SUM(CASE WHEN COALESCE(tx.voided,FALSE)=FALSE AND UPPER(COALESCE(tx.transaction_type,'')) IN ('CREDIT','DEBIT') AND UPPER(COALESCE(tx.payment_type,'')) NOT IN ('REFUND','VOID_TRANS','REFUND_CARD') AND COALESCE(tx.amount,0)<0 THEN 1 ELSE 0 END) AS payment_adjustment_count")
            ->whereIn('tx.ticket_id', $ticketIds)
            ->groupBy('tx.ticket_id')
            ->get()
            ->keyBy(fn (object $row) => (int) $row->ticket_id);
    }

    /**
     * Detalle de transacciones por ticket_id (lista plana).
     * Usado por SalesExceptionsReportService::loadTransactionDetails().
     */
    public function loadTransactionDetailsByTicketIds(Collection $ticketIds): Collection
    {
        if ($ticketIds->isEmpty()) {
            return collect();
        }

        return DB::connection($this->connection)
            ->table('public.transactions as tx')
            ->select('tx.ticket_id', 'tx.payment_type', 'tx.transaction_type', 'tx.amount', 'tx.voided')
            ->whereIn('tx.ticket_id', $ticketIds)
            ->orderBy('tx.id')
            ->get();
    }

    /**
     * Descuentos a nivel ticket agrupados por ticket_id (con coupon join).
     * Usado por SalesExceptionsReportService::loadDiscounts().
     */
    public function loadTicketDiscountsByTicketIds(Collection $ticketIds): Collection
    {
        if ($ticketIds->isEmpty()) {
            return collect();
        }

        return DB::connection($this->connection)
            ->table('public.ticket_discount as td')
            ->leftJoin('public.coupon_and_discount as cad', 'cad.id', '=', 'td.discount_id')
            ->select(
                'td.ticket_id',
                DB::raw("COALESCE(NULLIF(td.name, ''), cad.name, 'SIN NOMBRE') AS discount_name"),
                'td.type as discount_type',
                DB::raw('COALESCE(td.value, 0)::numeric(14,2) AS discount_amount'),
                DB::raw("'ticket'::text AS scope")
            )
            ->whereIn('td.ticket_id', $ticketIds)
            ->get();
    }

    /**
     * Descuentos a nivel ítem agrupados por ticket_id (con coupon join).
     * Usado por SalesExceptionsReportService::loadDiscounts().
     */
    public function loadItemDiscountsByTicketIds(Collection $ticketIds): Collection
    {
        if ($ticketIds->isEmpty()) {
            return collect();
        }

        return DB::connection($this->connection)
            ->table('public.ticket_item as ti')
            ->join('public.ticket_item_discount as tid', 'tid.ticket_itemid', '=', 'ti.id')
            ->leftJoin('public.coupon_and_discount as cad', 'cad.id', '=', 'tid.discount_id')
            ->select(
                'ti.ticket_id',
                DB::raw("COALESCE(NULLIF(tid.name, ''), cad.name, 'SIN NOMBRE') AS discount_name"),
                'tid.type as discount_type',
                DB::raw('COALESCE(tid.amount, tid.value, 0)::numeric(14,2) AS discount_amount'),
                DB::raw("'item'::text AS scope")
            )
            ->whereIn('ti.ticket_id', $ticketIds)
            ->get();
    }

    /**
     * Ítems de ticket agrupados por ticket_id.
     * Usado por SalesExceptionsReportService::loadItems().
     */
    public function loadItemsByTicketIds(Collection $ticketIds): Collection
    {
        if ($ticketIds->isEmpty()) {
            return collect();
        }

        return DB::connection($this->connection)
            ->table('public.ticket_item as ti')
            ->select(
                'ti.ticket_id',
                DB::raw("COALESCE(NULLIF(ti.item_name, ''), 'SIN NOMBRE') AS item_name"),
                DB::raw("COALESCE(NULLIF(ti.group_name, ''), NULLIF(ti.category_name, ''), '') AS item_group"),
                DB::raw('COALESCE(ti.item_quantity, ti.item_count, 1)::numeric(14,2) AS quantity'),
                DB::raw('COALESCE(ti.item_price, ti.sub_total, 0)::numeric(14,2) AS unit_price'),
                DB::raw('COALESCE(ti.sub_total, 0)::numeric(14,2) AS sub_total_amount'),
                DB::raw('COALESCE(ti.discount, 0)::numeric(14,2) AS discount_amount'),
                DB::raw('COALESCE(ti.total_price, ti.sub_total - COALESCE(ti.discount, 0), 0)::numeric(14,2) AS total_amount')
            )
            ->whereIn('ti.ticket_id', $ticketIds)
            ->orderBy('ti.ticket_id')
            ->orderBy('ti.id')
            ->get();
    }

    // -----------------------------------------------------------------------
    // Menu catalog queries (for SyncPosRecipes)
    // -----------------------------------------------------------------------

    /**
     * Top N productos por venta en un rango de fechas.
     * Usado por ReportsController::ventasTopProductos().
     */
    public function getTopProductsByRevenue(\Carbon\Carbon $start, \Carbon\Carbon $end, int $limit = 5): Collection
    {
        return DB::connection($this->connection)
            ->table('public.ticket_item as ti')
            ->selectRaw("
                ti.item_id AS plu,
                COALESCE(MAX(NULLIF(ti.item_name, '')), ti.item_id::text) AS descripcion,
                SUM(COALESCE(NULLIF(ti.item_quantity, 0), NULLIF(ti.item_count, 0), 0)::numeric) AS unidades,
                SUM(COALESCE(ti.total_price, 0)) AS venta_total
            ")
            ->join('public.ticket as t', 't.id', '=', 'ti.ticket_id')
            ->whereNotNull('ti.item_id')
            ->whereBetween('t.closing_date', [$start, $end])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->groupBy('ti.item_id')
            ->orderByDesc('venta_total')
            ->limit($limit)
            ->get();
    }

    /**
     * Estadísticas de ventas de productos para hoy.
     * Usado por ProductsReportController::getTodayStats().
     */
    public function getProductSalesSummaryForToday(string $fromTs, string $toTs): object
    {
        return DB::connection($this->connection)
            ->table('public.ticket AS t')
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.folio_date', [$fromTs, $toTs])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->selectRaw('SUM(ti.item_count) as unidades, SUM(ti.total_price) as ingresos, COUNT(DISTINCT t.id) as tickets, COUNT(DISTINCT ti.item_name) as productos_unicos')
            ->first() ?? (object) ['unidades' => 0, 'ingresos' => 0, 'tickets' => 0, 'productos_unicos' => 0];
    }

    /**
     * Modificadores de ítems de ticket por chunk de ticket_item_ids.
     * Usado por SalesDetailController.
     */
    public function getModifiersByTicketItemIds(array $ticketItemIds): Collection
    {
        if (empty($ticketItemIds)) {
            return collect();
        }

        $result = collect();

        foreach (array_chunk($ticketItemIds, 400) as $chunk) {
            $rows = DB::connection($this->connection)
                ->table('public.ticket_item_modifier as tim')
                ->selectRaw("
                    tim.ticket_item_id,
                    COALESCE(mm.name, tim.modifier_name, '') AS modifier_name,
                    COALESCE(tim.item_count, 0) AS modifier_count,
                    COALESCE(tim.total_price, 0) AS modifier_total,
                    COALESCE(mmg_mm.name, mmg_tim.name, 'Sin grupo') AS group_name
                ")
                ->leftJoin('public.menu_modifier as mm', 'mm.id', '=', 'tim.item_id')
                ->leftJoin('public.menu_modifier_group as mmg_mm', 'mmg_mm.id', '=', 'mm.group_id')
                ->leftJoin('public.menu_modifier_group as mmg_tim', 'mmg_tim.id', '=', 'tim.group_id')
                ->whereIn('tim.ticket_item_id', $chunk)
                ->get();

            $result = $result->merge($rows);
        }

        return $result;
    }

    /**
     * Ítems de menú con su grupo.
     * Usado por SyncPosRecipes. Acepta connection alternativa para host POS.
     */
    public function getMenuItemsWithGroups(string $connection = 'pgsql'): Collection
    {
        return DB::connection($connection)
            ->table('public.menu_item as mi')
            ->leftJoin('public.menu_group as mg', 'mi.group_id', '=', 'mg.id')
            ->select('mi.id', 'mi.name', 'mi.price', 'mg.name as group_name', 'mi.visible')
            ->orderBy('mi.id')
            ->get();
    }

    /**
     * Modificadores de menú con su grupo.
     * Usado por SyncPosRecipes. Acepta connection alternativa para host POS.
     */
    public function getMenuModifiersWithGroups(string $connection = 'pgsql'): Collection
    {
        return DB::connection($connection)
            ->table('public.menu_modifier as mm')
            ->leftJoin('public.menu_modifier_group as mg', 'mm.group_id', '=', 'mg.id')
            ->select('mm.id', 'mm.name', 'mm.price', 'mg.name as group_name')
            ->orderBy('mm.id')
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

    // -----------------------------------------------------------------------
    // ProductsReportService queries
    // -----------------------------------------------------------------------

    /**
     * Ventas de productos agrupadas por mes.
     */
    public function getProductSalesByMonth(
        Carbon $start,
        Carbon $end,
        ?array $branchIds = null,
        ?array $terminalIds = null
    ): Collection {
        $query = $this->buildTicketItemBaseQuery($start, $end, $branchIds, $terminalIds);

        return $query
            ->selectRaw("
                DATE_TRUNC('month', t.folio_date) AS mes,
                EXTRACT(YEAR FROM t.folio_date) AS anio,
                EXTRACT(MONTH FROM t.folio_date) AS numero_mes,
                COUNT(DISTINCT t.id) AS tickets_totales,
                SUM(ti.item_count) AS unidades_vendidas,
                SUM(ti.total_price) AS ingreso_total,
                ROUND(SUM(ti.total_price)::numeric, 2) AS ingreso_total_redondeado,
                AVG(ti.item_price) AS precio_promedio,
                MIN(ti.item_price) AS precio_minimo,
                MAX(ti.item_price) AS precio_maximo
            ")
            ->groupBy('mes', 'anio', 'numero_mes')
            ->orderBy('anio', 'desc')
            ->orderBy('numero_mes', 'desc')
            ->get();
    }

    /**
     * Ventas de productos agrupadas por categoría.
     */
    public function getProductSalesByCategory(
        Carbon $start,
        Carbon $end,
        ?array $branchIds = null,
        ?array $terminalIds = null
    ): Collection {
        return $this->buildTicketItemBaseQuery($start, $end, $branchIds, $terminalIds)
            ->selectRaw("
                ti.category_name AS categoria,
                COUNT(DISTINCT t.id) AS tickets_totales,
                SUM(ti.item_count) AS unidades_vendidas,
                SUM(ti.total_price) AS ingreso_total,
                ROUND(SUM(ti.total_price)::numeric, 2) AS ingreso_total_redondeado,
                AVG(ti.item_price) AS precio_promedio,
                COUNT(DISTINCT ti.item_name) AS productos_unicos
            ")
            ->groupBy('ti.category_name')
            ->orderBy('ingreso_total', 'desc')
            ->get();
    }

    /**
     * Ventas de productos agrupadas por producto.
     */
    public function getProductSalesByProduct(
        Carbon $start,
        Carbon $end,
        ?array $branchIds = null,
        ?array $terminalIds = null
    ): Collection {
        return $this->buildTicketItemBaseQuery($start, $end, $branchIds, $terminalIds)
            ->selectRaw("
                ti.category_name AS categoria,
                ti.group_name AS grupo_menu,
                ti.item_name AS producto,
                COUNT(DISTINCT t.id) AS tickets_totales,
                SUM(ti.item_count) AS unidades_vendidas,
                SUM(ti.total_price) AS ingreso_total,
                ROUND(SUM(ti.total_price)::numeric, 2) AS ingreso_total_redondeado,
                AVG(ti.item_price) AS precio_promedio,
                MIN(ti.item_price) AS precio_minimo,
                MAX(ti.item_price) AS precio_maximo
            ")
            ->groupBy('ti.category_name', 'ti.group_name', 'ti.item_name')
            ->orderBy('ingreso_total', 'desc')
            ->get();
    }

    /**
     * Ventas diarias de productos (detalle por ítem).
     */
    public function getDailyProductSales(
        Carbon $start,
        Carbon $end,
        ?array $branchIds = null,
        ?array $terminalIds = null
    ): Collection {
        $query = DB::connection($this->connection)
            ->table('public.ticket AS t')
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.folio_date', [$start->format('Y-m-d'), $end->format('Y-m-d')])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->whereNotNull('ti.item_name')
            ->where('ti.item_count', '>', 0)
            ->select('t.folio_date', 'ti.category_name', 'ti.item_name', 'ti.item_count',
                'ti.item_price', 'ti.total_price', 't.branch_key', 't.terminal_id')
            ->orderBy('t.folio_date', 'desc')
            ->orderBy('ti.item_name');

        if ($branchIds) {
            $query->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds) {
            $query->whereIn('t.terminal_id', $terminalIds);
        }

        return $query->get();
    }

    /**
     * Totales estilo JasperReports vs Canon SSOT.
     * Devuelve las 4 métricas crudas para que el servicio calcule los KPIs.
     */
    public function getJasperTotals(
        Carbon $start,
        Carbon $end,
        ?array $branchIds = null,
        ?array $terminalIds = null
    ): array {
        $baseTicketQuery = DB::connection($this->connection)
            ->table('public.ticket AS t')
            ->whereBetween('t.folio_date', [$start->format('Y-m-d 00:00:00'), $end->format('Y-m-d 23:59:59')])
            ->where('t.paid', true)
            ->where('t.voided', false);

        if ($branchIds) {
            $baseTicketQuery->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds) {
            $baseTicketQuery->whereIn('t.terminal_id', $terminalIds);
        }

        $canonTotals = DB::connection($this->connection)
            ->table('public.transactions as tx')
            ->join('public.ticket as t', 't.id', '=', 'tx.ticket_id')
            ->whereBetween('t.folio_date', [$start->format('Y-m-d 00:00:00'), $end->format('Y-m-d 23:59:59')])
            ->where(function ($q) { $q->where('tx.voided', false)->orWhereNull('tx.voided'); })
            ->whereIn(DB::raw("UPPER(COALESCE(tx.transaction_type, ''))"), ['CREDIT', 'DEBIT'])
            ->whereNotIn(DB::raw("UPPER(COALESCE(tx.payment_type, ''))"), ['REFUND', 'VOID_TRANS', 'REFUND_CARD'])
            ->where('tx.amount', '>', 0)
            ->selectRaw('SUM(tx.amount) as canon_neto, COUNT(DISTINCT t.id) as canon_tickets')
            ->first();

        $menuItemsTotals = (clone $baseTicketQuery)
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereNotNull('ti.item_name')
            ->selectRaw('SUM(ti.total_price) as items_neto, SUM(CASE WHEN ti.discount > 0 THEN ti.discount ELSE 0 END) as descuentos_items, COUNT(DISTINCT t.id) as total_tickets')
            ->first();

        $menuItemsExcluding100 = (clone $baseTicketQuery)
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereNotNull('ti.item_name')
            ->where('t.total_price', '>', 0)
            ->selectRaw('SUM(ti.total_price) as items_neto_excluding_100, SUM(CASE WHEN ti.discount > 0 THEN ti.discount ELSE 0 END) as descuentos_excluding_100, COUNT(DISTINCT t.id) as tickets_excluding_100')
            ->first();

        $totalModificadores = (clone $baseTicketQuery)
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->join('public.ticket_item_modifier AS tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->sum(DB::raw('COALESCE(tim.total_price, 0)'));

        return [
            'canon_neto' => (float) ($canonTotals->canon_neto ?? 0),
            'canon_tickets' => (int) ($canonTotals->canon_tickets ?? 0),
            'items_neto' => (float) ($menuItemsTotals->items_neto ?? 0),
            'descuentos_items' => (float) ($menuItemsTotals->descuentos_items ?? 0),
            'total_tickets' => (int) ($menuItemsTotals->total_tickets ?? 0),
            'items_neto_excluding_100' => (float) ($menuItemsExcluding100->items_neto_excluding_100 ?? 0),
            'descuentos_excluding_100' => (float) ($menuItemsExcluding100->descuentos_excluding_100 ?? 0),
            'tickets_excluding_100' => (int) ($menuItemsExcluding100->tickets_excluding_100 ?? 0),
            'modificadores_total' => (float) $totalModificadores,
        ];
    }

    /**
     * Datos de comparación mes a mes (ticket + ticket_item agregados por mes).
     */
    public function getMonthComparisonData(Carbon $start, Carbon $end): Collection
    {
        return DB::connection($this->connection)
            ->table('public.ticket AS t')
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.folio_date', [$start->format('Y-m-d 00:00:00'), $end->format('Y-m-d 23:59:59')])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->whereNotNull('ti.item_name')
            ->where('ti.item_count', '>', 0)
            ->selectRaw("DATE_TRUNC('month', t.folio_date) AS mes, EXTRACT(YEAR FROM t.folio_date) AS anio, SUM(ti.item_count) AS unidades, SUM(ti.total_price) AS ingresos")
            ->groupBy('mes', 'anio')
            ->orderBy('anio', 'desc')
            ->orderBy('mes', 'asc')
            ->get();
    }

    // -----------------------------------------------------------------------
    // MenuEngineeringService queries
    // -----------------------------------------------------------------------

    /**
     * Unidades vendidas por menu_item_id en un rango de fechas.
     * Reemplaza salesMetricsSubquery() — devuelve Collection keyed by menu_item_id.
     */
    public function getSalesUnitsByMenuItemInRange(
        \Carbon\CarbonImmutable $start,
        \Carbon\CarbonImmutable $end
    ): Collection {
        return DB::connection($this->connection)
            ->table('public.ticket_item as ti')
            ->selectRaw('mi.id as menu_item_id, SUM(ti.item_quantity) as units')
            ->join('selemti.menu_item_sync_map as map', 'map.pos_identifier', '=', 'ti.item_id')
            ->join('selemti.menu_items as mi', 'mi.id', '=', 'map.menu_item_id')
            ->join('public.ticket as t', 't.id', '=', 'ti.ticket_id')
            ->whereBetween('t.paid_time', [$start->startOfDay(), $end->endOfDay()])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->groupBy('mi.id')
            ->get()
            ->keyBy('menu_item_id');
    }

    // -----------------------------------------------------------------------
    // Private helpers
    // -----------------------------------------------------------------------

    private function buildTicketItemBaseQuery(
        Carbon $start,
        Carbon $end,
        ?array $branchIds,
        ?array $terminalIds
    ) {
        $query = DB::connection($this->connection)
            ->table('public.ticket AS t')
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.folio_date', [$start->format('Y-m-d 00:00:00'), $end->format('Y-m-d 23:59:59')])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->whereNotNull('ti.item_name')
            ->where('ti.item_count', '>', 0);

        if ($branchIds) {
            $query->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds) {
            $query->whereIn('t.terminal_id', $terminalIds);
        }

        return $query;
    }
}
