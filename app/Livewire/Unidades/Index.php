<?php

namespace App\Livewire\Unidades;

use Livewire\Component;
use Livewire\WithPagination;
use App\Models\Inv\Unidad;
use Illuminate\Validation\Rule;

class Index extends Component
{
    use WithPagination;

    // Propiedades de Búsqueda y Control
    public $search = '';
    public $editId = null;
    public $showModal = false; // Usado solo para el estado interno/validación

    // Propiedades mapeadas a los campos del formulario (Tu vista las espera)
    public $clave = ''; // Mapea a 'codigo' en la BD
    public $nombre = '';
    public $activo = true;
    
    // Campos faltantes en tu formulario Blade (pero necesarios para la tabla de BD)
    public $tipo = 'UNIDAD'; 
    public $categoria = 'CULINARIO';
    public $es_base = false;
    public $factor_conversion_base = 1.0;
    public $decimales = 0;

    // Reglas de validación para el formulario
    protected function rules()
    {
        return [
            // El 'codigo' (Clave) debe ser único excepto para la unidad que se está editando.
            'clave' => [
                'required', 
                'string', 
                'max:10', 
                Rule::unique('selemti.unidades_medida', 'codigo')->ignore($this->editId, 'id'),
            ],
            'nombre' => 'required|string|max:64',
            'activo' => 'boolean',
            
            // Reglas para campos no visibles en el formulario (si no se envían, Laravel usa por defecto)
            'tipo' => 'required|string', 
            'categoria' => 'required|string',
            'es_base' => 'boolean',
            'factor_conversion_base' => 'required|numeric|min:0.000001',
            'decimales' => 'required|integer|min:0|max:6',
        ];
    }
    
    // Hook: Reinicia la paginación cuando cambia la búsqueda
    public function updatedSearch()
    {
        $this->resetPage();
    }

    // Hook: Se ejecuta después de actualizar la propiedad $clave o $nombre
    public function updated($property)
    {
        if ($property === 'clave' || $property === 'nombre') {
            $this->validateOnly($property);
        }
    }

    // Abre el modal en modo "Crear"
    public function create()
    {
        $this->reset(['editId', 'clave', 'nombre', 'activo', 'tipo', 'categoria', 'es_base', 'factor_conversion_base', 'decimales']);
        $this->showModal = true;
        // Muestra el modal de Bootstrap desde JS
        $this->dispatch('show-modal'); 
    }

    // Abre el modal en modo "Editar"
    public function edit($id)
    {
        $unidad = Unidad::findOrFail($id);
        
        $this->editId = $unidad->id;
        $this->clave = $unidad->codigo; // Mapeo Clave (Blade) -> Codigo (BD)
        $this->nombre = $unidad->nombre;
        $this->activo = $unidad->activo;
        
        // Carga el resto de campos (aunque no estén en el modal de tu vista, son obligatorios en la BD)
        $this->tipo = $unidad->tipo;
        $this->categoria = $unidad->categoria;
        $this->es_base = $unidad->es_base;
        $this->factor_conversion_base = $unidad->factor_conversion_base;
        $this->decimales = $unidad->decimales;
        
        $this->showModal = true;
        $this->dispatch('show-modal');
    }

    // Guarda/Actualiza la unidad
    public function save()
    {
        // Validación completa
        $this->validate();

        // Mapeo de Blade a DB
        $data = [
            'codigo' => strtoupper($this->clave),
            'nombre' => $this->nombre,
            'activo' => $this->activo,
            
            // Campos que deberían estar en el formulario (pero los forzamos para evitar NULL)
            'tipo' => $this->tipo, 
            'categoria' => $this->categoria,
            'es_base' => $this->es_base,
            'factor_conversion_base' => $this->factor_conversion_base,
            'decimales' => $this->decimales,
        ];

        if ($this->editId) {
            // Actualizar
            Unidad::where('id', $this->editId)->update($data);
            session()->flash('ok', 'Unidad de medida actualizada con éxito.');
        } else {
            // Crear
            $data['created_at'] = now(); // La tabla no usa los timestamps automáticos de Laravel
            Unidad::create($data);
            session()->flash('ok', 'Unidad de medida creada con éxito.');
        }
        
        $this->dispatch('hide-modal');
        $this->resetPage();
        $this->reset(['editId', 'clave', 'nombre', 'activo']);
    }
    
    // Elimina la unidad
    public function delete($id)
    {
        try {
            Unidad::destroy($id);
            session()->flash('ok', 'Unidad eliminada exitosamente.');
        } catch (\Exception $e) {
            session()->flash('error', 'No se pudo eliminar la unidad. Puede estar en uso.');
        }
    }

    // Método principal para renderizar la vista con datos
    public function render()
    {
        $query = Unidad::query();

        if (!empty($this->search)) {
            $query->where(function ($q) {
                // Tu vista usa $r->clave y $r->nombre, por eso buscamos en ambas.
                $q->where('codigo', 'ilike', '%' . $this->search . '%')
                  ->orWhere('nombre', 'ilike', '%' . $this->search . '%');
            });
        }
        
        // Preparamos los datos para que Blade los consuma
        $rows = $query->paginate(10)
            ->through(function ($unidad) {
                // Mapeamos el campo 'codigo' de la BD a 'clave' que espera la vista
                $unidad->clave = $unidad->codigo; 
                return $unidad;
            });

        return view('livewire.unidades.index', [
            'rows' => $rows,
        ])->extends('layouts.terrena');
    }
}