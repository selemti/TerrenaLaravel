<?php

namespace App\Services\Reports;

use App\Adapters\FloreantPos\FloreantPosAdapter;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class SalesExceptionsReportService
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

    /**
     * Resumen de descuentos calculado en la última llamada a fetch.
     */
    protected Collection $discountSummary;

    public function __construct(private readonly FloreantPosAdapter $pos)
    {
        $this->discountSummary = collect();
    }

    public function getCategoryCatalog(): array
    {
        return $this->categoryCatalog;
    }

    /**
     * Obtiene tickets con información financiera básica.
     */
    public function fetch(Carbon $start, Carbon $end, array $filters = []): Collection
    {
        $branchIds = $this->normalizeBranchFilter($filters['branch_ids'] ?? []);
        $terminalIds = $this->normalizeFilter($filters['terminal_ids'] ?? []);

        $tickets = $this->fetchTickets($start, $end, $branchIds, $terminalIds);

        if ($tickets->isEmpty()) {
            $this->discountSummary = collect();

            return collect();
        }

        $ticketIds = $tickets
            ->pluck('ticket_id')
            ->map(fn ($id) => (int) $id)
            ->filter()
            ->unique()
            ->values();

        $payments = $this->loadPaymentSummary($ticketIds);
        $transactions = $this->loadTransactionDetails($ticketIds);
        [$discountsByTicket, $discountSummary] = $this->loadDiscounts($ticketIds);
        $itemsByTicket = $this->loadItems($ticketIds);

        $this->discountSummary = $discountSummary;

        return $tickets->map(function (object $row) use ($payments, $transactions, $discountsByTicket, $itemsByTicket) {
            $ticketId = (int) ($row->ticket_id ?? 0);
            $payment = $payments->get($ticketId, $this->emptyPaymentSummary());
            $discounts = $discountsByTicket->get($ticketId, collect());
            $paymentTotal = (float) ($payment['payment_total'] ?? 0);
            $paymentAdjustmentTotal = (float) ($payment['payment_adjustment_total'] ?? 0);

            $discountTotal = (float) ($row->discount_total ?? 0);
            $grossTotal = (float) ($row->gross_total ?? 0);
            $netRaw = (float) ($row->net_total_raw ?? 0);

            // Flag de Modo Canon (vía filtros o global)
            $isCanon = (bool) ($filters['is_canon'] ?? (request()->query('mode') === 'canon' || config('finance.use_canon_mode', false)));

            if ($isCanon) {
                // Modo Canon: El neto analítico es la liquidación efectiva (SSOT)
                $netTotal = $this->round($paymentTotal + $paymentAdjustmentTotal);
            } else {
                // Modo Legacy: Aritmética vulnerable a corrupción de total_discount (BUG-04)
                $netTotal = $netRaw !== 0.0 ? $netRaw : $this->round($grossTotal - $discountTotal);
            }

            return [
                'ticket_id' => $ticketId,
                'folio_date' => $this->normalizeDate($row->folio_date ?? null),
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
                'gross_total' => $grossTotal,
                'sub_total' => (float) ($row->sub_total ?? 0),
                'total_tax' => (float) ($row->total_tax ?? 0),
                'service_charge' => (float) ($row->service_charge ?? 0),
                'delivery_charge' => (float) ($row->delivery_charge ?? 0),
                'paid_amount_flag' => (float) ($row->paid_amount_flag ?? 0),
                'discount_total' => $discountTotal,
                'net_total' => $netTotal,
                'payment_total' => $paymentTotal,
                'payment_adjustment_total' => $paymentAdjustmentTotal,
                'effective_payment_total' => $this->round($paymentTotal + $paymentAdjustmentTotal),
                'refund_total' => (float) ($payment['refund_total'] ?? 0),
                'void_total' => (float) ($payment['void_total'] ?? 0),
                'recorded_total' => (float) ($payment['recorded_total'] ?? 0),
                'tx_count' => (int) ($payment['tx_count'] ?? 0),
                'payment_positive_count' => (int) ($payment['payment_positive_count'] ?? 0),
                'payment_adjustment_count' => (int) ($payment['payment_adjustment_count'] ?? 0),
                'transactions' => $transactions->get($ticketId, collect())->toArray(),
                'discounts' => $discounts->toArray(),
                'items' => $itemsByTicket->get($ticketId, collect())->toArray(),
            ];
        })->values();
    }

    /**
     * Construye resumen, categorías y registros de excepciones.
     */
    public function summarize(Collection $tickets, string $view = 'default'): array
    {
        if ($tickets->isEmpty()) {
            return [
                'records' => collect(),
                'categories' => collect(),
                'summary' => [
                    'total_records' => 0,
                    'total_tickets' => 0,
                    'impact_sum' => 0.0,
                    'by_category' => [],
                ],
                'discounts' => [
                    'by_ticket' => collect(),
                    'summary' => collect(),
                ],
            ];
        }

        $records = collect();
        $discountsByTicket = $this->buildDiscountsByTicket($tickets);
        $discountSummary = $this->discountSummary->isNotEmpty()
            ? $this->discountSummary
            : $this->summarizeDiscounts($discountsByTicket);

        foreach ($tickets as $ticket) {
            $ticketDiscounts = $discountsByTicket->get($ticket['ticket_id'] ?? 0, collect());
            $this->classifyTicket($ticket, $ticketDiscounts)
                ->each(fn (array $record) => $records->push($record));
        }

        $categories = $this->buildCategories($records);
        $summary = $this->buildSummary($records, $categories);

        return [
            'records' => $records->map(fn (array $record) => $this->prepareRecordForOutput($record))->values(),
            'categories' => $categories->values(),
            'summary' => $summary,
            'discounts' => [
                'by_ticket' => $discountsByTicket,
                'summary' => $discountSummary,
            ],
        ];
    }

    protected function fetchTickets(Carbon $start, Carbon $end, array $branches, array $terminals): Collection
    {
        return $this->pos->fetchExceptionTickets($start, $end, $branches, $terminals);
    }

    protected function loadPaymentSummary(Collection $ticketIds): Collection
    {
        $rows = $this->pos->loadPaymentSummaryByTicketIds($ticketIds);

        return $rows->map(function (object $row) {
            return [
                'payment_total' => (float) ($row->payment_total ?? 0),
                'payment_adjustment_total' => (float) ($row->payment_adjustment_total ?? 0),
                'refund_total' => (float) ($row->refund_total ?? 0),
                'void_total' => (float) ($row->void_total ?? 0),
                'recorded_total' => (float) ($row->recorded_total ?? 0),
                'tx_count' => (int) ($row->tx_count ?? 0),
                'payment_positive_count' => (int) ($row->payment_positive_count ?? 0),
                'payment_adjustment_count' => (int) ($row->payment_adjustment_count ?? 0),
            ];
        });
    }

    protected function loadTransactionDetails(Collection $ticketIds): Collection
    {
        if ($ticketIds->isEmpty()) {
            return collect();
        }

        $rows = $this->pos->loadTransactionDetailsByTicketIds($ticketIds);

        return collect($rows)
            ->groupBy(fn (object $row) => (int) ($row->ticket_id ?? 0))
            ->map(function (Collection $transactions) {
                return $transactions
                    ->map(function (object $tx) {
                        $paymentType = strtoupper(trim((string) ($tx->payment_type ?? '')));
                        $transactionType = strtoupper(trim((string) ($tx->transaction_type ?? '')));
                        $amount = (float) ($tx->amount ?? 0.0);
                        $voided = (bool) ($tx->voided ?? false);
                        $isRefund = in_array($paymentType, ['REFUND', 'REFUND_CARD'], true);
                        $isVoidTrans = $paymentType === 'VOID_TRANS';
                        $isAdjustment = $amount < 0 && ! $isRefund && ! $isVoidTrans;

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
                    })
                    ->values();
            });
    }

    protected function loadDiscounts(Collection $ticketIds): array
    {
        $discountRows = collect();

        if ($ticketIds->isEmpty()) {
            return [$discountRows, collect()];
        }

        try {
            $discountRows = $discountRows->merge($this->pos->loadTicketDiscountsByTicketIds($ticketIds));
        } catch (\Throwable $e) {
            // Algunas instalaciones no tienen ticket_discount disponible.
        }

        try {
            $discountRows = $discountRows->merge($this->pos->loadItemDiscountsByTicketIds($ticketIds));
        } catch (\Throwable $e) {
            // ticket_item_discount no existe en algunos entornos; continuar sin datos a nivel item.
        }

        $normalized = collect($discountRows)
            ->map(function (object $row) {
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

        $discountsByTicket = $normalized
            ->groupBy('ticket_id')
            ->map(function (Collection $items) {
                return $items
                    ->groupBy(fn (array $row) => $row['name'].'|'.($row['scope'] ?? 'ticket'))
                    ->map(function (Collection $group) {
                        $first = $group->first();

                        return [
                            'ticket_id' => $first['ticket_id'],
                            'name' => $first['name'],
                            'scope' => $first['scope'],
                            'type' => $first['type'],
                            'applications' => $group->count(),
                            'amount' => $this->round($group->sum('amount')),
                        ];
                    })
                    ->values();
            });

        $discountSummary = $this->summarizeDiscounts($discountsByTicket);

        return [$discountsByTicket, $discountSummary];
    }

    protected function loadItems(Collection $ticketIds): Collection
    {
        if ($ticketIds->isEmpty()) {
            return collect();
        }

        try {
            $items = $this->pos->loadItemsByTicketIds($ticketIds);
        } catch (\Throwable $e) {
            return collect();
        }

        return collect($items)
            ->groupBy(fn (object $row) => (int) ($row->ticket_id ?? 0))
            ->map(function (Collection $group) {
                return $group
                    ->map(function (object $row) {
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
    }

    protected function buildDiscountsByTicket(Collection $tickets): Collection
    {
        return $tickets
            ->mapWithKeys(function ($ticket) {
                $ticketId = $ticket['ticket_id'] ?? 0;
                $discounts = collect($ticket['discounts'] ?? [])
                    ->map(function (array $row) use ($ticketId) {
                        $row['ticket_id'] = $ticketId;

                        return $row;
                    });

                return [$ticketId => $discounts];
            })
            ->filter(fn (Collection $discounts) => $discounts->isNotEmpty());
    }

    protected function summarizeDiscounts(Collection $discountsByTicket): Collection
    {
        if ($discountsByTicket->isEmpty()) {
            return collect();
        }

        return $discountsByTicket
            ->flatten(1)
            ->groupBy('name')
            ->map(function (Collection $items, string $name) {
                $tickets = $items->pluck('ticket_id')->unique()->count();
                $total = $this->round($items->sum('amount'));
                $scopeTicket = $items->where('scope', 'ticket')->count();
                $scopeItem = $items->where('scope', 'item')->count();

                return [
                    'name' => $name,
                    'type' => $items->first()['type'] ?? null,
                    'applications' => $items->count(),
                    'tickets' => $tickets,
                    'total_amount' => $total,
                    'average_amount' => $tickets > 0 ? $this->round($total / $tickets) : 0.0,
                    'scopes' => [
                        'ticket' => $scopeTicket,
                        'item' => $scopeItem,
                    ],
                ];
            })
            ->sortByDesc('total_amount')
            ->values();
    }

    protected function classifyTicket(array $ticket, Collection $ticketDiscounts): Collection
    {
        $records = collect();

        $gross = (float) ($ticket['gross_total'] ?? 0);
        $discount = (float) ($ticket['discount_total'] ?? 0);
        $net = (float) ($ticket['net_total'] ?? 0);
        $payments = (float) ($ticket['payment_total'] ?? 0);
        $paymentAdjustments = (float) ($ticket['payment_adjustment_total'] ?? 0);
        $effectivePayments = $this->round($payments + $paymentAdjustments);
        $refunds = (float) ($ticket['refund_total'] ?? 0);
        $voidTotal = (float) ($ticket['void_total'] ?? 0);
        $recorded = (float) ($ticket['recorded_total'] ?? 0);
        $discountRatio = $gross > 0 ? $discount / max($gross, 0.0001) : 0.0;
        $difference = $this->round($net - $effectivePayments);
        $discountNames = $ticketDiscounts
            ->pluck('name')
            ->unique()
            ->filter()
            ->implode(', ');

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

        // Descuento 100%
        if ($gross > 0 && $discountRatio >= 0.99 && abs($effectivePayments) <= 0.01) {
            $notes = [
                sprintf('Descuento aplicado: %s (%.1f%%)', $this->formatMoney($discount), $discountRatio * 100),
            ];

            if (! $ticket['paid_flag']) {
                $notes[] = 'Ticket marcado como pagado: No';
            }

            if ($discountNames !== '') {
                $notes[] = 'Descuentos: '.$discountNames;
            }

            $records->push($this->buildRecord($ticket, 'discount_100', [
                'impact' => $discount,
                'difference' => $difference,
                'discounts' => $discountLines,
                'notes' => $notes,
            ]));
        } elseif ($gross > 0 && ($discount >= 100 || $discountRatio >= 0.20)) {
            $notes = [
                sprintf('Descuento aplicado: %s (%.1f%%)', $this->formatMoney($discount), $discountRatio * 100),
            ];

            if ($discountNames !== '') {
                $notes[] = 'Descuentos: '.$discountNames;
            }

            $records->push($this->buildRecord($ticket, 'discount_high', [
                'impact' => $discount,
                'difference' => $difference,
                'discounts' => $discountLines,
                'notes' => $notes,
            ]));
        }

        // Cerrados sin pago
        if (! ($ticket['voided_flag'] ?? false) && $net > 0.01 && abs($effectivePayments) <= 0.01) {
            $notes = [
                sprintf('Importe neto: %s', $this->formatMoney($net)),
                'Pagos registrados: $0.00',
            ];

            if ($ticket['paid_flag'] ?? false) {
                $notes[] = 'El ticket está marcado como pagado en POS.';
            }

            if ($discountNames !== '') {
                $notes[] = 'Descuentos: '.$discountNames;
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
        if (($ticket['voided_flag'] ?? false) && (abs($effectivePayments) > 0.01 || $refunds > 0.01 || $voidTotal > 0.01)) {
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
            $notes[] = sprintf('Movimientos activos: %d', (int) ($ticket['tx_count'] ?? 0));

            if ($discountNames !== '') {
                $notes[] = 'Descuentos: '.$discountNames;
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
            ! ($ticket['voided_flag'] ?? false)
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
                $notes[] = 'Descuentos: '.$discountNames;
            }

            $records->push($this->buildRecord($ticket, 'payment_mismatch', [
                'impact' => abs($difference),
                'difference' => $difference,
                'discounts' => $discountLines,
                'notes' => $notes,
            ]));
        }

        return $records;
    }

    protected function buildCategories(Collection $records): Collection
    {
        return collect($this->categoryCatalog)
            ->map(function (array $meta, string $key) use ($records) {
                $rows = $records->where('category', $key)->values();

                return array_merge($meta, [
                    'key' => $key,
                    'rows' => $rows,
                    'count' => $rows->count(),
                    'tickets' => $rows->pluck('ticket_id')->unique()->count(),
                    'impact' => $this->round($rows->sum('impact')),
                ]);
            })
            ->filter(fn (array $category) => $category['count'] > 0);
    }

    protected function buildSummary(Collection $records, Collection $categories): array
    {
        return [
            'total_records' => $records->count(),
            'total_tickets' => $records->pluck('ticket_id')->unique()->count(),
            'impact_sum' => $this->round($records->sum('impact')),
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
    }

    protected function buildRecord(array $ticket, string $category, array $overrides = []): array
    {
        $meta = $this->categoryCatalog[$category] ?? ['code' => strtoupper($category)];

        $record = [
            'category' => $category,
            'error_code' => $meta['code'] ?? strtoupper($category),
            'ticket_id' => $ticket['ticket_id'] ?? null,
            'ticket_number' => $ticket['ticket_number'] ?? null,
            'folio_date' => $ticket['folio_date'] ?? null,
            'branch_key' => $ticket['branch_key'] ?? null,
            'terminal_id' => $ticket['terminal_id'] ?? null,
            'gross_total' => (float) ($ticket['gross_total'] ?? 0),
            'discount_total' => (float) ($ticket['discount_total'] ?? 0),
            'net_total' => (float) ($ticket['net_total'] ?? 0),
            'payment_total' => (float) ($ticket['payment_total'] ?? 0),
            'payment_adjustment_total' => (float) ($ticket['payment_adjustment_total'] ?? 0),
            'effective_payment_total' => (float) ($ticket['effective_payment_total'] ?? 0),
            'refund_total' => (float) ($ticket['refund_total'] ?? 0),
            'void_total' => (float) ($ticket['void_total'] ?? 0),
            'recorded_total' => (float) ($ticket['recorded_total'] ?? 0),
            'payment_positive_count' => (int) ($ticket['payment_positive_count'] ?? 0),
            'payment_adjustment_count' => (int) ($ticket['payment_adjustment_count'] ?? 0),
            'paid_flag' => (bool) ($ticket['paid_flag'] ?? false),
            'voided_flag' => (bool) ($ticket['voided_flag'] ?? false),
            'settled_flag' => (bool) ($ticket['settled_flag'] ?? false),
            'refunded_flag' => (bool) ($ticket['refunded_flag'] ?? false),
            'reopened_flag' => (bool) ($ticket['reopened_flag'] ?? false),
            'tx_count' => (int) ($ticket['tx_count'] ?? 0),
            'transactions' => $ticket['transactions'] ?? [],
            'items' => $ticket['items'] ?? [],
            'impact' => 0.0,
            'impact_label' => $meta['impact_label'] ?? 'Impacto',
            'difference' => (float) (($ticket['net_total'] ?? 0) - ($ticket['effective_payment_total'] ?? 0)),
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
                $isAdjustment = $amount < 0 && ! $isRefund && ! $isVoidTrans;

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

    protected function normalizeDate(?string $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return Carbon::parse($value, 'America/Mexico_City')->format('Y-m-d');
    }

    protected function normalizeBranchFilter(array $branches): array
    {
        return collect($branches)
            ->map(fn ($branch) => strtoupper(trim((string) $branch)))
            ->filter()
            ->unique()
            ->values()
            ->all();
    }

    protected function normalizeFilter(array $values): array
    {
        return collect($values)
            ->map(fn ($value) => trim((string) $value))
            ->filter()
            ->unique()
            ->values()
            ->all();
    }

    protected function emptyPaymentSummary(): array
    {
        return [
            'payment_total' => 0.0,
            'payment_adjustment_total' => 0.0,
            'refund_total' => 0.0,
            'void_total' => 0.0,
            'recorded_total' => 0.0,
            'tx_count' => 0,
            'payment_positive_count' => 0,
            'payment_adjustment_count' => 0,
        ];
    }

    protected function round(float $value): float
    {
        return round($value, 2);
    }

    protected function formatMoney(float $value): string
    {
        return '$'.number_format($this->round($value), 2);
    }
}
