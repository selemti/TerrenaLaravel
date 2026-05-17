<?php

namespace Tests\Feature;

use App\Models\Catalogs\Almacen;
use App\Models\Inv\Item;
use App\Models\Inventory\TransferHeader;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TransferWorkflowTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected Almacen $almacenOrigen;

    protected Almacen $almacenDestino;

    protected Item $item;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create();

        $this->almacenOrigen = Almacen::factory()->create([
            'nombre' => 'Almacén Central',
            'clave' => 'CENTRAL',
        ]);

        $this->almacenDestino = Almacen::factory()->create([
            'nombre' => 'Almacén Sucursal',
            'clave' => 'SUCURSAL',
        ]);

        $this->item = Item::factory()->create([
            'nombre' => 'Producto Test',
            'clave' => 'PROD-001',
        ]);

        // Stock via mov_inv (service reads stock from here)
        DB::connection('pgsql')->table('selemti.mov_inv')->insert([
            'sucursal_id' => (string) $this->almacenOrigen->id,
            'item_id' => $this->item->id,
            'cantidad' => 100,
            'tipo' => 'INICIAL',
            'ts' => now(),
        ]);
    }

    /** @test */
    public function test_create_transfer_successfully()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/inventory/transfers', [
                'origen_almacen_id' => $this->almacenOrigen->id,
                'destino_almacen_id' => $this->almacenDestino->id,
                'lines' => [
                    [
                        'item_id' => $this->item->id,
                        'cantidad' => 10,
                        'unidad_medida' => 'PZ',
                    ],
                ],
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'ok' => true,
                'message' => 'Transferencia creada exitosamente',
            ]);

        $this->assertDatabaseHas('selemti.traspaso_cab', [
            'from_bodega_id' => $this->almacenOrigen->id,
            'to_bodega_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_SOLICITADA,
        ]);
    }

    /** @test */
    public function test_cannot_create_transfer_with_same_origin_and_destination()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/inventory/transfers', [
                'origen_almacen_id' => $this->almacenOrigen->id,
                'destino_almacen_id' => $this->almacenOrigen->id,
                'lines' => [
                    [
                        'item_id' => $this->item->id,
                        'cantidad' => 10,
                        'unidad_medida' => 'PZ',
                    ],
                ],
            ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function test_approve_transfer_validates_stock()
    {
        $transfer = TransferHeader::create([
            'from_bodega_id' => $this->almacenOrigen->id,
            'to_bodega_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_SOLICITADA,
            'usuario_id' => $this->user->id,
        ]);

        $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'qty' => 10,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transfer->id}/approve");

        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'message' => 'Transferencia aprobada exitosamente',
            ]);

        $this->assertDatabaseHas('selemti.traspaso_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_APROBADA,
        ]);
    }

    /** @test */
    public function test_approve_transfer_fails_with_insufficient_stock()
    {
        $transfer = TransferHeader::create([
            'from_bodega_id' => $this->almacenOrigen->id,
            'to_bodega_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_SOLICITADA,
            'usuario_id' => $this->user->id,
        ]);

        $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'qty' => 200, // más que stock disponible
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transfer->id}/approve");

        $response->assertStatus(400)
            ->assertJsonPath('ok', false);
    }

    /** @test */
    public function test_ship_transfer_successfully()
    {
        $transfer = TransferHeader::create([
            'from_bodega_id' => $this->almacenOrigen->id,
            'to_bodega_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_APROBADA,
            'usuario_id' => $this->user->id,
            'validada_por' => $this->user->id,
        ]);

        $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'qty' => 10,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transfer->id}/ship", [
                'numero_guia' => 'GUIA-123',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'message' => 'Transferencia despachada exitosamente',
            ]);

        $this->assertDatabaseHas('selemti.traspaso_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_EN_TRANSITO,
            'guia' => 'GUIA-123',
        ]);
    }

    /** @test */
    public function test_receive_transfer_successfully()
    {
        $transfer = TransferHeader::create([
            'from_bodega_id' => $this->almacenOrigen->id,
            'to_bodega_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_EN_TRANSITO,
            'usuario_id' => $this->user->id,
            'validada_por' => $this->user->id,
            'despachada_por' => $this->user->id,
        ]);

        $line = $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'qty' => 10,
            'cantidad_despachada' => 10,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transfer->id}/receive", [
                'lines' => [
                    [
                        'line_id' => $line->id,
                        'cantidad_recibida' => 10,
                    ],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'message' => 'Transferencia recibida exitosamente',
            ]);

        $this->assertDatabaseHas('selemti.traspaso_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_RECIBIDA,
        ]);
    }

    /** @test */
    public function test_receive_transfer_calculates_variance()
    {
        $transfer = TransferHeader::create([
            'from_bodega_id' => $this->almacenOrigen->id,
            'to_bodega_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_EN_TRANSITO,
            'usuario_id' => $this->user->id,
            'despachada_por' => $this->user->id,
        ]);

        $line = $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'qty' => 10,
            'cantidad_despachada' => 10,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transfer->id}/receive", [
                'lines' => [
                    [
                        'line_id' => $line->id,
                        'cantidad_recibida' => 8,
                    ],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('ok', true);

        $varianzas = $response->json('varianzas');
        $this->assertCount(1, $varianzas);
        $this->assertEquals(-2, $varianzas[0]['varianza']);
    }

    /** @test */
    public function test_full_transfer_workflow()
    {
        // 1. Crear transferencia
        $createResponse = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/inventory/transfers', [
                'origen_almacen_id' => $this->almacenOrigen->id,
                'destino_almacen_id' => $this->almacenDestino->id,
                'lines' => [
                    [
                        'item_id' => $this->item->id,
                        'cantidad' => 10,
                        'unidad_medida' => 'PZ',
                    ],
                ],
            ]);

        $createResponse->assertStatus(201);
        $transferId = $createResponse->json('data.id');

        // 2. Aprobar
        $approveResponse = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transferId}/approve");

        $approveResponse->assertStatus(200);

        // 3. Despachar
        $shipResponse = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transferId}/ship", [
                'numero_guia' => 'GUIA-TEST',
            ]);

        $shipResponse->assertStatus(200);

        // 4. Recibir
        $transfer = TransferHeader::find($transferId);
        $lineId = $transfer->lineas->first()->id;

        $receiveResponse = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transferId}/receive", [
                'lines' => [
                    [
                        'line_id' => $lineId,
                        'cantidad_recibida' => 10,
                    ],
                ],
            ]);

        $receiveResponse->assertStatus(200);

        // 5. Postear
        $postResponse = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transferId}/post");

        $postResponse->assertStatus(200)
            ->assertJsonPath('ok', true);

        // Verificar movimientos en mov_inv
        $this->assertDatabaseHas('selemti.mov_inv', [
            'sucursal_id' => (string) $this->almacenOrigen->id,
            'item_id' => $this->item->id,
            'tipo' => 'TRASPASO_SALIDA',
        ]);

        $this->assertDatabaseHas('selemti.mov_inv', [
            'sucursal_id' => (string) $this->almacenDestino->id,
            'item_id' => $this->item->id,
            'tipo' => 'TRASPASO_ENTRADA',
        ]);
    }
}
