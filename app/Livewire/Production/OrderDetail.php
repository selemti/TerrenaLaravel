<?php

namespace App\Livewire\Production;

use Illuminate\Support\Facades\DB;
use Livewire\Component;

class OrderDetail extends Component
{
    public int $orderId;

    public function iniciar(): void
    {
        $this->cambiarEstado('BORRADOR', 'EN_PROCESO', ['iniciado_en' => now()]);
        session()->flash('success', 'Orden iniciada.');
    }

    public function cancelar(): void
    {
        $this->cambiarEstado('BORRADOR', 'CANCELADO');
        session()->flash('success', 'Orden cancelada.');
    }

    protected function cambiarEstado(string $from, string $to, array $extra = []): void
    {
        $updated = DB::connection('pgsql')
            ->table('selemti.production_orders')
            ->where('id', $this->orderId)
            ->where('estado', $from)
            ->update(array_merge(['estado' => $to, 'updated_at' => now()], $extra));

        if (! $updated) {
            session()->flash('error', "No se pudo cambiar estado (actual no es {$from}).");
        }
    }

    public function render()
    {
        $orden = DB::connection('pgsql')
            ->table('selemti.production_orders as po')
            ->leftJoin('selemti.receta_cab as r', 'r.id', '=', 'po.recipe_id')
            ->leftJoin('selemti.items as i', 'i.id', '=', 'po.item_id')
            ->select([
                'po.*',
                'r.nombre as receta_nombre',
                'i.nombre as item_nombre',
                'i.codigo as item_codigo',
            ])
            ->where('po.id', $this->orderId)
            ->first();

        abort_if(! $orden, 404);

        $inputs = DB::connection('pgsql')
            ->table('selemti.production_order_inputs as inp')
            ->leftJoin('selemti.items as i', 'i.id', '=', 'inp.item_id')
            ->select(['inp.*', 'i.nombre as item_nombre', 'i.codigo as item_codigo'])
            ->where('inp.production_order_id', $this->orderId)
            ->get();

        $outputs = DB::connection('pgsql')
            ->table('selemti.production_order_outputs as out')
            ->leftJoin('selemti.items as i', 'i.id', '=', 'out.item_id')
            ->select(['out.*', 'i.nombre as item_nombre'])
            ->where('out.production_order_id', $this->orderId)
            ->get();

        $movimientos = DB::connection('pgsql')
            ->table('selemti.mov_inv as m')
            ->leftJoin('selemti.items as i', 'i.id', '=', 'm.item_id')
            ->select(['m.*', 'i.nombre as item_nombre'])
            ->where('m.ref_tipo', 'PROD')
            ->where('m.ref_id', $this->orderId)
            ->orderBy('m.ts')
            ->get();

        return view('livewire.production.order-detail', compact('orden', 'inputs', 'outputs', 'movimientos'))
            ->layout('layouts.terrena', ['active' => 'produccion']);
    }
}
