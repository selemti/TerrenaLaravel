<?php

namespace App\Livewire\Inventory;

use App\Models\Catalogs\Unidad;
use App\Services\Inventory\InsumoCodeService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Livewire\Component;

class ItemCreate extends Component
{
    // Identificación
    public string $nombre = '';
    public string $descripcion = '';
    public ?string $item_code = null; // SKU personalizado (opcional)

    // Categorización
    public string $tipo = 'MATERIA_PRIMA'; // MATERIA_PRIMA | ELABORADO | ENVASADO
    public ?int $category_id = null;

    // Unidades de Medida (Sistema Completo)
    public ?int $unidad_medida_id = null;  // Unidad BASE (KG, L, PZ)
    public ?int $unidad_compra_id = null;  // Unidad de COMPRA (CAJA, PAQUETE, etc)
    public ?float $factor_compra = 1.0;    // Factor: 1 unidad_compra = X unidades_base
    public ?int $unidad_salida_id = null;  // Unidad de SALIDA/RECETA (ML, TAZA, etc)

    // Presentación (descripción legible)
    public string $presentacion_texto = ''; // Ej: "12 pzas de 1.5 L"
    public ?int $cant_piezas = null;        // Para calcular automáticamente
    public ?float $contenido_pieza = null;  // Para calcular automáticamente

    // Propiedades físicas
    public bool $perishable = false;
    public ?int $temperatura_min = null;
    public ?int $temperatura_max = null;

    // Costo
    public float $costo_promedio = 0.0;

    // Estado
    public bool $activo = true;

    // Control de acceso
    public bool $authorized = false;

    // Datos precargados
    public array $unidadesBase = [];      // KG, L, PZ
    public array $unidadesCompra = [];    // CAJA, PAQUETE, COSTAL, etc
    public array $unidadesSalida = [];    // ML, TAZA, GRAMO, etc
    public array $categorias = [];
    public array $tipos = [
        'MATERIA_PRIMA' => 'Materia Prima',
        'ELABORADO' => 'Elaborado',
        'ENVASADO' => 'Envasado',
    ];

    protected $rules = [
        'nombre' => ['required', 'string', 'min:3', 'max:100'],
        'descripcion' => ['nullable', 'string', 'max:500'],
        'item_code' => ['nullable', 'string', 'max:32', 'unique:selemti.items,item_code'],
        'tipo' => ['required', 'in:MATERIA_PRIMA,ELABORADO,ENVASADO'],
        'category_id' => ['nullable', 'integer'],
        'unidad_medida_id' => ['required', 'integer', 'exists:selemti.cat_unidades,id'],
        'unidad_compra_id' => ['nullable', 'integer', 'exists:selemti.cat_unidades,id'],
        'factor_compra' => ['nullable', 'numeric', 'min:0.000001', 'max:999999'],
        'unidad_salida_id' => ['nullable', 'integer', 'exists:selemti.cat_unidades,id'],
        'perishable' => ['boolean'],
        'temperatura_min' => ['nullable', 'integer', 'min:-50', 'max:100'],
        'temperatura_max' => ['nullable', 'integer', 'min:-50', 'max:100'],
        'costo_promedio' => ['nullable', 'numeric', 'min:0', 'max:999999'],
        'activo' => ['boolean'],
    ];

    public function mount(): void
    {
        $user = Auth::user();
        $this->authorized = $user
            && ($user->can('inventory.items.manage') || $user->hasRole('Super Admin'));

        if (! $this->authorized) {
            session()->flash('warning', 'No tienes permiso para dar de alta items.');

            return;
        }

        $this->loadCatalogData();
    }

    public function updatedCantPiezas(): void
    {
        $this->calcularFactorCompra();
    }

    public function updatedContenidoPieza(): void
    {
        $this->calcularFactorCompra();
    }

    public function updatedUnidadMedidaId(): void
    {
        // Si cambió la unidad base, recalcular factor
        $this->calcularFactorCompra();
    }

    public function save(): void
    {
        if (! $this->authorized) {
            $this->addError('form', 'Sin permiso para guardar');

            return;
        }

        $this->validate();

        try {
            DB::connection('pgsql')->beginTransaction();

            // Generar ID automático si no se proporcionó item_code
            if (empty($this->item_code)) {
                $codeService = app(InsumoCodeService::class);
                $codes = $codeService->generateCode(
                    $this->tipo === 'MATERIA_PRIMA' ? 'MP' : 'PT',
                    'GEN'
                );
                $itemId = $codes['codigo'];
            } else {
                // Generar ID basado en item_code
                $itemId = strtoupper(str_replace(' ', '-', $this->item_code));
                // Validar formato
                if (! preg_match('/^[A-Z0-9\-]{1,20}$/', $itemId)) {
                    $itemId = 'ITEM-'.uniqid();
                }
            }

            // Obtener código de unidad base (legacy field)
            $unidadBase = Unidad::find($this->unidad_medida_id);
            $unidadCodigo = $unidadBase ? $unidadBase->clave : 'PZ';

            // Mapear a código legacy
            $legacyMap = ['KG' => 'KG', 'L' => 'LT', 'PZ' => 'PZ'];
            $unidadLegacy = $legacyMap[$unidadCodigo] ?? 'PZ';

            // Construir presentación automática si no se proporcionó
            if (empty($this->presentacion_texto) && $this->cant_piezas && $this->contenido_pieza) {
                $unidadCompra = Unidad::find($this->unidad_compra_id);
                $unidadBase = Unidad::find($this->unidad_medida_id);

                $this->presentacion_texto = sprintf(
                    '%d pzas de %s %s',
                    $this->cant_piezas,
                    number_format($this->contenido_pieza, 2),
                    $unidadBase ? $unidadBase->clave : ''
                );
            }

            // Crear descripción completa
            $descripcionCompleta = $this->descripcion;
            if ($this->presentacion_texto) {
                $descripcionCompleta .= ($descripcionCompleta ? ' - ' : '').$this->presentacion_texto;
            }

            $payload = [
                'id' => $itemId,
                'item_code' => $this->item_code ?: $itemId,
                'nombre' => $this->nombre,
                'descripcion' => $descripcionCompleta,
                'categoria_id' => $this->generarCategoriaId(),
                'category_id' => $this->category_id,
                'unidad_medida' => $unidadLegacy,
                'unidad_medida_id' => $this->unidad_medida_id,
                'unidad_compra_id' => $this->unidad_compra_id,
                'factor_compra' => $this->factor_compra,
                'unidad_salida_id' => $this->unidad_salida_id,
                'tipo' => $this->tipo,
                'perishable' => $this->perishable,
                'temperatura_min' => $this->temperatura_min,
                'temperatura_max' => $this->temperatura_max,
                'costo_promedio' => $this->costo_promedio ?: 0,
                'activo' => $this->activo,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            DB::connection('pgsql')->table('selemti.items')->insert($payload);

            DB::connection('pgsql')->commit();

            session()->flash('success', 'Item creado correctamente: '.$itemId);

            return redirect()->route('inventory.items');
        } catch (\Throwable $e) {
            DB::connection('pgsql')->rollBack();
            report($e);
            $this->addError('form', 'Error al guardar: '.$e->getMessage());
        }
    }

    public function render()
    {
        return view('livewire.inventory.item-create')
            ->layout('layouts.terrena', [
                'active' => 'inventory',
                'title' => 'Nuevo Item',
                'pageTitle' => 'Alta de Item',
            ]);
    }

    protected function loadCatalogData(): void
    {
        // Cargar unidades BASE (solo KG, L, PZ)
        $this->unidadesBase = Unidad::where('categoria', 'BASE')
            ->where('activo', true)
            ->orderBy('clave')
            ->get(['id', 'clave', 'nombre'])
            ->toArray();

        // Cargar unidades de COMPRA (CAJA, PAQUETE, etc)
        $this->unidadesCompra = Unidad::where('categoria', 'COMPRA')
            ->where('activo', true)
            ->orderBy('clave')
            ->get(['id', 'clave', 'nombre'])
            ->toArray();

        // Cargar unidades de COCINA/SALIDA (ML, TAZA, GRAMO, etc)
        $this->unidadesSalida = Unidad::whereIn('categoria', ['COCINA', 'PORCION'])
            ->where('activo', true)
            ->orderBy('categoria')
            ->orderBy('clave')
            ->get(['id', 'clave', 'nombre', 'categoria'])
            ->toArray();

        // Cargar categorías
        $this->categorias = DB::connection('pgsql')
            ->table('selemti.item_categories')
            ->where('activo', true)
            ->orderBy('nombre')
            ->get(['id', 'nombre'])
            ->toArray();
    }

    protected function calcularFactorCompra(): void
    {
        if ($this->cant_piezas && $this->contenido_pieza && $this->cant_piezas > 0) {
            $this->factor_compra = $this->cant_piezas * $this->contenido_pieza;
        }
    }

    protected function generarCategoriaId(): string
    {
        // Generar categoria_id en formato CAT-XXXX
        if ($this->category_id) {
            return 'CAT-'.str_pad($this->category_id, 4, '0', STR_PAD_LEFT);
        }

        // Por defecto, basado en tipo
        $tipoMap = [
            'MATERIA_PRIMA' => 'CAT-MP',
            'ELABORADO' => 'CAT-ELAB',
            'ENVASADO' => 'CAT-ENV',
        ];

        return $tipoMap[$this->tipo] ?? 'CAT-GEN';
    }
}
