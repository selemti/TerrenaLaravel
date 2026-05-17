<?php

namespace Tests\Unit\Services;

use App\Models\Catalogs\Almacen;
use App\Models\Inv\Item;
use App\Models\Inventory\TransferHeader;
use App\Models\User;
use App\Services\Inventory\TransferService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use App\Exceptions\Inventory\InsufficientStockException;
use App\Exceptions\Inventory\InventoryValidationException;
use App\Exceptions\Transfer\InvalidTransferStateException;
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

        $this->transferService = new TransferService;

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

        // Stock via mov_inv (the service reads SUM(cantidad) from here for stock validation)
        DB::connection('pgsql')->table('selemti.mov_inv')->insert([
            'sucursal_id' => (string) $this->almacenOrigen->id,
            'item_id' => $this->item->id,
            'cantidad' => 100,  // column added by baseline migration
            'tipo' => 'INICIAL',
            'ts' => now(),
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

        $this->assertDatabaseHas('selemti.traspaso_cab', [
            'id' => $result['transfer_id'],
            'from_bodega_id' => $this->almacenOrigen->id,
            'to_bodega_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_SOLICITADA,
        ]);

        $this->assertDatabaseHas('selemti.traspaso_det', [
            'item_id' => $this->item->id,
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

        $this->expectException(InventoryValidationException::class);
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
        $this->expectException(InventoryValidationException::class);
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

        $this->expectException(InventoryValidationException::class);
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

        $result = $this->transferService->approveTransfer($transfer->id, $this->user->id);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('transfer_id', $result);
        $this->assertEquals($transfer->id, $result['transfer_id']);
        $this->assertEquals(TransferHeader::STATUS_APROBADA, $result['status']);

        $this->assertDatabaseHas('selemti.traspaso_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_APROBADA,
            'validada_por' => $this->user->id,
        ]);
    }

    public function test_approve_transfer_fails_with_insufficient_stock(): void
    {
        $transfer = TransferHeader::create([
            'from_bodega_id' => $this->almacenOrigen->id,
            'to_bodega_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_SOLICITADA,
            'usuario_id' => $this->user->id,
        ]);

        $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'qty' => 200, // más que los 100 de stock
        ]);

        $this->expectException(InsufficientStockException::class);

        $this->transferService->approveTransfer($transfer->id, $this->user->id);
    }

    public function test_approve_transfer_fails_with_invalid_status(): void
    {
        $transfer = TransferHeader::create([
            'from_bodega_id' => $this->almacenOrigen->id,
            'to_bodega_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_APROBADA,
            'usuario_id' => $this->user->id,
        ]);

        $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'qty' => 10,
        ]);

        $this->expectException(InvalidTransferStateException::class);

        $this->transferService->approveTransfer($transfer->id, $this->user->id);
    }

    public function test_mark_in_transit_successfully(): void
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

        $result = $this->transferService->markInTransit($transfer->id, $this->user->id, 'GUIA-123');

        $this->assertIsArray($result);
        $this->assertArrayHasKey('transfer_id', $result);
        $this->assertEquals($transfer->id, $result['transfer_id']);
        $this->assertEquals(TransferHeader::STATUS_EN_TRANSITO, $result['status']);
        $this->assertEquals('GUIA-123', $result['numero_guia']);

        $this->assertDatabaseHas('selemti.traspaso_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_EN_TRANSITO,
            'guia' => 'GUIA-123',
            'despachada_por' => $this->user->id,
        ]);
    }

    public function test_receive_transfer_successfully(): void
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

        $this->assertDatabaseHas('selemti.traspaso_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_RECIBIDA,
            'recibida_por' => $this->user->id,
        ]);

        $this->assertDatabaseHas('selemti.traspaso_det', [
            'id' => $line->id,
            'cantidad_recibida' => 10,
        ]);
    }

    public function test_receive_transfer_calculates_variance(): void
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
        $transfer = TransferHeader::create([
            'from_bodega_id' => $this->almacenOrigen->id,
            'to_bodega_id' => $this->almacenDestino->id,
            'estado' => TransferHeader::STATUS_RECIBIDA,
            'usuario_id' => $this->user->id,
            'validada_por' => $this->user->id,
            'despachada_por' => $this->user->id,
            'recibida_por' => $this->user->id,
        ]);

        $transfer->lineas()->create([
            'item_id' => $this->item->id,
            'qty' => 10,
            'cantidad_despachada' => 10,
            'cantidad_recibida' => 10,
        ]);

        $result = $this->transferService->postTransferToInventory($transfer->id, $this->user->id);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('transfer_id', $result);
        $this->assertEquals($transfer->id, $result['transfer_id']);
        $this->assertEquals(TransferHeader::STATUS_POSTEADA, $result['status']);
        $this->assertEquals(2, $result['movements_created']); // 1 OUT + 1 IN

        $this->assertDatabaseHas('selemti.traspaso_cab', [
            'id' => $transfer->id,
            'estado' => TransferHeader::STATUS_POSTEADA,
        ]);

        // Verificar movimientos generados en mov_inv
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

    public function test_guard_positive_id_throws_exception_for_invalid_id(): void
    {
        $reflection = new \ReflectionClass(TransferService::class);
        $method = $reflection->getMethod('guardPositiveId');
        $method->setAccessible(true);

        $service = new TransferService;

        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('The test id must be greater than zero.');

        $method->invoke($service, 0, 'test');
    }
}
