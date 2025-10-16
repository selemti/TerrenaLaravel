<?php

namespace App\Livewire\Recipes;

use Livewire\Component;
use Livewire\WithPagination;
use App\Models\Inv\ConversionUnidad;
use App\Models\Inv\Unidad;

class ConversionesIndex extends Component
{
    use WithPagination;

    public ?int $from_id = null;
    public ?int $to_id = null;
    public string $factor = '1.000000';
    public ?int $editId = null;

    protected $rules = [
        'from_id' => 'required|integer|different:to_id',
        'to_id'   => 'required|integer|different:from_id',
        'factor'  => 'required|regex:/^\d+(\.\d{1,6})?$/',
    ];

    public function new()
    {
        $this->reset(['editId','from_id','to_id','factor']);
        $this->factor = '1.000000';
    }

    public function edit(int $id)
    {
        $c = ConversionUnidad::findOrFail($id);
        $this->editId = $c->id;
        $this->from_id = $c->from_id ?? $c->uom_from_id ?? null;
        $this->to_id   = $c->to_id   ?? $c->uom_to_id   ?? null;
        $this->factor  = (string)($c->factor ?? $c->ratio ?? '1.000000');
    }

    public function save()
    {
        $data = $this->validate();
        ConversionUnidad::updateOrCreate(
            ['id' => $this->editId],
            [
                'from_id' => $data['from_id'],
                'to_id'   => $data['to_id'],
                'factor'  => $data['factor'],
            ]
        );
        session()->flash('ok','Guardado');
        $this->new();
    }

    public function delete(int $id)
    {
        ConversionUnidad::findOrFail($id)->delete();
        session()->flash('ok','Eliminado');
    }

    public function render()
    {
        $rows = ConversionUnidad::with(['from','to'])->paginate(10);
        $unidades = Unidad::orderBy('nombre')->get();
        return view('livewire.recipes.conversiones-index', compact('rows','unidades'))
            ->layout('layouts.terrena', ['active' => 'recetas']);
    }
}
