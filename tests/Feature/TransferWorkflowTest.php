<?php

namespace Tests\Feature;

use App\Models\Catalogs\Almacen;
use App\Models\Inv\Item;
use App\Models\Inventory\TransferHeader;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
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

        // Crear usuario de prueba
        $this->user = User::factory()->create();

        // Crear almacenes de prueba
        $this->almacenOrigen = Almacen::factory()->create([
            'nombre' => 'Almacén Central',
            'clave' => 'CENTRAL',
        ]);

        $this->almacenDestino = Almacen::factory()->create([
            'nombre' => 'Almacén Sucursal',
            'clave' => 'SUCURSAL',
        ]);

        // Crear item de prueba
        $this->item = Item::factory()->create([
            'nombre' => 'Producto Test',
            'clave' => 'PROD-001',
        ]);

        // Crear stock inicial en almacén origen
        \DB::connection('pgsql')->table('selemti.stock')->insert([
            'almacen_id' => $this->almacenOrigen->id,
            'item_id' => $this->item->id,
            'cantidad_actual' => 100,
            'created_at' => now(),
            'updated_at' => now(),
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

        $this->assertDatabaseHas('selemti.transfer_cab', [
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
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
        // Crear transferencia
        $transfer = TransferHeader::create([
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_SOLICITADA,
            'creada_por' => $this->user->id,
            'fecha_solicitada' => now(),
        ]);

        $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 10,
            'unidad_medida' => 'PZ',
            'created_at' => now(),
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transfer->id}/approve");

        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'message' => 'Transferencia aprobada exitosamente',
            ]);

        $this->assertDatabaseHas('selemti.transfer_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_APROBADA,
        ]);
    }

    /** @test */
    public function test_approve_transfer_fails_with_insufficient_stock()
    {
        // Crear transferencia con cantidad mayor al stock
        $transfer = TransferHeader::create([
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_SOLICITADA,
            'creada_por' => $this->user->id,
            'fecha_solicitada' => now(),
        ]);

        $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 200, // Mayor que stock disponible (100)
            'unidad_medida' => 'PZ',
            'created_at' => now(),
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
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_APROBADA,
            'creada_por' => $this->user->id,
            'aprobada_por' => $this->user->id,
            'fecha_solicitada' => now(),
            'fecha_aprobada' => now(),
        ]);

        $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 10,
            'unidad_medida' => 'PZ',
            'created_at' => now(),
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

        $this->assertDatabaseHas('selemti.transfer_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_EN_TRANSITO,
            'numero_guia' => 'GUIA-123',
        ]);
    }

    /** @test */
    public function test_receive_transfer_successfully()
    {
        $transfer = TransferHeader::create([
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_EN_TRANSITO,
            'creada_por' => $this->user->id,
            'aprobada_por' => $this->user->id,
            'despachada_por' => $this->user->id,
            'fecha_solicitada' => now(),
            'fecha_aprobada' => now(),
            'fecha_despachada' => now(),
        ]);

        $line = $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 10,
            'cantidad_despachada' => 10,
            'unidad_medida' => 'PZ',
            'created_at' => now(),
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

        $this->assertDatabaseHas('selemti.transfer_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_RECIBIDA,
        ]);
    }

    /** @test */
    public function test_receive_transfer_calculates_variance()
    {
        $transfer = TransferHeader::create([
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_EN_TRANSITO,
            'creada_por' => $this->user->id,
            'aprobada_por' => $this->user->id,
            'despachada_por' => $this->user->id,
            'fecha_solicitada' => now(),
            'fecha_aprobada' => now(),
            'fecha_despachada' => now(),
        ]);

        $line = $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 10,
            'cantidad_despachada' => 10,
            'unidad_medida' => 'PZ',
            'created_at' => now(),
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/inventory/transfers/{$transfer->id}/receive", [
                'lines' => [
                    [
                        'line_id' => $line->id,
                        'cantidad_recibida' => 8, // Recibido menos que despachado
                    ],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('ok', true)
            ->assertJsonStructure([
                'varianzas' => [
                    '*' => [
                        'line_id',
                        'item_id',
                        'varianza',
                        'varianza_porcentaje',
                    ],
                ],
            ]);

        // Verificar que hay varianza
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
            ->assertJsonPath('ok', true)
            ->assertJsonPath('data.estado', TransferHeader::STATUS_POSTEADA);

        // Verificar que se crearon movimientos
        $this->assertDatabaseHas('selemti.mov_inv', [
            'almacen_id' => $this->almacenOrigen->id,
            'item_id' => $this->item->id,
            'tipo_movimiento' => 'TRASPASO_OUT',
        ]);

        $this->assertDatabaseHas('selemti.mov_inv', [
            'almacen_id' => $this->almacenDestino->id,
            'item_id' => $this->item->id,
            'tipo_movimiento' => 'TRASPASO_IN',
        ]);
    }
}
