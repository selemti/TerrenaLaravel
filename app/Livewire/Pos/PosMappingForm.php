<?php

namespace App\Livewire\Pos;

use App\Models\PosMap;
use App\Models\Rec\Receta;
use Livewire\Component;

class PosMappingForm extends Component
{
    public ?PosMap $mapping = null;
    public $tipo = '';
    public $plu = '';
    public $receta_id = '';
    public $recipe_version_id = '';
    public $valid_from = '';
    public $valid_to = '';
    public $vigente_desde = '';
    // No hay campos 'sucursal_id' ni 'activo' en la tabla pos_map en el esquema actual
    public $showForm = false;

    protected $rules = [
        'tipo' => 'required|in:MENU,MODIFIER',
        'plu' => 'required|string|max:50',
        'receta_id' => 'nullable|string|max:50',
        'recipe_version_id' => 'nullable|integer',
        'valid_from' => 'nullable|date',
        'valid_to' => 'nullable|date|after_or_equal:valid_from',
        'vigente_desde' => 'nullable|date',
        'sucursal_id' => 'nullable|string|max:50',
    ];

    public function mount(?int $mappingId = null)
    {
        if ($mappingId) {
            $this->mapping = PosMap::find($mappingId);
            if ($this->mapping) {
                $this->fill($this->mapping->toArray());
            }
        }
    }

    public function render()
    {
        $recetas = Receta::orderBy('nombre_plato')->get(['id', 'nombre_plato']);

        return view('livewire.pos.pos-mapping-form', [
            'recetas' => $recetas,
        ]);
    }

    public function save()
    {
        $this->validate();

        if ($this->mapping) {
            $this->mapping->update($this->getDirty());
            $this->dispatch('notify', 'Mapeo actualizado correctamente');
        } else {
            PosMap::create($this->only(
                'tipo', 'plu', 'receta_id', 'recipe_version_id', 
                'valid_from', 'valid_to', 'vigente_desde'
            ));
            $this->dispatch('notify', 'Mapeo creado correctamente');
        }

        // Reset form
        $this->reset();
        $this->dispatch('form-closed');
    }

    public function resetForm()
    {
        $this->reset();
        $this->dispatch('form-closed');
    }

    protected function getDirty()
    {
        $dirty = [];
        foreach ($this->rules as $key => $rule) {
            if (property_exists($this, $key) && $this->{$key} !== $this->mapping->{$key}) {
                $dirty[$key] = $this->{$key};
            }
        }
        return $dirty;
    }
}