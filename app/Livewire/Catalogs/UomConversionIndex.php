<?php

namespace App\Livewire\Catalogs;

use App\Models\Catalogs\Unidad;
use App\Models\Catalogs\UomConversion;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;
use Livewire\Attributes\Computed;
use Livewire\Attributes\On;
use Livewire\Component;
use Livewire\WithPagination;

class UomConversionIndex extends Component
{
    use WithPagination;

    protected string $paginationTheme = 'bootstrap';

    public string $search = '';

    public ?int $editId = null;

    public ?int $origen_id = null;

    public ?int $destino_id = null;

    public float $factor = 1.0;

    public bool $is_exact = true;

    public string $scope = 'global';

    public string $notes = '';

    public bool $tableReady = false;

    public bool $unitsReady = false;

    public string $tableNotice = '';

    protected ?string $unitKeyColumn = null;

    protected ?string $unitNameColumn = null;

    // Calculator properties
    public float $calcCantidad = 1.0;

    public ?int $calcOrigen = null;

    public ?int $calcDestino = null;

    public function mount(): void
    {
        $this->tableReady = Schema::hasTable('cat_uom_conversion');
        $this->unitsReady = $this->checkUnitsTable();

        if (! $this->tableReady && ! $this->unitsReady) {
            $this->tableNotice = 'No se detectaron las tablas de conversiones ni de unidades. Verifica que la base de datos tenga selemti.cat_uom_conversion y selemti.unidades_medida.';
        } elseif (! $this->tableReady) {
            $this->tableNotice = 'La tabla de conversiones (cat_uom_conversion) no existe. Ejecuta las migraciones correspondientes.';
        } elseif (! $this->unitsReady) {
            $this->tableNotice = 'No se pudo consultar selemti.unidades_medida. Verifica que la tabla exista y que las credenciales tengan permisos.';
        }

        $this->resolveUnitColumns();
    }

    protected function rules(): array
    {
        $origenRules = ['required', 'integer'];
        $destinoRules = ['required', 'integer', 'different:origen_id'];

        if ($this->unitsReady) {
            $origenRules[] = 'exists:selemti.cat_unidades,id';
            $destinoRules[] = 'exists:selemti.cat_unidades,id';
        }

        if ($this->tableReady) {
            $uniqueRule = Rule::unique('cat_uom_conversion', 'origen_id')
                ->where(fn ($query) => $query->where('destino_id', $this->destino_id));

            if ($this->editId) {
                $uniqueRule = $uniqueRule->ignore($this->editId);
            }

            $origenRules[] = $uniqueRule;
        }

        return [
            'origen_id' => $origenRules,
            'destino_id' => $destinoRules,
            'factor' => ['required', 'numeric', 'gt:0'],
            'is_exact' => ['boolean'],
            'scope' => ['string', 'in:global,branch,recipe'],
            'notes' => ['nullable', 'string', 'max:255'],
        ];
    }

    // =====================================================
    // COMPUTED PROPERTIES
    // =====================================================

    #[Computed]
    public function calcResultado()
    {
        if (! $this->calcOrigen || ! $this->calcDestino || ! $this->calcCantidad) {
            return null;
        }

        $origenUnit = Unidad::find($this->calcOrigen);
        if (! $origenUnit) {
            return null;
        }

        $factor = $origenUnit->getFactorTo($this->calcDestino);
        if (! $factor) {
            return null;
        }

        return $this->calcCantidad * $factor;
    }

    #[Computed]
    public function calcOrigenNombre()
    {
        if (! $this->calcOrigen) {
            return '';
        }
        $unit = Unidad::find($this->calcOrigen);

        return $unit ? $unit->clave : '';
    }

    #[Computed]
    public function calcDestinoNombre()
    {
        if (! $this->calcDestino) {
            return '';
        }
        $unit = Unidad::find($this->calcDestino);

        return $unit ? $unit->clave : '';
    }

    #[Computed]
    public function conversionesPeso()
    {
        if (! $this->tableReady || ! $this->unitsReady) {
            return collect();
        }

        $kgUnit = Unidad::where('clave', 'KG')->first();
        if (! $kgUnit) {
            return collect();
        }

        return UomConversion::with('origen')
            ->where('destino_id', $kgUnit->id)
            ->orderBy('factor', 'desc')
            ->get()
            ->map(function ($conv) use ($kgUnit) {
                $conv->origenClave = $conv->origen->clave ?? 'N/A';
                $conv->origenNombre = $conv->origen->nombre ?? '';
                $conv->destinoClave = $kgUnit->clave;
                $conv->destinoNombre = $kgUnit->nombre;

                return $conv;
            });
    }

    #[Computed]
    public function conversionesVolumen()
    {
        if (! $this->tableReady || ! $this->unitsReady) {
            return collect();
        }

        $lUnit = Unidad::where('clave', 'L')->first();
        if (! $lUnit) {
            return collect();
        }

        return UomConversion::with('origen')
            ->where('destino_id', $lUnit->id)
            ->orderBy('factor', 'desc')
            ->get()
            ->map(function ($conv) use ($lUnit) {
                $conv->origenClave = $conv->origen->clave ?? 'N/A';
                $conv->origenNombre = $conv->origen->nombre ?? '';
                $conv->destinoClave = $lUnit->clave;
                $conv->destinoNombre = $lUnit->nombre;

                return $conv;
            });
    }

    #[Computed]
    public function conversionesBidireccionales()
    {
        if (! $this->tableReady || ! $this->unitsReady) {
            return collect();
        }

        $bidirectional = collect();
        $conversions = UomConversion::with(['origen', 'destino'])->get();

        foreach ($conversions as $conv) {
            $inverse = $conversions->first(function ($c) use ($conv) {
                return $c->origen_id === $conv->destino_id && $c->destino_id === $conv->origen_id;
            });

            if ($inverse) {
                // Only add once (using lower ID as key to avoid duplicates)
                $key = min($conv->origen_id, $conv->destino_id).'-'.max($conv->origen_id, $conv->destino_id);

                if (! $bidirectional->has($key)) {
                    $bidirectional->put($key, [
                        'unidad1' => $conv->origen->clave ?? 'N/A',
                        'unidad2' => $conv->destino->clave ?? 'N/A',
                        'factor1' => $conv->factor,
                        'factor2' => $inverse->factor,
                    ]);
                }
            }
        }

        return $bidirectional->values();
    }

    #[Computed]
    public function sugerencias()
    {
        if (! $this->tableReady || ! $this->unitsReady) {
            return collect();
        }

        $suggestions = collect();
        $existingPairs = UomConversion::pluck('destino_id', 'origen_id')->toArray();

        // Get base units
        $baseUnits = Unidad::whereIn('clave', ['KG', 'L', 'PZ'])->get()->keyBy('clave');

        // Get COCINA units without conversions to BASE
        $cocinaUnits = Unidad::where('categoria', 'COCINA')
            ->where('activo', true)
            ->get();

        foreach ($cocinaUnits as $unit) {
            // Suggest conversion to KG for peso-based units
            if (in_array($unit->clave, ['G', 'MG', 'PIZCA']) && $baseUnits->has('KG')) {
                $kgId = $baseUnits['KG']->id;
                if (! isset($existingPairs[$unit->id]) || $existingPairs[$unit->id] != $kgId) {
                    $factor = $this->getSuggestedFactor($unit->clave, 'KG');
                    if ($factor) {
                        $suggestions->push([
                            'origenId' => $unit->id,
                            'destinoId' => $kgId,
                            'origen' => $unit->clave,
                            'destino' => 'KG',
                            'factor' => $factor,
                            'razon' => 'Unidad de peso sin conversión a KG',
                        ]);
                    }
                }
            }

            // Suggest conversion to L for volume-based units
            if (in_array($unit->clave, ['ML', 'TAZA', 'CUCH', 'CUCHT', 'VASO']) && $baseUnits->has('L')) {
                $lId = $baseUnits['L']->id;
                if (! isset($existingPairs[$unit->id]) || $existingPairs[$unit->id] != $lId) {
                    $factor = $this->getSuggestedFactor($unit->clave, 'L');
                    if ($factor) {
                        $suggestions->push([
                            'origenId' => $unit->id,
                            'destinoId' => $lId,
                            'origen' => $unit->clave,
                            'destino' => 'L',
                            'factor' => $factor,
                            'razon' => 'Unidad de volumen sin conversión a L',
                        ]);
                    }
                }
            }
        }

        return $suggestions->take(5);
    }

    #[Computed]
    public function totalConversiones()
    {
        if (! $this->tableReady) {
            return 0;
        }

        return UomConversion::count();
    }

    #[Computed]
    public function origenPreview()
    {
        if (! $this->origen_id) {
            return '';
        }

        $unit = Unidad::find($this->origen_id);

        return $unit ? $unit->clave : '';
    }

    #[Computed]
    public function destinoPreview()
    {
        if (! $this->destino_id) {
            return '';
        }

        $unit = Unidad::find($this->destino_id);

        return $unit ? $unit->clave : '';
    }

    // =====================================================
    // HELPER METHODS
    // =====================================================

    protected function getSuggestedFactor(string $fromClave, string $toClave): ?float
    {
        // Known conversion factors
        $factors = [
            'G-KG' => 0.001,
            'MG-KG' => 0.000001,
            'PIZCA-KG' => 0.0005,
            'ML-L' => 0.001,
            'TAZA-L' => 0.240,
            'CUCH-L' => 0.015,
            'CUCHT-L' => 0.005,
            'VASO-L' => 0.250,
        ];

        $key = $fromClave.'-'.$toClave;

        return $factors[$key] ?? null;
    }

    private function resetForm(): void
    {
        $this->reset(['editId', 'origen_id', 'destino_id']);
        $this->factor = 1.0;
        $this->is_exact = true;
        $this->scope = 'global';
        $this->notes = '';
    }

    // =====================================================
    // QUICK ACTION METHODS
    // =====================================================

    public function createFromCalc()
    {
        if (! $this->calcOrigen || ! $this->calcDestino) {
            session()->flash('warn', 'Selecciona origen y destino en la calculadora');

            return;
        }

        $origenUnit = Unidad::find($this->calcOrigen);
        $factor = $origenUnit->getFactorTo($this->calcDestino);

        if (! $factor) {
            session()->flash('warn', 'No se pudo calcular el factor de conversión');

            return;
        }

        $this->resetForm();
        $this->origen_id = $this->calcOrigen;
        $this->destino_id = $this->calcDestino;
        $this->factor = $factor;
        $this->dispatch('toggle-uom-modal', open: true);
    }

    public function createFromSuggestion($origenId, $destinoId, $factorSugerido = null)
    {
        $this->resetForm();
        $this->origen_id = (int) $origenId;
        $this->destino_id = (int) $destinoId;

        if ($factorSugerido) {
            $this->factor = (float) $factorSugerido;
        }

        $this->dispatch('toggle-uom-modal', open: true);
    }

    public function create()
    {
        if (! $this->tableReady || ! $this->unitsReady) {
            session()->flash('warn', 'Catálogo no disponible. Ejecuta las migraciones correspondientes.');

            return;
        }

        $this->resetForm();
        $this->dispatch('toggle-uom-modal', open: true);
    }

    public function edit(int $id)
    {
        if (! $this->tableReady) {
            session()->flash('warn', 'Catálogo no disponible. Ejecuta las migraciones antes de continuar.');

            return;
        }

        $conversion = UomConversion::findOrFail($id);

        $this->editId = $conversion->id;
        $this->origen_id = $conversion->origen_id;
        $this->destino_id = $conversion->destino_id;
        $this->factor = (float) $conversion->factor;
        $this->is_exact = $conversion->is_exact ?? true;
        $this->scope = $conversion->scope ?? 'global';
        $this->notes = $conversion->notes ?? '';
        $this->dispatch('toggle-uom-modal', open: true);
    }

    public function save()
    {
        if (! $this->tableReady || ! $this->unitsReady) {
            session()->flash('warn', 'No es posible guardar porque las tablas requeridas no están disponibles.');

            return;
        }

        $this->validate();

        $payload = [
            'origen_id' => $this->origen_id,
            'destino_id' => $this->destino_id,
            'factor' => $this->factor,
            'is_exact' => $this->is_exact,
            'scope' => $this->scope,
            'notes' => $this->notes ?: null,
        ];

        if ($this->editId) {
            UomConversion::findOrFail($this->editId)->update($payload);
        } else {
            UomConversion::create($payload);
        }

        $this->resetForm();
        session()->flash('ok', 'Conversión guardada');
        $this->dispatch('toggle-uom-modal', open: false);
    }

    public function delete(int $id)
    {
        if (! $this->tableReady) {
            session()->flash('warn', 'No es posible eliminar porque la tabla cat_uom_conversion no está disponible.');

            return;
        }

        UomConversion::whereKey($id)->delete();
        session()->flash('ok', 'Conversión eliminada');
        $this->resetForm();
        $this->dispatch('toggle-uom-modal', open: false);
    }

    public function closeModal(): void
    {
        $this->resetForm();
        $this->dispatch('toggle-uom-modal', open: false);
    }

    public function render()
    {
        if ($this->tableReady && $this->unitsReady) {
            $rows = UomConversion::with(['origen', 'destino'])
                ->when($this->search !== '', function ($query) {
                    $needle = '%'.$this->search.'%';
                    $query->where(function ($sub) use ($needle) {
                        $sub->whereHas('origen', function ($q) use ($needle) {
                            $this->applyUnitSearch($q, $needle);
                        })->orWhereHas('destino', function ($q) use ($needle) {
                            $this->applyUnitSearch($q, $needle);
                        });
                    });
                })
                ->orderBy('origen_id')
                ->orderBy('destino_id')
                ->paginate(10);
        } else {
            $rows = new LengthAwarePaginator([], 0, 10, 1, [
                'path' => request()->url(),
                'query' => request()->query(),
            ]);
        }

        if ($this->tableReady && $this->unitsReady) {
            $rows->getCollection()->transform(function ($row) {
                $row->origenClave = $this->formatUnitKey($row->origen, $row->origen_id);
                $row->origenNombre = $this->formatUnitName($row->origen);
                $row->destinoClave = $this->formatUnitKey($row->destino, $row->destino_id);
                $row->destinoNombre = $this->formatUnitName($row->destino);

                return $row;
            });
        }

        $unitOptions = $this->unitsReady
            ? Unidad::query()
                ->where('activo', true)
                ->orderBy('categoria', 'asc')
                ->orderBy('clave', 'asc')
                ->get()
                ->map(fn ($unit) => (object) [
                    'id' => $unit->id,
                    'clave' => $unit->clave,
                    'nombre' => $unit->nombre,
                    'categoria' => $unit->categoria,
                    'label' => $this->formatUnitLabel($unit),
                ])
            : collect();

        return view('livewire.catalogs.uom-conversion-index', [
            'rows' => $rows,
            'unitOptions' => $unitOptions,
            'allowEditing' => $this->tableReady && $this->unitsReady,
            'tableNotice' => $this->tableNotice,
        ])
            ->layout('layouts.terrena', [
                'active' => 'config',
                'title' => 'Catálogo · Conversiones UOM',
                'pageTitle' => 'Conversiones de Unidades',
            ]);
    }

    #[On('uom-modal-closed')]
    public function handleModalClosed(): void
    {
        $this->resetForm();
    }

    protected function checkUnitsTable(): bool
    {
        try {
            Unidad::query()->limit(1)->exists();

            return true;
        } catch (\Throwable $e) {
            return false;
        }
    }

    protected function resolveUnitColumns(): void
    {
        $this->unitKeyColumn = 'clave';
        $this->unitNameColumn = 'nombre';
    }

    protected function findFirstAvailable(array $columns, array $candidates): ?string
    {
        foreach ($candidates as $candidate) {
            if (in_array($candidate, $columns, true)) {
                return $candidate;
            }
        }

        return null;
    }

    protected function formatUnitKey($unit, int $fallbackId): string
    {
        if ($unit && ($clave = $unit->clave)) {
            return strtoupper($clave);
        }

        return 'ID '.$fallbackId;
    }

    protected function formatUnitName($unit): ?string
    {
        if ($unit && $unit->nombre && strtoupper($unit->clave ?? '') !== strtoupper($unit->nombre)) {
            return $unit->nombre;
        }

        return null;
    }

    protected function formatUnitLabel($unit): string
    {
        $clave = $unit->clave ? strtoupper($unit->clave) : null;
        $nombre = $unit->nombre ?? null;

        if ($clave && $nombre && strcasecmp($clave, $nombre) !== 0) {
            return $clave.' — '.$nombre;
        }

        if ($clave) {
            return $clave;
        }

        if ($nombre) {
            return $nombre;
        }

        return 'ID '.$unit->id;
    }

    protected function applyUnitSearch($query, string $needle): void
    {
        $query->where(function ($qq) use ($needle) {
            $qq->where('clave', 'ilike', $needle)
                ->orWhere('nombre', 'ilike', $needle);
        });
    }
}
