<?php

namespace Tests\Feature\Services\Inventory;

use App\Exceptions\Inventory\InventoryValidationException;
use App\Services\Inventory\PosConsumptionService;
use App\Services\Inventory\UomConversionService;
use App\Services\Pos\PosModifierService;
use Illuminate\Database\Connection;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Mockery;
use Tests\TestCase;

class PosConsumptionServiceTest extends TestCase
{
    protected function tearDown(): void
    {
        Mockery::close();

        parent::tearDown();
    }

    public function test_expand_ticket_delegates_to_canonical_database_function(): void
    {
        $connection = Mockery::mock(Connection::class);
        $connection->shouldReceive('select')
            ->once()
            ->with('SELECT * FROM selemti.fn_expandir_consumo_ticket(?)', [123])
            ->andReturn([]);

        DB::shouldReceive('connection')
            ->once()
            ->with('pgsql')
            ->andReturn($connection);

        app(PosConsumptionService::class)->expandTicket(123);

        $this->addToAssertionCount(1);
    }

    public function test_confirm_ticket_processes_inside_pgsql_transaction(): void
    {
        $connection = Mockery::mock(Connection::class);

        $connection->shouldReceive('transaction')
            ->once()
            ->with(Mockery::type('callable'), 5)
            ->andReturnUsing(function (callable $callback) {
                return $callback();
            });

        DB::shouldReceive('connection')
            ->once()
            ->with('pgsql')
            ->andReturn($connection);

        $service = new class(app(PosModifierService::class), app(UomConversionService::class)) extends PosConsumptionService
        {
            protected function ticketItemsForProcessing(int $ticketId): Collection
            {
                return collect();
            }

            protected function dispatchIngestedEvent(int $ticketId): void {}
        };

        $summary = $service->confirmTicket(123);

        $this->assertSame(123, $summary['ticket_id']);
        $this->assertSame(0, $summary['ticket_items_processed']);
    }

    public function test_reverse_ticket_delegates_inside_pgsql_transaction(): void
    {
        $connection = Mockery::mock(Connection::class);
        $connection->shouldReceive('transaction')
            ->once()
            ->with(Mockery::type('callable'), 5)
            ->andReturnUsing(function (callable $callback) {
                return $callback();
            });
        $connection->shouldReceive('statement')
            ->once()
            ->with('SELECT selemti.fn_reversar_consumo_ticket(?)', [123])
            ->andReturn(true);

        DB::shouldReceive('connection')
            ->once()
            ->with('pgsql')
            ->andReturn($connection);

        app(PosConsumptionService::class)->reverseTicket(123);

        $this->addToAssertionCount(1);
    }

    public function test_normalize_line_keeps_string_item_id_and_defaults_factor_origin_and_meta(): void
    {
        $line = app(PosConsumptionService::class)->normalizeLine([
            'item_id' => 'MP-UUID-1',
            'uom' => 'KG',
            'cantidad' => '2.5',
        ]);

        $this->assertSame('MP-UUID-1', $line['item_id']);
        $this->assertSame('KG', $line['uom']);
        $this->assertSame(2.5, $line['cantidad']);
        $this->assertSame(1.0, $line['factor']);
        $this->assertSame('RECETA', $line['origen']);
        $this->assertSame([], $line['meta']);
    }

    public function test_normalize_line_rejects_non_positive_quantity(): void
    {
        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('La cantidad debe ser mayor a cero.');

        app(PosConsumptionService::class)->normalizeLine([
            'item_id' => 'MP-UUID-1',
            'cantidad' => 0,
        ]);
    }
}
