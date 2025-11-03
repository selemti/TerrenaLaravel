<?php

namespace App\Livewire\Inventory;

use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

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
        'q' => ['except' => ''],
        'sucursal' => ['except' => null],
        'categoria' => ['except' => null],
        'estadoCad' => ['except' => null],
        'page' => ['except' => 1],
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
    public function updatingQ()
    {
        $this->resetPage();
        $this->calcKpis();
    }

    public function updatingSucursal()
    {
        $this->resetPage();
        $this->calcKpis();
    }

    public function updatingCategoria()
    {
        $this->resetPage();
        $this->calcKpis();
    }

    public function updatingEstadoCad()
    {
        $this->resetPage();
        $this->calcKpis();
    }

    public function updatingPerPage()
    {
        $this->resetPage();
    }

    // ===== Helpers =====
    protected function schema(): string
    {
        // Respeta tu .env(DB_SCHEMA=selemti)
        return env('DB_SCHEMA', 'public');
    }

    public function mount(): void
    {
        // Valores por defecto amigables
        $this->sucursal = $this->sucursal ?? 'PRINCIPAL';
        $this->categoria = $this->categoria ?? null;
        $this->calcKpis();
    }

    protected function baseQuery()
    {
        $schema = $this->schema();

        $q = DB::table("{$schema}.items as i")
            ->leftJoin("{$schema}.cat_unidades as uom", 'i.unidad_medida_id', '=', 'uom.id')
            ->leftJoin("{$schema}.cat_unidades as uom_compra", 'i.unidad_compra_id', '=', 'uom_compra.id')
            ->leftJoin("{$schema}.item_categories as cat", 'i.category_id', '=', 'cat.id')
            ->select([
                'i.id as item_id',
                'i.item_code as sku',
                'i.nombre as producto',
                'i.descripcion',
                'i.categoria_id',
                'cat.nombre as categoria_nombre',
                'uom.clave as udm_base',
                'uom.nombre as udm_base_nombre',
                'uom_compra.clave as udm_compra',
                'uom_compra.nombre as udm_compra_nombre',
                'i.factor_compra',
                'i.tipo',
                'i.costo_promedio',
                'i.perishable',
                'i.activo',
                DB::raw('NULL as existencia'),  // TODO: JOIN con stock cuando exista
                DB::raw('NULL as minimo'),
                DB::raw('NULL as maximo'),
            ])
            ->where('i.activo', true);

        if ($this->q !== '') {
            $like = '%'.$this->q.'%';
            $q->where(function ($w) use ($like) {
                $w->where('i.item_code', 'ilike', $like)
                    ->orWhere('i.nombre', 'ilike', $like)
                    ->orWhere('i.descripcion', 'ilike', $like);
            });
        }

        if ($this->categoria && $this->categoria !== 'Todas') {
            $q->where('i.categoria_id', $this->categoria);
        }

        return $q;
    }

    protected function calcKpis(): void
    {
        try {
            $schema = $this->schema();

            // Contar items totales
            $this->itemsDistintos = DB::table("{$schema}.items")
                ->where('activo', true)
                ->count();

            // Valor de inventario (basado en costo promedio)
            // TODO: Cuando tengas tabla de stock, multiplica existencia × costo
            $this->valorInventario = DB::table("{$schema}.items")
                ->where('activo', true)
                ->sum('costo_promedio') ?? 0.0;

            // Bajo stock y por vencer necesitan tabla de stock/lotes
            $this->bajoStock = 0;  // TODO: implementar cuando exista stock_policy
            $this->porVencer = 0;  // TODO: implementar cuando exista lotes con caducidad
        } catch (\Throwable $e) {
            $this->itemsDistintos = $this->bajoStock = $this->porVencer = 0;
            $this->valorInventario = 0.0;
        }
    }

    // ===== Modales =====
    public function openKardex(string $itemId, string $nombre): void
    {
        $this->kardexItemId = $itemId;
        $this->kardexItemNombre = $nombre;
        $this->showKardex = true;

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
        $this->moveItemId = $itemId;
        $this->moveItemNombre = $nombre;
        $this->moveUdm = $udm;
        $this->moveCantidad = 0;
        $this->moveTipo = 'ENTRADA';
        $this->sucOrigen = $this->sucursal ?: 'PRINCIPAL';
        $this->sucDestino = $this->sucursal ?: 'PRINCIPAL';
        $this->showMove = true;
    }

    public function saveMove(): void
    {
        $this->validate([
            'moveTipo' => 'required|in:ENTRADA,SALIDA,TRANSFERENCIA,MERMA',
            'moveItemId' => 'required',
            'moveCantidad' => 'required|numeric|not_in:0',
            'sucOrigen' => 'required',
            'sucDestino' => 'required_if:moveTipo,TRANSFERENCIA',
        ]);

        $schema = $this->schema();
        $sign = in_array($this->moveTipo, ['SALIDA', 'MERMA']) ? -1 : 1;
        $qty = $sign * (float) $this->moveCantidad;

        try {
            DB::table(DB::raw("{$schema}.mov_inv"))->insert([
                'ts' => now(config('app.timezone')),
                'item_id' => $this->moveItemId,
                'sucursal_id' => $this->sucOrigen,
                'sucursal_dest' => $this->moveTipo === 'TRANSFERENCIA' ? $this->sucDestino : null,
                'lote_codigo' => $this->moveLote,
                'caducidad' => $this->moveCaducidad,
                'qty' => $qty,
                'udm' => $this->moveUdm,
                'costo_unit' => $this->moveCosto,
                'tipo' => $this->moveTipo,
                'ref_tipo' => 'UI',
                'ref_id' => null,
                'notas' => $this->moveNotas,
                'created_by' => auth()->id() ?: 0,
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
            $pageName = $this->pageName ?? 'page';
            $currentPage = max(1, (int) request()->query($pageName, 1));
            $rows = new LengthAwarePaginator(
                items: [],
                total: 0,
                perPage: $this->perPage,
                currentPage: $currentPage,
                options: [
                    'path' => request()->url(),
                    'query' => request()->query(),
                ],
            );
        }

        return view('livewire.inventory.items-index', compact('rows'))
            ->layout('layouts.terrena', ['active' => 'inventory']);
    }
}
