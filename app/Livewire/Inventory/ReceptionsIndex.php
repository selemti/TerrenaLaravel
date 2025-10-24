<?php
namespace App\Livewire\Inventory;

use Livewire\Component;
use Livewire\Attributes\On;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ReceptionsIndex extends Component
{
    public bool $showCreateModal = false;
    public ?string $flashMessage = null;

    public function openCreateModal(): void
    {
        $this->flashMessage = null;
        $this->showCreateModal = true;
        $this->dispatch('reception-modal-toggled', open: true);
    }

    public function closeCreateModal(): void
    {
        $this->showCreateModal = false;
        $this->dispatch('reception-modal-toggled', open: false);
    }

    #[On('reception-saved')]
    public function handleReceptionSaved(int $receptionId, string $message = ''): void
    {
        $this->showCreateModal = false;
        $this->flashMessage = $message ?: "Recepción #{$receptionId} guardada.";
        $this->dispatch('reception-modal-toggled', open: false);
    }

    protected function fetchRows()
    {
        $query = DB::table('selemti.recepcion_cab as r')
            ->leftJoin('selemti.cat_proveedores as p', 'p.id', '=', 'r.proveedor_id')
            ->select([
                'r.id',
                'r.numero_recepcion',
                'r.proveedor_id',
                'r.sucursal_id',
                'r.almacen_id',
                'r.fecha_recepcion',
                'r.estado',
                'r.total_presentaciones',
                'r.total_canonico',
                DB::raw("COALESCE(p.nombre, '') as proveedor_nombre"),
            ]);

        if (Schema::hasTable('selemti.cat_sucursales')) {
            $query->leftJoin('selemti.cat_sucursales as s', function ($join) {
                $join->on(DB::raw('s.id::text'), '=', DB::raw('r.sucursal_id::text'));
            });
            $query->addSelect([
                's.nombre as sucursal_nombre',
                's.clave as sucursal_clave',
            ]);
        }

        if (Schema::hasTable('selemti.cat_almacenes')) {
            $query->leftJoin('selemti.cat_almacenes as a', function ($join) {
                $join->on(DB::raw('a.id::text'), '=', DB::raw('r.almacen_id::text'));
            });
            $query->addSelect([
                'a.nombre as almacen_nombre',
                'a.clave as almacen_clave',
            ]);
        }

        return $query
            ->orderByDesc('r.fecha_recepcion')
            ->limit(50)
            ->get()
            ->map(function ($row) {
                $row->sucursal_nombre = isset($row->sucursal_nombre)
                    ? trim(($row->sucursal_clave ? "{$row->sucursal_clave} · " : '') . ($row->sucursal_nombre ?? ''))
                    : null;

                $row->almacen_nombre = isset($row->almacen_nombre)
                    ? trim(($row->almacen_clave ? "{$row->almacen_clave} · " : '') . ($row->almacen_nombre ?? ''))
                    : null;

                return $row;
            });
    }

    public function render()
    {
        $rows = $this->fetchRows();

        return view('inventory.receptions-index', [
            'rows' => $rows,
            'showCreateModal' => $this->showCreateModal,
            'flashMessage' => $this->flashMessage,
        ])->layout('layouts.terrena', [
            'active'    => 'inventario',
            'title'     => 'Recepciones · Inventario',
            'pageTitle' => 'Recepciones',
        ]);
    }
}
