<?php

namespace App\Jobs;

use App\Services\Replenishment\ReplenishmentService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Job para calcular sugerencias de replenishment automáticamente
 * 
 * Este job debe ejecutarse diariamente (configurado en Kernel.php)
 * y genera sugerencias de compra/producción basadas en políticas de stock.
 * 
 * Algoritmos implementados:
 * - Min-Max: Basado en stock_policy (min/max por ítem/almacén)
 * - SMA: Simple Moving Average (promedio móvil de consumo)
 * - POS Consumption: Basado en tickets históricos expandidos
 * 
 * @see ReplenishmentService
 * @see \App\Console\Kernel::schedule() para configuración del cron
 */
class CalculateReplenishmentSuggestions implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Opciones de ejecución del job
     *
     * @var array{
     *   sucursal_id?: int,
     *   almacen_id?: int,
     *   dias_analisis?: int,
     *   auto_aprobar?: bool,
     *   algoritmo?: string
     * }
     */
    protected array $options;

    /**
     * Create a new job instance.
     *
     * @param array $options Opciones de ejecución
     */
    public function __construct(array $options = [])
    {
        $this->options = $options;
        $this->onQueue('replenishment');
    }

    /**
     * Execute the job.
     *
     * @param ReplenishmentService $service
     * @return void
     */
    public function handle(ReplenishmentService $service): void
    {
        $startTime = microtime(true);
        
        Log::info('🔄 Iniciando cálculo de sugerencias de replenishment', [
            'options' => $this->options,
            'timestamp' => now()->toDateTimeString(),
        ]);

        try {
            // Configurar opciones con defaults
            $options = array_merge([
                'dias_analisis' => 7,
                'auto_aprobar' => false,
                'dry_run' => false,
            ], $this->options);

            // Generar sugerencias usando el servicio
            $resultado = $service->generateDailySuggestions($options);

            $duration = round(microtime(true) - $startTime, 2);

            Log::info('✅ Sugerencias de replenishment generadas exitosamente', [
                'total' => $resultado['total'],
                'compras' => $resultado['compras'],
                'producciones' => $resultado['producciones'],
                'urgentes' => $resultado['urgentes'],
                'normales' => $resultado['normales'],
                'errors' => count($resultado['errors']),
                'duration_seconds' => $duration,
            ]);

            // Si hubo errores, registrarlos detalladamente
            if (!empty($resultado['errors'])) {
                Log::warning('⚠️ Errores durante generación de sugerencias', [
                    'errors' => $resultado['errors'],
                ]);
            }

        } catch (\Exception $e) {
            $duration = round(microtime(true) - $startTime, 2);
            
            Log::error('❌ Error al calcular sugerencias de replenishment', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'duration_seconds' => $duration,
            ]);

            // Re-lanzar la excepción para que Laravel maneje el retry
            throw $e;
        }
    }

    /**
     * Handle a job failure.
     *
     * @param  \Throwable  $exception
     * @return void
     */
    public function failed(\Throwable $exception): void
    {
        Log::critical('💀 Job de replenishment falló definitivamente', [
            'error' => $exception->getMessage(),
            'trace' => $exception->getTraceAsString(),
            'options' => $this->options,
        ]);

        // Aquí podrías enviar notificación al equipo de compras
        // o registrar en una tabla de alertas
    }

    /**
     * Get the tags that should be assigned to the job.
     *
     * @return array<int, string>
     */
    public function tags(): array
    {
        return ['replenishment', 'daily', 'purchasing'];
    }
}
