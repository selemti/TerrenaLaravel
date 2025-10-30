<?php

namespace App\Livewire\Pos;

use App\Models\PosMap;
use Livewire\Component;
use Livewire\WithPagination;

class PosMappingIndex extends Component
{
    use WithPagination;

    public $search = '';
    public $tipo = '';
    public $perPage = 10;
    public $showForm = false;
    public $editingId = null;

    protected $queryString = ['search', 'tipo', 'perPage'];

    public function render()
    {
        $query = PosMap::query();

        if ($this->search) {
            $query->where(function($q) {
                $q->where('plu', 'like', '%' . $this->search . '%')
                  ->orWhere('receta_id', 'like', '%' . $this->search . '%');
            });
        }

        if ($this->tipo) {
            $query->where('tipo', $this->tipo);
        }

        // No hay columnas 'sucursal_id' ni 'activo' en la tabla pos_map en el esquema actual, quitamos estos filtros

        $mappings = $query->with(['recipe:id,nombre_plato'])
                         ->orderBy('created_at', 'desc')
                         ->paginate($this->perPage);

        // Obtener valores únicos para filtros
        $tipos = PosMap::distinct('tipo')->pluck('tipo');

        return view('livewire.pos.pos-mapping-index', [
            'mappings' => $mappings,
            'tipos' => $tipos,
        ]);
    }

    public function delete($id)
    {
        $mapping = PosMap::find($id);
        if ($mapping) {
            $mapping->delete();
            $this->dispatch('notify', 'Mapeo eliminado correctamente');
        }
    }

    public function edit($id)
    {
        $this->editingId = $id;
        $this->showForm = true;
    }

    public function create()
    {
        $this->editingId = null;
        $this->showForm = true;
    }

    public function closeForm()
    {
        $this->showForm = false;
        $this->editingId = null;
    }
}