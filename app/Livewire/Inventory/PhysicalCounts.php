<?php

namespace App\Livewire\Inventory;

use Livewire\Component;
use Livewire\WithPagination;
use Illuminate\Support\Facades\DB;

class PhysicalCounts extends Component
{
    use WithPagination;

    public $search = '';
    public $branch = '';
    public $status = '';
    public $dateFrom = '';
    public $dateTo = '';
    public $perPage = 10;

    protected $queryString = [
        'search', 'branch', 'status', 'dateFrom', 'dateTo', 'perPage'
    ];

    public function render()
    {
        $query = DB::connection('pgsql')
            ->table('selemti.inventory_counts as h')
            ->select([
                'h.id',
                'h.sucursal_id',
                'h.estado',
                'h.programado_para',
                'h.iniciado_en',
                'h.cerrado_en',
                DB::raw('(SELECT COUNT(*) FROM selemti.inventory_count_lines l WHERE l.inventory_count_id = h.id) AS renglones'),
                DB::raw('(SELECT COUNT(*) FROM selemti.inventory_count_lines l WHERE l.inventory_count_id = h.id AND l.qty_contada > 0) AS contados'),
            ]);

        // Aplicar filtros
        if ($this->search) {
            $query->where(function($q) {
                $q->where('h.id', 'ilike', '%' . $this->search . '%')
                  ->orWhere('h.sucursal_id', 'ilike', '%' . $this->search . '%');
            });
        }

        if ($this->branch) {
            $query->where('h.sucursal_id', $this->branch);
        }

        if ($this->status) {
            $query->where('h.estado', $this->status);
        }

        if ($this->dateFrom) {
            $query->whereDate('h.programado_para', '>=', $this->dateFrom);
        }

        if ($this->dateTo) {
            $query->whereDate('h.programado_para', '<=', $this->dateTo);
        }

        $counts = $query->orderBy('h.programado_para', 'desc')
                        ->orderBy('h.id', 'desc')
                        ->paginate($this->perPage);

        // Obtener valores únicos para filtros
        $branches = DB::connection('pgsql')
            ->table('selemti.inventory_counts')
            ->distinct('sucursal_id')
            ->pluck('sucursal_id');

        $statuses = DB::connection('pgsql')
            ->table('selemti.inventory_counts')
            ->distinct('estado')
            ->pluck('estado');

        return view('livewire.inventory.physical-counts', [
            'counts' => $counts,
            'branches' => $branches,
            'statuses' => $statuses,
        ]);
    }

    public function closeCount($id)
    {
        // Verificar si hay conteos pendientes o diferencias significativas
        $pendingLines = DB::connection('pgsql')
            ->table('selemti.inventory_count_lines')
            ->where('inventory_count_id', $id)
            ->where('qty_contada', 0)
            ->count();

        if ($pendingLines > 0) {
            $this->dispatch('notify', message: "Advertencia: Aún hay {$pendingLines} items sin contar.", type: 'warning');
        }

        // Ejecutar bloque 8 de verification_queries_psql_v6.sql para validar el cierre
        $date = now()->format('Y-m-d');
        $validationResults = DB::connection('pgsql')
            ->select("
                SELECT
                  h.id,
                  h.sucursal_id,
                  h.programado_para::date AS programado_para,
                  h.iniciado_en::date     AS iniciado_en,
                  h.estado,
                  (SELECT count(*) FROM selemti.inventory_count_lines l WHERE l.inventory_count_id = h.id) AS renglones
                FROM selemti.inventory_counts h
                WHERE h.sucursal_id::text = '1'
                  AND (h.programado_para::date = ? OR h.iniciado_en::date = ?)
                  AND COALESCE(h.estado,'') NOT IN ('CERRADO','CLOSED')
                  AND h.id = ?
                ORDER BY h.id
            ", [$date, $date, $id]);

        if (!empty($validationResults)) {
            // Actualizar estado a cerrado
            DB::connection('pgsql')
                ->table('selemti.inventory_counts')
                ->where('id', $id)
                ->update([
                    'estado' => 'CERRADO',
                    'cerrado_en' => now(),
                    'updated_at' => now(),
                ]);
            
            $this->dispatch('notify', message: 'Conteo físico cerrado correctamente');
        } else {
            $this->dispatch('notify', message: 'No se pudo cerrar el conteo. Puede que ya esté cerrado.', type: 'error');
        }
    }
    
    public function validatePhysicalCounts($date = null, $branch = '1')
    {
        $date = $date ?: now()->format('Y-m-d');
        
        // Bloque 8 de verification_queries_psql_v6.sql: Conteos físicos abiertos en el día (por sucursal)
        $openCounts = DB::connection('pgsql')
            ->select("
                SELECT
                  h.id,
                  h.sucursal_id,
                  h.programado_para::date AS programado_para,
                  h.iniciado_en::date     AS iniciado_en,
                  h.estado,
                  (SELECT count(*) FROM selemti.inventory_count_lines l WHERE l.inventory_count_id = h.id) AS renglones
                FROM selemti.inventory_counts h
                WHERE h.sucursal_id::text = ?
                  AND (h.programado_para::date = ? OR h.iniciado_en::date = ?)
                  AND COALESCE(h.estado,'') NOT IN ('CERRADO','CLOSED')
                ORDER BY h.id
            ", [$branch, $date, $date]);

        return $openCounts;
    }

    public function openDetail($id)
    {
        return redirect()->route('inv.counts.detail', ['id' => $id]);
    }
}