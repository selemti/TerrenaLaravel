<?php

namespace App\Services\Alerts;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AlertEngine
{
    public function run(): void
    {
        DB::connection('pgsql')->transaction(function (): void {
            $rules = DB::table('selemti.alert_rules')
                ->where('enabled', true)
                ->get();

            foreach ($rules as $rule) {
                $type = $rule->type;
                $scope = $rule->scope ?? 'global';

                match ($type) {
                    'stock_minimo' => $this->evaluateStockRule($rule),
                    'caducidad' => $this->evaluateExpiryRule($rule),
                    'variancia' => $this->evaluateVarianceRule($rule),
                    'precio_atipico' => $this->evaluatePriceRule($rule),
                    default => null,
                };
            }
        });
    }

    protected function evaluateStockRule(object $rule): void
    {
        $threshold = (float) ($rule->threshold_numeric ?? 0);

        if (! $this->relationExists('selemti.vw_inventory_stock_levels')) {
            return;
        }

        $rows = DB::table('selemti.vw_inventory_stock_levels as stock')
            ->where('stock.on_hand', '<', DB::raw((string) $threshold))
            ->get();

        foreach ($rows as $row) {
            $this->storeAlert(
                rule: $rule,
                entityType: 'item',
                entityId: $row->item_id,
                payload: [
                    'on_hand' => $row->on_hand,
                    'threshold' => $threshold,
                ],
                severity: 'high'
            );
        }
    }

    protected function evaluateExpiryRule(object $rule): void
    {
        $days = (int) ($rule->threshold_numeric ?? 3);

        $rows = DB::table('selemti.inv_batches as batch')
            ->select('batch.id', 'batch.item_id', 'batch.expires_at')
            ->whereNotNull('batch.expires_at')
            ->whereRaw('batch.expires_at <= (CURRENT_DATE + INTERVAL ? DAY)', [$days])
            ->get();

        foreach ($rows as $row) {
            $this->storeAlert(
                $rule,
                'batch',
                $row->id,
                [
                    'expires_at' => $row->expires_at,
                    'days' => $days,
                ],
                'medium'
            );
        }
    }

    protected function evaluateVarianceRule(object $rule): void
    {
        $percent = (float) ($rule->threshold_percent ?? 0.1);

        if (! $this->relationExists('selemti.inventory_variances')) {
            return;
        }

        $rows = DB::table('selemti.inventory_variances as v')
            ->where('v.absolute_percent', '>=', $percent)
            ->where('v.handled', false)
            ->get();

        foreach ($rows as $row) {
            $this->storeAlert(
                $rule,
                'inventory_variance',
                $row->id,
                [
                    'absolute_percent' => $row->absolute_percent,
                    'variance_qty' => $row->variance_qty,
                ],
                'high'
            );
        }
    }

    protected function evaluatePriceRule(object $rule): void
    {
        $percent = (float) ($rule->threshold_percent ?? 0.15);

        $rows = DB::table('selemti.item_vendor_prices as ivp')
            ->join('selemti.vw_item_last_price as last', function ($join) {
                $join->on('last.item_id', '=', 'ivp.item_id')
                    ->on('last.vendor_id', '=', 'ivp.vendor_id');
            })
            ->select('ivp.id', 'ivp.item_id', 'ivp.vendor_id', 'ivp.price', 'last.price as reference_price')
            ->whereNull('ivp.effective_to')
            ->get();

        foreach ($rows as $row) {
            if ($row->reference_price <= 0) {
                continue;
            }

            $delta = abs($row->price - $row->reference_price) / $row->reference_price;

            if ($delta >= $percent) {
                $this->storeAlert(
                    $rule,
                    'item_vendor_price',
                    $row->id,
                    [
                        'price' => $row->price,
                        'reference_price' => $row->reference_price,
                        'delta_percent' => $delta,
                    ],
                    'medium'
                );
            }
        }
    }

    protected function relationExists(string $relation): bool
    {
        $result = DB::selectOne("SELECT to_regclass(?) AS name", [$relation]);

        return $result !== null && $result->name !== null;
    }

    protected function storeAlert(
        object $rule,
        string $entityType,
        int|string $entityId,
        array $payload,
        string $severity
    ): void {
        $existing = DB::table('selemti.alert_events')
            ->where('rule_id', $rule->id)
            ->where('entity_type', $entityType)
            ->where('entity_id', (string) $entityId)
            ->where('handled', false)
            ->first();

        if ($existing) {
            return;
        }

        DB::table('selemti.alert_events')->insert([
            'rule_id' => $rule->id,
            'entity_type' => $entityType,
            'entity_id' => (string) $entityId,
            'payload' => json_encode($payload, JSON_THROW_ON_ERROR),
            'severity' => $severity,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Log::info('Nueva alerta generada', [
            'rule_id' => $rule->id,
            'entity' => $entityType,
            'entity_id' => $entityId,
        ]);
    }
}
