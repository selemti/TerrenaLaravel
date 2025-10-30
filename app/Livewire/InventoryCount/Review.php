<?php

namespace App\Livewire\InventoryCount;

use App\Models\InventoryCount;
use App\Services\Inventory\InventoryCountService;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class Review extends Component
{
    public $countId;
    public $count;

    public string $notas = '';
    public string $filterVariacion = 'all'; // all, exactos, variacion, faltantes, sobrantes
    public bool $showConfirmModal = false;

    public function mount($id)
    {
        $this->countId = $id;
        $this->loadCount();
    }

    protected function loadCount()
    {
        $this->count = InventoryCount::with(['lines.item', 'createdBy'])
            ->findOrFail($this->countId);

        // Verificar que esté en estado correcto
        if ($this->count->estado !== 'EN_PROCESO') {
            abort(403, 'Este conteo no puede ser revisado');
        }
    }

    public function render()
    {
        $query = $this->count->lines()->with('item');

        // Filtrar según tipo de variación
        switch ($this->filterVariacion) {
            case 'exactos':
                $query->whereRaw('ABS(qty_variacion) < 0.000001');
                break;
            case 'variacion':
                $query->whereRaw('ABS(qty_variacion) >= 0.000001');
                break;
            case 'faltantes':
                $query->where('qty_variacion', '<', 0);
                break;
            case 'sobrantes':
                $query->where('qty_variacion', '>', 0);
                break;
        }

        $lines = $query->get();

        // Estadísticas
        $totalLineas = $this->count->lines()->count();
        $exactos = $this->count->lines()->whereRaw('ABS(qty_variacion) < 0.000001')->count();
        $conVariacion = $this->count->lines()->whereRaw('ABS(qty_variacion) >= 0.000001')->count();
        $faltantes = $this->count->lines()->where('qty_variacion', '<', 0)->count();
        $sobrantes = $this->count->lines()->where('qty_variacion', '>', 0)->count();

        return view('livewire.inventory-count.review', [
            'lines' => $lines,
            'totalLineas' => $totalLineas,
            'exactos' => $exactos,
            'conVariacion' => $conVariacion,
            'faltantes' => $faltantes,
            'sobrantes' => $sobrantes,
        ]);
    }

    public function openConfirmModal()
    {
        $this->showConfirmModal = true;
    }

    public function closeConfirmModal()
    {
        $this->showConfirmModal = false;
    }

    public function finalizarConteo()
    {
        try {
            $service = new InventoryCountService();

            // Preparar líneas para finalización
            $lines = $this->count->lines->map(function($line) {
                return [
                    'item_id' => $line->item_id,
                    'inventory_batch_id' => $line->inventory_batch_id,
                    'qty_teorica' => $line->qty_teorica,
                    'qty_contada' => $line->qty_contada,
                    'uom' => $line->uom,
                    'motivo' => $line->motivo,
                ];
            })->toArray();

            $service->finalize(
                $this->countId,
                $lines,
                Auth::id(),
                $this->notas
            );

            $this->dispatch('toast',
                type: 'success',
                body: 'Conteo finalizado y ajustes aplicados correctamente'
            );

            return redirect()->route('inv.counts.detail', ['id' => $this->countId]);

        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al finalizar conteo: ' . $e->getMessage()
            );

            $this->showConfirmModal = false;
        }
    }

    public function volver()
    {
        return redirect()->route('inv.counts.capture', ['id' => $this->countId]);
    }

    public function cancelar()
    {
        return redirect()->route('inv.counts.index');
    }
}
