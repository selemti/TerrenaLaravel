<?php

namespace App\Livewire\Recipes;

use App\Models\Inv\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use App\Models\Rec\RecetaVersion;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Livewire\Component;

class RecipeEditor extends Component
{
    public ?string $recipeId = null;
    public ?int $versionId = null;
    public bool $isNew = false;
    public string $idPrefix = 'REC';

    public array $form = [
        'id' => '',
        'nombre_plato' => '',
        'codigo_plato_pos' => '',
        'categoria_plato' => '',
        'porciones_standard' => 1,
        'tiempo_preparacion_min' => null,
        'costo_standard_porcion' => 0,
        'precio_venta_sugerido' => 0,
    ];

    public array $ingredients = [];
    public float $costo_estimado = 0.0;

    protected function rules(): array
    {
        $nombreRule = Rule::unique('receta_cab', 'nombre_plato');

        if ($this->recipeId) {
            $nombreRule = $nombreRule->ignore($this->recipeId, 'id');
        }

        return [
            'form.id' => ['required', 'regex:/^(REC|SUB)\-[0-9]{5}$|^REC\-MOD\-[0-9]{5}$/'],
            'form.nombre_plato' => ['required', 'string', 'max:100', $nombreRule],
            'form.codigo_plato_pos' => ['nullable', 'string', 'max:20'],
            'form.categoria_plato' => ['nullable', 'string', 'max:50'],
            'form.porciones_standard' => ['required', 'numeric', 'min:0.01'],
            'form.tiempo_preparacion_min' => ['nullable', 'integer', 'min:0'],
            'form.costo_standard_porcion' => ['nullable', 'numeric', 'min:0'],
            'form.precio_venta_sugerido' => ['nullable', 'numeric', 'min:0'],
            'ingredients' => ['required', 'array', 'min:1'],
            'ingredients.*.item_id' => [
                'required',
                'string',
                'max:30',
                function ($attribute, $value, $fail) {
                    $value = trim((string) $value);

                    if ($value === '') {
                        return;
                    }

                    $exists = Item::query()->where('id', $value)->exists()
                        || Receta::query()->where('id', $value)->exists();

                    if (! $exists) {
                        $fail('Debe seleccionar un ítem o sub-receta válido.');
                    }
                },
            ],
            'ingredients.*.cantidad' => ['required', 'numeric', 'gt:0'],
            'ingredients.*.unidad_medida' => ['required', 'string', 'max:10'],
            'ingredients.*.merma_porcentaje' => ['nullable', 'numeric', 'min:0', 'max:99.99'],
            'ingredients.*.orden' => ['nullable', 'integer', 'min:1'],
        ];
    }

    protected function messages(): array
    {
        return [
            'form.id.required' => 'El identificador de la receta es obligatorio',
            'form.id.regex' => 'El identificador debe seguir el patrón REC-00001 o SUB-00001',
            'form.nombre_plato.required' => 'El nombre del plato es obligatorio',
            'form.nombre_plato.unique' => 'Ya existe una receta con este nombre',
            'form.porciones_standard.required' => 'Ingresa el rendimiento estándar',
            'form.porciones_standard.min' => 'El rendimiento debe ser mayor a 0',
            'ingredients.required' => 'Debe agregar al menos un ingrediente',
            'ingredients.*.item_id.required' => 'Selecciona un ítem o sub-receta',
            'ingredients.*.item_id.max' => 'El identificador no debe exceder 30 caracteres',
            'ingredients.*.cantidad.required' => 'Ingresa una cantidad',
            'ingredients.*.cantidad.gt' => 'La cantidad debe ser mayor a 0',
            'ingredients.*.unidad_medida.required' => 'Selecciona una unidad de medida',
        ];
    }

    public function updated($propertyName): void
    {
        if (str_starts_with($propertyName, 'form.')) {
            $this->validateOnly($propertyName);
        }

        if (str_starts_with($propertyName, 'ingredients')) {
            $this->validateOnly($propertyName);
            $this->calculateEstimatedCost();
        }
    }

    public function updatedIngredients(): void
    {
        $this->calculateEstimatedCost();
    }

    protected function calculateEstimatedCost(): void
    {
        $itemIds = collect($this->ingredients)
            ->pluck('item_id')
            ->filter()
            ->map(fn ($id) => trim((string) $id))
            ->filter()
            ->unique()
            ->values();

        $costs = $itemIds->isNotEmpty()
            ? Item::query()->whereIn('id', $itemIds)->pluck('costo_promedio', 'id')
            : collect();

        $total = 0;

        foreach ($this->ingredients as $row) {
            $id = trim((string) ($row['item_id'] ?? ''));

            if ($id === '' || ! $costs->has($id)) {
                continue;
            }

            $cantidad = (float) ($row['cantidad'] ?? 0);
            $total += $cantidad * (float) $costs[$id];
        }

        $this->costo_estimado = round($total, 4);
    }

    public function mount(?string $id = null): void
    {
        if ($id) {
            $this->loadExisting($id);
        } else {
            $this->initializeNew();
        }

        if (empty($this->ingredients)) {
            $this->addIngredientRow();
        }

        $this->calculateEstimatedCost();
    }

    protected function loadExisting(string $id): void
    {
        $recipe = Receta::with(['versiones' => function ($query) {
            $query->with('detalles')->orderByDesc('version');
        }])->findOrFail($id);

        $this->recipeId = $recipe->id;
        $this->form = [
            'id' => $recipe->id,
            'nombre_plato' => $recipe->nombre_plato,
            'codigo_plato_pos' => $recipe->codigo_plato_pos,
            'categoria_plato' => $recipe->categoria_plato,
            'porciones_standard' => $recipe->porciones_standard ?? 1,
            'tiempo_preparacion_min' => $recipe->tiempo_preparacion_min,
            'costo_standard_porcion' => $recipe->costo_standard_porcion ?? 0,
            'precio_venta_sugerido' => $recipe->precio_venta_sugerido ?? 0,
        ];
        $this->idPrefix = str_starts_with($recipe->id, 'SUB-') ? 'SUB' : 'REC';

        $version = $recipe->versiones->first();
        if (!$version) {
            $version = RecetaVersion::create([
                'receta_id' => $recipe->id,
                'version' => 1,
                'descripcion_cambios' => 'Versión creada automáticamente',
                'fecha_efectiva' => now()->toDateString(),
                'version_publicada' => false,
                'created_at' => now(),
            ]);
        }

        $this->versionId = $version->id;
        $this->isNew = false;

        $this->ingredients = $version->detalles->map(function (RecetaDetalle $detalle) {
            return [
                'id' => $detalle->id,
                'item_id' => $detalle->item_id,
                'cantidad' => (float) $detalle->cantidad,
                'unidad_medida' => $detalle->unidad_medida,
                'merma_porcentaje' => (float) ($detalle->merma_porcentaje ?? 0),
                'orden' => $detalle->orden ?? 1,
                'instrucciones_especificas' => $detalle->instrucciones_especificas,
            ];
        })->toArray();

        $this->calculateEstimatedCost();
    }

    protected function initializeNew(): void
    {
        $this->isNew = true;
        $this->idPrefix = 'REC';
        $this->recipeId = $this->generateSequentialId($this->idPrefix);
        $this->form['id'] = $this->recipeId;
        $this->form['nombre_plato'] = '';
        $this->form['categoria_plato'] = '';
        $this->form['codigo_plato_pos'] = '';
        $this->form['porciones_standard'] = 1;
        $this->form['tiempo_preparacion_min'] = null;
        $this->form['costo_standard_porcion'] = 0;
        $this->form['precio_venta_sugerido'] = 0;
        $this->versionId = null;
        $this->ingredients = [];
        $this->costo_estimado = 0.0;
    }

    protected function generateSequentialId(string $prefix): string
    {
        $prefix = strtoupper($prefix);
        if (!in_array($prefix, ['REC', 'SUB'], true)) {
            $prefix = 'REC';
        }

        $pattern = '^' . $prefix . '\-[0-9]{5}$';
        $last = DB::table('selemti.receta_cab')
            ->whereRaw('id ~ ?', [$pattern])
            ->orderBy('id', 'desc')
            ->value('id');

        $next = 1;
        if ($last) {
            $next = (int) substr($last, strlen($prefix) + 1) + 1;
        }

        return sprintf('%s-%05d', $prefix, $next);
    }

    public function addIngredientRow(): void
    {
        $this->ingredients[] = [
            'item_id' => '',
            'cantidad' => 0,
            'unidad_medida' => 'PZ',
            'merma_porcentaje' => 0,
            'orden' => count($this->ingredients) + 1,
            'instrucciones_especificas' => null,
        ];

        $this->calculateEstimatedCost();
    }

    public function removeIngredientRow(int $index): void
    {
        if (isset($this->ingredients[$index])) {
            unset($this->ingredients[$index]);
            $this->ingredients = array_values($this->ingredients);
            $this->calculateEstimatedCost();
        }
    }

    public function updatedIdPrefix(): void
    {
        if ($this->isNew) {
            $this->form['id'] = $this->generateSequentialId($this->idPrefix);
            $this->recipeId = $this->form['id'];
        }
    }

    public function regenerateId(): void
    {
        if (!$this->isNew) {
            return;
        }

        $this->form['id'] = $this->generateSequentialId($this->idPrefix);
        $this->recipeId = $this->form['id'];
    }

    public function save(): void
    {
        $this->validate();
        $this->sanitizeIngredients();

        DB::transaction(function () {
            $now = now();
            $this->form['id'] = strtoupper($this->form['id']);

            if ($this->isNew) {
                DB::table('selemti.receta_cab')->insert([
                    'id' => $this->form['id'],
                    'nombre_plato' => $this->form['nombre_plato'],
                    'codigo_plato_pos' => $this->form['codigo_plato_pos'],
                    'categoria_plato' => $this->form['categoria_plato'],
                    'porciones_standard' => $this->form['porciones_standard'],
                    'tiempo_preparacion_min' => $this->form['tiempo_preparacion_min'],
                    'costo_standard_porcion' => $this->form['costo_standard_porcion'],
                    'precio_venta_sugerido' => $this->form['precio_venta_sugerido'],
                    'activo' => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
                $this->isNew = false;
            } else {
                DB::table('selemti.receta_cab')
                    ->where('id', $this->form['id'])
                    ->update([
                        'nombre_plato' => $this->form['nombre_plato'],
                        'codigo_plato_pos' => $this->form['codigo_plato_pos'],
                        'categoria_plato' => $this->form['categoria_plato'],
                        'porciones_standard' => $this->form['porciones_standard'],
                        'tiempo_preparacion_min' => $this->form['tiempo_preparacion_min'],
                        'costo_standard_porcion' => $this->form['costo_standard_porcion'],
                        'precio_venta_sugerido' => $this->form['precio_venta_sugerido'],
                        'updated_at' => $now,
                    ]);
            }

            $version = RecetaVersion::updateOrCreate(
                ['receta_id' => $this->form['id'], 'version' => 1],
                [
                    'descripcion_cambios' => 'Actualización manual',
                    'fecha_efectiva' => $now->toDateString(),
                    'version_publicada' => false,
                    'created_at' => $now,
                ]
            );

            $this->versionId = $version->id;
            $this->recipeId = $this->form['id'];

            RecetaDetalle::where('receta_version_id', $version->id)->delete();

            foreach ($this->ingredients as $index => $row) {
                if (!$row['item_id']) {
                    continue;
                }

                RecetaDetalle::create([
                    'receta_version_id' => $version->id,
                    'item_id' => $row['item_id'],
                    'cantidad' => $row['cantidad'] ?? 0,
                    'unidad_medida' => $row['unidad_medida'] ?? 'PZ',
                    'merma_porcentaje' => $row['merma_porcentaje'] ?? 0,
                    'orden' => $row['orden'] ?? ($index + 1),
                    'instrucciones_especificas' => $row['instrucciones_especificas'] ?? null,
                    'created_at' => $now,
                ]);
            }
        });

        session()->flash('ok', 'Receta guardada correctamente.');
        $this->loadExisting($this->form['id']);
    }

    protected function sanitizeIngredients(): void
    {
        $this->ingredients = collect($this->ingredients)
            ->map(function ($row, $index) {
                $row['orden'] = $row['orden'] ?? ($index + 1);
                return $row;
            })
            ->toArray();
    }

    public function render()
    {
        return view('livewire.recipes.recipe-editor')
            ->layout('layouts.terrena', ['active' => 'recetas']);
    }
}
