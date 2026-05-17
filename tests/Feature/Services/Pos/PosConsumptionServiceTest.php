<?php

namespace Tests\Feature\Services\Pos;

use App\Services\Inventory\PosConsumptionService;
use App\Services\Inventory\UomConversionService;
use App\Services\Pos\PosModifierService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class PosConsumptionServiceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        app(PosModifierService::class)->clearCache();
    }

    public function test_confirms_ticket_deducts_base_recipe_ingredients(): void
    {
        $recipeId = $this->createRecipeWithIngredient('BASE-REC', '1001', 0.5);
        $this->createItem('1001');
        $this->createBatch('1001', 10);

        DB::connection('pgsql')->table('selemti.pos_menu_item_recipe_mapping')->insert([
            'menu_item_id' => 77,
            'menu_item_name' => 'Taco',
            'recipe_id' => $recipeId,
            'porciones_por_orden' => 2,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $service = $this->serviceWithTicketItems([
            (object) ['id' => 501, 'item_id' => 77, 'item_count' => 3],
        ]);

        $summary = $service->confirmTicket(9001, userId: 10);

        $this->assertSame(1, $summary['ticket_items_processed']);
        $this->assertSame(1, $summary['recipe_movements']);
        $this->assertDatabaseHas('selemti.mov_inv', [
            'item_id' => '1001',
            'tipo' => 'VENTA_POS',
            'qty' => -3.0,
            'ref_tipo' => 'POS_TICKET',
            'ref_id' => 9001,
        ]);
        $this->assertSame('7.000000', DB::connection('pgsql')->table('selemti.inventory_batch')->where('item_id', '1001')->value('cantidad_actual'));
    }

    public function test_confirms_ticket_deducts_modifier_items(): void
    {
        $this->createItem('2001');
        $this->createBatch('2001', 5);
        $this->createModifierMapping(menuModifierId: 333, itemId: '2001', qty: 0.25);

        $service = $this->serviceWithTicketItems(
            [(object) ['id' => 601, 'item_id' => 88, 'item_count' => 1]],
            [601 => [(object) ['id' => 1, 'item_id' => 333, 'item_count' => 4, 'modifier_name' => 'Extra salsa']]]
        );

        $summary = $service->confirmTicket(9002, userId: 10);

        $this->assertSame(1, $summary['modifier_movements']);
        $this->assertDatabaseHas('selemti.mov_inv', [
            'item_id' => '2001',
            'tipo' => 'VENTA_POS',
            'qty' => -1.0,
            'ref_id' => 9002,
        ]);
    }

    public function test_confirms_ticket_skips_null_mapping(): void
    {
        $service = $this->serviceWithTicketItems(
            [(object) ['id' => 701, 'item_id' => 99, 'item_count' => 1]],
            [701 => [(object) ['id' => 1, 'item_id' => 9999, 'item_count' => 1, 'modifier_name' => 'Sin mapping']]]
        );

        $summary = $service->confirmTicket(9003, userId: 10);

        $this->assertSame(1, $summary['ticket_items_processed']);
        $this->assertSame(0, $summary['modifier_movements']);
        $this->assertDatabaseCount('selemti.mov_inv', 0);
    }

    public function test_modifier_qty_source_recipe_derives_from_recipe(): void
    {
        $modifierRecipeId = $this->createRecipeWithIngredient('MOD-REC', '3002', 0.75);
        DB::connection('pgsql')->table('selemti.recipe_version_items')->insert([
            'recipe_version_id' => DB::connection('pgsql')->table('selemti.recipe_versions')->where('recipe_id', $modifierRecipeId)->value('id'),
            'item_id' => '3003',
            'qty' => 0.25,
            'uom_receta' => 'KG',
        ]);

        $this->createItem('3001');
        $this->createBatch('3001', 10);
        $this->createModifierMapping(menuModifierId: 444, itemId: '3001', qty: 99, qtySource: 'RECIPE', recipeId: $modifierRecipeId);

        $service = $this->serviceWithTicketItems(
            [(object) ['id' => 801, 'item_id' => 123, 'item_count' => 1]],
            [801 => [(object) ['id' => 1, 'item_id' => 444, 'item_count' => 2, 'modifier_name' => 'Doble queso']]]
        );

        $summary = $service->confirmTicket(9004, userId: 10);

        $this->assertSame(1, $summary['modifier_movements']);
        $this->assertDatabaseHas('selemti.mov_inv', [
            'item_id' => '3001',
            'qty' => -2.0,
            'ref_id' => 9004,
        ]);
    }

    public function test_selector_modifier_replaces_base_recipe_slot_with_same_uom(): void
    {
        $recipeId = $this->createRecipeWithIngredient('SEL-REC', '4001', 0.2, 'KG');
        $this->createItem('4001', 'KG');
        $this->createItem('4002', 'KG');
        $this->createBatch('4001', 10, 'KG');
        $this->createBatch('4002', 10, 'KG');
        $this->createMenuMapping(901, $recipeId);
        $this->createModifierMapping(menuModifierId: 9011, itemId: '4002', qty: 0.2, tipoEfecto: 'SELECTOR', uom: 'KG');

        $service = $this->serviceWithTicketItems(
            [(object) ['id' => 90101, 'item_id' => 901, 'item_count' => 1]],
            [90101 => [(object) ['id' => 1, 'item_id' => 9011, 'item_count' => 1, 'modifier_name' => 'Selector salsa']]]
        );

        $summary = $service->confirmTicket(9101, userId: 10);

        $this->assertSame(0, $summary['recipe_movements']);
        $this->assertSame(1, $summary['modifier_movements']);
        $this->assertDatabaseHas('selemti.mov_inv', [
            'item_id' => '4002',
            'qty' => -0.2,
            'ref_id' => 9101,
        ]);
        $this->assertDatabaseMissing('selemti.mov_inv', [
            'item_id' => '4001',
            'ref_id' => 9101,
        ]);
    }

    public function test_adicional_modifier_sums_on_top_of_base_recipe(): void
    {
        $recipeId = $this->createRecipeWithIngredient('ADD-REC', '4101', 0.1, 'KG');
        $this->createItem('4101', 'KG');
        $this->createBatch('4101', 10, 'KG');
        $this->createMenuMapping(902, $recipeId);
        $this->createModifierMapping(menuModifierId: 9021, itemId: '4101', qty: 0.05, tipoEfecto: 'ADICIONAL', uom: 'KG');

        $service = $this->serviceWithTicketItems(
            [(object) ['id' => 90201, 'item_id' => 902, 'item_count' => 1]],
            [90201 => [(object) ['id' => 1, 'item_id' => 9021, 'item_count' => 1, 'modifier_name' => 'Extra base']]]
        );

        $summary = $service->confirmTicket(9102, userId: 10);
        $total = DB::connection('pgsql')->table('selemti.mov_inv')
            ->where('ref_id', 9102)
            ->where('item_id', '4101')
            ->sum('qty');

        $this->assertSame(1, $summary['recipe_movements']);
        $this->assertSame(1, $summary['modifier_movements']);
        $this->assertEquals(-0.15, (float) $total);
    }

    public function test_selector_define_mapping_without_recipe_consumes_only_selector(): void
    {
        $this->createItem('4201', 'PZ');
        $this->createBatch('4201', 10, 'PZ');
        $this->createMenuMapping(903, null);
        $this->createModifierMapping(menuModifierId: 9031, itemId: '4201', qty: 1, tipoEfecto: 'SELECTOR', uom: 'PZ');

        $service = $this->serviceWithTicketItems(
            [(object) ['id' => 90301, 'item_id' => 903, 'item_count' => 1]],
            [90301 => [(object) ['id' => 1, 'item_id' => 9031, 'item_count' => 2, 'modifier_name' => 'Relleno']]]
        );

        $summary = $service->confirmTicket(9103, userId: 10);

        $this->assertSame(0, $summary['recipe_movements']);
        $this->assertSame(1, $summary['modifier_movements']);
        $this->assertDatabaseHas('selemti.mov_inv', [
            'item_id' => '4201',
            'qty' => -2.0,
            'ref_id' => 9103,
        ]);
        $this->assertSame(1, DB::connection('pgsql')->table('selemti.mov_inv')->where('ref_id', 9103)->count());
    }

    public function test_selector_with_different_uom_does_not_replace_base_slot(): void
    {
        $recipeId = $this->createRecipeWithIngredient('SEL-FALLBACK-REC', '4301', 0.3, 'KG');
        $this->createItem('4301', 'KG');
        $this->createItem('4302', 'PZ');
        $this->createBatch('4301', 10, 'KG');
        $this->createBatch('4302', 10, 'PZ');
        $this->createMenuMapping(904, $recipeId);
        $this->createModifierMapping(menuModifierId: 9041, itemId: '4302', qty: 1, tipoEfecto: 'SELECTOR', uom: 'PZ');

        $service = $this->serviceWithTicketItems(
            [(object) ['id' => 90401, 'item_id' => 904, 'item_count' => 1]],
            [90401 => [(object) ['id' => 1, 'item_id' => 9041, 'item_count' => 1, 'modifier_name' => 'Selector pieza']]]
        );

        $summary = $service->confirmTicket(9104, userId: 10);

        $this->assertSame(1, $summary['recipe_movements']);
        $this->assertSame(1, $summary['modifier_movements']);
        $this->assertDatabaseHas('selemti.mov_inv', [
            'item_id' => '4301',
            'qty' => -0.3,
            'ref_id' => 9104,
        ]);
        $this->assertDatabaseHas('selemti.mov_inv', [
            'item_id' => '4302',
            'qty' => -1.0,
            'ref_id' => 9104,
        ]);
    }

    private function serviceWithTicketItems(array $ticketItems, array $modifiersByTicketItem = []): PosConsumptionService
    {
        return new class(app(PosModifierService::class), app(UomConversionService::class), $ticketItems, $modifiersByTicketItem) extends PosConsumptionService
        {
            public function __construct(
                PosModifierService $modifierService,
                UomConversionService $uomService,
                private readonly array $ticketItems,
                private readonly array $modifiersByTicketItem,
            ) {
                parent::__construct($modifierService, $uomService);
            }

            protected function ticketItemsForProcessing(int $ticketId): Collection
            {
                return collect($this->ticketItems);
            }

            protected function modifiersForTicketItem(int $ticketItemId): Collection
            {
                return collect($this->modifiersByTicketItem[$ticketItemId] ?? []);
            }

            protected function dispatchIngestedEvent(int $ticketId): void {}
        };
    }

    private function createItem(string $itemId, string $uom = 'KG'): void
    {
        DB::connection('pgsql')->table('selemti.items')->insert([
            'id' => $itemId,
            'item_code' => 'IT-'.$itemId,
            'nombre' => 'Item '.$itemId,
            'unidad_medida' => $uom,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function createBatch(string $itemId, float $qty, string $uom = 'KG'): void
    {
        DB::connection('pgsql')->table('selemti.inventory_batch')->insert([
            'item_id' => $itemId,
            'lote_proveedor' => 'L-'.$itemId,
            'cantidad_original' => $qty,
            'cantidad_actual' => $qty,
            'uom_base' => $uom,
            'caducidad' => now()->addDays(7)->toDateString(),
            'estado' => 'ACTIVO',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function createRecipeWithIngredient(string $code, string $itemId, float $qty, string $uom = 'KG'): int
    {
        $recipeId = (int) DB::connection('pgsql')->table('selemti.recipes')->insertGetId([
            'codigo' => $code,
            'nombre' => 'Recipe '.$code,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $versionId = (int) DB::connection('pgsql')->table('selemti.recipe_versions')->insertGetId([
            'recipe_id' => $recipeId,
            'version_no' => 1,
            'valid_from' => now(),
            'valid_to' => null,
            'created_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.recipe_version_items')->insert([
            'recipe_version_id' => $versionId,
            'item_id' => $itemId,
            'qty' => $qty,
            'uom_receta' => $uom,
        ]);

        return $recipeId;
    }

    private function createMenuMapping(int $menuItemId, ?int $recipeId): void
    {
        DB::connection('pgsql')->table('selemti.pos_menu_item_recipe_mapping')->insert([
            'menu_item_id' => $menuItemId,
            'menu_item_name' => 'Menu '.$menuItemId,
            'recipe_id' => $recipeId,
            'porciones_por_orden' => 1,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function createModifierMapping(
        int $menuModifierId,
        string $itemId,
        float $qty,
        string $qtySource = 'MANUAL',
        ?int $recipeId = null,
        string $tipoEfecto = 'ADICIONAL',
        string $uom = 'KG',
    ): void {
        DB::connection('pgsql')->table('selemti.pos_modifier_inv_mapping')->insert([
            'menu_modifier_id' => $menuModifierId,
            'modifier_name_trim' => 'Modifier '.$menuModifierId,
            'item_id' => $itemId,
            'qty_por_unidad' => $qty,
            'uom' => $uom,
            'qty_source' => $qtySource,
            'recipe_id' => $recipeId,
            'tipo_efecto' => $tipoEfecto,
            'afecta_costo' => true,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
