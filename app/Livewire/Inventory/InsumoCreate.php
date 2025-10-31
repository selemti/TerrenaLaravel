<?php

namespace App\Livewire\Inventory;

use App\Services\Inventory\InsumoCodeService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Livewire\Component;
use Illuminate\Validation\Rule;

class InsumoCreate extends Component
{
    public string $categoria = '';
    public string $subcategoria = '';
    public string $nombre = '';
    public ?string $sku = null;
    public int|string $um_id = '';
    public bool $perecible = false;
    public float $merma_pct = 0.0;
    public array $units = [];

    public bool $authorized = false;

    protected array $categorias = [
        'MP'  => 'Materia Prima',
        'PT'  => 'Producto Terminado',
        'EM'  => 'Empaque / Packaging',
        'LIM' => 'Limpieza / Químicos',
        'SRV' => 'Servicio',
    ];

    protected array $subcategorias = [
        'MP' => [
            'LAC'  => 'Lácteos',
            'CAR'  => 'Cárnicos',
            'FRU'  => 'Frutas y verduras',
            'SECO' => 'Secos / abarrotes',
        ],
        'PT' => [
            'BOT' => 'Bebida embotellada',
            'SNK' => 'Botana empaquetada',
        ],
        'EM' => [
            'VAS' => 'Vasos',
            'TAP' => 'Tapas',
            'BOL' => 'Bolsas / empaques',
        ],
        'LIM' => [
            'DET' => 'Detergentes',
            'DES' => 'Desinfectantes',
        ],
        'SRV' => [
            'EXT' => 'Servicio externo',
        ],
    ];

    protected array $allowedUnitKeys = ['KG', 'L', 'PZA'];

    public function mount(): void
    {
        $user = Auth::user();
        $this->authorized = $user
            && ($user->can('inventory.items.manage') || $user->hasRole('Super Admin'));

        if (! $this->authorized) {
            session()->flash('warning', 'No tienes permiso para dar de alta insumos.');
            return;
        }

        $this->loadUnits();
    }

    public function updatedCategoria(): void
    {
        $this->subcategoria = '';
    }

    public function save(): void
    {
        if (! $this->authorized) {
            $this->dispatch('form-error', 'Sin permiso');
            return;
        }

        $validated = Validator::make(
            [
                'categoria'    => $this->categoria,
                'subcategoria' => $this->subcategoria,
                'nombre'       => $this->nombre,
                'um_id'        => $this->um_id,
                'sku'          => $this->sku,
                'perecible'    => $this->perecible,
                'merma_pct'    => $this->merma_pct,
            ],
            [
                'categoria'    => ['required', 'string', 'max:4'],
                'subcategoria' => ['required', 'string', 'max:6'],
                'nombre'       => ['required', 'string', 'max:255'],
                'um_id'        => ['required', 'integer', Rule::in($this->unitIds())],
                'sku'          => ['nullable', 'string', 'max:120'],
                'perecible'    => ['boolean'],
                'merma_pct'    => ['required', 'numeric', 'between:0,100', 'decimal:0,3'],
            ],
            [],
            [
                'categoria'    => 'categoría',
                'subcategoria' => 'subcategoría',
                'um_id'        => 'unidad de medida',
                'merma_pct'    => 'merma %',
            ]
        )->validate();

        try {
            $codes = app(InsumoCodeService::class)->generateCode($this->categoria, $this->subcategoria);

            // Mapear categoría a category_id en item_categories
            $categoryMap = [
                'MP'  => 1, // Materia Prima
                'PT'  => 2, // Producto Terminado
                'EM'  => 3, // Empaque / Packaging
                'LIM' => 4, // Limpieza / Químicos
                'SRV' => 5, // Servicio
            ];
            $categoryId = $categoryMap[$this->categoria] ?? null;

            // Obtener el código de unidad
            $unit = DB::connection('pgsql')
                ->table('selemti.unidades_medida_legacy')
                ->where('id', (int) $this->um_id)
                ->first(['codigo']);

            $payload = [
                'id'                  => $codes['codigo'], // MP-LAC-00001
                'nombre'              => $this->nombre,
                'descripcion'         => null,
                'categoria_id'        => 'CAT-' . str_pad($categoryId, 4, '0', STR_PAD_LEFT), // CAT-0001
                'category_id'         => $categoryId,
                'unidad_medida'       => $unit ? $unit->codigo : 'KG',
                'unidad_medida_id'    => (int) $this->um_id,
                'perishable'          => (bool) $this->perecible,
                'activo'              => true,
                'created_at'          => now(),
                'updated_at'          => now(),
            ];

            // Insertar en la tabla selemti.items usando conexión PostgreSQL
            DB::connection('pgsql')->table('selemti.items')->insert($payload);

            session()->flash('success', 'Insumo creado correctamente.');

            $this->reset([
                'categoria',
                'subcategoria',
                'nombre',
                'sku',
                'um_id',
                'perecible',
                'merma_pct',
            ]);
            $this->merma_pct = 0.0;
        } catch (\Throwable $e) {
            report($e);
            $this->addError('form', 'No se pudo guardar el insumo. Intenta nuevamente.');
        }
    }

    public function render()
    {
        return view('livewire.inventory.insumo-create', [
            'categorias'    => $this->categorias,
            'subcategorias' => $this->categoria ? ($this->subcategorias[$this->categoria] ?? []) : [],
            'units'         => $this->units,
        ])->layout('layouts.terrena', [
            'active'    => 'inventario',
            'title'     => 'Catálogo · Alta de insumo',
            'pageTitle' => 'Alta de insumo',
        ]);
    }

    protected function unitIds(): array
    {
        return array_map(
            static fn ($unit) => (int) $unit['id'],
            $this->units
        );
    }

    protected function loadUnits(): void
    {
        $allowedCodes = ['KG', 'LT', 'PZ']; // Códigos reales en la tabla
        $this->units = DB::connection('pgsql')
            ->table('selemti.unidades_medida_legacy')
            ->whereIn('codigo', $allowedCodes)
            ->orderBy('codigo')
            ->get(['id', 'codigo as clave', 'nombre'])
            ->map(fn ($row) => [
                'id'    => (int) $row->id,
                'clave' => $row->clave,
                'nombre' => $row->nombre,
            ])->toArray();
    }
}
