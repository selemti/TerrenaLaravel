<?php

namespace App\Livewire\Pos;

use App\Models\PosMap;
use Livewire\Component;
use Livewire\WithPagination;
use Illuminate\Support\Facades\DB;

class PosMapIndex extends Component
{
    use WithPagination;

    public $plu, $receta_id, $tipo = 'MENU', $valid_from, $valid_to, $vigente_desde;
    public $selected_id;
    public $updateMode = false;
    public $unmappedSales = [];

    protected $rules = [
        'plu' => 'required|string|max:255',
        'receta_id' => 'required|integer',
        'tipo' => 'required|string|in:MENU,MODIFIER',
        'valid_from' => 'nullable|date',
        'valid_to' => 'nullable|date',
        'vigente_desde' => 'nullable|date',
    ];

    public function render()
    {
        $mappings = PosMap::with('recipe')->paginate(10);
        return view('livewire.pos.pos-map-index', compact('mappings'));
    }

    public function mount()
    {
        $this->loadUnmappedSales();
    }

    public function loadUnmappedSales()
    {
        $bdate = now()->format('Y-m-d');
        $sucursal_key = '1'; // Example sucursal_key

        $query = "
            SELECT
              ti.id AS ticket_item_id,
              mi.id AS menu_item_id,
              mi.pg_id AS menu_item_pg_id,
              mi.name AS menu_item_name,
              t.id AS ticket_id,
              t.create_date::date AS fecha_venta,
              t.terminal_id
            FROM public.ticket t
            JOIN public.terminal term
              ON term.id = t.terminal_id
             AND term.location::text = ?
            JOIN public.ticket_item ti
              ON ti.ticket_id = t.id
            LEFT JOIN public.menu_item mi
              ON mi.id = ti.item_id
            LEFT JOIN selemti.pos_map pm
              ON pm.tipo = 'MENU'
             AND (pm.plu = mi.id::text OR pm.plu = mi.pg_id::text)
             AND (
                  (pm.valid_from IS NULL OR pm.valid_from <= ?::date)
              AND (pm.valid_to   IS NULL OR pm.valid_to   >= ?::date)
               OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde::date <= ?::date)
             )
            WHERE t.create_date::date = ?::date
              AND pm.plu IS NULL
            ORDER BY mi.name;
        ";

        $this->unmappedSales = DB::connection('pgsql')->select($query, [$sucursal_key, $bdate, $bdate, $bdate, $bdate]);
    }

    private function resetInput()
    {
        $this->plu = null;
        $this->receta_id = null;
        $this->tipo = 'MENU';
        $this->valid_from = null;
        $this->valid_to = null;
        $this->vigente_desde = null;
        $this->selected_id = null;
        $this->updateMode = false;
    }

    public function store()
    {
        $this->validate();

        PosMap::create([
            'plu' => $this->plu,
            'receta_id' => $this->receta_id,
            'tipo' => $this->tipo,
            'valid_from' => $this->valid_from,
            'valid_to' => $this->valid_to,
            'vigente_desde' => $this->vigente_desde,
        ]);

        $this->resetInput();
        session()->flash('message', 'Mapeo creado exitosamente.');
    }

    public function edit($id)
    {
        $record = PosMap::findOrFail($id);
        $this->selected_id = $id;
        $this->plu = $record->plu;
        $this->receta_id = $record->receta_id;
        $this->tipo = $record->tipo;
        $this->valid_from = $record->valid_from ? $record->valid_from->format('Y-m-d') : null;
        $this->valid_to = $record->valid_to ? $record->valid_to->format('Y-m-d') : null;
        $this->vigente_desde = $record->vigente_desde ? $record->vigente_desde->format('Y-m-d') : null;
        $this->updateMode = true;
    }

    public function update()
    {
        $this->validate();

        if ($this->selected_id) {
            $record = PosMap::find($this->selected_id);
            $record->update([
                'plu' => $this->plu,
                'receta_id' => $this->receta_id,
                'tipo' => $this->tipo,
                'valid_from' => $this->valid_from,
                'valid_to' => $this->valid_to,
                'vigente_desde' => $this->vigente_desde,
            ]);
            $this->resetInput();
            session()->flash('message', 'Mapeo actualizado exitosamente.');
        }
    }

    public function destroy($id)
    {
        if ($id) {
            PosMap::where('id', $id)->delete();
            session()->flash('message', 'Mapeo eliminado exitosamente.');
        }
    }
}