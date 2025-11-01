<?php

namespace App\Livewire\Production;

use App\Models\Almacen;
use App\Models\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaVersion;
use App\Models\Sucursal;
use Illuminate\Contracts\View\View;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;
use Livewire\Component;

class Create extends Component
{
    public int $step = 1;

    /** @var array<string, mixed> */
    public array $form = [
        'receta_id' => '',
        'receta_version_id' => '',
        'cantidad_planeada' => 1,
        'sucursal_id' => '',
        'almacen_id' => '',
        'programado_para' => '',
        'notas' => '',
    ];

    /** @var array<int, array{item_id:string,cantidad:float,uom:string}> */
    public array $lineItems = [];

    /** @var array<int, array{id:string,label:string}> */
    public array $recetas = [];

    /** @var array<int, array{id:int,label:string}> */
    public array $versiones = [];

    /** @var array<int, array{id:string,label:string}> */
    public array $items = [];

    /** @var array<int, array{id:int,label:string}> */
    public array $almacenes = [];

    /** @var array<int, array{id:int,label:string}> */
    public array $sucursales = [];

    /** @var array<int, array{id:string,label:string}> */
    public array $uoms = [];

    public bool $saving = false;

    public ?string $apiError = null;

    public function mount(): void
    {
        $this->form['programado_para'] = now()->format('Y-m-d\TH:i');

        $this->recetas = Receta::query()
            ->where('activo', true)
            ->orderBy('nombre_plato')
            ->get(['id', 'nombre_plato'])
            ->map(fn ($receta) => ['id' => (string) $receta->id, 'label' => $receta->nombre_plato])
            ->all();

        $this->items = Item::query()
            ->activo()
            ->orderBy('nombre')
            ->limit(250)
            ->get(['id', 'nombre', 'unidad_compra'])
            ->map(fn ($item) => [
                'id' => (string) $item->id,
                'label' => $item->nombre,
                'uom' => $item->unidad_compra ?? 'PZ',
            ])
            ->all();

        $this->almacenes = Almacen::query()
            ->orderBy('nombre')
            ->get(['id', 'nombre'])
            ->map(fn ($almacen) => ['id' => (int) $almacen->id, 'label' => $almacen->nombre])
            ->all();

        $this->sucursales = Sucursal::query()
            ->orderBy('nombre')
            ->get(['id', 'nombre'])
            ->map(fn ($sucursal) => ['id' => (int) $sucursal->id, 'label' => $sucursal->nombre])
            ->all();

        $this->uoms = DB::connection('pgsql')
            ->table('selemti.cat_unidades')
            ->orderBy('nombre')
            ->get(['id', 'nombre', 'codigo'])
            ->map(fn ($uom) => ['id' => (string) $uom->codigo, 'label' => $uom->nombre . ' (' . $uom->codigo . ')'])
            ->all();

        $this->lineItems = [
            ['item_id' => '', 'cantidad' => 1, 'uom' => $this->uoms[0]['id'] ?? 'PZ'],
        ];
    }

    public function updatedFormRecetaId(string $value): void
    {
        $this->form['receta_version_id'] = '';
        $this->versiones = [];

        if ($value === '') {
            return;
        }

        $this->versiones = RecetaVersion::query()
            ->where('receta_id', $value)
            ->orderByDesc('version')
            ->get(['id', 'version', 'version_publicada'])
            ->map(fn ($version) => [
                'id' => (int) $version->id,
                'label' => sprintf('v%s %s', $version->version, $version->version_publicada ? '(Publicada)' : ''),
                'is_published' => (bool) $version->version_publicada,
            ])
            ->all();

        $published = Arr::first($this->versiones, fn ($version) => $version['is_published']);

        $this->form['receta_version_id'] = $published['id'] ?? ($this->versiones[0]['id'] ?? '');
    }

    public function updated(string $propertyName): void
    {
        $rules = $this->rulesForStep($this->step);

        if (array_key_exists($propertyName, $rules)) {
            $this->validateOnly($propertyName, $rules);
        }
    }

    public function addLine(): void
    {
        $this->lineItems[] = ['item_id' => '', 'cantidad' => 1, 'uom' => $this->uoms[0]['id'] ?? 'PZ'];
    }

    public function removeLine(int $index): void
    {
        unset($this->lineItems[$index]);
        $this->lineItems = array_values($this->lineItems);
    }

    public function goToStep(int $step): void
    {
        if ($step === $this->step) {
            return;
        }

        if ($step > $this->step) {
            $this->validate($this->rulesForStep($this->step));
        }

        $this->step = max(1, min(3, $step));
    }

    public function save(): void
    {
        $this->validate($this->rulesForStep(3));

        $this->saving = true;
        $this->apiError = null;

        try {
            $payload = [
                'receta_id' => $this->form['receta_id'],
                'receta_version_id' => $this->form['receta_version_id'],
                'cantidad_planeada' => (float) $this->form['cantidad_planeada'],
                'sucursal_id' => $this->form['sucursal_id'],
                'almacen_id' => $this->form['almacen_id'],
                'programado_para' => $this->form['programado_para'] ?: null,
                'notas' => $this->form['notas'] ?: null,
                'lineas' => array_map(fn ($line) => [
                    'item_id' => $line['item_id'],
                    'cantidad' => (float) $line['cantidad'],
                    'uom' => $line['uom'],
                ], $this->lineItems),
            ];

            $response = $this->sendApiRequest('post', '/api/production/orders', $payload);

            if ($response && $response->successful()) {
                session()->flash('ok', 'Orden de producción creada correctamente.');
                $this->redirectRoute('production.index', navigate: true);
                return;
            }

            $this->apiError = $response?->json('message') ?? 'No se pudo crear la orden.';
            session()->flash('error', $this->apiError);
        } catch (ValidationException $e) {
            throw $e;
        } catch (\Throwable $e) {
            Log::error('Error creando orden de producción', [
                'message' => $e->getMessage(),
            ]);
            $this->apiError = 'Ocurrió un error inesperado al comunicarse con la API.';
            session()->flash('error', $this->apiError);
        } finally {
            $this->saving = false;
        }
    }

    public function render(): View
    {
        return view('livewire.production.create', [
            'resumenLineas' => $this->lineItemsForReview(),
            'totalCantidad' => $this->totalCantidad(),
        ])->layout('layouts.terrena', [
            'active' => 'produccion',
            'title' => 'Nueva orden de producción',
            'pageTitle' => 'Nueva Orden de Producción',
        ]);
    }

    protected function rulesForStep(int $step): array
    {
        return match ($step) {
            1 => [
                'form.receta_id' => ['required', 'string'],
                'form.receta_version_id' => ['required'],
                'form.cantidad_planeada' => ['required', 'numeric', 'gt:0'],
                'form.sucursal_id' => ['required'],
                'form.almacen_id' => ['required'],
                'form.programado_para' => ['nullable', 'date'],
            ],
            2 => [
                'lineItems' => ['required', 'array', 'min:1'],
                'lineItems.*.item_id' => ['required', 'string'],
                'lineItems.*.cantidad' => ['required', 'numeric', 'gt:0'],
                'lineItems.*.uom' => ['required', 'string'],
            ],
            default => [
                'form.receta_id' => ['required', 'string'],
                'form.receta_version_id' => ['required'],
                'form.cantidad_planeada' => ['required', 'numeric', 'gt:0'],
                'form.sucursal_id' => ['required'],
                'form.almacen_id' => ['required'],
                'lineItems' => ['required', 'array', 'min:1'],
                'lineItems.*.item_id' => ['required', 'string'],
                'lineItems.*.cantidad' => ['required', 'numeric', 'gt:0'],
                'lineItems.*.uom' => ['required', 'string'],
            ],
        };
    }

    protected function lineItemsForReview(): array
    {
        return array_map(function (array $line) {
            $itemLabel = Arr::first($this->items, fn ($item) => $item['id'] === $line['item_id'])['label'] ?? $line['item_id'];
            $uomLabel = Arr::first($this->uoms, fn ($uom) => $uom['id'] === $line['uom'])['label'] ?? $line['uom'];

            return [
                'item' => $itemLabel,
                'cantidad' => (float) $line['cantidad'],
                'uom' => $uomLabel,
            ];
        }, $this->lineItems);
    }

    protected function totalCantidad(): float
    {
        return array_sum(array_map(fn ($line) => (float) $line['cantidad'], $this->lineItems));
    }

    protected function sendApiRequest(string $method, string $uri, array $payload = []): ?\Illuminate\Http\Client\Response
    {
        $token = session('api_token') ?? auth()->user()?->remember_token;

        if (! $token) {
            return null;
        }

        $client = Http::withToken($token)
            ->acceptJson()
            ->baseUrl(config('app.url'));

        if (! method_exists($client, $method)) {
            throw new \InvalidArgumentException("Método HTTP no soportado: {$method}");
        }

        /** @var \Illuminate\Http\Client\PendingRequest $client */
        return $client->{$method}($uri, $payload);
    }
}

