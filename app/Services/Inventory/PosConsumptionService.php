<?php

namespace App\Services\Inventory;

use App\Events\Pos\PosTicketIngested;
use App\Exceptions\Inventory\InventoryValidationException;
use App\Models\Inv\Item;
use App\Models\Pos\PosModifierInvMapping;
use App\Services\Pos\PosModifierService;
use Illuminate\Support\Arr;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class PosConsumptionService
{
    private const TIPO_VENTA_POS = 'VENTA_POS';

    private const REF_TIPO_POS_TICKET = 'POS_TICKET';

    public function __construct(
        private readonly PosModifierService $modifierService,
        private readonly UomConversionService $uomService,
    ) {}

    public function expandTicket(int $ticketId): void
    {
        $connection = DB::connection('pgsql');
        $connection->select('SELECT * FROM selemti.fn_expandir_consumo_ticket(?)', [$ticketId]);
    }

    public function confirmTicket(
        int $ticketId,
        ?int $userId = null,
        ?string $sucursalId = null,
        ?string $almacenId = null
    ): array {
        $connection = DB::connection('pgsql');
        $summary = $connection->transaction(function () use ($ticketId, $userId, $sucursalId, $almacenId): array {
            $summary = [
                'ticket_id' => $ticketId,
                'ticket_items_processed' => 0,
                'recipe_movements' => 0,
                'modifier_movements' => 0,
                'warnings' => [],
            ];

            foreach ($this->ticketItemsForProcessing($ticketId) as $ticketItem) {
                $itemCount = max((float) ($ticketItem->item_count ?? $ticketItem->item_quantity ?? 1), 0.0);
                $menuMapping = $this->modifierService->findMenuItemMapping((int) $ticketItem->item_id);
                $resolvedModifiers = $this->resolvedModifierMappings((int) $ticketItem->id);
                $selectorUoms = [];
                $pendingAdicionales = [];

                foreach ($resolvedModifiers as [$modifier, $mapping]) {
                    if ($mapping->tipo_efecto === 'SELECTOR') {
                        $qty = $this->resolveModifierQty($mapping, max((int) ($modifier->item_count ?? 1), 1));
                        $movements = $this->deductInventoryItem(
                            itemId: (string) $mapping->item_id,
                            qty: $qty,
                            uom: (string) $mapping->uom,
                            ticketItemId: (int) $ticketItem->id,
                            ticketId: $ticketId,
                            sucursalId: $sucursalId,
                            almacenId: $almacenId,
                            userId: $userId,
                            source: 'selector',
                            warnings: $summary['warnings'],
                        );

                        if ($movements > 0) {
                            $selectorUoms[(string) $mapping->uom] = (string) $mapping->item_id;
                        }

                        $summary['modifier_movements'] += $movements;

                        continue;
                    }

                    $pendingAdicionales[] = [$modifier, $mapping];
                }

                if ($menuMapping?->recipe_id) {
                    $porciones = $itemCount * (int) $menuMapping->porciones_por_orden;
                    $summary['recipe_movements'] += $this->deductRecipeIngredients(
                        recipeId: (int) $menuMapping->recipe_id,
                        qty: $porciones,
                        ticketItemId: (int) $ticketItem->id,
                        ticketId: $ticketId,
                        sucursalId: $sucursalId,
                        almacenId: $almacenId,
                        userId: $userId,
                        selectorUoms: $selectorUoms,
                        warnings: $summary['warnings'],
                    );
                } elseif (! $menuMapping) {
                    $summary['warnings'][] = "Ticket item {$ticketItem->id} sin mapping menu_item->recipe.";
                    Log::warning('POS ticket item sin mapping de receta', [
                        'ticket_id' => $ticketId,
                        'ticket_item_id' => $ticketItem->id,
                        'menu_item_id' => $ticketItem->item_id,
                    ]);
                }

                foreach ($pendingAdicionales as [$modifier, $mapping]) {
                    if ($menuMapping && $menuMapping->recipe_id === null) {
                        Log::info('POS modifier adicional omitido para SELECTOR_DEFINE', [
                            'ticket_id' => $ticketId,
                            'ticket_item_id' => $ticketItem->id,
                            'modifier_id' => $modifier->id ?? null,
                            'modifier_name' => $modifier->modifier_name ?? null,
                        ]);

                        continue;
                    }

                    $qty = $this->resolveModifierQty($mapping, max((int) ($modifier->item_count ?? 1), 1));
                    $summary['modifier_movements'] += $this->deductInventoryItem(
                        itemId: (string) $mapping->item_id,
                        qty: $qty,
                        uom: (string) $mapping->uom,
                        ticketItemId: (int) $ticketItem->id,
                        ticketId: $ticketId,
                        sucursalId: $sucursalId,
                        almacenId: $almacenId,
                        userId: $userId,
                        source: 'modifier',
                        warnings: $summary['warnings'],
                    );
                }

                $this->markProcessed((int) $ticketItem->id, $ticketId, $userId);
                $summary['ticket_items_processed']++;
            }

            return $summary;
        }, 5);

        $this->dispatchIngestedEvent($ticketId);

        return $summary;
    }

    public function reverseTicket(int $ticketId): void
    {
        $connection = DB::connection('pgsql');

        $connection->transaction(static function () use ($connection, $ticketId) {
            $connection->statement('SELECT selemti.fn_reversar_consumo_ticket(?)', [$ticketId]);
        }, 5);
    }

    public function normalizeLine(array $line): array
    {
        $normalized = [
            'item_id' => (string) Arr::get($line, 'item_id'),
            'uom' => Arr::get($line, 'uom'),
            'cantidad' => (float) Arr::get($line, 'cantidad', 0),
            'factor' => (float) Arr::get($line, 'factor', 1),
            'origen' => Arr::get($line, 'origen', 'RECETA'),
            'meta' => Arr::get($line, 'meta', []),
        ];

        if ($normalized['cantidad'] <= 0) {
            throw new InventoryValidationException('La cantidad debe ser mayor a cero.');
        }

        return $normalized;
    }

    protected function dispatchIngestedEvent(int $ticketId): void
    {
        $ticket = DB::connection('pgsql')
            ->table('public.ticket')
            ->select('id', 'create_date', 'terminal_id')
            ->where('id', $ticketId)
            ->first();

        event(new PosTicketIngested(
            ticketId: $ticketId,
            date: $ticket ? (string) $ticket->create_date : now()->toIso8601String(),
            terminalId: $ticket ? (int) $ticket->terminal_id : null,
        ));
    }

    protected function ticketItemsForProcessing(int $ticketId): Collection
    {
        return DB::connection('pgsql')
            ->table('public.ticket_item as ti')
            ->leftJoin('selemti.pos_ticket_item_processed as processed', 'processed.ticket_item_id', '=', 'ti.id')
            ->select('ti.*')
            ->where('ti.ticket_id', $ticketId)
            ->whereNull('processed.ticket_item_id')
            ->where(function ($query): void {
                $query->where('ti.inventory_handled', false)
                    ->orWhereNull('ti.inventory_handled');
            })
            ->orderBy('ti.id')
            ->get();
    }

    protected function modifiersForTicketItem(int $ticketItemId): Collection
    {
        return DB::connection('pgsql')
            ->table('public.ticket_item_modifier')
            ->where('ticket_item_id', $ticketItemId)
            ->orderBy('id')
            ->get();
    }

    protected function resolveMenuModifierId(int $ticketItemId, object $modifier): int
    {
        if (! empty($modifier->item_id)) {
            return (int) $modifier->item_id;
        }

        $relation = DB::connection('pgsql')
            ->table('public.ticket_item_modifier_relation')
            ->where('ticket_item_id', $ticketItemId)
            ->where('list_order', (int) ($modifier->id ?? 0))
            ->first();

        return (int) ($relation->modifier_id ?? 0);
    }

    /**
     * @return array<int, array{0: object, 1: PosModifierInvMapping}>
     */
    private function resolvedModifierMappings(int $ticketItemId): array
    {
        $resolved = [];

        foreach ($this->modifiersForTicketItem($ticketItemId) as $modifier) {
            $menuModifierId = $this->resolveMenuModifierId($ticketItemId, $modifier);
            $mapping = $this->modifierService->findMapping($menuModifierId, (string) ($modifier->modifier_name ?? ''));

            if (! $mapping || ! $mapping->item_id || (float) $mapping->qty_por_unidad == 0.0) {
                Log::info('POS modifier sin efecto de inventario', [
                    'ticket_item_id' => $ticketItemId,
                    'modifier_id' => $modifier->id ?? null,
                    'menu_modifier_id' => $menuModifierId,
                    'modifier_name' => $modifier->modifier_name ?? null,
                ]);

                continue;
            }

            $resolved[] = [$modifier, $mapping];
        }

        return $resolved;
    }

    private function deductRecipeIngredients(
        int $recipeId,
        float $qty,
        int $ticketItemId,
        int $ticketId,
        ?string $sucursalId,
        ?string $almacenId,
        ?int $userId,
        array $selectorUoms,
        array &$warnings
    ): int {
        $version = DB::connection('pgsql')
            ->table('selemti.recipe_versions')
            ->whereRaw('recipe_id::text = ?', [(string) $recipeId])
            ->where(function ($query): void {
                $query->whereNull('valid_to')
                    ->orWhere('valid_to', '>', now());
            })
            ->orderByDesc('valid_from')
            ->orderByDesc('version_no')
            ->first();

        if (! $version) {
            $warnings[] = "Receta {$recipeId} sin versión activa.";

            return 0;
        }

        $movements = 0;
        $items = DB::connection('pgsql')
            ->table('selemti.recipe_version_items')
            ->where('recipe_version_id', $version->id)
            ->orderBy('id')
            ->get();

        foreach ($items as $ingredient) {
            if (isset($selectorUoms[(string) $ingredient->uom_receta])) {
                continue;
            }

            $lineQty = (float) $ingredient->qty * $qty;

            if ($ingredient->item_id !== null) {
                $movements += $this->deductInventoryItem(
                    itemId: (string) $ingredient->item_id,
                    qty: $lineQty,
                    uom: (string) $ingredient->uom_receta,
                    ticketItemId: $ticketItemId,
                    ticketId: $ticketId,
                    sucursalId: $sucursalId,
                    almacenId: $almacenId,
                    userId: $userId,
                    source: 'recipe',
                    warnings: $warnings,
                );

                continue;
            }

            if ($ingredient->sub_recipe_id !== null) {
                $producedItemId = $this->findProducedItemForRecipe((int) $ingredient->sub_recipe_id);
                if (! $producedItemId) {
                    $warnings[] = "Sub-receta {$ingredient->sub_recipe_id} sin item producible.";

                    continue;
                }

                $movements += $this->deductInventoryItem(
                    itemId: $producedItemId,
                    qty: $lineQty,
                    uom: (string) $ingredient->uom_receta,
                    ticketItemId: $ticketItemId,
                    ticketId: $ticketId,
                    sucursalId: $sucursalId,
                    almacenId: $almacenId,
                    userId: $userId,
                    source: 'sub_recipe',
                    warnings: $warnings,
                );
            }
        }

        return $movements;
    }

    private function resolveModifierQty(PosModifierInvMapping $mapping, int $itemCount): float
    {
        if ($mapping->qty_source === 'RECIPE' && $mapping->recipe_id) {
            $recipeQty = DB::connection('pgsql')
                ->table('selemti.recipe_versions as rv')
                ->join('selemti.recipe_version_items as rvi', 'rvi.recipe_version_id', '=', 'rv.id')
                ->whereRaw('rv.recipe_id::text = ?', [(string) $mapping->recipe_id])
                ->whereNull('rv.valid_to')
                ->whereNotNull('rvi.item_id')
                ->sum('rvi.qty');

            return (float) $recipeQty * $itemCount;
        }

        return (float) $mapping->qty_por_unidad * $itemCount;
    }

    private function deductInventoryItem(
        string $itemId,
        float $qty,
        string $uom,
        int $ticketItemId,
        int $ticketId,
        ?string $sucursalId,
        ?string $almacenId,
        ?int $userId,
        string $source,
        array &$warnings
    ): int {
        if ($qty <= 0) {
            return 0;
        }

        $item = Item::with(['uom', 'uomCompra'])->find($itemId);
        $baseQty = $item ? $this->uomService->resolveToBase($qty, $uom, $item) : $qty;
        $baseUom = (string) ($item?->uom?->clave ?? $uom);
        $remaining = $baseQty;
        $movements = 0;
        $expiryColumn = Schema::connection('pgsql')->hasColumn('selemti.inventory_batch', 'fecha_caducidad')
            ? 'fecha_caducidad'
            : 'caducidad';

        while ($remaining > 0.000001) {
            $batch = DB::connection('pgsql')
                ->table('selemti.inventory_batch')
                ->whereRaw('item_id::text = ?', [$itemId])
                ->where('cantidad_actual', '>', 0)
                ->when($almacenId, fn ($query) => $query->where('almacen_id', $almacenId))
                ->orderByRaw("{$expiryColumn} ASC NULLS LAST")
                ->orderBy('created_at')
                ->lockForUpdate()
                ->first();

            if (! $batch) {
                $warnings[] = "Stock insuficiente para item {$itemId}; faltante {$remaining} {$baseUom}.";
                Log::warning('Stock insuficiente para consumo POS', [
                    'ticket_id' => $ticketId,
                    'ticket_item_id' => $ticketItemId,
                    'item_id' => $itemId,
                    'remaining' => $remaining,
                    'uom' => $baseUom,
                ]);

                break;
            }

            $deductQty = min($remaining, (float) $batch->cantidad_actual);

            DB::connection('pgsql')
                ->table('selemti.inventory_batch')
                ->where('id', $batch->id)
                ->update([
                    'cantidad_actual' => (float) $batch->cantidad_actual - $deductQty,
                    'updated_at' => now(),
                ]);

            DB::connection('pgsql')
                ->table('selemti.mov_inv')
                ->insert([
                    'item_id' => $itemId,
                    'inventory_batch_id' => $batch->id,
                    'tipo' => self::TIPO_VENTA_POS,
                    'qty' => -$deductQty,
                    'uom' => $baseUom,
                    'sucursal_id' => $sucursalId ?? $batch->sucursal_id ?? null,
                    'almacen_id' => $almacenId ?? $batch->almacen_id ?? null,
                    'ref_tipo' => self::REF_TIPO_POS_TICKET,
                    'ref_id' => $ticketId,
                    'user_id' => $userId,
                    'ts' => now(),
                    'meta' => json_encode([
                        'source' => $source,
                        'ticket_item_id' => $ticketItemId,
                    ]),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

            $remaining -= $deductQty;
            $movements++;
        }

        return $movements;
    }

    private function findProducedItemForRecipe(int $recipeId): ?string
    {
        $recipe = DB::connection('pgsql')
            ->table('selemti.recipes')
            ->select('codigo', 'nombre', 'meta')
            ->where('id', $recipeId)
            ->first();

        if (! $recipe) {
            return null;
        }

        $meta = is_string($recipe->meta) ? json_decode($recipe->meta, true) : null;
        $itemCode = $meta['item_producido_codigo'] ?? $meta['item_producido'] ?? null;

        if ($itemCode) {
            $item = DB::connection('pgsql')
                ->table('selemti.items')
                ->select('id')
                ->where('es_producible', true)
                ->where('item_code', $itemCode)
                ->first();

            if ($item) {
                return (string) $item->id;
            }
        }

        $item = DB::connection('pgsql')
            ->table('selemti.items')
            ->select('id')
            ->where('es_producible', true)
            ->where(function ($query) use ($recipe): void {
                $query->where('item_code', $recipe->codigo)
                    ->orWhere('nombre', $recipe->nombre);
            })
            ->first();

        return $item ? (string) $item->id : null;
    }

    protected function markProcessed(int $ticketItemId, int $ticketId, ?int $userId): void
    {
        DB::connection('pgsql')
            ->table('selemti.pos_ticket_item_processed')
            ->updateOrInsert(
                ['ticket_item_id' => $ticketItemId],
                [
                    'ticket_id' => $ticketId,
                    'processed_at' => now(),
                    'user_id' => $userId ?? 0,
                ],
            );
    }
}
