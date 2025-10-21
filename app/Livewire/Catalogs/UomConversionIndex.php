<?php

namespace App\Livewire\Catalogs;

use App\Models\Catalogs\Unidad;
use App\Models\Catalogs\UomConversion;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;
use Livewire\Attributes\On;

class UomConversionIndex extends Component
{
    use WithPagination;

    protected string $paginationTheme = 'bootstrap';
    public string $search = '';
    public ?int $editId = null;
    public ?int $origen_id = null;
    public ?int $destino_id = null;
    public float $factor = 1.0;
    public bool $tableReady = false;
    public bool $unitsReady = false;
    public string $tableNotice = '';
    protected ?string $unitKeyColumn = null;
    protected ?string $unitNameColumn = null;

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
        $origenRules = ['required','integer'];
        $destinoRules = ['required','integer','different:origen_id'];

        if ($this->unitsReady) {
            $origenRules[] = 'exists:selemti.unidades_medida,id';
            $destinoRules[] = 'exists:selemti.unidades_medida,id';
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
            'origen_id'  => $origenRules,
            'destino_id' => $destinoRules,
            'factor'     => ['required','numeric','gt:0'],
        ];
    }

    private function resetForm(): void
    {
        $this->reset(['editId','origen_id','destino_id']);
        $this->factor = 1.0;
    }

    public function create()
    {
        if (! $this->tableReady || ! $this->unitsReady) {
            session()->flash('warn','Catálogo no disponible. Ejecuta las migraciones correspondientes.');
            return;
        }

        $this->resetForm();
        $this->dispatch('toggle-uom-modal', open: true);
    }

    public function edit(int $id)
    {
        if (! $this->tableReady) {
            session()->flash('warn','Catálogo no disponible. Ejecuta las migraciones antes de continuar.');
            return;
        }

        $conversion = UomConversion::findOrFail($id);

        $this->editId     = $conversion->id;
        $this->origen_id  = $conversion->origen_id;
        $this->destino_id = $conversion->destino_id;
        $this->factor     = (float) $conversion->factor;
        $this->dispatch('toggle-uom-modal', open: true);
    }

    public function save()
    {
        if (! $this->tableReady || ! $this->unitsReady) {
            session()->flash('warn','No es posible guardar porque las tablas requeridas no están disponibles.');
            return;
        }

        $this->validate();

        $payload = [
            'origen_id'  => $this->origen_id,
            'destino_id' => $this->destino_id,
            'factor'     => $this->factor,
        ];

        if ($this->editId) {
            UomConversion::findOrFail($this->editId)->update($payload);
        } else {
            UomConversion::create($payload);
        }

        $this->resetForm();
        session()->flash('ok','Conversión guardada');
        $this->dispatch('toggle-uom-modal', open: false);
    }

    public function delete(int $id)
    {
        if (! $this->tableReady) {
            session()->flash('warn','No es posible eliminar porque la tabla cat_uom_conversion no está disponible.');
            return;
        }

        UomConversion::whereKey($id)->delete();
        session()->flash('ok','Conversión eliminada');
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
                    $needle = '%' . $this->search . '%';
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
                'path'  => request()->url(),
                'query' => request()->query(),
            ]);
        }

        if ($this->tableReady && $this->unitsReady) {
            $rows->getCollection()->transform(function ($row) {
                $row->origenKey = $this->formatUnitKey($row->origen, $row->origen_id);
                $row->origenName = $this->formatUnitName($row->origen);
                $row->destinoKey = $this->formatUnitKey($row->destino, $row->destino_id);
                $row->destinoName = $this->formatUnitName($row->destino);
                return $row;
            });
        }

        $unitOptions = $this->unitsReady
            ? Unidad::query()
                ->orderBy('nombre')
                ->get()
                ->map(fn ($unit) => (object) [
                    'id'    => $unit->id,
                    'label' => $this->formatUnitLabel($unit),
                ])
            : collect();

        return view('livewire.catalogs.uom-conversion-index', [
            'rows'        => $rows,
            'unitOptions' => $unitOptions,
            'allowEditing'=> $this->tableReady && $this->unitsReady,
            'tableNotice' => $this->tableNotice,
        ])
            ->layout('layouts.terrena', [
                'active'    => 'config',
                'title'     => 'Catálogo · Conversiones UOM',
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
        $this->unitKeyColumn = 'codigo';
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
        if ($unit && ($codigo = $unit->codigo)) {
            return strtoupper($codigo);
        }

        return 'ID ' . $fallbackId;
    }

    protected function formatUnitName($unit): ?string
    {
        if ($unit && $unit->nombre && strtoupper($unit->codigo ?? '') !== strtoupper($unit->nombre)) {
            return $unit->nombre;
        }

        return null;
    }

    protected function formatUnitLabel($unit): string
    {
        $codigo = $unit->codigo ? strtoupper($unit->codigo) : null;
        $nombre = $unit->nombre ?? null;

        if ($codigo && $nombre && strcasecmp($codigo, $nombre) !== 0) {
            return $codigo . ' — ' . $nombre;
        }

        if ($codigo) {
            return $codigo;
        }

        if ($nombre) {
            return $nombre;
        }

        return 'ID ' . $unit->id;
    }

    protected function applyUnitSearch($query, string $needle): void
    {
        $query->where(function ($qq) use ($needle) {
            $qq->where('codigo', 'ilike', $needle)
               ->orWhere('nombre', 'ilike', $needle);
        });
    }
}
