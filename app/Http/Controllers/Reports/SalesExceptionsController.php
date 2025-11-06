<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Illuminate\Http\Response;

class SalesExceptionsController extends BaseReportController
{
    /**
     * Catálogo de categorías de excepción y metadatos para UI/exports.
     */
    protected array $categoryCatalog = [
        'discount_100' => [
            'code' => 'DISCOUNT_100_PERCENT',
            'label' => 'Descuentos 100%',
            'description' => 'Tickets con descuento total (>= 99%) y sin cobro asociado.',
            'severity' => 'critical',
            'impact_label' => 'Monto descontado',
            'icon' => 'fa-gift',
            'badge_class' => 'bg-danger-subtle text-danger',
        ],
        'discount_high' => [
            'code' => 'DISCOUNT_OVER_THRESHOLD',
            'label' => 'Descuentos elevados',
            'description' => 'Tickets con descuentos mayores a $100 o superiores al 20% del total.',
            'severity' => 'warning',
            'impact_label' => 'Descuento aplicado',
            'icon' => 'fa-percent',
            'badge_class' => 'bg-warning-subtle text-warning',
        ],
        'unpaid_closed' => [
            'code' => 'PAID_WITHOUT_TX',
            'label' => 'Cerrados sin pago',
            'description' => 'Tickets con neto > 0 cerrados sin movimientos de pago.',
            'severity' => 'critical',
            'impact_label' => 'Monto pendiente',
            'icon' => 'fa-circle-minus',
            'badge_class' => 'bg-danger-subtle text-danger',
        ],
        'voided_with_payments' => [
            'code' => 'VOIDED_WITH_PAYMENTS',
            'label' => 'Anulados con cobros',
            'description' => 'Tickets anulados que conservan cobros, reembolsos o movimientos de anulación.',
            'severity' => 'critical',
            'impact_label' => 'Movimientos asociados',
            'icon' => 'fa-ban',
            'badge_class' => 'bg-danger-subtle text-danger',
        ],
        'payment_mismatch' => [
            'code' => 'PAYMENT_VS_NET_MISMATCH',
            'label' => 'Pagos vs Neto',
            'description' => 'Diferencia relevante entre el neto del ticket y los pagos registrados.',
            'severity' => 'warning',
            'impact_label' => 'Diferencia detectada',
            'icon' => 'fa-scale-unbalanced',
            'badge_class' => 'bg-warning-subtle text-warning',
        ],
    ];

    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $dataset = $this->fetch($start, $end, $branches, $terminals);
        $records = $dataset['records'];

        $summary = $dataset['summary'];
        $discountSummary = $dataset['discounts']['summary'] ?? collect();

        $observedBranches = $records
            ->pluck('branch_key')
            ->filter()
            ->all();

        [$branchColors] = $this->buildBranchContext($observedBranches, $branches);

        $categories = $dataset['categories']->map(function (array $category) {
            $rows = $category['rows'] instanceof Collection
                ? $category['rows']->map(fn (array $row) => $this->prepareRecordForOutput($row))->values()->all()
                : [];

            return array_merge($category, [
                'rows' => $rows,
            ]);
        })->values();

        $recordsPayload = $records
            ->map(fn (array $row) => $this->prepareRecordForOutput($row))
            ->values()
            ->all();

        return response()->json([
            'success' => true,
            'range' => ['start' => $start->toDateString(), 'end' => $end->toDateString()],
            'branch' => $this->stringifyFilter($branches),
            'terminal' => $this->stringifyFilter($terminals),
            'filters' => [
                'branches' => $branches,
                'terminals' => $terminals,
            ],
            'branch_colors' => $branchColors,
            'summary' => $summary,
            'categories' => $categories,
            'records' => $recordsPayload,
            'discounts_summary' => $discountSummary instanceof Collection ? $discountSummary->values()->all() : $discountSummary,
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $dataset = $this->fetch($start, $end, $branches, $terminals);
        $records = $dataset['records'];

        $observedBranches = $records
            ->pluck('branch_key')
            ->filter()
            ->all();

        [$branchColors, $branchOptions, $branchLabels] = $this->buildBranchContext($observedBranches, $branches);
        $terminalOptions = $this->loadTerminalOptions($branchColors, $branchLabels, $terminals, $branches);

        return view('reports.sales.exceptions', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $branches,
            'terminalFilter' => $terminals,
            'branchOptions' => $branchOptions,
            'terminalOptions' => $terminalOptions,
            'branchColors' => $branchColors,
            'branchLabels' => $branchLabels,
            'records' => $records,
            'categories' => $dataset['categories'],
            'summary' => $dataset['summary'],
            'discountSummary' => $dataset['discounts']['summary'] ?? collect(),
            'categoryCatalog' => $this->categoryCatalog,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $dataset = $this->fetch($start, $end, $branches, $terminals);

        $filename = sprintf(
            'reporte_excepciones_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            !empty($branches)
                ? '_' . str_replace(' ', '_', strtolower($this->stringifyFilter($branches)))
            : ''
        );

        return $this->renderPdf('reports.exports.sales.exceptions', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $this->stringifyFilter($branches),
            'terminal' => $this->stringifyFilter($terminals),
            'categories' => $dataset['categories'],
            'summary' => $dataset['summary'],
            'discountSummary' => $dataset['discounts']['summary'] ?? collect(),
            'generatedAt' => now('America/Mexico_City'),
        ], $filename);
    }

    protected function resolveFilters(Request $request): array
    {
        $startInput = $request->input('start') ?? $request->input('start_date');
        $endInput = $request->input('end') ?? $request->input('end_date');

        $start = $startInput
            ? Carbon::parse($startInput, 'America/Mexico_City')
            : now('America/Mexico_City')->startOfDay();
        $end = $endInput
            ? Carbon::parse($endInput, 'America/Mexico_City')
            : $start->copy();

        if ($end->lt($start)) {
            [$start, $end] = [$end, $start];
        }

        $start = $start->startOfDay();
        $end = $end->startOfDay();

        $branches = $this->normalizeFilterList($request->input('branch'), uppercase: true);
        $terminals = $this->normalizeFilterList($request->input('terminal'), uppercase: false);

        return [$start, $end, $branches, $terminals];
    }

    protected function fetch(Carbon $start, Carbon $end, array $branches, array $terminals): array
    {
        $branchList = $this->stringifyFilter($branches);
        $terminalList = $this->stringifyFilter($terminals);

        $bindings = [
            $start->toDateString(),
            $end->toDateString(),
        ];

        $sql = <<<SQL
WITH raw AS (
    SELECT
        t.id AS ticket_id,
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
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
        (
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
            )
        )::numeric(14,2) AS discount_total
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) BETWEEN ? AND ?
SQL;

        if ($branchList) {
            $sql .= " AND UPPER(COALESCE(t.branch_key, '')) IN (SELECT UNNEST(string_to_array(?, ',')))";
            $bindings[] = $branchList;
        }

        if ($terminalList) {
            $sql .= " AND CAST(t.terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ',')))";
            $bindings[] = $terminalList;
        }

        $sql .= "\n), base AS (\n"
            . "    SELECT raw.*,\n"
            . "        COALESCE(raw.net_total_raw, (raw.gross_total - raw.discount_total)::numeric(14,2)) AS net_total\n"
            . "    FROM raw\n"
            . ")\n"
            . ", payments AS (\n"
            . "    SELECT\n"
            . "        tx.ticket_id,\n"
            . "        SUM(CASE\n"
            . "            WHEN COALESCE(tx.voided, FALSE) = FALSE\n"
            . "             AND UPPER(COALESCE(tx.transaction_type, '')) IN ('CREDIT','DEBIT')\n"
            . "             AND UPPER(COALESCE(tx.payment_type, '')) NOT IN ('REFUND','VOID_TRANS','REFUND_CARD')\n"
            . "             AND COALESCE(tx.amount, 0) > 0\n"
            . "            THEN COALESCE(tx.amount, 0)\n"
            . "            ELSE 0\n"
            . "        END)::numeric(14,2) AS payment_total,\n"
            . "        SUM(CASE\n"
            . "            WHEN COALESCE(tx.voided, FALSE) = FALSE\n"
            . "             AND UPPER(COALESCE(tx.transaction_type, '')) IN ('CREDIT','DEBIT')\n"
            . "             AND UPPER(COALESCE(tx.payment_type, '')) NOT IN ('REFUND','VOID_TRANS','REFUND_CARD')\n"
            . "             AND COALESCE(tx.amount, 0) < 0\n"
            . "            THEN COALESCE(tx.amount, 0)\n"
            . "            ELSE 0\n"
            . "        END)::numeric(14,2) AS payment_adjustment_total,\n"
            . "        SUM(CASE\n"
            . "            WHEN COALESCE(tx.voided, FALSE) = FALSE\n"
            . "             AND UPPER(COALESCE(tx.payment_type, '')) IN ('REFUND','REFUND_CARD')\n"
            . "            THEN COALESCE(tx.amount, 0)\n"
            . "            ELSE 0\n"
            . "        END)::numeric(14,2) AS refund_total,\n"
            . "        SUM(CASE\n"
            . "            WHEN COALESCE(tx.voided, FALSE) = FALSE\n"
            . "             AND UPPER(COALESCE(tx.payment_type, '')) = 'VOID_TRANS'\n"
            . "            THEN COALESCE(tx.amount, 0)\n"
            . "            ELSE 0\n"
            . "        END)::numeric(14,2) AS void_total,\n"
            . "        SUM(CASE\n"
            . "            WHEN COALESCE(tx.voided, FALSE) = FALSE\n"
            . "            THEN COALESCE(tx.amount, 0)\n"
            . "            ELSE 0\n"
            . "        END)::numeric(14,2) AS recorded_total,\n"
            . "        SUM(CASE WHEN COALESCE(tx.voided, FALSE) = FALSE THEN 1 ELSE 0 END) AS tx_count,\n"
            . "        SUM(CASE\n"
            . "            WHEN COALESCE(tx.voided, FALSE) = FALSE\n"
            . "             AND UPPER(COALESCE(tx.transaction_type, '')) IN ('CREDIT','DEBIT')\n"
            . "             AND UPPER(COALESCE(tx.payment_type, '')) NOT IN ('REFUND','VOID_TRANS','REFUND_CARD')\n"
            . "             AND COALESCE(tx.amount, 0) > 0\n"
            . "            THEN 1\n"
            . "            ELSE 0\n"
            . "        END) AS payment_positive_count,\n"
            . "        SUM(CASE\n"
            . "            WHEN COALESCE(tx.voided, FALSE) = FALSE\n"
            . "             AND UPPER(COALESCE(tx.transaction_type, '')) IN ('CREDIT','DEBIT')\n"
            . "             AND UPPER(COALESCE(tx.payment_type, '')) NOT IN ('REFUND','VOID_TRANS','REFUND_CARD')\n"
            . "             AND COALESCE(tx.amount, 0) < 0\n"
            . "            THEN 1\n"
            . "            ELSE 0\n"
            . "        END) AS payment_adjustment_count,\n"
            . "        jsonb_agg(\n"
            . "            jsonb_build_object(\n"
            . "                'payment_type', COALESCE(tx.payment_type, ''),\n"
            . "                'transaction_type', COALESCE(tx.transaction_type, ''),\n"
            . "                'amount', ROUND(COALESCE(tx.amount, 0)::numeric, 2),\n"
            . "                'voided', COALESCE(tx.voided, FALSE)\n"
            . "            ) ORDER BY tx.id\n"
            . "        ) AS tx_detail\n"
            . "    FROM public.transactions tx\n"
            . "    JOIN base b ON b.ticket_id = tx.ticket_id\n"
            . "    GROUP BY tx.ticket_id\n"
            . ")\n"
            . "SELECT\n"
            . "    b.ticket_id,\n"
            . "    b.folio_date,\n"
            . "    b.branch_key,\n"
            . "    b.terminal_id,\n"
            . "    b.paid_flag,\n"
            . "    b.voided_flag,\n"
            . "    b.settled_flag,\n"
            . "    b.wasted_flag,\n"
            . "    b.refunded_flag,\n"
            . "    b.reopened_flag,\n"
            . "    b.ticket_status,\n"
            . "    b.ticket_type,\n"
            . "    b.daily_folio,\n"
            . "    b.gross_total,\n"
            . "    b.sub_total,\n"
            . "    b.total_tax,\n"
            . "    b.service_charge,\n"
            . "    b.delivery_charge,\n"
            . "    b.paid_amount_flag,\n"
            . "    b.discount_total,\n"
            . "    b.net_total,\n"
            . "    COALESCE(p.payment_total, 0)::numeric(14,2) AS payment_total,\n"
            . "    COALESCE(p.payment_adjustment_total, 0)::numeric(14,2) AS payment_adjustment_total,\n"
            . "    COALESCE(p.refund_total, 0)::numeric(14,2) AS refund_total,\n"
            . "    COALESCE(p.void_total, 0)::numeric(14,2) AS void_total,\n"
            . "    COALESCE(p.recorded_total, 0)::numeric(14,2) AS recorded_total,\n"
            . "    COALESCE(p.tx_count, 0) AS tx_count,\n"
            . "    COALESCE(p.payment_positive_count, 0) AS payment_positive_count,\n"
            . "    COALESCE(p.payment_adjustment_count, 0) AS payment_adjustment_count,\n"
            . "    p.tx_detail\n"
            . "FROM base b\n"
            . "LEFT JOIN payments p ON p.ticket_id = b.ticket_id\n"
            . "ORDER BY b.folio_date, b.ticket_id";

        $rows = DB::connection('pgsql')->select($sql, $bindings);

        $tickets = collect($rows)->map(function ($row) {
            $transactions = [];
            if (isset($row->tx_detail) && $row->tx_detail !== null) {
                $decoded = json_decode($row->tx_detail, true);
                if (is_array($decoded)) {
                    $transactions = array_map(function ($tx) {
                        return [
                            'payment_type' => strtoupper(trim((string) ($tx['payment_type'] ?? ''))),
                            'transaction_type' => strtoupper(trim((string) ($tx['transaction_type'] ?? ''))),
                            'amount' => (float) ($tx['amount'] ?? 0.0),
                            'voided' => (bool) ($tx['voided'] ?? false),
                        ];
                    }, $decoded);
                }
            }

            return [
                'ticket_id' => (int) ($row->ticket_id ?? 0),
                'folio_date' => $row->folio_date ? Carbon::parse($row->folio_date, 'America/Mexico_City')->format('Y-m-d') : null,
                'branch_key' => strtoupper(trim((string) ($row->branch_key ?? ''))),
                'terminal_id' => $row->terminal_id !== null ? (string) $row->terminal_id : null,
                'paid_flag' => (bool) ($row->paid_flag ?? false),
                'voided_flag' => (bool) ($row->voided_flag ?? false),
                'settled_flag' => (bool) ($row->settled_flag ?? false),
                'wasted_flag' => (bool) ($row->wasted_flag ?? false),
                'refunded_flag' => (bool) ($row->refunded_flag ?? false),
                'reopened_flag' => (bool) ($row->reopened_flag ?? false),
                'ticket_status' => trim((string) ($row->ticket_status ?? '')),
                'ticket_type' => trim((string) ($row->ticket_type ?? '')),
                'daily_folio' => $row->daily_folio !== null ? (int) $row->daily_folio : null,
                'gross_total' => (float) ($row->gross_total ?? 0),
                'sub_total' => (float) ($row->sub_total ?? 0),
                'total_tax' => (float) ($row->total_tax ?? 0),
                'service_charge' => (float) ($row->service_charge ?? 0),
                'delivery_charge' => (float) ($row->delivery_charge ?? 0),
                'paid_amount_flag' => (float) ($row->paid_amount_flag ?? 0),
                'discount_total' => (float) ($row->discount_total ?? 0),
                'net_total' => (float) ($row->net_total ?? 0),
                'payment_total' => (float) ($row->payment_total ?? 0),
                'payment_adjustment_total' => (float) ($row->payment_adjustment_total ?? 0),
                'effective_payment_total' => (float) ($row->payment_total ?? 0) + (float) ($row->payment_adjustment_total ?? 0),
                'refund_total' => (float) ($row->refund_total ?? 0),
                'void_total' => (float) ($row->void_total ?? 0),
                'recorded_total' => (float) ($row->recorded_total ?? 0),
                'tx_count' => (int) ($row->tx_count ?? 0),
                'payment_positive_count' => (int) ($row->payment_positive_count ?? 0),
                'payment_adjustment_count' => (int) ($row->payment_adjustment_count ?? 0),
                'transactions' => $transactions,
                'items' => [],
            ];
        });

        $ticketIds = $tickets
            ->pluck('ticket_id')
            ->filter(fn ($id) => is_int($id) && $id > 0)
            ->unique()
            ->values();

        $discountRows = collect();
        $discountsByTicket = collect();
        $discountSummary = collect();
        $itemsByTicket = collect();

        if ($ticketIds->isNotEmpty()) {
            $idList = $ticketIds->implode(',');

            if ($idList !== '') {
                $ticketDiscountSql = "
                    SELECT
                        td.ticket_id,
                        COALESCE(NULLIF(td.name, ''), cad.name, 'SIN NOMBRE') AS discount_name,
                        td.type AS discount_type,
                        COALESCE(td.value, 0)::numeric(14,2) AS discount_amount,
                        'ticket'::text AS scope
                    FROM public.ticket_discount td
                    LEFT JOIN public.coupon_and_discount cad ON cad.id = td.discount_id
                    WHERE td.ticket_id IN (SELECT UNNEST(string_to_array(?, ','))::integer)
                ";

                try {
                    $ticketDiscountRows = DB::connection('pgsql')->select($ticketDiscountSql, [$idList]);
                    $discountRows = $discountRows->merge($ticketDiscountRows);
                } catch (\Throwable $e) {
                    // Si la tabla no está disponible en el entorno actual, continuar sin frenar el reporte.
                }

                $itemDiscountSql = "
                    SELECT
                        ti.ticket_id,
                        COALESCE(NULLIF(tid.name, ''), cad.name, 'SIN NOMBRE') AS discount_name,
                        tid.type AS discount_type,
                        COALESCE(tid.amount, tid.value, 0)::numeric(14,2) AS discount_amount,
                        'item'::text AS scope
                    FROM public.ticket_item ti
                    JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
                    LEFT JOIN public.coupon_and_discount cad ON cad.id = tid.discount_id
                    WHERE ti.ticket_id IN (SELECT UNNEST(string_to_array(?, ','))::integer)
                ";

                try {
                    $itemDiscountRows = DB::connection('pgsql')->select($itemDiscountSql, [$idList]);
                    $discountRows = $discountRows->merge($itemDiscountRows);
                } catch (\Throwable $e) {
                    // ticket_item_discount no existe en algunas versiones; continuar sin datos a nivel item.
                }

                $itemSql = "
                    SELECT
                        ti.ticket_id,
                        COALESCE(NULLIF(ti.item_name, ''), 'SIN NOMBRE') AS item_name,
                        COALESCE(NULLIF(ti.group_name, ''), NULLIF(ti.category_name, ''), '') AS item_group,
                        COALESCE(ti.item_quantity, ti.item_count, 1)::numeric(14,2) AS quantity,
                        COALESCE(ti.item_price, ti.sub_total, 0)::numeric(14,2) AS unit_price,
                        COALESCE(ti.sub_total, 0)::numeric(14,2) AS sub_total_amount,
                        COALESCE(ti.discount, 0)::numeric(14,2) AS discount_amount,
                        COALESCE(ti.total_price, ti.sub_total - COALESCE(ti.discount, 0), 0)::numeric(14,2) AS total_amount,
                        ti.id
                    FROM public.ticket_item ti
                    WHERE ti.ticket_id IN (SELECT UNNEST(string_to_array(?, ','))::integer)
                    ORDER BY ti.ticket_id, ti.id
                ";

                try {
                    $itemRows = DB::connection('pgsql')->select($itemSql, [$idList]);
                    $itemsByTicket = collect($itemRows)
                        ->groupBy(fn ($row) => (int) ($row->ticket_id ?? 0))
                        ->map(function (Collection $items) {
                            return $items
                                ->map(function ($row) {
                                    $quantity = (float) ($row->quantity ?? 0);
                                    $unitPrice = (float) ($row->unit_price ?? 0);
                                    $subTotal = (float) ($row->sub_total_amount ?? ($quantity * $unitPrice));
                                    $discount = (float) ($row->discount_amount ?? 0);
                                    $total = (float) ($row->total_amount ?? ($subTotal - $discount));

                                    return [
                                        'name' => trim((string) ($row->item_name ?? 'SIN NOMBRE')),
                                        'group' => trim((string) ($row->item_group ?? '')),
                                        'quantity' => $quantity,
                                        'unit_price' => $unitPrice,
                                        'sub_total' => $subTotal,
                                        'discount_amount' => $discount,
                                        'total_amount' => $total,
                                    ];
                                })
                                ->values();
                        });
                } catch (\Throwable $e) {
                    // ticket_item puede faltar; continuar sin detalle de items.
                }
            }
        }

        $discountRows = $discountRows
            ->map(function ($row) {
                $name = trim((string) ($row->discount_name ?? ''));
                if ($name === '') {
                    $name = 'SIN NOMBRE';
                }

                return [
                    'ticket_id' => (int) ($row->ticket_id ?? 0),
                    'name' => $name,
                    'scope' => (string) ($row->scope ?? 'ticket'),
                    'type' => $row->discount_type !== null ? (int) $row->discount_type : null,
                    'amount' => (float) ($row->discount_amount ?? 0),
                ];
            })
            ->filter(fn (array $row) => $row['ticket_id'] > 0);

        if ($discountRows->isNotEmpty()) {
            $discountsByTicket = $discountRows
                ->groupBy('ticket_id')
                ->map(function (Collection $items) {
                    return $items
                        ->groupBy(fn (array $row) => $row['name'] . '|' . ($row['scope'] ?? 'ticket'))
                        ->map(function (Collection $group) {
                            $first = $group->first();

                            return [
                                'name' => $first['name'],
                                'scope' => $first['scope'],
                                'type' => $first['type'],
                                'applications' => $group->count(),
                                'amount' => round($group->sum('amount'), 2),
                            ];
                        })
                        ->values();
                });

            $discountSummary = $discountRows
                ->groupBy('name')
                ->map(function (Collection $items, string $name) {
                    $tickets = $items->pluck('ticket_id')->unique()->count();
                    $total = round($items->sum('amount'), 2);
                    $scopeTicket = $items->where('scope', 'ticket')->count();
                    $scopeItem = $items->where('scope', 'item')->count();

                    return [
                        'name' => $name,
                        'type' => $items->first()['type'],
                        'applications' => $items->count(),
                        'tickets' => $tickets,
                        'total_amount' => $total,
                        'average_amount' => $tickets > 0 ? round($total / $tickets, 2) : 0.0,
                        'scopes' => [
                            'ticket' => $scopeTicket,
                            'item' => $scopeItem,
                        ],
                    ];
                })
                ->sortByDesc('total_amount')
                ->values();
        }

        if ($itemsByTicket->isNotEmpty()) {
            $tickets = $tickets->map(function (array $ticket) use ($itemsByTicket) {
                $ticket['items'] = $itemsByTicket->get($ticket['ticket_id'], collect())->toArray();
                return $ticket;
            });
        }

        $records = collect();

        $tickets->each(function (array $ticket) use (&$records, $discountsByTicket) {
            $gross = $ticket['gross_total'];
            $discount = $ticket['discount_total'];
            $net = $ticket['net_total'];
            $payments = $ticket['payment_total'];
            $paymentAdjustments = $ticket['payment_adjustment_total'];
            $effectivePayments = $ticket['payment_total'] + $ticket['payment_adjustment_total'];
            $refunds = $ticket['refund_total'];
            $voidTotal = $ticket['void_total'];
            $recorded = $ticket['recorded_total'];

            $discountRatio = $gross > 0 ? $discount / max($gross, 0.0001) : 0.0;
            $difference = $net - $effectivePayments;
            $notes = [];

            $ticketDiscounts = $discountsByTicket->get($ticket['ticket_id'], collect());
            if (!$ticketDiscounts instanceof Collection) {
                $ticketDiscounts = collect($ticketDiscounts);
            }

            $discountLines = $ticketDiscounts
                ->map(fn (array $row) => [
                    'name' => $row['name'],
                    'scope' => $row['scope'],
                    'type' => $row['type'],
                    'applications' => $row['applications'],
                    'amount' => $row['amount'],
                ])
                ->values()
                ->all();

            $discountNames = $ticketDiscounts
                ->pluck('name')
                ->unique()
                ->filter()
                ->implode(', ');

            // Descuento 100%
            if ($gross > 0 && $discountRatio >= 0.99 && abs($effectivePayments) <= 0.01) {
                $notes[] = sprintf(
                    'Descuento aplicado: %s (%.1f%%)',
                    $this->formatMoney($discount),
                    $discountRatio * 100
                );

                if (!$ticket['paid_flag']) {
                    $notes[] = 'Ticket marcado como pagado: No';
                }

                if ($discountNames !== '') {
                    $notes[] = 'Descuentos: ' . $discountNames;
                }

                $records->push($this->buildRecord($ticket, 'discount_100', [
                    'impact' => $discount,
                    'difference' => $difference,
                    'discounts' => $discountLines,
                    'notes' => $notes,
                ]));
            } elseif ($gross > 0 && ($discount >= 100 || $discountRatio >= 0.20)) {
                $notes[] = sprintf(
                    'Descuento aplicado: %s (%.1f%%)',
                    $this->formatMoney($discount),
                    $discountRatio * 100
                );

                if ($discountNames !== '') {
                    $notes[] = 'Descuentos: ' . $discountNames;
                }

                $records->push($this->buildRecord($ticket, 'discount_high', [
                    'impact' => $discount,
                    'difference' => $difference,
                    'discounts' => $discountLines,
                    'notes' => $notes,
                ]));
            }

            // Cerrados sin pago
            if (!$ticket['voided_flag'] && $net > 0.01 && abs($effectivePayments) <= 0.01) {
                $notes = [
                    sprintf('Importe neto: %s', $this->formatMoney($net)),
                    'Pagos registrados: $0.00',
                ];

                if ($ticket['paid_flag']) {
                    $notes[] = 'El ticket está marcado como pagado en POS.';
                }

                if ($discountNames !== '') {
                    $notes[] = 'Descuentos: ' . $discountNames;
                }
                if ($paymentAdjustments < -0.01) {
                    $notes[] = sprintf('Ajustes fuera de pago: %s', $this->formatMoney($paymentAdjustments));
                }

                $records->push($this->buildRecord($ticket, 'unpaid_closed', [
                    'impact' => $net,
                    'difference' => $difference,
                    'discounts' => $discountLines,
                    'notes' => $notes,
                ]));
            }

            // Anulados con pagos
            if ($ticket['voided_flag'] && (abs($effectivePayments) > 0.01 || $refunds > 0.01 || $voidTotal > 0.01)) {
                $notes = [];

                if ($effectivePayments > 0.01) {
                    $notes[] = sprintf('Cobros netos: %s', $this->formatMoney($effectivePayments));
                } elseif ($payments > 0.01) {
                    $notes[] = sprintf('Cobros: %s', $this->formatMoney($payments));
                }
                if ($refunds > 0.01) {
                    $notes[] = sprintf('Reembolsos: %s', $this->formatMoney($refunds));
                }
                if ($voidTotal > 0.01) {
                    $notes[] = sprintf('Movimientos VOID_TRANS: %s', $this->formatMoney($voidTotal));
                }
                if ($paymentAdjustments < -0.01) {
                    $notes[] = sprintf('Ajustes fuera de pago: %s', $this->formatMoney($paymentAdjustments));
                }
                $notes[] = sprintf('Movimientos activos: %d', $ticket['tx_count']);

                if ($discountNames !== '') {
                    $notes[] = 'Descuentos: ' . $discountNames;
                }

                $voidImpact = max($effectivePayments - $refunds, 0);

                $records->push($this->buildRecord($ticket, 'voided_with_payments', [
                    'impact' => $voidImpact,
                    'difference' => $difference,
                    'notes' => $notes,
                    'discounts' => $discountLines,
                ]));
            }

            // Diferencia entre pagos y neto (solo aplica si hubo pagos)
            if (
                !$ticket['voided_flag']
                && $net > 0.01
                && $effectivePayments > 0.01
                && abs($difference) > 0.5
            ) {
                $notes = [
                    sprintf('Importe neto: %s', $this->formatMoney($net)),
                    sprintf('Cobros netos: %s', $this->formatMoney($effectivePayments)),
                    sprintf('Diferencia: %s', $this->formatMoney(abs($difference))),
                ];
                if ($paymentAdjustments < -0.01) {
                    $notes[] = sprintf('Ajustes fuera de pago: %s', $this->formatMoney($paymentAdjustments));
                }

                if ($discountNames !== '') {
                    $notes[] = 'Descuentos: ' . $discountNames;
                }

                $records->push($this->buildRecord($ticket, 'payment_mismatch', [
                    'impact' => abs($difference),
                    'difference' => $difference,
                    'discounts' => $discountLines,
                    'notes' => $notes,
                ]));
            }
        });

        $categories = collect($this->categoryCatalog)->map(function (array $meta, string $key) use ($records) {
            $rows = $records->where('category', $key)->values();

            return array_merge($meta, [
                'key' => $key,
                'rows' => $rows,
                'count' => $rows->count(),
                'tickets' => $rows->pluck('ticket_id')->unique()->count(),
                'impact' => round($rows->sum('impact'), 2),
            ]);
        })->filter(fn (array $category) => $category['count'] > 0);

        $summary = [
            'total_records' => $records->count(),
            'total_tickets' => $records->pluck('ticket_id')->unique()->count(),
            'impact_sum' => round($records->sum('impact'), 2),
            'by_category' => $categories
                ->map(fn (array $category) => [
                    'key' => $category['key'],
                    'label' => $category['label'],
                    'count' => $category['count'],
                    'tickets' => $category['tickets'],
                    'impact' => $category['impact'],
                ])
                ->values()
                ->all(),
        ];

        return [
            'tickets' => $tickets,
            'records' => $records,
            'categories' => $categories,
            'summary' => $summary,
            'discounts' => [
                'by_ticket' => $discountsByTicket,
                'summary' => $discountSummary,
            ],
        ];
    }

    protected function buildRecord(array $ticket, string $category, array $overrides = []): array
    {
        $meta = $this->categoryCatalog[$category] ?? ['code' => strtoupper($category)];

        $record = [
            'category' => $category,
            'error_code' => $meta['code'] ?? strtoupper($category),
            'ticket_id' => $ticket['ticket_id'],
            'ticket_number' => $ticket['ticket_number'] ?? null,
            'folio_date' => $ticket['folio_date'],
            'branch_key' => $ticket['branch_key'],
            'terminal_id' => $ticket['terminal_id'],
            'gross_total' => $ticket['gross_total'],
            'discount_total' => $ticket['discount_total'],
            'net_total' => $ticket['net_total'],
            'payment_total' => $ticket['payment_total'],
            'payment_adjustment_total' => $ticket['payment_adjustment_total'],
            'effective_payment_total' => $ticket['effective_payment_total'],
            'refund_total' => $ticket['refund_total'],
            'void_total' => $ticket['void_total'],
            'recorded_total' => $ticket['recorded_total'],
            'payment_positive_count' => $ticket['payment_positive_count'],
            'payment_adjustment_count' => $ticket['payment_adjustment_count'],
            'paid_flag' => $ticket['paid_flag'],
            'voided_flag' => $ticket['voided_flag'],
            'settled_flag' => $ticket['settled_flag'],
            'refunded_flag' => $ticket['refunded_flag'],
            'reopened_flag' => $ticket['reopened_flag'],
            'tx_count' => $ticket['tx_count'],
            'transactions' => $ticket['transactions'],
            'items' => $ticket['items'],
            'impact' => 0.0,
            'impact_label' => $meta['impact_label'] ?? 'Impacto',
            'difference' => $ticket['net_total'] - $ticket['effective_payment_total'],
            'notes' => [],
            'discounts' => [],
        ];

        return array_merge($record, $overrides);
    }

    protected function prepareRecordForOutput(array $record): array
    {
        return array_merge($record, [
            'notes' => array_values($record['notes'] ?? []),
            'discounts' => array_map(function (array $discount) {
                return [
                    'name' => $discount['name'] ?? '',
                    'scope' => $discount['scope'] ?? 'ticket',
                    'type' => $discount['type'] ?? null,
                    'applications' => (int) ($discount['applications'] ?? 0),
                    'amount' => (float) ($discount['amount'] ?? 0),
                ];
            }, $record['discounts'] ?? []),
            'items' => array_map(function (array $item) {
                return [
                    'name' => $item['name'] ?? 'SIN NOMBRE',
                    'group' => $item['group'] ?? '',
                    'quantity' => (float) ($item['quantity'] ?? 0),
                    'unit_price' => (float) ($item['unit_price'] ?? 0),
                    'sub_total' => (float) ($item['sub_total'] ?? 0),
                    'discount_amount' => (float) ($item['discount_amount'] ?? 0),
                    'total_amount' => (float) ($item['total_amount'] ?? 0),
                ];
            }, $record['items'] ?? []),
            'transactions' => array_map(function (array $tx) {
                $paymentType = strtoupper($tx['payment_type'] ?? '');
                $transactionType = strtoupper($tx['transaction_type'] ?? '');
                $amount = (float) ($tx['amount'] ?? 0.0);
                $voided = (bool) ($tx['voided'] ?? false);
                $isRefund = in_array($paymentType, ['REFUND', 'REFUND_CARD'], true);
                $isVoidTrans = $paymentType === 'VOID_TRANS';
                $isAdjustment = $amount < 0 && !$isRefund && !$isVoidTrans;

                return [
                    'payment_type' => $paymentType,
                    'transaction_type' => $transactionType,
                    'amount' => $amount,
                    'amount_abs' => abs($amount),
                    'voided' => $voided,
                    'is_refund' => $isRefund,
                    'is_void' => $isVoidTrans || $voided,
                    'is_adjustment' => $isAdjustment,
                    'direction' => $amount < 0 ? 'out' : 'in',
                ];
            }, $record['transactions'] ?? []),
        ]);
    }
}
