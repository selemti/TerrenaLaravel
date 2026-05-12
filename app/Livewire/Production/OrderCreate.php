<?php

namespace App\Livewire\Production;

use Illuminate\Support\Facades\DB;
use Livewire\Component;

class OrderCreate extends Component
{
    public ?int $recipeId = null;

    public float $qtyProgramada = 1.0;

    public string $programadoPara = '';

    public string $notas = '';

    protected $rules = [
        'recipeId' => 'required|integer|min:1',
        'qtyProgramada' => 'required|numeric|min:0.001',
        'programadoPara' => 'nullable|date',
        'notas' => 'nullable|string|max:500',
    ];

    protected $messages = [
        'recipeId.required' => 'Selecciona una receta.',
        'qtyProgramada.required' => 'La cantidad programada es obligatoria.',
        'qtyProgramada.min' => 'La cantidad debe ser mayor a 0.',
    ];

    public function save()
    {
        $this->validate();

        $recipe = DB::connection('pgsql')
            ->table('selemti.receta_cab')
            ->where('id', $this->recipeId)
            ->first();

        if (! $recipe) {
            $this->addError('recipeId', 'Receta no encontrada.');

            return;
        }

        $folio = 'PROD-'.date('Ymd').'-'.str_pad(
            DB::connection('pgsql')->table('selemti.production_orders')->count() + 1,
            4, '0', STR_PAD_LEFT
        );

        $id = DB::connection('pgsql')->table('selemti.production_orders')->insertGetId([
            'folio' => $folio,
            'recipe_id' => $this->recipeId,
            'item_id' => $recipe->item_id ?? null,
            'qty_programada' => $this->qtyProgramada,
            'qty_producida' => 0,
            'qty_merma' => 0,
            'uom_base' => $recipe->uom_base ?? 'PZ',
            'estado' => 'BORRADOR',
            'programado_para' => $this->programadoPara ?: null,
            'notas' => $this->notas ?: null,
            'creado_por' => auth()->id(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        session()->flash('success', "Orden {$folio} creada correctamente.");

        return $this->redirect(route('production.show', $id), navigate: true);
    }

    public function render()
    {
        $recetas = DB::connection('pgsql')
            ->table('selemti.receta_cab')
            ->select('id', 'nombre', 'uom_base')
            ->orderBy('nombre')
            ->get();

        return view('livewire.production.order-create', compact('recetas'))
            ->layout('layouts.terrena', ['active' => 'produccion']);
    }
}
