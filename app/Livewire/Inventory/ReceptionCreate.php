<?php
namespace App\Livewire\Inventory;

use Livewire\Component;
use Livewire\WithFileUploads;
use App\Services\Inventory\ReceptionService;
use Illuminate\Support\Facades\Storage;

class ReceptionCreate extends Component
{
    use WithFileUploads;

    public $supplier_id;
    public $branch_id, $warehouse_id;
    public $lines = []; // array de líneas del formulario

    public function mount() {
        $this->addLine(); // inicia con 1 línea
    }

    public function addLine() {
        $this->lines[] = [
            'item_id'=>null,
            'qty_pack'=>1,
            'uom_purchase'=>'PZ',
            'pack_size'=>1,
            'uom_base'=>'PZ',
            'lot'=>'',
            'exp_date'=>'',
            'temp'=>null,
            'evidence'=>null, // archivo temporal
            'precio_unit'=>null,
        ];
    }

    public function removeLine($idx) {
        unset($this->lines[$idx]);
        $this->lines = array_values($this->lines);
    }

    public function save(ReceptionService $svc)
    {
        $this->validate([
            'supplier_id' => 'required|integer',
            'lines' => 'required|array|min:1',
            'lines.*.item_id' => 'required|integer',
            'lines.*.qty_pack' => 'required|numeric|min:0.0001',
            'lines.*.pack_size' => 'nullable|numeric|min:0.0001',
            'lines.*.uom_purchase' => 'required|string',
            'lines.*.uom_base' => 'required|string|in:GR,ML,PZ',
            'lines.*.exp_date' => 'nullable|date',
            'lines.*.temp' => 'nullable|numeric',
        ]);

        // subir evidencias
        foreach ($this->lines as $i => $l) {
            if (!empty($l['evidence'])) {
                $path = $l['evidence']->store('evidencias', 'public'); // php artisan storage:link
                $this->lines[$i]['doc_url'] = Storage::disk('public')->url($path);
            }
        }

        $header = [
            'supplier_id' => (int)$this->supplier_id,
            'branch_id'   => $this->branch_id,
            'warehouse_id'=> $this->warehouse_id,
            'user_id'     => auth()->id() ?? 1,
        ];

        $id = $svc->createReception($header, $this->lines);

        session()->flash('ok', "Recepción #{$id} guardada");
        return redirect()->route('inv.receptions');
    }

    public function render()
    {
        // podrías cargar catálogos reales: proveedores, items, UOM, etc.
        $suppliers = [[ 'id'=>1, 'nombre'=>'Proveedor Demo']];
        $items = [
            ['id'=>101, 'nombre'=>'Leche 1L (consumo ML)', 'uom_base'=>'ML'],
            ['id'=>202, 'nombre'=>'Botella Agua (consumo PZ)', 'uom_base'=>'PZ'],
        ];

        return view('inventory.receptions-create', compact('suppliers','items'))
            ->layout('layouts.app', ['title' => 'Nueva Recepción']);
    }
}
