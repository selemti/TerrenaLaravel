<?php

namespace App\Services\Pos;

use App\Services\Pos\DTO\PosConsumptionDiagnostics;
use App\Services\Pos\DTO\PosConsumptionResult;
use App\Services\Pos\Repositories\ConsumoPosRepository;
use App\Services\Pos\Repositories\CostosRepository;
use App\Services\Pos\Repositories\InventarioRepository;
use App\Services\Pos\Repositories\RecetaRepository;
use App\Services\Pos\Repositories\TicketRepository;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PosConsumptionService
{
    public function __construct(
        protected TicketRepository $ticketRepo,
        protected ConsumoPosRepository $consumoRepo,
        protected InventarioRepository $inventarioRepo,
        protected RecetaRepository $recetaRepo,
        protected CostosRepository $costosRepo
    ) {
    }

    /**
     * Ingesta un ticket (caso normal de venta pagada)
     * No vuelve a descontar inventario si ya existe consumo confirmado
     *
     * @param int $ticketId
     * @return PosConsumptionResult
     */
    public function ingestarTicket(int $ticketId): PosConsumptionResult
    {
        try {
            // Verificar que el ticket existe
            $header = $this->ticketRepo->getTicketHeader($ticketId);
            if (!$header) {
                return new PosConsumptionResult(
                    ticketId: $ticketId,
                    status: 'ERROR',
                    message: 'Ticket no encontrado'
                );
            }

            // Verificar si ya tiene consumo confirmado
            $estadoConsumo = $this->consumoRepo->getEstadoConsumo($ticketId);
            if ($estadoConsumo === 'CONFIRMADO') {
                $consumo = $this->consumoRepo->getConsumoByTicket($ticketId);
                $movimientos = $this->inventarioRepo->getMovimientosByTicket($ticketId);

                return new PosConsumptionResult(
                    ticketId: $ticketId,
                    status: 'ALREADY_PROCESSED',
                    consumos: $this->formatConsumos($consumo['detalles'] ?? []),
                    message: 'Ticket ya tiene consumo confirmado',
                    meta: [
                        'num_movimientos' => count($movimientos),
                        'fecha_confirmacion' => $consumo['header']['fecha_confirmacion'] ?? null,
                    ]
                );
            }

            // Si llegamos aquí, el ticket podría ser procesado por el trigger automático
            // o podría estar pendiente. Consultamos el estado actual.
            $consumo = $this->consumoRepo->getConsumoByTicket($ticketId);

            if (empty($consumo)) {
                return new PosConsumptionResult(
                    ticketId: $ticketId,
                    status: 'OK',
                    message: 'Ticket sin consumo registrado (posiblemente pendiente de trigger)',
                    meta: [
                        'ticket_paid' => $header['paid'] ?? false,
                        'ticket_voided' => $header['voided'] ?? false,
                    ]
                );
            }

            return new PosConsumptionResult(
                ticketId: $ticketId,
                status: 'OK',
                consumos: $this->formatConsumos($consumo['detalles'] ?? []),
                message: 'Consumo registrado',
                meta: [
                    'estado' => $estadoConsumo,
                ]
            );
        } catch (\Exception $e) {
            Log::error('Error en ingestarTicket', [
                'ticket_id' => $ticketId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return new PosConsumptionResult(
                ticketId: $ticketId,
                status: 'ERROR',
                message: 'Error al ingestar ticket: ' . $e->getMessage()
            );
        }
    }

    /**
     * Reprocesa un ticket histórico que no tenía receta mapeada
     *
     * @param int $ticketId
     * @param int $userId
     * @return PosConsumptionResult
     */
    public function reprocesarTicket(int $ticketId, int $userId): PosConsumptionResult
    {
        try {
            DB::connection('pgsql')->beginTransaction();

            // 1. Verificar que el ticket existe
            $header = $this->ticketRepo->getTicketHeader($ticketId);
            if (!$header) {
                DB::connection('pgsql')->rollBack();
                return new PosConsumptionResult(
                    ticketId: $ticketId,
                    status: 'ERROR',
                    message: 'Ticket no encontrado'
                );
            }

            // 2. Verificar si ya tiene consumo confirmado
            if ($this->consumoRepo->hasMovInvForTicket($ticketId)) {
                DB::connection('pgsql')->rollBack();
                return new PosConsumptionResult(
                    ticketId: $ticketId,
                    status: 'ALREADY_PROCESSED',
                    message: 'El ticket ya tiene movimientos de inventario registrados'
                );
            }

            // 3. Expandir consumo (llama a fn_expandir_consumo_ticket)
            DB::connection('pgsql')->select("
                SELECT selemti.fn_expandir_consumo_ticket(?)
            ", [$ticketId]);

            // 4. Confirmar consumo con flag de reproceso
            DB::connection('pgsql')->select("
                SELECT selemti.fn_confirmar_consumo_ticket(?, true)
            ", [$ticketId]);

            // 5. Registrar en log de reprocesos
            DB::connection('pgsql')->table('selemti.pos_reprocess_log')->insert([
                'ticket_id' => $ticketId,
                'user_id' => $userId,
                'reprocessed_at' => now(),
                'motivo' => 'Reproceso manual por falta de mapeo histórico',
                'meta' => json_encode([
                    'ticket_total' => $header['total_amount'] ?? 0,
                    'ticket_date' => $header['create_date'] ?? null,
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::connection('pgsql')->commit();

            // 6. Obtener detalles del consumo procesado
            $consumo = $this->consumoRepo->getConsumoByTicket($ticketId);
            $movimientos = $this->inventarioRepo->getMovimientosByTicket($ticketId);

            return new PosConsumptionResult(
                ticketId: $ticketId,
                status: 'REPROCESSED',
                consumos: $this->formatConsumos($consumo['detalles'] ?? []),
                message: 'Ticket reprocesado exitosamente',
                meta: [
                    'num_movimientos' => count($movimientos),
                    'user_id' => $userId,
                    'fecha_reproceso' => now()->toIso8601String(),
                ]
            );
        } catch (\Exception $e) {
            DB::connection('pgsql')->rollBack();

            Log::error('Error en reprocesarTicket', [
                'ticket_id' => $ticketId,
                'user_id' => $userId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return new PosConsumptionResult(
                ticketId: $ticketId,
                status: 'ERROR',
                message: 'Error al reprocesar ticket: ' . $e->getMessage()
            );
        }
    }

    /**
     * Reversa el consumo de un ticket
     *
     * @param int $ticketId
     * @param int $userId
     * @param string|null $motivo
     * @return PosConsumptionResult
     */
    public function reversarTicket(int $ticketId, int $userId, ?string $motivo = null): PosConsumptionResult
    {
        try {
            DB::connection('pgsql')->beginTransaction();

            // 1. Verificar que el ticket existe
            $header = $this->ticketRepo->getTicketHeader($ticketId);
            if (!$header) {
                DB::connection('pgsql')->rollBack();
                return new PosConsumptionResult(
                    ticketId: $ticketId,
                    status: 'ERROR',
                    message: 'Ticket no encontrado'
                );
            }

            // 2. Verificar que tiene consumo para reversar
            if (!$this->consumoRepo->hasMovInvForTicket($ticketId)) {
                DB::connection('pgsql')->rollBack();
                return new PosConsumptionResult(
                    ticketId: $ticketId,
                    status: 'ERROR',
                    message: 'El ticket no tiene movimientos de inventario para reversar'
                );
            }

            // 3. Obtener detalles antes de reversar
            $consumoAntes = $this->consumoRepo->getConsumoByTicket($ticketId);
            $movimientosAntes = $this->inventarioRepo->getMovimientosByTicket($ticketId);

            // 4. Llamar función de reversa
            DB::connection('pgsql')->select("
                SELECT selemti.fn_reversar_consumo_ticket(?)
            ", [$ticketId]);

            // 5. Registrar en log de reversas
            DB::connection('pgsql')->table('selemti.pos_reverse_log')->insert([
                'ticket_id' => $ticketId,
                'user_id' => $userId,
                'reversed_at' => now(),
                'motivo' => $motivo ?? 'Reversa manual',
                'meta' => json_encode([
                    'ticket_total' => $header['total_amount'] ?? 0,
                    'ticket_date' => $header['create_date'] ?? null,
                    'num_movimientos_reversados' => count($movimientosAntes),
                    'consumo_detalles' => $consumoAntes['detalles'] ?? [],
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::connection('pgsql')->commit();

            return new PosConsumptionResult(
                ticketId: $ticketId,
                status: 'REVERSED',
                message: 'Ticket reversado exitosamente',
                meta: [
                    'num_movimientos_reversados' => count($movimientosAntes),
                    'user_id' => $userId,
                    'fecha_reversa' => now()->toIso8601String(),
                    'motivo' => $motivo,
                ]
            );
        } catch (\Exception $e) {
            DB::connection('pgsql')->rollBack();

            Log::error('Error en reversarTicket', [
                'ticket_id' => $ticketId,
                'user_id' => $userId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return new PosConsumptionResult(
                ticketId: $ticketId,
                status: 'ERROR',
                message: 'Error al reversar ticket: ' . $e->getMessage()
            );
        }
    }

    /**
     * Diagnostica el estado de un ticket
     *
     * @param int $ticketId
     * @return PosConsumptionDiagnostics
     */
    public function diagnosticarTicket(int $ticketId): PosConsumptionDiagnostics
    {
        try {
            // 1. Verificar header del ticket
            $header = $this->ticketRepo->getTicketHeader($ticketId);
            $ticketHeaderOk = !empty($header);

            if (!$ticketHeaderOk) {
                return new PosConsumptionDiagnostics(
                    ticketHeaderOk: false,
                    itemsTotal: 0,
                    itemsConReceta: 0,
                    itemsSinReceta: 0,
                    tieneConsumoConfirmado: false,
                    estadoConsumo: 'SIN_DATOS',
                    puedeReprocesar: false,
                    puedeReversar: false,
                    faltanEmpaquesToGo: false,
                    faltanConsumiblesOperativos: false,
                    warnings: ['Ticket no encontrado']
                );
            }

            // 2. Obtener items del ticket
            $items = $this->ticketRepo->getTicketItems($ticketId);
            $itemsTotal = count($items);

            // 3. Verificar cuántos items tienen receta mapeada
            $itemsConReceta = 0;
            $itemsSinReceta = 0;
            $itemsSinRecetaDetalle = [];

            foreach ($items as $item) {
                $itemName = $item['item_name'] ?? $item['name'] ?? 'Unknown';
                $posCode = $itemName; // Simplificado, en realidad podría ser un código específico

                if ($this->recetaRepo->hasActiveMapping($posCode)) {
                    $itemsConReceta++;
                } else {
                    $itemsSinReceta++;
                    $itemsSinRecetaDetalle[] = [
                        'item_id' => $item['id'],
                        'item_name' => $itemName,
                        'quantity' => $item['quantity'] ?? 1,
                    ];
                }
            }

            // 4. Verificar estado del consumo
            $estadoConsumo = $this->consumoRepo->getEstadoConsumo($ticketId);
            if (!$estadoConsumo) {
                $estadoConsumo = 'SIN_DATOS';
            }

            $tieneConsumoConfirmado = $estadoConsumo === 'CONFIRMADO';
            $hasMovInv = $this->consumoRepo->hasMovInvForTicket($ticketId);

            // 5. Determinar si puede reprocesar
            $puedeReprocesar = !$hasMovInv && $itemsTotal > 0;

            // 6. Determinar si puede reversar
            $puedeReversar = $hasMovInv && $estadoConsumo !== 'ANULADO';

            // 7. Verificar empaques y consumibles
            $faltanEmpaquesToGo = $this->consumoRepo->faltanEmpaquesToGo($ticketId);
            $faltanConsumiblesOperativos = $this->consumoRepo->faltanConsumiblesOperativos($ticketId);

            // 8. Warnings
            $warnings = [];
            if ($itemsSinReceta > 0) {
                $warnings[] = "Hay {$itemsSinReceta} items sin receta mapeada";
            }
            if ($faltanEmpaquesToGo) {
                $warnings[] = 'Faltan empaques to-go en el consumo';
            }
            if ($faltanConsumiblesOperativos) {
                $warnings[] = 'Faltan consumibles operativos en el consumo';
            }
            if (!$header['paid'] ?? false) {
                $warnings[] = 'Ticket no está pagado';
            }
            if ($header['voided'] ?? false) {
                $warnings[] = 'Ticket está anulado';
            }

            return new PosConsumptionDiagnostics(
                ticketHeaderOk: $ticketHeaderOk,
                itemsTotal: $itemsTotal,
                itemsConReceta: $itemsConReceta,
                itemsSinReceta: $itemsSinReceta,
                tieneConsumoConfirmado: $tieneConsumoConfirmado,
                estadoConsumo: $estadoConsumo,
                puedeReprocesar: $puedeReprocesar,
                puedeReversar: $puedeReversar,
                faltanEmpaquesToGo: $faltanEmpaquesToGo,
                faltanConsumiblesOperativos: $faltanConsumiblesOperativos,
                itemsSinRecetaDetalle: $itemsSinRecetaDetalle,
                warnings: $warnings
            );
        } catch (\Exception $e) {
            Log::error('Error en diagnosticarTicket', [
                'ticket_id' => $ticketId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return new PosConsumptionDiagnostics(
                ticketHeaderOk: false,
                itemsTotal: 0,
                itemsConReceta: 0,
                itemsSinReceta: 0,
                tieneConsumoConfirmado: false,
                estadoConsumo: 'ERROR',
                puedeReprocesar: false,
                puedeReversar: false,
                faltanEmpaquesToGo: false,
                faltanConsumiblesOperativos: false,
                warnings: ['Error al diagnosticar: ' . $e->getMessage()]
            );
        }
    }

    /**
     * Recalcula el costo estándar de una receta
     *
     * @param int $recipeId
     * @return void
     * @throws \Exception
     */
    public function recalcularCostoReceta(int $recipeId): void
    {
        try {
            // Llamar al stored procedure de snapshot de costo
            DB::connection('pgsql')->select("
                SELECT selemti.sp_snapshot_recipe_cost(?, NOW())
            ", [$recipeId]);

            Log::info('Costo de receta recalculado', [
                'recipe_id' => $recipeId,
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            Log::error('Error al recalcular costo de receta', [
                'recipe_id' => $recipeId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            throw $e;
        }
    }

    /**
     * Formatea los consumos para la respuesta
     *
     * @param array $detalles
     * @return array
     */
    protected function formatConsumos(array $detalles): array
    {
        $formatted = [];

        foreach ($detalles as $det) {
            $itemId = $det['item_id'] ?? null;
            $qty = (float) ($det['qty'] ?? 0);
            $uom = $det['uom'] ?? 'UNI';

            if (!$itemId) {
                continue;
            }

            $costoUnitario = $this->costosRepo->getItemUnitCostNow($itemId, $uom);
            $costoTotal = $costoUnitario * $qty;

            $formatted[] = [
                'item_id' => $itemId,
                'description' => $det['item_descripcion'] ?? 'Unknown',
                'qty' => $qty,
                'uom' => $uom,
                'costo_unitario' => round($costoUnitario, 2),
                'costo_total' => round($costoTotal, 2),
            ];
        }

        return $formatted;
    }
}
