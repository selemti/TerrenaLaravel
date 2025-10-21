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
        $hasSucursal = Schema::hasColumn('recepcion_cab', 'sucursal_id');
        $hasAlmacen  = Schema::hasColumn('recepcion_cab', 'almacen_id');

        $query = DB::table('recepcion_cab as r')
            ->leftJoin('cat_proveedores as p', 'p.id', '=', 'r.proveedor_id')
            ->select([
                'r.id',
                'r.ts',
                'r.proveedor_id',
                DB::raw("COALESCE(p.nombre, '') as proveedor_nombre"),
            ]);

        if ($hasSucursal) {
            $query->addSelect('r.sucursal_id');
            $query->leftJoin(DB::raw('selemti.cat_sucursales as s'), function ($join) {
                $join->on(DB::raw('s.id::text'), '=', 'r.sucursal_id');
            });
            $query->addSelect([
                's.nombre as sucursal_nombre',
                's.clave as sucursal_clave',
            ]);
        }

        if ($hasAlmacen) {
            $query->addSelect('r.almacen_id');
            $query->leftJoin(DB::raw('selemti.cat_almacenes as a'), function ($join) {
                $join->on(DB::raw('a.id::text'), '=', 'r.almacen_id');
            });
            $query->addSelect([
                'a.nombre as almacen_nombre',
                'a.clave as almacen_clave',
            ]);
        }

        return $query
            ->orderByDesc('r.ts')
            ->limit(50)
            ->get()
            ->map(function ($row) use ($hasSucursal, $hasAlmacen) {
                if ($hasSucursal) {
                    $row->sucursal_nombre = $row->sucursal_nombre
                        ? trim(($row->sucursal_clave ? "{$row->sucursal_clave} · " : '') . $row->sucursal_nombre)
                        : null;
                } else {
                    $row->sucursal_nombre = null;
                }

                if ($hasAlmacen) {
                    $row->almacen_nombre = $row->almacen_nombre
                        ? trim(($row->almacen_clave ? "{$row->almacen_clave} · " : '') . $row->almacen_nombre)
                        : null;
                } else {
                    $row->almacen_nombre = null;
                }

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
