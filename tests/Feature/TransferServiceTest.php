<?php

namespace Tests\Feature;

use App\Models\Inventory\TransferHeader;
use App\Services\Inventory\TransferService;
use Illuminate\Support\Facades\DB;
use Tests\Support\InteractsWithTransferDatabase;
use Tests\TestCase;

class TransferServiceTest extends TestCase
{
    use InteractsWithTransferDatabase;

    private TransferService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->setUpTransferDatabase();
        $this->service = app(TransferService::class);
    }

    public function test_it_creates_a_transfer_successfully(): void
    {
        $result = $this->service->createTransfer(
            fromAlmacenId: 1,
            toAlmacenId: 2,
            lines: [
                ['item_id' => 'ITEM-001', 'cantidad' => 5, 'uom_id' => 1],
                ['item_id' => 'ITEM-002', 'cantidad' => 3, 'uom_id' => 1],
            ],
            userId: 1
        );

        $this->assertArrayHasKey('transfer_id', $result);
        $this->assertEquals(TransferHeader::STATUS_SOLICITADA, $result['status']);

        $transfer = TransferHeader::with('lineas')->find($result['transfer_id']);
        $this->assertNotNull($transfer);
        $this->assertCount(2, $transfer->lineas);
        $this->assertEquals(5, (float) $transfer->lineas[0]->cantidad_solicitada);
    }

    public function test_it_rejects_same_origin_and_destination(): void
    {
        $this->expectException(\InvalidArgumentException::class);

        $this->service->createTransfer(
            fromAlmacenId: 1,
            toAlmacenId: 1,
            lines: [['item_id' => 'ITEM-001', 'cantidad' => 1, 'uom_id' => 1]],
            userId: 1
        );
    }

    public function test_it_approves_a_transfer_with_sufficient_stock(): void
    {
        $result = $this->service->createTransfer(
            fromAlmacenId: 1,
            toAlmacenId: 2,
            lines: [['item_id' => 'ITEM-001', 'cantidad' => 2, 'uom_id' => 1]],
            userId: 1
        );

        DB::table('selemti.mov_inv')->insert([
            'item_id' => 'ITEM-001',
            'cantidad' => 5,
            'tipo' => 'ENTRADA',
            'ref_tipo' => 'SEED',
            'usuario_id' => 1,
        ]);

        $approval = $this->service->approveTransfer($result['transfer_id'], 1);

        $this->assertEquals(TransferHeader::STATUS_APROBADA, $approval['status']);
        $transfer = TransferHeader::find($result['transfer_id']);
        $this->assertEquals(TransferHeader::STATUS_APROBADA, $transfer->estado);
        $this->assertNotNull($transfer->fecha_aprobada);
    }

    public function test_it_rejects_approval_without_sufficient_stock(): void
    {
        $result = $this->service->createTransfer(
            fromAlmacenId: 1,
            toAlmacenId: 2,
            lines: [['item_id' => 'ITEM-001', 'cantidad' => 2, 'uom_id' => 1]],
            userId: 1
        );

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Stock insuficiente');

        $this->service->approveTransfer($result['transfer_id'], 1);
    }

    public function test_it_marks_transfer_in_transit(): void
    {
        $result = $this->service->createTransfer(
            fromAlmacenId: 1,
            toAlmacenId: 2,
            lines: [['item_id' => 'ITEM-001', 'cantidad' => 2, 'uom_id' => 1]],
            userId: 1
        );

        DB::table('selemti.mov_inv')->insert([
            'item_id' => 'ITEM-001',
            'cantidad' => 5,
            'tipo' => 'ENTRADA',
            'ref_tipo' => 'SEED',
            'usuario_id' => 1,
        ]);

        $this->service->approveTransfer($result['transfer_id'], 1);

        $inTransit = $this->service->markInTransit($result['transfer_id'], 1, 'GUIA-1234');

        $this->assertEquals(TransferHeader::STATUS_EN_TRANSITO, $inTransit['status']);
        $transfer = TransferHeader::find($result['transfer_id']);
        $this->assertEquals('GUIA-1234', $transfer->guia);
    }

    public function test_it_receives_transfer_with_quantities(): void
    {
        $result = $this->service->createTransfer(
            fromAlmacenId: 1,
            toAlmacenId: 2,
            lines: [['item_id' => 'ITEM-001', 'cantidad' => 5, 'uom_id' => 1]],
            userId: 1
        );

        DB::table('selemti.mov_inv')->insert([
            'item_id' => 'ITEM-001',
            'cantidad' => 10,
            'tipo' => 'ENTRADA',
            'ref_tipo' => 'SEED',
            'usuario_id' => 1,
        ]);

        $this->service->approveTransfer($result['transfer_id'], 1);
        $this->service->markInTransit($result['transfer_id'], 1);

        $transfer = TransferHeader::with('lineas')->find($result['transfer_id']);
        $line = $transfer->lineas->first();

        $received = $this->service->receiveTransfer(
            transferId: $transfer->id,
            receivedLines: [[
                'line_id' => $line->id,
                'cantidad_recibida' => 4.5,
                'observaciones' => 'Faltó 0.5',
            ]],
            userId: 1
        );

        $this->assertEquals(TransferHeader::STATUS_RECIBIDA, $received['status']);
        $line->refresh();
        $this->assertEquals(4.5, (float) $line->cantidad_recibida);
        $this->assertEquals('Faltó 0.5', $line->observaciones);
    }

    public function test_it_posts_transfer_to_inventory(): void
    {
        $result = $this->service->createTransfer(
            fromAlmacenId: 1,
            toAlmacenId: 2,
            lines: [['item_id' => 'ITEM-001', 'cantidad' => 3, 'uom_id' => 1]],
            userId: 1
        );

        DB::table('selemti.mov_inv')->insert([
            'item_id' => 'ITEM-001',
            'cantidad' => 5,
            'tipo' => 'ENTRADA',
            'ref_tipo' => 'SEED',
            'usuario_id' => 1,
        ]);

        $this->service->approveTransfer($result['transfer_id'], 1);
        $this->service->markInTransit($result['transfer_id'], 1);

        $transfer = TransferHeader::with('lineas')->find($result['transfer_id']);
        $line = $transfer->lineas->first();

        $this->service->receiveTransfer(
            transferId: $transfer->id,
            receivedLines: [[
                'line_id' => $line->id,
                'cantidad_recibida' => 3,
            ]],
            userId: 1
        );

        $posted = $this->service->postTransferToInventory($transfer->id, 1);

        $this->assertEquals(TransferHeader::STATUS_POSTEADA, $posted['status']);

        $movimientos = DB::table('selemti.mov_inv')
            ->where('ref_tipo', 'TRANSFER')
            ->where('ref_id', $transfer->id)
            ->get();

        $this->assertCount(3, $movimientos); // uno inicial + 2 del posteo
        $salida = $movimientos->firstWhere('cantidad', -3.0);
        $entrada = $movimientos->firstWhere('cantidad', 3.0);
        $this->assertNotNull($salida);
        $this->assertNotNull($entrada);
    }

    public function test_it_rejects_posting_non_received_transfer(): void
    {
        $result = $this->service->createTransfer(
            fromAlmacenId: 1,
            toAlmacenId: 2,
            lines: [['item_id' => 'ITEM-001', 'cantidad' => 3, 'uom_id' => 1]],
            userId: 1
        );

        DB::table('selemti.mov_inv')->insert([
            'item_id' => 'ITEM-001',
            'cantidad' => 5,
            'tipo' => 'ENTRADA',
            'ref_tipo' => 'SEED',
            'usuario_id' => 1,
        ]);

        $this->service->approveTransfer($result['transfer_id'], 1);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('no puede ser posteada');

        $this->service->postTransferToInventory($result['transfer_id'], 1);
    }
}
