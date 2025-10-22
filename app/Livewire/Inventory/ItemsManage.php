<?php

namespace App\Livewire\Inventory;

use App\Models\Inv\HistorialCostoItem;
use App\Models\Inv\Item as InvItem;
use App\Models\Inv\ItemVendor;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

class ItemsManage extends Component
{
    use WithPagination;

    public string $q = '';
    public int $perPage = 15;
    public bool $showForm = false;
    public bool $isEditing = false;
    public ?string $editingId = null;

    public array $form = [
        'id' => '',
        'nombre' => '',
        'descripcion' => '',
        'categoria_id' => '',
        'unidad_base_id' => null,
        'unidad_compra_id' => null,
        'unidad_salida_id' => null,
        'factor_compra' => 1,
        'factor_conversion' => 1,
        'perishable' => false,
        'temperatura_min' => null,
        'temperatura_max' => null,
        'tipo' => 'MATERIA_PRIMA',
        'activo' => true,
    ];

    public array $providers = [];
    public array $priceHistory = [];

    public array $units = [];
    public array $providerOptions = [];
    public array $tipoOptions = ['MATERIA_PRIMA', 'ELABORADO', 'ENVASADO'];

    protected $queryString = [
        'q' => ['except' => ''],
    ];

    protected $listeners = [
        'refreshItems' => '$refresh',
    ];

    public function mount(): void
    {
        $this->loadUnits();
        $this->loadProviders();
    }

    public function updatingQ(): void
    {
        $this->resetPage();
    }

    public function openCreate(): void
    {
        $this->resetForm();
        $this->showForm = true;
        $this->isEditing = false;
        $this->editingId = null;
        $this->addProviderLine();
    }

    public function openEdit(string $itemId): void
    {
        $item = InvItem::query()->findOrFail($itemId);

        $this->resetForm();

        $this->form = [
            'id' => $item->id,
            'nombre' => $item->nombre,
            'descripcion' => $item->descripcion ?? '',
            'categoria_id' => $item->categoria_id,
            'unidad_base_id' => $item->unidad_medida_id,
            'unidad_compra_id' => $item->unidad_compra_id,
            'unidad_salida_id' => $item->unidad_salida_id,
            'factor_compra' => $item->factor_compra ?? 1,
            'factor_conversion' => $item->factor_conversion ?? 1,
            'perishable' => (bool) $item->perishable,
            'temperatura_min' => $item->temperatura_min,
            'temperatura_max' => $item->temperatura_max,
            'tipo' => $item->tipo ?? 'MATERIA_PRIMA',
            'activo' => (bool) $item->activo,
        ];

        $this->providers = ItemVendor::query()
            ->where('item_id', $itemId)
            ->orderByDesc('preferente')
            ->orderBy('vendor_id')
            ->get()
            ->map(function (ItemVendor $vendor) {
                return [
                    'vendor_id' => $vendor->vendor_id,
                    'presentacion' => $vendor->presentacion,
                    'unidad_presentacion_id' => $vendor->unidad_presentacion_id,
                    'factor_a_canonica' => (float) $vendor->factor_a_canonica,
                    'costo_ultimo' => (float) $vendor->costo_ultimo,
                    'moneda' => $vendor->moneda ?? 'MXN',
                    'lead_time_dias' => $vendor->lead_time_dias,
                    'codigo_proveedor' => $vendor->codigo_proveedor,
                    'preferente' => (bool) $vendor->preferente,
                ];
            })
            ->values()
            ->toArray();

        if ($this->providers === []) {
            $this->addProviderLine();
        }

        $this->priceHistory = HistorialCostoItem::query()
            ->where('item_id', $itemId)
            ->orderByDesc('fecha_efectiva')
            ->orderByDesc('version_datos')
            ->limit(15)
            ->get()
            ->map(function (HistorialCostoItem $history) {
                return [
                    'fecha_efectiva' => optional($history->fecha_efectiva)->format('Y-m-d'),
                    'costo_nuevo' => (float) $history->costo_nuevo,
                    'costo_anterior' => (float) ($history->costo_anterior ?? 0),
                    'fuente_datos' => $history->fuente_datos ?? '-',
                    'usuario_id' => $history->usuario_id,
                    'version_datos' => $history->version_datos,
                ];
            })
            ->toArray();

        $this->showForm = true;
        $this->isEditing = true;
        $this->editingId = $item->id;
    }

    public function addProviderLine(): void
    {
        $this->providers[] = [
            'vendor_id' => null,
            'presentacion' => '',
            'unidad_presentacion_id' => null,
            'factor_a_canonica' => 1,
            'costo_ultimo' => null,
            'moneda' => 'MXN',
            'lead_time_dias' => null,
            'codigo_proveedor' => '',
            'preferente' => $this->providers === [],
        ];
    }

    public function removeProviderLine(int $index): void
    {
        if (!isset($this->providers[$index])) {
            return;
        }

        unset($this->providers[$index]);
        $this->providers = array_values($this->providers);

        if ($this->providers === []) {
            $this->addProviderLine();
        } else {
            $this->ensureSinglePreferred();
        }
    }

    public function setPreferred(int $index): void
    {
        if (!isset($this->providers[$index])) {
            return;
        }

        foreach ($this->providers as $i => &$provider) {
            $provider['preferente'] = $i === $index;
        }
        unset($provider);
    }

    public function save(): void
    {
        $validated = $this->validate($this->rules(), $this->messages());
        $providerData = $this->validateProviders();

        DB::connection('pgsql')->transaction(function () use ($validated, $providerData) {
            $validated['id'] = strtoupper(trim($validated['id']));
            $validated['nombre'] = trim($validated['nombre']);
            $validated['descripcion'] = $validated['descripcion'] ? trim($validated['descripcion']) : null;
            $validated['categoria_id'] = strtoupper(trim($validated['categoria_id']));
            $validated['factor_compra'] = $validated['factor_compra'] ?: 1;
            $validated['factor_conversion'] = $validated['factor_conversion'] ?: 1;
            $validated['perishable'] = filter_var($validated['perishable'], FILTER_VALIDATE_BOOLEAN);
            $validated['activo'] = filter_var($validated['activo'], FILTER_VALIDATE_BOOLEAN);

            $payload = [
                'id' => $validated['id'],
                'nombre' => $validated['nombre'],
                'descripcion' => $validated['descripcion'] ?: null,
                'categoria_id' => $validated['categoria_id'],
                'unidad_medida_id' => $validated['unidad_base_id'],
                'unidad_compra_id' => $validated['unidad_compra_id'] ?: null,
                'unidad_salida_id' => $validated['unidad_salida_id'] ?: null,
                'factor_compra' => (float) $validated['factor_compra'],
                'factor_conversion' => (float) $validated['factor_conversion'],
                'perishable' => $validated['perishable'],
                'temperatura_min' => $validated['temperatura_min'],
                'temperatura_max' => $validated['temperatura_max'],
                'tipo' => $validated['tipo'],
                'activo' => $validated['activo'],
            ];

            if ($this->isEditing) {
                InvItem::query()->whereKey($this->editingId)->update(array_merge(
                    Arr::except($payload, ['id']),
                    [
                        'unidad_medida' => $this->unitCode($payload['unidad_medida_id']),
                        'updated_at' => now(),
                    ]
                ));
            } else {
                InvItem::query()->insert(array_merge(
                    $payload,
                    [
                        'unidad_medida' => $this->unitCode($payload['unidad_medida_id']),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                ));
            }

            ItemVendor::query()->where('item_id', $payload['id'])->delete();

            $preferredCost = null;
            foreach ($providerData as $provider) {
                $record = [
                    'item_id' => $payload['id'],
                    'vendor_id' => (string) $provider['vendor_id'],
                    'presentacion' => $provider['presentacion'],
                    'unidad_presentacion_id' => $provider['unidad_presentacion_id'],
                    'factor_a_canonica' => (float) $provider['factor_a_canonica'],
                    'costo_ultimo' => (float) $provider['costo_ultimo'],
                    'moneda' => $provider['moneda'],
                    'lead_time_dias' => $provider['lead_time_dias'],
                    'codigo_proveedor' => $provider['codigo_proveedor'] ?: null,
                    'preferente' => $provider['preferente'],
                    'activo' => true,
                    'created_at' => now(),
                ];

                ItemVendor::query()->insert($record);

                if ($provider['preferente']) {
                    $preferredCost = (float) $provider['costo_ultimo'];
                }
            }

            if ($preferredCost !== null) {
                InvItem::query()
                    ->where('id', $payload['id'])
                    ->update(['costo_promedio' => $preferredCost]);

                $this->registerPriceHistory($payload['id'], $preferredCost);
            }
        });

        $this->dispatch('toast', body: 'Item guardado correctamente');
        $this->resetForm();
        $this->showForm = false;
        $this->isEditing = false;
        $this->editingId = null;
        $this->emitSelf('refreshItems');
    }

    public function closeForm(): void
    {
        $this->showForm = false;
    }

    public function render()
    {
        $items = DB::connection('pgsql')
            ->table(DB::raw('selemti.items as i'))
            ->leftJoin(DB::raw('selemti.vw_item_last_price_pref as lp'), 'lp.item_id', '=', 'i.id')
            ->leftJoin(DB::raw('selemti.item_vendor as pv'), function ($join) {
                $join->on('pv.item_id', '=', 'i.id');
                $join->on(DB::raw('pv.vendor_id::text'), '=', 'lp.vendor_id');
            })
            ->when($this->q !== '', function ($query) {
                $needle = '%' . trim($this->q) . '%';
                $query->where(function ($sub) use ($needle) {
                    $sub->where('i.id', 'ilike', $needle)
                        ->orWhere('i.nombre', 'ilike', $needle)
                        ->orWhere('i.descripcion', 'ilike', $needle);
                });
            })
            ->orderBy('i.nombre')
            ->select([
                'i.id',
                'i.item_code',
                'i.nombre',
                'i.categoria_id',
                'i.unidad_medida_id',
                'i.unidad_compra_id',
                'i.tipo',
                'i.costo_promedio',
                'i.perishable',
                'i.activo',
                'lp.vendor_id as preferente_vendor',
                'lp.price as preferente_price',
                'lp.pack_qty as preferente_pack_qty',
                'lp.pack_uom as preferente_pack_uom',
                'lp.effective_from as preferente_effective_from',
                'pv.presentacion as preferente_presentacion',
            ])
            ->paginate($this->perPage);

        $unitsIndex = collect($this->units)->keyBy('id');

        return view('livewire.inventory.items-manage', [
            'items' => $items,
            'unitsIndex' => $unitsIndex,
        ])->layout('layouts.terrena', [
            'active' => 'inventario',
            'title' => 'Catálogo · Ítems',
            'pageTitle' => 'Ítems de inventario',
        ]);
    }

    protected function rules(): array
    {
        $idRule = $this->isEditing
            ? 'required|string|max:20|regex:/^[A-Z0-9\-]+$/|exists:selemti.items,id'
            : 'required|string|max:20|regex:/^[A-Z0-9\-]+$/|unique:selemti.items,id';

        return [
            'form.id' => $idRule,
            'form.nombre' => 'required|string|min:3|max:100',
            'form.descripcion' => 'nullable|string|max:500',
            'form.categoria_id' => 'required|string|regex:/^CAT-[A-Z0-9\-]{2,}$/',
            'form.unidad_base_id' => 'required|integer|exists:selemti.unidades_medida,id',
            'form.unidad_compra_id' => 'nullable|integer|exists:selemti.unidades_medida,id',
            'form.unidad_salida_id' => 'nullable|integer|exists:selemti.unidades_medida,id',
            'form.factor_compra' => 'nullable|numeric|min:0.0001',
            'form.factor_conversion' => 'nullable|numeric|min:0.0001',
            'form.perishable' => 'boolean',
            'form.temperatura_min' => 'nullable|integer',
            'form.temperatura_max' => 'nullable|integer|gte:form.temperatura_min',
            'form.tipo' => 'nullable|in:' . implode(',', $this->tipoOptions),
            'form.activo' => 'boolean',
        ];
    }

    protected function messages(): array
    {
        return [
            'form.id.regex' => 'El SKU debe usar únicamente mayúsculas, números o guiones.',
            'form.categoria_id.regex' => 'Usa el formato CAT-XXXX para la categoría.',
            'form.temperatura_max.gte' => 'La temperatura máxima debe ser mayor o igual que la mínima.',
        ];
    }

    protected function validateProviders(): array
    {
        $validatedProviders = [];
        $preferredExists = false;

        foreach ($this->providers as $index => $provider) {
            $rules = [
                'vendor_id' => 'required|integer|exists:selemti.cat_proveedores,id',
                'presentacion' => 'required|string|max:120',
                'unidad_presentacion_id' => 'required|integer|exists:selemti.unidades_medida,id',
                'factor_a_canonica' => 'required|numeric|min:0.0001',
                'costo_ultimo' => 'required|numeric|min:0',
                'moneda' => 'required|string|in:MXN,USD',
                'lead_time_dias' => 'nullable|integer|min:0',
                'codigo_proveedor' => 'nullable|string|max:120',
                'preferente' => 'boolean',
            ];

            $messages = [
                'vendor_id.required' => 'Selecciona un proveedor.',
                'presentacion.required' => 'Indica la presentación.',
                'unidad_presentacion_id.required' => 'Selecciona la unidad de la presentación.',
                'factor_a_canonica.min' => 'El factor debe ser mayor a cero.',
                'costo_ultimo.required' => 'Captura el costo.',
            ];

            $data = validator($provider, $rules, $messages)->validate();

            if ($data['preferente']) {
                $preferredExists = true;
            }

            $validatedProviders[] = $data;
        }

        if (!$preferredExists && $validatedProviders !== []) {
            // marca primero como preferente si el usuario no lo hizo
            $validatedProviders[0]['preferente'] = true;
        }

        $this->providers = $validatedProviders;

        return $validatedProviders;
    }

    protected function registerPriceHistory(string $itemId, float $newCost): void
    {
        $last = HistorialCostoItem::query()
            ->where('item_id', $itemId)
            ->orderByDesc('fecha_efectiva')
            ->orderByDesc('version_datos')
            ->first();

        $version = $last ? ($last->version_datos + 1) : 1;

        if ($last && $last->valid_to === null) {
            $last->valid_to = now()->toDateString();
            $last->save();
        }

        HistorialCostoItem::query()->create([
            'item_id' => $itemId,
            'fecha_efectiva' => now()->toDateString(),
            'fecha_registro' => now(),
            'costo_anterior' => $last->costo_nuevo ?? null,
            'costo_nuevo' => $newCost,
            'tipo_cambio' => 'COMPRA',
            'referencia_id' => null,
            'referencia_tipo' => 'MANUAL',
            'usuario_id' => Auth::id(),
            'valid_from' => now()->toDateString(),
            'valid_to' => null,
            'sys_from' => now(),
            'costo_wac' => $newCost,
            'algoritmo_principal' => 'WAC',
            'version_datos' => $version,
            'recalculado' => false,
            'fuente_datos' => 'CAPTURA',
            'metadata_calculo' => [
                'origen' => 'items-manage',
                'usuario' => Auth::id(),
            ],
            'created_at' => now(),
        ]);
    }

    protected function resetForm(): void
    {
        $this->form = [
            'id' => '',
            'nombre' => '',
            'descripcion' => '',
            'categoria_id' => '',
            'unidad_base_id' => null,
            'unidad_compra_id' => null,
            'unidad_salida_id' => null,
            'factor_compra' => 1,
            'factor_conversion' => 1,
            'perishable' => false,
            'temperatura_min' => null,
            'temperatura_max' => null,
            'tipo' => 'MATERIA_PRIMA',
            'activo' => true,
        ];

        $this->providers = [];
        $this->priceHistory = [];
    }

    protected function ensureSinglePreferred(): void
    {
        $found = false;
        foreach ($this->providers as &$provider) {
            if ($provider['preferente'] && !$found) {
                $found = true;
                continue;
            }
            $provider['preferente'] = false;
        }
        unset($provider);

        if (!$found && $this->providers !== []) {
            $this->providers[0]['preferente'] = true;
        }
    }

    protected function loadUnits(): void
    {
        $this->units = DB::connection('pgsql')
            ->table(DB::raw('selemti.unidades_medida'))
            ->orderBy('nombre')
            ->get(['id', 'codigo', 'nombre'])
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'codigo' => $row->codigo,
                'nombre' => $row->nombre,
            ])->toArray();
    }

    protected function loadProviders(): void
    {
        $this->providerOptions = DB::connection('pgsql')
            ->table(DB::raw('selemti.cat_proveedores'))
            ->where('activo', true)
            ->orderBy('nombre')
            ->get(['id', 'nombre'])
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'nombre' => $row->nombre,
            ])->toArray();
    }

    protected function unitCode(?int $unitId): ?string
    {
        if (!$unitId) {
            return null;
        }

        $unit = collect($this->units)->firstWhere('id', $unitId);
        return $unit['codigo'] ?? null;
    }
}
