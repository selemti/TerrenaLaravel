<?php

namespace App\Livewire\Inventory;

use Livewire\Component;
use App\Services\Operations\DailyCloseService;
use App\Services\Recetas\RecalcularCostosRecetasService;
use Carbon\Carbon;
use Illuminate\Support\Facades\Artisan;

class OrquestadorPanel extends Component
{
    public $selectedDate;
    public $selectedBranch = '1';
    public $closeStatus = [];
    public $recalculationResult = [];
    public $isProcessing = false;
    public $logOutput = '';

    protected $listeners = ['runDailyProcess' => 'executeDailyProcess'];

    public function mount()
    {
        $this->selectedDate = now()->subDay()->format('Y-m-d'); // Por defecto ayer
    }

    public function runDailyClose()
    {
        $this->isProcessing = true;
        $this->logOutput = "Iniciando cierre diario para {$this->selectedDate}...\n";
        
        try {
            $dailyCloseService = app(DailyCloseService::class);
            $result = $dailyCloseService->run($this->selectedBranch, $this->selectedDate);
            
            $this->closeStatus = $result;
            $this->logOutput .= "Cierre diario completado:\n" . json_encode($result, JSON_PRETTY_PRINT) . "\n";
        } catch (\Exception $e) {
            $this->logOutput .= "Error en cierre diario: " . $e->getMessage() . "\n";
        }
        
        $this->isProcessing = false;
    }

    public function runCostRecalculation()
    {
        $this->isProcessing = true;
        $this->logOutput .= "Iniciando recálculo de costos para {$this->selectedDate}...\n";
        
        try {
            $recalculationService = app(RecalcularCostosRecetasService::class);
            $result = $recalculationService->recalcularCostos($this->selectedBranch, $this->selectedDate);
            
            $this->recalculationResult = $result;
            $this->logOutput .= "Recálculo de costos completado:\n" . json_encode($result, JSON_PRETTY_PRINT) . "\n";
        } catch (\Exception $e) {
            $this->logOutput .= "Error en recálculo de costos: " . $e->getMessage() . "\n";
        }
        
        $this->isProcessing = false;
    }

    public function generateSnapshot()
    {
        $this->isProcessing = true;
        $this->logOutput .= "Generando snapshot de inventario para {$this->selectedDate}...\n";
        
        try {
            // Ejecutar el comando de cierre diario que incluye la generación de snapshots
            $exitCode = Artisan::call('close:daily', [
                '--date' => $this->selectedDate,
                '--branch' => $this->selectedBranch
            ]);
            
            $output = Artisan::output();
            $this->logOutput .= "Comando de snapshot ejecutado (exit code: {$exitCode}):\n{$output}\n";
        } catch (\Exception $e) {
            $this->logOutput .= "Error generando snapshot: " . $e->getMessage() . "\n";
        }
        
        $this->isProcessing = false;
    }

    public function executeDailyProcess()
    {
        $this->runDailyClose();
        $this->runCostRecalculation();
        $this->generateSnapshot();
    }

    public function render()
    {
        return view('livewire.inventory.orquestador-panel');
    }
}