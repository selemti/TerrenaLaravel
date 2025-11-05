<?php

namespace Tests\Unit\Services;

use App\Models\Catalogs\Almacen;
use App\Models\Inv\Item;
use App\Models\Inventory\TransferHeader;
use App\Models\Inventory\TransferLine;
use App\Models\Inv\Movement;
use App\Models\User;
use App\Services\Inventory\TransferService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use RuntimeException;
use Tests\TestCase;

class TransferServiceTest extends TestCase
{
    use RefreshDatabase;

    protected TransferService $transferService;
    protected User $user;
    protected Almacen $almacenOrigen;
    protected Almacen $almacenDestino;
    protected Item $item;

    protected function setUp(): void
    {
        parent::setUp();

        $this->transferService = new TransferService();
        
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
        DB::connection('pgsql')->table('selemti.stock')->insert([
            'almacen_id' => $this->almacenOrigen->id,
            'item_id' => $this->item->id,
            'cantidad_actual' => 100,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function test_create_transfer_successfully(): void
    {
        $lines = [
            [
                'item_id' => $this->item->id,
                'cantidad' => 10,
                'unidad_medida' => 'PZ',
            ],
        ];

        $result = $this->transferService->createTransfer(
            $this->almacenOrigen->id,
            $this->almacenDestino->id,
            $lines,
            $this->user->id
        );

        $this->assertIsArray($result);
        $this->assertArrayHasKey('transfer_id', $result);
        $this->assertEquals(TransferHeader::STATUS_SOLICITADA, $result['status']);

        $this->assertDatabaseHas('selemti.transfer_cab', [
            'id' => $result['transfer_id'],
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_SOLICITADA,
        ]);

        $this->assertDatabaseHas('selemti.transfer_det', [
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 10,
        ]);
    }

    public function test_create_transfer_throws_exception_with_same_origin_and_destination(): void
    {
        $lines = [
            [
                'item_id' => $this->item->id,
                'cantidad' => 10,
                'unidad_medida' => 'PZ',
            ],
        ];

        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('Almacén origen y destino deben ser diferentes.');

        $this->transferService->createTransfer(
            $this->almacenOrigen->id,
            $this->almacenOrigen->id,
            $lines,
            $this->user->id
        );
    }

    public function test_create_transfer_throws_exception_with_empty_lines(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('At least one line item is required for a transfer.');

        $this->transferService->createTransfer(
            $this->almacenOrigen->id,
            $this->almacenDestino->id,
            [],
            $this->user->id
        );
    }

    public function test_create_transfer_throws_exception_with_invalid_ids(): void
    {
        $lines = [
            [
                'item_id' => $this->item->id,
                'cantidad' => 10,
                'unidad_medida' => 'PZ',
            ],
        ];

        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('The almacén origen id must be greater than zero.');

        $this->transferService->createTransfer(
            0,
            $this->almacenDestino->id,
            $lines,
            $this->user->id
        );
    }

    public function test_approve_transfer_successfully(): void
    {
        // Crear transferencia
        $transfer = TransferHeader::create([
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_SOLICITADA,
            'creada_por' => $this->user->id,
            'fecha_solicitada' => now(),
        ]);

        $line = $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 10,
            'unidad_medida' => 'PZ',
            'created_at' => now(),
        ]);

        $result = $this->transferService->approveTransfer($transfer->id, $this->user->id);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('transfer_id', $result);
        $this->assertEquals($transfer->id, $result['transfer_id']);
        $this->assertEquals(TransferHeader::STATUS_APROBADA, $result['status']);

        $this->assertDatabaseHas('selemti.transfer_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_APROBADA,
            'aprobada_por' => $this->user->id,
        ]);
    }

    public function test_approve_transfer_fails_with_insufficient_stock(): void
    {
        // Crear transferencia con cantidad mayor al stock
        $transfer = TransferHeader::create([
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_SOLICITADA,
            'creada_por' => $this->user->id,
            'fecha_solicitada' => now(),
        ]);

        $line = $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 200, // Mayor que stock disponible (100)
            'unidad_medida' => 'PZ',
            'created_at' => now(),
        ]);

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Stock insuficiente');

        $this->transferService->approveTransfer($transfer->id, $this->user->id);
    }

    public function test_approve_transfer_fails_with_invalid_status(): void
    {
        // Crear transferencia con estado diferente a SOLICITADA
        $transfer = TransferHeader::create([
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_APROBADA,
            'creada_por' => $this->user->id,
            'fecha_solicitada' => now(),
        ]);

        $line = $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 10,
            'unidad_medida' => 'PZ',
            'created_at' => now(),
        ]);

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Transfer must be in SOLICITADA status to be approved.');

        $this->transferService->approveTransfer($transfer->id, $this->user->id);
    }

    public function test_mark_in_transit_successfully(): void
    {
        // Crear transferencia aprobada
        $transfer = TransferHeader::create([
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_APROBADA,
            'creada_por' => $this->user->id,
            'aprobada_por' => $this->user->id,
            'fecha_solicitada' => now(),
            'fecha_aprobada' => now(),
        ]);

        $line = $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 10,
            'unidad_medida' => 'PZ',
            'created_at' => now(),
        ]);

        $result = $this->transferService->markInTransit($transfer->id, $this->user->id, 'GUIA-123');

        $this->assertIsArray($result);
        $this->assertArrayHasKey('transfer_id', $result);
        $this->assertEquals($transfer->id, $result['transfer_id']);
        $this->assertEquals(TransferHeader::STATUS_EN_TRANSITO, $result['status']);
        $this->assertEquals('GUIA-123', $result['numero_guia']);

        $this->assertDatabaseHas('selemti.transfer_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_EN_TRANSITO,
            'numero_guia' => 'GUIA-123',
            'despachada_por' => $this->user->id,
        ]);

        $this->assertDatabaseHas('selemti.transfer_det', [
            'id' => $line->id,
            'cantidad_despachada' => 10,
        ]);
    }

    public function test_receive_transfer_successfully(): void
    {
        // Crear transferencia en tránsito
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

        $receivedLines = [
            [
                'line_id' => $line->id,
                'cantidad_recibida' => 10,
            ],
        ];

        $result = $this->transferService->receiveTransfer($transfer->id, $receivedLines, $this->user->id);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('transfer_id', $result);
        $this->assertEquals($transfer->id, $result['transfer_id']);
        $this->assertEquals(TransferHeader::STATUS_RECIBIDA, $result['status']);

        $this->assertDatabaseHas('selemti.transfer_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_RECIBIDA,
            'recibida_por' => $this->user->id,
        ]);

        $this->assertDatabaseHas('selemti.transfer_det', [
            'id' => $line->id,
            'cantidad_recibida' => 10,
        ]);
    }

    public function test_receive_transfer_calculates_variance(): void
    {
        // Crear transferencia en tránsito
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

        $receivedLines = [
            [
                'line_id' => $line->id,
                'cantidad_recibida' => 8, // Menos que despachado
            ],
        ];

        $result = $this->transferService->receiveTransfer($transfer->id, $receivedLines, $this->user->id);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('varianzas', $result);
        $this->assertCount(1, $result['varianzas']);
        $this->assertEquals(-2, $result['varianzas'][0]['varianza']); // 8 - 10 = -2
    }

    public function test_post_transfer_to_inventory_successfully(): void
    {
        // Crear transferencia recibida
        $transfer = TransferHeader::create([
            'origen_almacen_id' => $this->almacenOrigen->id,
            'destino_almacen_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_RECIBIDA,
            'creada_por' => $this->user->id,
            'aprobada_por' => $this->user->id,
            'despachada_por' => $this->user->id,
            'recibida_por' => $this->user->id,
            'fecha_solicitada' => now(),
            'fecha_aprobada' => now(),
            'fecha_despachada' => now(),
            'fecha_recibida' => now(),
        ]);

        $line = $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 10,
            'cantidad_despachada' => 10,
            'cantidad_recibida' => 10,
            'unidad_medida' => 'PZ',
            'created_at' => now(),
        ]);

        $result = $this->transferService->postTransferToInventory($transfer->id, $this->user->id);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('transfer_id', $result);
        $this->assertEquals($transfer->id, $result['transfer_id']);
        $this->assertEquals(TransferHeader::STATUS_POSTEADA, $result['status']);
        $this->assertEquals(2, $result['movimientos_generados']); // 1 OUT + 1 IN

        $this->assertDatabaseHas('selemti.transfer_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_POSTEADA,
        ]);

        // Verificar movimientos generados
        $this->assertDatabaseHas('selemti.mov_inv', [
            'almacen_id' => $this->almacenOrigen->id,
            'item_id' => $this->item->id,
            'tipo_movimiento' => 'TRASPASO_OUT',
            'cantidad' => -10,
        ]);

        $this->assertDatabaseHas('selemti.mov_inv', [
            'almacen_id' => $this->almacenDestino->id,
            'item_id' => $this->item->id,
            'tipo_movimiento' => 'TRASPASO_IN',
            'cantidad' => 10,
        ]);
    }

    public function test_guard_positive_id_throws_exception_for_invalid_id(): void
    {
        $reflection = new \ReflectionClass(TransferService::class);
        $method = $reflection->getMethod('guardPositiveId');
        $method->setAccessible(true);

        $service = new TransferService();

        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('The test id must be greater than zero.');

        $method->invoke($service, 0, 'test');
    }
}