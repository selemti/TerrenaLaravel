<?php

namespace App\Livewire\Transfers;

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
        // TODO: conectar con GET /api/transferencias
        $transfers = $this->mockTransfers();

        return view('livewire.transfers.index', [
            'transfers' => $transfers,
        ])
        ->layout('layouts.terrena', [
            'active' => 'inventario',
            'title' => 'Transferencias · Inventario',
            'pageTitle' => 'Transferencias entre Almacenes',
        ]);
    }

    /**
     * Mock temporal
     */
    protected function mockTransfers(): array
    {
        return [
            [
                'id' => 1001,
                'numero' => 'TRANS-001001',
                'almacen_origen' => 'Principal',
                'almacen_destino' => 'Sucursal Norte',
                'fecha_solicitada' => now()->addDay()->format('Y-m-d'),
                'estado' => 'BORRADOR',
                'lineas_count' => 5,
                'creado_por' => 'Juan Pérez',
                'created_at' => now()->format('Y-m-d H:i'),
            ],
            [
                'id' => 1000,
                'numero' => 'TRANS-001000',
                'almacen_origen' => 'Principal',
                'almacen_destino' => 'Sucursal Sur',
                'fecha_solicitada' => now()->format('Y-m-d'),
                'estado' => 'DESPACHADA',
                'lineas_count' => 3,
                'creado_por' => 'María García',
                'created_at' => now()->subDay()->format('Y-m-d H:i'),
            ],
        ];
    }
}
