<?php

namespace App\Livewire\Transfers;

use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

/**
 * Listado de transferencias entre almacenes
 */
class Index extends Component
{
    use WithPagination;

    public string $search = '';

    public string $estadoFilter = 'all';

    public function updatingSearch(): void
    {
        $this->resetPage();
    }

    public function updatedEstadoFilter(): void
    {
        $this->resetPage();
    }

    public function render()
    {
        $query = DB::connection('pgsql')
            ->table('selemti.traspaso_cab as t')
            ->leftJoin('selemti.cat_almacenes as ao', 'ao.id', '=', 't.from_bodega_id')
            ->leftJoin('selemti.cat_almacenes as ad', 'ad.id', '=', 't.to_bodega_id')
            ->leftJoin('users as u', 'u.id', '=', 't.usuario_id')
            ->select([
                't.id',
                't.estado',
                'ao.nombre as almacen_origen',
                'ad.nombre as almacen_destino',
                't.created_at',
                'u.name as creado_por',
                DB::raw('(SELECT COUNT(*) FROM selemti.traspaso_det WHERE traspaso_id = t.id) as lineas_count'),
            ])
            ->orderBy('t.id', 'desc');

        if ($this->estadoFilter !== 'all') {
            $query->where('t.estado', $this->estadoFilter);
        }

        if ($this->search) {
            $query->where(function ($q) {
                $q->where(DB::raw('CAST(t.id AS TEXT)'), 'like', "%{$this->search}%")
                    ->orWhere('ao.nombre', 'like', "%{$this->search}%")
                    ->orWhere('ad.nombre', 'like', "%{$this->search}%");
            });
        }

        $transfers = $query->paginate(20);

        return view('livewire.transfers.index', [
            'transfers' => $transfers,
        ])
            ->layout('layouts.terrena', [
                'active' => 'inventario',
                'title' => 'Transferencias · Inventario',
                'pageTitle' => 'Transferencias entre Almacenes',
            ]);
    }
}
