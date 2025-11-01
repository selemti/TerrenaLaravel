<?php

namespace Tests\Feature;

use App\Models\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use App\Models\Rec\RecetaVersion;
use App\Models\Rec\RecipeCostSnapshot;
use App\Services\Recipes\RecipeCostSnapshotService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Support\InteractsWithRecipeDatabase;
use Tests\TestCase;

class RecipeCostSnapshotTest extends TestCase
{
    use InteractsWithRecipeDatabase;

    private RecipeCostSnapshotService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->setUpRecipeDatabase();
        $this->service = app(RecipeCostSnapshotService::class);

        DB::table('users')->insert([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function test_it_creates_manual_snapshot(): void
    {
        $recipe = Receta::factory()->create([
            'id' => 'REC-TEST-001',
            'porciones_standard' => 2,
        ]);

        $version = $this->createVersion($recipe);

        $item1 = Item::factory()->create([
            'id' => 'ITEM-001',
            'costo_promedio' => 50,
        ]);

        $item2 = Item::factory()->create([
            'id' => 'ITEM-002',
            'costo_promedio' => 30,
        ]);

        RecetaDetalle::create([
            'receta_version_id' => $version->id,
            'item_id' => $item1->id,
            'cantidad' => 1.5,
            'unidad_medida' => 'KG',
            'created_at' => now(),
        ]);

        RecetaDetalle::create([
            'receta_version_id' => $version->id,
            'item_id' => $item2->id,
            'cantidad' => 0.5,
            'unidad_medida' => 'KG',
            'created_at' => now(),
        ]);

        $snapshot = $this->service->createSnapshot(
            'REC-TEST-001',
            RecipeCostSnapshot::REASON_MANUAL,
            1
        );

        $this->assertInstanceOf(RecipeCostSnapshot::class, $snapshot);
        $this->assertEquals('REC-TEST-001', $snapshot->recipe_id);
        $this->assertEquals(RecipeCostSnapshot::REASON_MANUAL, $snapshot->reason);
        $this->assertEquals(1, $snapshot->created_by_user_id);
        $this->assertGreaterThan(0, (float) $snapshot->cost_total);
        $this->assertGreaterThan(0, (float) $snapshot->cost_per_portion);
    }

    public function test_it_retrieves_cost_from_snapshot(): void
    {
        $recipe = Receta::factory()->create([
            'id' => 'REC-TEST-002',
        ]);

        RecipeCostSnapshot::create([
            'recipe_id' => $recipe->id,
            'snapshot_date' => Carbon::parse('2025-10-15 10:00:00'),
            'cost_total' => 125.50,
            'cost_per_portion' => 62.75,
            'portions' => 2,
            'cost_breakdown' => [
                ['item_id' => 'ITEM-001', 'item_name' => 'Carne', 'total_cost' => 80.00],
                ['item_id' => 'ITEM-002', 'item_name' => 'Pan', 'total_cost' => 45.50],
            ],
            'reason' => RecipeCostSnapshot::REASON_MANUAL,
        ]);

        $costData = $this->service->getCostAtDate(
            'REC-TEST-002',
            Carbon::parse('2025-10-15 12:00:00')
        );

        $this->assertTrue($costData['from_snapshot']);
        $this->assertEquals(125.50, $costData['cost_total']);
        $this->assertEquals(62.75, $costData['cost_per_portion']);
        $this->assertCount(2, $costData['cost_breakdown']);
    }

    public function test_it_creates_automatic_snapshot_when_threshold_exceeded(): void
    {
        $recipe = Receta::factory()->create([
            'id' => 'REC-TEST-003',
            'porciones_standard' => 2,
        ]);

        $version = $this->createVersion($recipe);

        $item = Item::factory()->create([
            'id' => 'ITEM-003',
            'costo_promedio' => 100,
        ]);

        RecetaDetalle::create([
            'receta_version_id' => $version->id,
            'item_id' => $item->id,
            'cantidad' => 1,
            'unidad_medida' => 'PZ',
            'created_at' => now(),
        ]);

        $initialSnapshot = $this->service->createSnapshot(
            'REC-TEST-003',
            RecipeCostSnapshot::REASON_MANUAL
        );

        $oldCost = (float) $initialSnapshot->cost_total;
        $newCost = $oldCost * 1.05;

        $created = $this->service->checkAndCreateIfThresholdExceeded(
            'REC-TEST-003',
            $newCost
        );

        $this->assertTrue($created);

        $autoSnapshot = RecipeCostSnapshot::forRecipe('REC-TEST-003')
            ->where('reason', RecipeCostSnapshot::REASON_AUTO_THRESHOLD)
            ->first();

        $this->assertNotNull($autoSnapshot);
    }

    public function test_it_does_not_create_snapshot_when_threshold_not_exceeded(): void
    {
        $recipe = Receta::factory()->create([
            'id' => 'REC-TEST-004',
            'porciones_standard' => 2,
        ]);

        $version = $this->createVersion($recipe);

        $item = Item::factory()->create([
            'id' => 'ITEM-004',
            'costo_promedio' => 80,
        ]);

        RecetaDetalle::create([
            'receta_version_id' => $version->id,
            'item_id' => $item->id,
            'cantidad' => 1,
            'unidad_medida' => 'PZ',
            'created_at' => now(),
        ]);

        $initialSnapshot = $this->service->createSnapshot(
            'REC-TEST-004',
            RecipeCostSnapshot::REASON_MANUAL
        );

        $oldCost = (float) $initialSnapshot->cost_total;
        $newCost = $oldCost * 1.01;

        $created = $this->service->checkAndCreateIfThresholdExceeded(
            'REC-TEST-004',
            $newCost
        );

        $this->assertFalse($created);

        $count = RecipeCostSnapshot::forRecipe('REC-TEST-004')->count();
        $this->assertEquals(1, $count);
    }

    public function test_it_creates_snapshots_for_all_active_recipes(): void
    {
        $activeRecipes = Receta::factory()->count(3)->create(['activo' => true]);
        Receta::factory()->count(2)->create(['activo' => false]);

        foreach ($activeRecipes as $index => $recipe) {
            $version = $this->createVersion($recipe);

            $item = Item::factory()->create([
                'id' => 'ITEM-ACT-' . $index,
                'costo_promedio' => 20 + ($index * 5),
            ]);

            RecetaDetalle::create([
                'receta_version_id' => $version->id,
                'item_id' => $item->id,
                'cantidad' => 1,
                'unidad_medida' => 'PZ',
                'created_at' => now(),
            ]);
        }

        $count = $this->service->createSnapshotsForAllRecipes();

        $this->assertEquals(3, $count);
        $this->assertEquals(3, RecipeCostSnapshot::count());
    }

    private function createVersion(Receta $recipe): RecetaVersion
    {
        return RecetaVersion::create([
            'receta_id' => $recipe->id,
            'version' => 1,
            'descripcion_cambios' => 'Versión de prueba',
            'fecha_efectiva' => now()->toDateString(),
            'version_publicada' => false,
            'created_at' => now(),
        ]);
    }
}
