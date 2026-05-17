<?php

namespace Database\Seeders\E2E;

use App\Services\Inventory\InventoryCountService;
use App\Services\Inventory\PosConsumptionService;
use App\Services\Inventory\ProductionService;
use App\Services\Inventory\ReceptionService;
use App\Services\Inventory\TransferService;
use App\Services\Inventory\UomConversionService;
use App\Services\Pos\PosModifierService;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class TransactionalFlowSeeder extends Seeder
{
    private const REF_E2E = 'E2E_SEEDER';

    private const SYNTHETIC_TICKET_ID = 90001;

    private Carbon $now;

    private int $sucursalId;

    private int $almGenId;

    private int $almCocId;

    private int $userId;

    /** @var array<int,array{codigo:string,uom_base:string,uom_compra:string,factor_compra:float}> */
    private array $items = [];

    /** @var array<string,int> */
    private array $provIds = [];

    public function run(
        ReceptionService $receptionSvc,
        ProductionService $productionSvc,
        TransferService $transferSvc,
        InventoryCountService $countSvc,
        PosModifierService $modifierSvc,
        UomConversionService $uomSvc,
    ): void {
        $this->now = Carbon::now();
        $this->resolveUserId();

        if ($this->hasPreviousRun()) {
            if (! $this->command?->confirm('Ya existe una corrida E2E. ¿Limpiar y re-ejecutar?', false)) {
                $this->command?->info('Corrida E2E omitida; no se duplicaron movimientos.');

                return;
            }

            $this->limpiarCorrida();
        }

        $this->resolveIds();

        DB::connection('pgsql')->beginTransaction();
        try {
            $this->ensureCanonicalMovementTypes();
            $this->seedApertura();
            $this->seedRecepciones($receptionSvc);
            $this->seedProduccion($productionSvc);
            $this->seedTraspaso($transferSvc);
            $this->seedConteo($countSvc);
            $this->seedPosConsumo($modifierSvc, $uomSvc);

            DB::connection('pgsql')->commit();
            $this->command?->info('✅ TransactionalFlowSeeder completado.');
        } catch (\Throwable $e) {
            DB::connection('pgsql')->rollBack();
            $this->command?->error('❌ TransactionalFlowSeeder falló: '.$e->getMessage());
            throw $e;
        }
    }

    private function resolveUserId(): void
    {
        $query = DB::connection('pgsql')->table('selemti.users')->orderBy('id');

        if (Schema::connection('pgsql')->hasColumn('selemti.users', 'activo')) {
            $query->where('activo', true);
        }

        $this->userId = (int) $query->value('id');

        if (! $this->userId) {
            throw new \RuntimeException('No hay usuarios activos en selemti.users. Ejecutar UsersSeeder primero.');
        }
    }

    private function hasPreviousRun(): bool
    {
        return DB::connection('pgsql')
            ->table('selemti.mov_inv')
            ->where('tipo', 'APERTURA')
            ->exists();
    }

    private function limpiarCorrida(): void
    {
        DB::connection('pgsql')->transaction(function (): void {
            $productionOrderIds = DB::connection('pgsql')
                ->table('selemti.production_orders')
                ->where('notas', 'like', 'Corrida E2E%')
                ->pluck('id');

            $transferIds = DB::connection('pgsql')
                ->table('selemti.traspaso_cab')
                ->whereRaw('meta::text like ?', ['%E2E_SEEDER%'])
                ->pluck('id');

            $countIds = DB::connection('pgsql')
                ->table('selemti.inventory_counts')
                ->where('notas', 'like', 'Conteo E2E%')
                ->orWhere('notas', 'like', 'Corrida E2E%')
                ->pluck('id');

            $receptionIds = DB::connection('pgsql')
                ->table('selemti.recepcion_cab')
                ->whereRaw('meta::text like ?', ['%E2E_SEEDER%'])
                ->pluck('id');

            DB::connection('pgsql')
                ->table('selemti.pos_ticket_item_processed')
                ->where('user_id', $this->userId)
                ->whereBetween('ticket_id', [self::SYNTHETIC_TICKET_ID, self::SYNTHETIC_TICKET_ID + 1000])
                ->delete();

            DB::connection('pgsql')
                ->table('selemti.mov_inv')
                ->where('ref_tipo', self::REF_E2E)
                ->delete();

            DB::connection('pgsql')
                ->table('selemti.mov_inv')
                ->where('ref_tipo', 'POS_TICKET')
                ->whereBetween('ref_id', [self::SYNTHETIC_TICKET_ID, self::SYNTHETIC_TICKET_ID + 1000])
                ->delete();

            if ($productionOrderIds->isNotEmpty()) {
                DB::connection('pgsql')->table('selemti.mov_inv')
                    ->where('ref_tipo', 'production_order')
                    ->whereIn('ref_id', $productionOrderIds)
                    ->delete();
                DB::connection('pgsql')->table('selemti.inventory_wastes')->whereIn('production_order_id', $productionOrderIds)->delete();
                DB::connection('pgsql')->table('selemti.production_order_inputs')->whereIn('production_order_id', $productionOrderIds)->delete();
                DB::connection('pgsql')->table('selemti.production_order_outputs')->whereIn('production_order_id', $productionOrderIds)->delete();
                DB::connection('pgsql')->table('selemti.production_orders')->whereIn('id', $productionOrderIds)->delete();
            }

            if ($transferIds->isNotEmpty()) {
                DB::connection('pgsql')->table('selemti.mov_inv')
                    ->where('ref_tipo', 'traspaso')
                    ->whereIn('ref_id', $transferIds)
                    ->delete();
                DB::connection('pgsql')->table('selemti.traspaso_det')->whereIn('traspaso_id', $transferIds)->delete();
                DB::connection('pgsql')->table('selemti.traspaso_cab')->whereIn('id', $transferIds)->delete();
            }

            if ($countIds->isNotEmpty()) {
                DB::connection('pgsql')->table('selemti.mov_inv')
                    ->where('ref_tipo', 'inventory_count')
                    ->whereIn('ref_id', $countIds)
                    ->delete();
                DB::connection('pgsql')->table('selemti.inventory_count_lines')->whereIn('inventory_count_id', $countIds)->delete();
                DB::connection('pgsql')->table('selemti.inventory_counts')->whereIn('id', $countIds)->delete();
            }

            if ($receptionIds->isNotEmpty()) {
                DB::connection('pgsql')->table('selemti.mov_inv')
                    ->where('ref_tipo', 'recepcion')
                    ->whereIn('ref_id', $receptionIds)
                    ->delete();
                DB::connection('pgsql')->table('selemti.recepcion_det')->whereIn('recepcion_id', $receptionIds)->delete();
                DB::connection('pgsql')->table('selemti.recepcion_cab')->whereIn('id', $receptionIds)->delete();
            }

            DB::connection('pgsql')
                ->table('selemti.inventory_batch')
                ->where(function ($query): void {
                    $query->where('lote_proveedor', 'like', 'E2E-%')
                        ->orWhere('lote_proveedor', 'like', 'APERTURA-%');
                })
                ->delete();
        });
    }

    private function resolveIds(): void
    {
        $this->sucursalId = (int) DB::connection('pgsql')
            ->table('selemti.cat_sucursales')->where('clave', 'SUC-01')->value('id');

        $almacenes = DB::connection('pgsql')
            ->table('selemti.cat_almacenes')
            ->where('sucursal_id', $this->sucursalId)
            ->pluck('id', 'clave');

        $this->almGenId = (int) ($almacenes['ALM-GEN'] ?? 0);
        $this->almCocId = (int) ($almacenes['ALM-COC'] ?? 0);

        if (! $this->sucursalId || ! $this->almGenId || ! $this->almCocId) {
            throw new \RuntimeException('MasterDataSeeder debe ejecutarse antes (faltan sucursal/almacenes).');
        }

        $rows = DB::connection('pgsql')
            ->table('selemti.items as i')
            ->leftJoin('selemti.cat_unidades as ub', 'ub.id', '=', 'i.unidad_medida_id')
            ->leftJoin('selemti.cat_unidades as uc', 'uc.id', '=', 'i.unidad_compra_id')
            ->select('i.id', 'i.codigo', 'ub.clave as uom_base', 'uc.clave as uom_compra', 'i.factor_compra')
            ->get();

        foreach ($rows as $row) {
            $this->items[(int) $row->id] = [
                'codigo' => $row->codigo,
                'uom_base' => $row->uom_base ?? 'KG',
                'uom_compra' => $row->uom_compra ?? $row->uom_base ?? 'KG',
                'factor_compra' => (float) ($row->factor_compra ?? 1),
            ];
        }

        if (empty($this->items)) {
            throw new \RuntimeException('No hay items en selemti.items; ejecute MasterDataSeeder primero.');
        }

        $this->provIds = DB::connection('pgsql')
            ->table('selemti.cat_proveedores')
            ->pluck('id', 'rfc')
            ->toArray();

        $this->command?->info("  ➜ IDs resueltos: SUC={$this->sucursalId} ALM-GEN={$this->almGenId} ALM-COC={$this->almCocId} USER={$this->userId}");
    }

    private function ensureCanonicalMovementTypes(): void
    {
        $types = [
            ['clave' => 'RECEPCION_COMPRA', 'descripcion' => 'Entrada por recepción de orden de compra', 'signo' => 1, 'afecta_costo' => true],
            ['clave' => 'PRODUCCION_ENTRADA', 'descripcion' => 'Entrada de producto elaborado a inventario', 'signo' => 1, 'afecta_costo' => true],
            ['clave' => 'TRASPASO_ENTRADA', 'descripcion' => 'Entrada por traspaso entre almacenes', 'signo' => 1, 'afecta_costo' => false],
            ['clave' => 'AJUSTE_ENTRADA', 'descripcion' => 'Ajuste positivo por conteo físico', 'signo' => 1, 'afecta_costo' => true],
            ['clave' => 'APERTURA', 'descripcion' => 'Carga inicial de inventario', 'signo' => 1, 'afecta_costo' => true],
            ['clave' => 'PRODUCCION_SALIDA', 'descripcion' => 'Salida de materia prima para producción', 'signo' => -1, 'afecta_costo' => true],
            ['clave' => 'VENTA_POS', 'descripcion' => 'Salida de inventario por venta POS', 'signo' => -1, 'afecta_costo' => true],
            ['clave' => 'TRASPASO_SALIDA', 'descripcion' => 'Salida por traspaso entre almacenes', 'signo' => -1, 'afecta_costo' => false],
            ['clave' => 'AJUSTE_SALIDA', 'descripcion' => 'Ajuste negativo por conteo físico', 'signo' => -1, 'afecta_costo' => true],
            ['clave' => 'MERMA', 'descripcion' => 'Merma operativa o de producción', 'signo' => -1, 'afecta_costo' => true],
        ];

        foreach ($types as $type) {
            DB::connection('pgsql')->table('selemti.cat_tipo_mov_inv')->updateOrInsert(
                ['clave' => $type['clave']],
                $type + ['activo' => true]
            );
        }
    }

    private function seedApertura(): void
    {
        // First 6 items + INS-1020 (Aceite), INS-1021 (Tortilla), INS-1022 (Masa)
        $baseItems = array_slice($this->items, 0, 6, true);
        $extraIds  = array_intersect_key($this->items, array_flip([1020, 1021, 1022]));
        $aperItems = $baseItems + $extraIds;

        foreach ($aperItems as $itemId => $meta) {
            $qty = 100.0;

            $batchId = (int) DB::connection('pgsql')->table('selemti.inventory_batch')->insertGetId([
                'item_id' => (string) $itemId,
                'lote_proveedor' => 'E2E-APERTURA-'.strtoupper(Str::random(6)),
                'cantidad_original' => $qty,
                'cantidad_actual' => $qty,
                'uom_base' => $meta['uom_base'],
                'estado' => 'DISPONIBLE',
                'sucursal_id' => (string) $this->sucursalId,
                'almacen_id' => (string) $this->almGenId,
                'created_at' => $this->now,
                'updated_at' => $this->now,
            ]);

            DB::connection('pgsql')->table('selemti.mov_inv')->insert([
                'item_id' => (string) $itemId,
                'inventory_batch_id' => $batchId,
                'tipo' => 'APERTURA',
                'qty' => $qty,
                'cantidad' => $qty,
                'uom' => $meta['uom_base'],
                'sucursal_id' => (string) $this->sucursalId,
                'almacen_id' => (string) $this->almGenId,
                'ref_tipo' => self::REF_E2E,
                'ref_id' => crc32('apertura'),
                'user_id' => $this->userId,
                'usuario_id' => $this->userId,
                'ts' => $this->now,
                'meta' => json_encode(['step' => 'apertura']),
                'created_at' => $this->now,
                'updated_at' => $this->now,
            ]);
        }

        $this->command?->info('  ➜ Apertura: '.count($aperItems).' lotes iniciales.');
    }

    private function seedRecepciones(ReceptionService $svc): void
    {
        $provIds = array_values($this->provIds);
        if (empty($provIds)) {
            throw new \RuntimeException('No hay proveedores; ejecute MasterDataSeeder primero.');
        }

        $recepciones = [
            ['proveedor_id' => $provIds[0], 'lines' => $this->recepcionLines([1001, 1002, 1003, 1004], [10, 15, 20, 8])],
            ['proveedor_id' => $provIds[count($provIds) > 1 ? 1 : 0], 'lines' => $this->recepcionLines([1005, 1006, 1007, 1008], [5, 12, 30, 10])],
        ];

        foreach ($recepciones as $rec) {
            $recId = $svc->createDraftReception([
                'supplier_id' => $rec['proveedor_id'],
                'branch_id' => $this->sucursalId,
                'warehouse_id' => $this->almGenId,
                'user_id' => $this->userId,
                'meta' => ['source' => self::REF_E2E],
            ], $rec['lines']);

            $svc->validateReception($recId, $this->userId);
            $svc->postReception($recId, $this->userId);
        }

        $this->command?->info('  ➜ Recepciones: '.count($recepciones).' posteadas.');
    }

    private function recepcionLines(array $itemIds, array $qtys): array
    {
        $lines = [];
        foreach ($itemIds as $i => $rawId) {
            $meta = $this->items[$rawId] ?? null;
            if (! $meta) {
                continue;
            }

            $lines[] = [
                'item_id' => (string) $rawId,
                'qty_pack' => $qtys[$i],
                'pack_size' => 1,
                'uom_purchase' => $meta['uom_compra'],
                'uom_base' => $meta['uom_base'],
                'costo_unit' => 50.00,
                'lot' => 'E2E-RECEP-'.strtoupper(Str::random(6)),
                'meta' => ['source' => self::REF_E2E],
            ];
        }

        return $lines;
    }

    private function seedProduccion(ProductionService $svc): void
    {
        $data = require __DIR__.'/RestaurantDataArrays.php';
        $recetasProd = array_values(array_filter(
            $data['recetas'],
            fn (array $receta): bool => str_starts_with($receta['tipo'], 'PROD_')
        ));

        $itemIdsByCode = DB::connection('pgsql')->table('selemti.items')->pluck('id', 'codigo');
        $recipeIdsByCode = DB::connection('pgsql')->table('selemti.recipes')->pluck('id', 'codigo');
        $ordenes = 0;

        foreach ($recetasProd as $receta) {
            $itemProducidoCodigo = $receta['item_producido_codigo'] ?? $receta['item_producido'] ?? null;
            $outputItemId = $itemProducidoCodigo ? (int) ($itemIdsByCode[$itemProducidoCodigo] ?? 0) : 0;
            $recipeId = (int) ($recipeIdsByCode[$receta['codigo']] ?? 0);

            if (! $itemProducidoCodigo || ! $outputItemId || ! $recipeId || ! isset($this->items[$outputItemId])) {
                $this->command?->warn("  ⚠ Receta {$receta['codigo']} sin output producible válido.");

                continue;
            }

            $inputs = [];
            foreach ($receta['ingredientes'] as $ing) {
                $itemId = (int) ($itemIdsByCode[$ing['item_codigo']] ?? 0);
                if (! $itemId || ! isset($this->items[$itemId])) {
                    continue;
                }

                $batch = DB::connection('pgsql')
                    ->table('selemti.inventory_batch')
                    ->where('item_id', (string) $itemId)
                    ->where('cantidad_actual', '>', 0)
                    ->orderBy('created_at')
                    ->first();

                $inputs[] = [
                    'item_id' => $itemId,
                    'qty' => (float) $ing['qty'],
                    'uom' => $ing['uom'] ?? $this->items[$itemId]['uom_base'],
                    'inventory_batch_id' => $batch?->id,
                    'meta' => ['source' => self::REF_E2E],
                ];
            }

            if (empty($inputs)) {
                continue;
            }

            $outputMeta = $this->items[$outputItemId];
            $svc->createOrder(
                [
                    'recipe_id' => $recipeId,
                    'item_id' => $outputItemId,
                    'scheduled_qty' => (float) $receta['porciones'],
                    'uom' => $receta['uom_salida'] ?? $outputMeta['uom_base'],
                    'branch_id' => (string) $this->sucursalId,
                    'warehouse_id' => (string) $this->almGenId,
                    'scheduled_at' => now()->toDateString(),
                    'user_id' => $this->userId,
                    'notes' => 'Corrida E2E — '.$receta['nombre'],
                    'meta' => ['source' => self::REF_E2E, 'item_producido_codigo' => $itemProducidoCodigo],
                ],
                $inputs,
                [[
                    'item_id' => $outputItemId,
                    'qty' => (float) $receta['porciones'],
                    'uom' => $receta['uom_salida'] ?? $outputMeta['uom_base'],
                    'lot' => 'E2E-PROD-'.$itemProducidoCodigo,
                    'meta' => ['source' => self::REF_E2E],
                ]],
                [[
                    'item_id' => $outputItemId,
                    'qty' => 0.01,
                    'uom' => $receta['uom_salida'] ?? $outputMeta['uom_base'],
                    'reason' => 'Merma E2E',
                    'meta' => ['source' => self::REF_E2E],
                ]]
            );
            $ordenes++;
        }

        $this->assertProducedStock();
        $this->command?->info("  ➜ Producción: {$ordenes} órdenes creadas.");
    }

    private function assertProducedStock(): void
    {
        $missing = DB::connection('pgsql')
            ->table('selemti.items as i')
            ->leftJoin('selemti.inventory_batch as b', function ($join): void {
                $join->on('b.item_id', '=', 'i.id')
                    ->where('b.cantidad_actual', '>', 0);
            })
            ->whereBetween('i.item_code', ['PROD-001', 'PROD-009'])
            ->groupBy('i.item_code')
            ->havingRaw('COALESCE(SUM(b.cantidad_actual), 0) <= 0')
            ->pluck('i.item_code');

        if ($missing->isNotEmpty()) {
            throw new \RuntimeException('Producción E2E no generó stock para: '.$missing->implode(', '));
        }
    }

    private function seedTraspaso(TransferService $svc): void
    {
        $batches = DB::connection('pgsql')
            ->table('selemti.inventory_batch')
            ->where('almacen_id', (string) $this->almGenId)
            ->where('cantidad_actual', '>', 5)
            ->limit(3)
            ->get(['item_id', 'id', 'cantidad_actual', 'uom_base']);

        if ($batches->isEmpty()) {
            $this->command?->warn('  ⚠ Sin stock en ALM-GEN para traspasar; omitiendo traspaso.');

            return;
        }

        $result = $svc->createTransfer(
            $this->almGenId,
            $this->almCocId,
            $batches->map(fn ($b) => ['item_id' => (int) $b->item_id, 'qty_requested' => 5.0])->all(),
            $this->userId
        );
        $transferId = $result['transfer_id'];

        DB::connection('pgsql')
            ->table('selemti.traspaso_det')
            ->where('traspaso_id', $transferId)
            ->update(['cantidad_recibida' => DB::raw('qty'), 'cantidad_despachada' => DB::raw('qty')]);

        DB::connection('pgsql')
            ->table('selemti.traspaso_cab')
            ->where('id', $transferId)
            ->update([
                'estado' => 'RECIBIDA',
                'validada_por' => $this->userId,
                'recibida_por' => $this->userId,
                'meta' => json_encode(['source' => self::REF_E2E]),
                'updated_at' => now(),
            ]);

        $svc->postTransferToInventory($transferId, $this->userId);
        $this->command?->info("  ➜ Traspaso #{$transferId}: {$batches->count()} líneas ALM-GEN → ALM-COC.");
    }

    private function seedConteo(InventoryCountService $svc): void
    {
        $count = $svc->createCount([
            'sucursal_id' => $this->sucursalId,
            'almacen_id' => $this->almGenId,
            'programado_para' => now()->toDateString(),
            'notes' => 'Conteo E2E corrida inicial',
            'meta' => ['source' => self::REF_E2E],
        ], $this->userId);

        $batches = DB::connection('pgsql')
            ->table('selemti.inventory_batch')
            ->where('almacen_id', (string) $this->almGenId)
            ->where('cantidad_actual', '>', 0)
            ->limit(4)
            ->get(['item_id', 'id', 'cantidad_actual', 'uom_base']);

        if ($batches->isEmpty()) {
            $this->command?->warn('  ⚠ Sin lotes en ALM-GEN para conteo físico; omitiendo conteo.');

            return;
        }

        $lines = $batches->map(fn ($b) => [
            'item_id' => (string) $b->item_id,
            'inventory_batch_id' => $b->id,
            'qty_contada' => (float) $b->cantidad_actual + 2.0,
            'qty_teorica' => (float) $b->cantidad_actual,
            'uom' => $b->uom_base,
            'motivo' => 'Diferencia ajuste E2E',
            'source' => self::REF_E2E,
        ])->all();

        $svc->finalize($count->id, $lines, $this->userId, 'Corrida E2E — conteo inicial');
        $this->command?->info('  ➜ Conteo #'.$count->id.': '.count($lines).' líneas ajustadas en ALM-GEN.');
    }

    private function seedPosConsumo(PosModifierService $modifierSvc, UomConversionService $uomSvc): void
    {
        $modifierSvc->clearCache();

        $menuMappings = DB::connection('pgsql')
            ->table('selemti.pos_menu_item_recipe_mapping')
            ->where('activo', true)
            ->orderBy('menu_item_id')
            ->get();

        if ($menuMappings->isEmpty()) {
            $this->command?->warn('  ⚠ No hay pos_menu_item_recipe_mapping; omitiendo POS.');

            return;
        }

        $modifierMappings = DB::connection('pgsql')
            ->table('selemti.pos_modifier_inv_mapping')
            ->where('activo', true)
            ->whereNotNull('item_id')
            ->get();

        $adicional = $modifierMappings->first(fn ($m) => $m->tipo_efecto === 'ADICIONAL' && (float) $m->qty_por_unidad > 0);
        $selector = $modifierMappings->first(fn ($m) => $m->tipo_efecto === 'SELECTOR' && (float) $m->qty_por_unidad > 0);
        $totalMovimientos = 0;
        $ticketId = self::SYNTHETIC_TICKET_ID;

        foreach ($menuMappings as $index => $mapping) {
            $ticketItemId = ($ticketId * 10) + 1;
            $syntheticItems = [
                $ticketId => [
                    (object) ['id' => $ticketItemId, 'item_id' => $mapping->menu_item_id, 'item_count' => 2],
                ],
            ];
            $syntheticModifiers = [];

            $modifier = match ($index % 3) {
                1 => $adicional,
                2 => $selector,
                default => null,
            };

            if ($modifier) {
                $syntheticModifiers[$ticketItemId] = [
                    (object) [
                        'id' => 1,
                        'item_id' => $modifier->menu_modifier_id,
                        'item_count' => 1,
                        'modifier_name' => $modifier->modifier_name_trim,
                    ],
                ];
            }

            $svc = new SyntheticPosConsumptionService($modifierSvc, $uomSvc, $syntheticItems, $syntheticModifiers);
            $summary = $svc->confirmTicket(
                ticketId: $ticketId,
                userId: $this->userId,
                sucursalId: (string) $this->sucursalId,
                almacenId: (string) $this->almGenId
            );

            $totalMovimientos += $summary['recipe_movements'] + $summary['modifier_movements'];
            foreach ($summary['warnings'] as $warning) {
                $this->command?->warn("  ⚠ Ticket {$ticketId}: {$warning}");
            }

            $ticketId++;
        }

        $this->command?->info("  ➜ POS consumo: {$menuMappings->count()} tickets → {$totalMovimientos} movimientos VENTA_POS.");
    }
}

class SyntheticPosConsumptionService extends PosConsumptionService
{
    public function __construct(
        PosModifierService $modifierService,
        UomConversionService $uomService,
        private readonly array $syntheticItems,
        private readonly array $syntheticModifiers,
    ) {
        parent::__construct($modifierService, $uomService);
    }

    protected function ticketItemsForProcessing(int $ticketId): Collection
    {
        return collect($this->syntheticItems[$ticketId] ?? []);
    }

    protected function modifiersForTicketItem(int $ticketItemId): Collection
    {
        return collect($this->syntheticModifiers[$ticketItemId] ?? []);
    }

    protected function dispatchIngestedEvent(int $ticketId): void {}
}
