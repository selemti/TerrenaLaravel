<?php

namespace Tests\Feature;

use App\Services\Pos\DTO\PosConsumptionDiagnostics;
use App\Services\Pos\DTO\PosConsumptionResult;
use App\Services\Pos\PosConsumptionService;
use App\Services\Pos\Repositories\ConsumoPosRepository;
use App\Services\Pos\Repositories\CostosRepository;
use App\Services\Pos\Repositories\InventarioRepository;
use App\Services\Pos\Repositories\RecetaRepository;
use App\Services\Pos\Repositories\TicketRepository;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class PosConsumptionServiceTest extends TestCase
{
    protected PosConsumptionService $service;
    protected TicketRepository $ticketRepo;
    protected ConsumoPosRepository $consumoRepo;
    protected InventarioRepository $inventarioRepo;
    protected RecetaRepository $recetaRepo;
    protected CostosRepository $costosRepo;

    protected function setUp(): void
    {
        parent::setUp();

        // Mock repositories
        $this->ticketRepo = $this->createMock(TicketRepository::class);
        $this->consumoRepo = $this->createMock(ConsumoPosRepository::class);
        $this->inventarioRepo = $this->createMock(InventarioRepository::class);
        $this->recetaRepo = $this->createMock(RecetaRepository::class);
        $this->costosRepo = $this->createMock(CostosRepository::class);

        // Create service with mocked dependencies
        $this->service = new PosConsumptionService(
            $this->ticketRepo,
            $this->consumoRepo,
            $this->inventarioRepo,
            $this->recetaRepo,
            $this->costosRepo
        );
    }

    /**
     * Test: No debe permitir doble consumo para un ticket ya procesado
     */
    public function test_no_double_consumption_for_already_processed_ticket(): void
    {
        $ticketId = 12345;

        // Mock: Ticket existe
        $this->ticketRepo->method('getTicketHeader')
            ->willReturn([
                'id' => $ticketId,
                'paid' => true,
                'voided' => false,
                'total_amount' => 150.00,
            ]);

        // Mock: Consumo ya está confirmado
        $this->consumoRepo->method('getEstadoConsumo')
            ->willReturn('CONFIRMADO');

        $this->consumoRepo->method('getConsumoByTicket')
            ->willReturn([
                'header' => [
                    'id' => 1,
                    'ticket_id' => $ticketId,
                    'estado' => 'CONFIRMADO',
                    'fecha_confirmacion' => '2025-10-27 10:00:00',
                ],
                'detalles' => [
                    [
                        'item_id' => 101,
                        'item_descripcion' => 'Hamburguesa',
                        'qty' => 1.0,
                        'uom' => 'UNI',
                        'costo_unitario' => 50.00,
                    ],
                ],
            ]);

        $this->inventarioRepo->method('getMovimientosByTicket')
            ->willReturn([
                [
                    'id' => 1,
                    'item_id' => 101,
                    'qty' => -1.0,
                    'tipo' => 'VENTA_TEO',
                ],
            ]);

        // Ejecutar
        $result = $this->service->ingestarTicket($ticketId);

        // Verificar
        $this->assertEquals('ALREADY_PROCESSED', $result->getStatus());
        $this->assertEquals($ticketId, $result->getTicketId());
        $this->assertStringContainsString('ya tiene consumo confirmado', $result->getMessage());
    }

    /**
     * Test: Reprocesar crea consumo y marca como REPROCESSED
     */
    public function test_reprocess_creates_consumption_and_marks_as_reprocessed(): void
    {
        $ticketId = 67890;
        $userId = 1;

        // Mock DB connection y transacciones
        DB::shouldReceive('connection')
            ->with('pgsql')
            ->andReturnSelf();

        DB::shouldReceive('beginTransaction')->once();
        DB::shouldReceive('commit')->once();
        DB::shouldReceive('rollBack')->never();

        DB::shouldReceive('select')
            ->with("
                SELECT selemti.fn_expandir_consumo_ticket(?)
            ", [$ticketId])
            ->once()
            ->andReturn([]);

        DB::shouldReceive('select')
            ->with("
                SELECT selemti.fn_confirmar_consumo_ticket(?, true)
            ", [$ticketId])
            ->once()
            ->andReturn([]);

        DB::shouldReceive('table')
            ->with('selemti.pos_reprocess_log')
            ->andReturnSelf();

        DB::shouldReceive('insert')
            ->once()
            ->andReturn(true);

        // Mock: Ticket existe
        $this->ticketRepo->method('getTicketHeader')
            ->willReturn([
                'id' => $ticketId,
                'paid' => true,
                'voided' => false,
            ]);

        // Mock: No tiene movimientos previos
        $this->consumoRepo->method('hasMovInvForTicket')
            ->willReturn(false);

        // Mock: Después del reproceso, el consumo existe
        $this->consumoRepo->method('getConsumoByTicket')
            ->willReturn([
                'header' => ['estado' => 'CONFIRMADO'],
                'detalles' => [
                    [
                        'item_id' => 201,
                        'item_descripcion' => 'Pizza',
                        'qty' => 1.0,
                        'uom' => 'UNI',
                        'costo_unitario' => 80.00,
                    ],
                ],
            ]);

        $this->inventarioRepo->method('getMovimientosByTicket')
            ->willReturn([
                [
                    'id' => 2,
                    'item_id' => 201,
                    'qty' => -1.0,
                    'ref_tipo' => 'POS_TICKET_REPROCESS',
                ],
            ]);

        $this->costosRepo->method('getItemUnitCostNow')
            ->willReturn(80.00);

        // Ejecutar
        $result = $this->service->reprocesarTicket($ticketId, $userId);

        // Verificar
        $this->assertEquals('REPROCESSED', $result->getStatus());
        $this->assertEquals($ticketId, $result->getTicketId());
        $this->assertNotNull($result->getConsumos());
        $this->assertCount(1, $result->getConsumos());
    }

    /**
     * Test: Reversar crea log de reversa y llama función DB
     */
    public function test_reverse_creates_reverse_log_and_calls_db_function(): void
    {
        $ticketId = 11111;
        $userId = 1;
        $motivo = 'Error en ticket';

        // Mock DB
        DB::shouldReceive('connection')
            ->with('pgsql')
            ->andReturnSelf();

        DB::shouldReceive('beginTransaction')->once();
        DB::shouldReceive('commit')->once();
        DB::shouldReceive('rollBack')->never();

        DB::shouldReceive('select')
            ->with("
                SELECT selemti.fn_reversar_consumo_ticket(?)
            ", [$ticketId])
            ->once()
            ->andReturn([]);

        DB::shouldReceive('table')
            ->with('selemti.pos_reverse_log')
            ->andReturnSelf();

        DB::shouldReceive('insert')
            ->once()
            ->andReturn(true);

        // Mock: Ticket existe
        $this->ticketRepo->method('getTicketHeader')
            ->willReturn([
                'id' => $ticketId,
                'total_amount' => 200.00,
            ]);

        // Mock: Tiene movimientos para reversar
        $this->consumoRepo->method('hasMovInvForTicket')
            ->willReturn(true);

        $this->consumoRepo->method('getConsumoByTicket')
            ->willReturn([
                'header' => ['estado' => 'CONFIRMADO'],
                'detalles' => [
                    ['item_id' => 301, 'item_descripcion' => 'Taco', 'qty' => 2.0],
                ],
            ]);

        $this->inventarioRepo->method('getMovimientosByTicket')
            ->willReturn([
                ['id' => 3, 'item_id' => 301, 'qty' => -2.0],
            ]);

        // Ejecutar
        $result = $this->service->reversarTicket($ticketId, $userId, $motivo);

        // Verificar
        $this->assertEquals('REVERSED', $result->getStatus());
        $this->assertEquals($ticketId, $result->getTicketId());
        $this->assertEquals($motivo, $result->getMeta()['motivo']);
    }

    /**
     * Test: Diagnostics detecta items sin receta y flags de packaging
     */
    public function test_diagnostics_detects_missing_mappings_and_packaging_flags(): void
    {
        $ticketId = 99999;

        // Mock: Ticket existe
        $this->ticketRepo->method('getTicketHeader')
            ->willReturn([
                'id' => $ticketId,
                'paid' => true,
                'voided' => false,
            ]);

        // Mock: Ticket tiene 3 items
        $this->ticketRepo->method('getTicketItems')
            ->willReturn([
                ['id' => 1, 'item_name' => 'Hamburguesa', 'quantity' => 1],
                ['id' => 2, 'item_name' => 'Papas', 'quantity' => 1],
                ['id' => 3, 'item_name' => 'Refresco', 'quantity' => 1],
            ]);

        // Mock: Solo 2 de 3 tienen mapeo
        $this->recetaRepo->method('hasActiveMapping')
            ->willReturnCallback(function ($posCode) {
                return in_array($posCode, ['Hamburguesa', 'Papas']);
            });

        // Mock: No tiene consumo confirmado
        $this->consumoRepo->method('getEstadoConsumo')
            ->willReturn('SIN_DATOS');

        $this->consumoRepo->method('hasMovInvForTicket')
            ->willReturn(false);

        $this->consumoRepo->method('faltanEmpaquesToGo')
            ->willReturn(true);

        $this->consumoRepo->method('faltanConsumiblesOperativos')
            ->willReturn(false);

        // Ejecutar
        $diagnostics = $this->service->diagnosticarTicket($ticketId);

        // Verificar
        $this->assertTrue($diagnostics->getTicketHeaderOk());
        $this->assertEquals(3, $diagnostics->getItemsTotal());
        $this->assertEquals(2, $diagnostics->getItemsConReceta());
        $this->assertEquals(1, $diagnostics->getItemsSinReceta());
        $this->assertTrue($diagnostics->getFaltanEmpaquesToGo());
        $this->assertFalse($diagnostics->getFaltanConsumiblesOperativos());
        $this->assertTrue($diagnostics->getPuedeReprocesar());
        $this->assertFalse($diagnostics->getPuedeReversar());
        $this->assertTrue($diagnostics->hasIssues());
    }

    /**
     * Test: Recalcular costo de receta llama al SP correcto
     */
    public function test_recalculate_recipe_cost_calls_stored_procedure(): void
    {
        $recipeId = 555;

        // Mock DB
        DB::shouldReceive('connection')
            ->with('pgsql')
            ->andReturnSelf();

        DB::shouldReceive('select')
            ->with("
                SELECT selemti.sp_snapshot_recipe_cost(?, NOW())
            ", [$recipeId])
            ->once()
            ->andReturn([]);

        // Ejecutar (no debería lanzar excepción)
        $this->service->recalcularCostoReceta($recipeId);

        // Si llegamos aquí sin excepción, el test pasa
        $this->assertTrue(true);
    }
}
