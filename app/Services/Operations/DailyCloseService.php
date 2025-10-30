<?php

namespace App\Services\Operations;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Throwable;

class DailyCloseService
{
    protected string $traceId;
    protected Carbon $date;
    protected string $branchId;
    protected string $connection = 'pgsql'; // Conexión a PostgreSQL
    protected PosConsumptionService $posConsumptionService;

    public function __construct(PosConsumptionService $posConsumptionService)
    {
        $this->traceId = uniqid('close_');
        $this->posConsumptionService = $posConsumptionService;
    }

    /**
     * Orquesta el proceso de cierre diario para una sucursal y fecha.
     */
    public function run(string $branchId, string $date): array
    {
        $this->branchId = $branchId;
        $this->date = Carbon::parse($date)->timezone('America/Mexico_City');

        $this->log('info', 'start', ['branch' => $this->branchId, 'date' => $this->date->toDateString()]);

        if (!$this->acquireLock()) {
            $this->log('info', 'already_done', ['message' => 'Process already running or completed for this date and branch.']);
            return ['status' => 'already_done'];
        }

        try {
            $posOk = $this->checkPosSync();
            if (!$posOk) {
                $this->log('warning', 'pending_pos', ['message' => 'POS sync not complete. Aborting.']);
                return $this->buildStatus(pos_ok: false);
            }

            $consumptionResult = $this->processTheoreticalConsumption();
            $operationalMovesOk = $this->checkOperationalMoves();
            $countsOk = $this->checkInventoryCounts();
            $snapshotOk = $this->generateDailySnapshot();

            $finalStatus = $this->buildStatus(
                pos_ok: $posOk,
                consumo_ok: $consumptionResult['status'],
                movs_ok: $operationalMovesOk,
                conteos_ok: $countsOk,
                snapshot_ok: $snapshotOk
            );

            $this->log('info', 'finish', $finalStatus);

            return $finalStatus;

        } catch (Throwable $e) {
            $this->log('error', 'process_failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);
            // Devuelve un estado de fallo general
            return $this->buildStatus();
        }
    }

    protected function acquireLock(): bool
    {
        $key = "close:lock:{$this->branchId}:{$this->date->toDateString()}";
        // Intenta obtener un lock por 23 horas. Si no está disponible, retorna false.
        return Cache::lock($key, 82800)->get();
    }

    protected function checkPosSync(): bool
    {
        $this->log('info', 'step_check_pos_sync', ['status' => 'started']);

        $isComplete = DB::connection($this->connection)
            ->table('selemti.pos_sync_batches')
            ->where('branch_id', $this->branchId)
            ->where('batch_date', $this->date->toDateString())
            ->where('status', 'COMPLETED')
            ->exists();

        $this->log('info', 'step_check_pos_sync', ['status' => 'completed', 'result' => $isComplete]);
        return $isComplete;
    }



    protected function checkOperationalMoves(): bool
    {
        $this->log('info', 'step_check_operational_moves', ['status' => 'started']);
        $hasPending = false;

        // Asumo estados 'PENDIENTE' o 'BORRADOR'. Ajustar si los estados son otros.
        $pendingReceptions = DB::connection($this->connection)->table('selemti.recepcion_cab')
            ->where('sucursal_id', $this->branchId)
            ->whereDate('fecha_recepcion', $this->date->toDateString())
            ->where('status', '!=', 'POSTED')->count();

        $pendingTransfers = DB::connection($this->connection)->table('selemti.transferencias')
            ->where(fn($q) => $q->where('origen_id', $this->branchId)->orWhere('destino_id', $this->branchId))
            ->whereDate('fecha_transferencia', $this->date->toDateString())
            ->where('status', '!=', 'APPLIED')->count();

        if ($pendingReceptions > 0 || $pendingTransfers > 0) {
            $hasPending = true;
            $this->log('warning', 'step_check_operational_moves', [
                'status' => 'completed_with_warnings',
                'pending_receptions' => $pendingReceptions,
                'pending_transfers' => $pendingTransfers,
            ]);
        } else {
            $this->log('info', 'step_check_operational_moves', ['status' => 'completed', 'pending_docs' => 0]);
        }

        // El cierre no se detiene, solo se reporta. Por eso retorna true.
        return true;
    }

    protected function checkInventoryCounts(): bool
    {
        $this->log('info', 'step_check_inventory_counts', ['status' => 'started']);

        $openCounts = DB::connection($this->connection)->table('selemti.inventory_counts')
            ->where('branch_id', $this->branchId)
            ->whereDate('count_date', $this->date->toDateString())
            ->where('status', '!=', 'CLOSED')->count();

        if ($openCounts > 0) {
            $this->log('warning', 'step_check_inventory_counts', [
                'status' => 'completed_with_warnings',
                'open_counts' => $openCounts
            ]);
        } else {
            $this->log('info', 'step_check_inventory_counts', ['status' => 'completed', 'open_counts' => 0]);
        }

        // El cierre no se detiene, solo se reporta.
        return true;
    }

    protected function generateDailySnapshot(): bool
    {
        $this->log('info', 'step_generate_snapshot', ['status' => 'started']);

        // 1. Obtener todos los items con movimiento en la sucursal para optimizar.
        $itemIds = DB::connection($this->connection)->table('selemti.mov_inv')
            ->where('branch_id', $this->branchId)
            ->distinct('item_id')->pluck('item_id');

        $snapshotData = [];
        $dateEnd = $this->date->copy()->endOfDay();

        // 2. Obtener conteos físicos del día si existen.
        $physicalCounts = DB::connection($this->connection)->table('selemti.inventory_count_lines as l')
            ->join('selemti.inventory_counts as h', 'h.id', '=', 'l.inventory_count_id')
            ->where('h.branch_id', $this->branchId)
            ->whereDate('h.count_date', $this->date->toDateString())
            ->where('h.status', 'CLOSED')
            ->pluck('l.physical_qty', 'l.item_id');

        foreach ($itemIds as $itemId) {
            // 3. Calcular el stock teórico sumando todos los movimientos hasta el final del día.
            $theoreticalQty = DB::connection($this->connection)->table('selemti.mov_inv')
                ->where('branch_id', $this->branchId)
                ->where('item_id', $itemId)
                ->where('created_at', '<=', $dateEnd)
                ->sum('cantidad');

            // 4. Obtener el costo promedio actual del item.
            $unitCost = DB::connection($this->connection)->table('selemti.items')
                ->where('id', $itemId)->value('costo_promedio');

            $snapshotData[] = [
                'snapshot_date' => $this->date->toDateString(),
                'branch_id' => $this->branchId,
                'item_id' => $itemId,
                'teorico_qty' => $theoreticalQty,
                'costo_unit_efectivo' => $unitCost,
                'fisico_qty' => $physicalCounts[$itemId] ?? null, // Llenar si hubo conteo
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        if (!empty($snapshotData)) {
            // 5. Usar upsert para insertar o actualizar.
            DB::connection($this->connection)->table('selemti.inventory_snapshot')->upsert(
                $snapshotData,
                ['snapshot_date', 'branch_id', 'item_id'], // Unique constraint
                ['teorico_qty', 'costo_unit_efectivo', 'fisico_qty', 'updated_at'] // Columns to update on conflict
            );
        }

        $this->log('info', 'step_generate_snapshot', ['status' => 'completed', 'items_snapshotted' => count($snapshotData)]);
        return true;
    }

    protected function buildStatus(
        bool $pos_ok = false,
        bool $consumo_ok = false,
        bool $movs_ok = false,
        bool $conteos_ok = false,
        bool $snapshot_ok = false
    ): array {
        $closed = $pos_ok && $consumo_ok && $snapshot_ok; // movs y conteos no bloquean
        return [
            'closed' => $closed,
            'semaphore' => [
                'pos_ok' => $pos_ok,
                'consumo_ok' => $consumo_ok,
                'movs_ok' => $movs_ok,
                'conteos_ok' => $conteos_ok,
                'snapshot_ok' => $snapshot_ok,
            ]
        ];
    }

    protected function log(string $level, string $step, array $meta = []): void
    {
        // Conforme a METRICS_EVENTS_SCHEMA.md
        $logData = [
            'trace_id' => $this->traceId,
            'branch_id' => $this->branchId ?? null,
            'date' => isset($this->date) ? $this->date->toDateString() : null,
            'step' => $step,
            'level' => $level,
            'meta' => $meta,
        ];

        // Asumiendo que existe un canal 'daily_close' configurado en logging.php
        Log::channel('daily_close')->{$level}(json_encode($logData, JSON_UNESCAPED_UNICODE));
    }
}