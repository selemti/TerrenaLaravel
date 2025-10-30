<?php

namespace App\Livewire\InventoryCount;

use App\Models\InventoryCount;
use App\Models\InventoryCountLine;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class Capture extends Component
{
    public $countId;
    public $count;

    // Datos de captura
    public array $contados = [];
    public string $search = '';
    public bool $soloSinContar = false;
    public bool $soloConVariacion = false;

    public function mount($id)
    {
        $this->countId = $id;
        $this->loadCount();

        // Inicializar array de contados
        foreach ($this->count->lines as $line) {
            $this->contados[$line->id] = $line->qty_contada;
        }
    }

    protected function loadCount()
    {
        $this->count = InventoryCount::with(['lines.item', 'createdBy'])
            ->findOrFail($this->countId);

        // Verificar que esté en estado correcto
        if ($this->count->estado !== 'EN_PROCESO') {
            abort(403, 'Este conteo no está disponible para captura');
        }
    }

    public function render()
    {
        $query = $this->count->lines()
            ->with('item');

        // Filtro de búsqueda
        if ($this->search) {
            $query->whereHas('item', function($q) {
                $q->where('nombre', 'ILIKE', '%' . $this->search . '%')
                  ->orWhere('codigo', 'ILIKE', '%' . $this->search . '%');
            });
        }

        // Solo sin contar
        if ($this->soloSinContar) {
            $query->where('qty_contada', 0);
        }

        $lines = $query->get();

        // Calcular estadísticas
        $totalItems = $this->count->lines()->count();
        $contados = $this->count->lines()
            ->where('qty_contada', '!=', 0)
            ->count();
        $porcentaje = $totalItems > 0 ? ($contados / $totalItems) * 100 : 0;

        return view('livewire.inventory-count.capture', [
            'lines' => $lines,
            'totalItems' => $totalItems,
            'contados' => $contados,
            'porcentaje' => $porcentaje,
        ]);
    }

    public function actualizarConteo($lineId, $cantidad)
    {
        try {
            $line = InventoryCountLine::findOrFail($lineId);

            $cantidad = (float) $cantidad;

            $line->update([
                'qty_contada' => $cantidad,
                'qty_variacion' => $cantidad - $line->qty_teorica,
            ]);

            $this->contados[$lineId] = $cantidad;

            $this->loadCount(); // Recargar para actualizar estadísticas

        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al actualizar: ' . $e->getMessage()
            );
        }
    }

    public function guardarYContinuar()
    {
        $this->dispatch('toast',
            type: 'success',
            body: 'Captura guardada'
        );

        $this->loadCount();
    }

    public function finalizarCaptura()
    {
        // Verificar que todos estén contados
        $sinContar = $this->count->lines()
            ->where('qty_contada', 0)
            ->count();

        if ($sinContar > 0) {
            $this->dispatch('toast',
                type: 'warning',
                body: "Aún hay {$sinContar} items sin contar. ¿Desea continuar de todos modos?"
            );
        }

        return redirect()->route('inv.counts.review', ['id' => $this->countId]);
    }

    public function cancelar()
    {
        return redirect()->route('inv.counts.index');
    }
}
