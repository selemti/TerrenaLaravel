<?php

namespace App\Livewire\CashFund;

use App\Models\CashFund;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

/**
 * Listado de fondos de caja chica
 * Consulta datos reales de la tabla cash_funds
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
        $query = CashFund::with(['responsable', 'createdBy'])
            ->orderBy('fecha', 'desc')
            ->orderBy('id', 'desc');

        // Filtrar por estado
        if ($this->estadoFilter !== 'all') {
            $query->where('estado', strtoupper($this->estadoFilter));
        }

        // Filtrar por búsqueda
        if (trim($this->search) !== '') {
            $search = trim($this->search);
            $query->where(function($q) use ($search) {
                $q->where('id', 'like', "%{$search}%")
                  ->orWhereHas('responsable', function($q2) use ($search) {
                      $q2->where('nombre_completo', 'like', "%{$search}%");
                  })
                  ->orWhereHas('createdBy', function($q2) use ($search) {
                      $q2->where('nombre_completo', 'like', "%{$search}%");
                  });
            });
        }

        $fondos = $query->paginate(20);

        // Obtener nombres de sucursales desde PostgreSQL
        $fondosWithSucursal = $fondos->map(function($fondo) {
            $sucursal = $this->getSucursalNombre($fondo->sucursal_id);

            return [
                'id' => $fondo->id,
                'sucursal_nombre' => $sucursal,
                'fecha' => $fondo->fecha->format('Y-m-d'),
                'monto_inicial' => $fondo->monto_inicial,
                'moneda' => $fondo->moneda,
                'estado' => $fondo->estado,
                'total_egresos' => $fondo->total_egresos,
                'saldo_disponible' => $fondo->saldo_disponible,
                'responsable' => $fondo->responsable->nombre_completo ?? 'Sin asignar',
                'creado_por' => $fondo->createdBy->nombre_completo ?? 'Sistema',
                'created_at' => $fondo->created_at->format('Y-m-d H:i'),
            ];
        });

        return view('livewire.cash-fund.index', [
            'fondos' => $fondosWithSucursal,
        ])
        ->layout('layouts.terrena', [
            'active' => 'cajachica',
            'title' => 'Caja Chica',
            'pageTitle' => 'Fondos de Caja Chica',
        ]);
    }

    protected function getSucursalNombre(int $sucursalId): string
    {
        try {
            $sucursal = DB::connection('pgsql')
                ->table('selemti.cat_sucursales')
                ->where('id', $sucursalId)
                ->first(['nombre', 'clave']);

            if ($sucursal) {
                return trim(($sucursal->clave ? "{$sucursal->clave} - " : '') . $sucursal->nombre);
            }

            return "Sucursal #{$sucursalId}";
        } catch (\Exception $e) {
            return "Sucursal #{$sucursalId}";
        }
    }
}
