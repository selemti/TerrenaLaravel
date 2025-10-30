<?php

namespace App\Console\Commands;

use App\Services\Recetas\RecalcularCostosRecetasService;
use Illuminate\Console\Command;

class RecalcularCostosRecetasCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'recetas:recalcular-costos 
                            {--date= : Fecha objetivo para el recálculo (formato YYYY-MM-DD, por defecto ayer)} 
                            {--branch= : ID de la sucursal (opcional)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Recalcular el costo unitario de recetas publicadas y subrecetas cuyo insumo cambió de precio el día anterior, y propagar costo a padres';

    /**
     * Execute the console command.
     */
    public function handle(RecalcularCostosRecetasService $service)
    {
        $date = $this->option('date');
        $branchId = $this->option('branch');

        if (!$date) {
            $date = now()->subDay()->format('Y-m-d');
        }

        $this->info("Iniciando recálculo de costos para la fecha: {$date}" . ($branchId ? " y sucursal: {$branchId}" : ""));

        $result = $service->recalcularCostos($branchId ? (int)$branchId : null, $date);

        if ($result['success']) {
            $this->info("Recálculo de costos completado exitosamente para la fecha {$date}");
            $this->info("Items afectados: " . $result['affected_items']);
            $this->info("Subrecetas afectadas: " . $result['affected_subrecetas']);
            $this->info("Recetas afectadas: " . $result['affected_recetas']);
            $this->info("Alertas generadas: " . $result['alerts_generated']);
        } else {
            $this->error($result['message']);
        }

        return $result['success'] ? 0 : 1;
    }
}