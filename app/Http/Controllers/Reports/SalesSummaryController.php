<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class SalesSummaryController extends BaseReportController
{
    /**
     * Paleta utilizada cuando no hay color definido en config/reports.php.
     */
    protected array $fallbackPalette = [
        '#2563eb',
        '#16a34a',
        '#f97316',
        '#0ea5e9',
        '#f43f5e',
        '#8b5cf6',
        '#f59e0b',
        '#22c55e',
        '#7c3aed',
        '#ef4444',
        '#0f172a',
    ];

    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);

        $rows = $this->fetchRows($start, $end, $branches, $terminals);

        $branchColors = $this->prepareBranchColors(
            $rows->pluck('branch_key')->filter()->unique()->values()->all()
        );

        $branchLabels = $this
            ->loadBranchOptions($branchColors, $branches)
            ->keyBy('key')
            ->map(fn (array $opt) => $opt['label'])
            ->toArray();

        $rows = $this->hydrateRows($rows, $branchColors, $branchLabels);
        $totals = $this->summarize($rows);

        return response()->json([
            'success' => true,
            'range' => [
                'start' => $start->toDateString(),
                'end' => $end->toDateString(),
            ],
            'branch' => $this->stringifyFilter($branches),
            'terminal' => $this->stringifyFilter($terminals),
            'filters' => [
                'branches' => $branches,
                'terminals' => $terminals,
            ],
            'totals' => $totals,
            'branch_colors' => $branchColors,
            'data' => $rows->values(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);

        $rows = $this->fetchRows($start, $end, $branches, $terminals);

        $branchColors = $this->prepareBranchColors(
            $rows->pluck('branch_key')->filter()->unique()->values()->all()
        );

        $branchOptions = $this->loadBranchOptions($branchColors, $branches);
        $branchLabels = $branchOptions->keyBy('key')
            ->map(fn (array $opt) => $opt['label'])
            ->toArray();

        $rows = $this->hydrateRows($rows, $branchColors, $branchLabels);
        $totals = $this->summarize($rows);

        $terminalOptions = $this->loadTerminalOptions(
            $branchColors,
            $branchLabels,
            $terminals,
            $branches
        );

        return view('reports.sales.summary', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $branches,
            'terminalFilter' => $terminals,
            'branchOptions' => $branchOptions,
            'terminalOptions' => $terminalOptions,
            'branchColors' => $branchColors,
            'branchLabels' => $branchLabels,
            'rows' => $rows,
            'totals' => $totals,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);

        $rows = $this->fetchRows($start, $end, $branches, $terminals);
        $branchColors = $this->prepareBranchColors(
            $rows->pluck('branch_key')->filter()->unique()->values()->all()
        );
        $branchLabels = $this
            ->loadBranchOptions($branchColors, $branches)
            ->keyBy('key')
            ->map(fn (array $opt) => $opt['label'])
            ->toArray();

        $rows = $this->hydrateRows($rows, $branchColors, $branchLabels);
        $totals = $this->summarize($rows);

        $filename = sprintf(
            'reporte_resumen_ventas_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            $branches ? '_'.str_replace(' ', '_', strtolower($this->stringifyFilter($branches))) : ''
        );

        return $this->renderPdf('reports.exports.sales.summary', [
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $branches,
            'terminalFilter' => $terminals,
            'branchColors' => $branchColors,
            'branchLabels' => $branchLabels,
            'rows' => $rows,
            'totals' => $totals,
            'generatedAt' => now('America/Mexico_City'),
        ], $filename);
    }

    protected function resolveFilters(Request $request): array
    {
        [$start, $end] = $this->parseDateRange($request);

        $branchParam = $request->input('branch', []);
        $branches = is_array($branchParam)
            ? $branchParam
            : explode(',', (string) $branchParam);

        $branches = collect($branches)
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->unique()
            ->values()
            ->all();

        $terminalParam = $request->input('terminal', []);
        $terminals = is_array($terminalParam)
            ? $terminalParam
            : explode(',', (string) $terminalParam);

        $terminals = collect($terminals)
            ->map(fn ($value) => trim((string) $value))
            ->filter()
            ->unique()
            ->values()
            ->all();

        return [$start, $end, $branches, $terminals];
    }

    protected function fetchRows(Carbon $start, Carbon $end, array $branches, array $terminals): Collection
    {
        $sql = <<<'SQL'
            WITH params AS (
                SELECT
                    ?::date AS start_date,
                    ?::date AS end_date,
                    NULLIF(?::text, '') AS branch_raw,
                    NULLIF(?::text, '') AS terminal_raw
            ),
            normalized AS (
                SELECT
                    start_date,
                    end_date,
                    CASE
                        WHEN branch_raw IS NULL THEN NULL
                        ELSE string_to_array(UPPER(branch_raw), ',')
                    END AS branches,
                    CASE
                        WHEN terminal_raw IS NULL THEN NULL
                        ELSE string_to_array(terminal_raw, ',')
                    END AS terminals
                FROM params
            ),
            ticket_scope AS (
                SELECT
                    b.*
                FROM public.vw_ticket_base b
                JOIN normalized n
                  ON b.folio_date BETWEEN n.start_date AND n.end_date
                WHERE (n.branches IS NULL OR UPPER(TRIM(b.branch_key)) = ANY(n.branches))
                  AND (n.terminals IS NULL OR CAST(b.terminal_id AS text) = ANY(n.terminals))
            ),
            valid_summary AS (
                SELECT
                    b.folio_date,
                    UPPER(TRIM(b.branch_key)) AS branch_key,
                    COUNT(DISTINCT b.ticket_id)::bigint AS tickets,
                    SUM(b.total_price)::numeric(14,2) AS bruto,
                    SUM(b.total_discount)::numeric(14,2) AS descuento,
                    SUM(b.tip_amount)::numeric(14,2) AS propina,
                    SUM(b.service_charges)::numeric(14,2) AS cargo_servicio
                FROM ticket_scope b
                GROUP BY 1,2
            ),
            ticket_all AS (
                SELECT
                    t.id,
                    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
                    UPPER(TRIM(t.branch_key)) AS branch_key,
                    t.terminal_id,
                    COALESCE(t.paid, FALSE) AS paid,
                    COALESCE(t.voided, FALSE) AS voided,
                    COALESCE(t.total_price, 0)::numeric(14,2) AS total_price,
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
                                0
                            ),
                            COALESCE(t.total_price, 0)
                        )
                    )::numeric(14,2) AS total_discount
                FROM public.ticket t
                JOIN normalized n
                  ON COALESCE(t.folio_date, t.closing_date::date, t.create_date::date)
                 BETWEEN n.start_date AND n.end_date
                WHERE (n.branches IS NULL OR UPPER(TRIM(t.branch_key)) = ANY(n.branches))
                  AND (n.terminals IS NULL OR CAST(t.terminal_id AS text) = ANY(n.terminals))
            ),
            transactions_scope AS (
                SELECT
                    ta.*,
                    COALESCE(tx.amount, 0)::numeric(14,2) AS amount,
                    UPPER(COALESCE(tx.payment_type, '')) AS payment_type,
                    UPPER(COALESCE(tx.transaction_type, '')) AS transaction_type,
                    COALESCE(tx.voided, FALSE) AS tx_voided
                FROM ticket_all ta
                LEFT JOIN public.transactions tx ON tx.ticket_id = ta.id
            ),
            refunds AS (
                SELECT
                    folio_date,
                    branch_key,
                    SUM(
                        CASE
                            WHEN voided = FALSE
                             AND tx_voided = FALSE
                             AND transaction_type IN ('CREDIT','DEBIT')
                             AND payment_type IN ('REFUND','VOID_TRANS','REFUND_CARD')
                            THEN amount
                            ELSE 0
                        END
                    )::numeric(14,2) AS refund_amount
                FROM transactions_scope
                GROUP BY 1,2
            ),
            voids AS (
                SELECT
                    folio_date,
                    branch_key,
                    SUM(total_price - total_discount)::numeric(14,2) AS void_amount
                FROM (
                    SELECT DISTINCT id, folio_date, branch_key, total_price, total_discount
                    FROM transactions_scope
                    WHERE voided = TRUE
                ) v
                GROUP BY 1,2
            ),
            payments AS (
                SELECT
                    folio_date,
                    branch_key,
                    SUM(
                        CASE
                            WHEN voided = FALSE
                             AND tx_voided = FALSE
                             AND transaction_type IN ('CREDIT','DEBIT')
                             AND payment_type NOT IN ('REFUND','VOID_TRANS','REFUND_CARD')
                            THEN amount
                            ELSE 0
                        END
                    )::numeric(14,2) AS gross_payments
                FROM transactions_scope
                GROUP BY 1,2
            ),
            terminals AS (
                SELECT
                    b.folio_date,
                    UPPER(TRIM(b.branch_key)) AS branch_key,
                    STRING_AGG(
                        DISTINCT CAST(b.terminal_id AS text),
                        ',' ORDER BY CAST(b.terminal_id AS text)
                    ) AS terminales
                FROM ticket_scope b
                GROUP BY 1,2
            ),
            exceptions AS (
                SELECT
                    e.folio_date,
                    UPPER(TRIM(e.branch_key)) AS branch_key,
                    COUNT(*) AS total_exceptions,
                    STRING_AGG(DISTINCT e.error_code, ',') AS exception_codes
                FROM public.vw_report_sales_exceptions e
                JOIN normalized n
                  ON e.folio_date BETWEEN n.start_date AND n.end_date
                WHERE (n.branches IS NULL OR UPPER(e.branch_key) = ANY(n.branches))
                  AND (
                        n.terminals IS NULL
                     OR EXISTS (
                            SELECT 1
                            FROM ticket_scope ts
                            WHERE ts.folio_date = e.folio_date
                              AND UPPER(ts.branch_key) = UPPER(e.branch_key)
                        )
                  )
                GROUP BY 1,2
            ),
            keys AS (
                SELECT folio_date, branch_key FROM valid_summary
                UNION
                SELECT folio_date, branch_key FROM refunds
                UNION
                SELECT folio_date, branch_key FROM voids
            ),
            result_calculation AS (
                SELECT
                    k.folio_date,
                    k.branch_key,
                    COALESCE(vs.tickets, 0)::bigint AS tickets,
                    ROUND(COALESCE(vs.bruto, 0) + COALESCE(vd.void_amount, 0), 2) AS bruto,
                    ROUND(COALESCE(vs.descuento, 0), 2) AS descuento,
                    ROUND(COALESCE(r.refund_amount, 0) + COALESCE(vd.void_amount, 0), 2) AS anulaciones,
                    ROUND(
                        COALESCE(p.gross_payments, 0) - COALESCE(r.refund_amount, 0),
                        2
                    ) AS pagos_netos,
                    ROUND(
                        COALESCE(vs.bruto, 0) + COALESCE(vd.void_amount, 0)
                        - COALESCE(vs.descuento, 0)
                        - (COALESCE(r.refund_amount, 0) + COALESCE(vd.void_amount, 0)),
                        2
                    ) AS neto_legacy,
                    COALESCE(t.terminales, '') AS terminales,
                    COALESCE(ex.total_exceptions, 0)::bigint AS exceptions_count,
                    COALESCE(ex.exception_codes, '') AS exception_codes,
                    ROUND(COALESCE(vs.propina, 0), 2) AS propina,
                    ROUND(COALESCE(vs.cargo_servicio, 0), 2) AS cargo_servicio
                FROM keys k
                LEFT JOIN valid_summary vs
                  ON vs.folio_date = k.folio_date AND vs.branch_key = k.branch_key
                LEFT JOIN refunds r
                  ON r.folio_date = k.folio_date AND r.branch_key = k.branch_key
                LEFT JOIN voids vd
                  ON vd.folio_date = k.folio_date AND vd.branch_key = k.branch_key
                LEFT JOIN payments p
                  ON p.folio_date = k.folio_date AND p.branch_key = k.branch_key
                LEFT JOIN terminals t
                  ON t.folio_date = k.folio_date AND t.branch_key = k.branch_key
                LEFT JOIN exceptions ex
                  ON ex.folio_date = k.folio_date AND ex.branch_key = k.branch_key
            )
            SELECT
                *,
                CASE 
                    WHEN ? = 1 THEN pagos_netos 
                    ELSE neto_legacy 
                END AS neto
            FROM result_calculation
            ORDER BY folio_date, branch_key;
        SQL;

        $rows = $this->executeWithTimeout($sql, [
            $start->toDateString(),
            $end->toDateString(),
            $this->stringifyFilter($branches),
            $this->stringifyFilter($terminals),
            $this->isCanonMode() ? 1 : 0,
        ]);

        return collect($rows)->map(function (object $row): array {
            return [
                'folio_date' => Carbon::parse($row->folio_date)->format('Y-m-d'),
                'branch_key' => strtoupper(trim((string) ($row->branch_key ?? ''))),
                'tickets' => (int) ($row->tickets ?? 0),
                'bruto' => (float) ($row->bruto ?? 0),
                'descuento' => (float) ($row->descuento ?? 0),
                'anulaciones' => (float) ($row->anulaciones ?? 0),
                'neto' => (float) ($row->neto ?? 0),
                'pagos_netos' => (float) ($row->pagos_netos ?? 0),
                'propina' => (float) ($row->propina ?? 0),
                'cargo_servicio' => (float) ($row->cargo_servicio ?? 0),
                'terminals_raw' => (string) ($row->terminales ?? ''),
                'exceptions_count' => (int) ($row->exceptions_count ?? 0),
                'exception_codes' => (string) ($row->exception_codes ?? ''),
            ];
        });
    }

    protected function hydrateRows(Collection $rows, array $branchColors, array $branchLabels): Collection
    {
        return $rows->map(function (array $row) use ($branchColors, $branchLabels) {
            $terminals = $this->explodeList($row['terminals_raw'] ?? '');
            $date = Carbon::parse($row['folio_date'], 'America/Mexico_City');
            $branchKey = $row['branch_key'] ? strtoupper(trim($row['branch_key'])) : 'SIN_SUCURSAL';

            $detailParams = [
                'start' => $date->format('Y-m-d'),
                'end' => $date->format('Y-m-d'),
                'branch' => $branchKey,
            ];

            if (! empty($terminals)) {
                $detailParams['terminal'] = implode(',', $terminals);
            }

            $paymentsDelta = $this->round($row['pagos_netos'] - $row['neto']);

            return array_merge($row, [
                'branch_key' => $branchKey,
                'branch_label' => $branchLabels[$branchKey] ?? $branchKey,
                'branch_color' => $branchColors[$branchKey] ?? $this->fallbackPalette[0],
                'terminals' => $terminals,
                'terminals_display' => implode(' · ', $terminals),
                'detail_route_params' => $detailParams,
                'has_exceptions' => ($row['exceptions_count'] ?? 0) > 0,
                'payments_delta' => $paymentsDelta,
                'exception_codes_list' => $this->explodeList($row['exception_codes'] ?? ''),
                'discount_rate' => ($row['bruto'] > 0)
                    ? $this->round((($row['descuento'] + $row['anulaciones']) / $row['bruto']) * 100)
                    : 0.0,
            ]);
        });
    }

    protected function summarize(Collection $rows): array
    {
        return [
            'tickets' => (int) $rows->sum(fn (array $row) => $row['tickets']),
            'bruto' => $this->round($rows->sum(fn (array $row) => $row['bruto'])),
            'descuento' => $this->round($rows->sum(fn (array $row) => $row['descuento'])),
            'anulaciones' => $this->round($rows->sum(fn (array $row) => $row['anulaciones'])),
            'neto' => $this->round($rows->sum(fn (array $row) => $row['neto'])),
            'pagos_netos' => $this->round($rows->sum(fn (array $row) => $row['pagos_netos'])),
            'propina' => $this->round($rows->sum(fn (array $row) => $row['propina'])),
            'cargo_servicio' => $this->round($rows->sum(fn (array $row) => $row['cargo_servicio'])),
            'delta_pagos' => $this->round(
                $rows->sum(fn (array $row) => $row['pagos_netos'] - $row['neto'])
            ),
        ];
    }

    protected function stringifyFilter(array $values): ?string
    {
        if (empty($values)) {
            return null;
        }

        return implode(',', array_map(
            fn ($value) => strtoupper(trim((string) $value)),
            $values
        ));
    }

    protected function explodeList(string $value): array
    {
        return collect(explode(',', $value))
            ->map(fn ($item) => trim($item))
            ->filter()
            ->values()
            ->all();
    }

    protected function prepareBranchColors(array $branchKeys): array
    {
        $configured = collect(config('reports.branch_colors', []))
            ->mapWithKeys(fn ($color, $key) => [strtoupper((string) $key) => $color])
            ->toArray();

        $palette = config('reports.branch_palette', $this->fallbackPalette);
        if (empty($palette)) {
            $palette = $this->fallbackPalette;
        }

        $colors = $configured;
        $index = 0;

        foreach ($branchKeys as $key) {
            $upper = strtoupper((string) $key);
            if ($upper === '') {
                continue;
            }

            if (! isset($colors[$upper])) {
                $colors[$upper] = $palette[$index % count($palette)];
                $index++;
            }
        }

        return $colors;
    }

    protected function loadBranchOptions(array $branchColors, array $selected): Collection
    {
        try {
            $rows = DB::connection('pgsql')->select("
                SELECT
                    UPPER(COALESCE(clave, '')) AS key,
                    COALESCE(nombre, UPPER(clave)) AS label
                FROM selemti.cat_sucursales
                ORDER BY nombre
            ");
        } catch (\Throwable $e) {
            $rows = [];
        }

        $options = collect($rows)
            ->map(fn (object $row) => [
                'key' => strtoupper(trim((string) ($row->key ?? ''))),
                'label' => trim((string) ($row->label ?? ($row->key ?? ''))),
            ])
            ->filter(fn (array $opt) => $opt['key'] !== '')
            ->keyBy('key');

        $selectedKeys = collect($selected)
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->values()
            ->all();

        $allKeys = collect($branchColors)->keys()
            ->merge($options->keys())
            ->unique()
            ->values();

        return $allKeys
            ->map(function (string $key) use ($options, $branchColors, $selectedKeys) {
                $base = $options->get($key, [
                    'key' => $key,
                    'label' => $key,
                ]);

                $color = $branchColors[$key] ?? $this->fallbackPalette[0];

                return array_merge($base, [
                    'key' => $key,
                    'value' => $key,
                    'color' => $color,
                    'indicator_color' => $color,
                    'selected' => in_array($key, $selectedKeys, true),
                    'badge' => null,
                    'highlight' => false,
                ]);
            })
            ->sortBy(fn (array $opt) => $opt['label'])
            ->values();
    }

    protected function loadTerminalOptions(
        array $branchColors,
        array $branchLabels,
        array $selectedTerminals,
        array $selectedBranches
    ): Collection {
        try {
            $rows = DB::connection('pgsql')->select("
                SELECT
                    CAST(t.id AS text) AS id,
                    COALESCE(NULLIF(t.name, ''), CONCAT('Terminal ', t.id::text)) AS name,
                    UPPER(COALESCE(s.clave, t.location, '')) AS branch_key,
                    COALESCE(s.nombre, t.location, CONCAT('Terminal ', t.id::text)) AS branch_label
                FROM public.terminal t
                LEFT JOIN selemti.cat_sucursales s ON s.pos_location = t.location
                ORDER BY branch_label, t.id
            ");
        } catch (\Throwable $e) {
            $rows = [];
        }

        $selected = collect($selectedTerminals)
            ->map(fn ($value) => trim((string) $value))
            ->filter()
            ->values()
            ->all();

        $selectedBranchSet = collect($selectedBranches)
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->values()
            ->all();

        return collect($rows)
            ->map(function (object $row) use ($branchColors, $branchLabels, $selected, $selectedBranchSet) {
                $branchKey = strtoupper((string) ($row->branch_key ?? ''));
                $label = trim((string) ($row->branch_label ?? ''));

                $color = $branchColors[$branchKey] ?? $this->fallbackPalette[0];

                return [
                    'id' => (string) ($row->id ?? ''),
                    'value' => (string) ($row->id ?? ''),
                    'label' => trim(sprintf(
                        '%s · %s',
                        (string) ($row->id ?? ''),
                        (string) ($row->name ?? $row->id ?? '')
                    )),
                    'branch_key' => $branchKey,
                    'branch_label' => $branchLabels[$branchKey] ?? ($label ?: $branchKey),
                    'color' => $color,
                    'indicator_color' => null,
                    'selected' => in_array((string) ($row->id ?? ''), $selected, true),
                    'highlight' => $branchKey && in_array($branchKey, $selectedBranchSet, true),
                    'badge' => [
                        'label' => $branchLabels[$branchKey] ?? ($label ?: $branchKey),
                        'color' => $color,
                        'text_color' => '#ffffff',
                    ],
                ];
            })
            ->filter(fn (array $opt) => $opt['id'] !== '')
            ->values();
    }
}
