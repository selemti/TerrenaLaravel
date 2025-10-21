<?php

namespace App\Livewire\Inventory;

use Livewire\Component;
use Livewire\WithPagination;
use Illuminate\Support\Facades\DB;
use Illuminate\Pagination\LengthAwarePaginator;

class ItemsIndex extends Component
{
    use WithPagination;

    // ===== Filtros (persisten en query string) =====
    public string $q = '';
    public ?string $sucursal = null;     // 'PRINCIPAL' por defecto en mount()
    public ?string $categoria = null;    // opcional (si tu vista la expone)
    public ?string $estadoCad = null;    // ej. "<15d"
    public int $perPage = 15;

    protected $queryString = [
        'q'         => ['except' => ''],
        'sucursal'  => ['except' => null],
        'categoria' => ['except' => null],
        'estadoCad' => ['except' => null],
        'page'      => ['except' => 1],
    ];

    // ===== KPIs =====
    public int $itemsDistintos = 0;
    public float $valorInventario = 0.0;
    public int $bajoStock = 0;
    public int $porVencer = 0;

    // ===== Modal Kardex =====
    public bool $showKardex = false;
    public ?string $kardexItemId = null;
    public string $kardexItemNombre = '';
    public array $kardexRows = [];

    // ===== Modal Movimiento rápido =====
    public bool $showMove = false;
    public string $moveTipo = 'ENTRADA'; // ENTRADA|SALIDA|TRANSFERENCIA|MERMA
    public ?string $moveItemId = null;
    public string $moveItemNombre = '';
    public float $moveCantidad = 0;
    public string $moveUdm = 'ML';
    public ?string $moveLote = null;
    public ?string $moveCaducidad = null; // YYYY-MM-DD
    public ?string $sucOrigen = null;
    public ?string $sucDestino = null;
    public ?float $moveCosto = null;
    public ?string $moveNotas = null;

    // ===== Livewire v3: reset paginación al cambiar filtros =====
    public function updatingQ()         { $this->resetPage(); $this->calcKpis(); }
    public function updatingSucursal()  { $this->resetPage(); $this->calcKpis(); }
    public function updatingCategoria() { $this->resetPage(); $this->calcKpis(); }
    public function updatingEstadoCad() { $this->resetPage(); $this->calcKpis(); }
    public function updatingPerPage()   { $this->resetPage(); }

    // ===== Helpers =====
    protected function schema(): string
    {
        // Respeta tu .env(DB_SCHEMA=selemti)
        return env('DB_SCHEMA', 'public');
    }

    public function mount(): void
    {
        // Valores por defecto amigables
        $this->sucursal  = $this->sucursal ?? 'PRINCIPAL';
        $this->categoria = $this->categoria ?? null;
        $this->calcKpis();
    }

    protected function baseQuery()
    {
        // Vista resumida por item/sucursal (asegúrate que exista):
        // selemti.v_stock_resumen con columnas:
        // item_id, sku, producto, udm_base, existencia, minimo, maximo,
        // costo_base, sucursal, caducidades_15d, categoria (si aplica)
        $view = $this->schema().'.v_stock_resumen';

        $q = DB::table(DB::raw($view))
            ->select([
                'item_id', 'sku', 'producto', 'udm_base',
                'existencia', 'minimo', 'maximo',
                'costo_base', 'sucursal', 'caducidades_15d',
                DB::raw("NULLIF(categoria, '') as categoria"),
            ]);

        if ($this->q !== '') {
            $like = '%'.$this->q.'%';
            $q->where(function ($w) use ($like) {
                $w->where('sku', 'ilike', $like)
                  ->orWhere('producto', 'ilike', $like);
            });
        }

        if ($this->sucursal && $this->sucursal !== 'Todas') {
            $q->where('sucursal', $this->sucursal);
        }

        if ($this->categoria && $this->categoria !== 'Todas') {
            // Si tu vista NO tiene 'categoria', comenta esta línea
            $q->where('categoria', $this->categoria);
        }

        if ($this->estadoCad === '<15d') {
            $q->where('caducidades_15d', '>', 0);
        }

        return $q;
    }

    protected function calcKpis(): void
    {
        try {
            $agg = $this->baseQuery();
            $rows = DB::query()
                ->fromSub($agg, 't')
                ->selectRaw('
                    count(*)::int                                             as items_distintos,
                    coalesce(sum((existencia)::numeric * costo_base),0)::float as valor_inventario,
                    sum(case when existencia < minimo then 1 else 0 end)::int  as bajo_stock,
                    sum(coalesce(caducidades_15d,0))::int                      as por_vencer
                ')
                ->first();

            $this->itemsDistintos  = (int) ($rows->items_distintos ?? 0);
            $this->valorInventario = (float) ($rows->valor_inventario ?? 0);
            $this->bajoStock       = (int) ($rows->bajo_stock ?? 0);
            $this->porVencer       = (int) ($rows->por_vencer ?? 0);
        } catch (\Throwable $e) {
            // Si la vista aún no existe, evita 500
            $this->itemsDistintos = $this->bajoStock = $this->porVencer = 0;
            $this->valorInventario = 0.0;
        }
    }

    // ===== Modales =====
    public function openKardex(string $itemId, string $nombre): void
    {
        $this->kardexItemId     = $itemId;
        $this->kardexItemNombre = $nombre;
        $this->showKardex       = true;

        try {
            // Vista de detalle (asegúrate que exista):
            // selemti.v_kardex_item con columnas:
            // ts, tipo, ref, entrada, salida, saldo, costo, notas, item_id
            $view = $this->schema().'.v_kardex_item';

            $this->kardexRows = DB::table(DB::raw($view))
                ->where('item_id', $itemId)
                ->orderByDesc('ts')
                ->limit(200)
                ->get()
                ->map(fn ($r) => (array) $r)
                ->toArray();
        } catch (\Throwable $e) {
            $this->kardexRows = [];
        }
    }

    public function openMove(string $itemId, string $nombre, string $udm): void
    {
        $this->moveItemId     = $itemId;
        $this->moveItemNombre = $nombre;
        $this->moveUdm        = $udm;
        $this->moveCantidad   = 0;
        $this->moveTipo       = 'ENTRADA';
        $this->sucOrigen      = $this->sucursal ?: 'PRINCIPAL';
        $this->sucDestino     = $this->sucursal ?: 'PRINCIPAL';
        $this->showMove       = true;
    }

    public function saveMove(): void
    {
        $this->validate([
            'moveTipo'     => 'required|in:ENTRADA,SALIDA,TRANSFERENCIA,MERMA',
            'moveItemId'   => 'required',
            'moveCantidad' => 'required|numeric|not_in:0',
            'sucOrigen'    => 'required',
            'sucDestino'   => 'required_if:moveTipo,TRANSFERENCIA',
        ]);

        $schema = $this->schema();
        $sign   = in_array($this->moveTipo, ['SALIDA','MERMA']) ? -1 : 1;
        $qty    = $sign * (float) $this->moveCantidad;

        try {
            DB::table(DB::raw("{$schema}.mov_inv"))->insert([
                'ts'            => now(config('app.timezone')),
                'item_id'       => $this->moveItemId,
                'sucursal_id'   => $this->sucOrigen,
                'sucursal_dest' => $this->moveTipo === 'TRANSFERENCIA' ? $this->sucDestino : null,
                'lote_codigo'   => $this->moveLote,
                'caducidad'     => $this->moveCaducidad,
                'qty'           => $qty,
                'udm'           => $this->moveUdm,
                'costo_unit'    => $this->moveCosto,
                'tipo'          => $this->moveTipo,
                'ref_tipo'      => 'UI',
                'ref_id'        => null,
                'notas'         => $this->moveNotas,
                'created_by'    => auth()->id() ?: 0,
            ]);
        } catch (\Throwable $e) {
            // Podríamos mostrar un toast con el error si quieres
        }

        $this->showMove = false;
        $this->calcKpis();
        $this->dispatch('toast', body: 'Movimiento guardado');
    }

    public function render()
    {
        try {
            $rows = $this->baseQuery()
                ->orderBy('producto')
                ->paginate($this->perPage);
        } catch (\Throwable $e) {
            // Si la vista no existe aún, evita lanzar un error de paginate()
            $currentPage = max(1, (int) request()->query($this->getPageName(), 1));
            $rows = new LengthAwarePaginator(
                items: [],
                total: 0,
                perPage: $this->perPage,
                currentPage: $currentPage,
                options: [
                    'path'  => request()->url(),
                    'query' => request()->query(),
                ],
            );
        }

        return view('livewire.inventory.items-index', compact('rows'))
            ->layout('layouts.terrena', ['active' => 'inventory']);
    }
}
