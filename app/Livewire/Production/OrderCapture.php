<?php

namespace App\Livewire\Production;

use Illuminate\Support\Facades\DB;
use Livewire\Component;

class OrderCapture extends Component
{
    public int $orderId;

    // Captura de salida de producto
    public float $qtyProducida = 0.0;

    public float $qtyMerma = 0.0;

    public string $loteProducido = '';

    public string $fechaCaducidad = '';

    public string $notas = '';

    protected $rules = [
        'qtyProducida' => 'required|numeric|min:0.001',
        'qtyMerma' => 'required|numeric|min:0',
        'loteProducido' => 'nullable|string|max:120',
        'fechaCaducidad' => 'nullable|date',
        'notas' => 'nullable|string|max:500',
    ];

    public function completar()
    {
        $this->validate();

        $orden = DB::connection('pgsql')
            ->table('selemti.production_orders')
            ->where('id', $this->orderId)
            ->where('estado', 'EN_PROCESO')
            ->first();

        if (! $orden) {
            session()->flash('error', 'La orden debe estar EN_PROCESO para capturar producción.');

            return;
        }

        DB::connection('pgsql')->transaction(function () use ($orden) {
            // Registrar output
            DB::connection('pgsql')->table('selemti.production_order_outputs')->insert([
                'production_order_id' => $this->orderId,
                'item_id' => $orden->item_id,
                'lote_producido' => $this->loteProducido ?: null,
                'fecha_caducidad' => $this->fechaCaducidad ?: null,
                'qty' => $this->qtyProducida,
                'uom' => $orden->uom_base,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Actualizar orden → COMPLETADA
            DB::connection('pgsql')->table('selemti.production_orders')
                ->where('id', $this->orderId)
                ->update([
                    'estado' => 'COMPLETADO',
                    'qty_producida' => $this->qtyProducida,
                    'qty_merma' => $this->qtyMerma,
                    'cerrado_en' => now(),
                    'notas' => $this->notas ?: null,
                    'updated_at' => now(),
                ]);
        });

        session()->flash('success', 'Producción capturada. La orden queda en estado COMPLETADA, pendiente de posteo.');

        return $this->redirect(route('production.show', $this->orderId), navigate: true);
    }

    public function render()
    {
        $orden = DB::connection('pgsql')
            ->table('selemti.production_orders as po')
            ->leftJoin('selemti.receta_cab as r', 'r.id', '=', 'po.recipe_id')
            ->leftJoin('selemti.items as i', 'i.id', '=', 'po.item_id')
            ->select(['po.*', 'r.nombre as receta_nombre', 'i.nombre as item_nombre', 'i.codigo as item_codigo'])
            ->where('po.id', $this->orderId)
            ->first();

        abort_if(! $orden, 404);

        // Insumos esperados desde receta
        $insumos = DB::connection('pgsql')
            ->table('selemti.receta_det as rd')
            ->leftJoin('selemti.items as i', 'i.id', '=', 'rd.item_id')
            ->leftJoin('selemti.cat_unidades as u', 'u.id', '=', 'rd.uom_id')
            ->select(['rd.*', 'i.nombre as item_nombre', 'i.codigo as item_codigo', 'u.clave as uom_clave'])
            ->where('rd.receta_id', $orden->recipe_id)
            ->get();

        // Stock disponible por insumo
        $stockPorItem = DB::connection('pgsql')
            ->table('selemti.inventory_batch')
            ->whereIn('item_id', $insumos->pluck('item_id')->filter())
            ->whereNull('deleted_at')
            ->selectRaw('item_id, SUM(cantidad_actual) as stock')
            ->groupBy('item_id')
            ->pluck('stock', 'item_id');

        return view('livewire.production.order-capture', compact('orden', 'insumos', 'stockPorItem'))
            ->layout('layouts.terrena', ['active' => 'produccion']);
    }
}
