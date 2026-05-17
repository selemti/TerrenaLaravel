<?php

namespace Tests\Feature\Livewire\Inventory;

use App\Livewire\Inventory\KardexView;
use App\Models\Catalogs\Almacen;
use App\Models\Catalogs\Unidad;
use App\Models\Inv\Item;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Livewire\Livewire;
use Tests\TestCase;

class KardexViewTest extends TestCase
{
    use RefreshDatabase;

    public function test_kardex_view_renders_item_header_filters_and_movements(): void
    {
        $unit = Unidad::query()->create([
            'clave' => 'PZ',
            'nombre' => 'Pieza',
            'activo' => true,
        ]);
        $item = Item::query()->create([
            'id' => 'KDX-VIEW-1',
            'item_code' => 'KDX-VIEW-001',
            'nombre' => 'Producto Vista Kardex',
            'unidad_medida_id' => $unit->id,
            'unidad_medida' => 'PZ',
            'activo' => true,
            'costo_promedio' => 10,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $almacen = Almacen::query()->create([
            'clave' => 'KVW',
            'nombre' => 'Almacen Vista',
            'activo' => true,
        ]);
        $user = User::factory()->create();

        DB::connection('pgsql')->table('selemti.inventory_batch')->insert([
            'item_id' => $item->id,
            'lote_proveedor' => 'KVW-001',
            'cantidad_original' => 10,
            'cantidad_actual' => 7,
            'uom_base' => 'PZ',
            'caducidad' => now()->addMonth()->toDateString(),
            'estado' => 'ACTIVO',
            'almacen_id' => (string) $almacen->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.mov_inv')->insert([
            'item_id' => $item->id,
            'inventory_batch_id' => null,
            'tipo' => 'RECEPCION_COMPRA',
            'qty' => 7,
            'cantidad' => 7,
            'qty_original' => 7,
            'uom' => 'PZ',
            'uom_original_id' => $unit->id,
            'costo_unit' => 10,
            'sucursal_id' => '1',
            'almacen_id' => (string) $almacen->id,
            'ref_tipo' => 'RECEPCION',
            'ref_id' => 123,
            'usuario_id' => $user->id,
            'ts' => now()->subDay(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Livewire::test(KardexView::class, ['itemId' => $item->id])
            ->assertSee('Producto Vista Kardex')
            ->assertSee('UOM base')
            ->assertSee('Stock actual total')
            ->assertSee('RECEPCION_COMPRA')
            ->assertSee('RECEPCION #123')
            ->assertSee('Almacen Vista');
    }
}
