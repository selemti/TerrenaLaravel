<?php

namespace Tests\Feature;

use App\Adapters\FloreantPos\Dtos\PosMenuModifierDto;
use App\Adapters\FloreantPos\FloreantPosAdapter;
use App\Models\Caja\TicketItemModifier;
use App\Services\Inventory\InventoryMovementService;
use App\Services\Inventory\ModifierValidationService;
use Illuminate\Support\Facades\DB;
use Mockery;
use Tests\TestCase;

class ModifierConsistencyTest extends TestCase
{
    private array $createdRecetaIds = [];
    private array $createdMovInvIds = [];

    protected function tearDown(): void
    {
        if ($this->createdMovInvIds) {
            DB::connection('pgsql')->table('selemti.mov_inv')
                ->whereIn('id', $this->createdMovInvIds)->delete();
        }
        if ($this->createdRecetaIds) {
            DB::connection('pgsql')->table('selemti.receta_det')
                ->whereIn('receta_id', $this->createdRecetaIds)->delete();
            DB::connection('pgsql')->table('selemti.recetas')
                ->whereIn('id', $this->createdRecetaIds)->delete();
        }
        Mockery::close();
        parent::tearDown();
    }

    public function test_modifier_group_consistency(): void
    {
        $adapter = Mockery::mock(FloreantPosAdapter::class);
        $adapter->shouldReceive('getModifierGroupId')
            ->once()->with(2)->andReturn(3);

        $service = new ModifierValidationService($adapter);

        $this->assertSame(3, $service->getModifierGroup(2));
    }

    public function test_inventory_movement_uses_correct_group(): void
    {
        $recetaId = DB::connection('pgsql')->table('selemti.recetas')->insertGetId([
            'grupo_modificador_id' => 3,
            'nombre_modificador'   => 'Picadillo',
            'created_at'           => now(),
            'updated_at'           => now(),
        ]);
        $this->createdRecetaIds[] = $recetaId;

        DB::connection('pgsql')->table('selemti.receta_det')->insert([
            'receta_id'  => (string) $recetaId,
            'item_id'    => '500',
            'cantidad'   => 1,
            'orden'      => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $adapter = Mockery::mock(FloreantPosAdapter::class);
        $adapter->shouldReceive('getModifierWithGroup')
            ->once()->with(2)
            ->andReturn(new PosMenuModifierDto(id: 2, name: 'Picadillo', groupId: 3, groupName: 'Relleno Empanada'));

        $movementService = new InventoryMovementService(new ModifierValidationService($adapter));
        $movementId = $movementService->recordModifierMovement(2, 1, 'SALE', ['uom' => 'EA']);

        if ($movementId > 0) {
            $this->createdMovInvIds[] = $movementId;
        }

        $this->assertGreaterThan(0, $movementId);

        $movement = DB::connection('pgsql')->table('selemti.mov_inv')->where('id', $movementId)->first();
        $this->assertNotNull($movement);
        $this->assertSame('500', (string) $movement->item_id);
        $this->assertSame((string) $recetaId, (string) $movement->ref_id);
        $this->assertSame('MODIFIER_RECIPE', $movement->tipo);
    }

    public function test_miscellaneous_modifiers_are_considered_consistent(): void
    {
        $tim = new TicketItemModifier(['item_id' => 0, 'group_id' => 99]);

        $this->assertTrue($tim->is_consistent);
    }
}
