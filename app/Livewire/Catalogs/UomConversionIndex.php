<?php

namespace App\Livewire\Catalogs;

use App\Models\CatUnidad;
use App\Models\Catalogs\UomConversion;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;

class UomConversionIndex extends Component
{
    use WithPagination;

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
        $this->unitsReady = Schema::hasTable('cat_unidades');

        if (! $this->tableReady && ! $this->unitsReady) {
            $this->tableNotice = 'Las tablas cat_uom_conversion y cat_unidades no existen. Ejecuta las migraciones de catálogos para habilitar este módulo.';
        } elseif (! $this->tableReady) {
            $this->tableNotice = 'La tabla cat_uom_conversion no existe. Ejecuta las migraciones correspondientes.';
        } elseif (! $this->unitsReady) {
            $this->tableNotice = 'La tabla cat_unidades no existe. Ejecuta las migraciones correspondientes antes de gestionar conversiones.';
        }

        $this->resolveUnitColumns();
    }

    protected function rules(): array
    {
        $origenRules = ['required','integer'];
        $destinoRules = ['required','integer','different:origen_id'];

        if ($this->unitsReady) {
            $origenRules[] = 'exists:cat_unidades,id';
            $destinoRules[] = 'exists:cat_unidades,id';
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

    public function create()
    {
        $this->reset(['editId','origen_id','destino_id','factor']);
        $this->factor = 1.0;
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

        $this->create();
        session()->flash('ok','Conversión guardada');
    }

    public function delete(int $id)
    {
        if (! $this->tableReady) {
            session()->flash('warn','No es posible eliminar porque la tabla cat_uom_conversion no está disponible.');
            return;
        }

        UomConversion::whereKey($id)->delete();
        session()->flash('ok','Conversión eliminada');
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
            $rows = new LengthAwarePaginator([], 0, 10, $this->getPage(), [
                'path'  => request()->url(),
                'query' => request()->query(),
            ]);
        }

        if ($this->tableReady && $this->unitsReady) {
            $rows->getCollection()->transform(function ($row) {
                $row->origenKey = $this->extractUnitValue($row->origen, $this->unitKeyColumn);
                $row->origenName = $this->extractUnitValue($row->origen, $this->unitNameColumn);
                $row->destinoKey = $this->extractUnitValue($row->destino, $this->unitKeyColumn);
                $row->destinoName = $this->extractUnitValue($row->destino, $this->unitNameColumn);
                return $row;
            });
        }

        $unitOptions = $this->unitsReady
            ? CatUnidad::query()
                ->orderBy($this->unitOrderColumn(), 'asc')
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

    protected function resolveUnitColumns(): void
    {
        if (! $this->unitsReady) {
            return;
        }

        $columns = Schema::getColumnListing('cat_unidades');
        $this->unitKeyColumn = $this->findFirstAvailable($columns, ['clave', 'codigo', 'abreviatura', 'abbr', 'clave_unidad']);
        $this->unitNameColumn = $this->findFirstAvailable($columns, ['nombre', 'descripcion', 'name', 'label', 'detalle']);

        if (! $this->unitKeyColumn) {
            $this->unitKeyColumn = 'id';
        }
        if (! $this->unitNameColumn) {
            $this->unitNameColumn = $this->unitKeyColumn;
        }
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

    protected function extractUnitValue($unit, ?string $column): ?string
    {
        if (! $unit || ! $column) {
            return null;
        }

        $value = data_get($unit, $column);

        if (is_string($value) || is_numeric($value)) {
            return (string) $value;
        }

        return null;
    }

    protected function formatUnitLabel($unit): string
    {
        $key = $this->extractUnitValue($unit, $this->unitKeyColumn);
        $name = $this->extractUnitValue($unit, $this->unitNameColumn);

        $parts = collect([$key ? strtoupper((string) $key) : null, $name])
            ->filter()
            ->unique();

        return $parts->isEmpty()
            ? 'ID ' . $unit->id
            : $parts->implode(' — ');
    }

    protected function unitOrderColumn(): string
    {
        if ($this->unitNameColumn && $this->unitNameColumn !== 'id') {
            return $this->unitNameColumn;
        }

        if ($this->unitKeyColumn && $this->unitKeyColumn !== 'id') {
            return $this->unitKeyColumn;
        }

        return 'id';
    }

    protected function applyUnitSearch($query, string $needle): void
    {
        $columns = collect([$this->unitKeyColumn, $this->unitNameColumn])
            ->filter()
            ->unique()
            ->values();

        if ($columns->isEmpty()) {
            $columns = collect(['id']);
        }

        $query->where(function ($qq) use ($columns, $needle) {
            foreach ($columns as $index => $column) {
                $method = $index === 0 ? 'where' : 'orWhere';
                $qq->{$method}($column, 'ilike', $needle);
            }
        });
    }
}
