<?php

namespace App\Livewire\Pos;

use Livewire\Component;
use Livewire\WithPagination;
use Illuminate\Support\Facades\DB;

class PosMap extends Component
{
    use WithPagination;

    public $search = '';
    public $system = '';
    public $tipo = '';
    public $status = 'all';
    public $perPage = 10;

    public $showForm = false;
    public $isEditing = false;
    public $editingId = null;

    public $form = [
        'pos_system' => 'FLOREANT',
        'plu' => '',
        'tipo' => 'MENU',
        'receta_id' => '',
        'receta_version_id' => null,
        'valid_from' => '',
        'valid_to' => null,
        'vigente_desde' => null,
        'meta' => null,
    ];

    public $tipoOptions = ['MENU', 'MODIFICADOR', 'COMBO'];

    protected $queryString = [
        'search', 'system', 'tipo', 'status', 'perPage'
    ];

    public function mount()
    {
        $this->form['valid_from'] = now()->format('Y-m-d');
    }

    public function render()
    {
        $query = DB::connection('pgsql')
            ->table('selemti.pos_map')
            ->select('*');

        // Aplicar filtros
        if ($this->search) {
            $query->where(function($q) {
                $q->where('plu', 'ilike', '%' . $this->search . '%')
                  ->orWhere('receta_id', 'ilike', '%' . $this->search . '%');
            });
        }

        if ($this->system) {
            $query->where('pos_system', $this->system);
        }

        if ($this->tipo) {
            $query->where('tipo', $this->tipo);
        }

        if ($this->status !== 'all') {
            if ($this->status === 'activo') {
                $query->where(function($q) {
                    $q->whereNull('valid_to')
                      ->orWhere('valid_to', '>=', now()->format('Y-m-d'));
                })
                ->where(function($q) {
                    $q->whereNull('vigente_desde')
                      ->orWhere('vigente_desde', '<=', now()->format('Y-m-d'));
                });
            } elseif ($this->status === 'inactivo') {
                $query->where(function($q) {
                    $q->whereNotNull('valid_to')
                      ->where('valid_to', '<', now()->format('Y-m-d'));
                });
            }
        }

        $mappings = $query->orderBy('valid_from', 'desc')
                         ->orderBy('plu')
                         ->paginate($this->perPage);

        // Obtener valores únicos para filtros
        $systems = DB::connection('pgsql')
            ->table('selemti.pos_map')
            ->distinct('pos_system')
            ->pluck('pos_system');

        $tipos = DB::connection('pgsql')
            ->table('selemti.pos_map')
            ->distinct('tipo')
            ->pluck('tipo');

        return view('livewire.pos.pos-map', [
            'mappings' => $mappings,
            'systems' => $systems,
            'tipos' => $tipos,
        ]);
    }

    public function openCreate()
    {
        $this->resetForm();
        $this->showForm = true;
        $this->isEditing = false;
        $this->editingId = null;
    }

    public function openEdit($id)
    {
        $mapping = DB::connection('pgsql')
            ->table('selemti.pos_map')
            ->where('pos_system', $id[0])
            ->where('plu', $id[1])
            ->where('valid_from', $id[2])
            ->where('sys_from', $id[3])
            ->first();

        if ($mapping) {
            $this->form = [
                'pos_system' => $mapping->pos_system,
                'plu' => $mapping->plu,
                'tipo' => $mapping->tipo,
                'receta_id' => $mapping->receta_id,
                'receta_version_id' => $mapping->receta_version_id,
                'valid_from' => $mapping->valid_from,
                'valid_to' => $mapping->valid_to,
                'vigente_desde' => $mapping->vigente_desde,
                'meta' => $mapping->meta,
            ];

            $this->showForm = true;
            $this->isEditing = true;
            $this->editingId = [$mapping->pos_system, $mapping->plu, $mapping->valid_from, $mapping->sys_from];
        }
    }

    public function save()
    {
        $this->validate([
            'form.pos_system' => 'required|string|max:50',
            'form.plu' => 'required|string|max:50',
            'form.tipo' => 'required|in:MENU,MODIFICADOR,COMBO',
            'form.valid_from' => 'required|date',
        ]);

        $data = [
            'pos_system' => $this->form['pos_system'],
            'plu' => $this->form['plu'],
            'tipo' => $this->form['tipo'],
            'receta_id' => $this->form['receta_id'] ?: null,
            'receta_version_id' => $this->form['receta_version_id'] ?: null,
            'valid_from' => $this->form['valid_from'],
            'valid_to' => $this->form['valid_to'] ?: null,
            'vigente_desde' => $this->form['vigente_desde'] ?: null,
            'meta' => $this->form['meta'] ?: null,
            'sys_from' => now(),
        ];

        if ($this->isEditing) {
            // Actualizar registro existente
            DB::connection('pgsql')
                ->table('selemti.pos_map')
                ->where('pos_system', $this->editingId[0])
                ->where('plu', $this->editingId[1])
                ->where('valid_from', $this->editingId[2])
                ->where('sys_to', null) // Asumiendo sistema de versionado
                ->update(array_merge($data, ['sys_to' => now()]));
                
            // Insertar nueva versión
            DB::connection('pgsql')
                ->table('selemti.pos_map')
                ->insert($data);
        } else {
            // Insertar nuevo registro
            DB::connection('pgsql')
                ->table('selemti.pos_map')
                ->insert($data);
        }

        $this->showForm = false;
        $this->dispatch('notify', message: 'Mapeo POS guardado correctamente');
    }

    public function delete($id)
    {
        $this->dispatch('confirm-delete', id: $id);
    }

    public function confirmDelete($id)
    {
        DB::connection('pgsql')
            ->table('selemti.pos_map')
            ->where('pos_system', $id[0])
            ->where('plu', $id[1])
            ->where('valid_from', $id[2])
            ->update(['sys_to' => now()]); // Soft delete lógico

        $this->dispatch('notify', message: 'Mapeo POS eliminado correctamente');
    }

    public function closeForm()
    {
        $this->showForm = false;
    }

    protected function resetForm()
    {
        $this->form = [
            'pos_system' => 'FLOREANT',
            'plu' => '',
            'tipo' => 'MENU',
            'receta_id' => '',
            'receta_version_id' => null,
            'valid_from' => now()->format('Y-m-d'),
            'valid_to' => null,
            'vigente_desde' => null,
            'meta' => null,
        ];
    }

    public function checkUnmappedSales($date = null)
    {
        $date = $date ?: now()->format('Y-m-d');
        
        // Consulta 1 de verification_queries_psql_v6: Ventas del día sin mapeo POS→Receta
        $unmappedSales = DB::connection('pgsql')
            ->select("
                SELECT
                  ti.id               AS ticket_item_id,
                  mi.id               AS menu_item_id,
                  mi.pg_id            AS menu_item_pg_id,
                  mi.name             AS menu_item_name,
                  t.id                AS ticket_id,
                  t.create_date::date AS fecha_venta,
                  t.terminal_id
                FROM public.ticket t
                JOIN public.terminal term
                  ON term.id = t.terminal_id
                 AND term.location::text = '1'
                JOIN public.ticket_item ti
                  ON ti.ticket_id = t.id
                LEFT JOIN public.menu_item mi
                  ON mi.id = ti.item_id
                LEFT JOIN selemti.pos_map pm
                  ON pm.tipo = 'MENU'
                 AND (pm.plu = mi.id::text OR pm.plu = mi.pg_id::text)
                 AND (
                      (pm.valid_from IS NULL OR pm.valid_from <= ?)
                  AND (pm.valid_to   IS NULL OR pm.valid_to   >= ?)
                   OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde::date <= ?)
                 )
                WHERE t.create_date::date = ?
                  AND pm.plu IS NULL
                ORDER BY mi.name
            ", [$date, $date, $date, $date]);

        return $unmappedSales;
    }

    public function checkUnmappedModifiers($date = null)
    {
        $date = $date ?: now()->format('Y-m-d');
        
        // Consulta 1.b de verification_queries_psql_v6: Modificadores del día sin mapeo
        $unmappedModifiers = DB::connection('pgsql')
            ->select("
                SELECT
                  tim.id               AS ticket_item_mod_id,
                  tim.item_id          AS modifier_item_id,
                  t.id                 AS ticket_id,
                  t.create_date::date  AS fecha_venta,
                  t.terminal_id
                FROM public.ticket t
                JOIN public.terminal term
                  ON term.id = t.terminal_id
                 AND term.location::text = '1'
                JOIN public.ticket_item ti
                  ON ti.ticket_id = t.id
                JOIN public.ticket_item_modifier tim
                  ON tim.ticket_item_id = ti.id
                LEFT JOIN selemti.pos_map pm
                  ON pm.tipo = 'MODIFIER'
                 AND pm.plu = tim.item_id::text
                 AND (
                      (pm.valid_from IS NULL OR pm.valid_from <= ?)
                  AND (pm.valid_to   IS NULL OR pm.valid_to   >= ?)
                   OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde::date <= ?)
                 )
                WHERE t.create_date::date = ?
                  AND pm.plu IS NULL
                ORDER BY tim.id
            ", [$date, $date, $date, $date]);

        return $unmappedModifiers;
    }
    
    public function checkPendingConsumptionLines($date = null)
    {
        $date = $date ?: now()->format('Y-m-d');
        
        // Consulta 2 de verification_queries_psql_v6: Líneas inv_consumo_pos/_det pendientes
        $pendingLines = DB::connection('pgsql')
            ->select("
                SELECT
                  d.id,
                  h.ticket_id,
                  h.sucursal_id,
                  h.terminal_id,
                  h.created_at::date AS fecha,
                  d.mp_id,           -- <== columna real
                  d.uom_id,
                  d.factor,
                  d.cantidad,
                  d.requiere_reproceso,
                  d.procesado,
                  h.fecha_proceso
                FROM selemti.inv_consumo_pos      h
                JOIN selemti.inv_consumo_pos_det  d ON d.consumo_id = h.id
                LEFT JOIN selemti.materia_prima mp ON d.mp_id = mp.id
                WHERE h.created_at::date = ?
                  AND h.sucursal_id::text = '1'
                  AND (d.requiere_reproceso = true OR d.procesado = false OR mp.id IS NULL)
                ORDER BY h.ticket_id, d.id
            ", [$date]);

        return $pendingLines;
    }
}