<?php

namespace App\Livewire\Production;

use App\Models\Almacen;
use App\Models\ProductionOrder;
use App\Models\Sucursal;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Contracts\View\View;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Livewire\Component;
use Livewire\WithPagination;

class Index extends Component
{
    use WithPagination;

    public string $estado = '';

    public string $sucursalId = '';

    public string $almacenId = '';

    public ?string $fechaDesde = null;

    public ?string $fechaHasta = null;

    public ?int $postingOrderId = null;

    /** @var array<int, array{value:string,label:string}> */
    public array $estadosDisponibles = [];

    /** @var array<int, array{id:string|int,label:string}> */
    public array $sucursales = [];

    /** @var array<int, array{id:string|int,label:string}> */
    public array $almacenes = [];

    protected array $queryString = [
        'estado' => ['except' => ''],
        'sucursalId' => ['except' => ''],
        'almacenId' => ['except' => ''],
    ];

    public function mount(): void
    {
        $this->fechaDesde = now()->subDays(30)->toDateString();
        $this->fechaHasta = now()->toDateString();

        $this->estadosDisponibles = [
            ['value' => ProductionOrder::ESTADO_PLANIFICADA, 'label' => 'Planificada'],
            ['value' => ProductionOrder::ESTADO_APROBADA, 'label' => 'Aprobada'],
            ['value' => ProductionOrder::ESTADO_EN_PROCESO, 'label' => 'En proceso'],
            ['value' => ProductionOrder::ESTADO_COMPLETADA, 'label' => 'Completada'],
            ['value' => ProductionOrder::ESTADO_POSTEADA, 'label' => 'Posteada'],
            ['value' => ProductionOrder::ESTADO_CANCELADA, 'label' => 'Cancelada'],
        ];

        $this->sucursales = Sucursal::query()
            ->orderBy('nombre')
            ->get(['id', 'nombre'])
            ->map(fn ($sucursal) => ['id' => (string) $sucursal->id, 'label' => $sucursal->nombre])
            ->all();

        $this->almacenes = Almacen::query()
            ->orderBy('nombre')
            ->get(['id', 'nombre'])
            ->map(fn ($almacen) => ['id' => (string) $almacen->id, 'label' => $almacen->nombre])
            ->all();
    }

    public function updatingEstado(): void
    {
        $this->resetPage();
    }

    public function updatingSucursalId(): void
    {
        $this->resetPage();
    }

    public function updatingAlmacenId(): void
    {
        $this->resetPage();
    }

    public function updatingFechaDesde(): void
    {
        $this->resetPage();
    }

    public function updatingFechaHasta(): void
    {
        $this->resetPage();
    }

    public function clearFilters(): void
    {
        $this->estado = '';
        $this->sucursalId = '';
        $this->almacenId = '';
        $this->fechaDesde = now()->subDays(30)->toDateString();
        $this->fechaHasta = now()->toDateString();
        $this->resetPage();
    }

    public function postOrder(int $orderId): void
    {
        $this->postingOrderId = $orderId;

        try {
            $response = $this->sendApiRequest('post', "/api/production/orders/{$orderId}/post");

            if ($response && $response->successful()) {
                session()->flash('ok', 'Orden posteada a inventario correctamente.');
            } else {
                $message = $response?->json('message') ?? 'No fue posible postear la orden.';
                session()->flash('error', $message);
            }
        } catch (\Throwable $e) {
            Log::error('Error posteando orden de producción', [
                'order_id' => $orderId,
                'message' => $e->getMessage(),
            ]);

            session()->flash('error', 'Ocurrió un error al postear la orden.');
        }

        $this->postingOrderId = null;
    }

    public function render(): View
    {
        return view('livewire.production.index', [
            'orders' => $this->paginatedOrders(),
        ])->layout('layouts.terrena', [
            'active' => 'produccion',
            'title' => 'Órdenes de producción',
            'pageTitle' => 'Órdenes de Producción',
        ]);
    }

    protected function paginatedOrders(): LengthAwarePaginator
    {
        return ProductionOrder::query()
            ->with(['recipe', 'recipeVersion', 'item', 'sucursal', 'almacen', 'creador'])
            ->when($this->estado !== '', fn ($query) => $query->where('estado', $this->estado))
            ->when($this->sucursalId !== '', fn ($query) => $query->where('sucursal_id', $this->sucursalId))
            ->when($this->almacenId !== '', fn ($query) => $query->where('almacen_id', $this->almacenId))
            ->when($this->fechaDesde, fn ($query) => $query->whereDate('programado_para', '>=', $this->fechaDesde))
            ->when($this->fechaHasta, fn ($query) => $query->whereDate('programado_para', '<=', $this->fechaHasta))
            ->orderByDesc('created_at')
            ->paginate(20);
    }

    protected function sendApiRequest(string $method, string $uri, array $payload = []): ?\Illuminate\Http\Client\Response
    {
        $token = $this->apiToken();

        if (! $token) {
            return null;
        }

        $client = Http::withToken($token)
            ->acceptJson()
            ->baseUrl(config('app.url'));

        $method = strtolower($method);

        if (! method_exists($client, $method)) {
            throw new \InvalidArgumentException("Método HTTP no soportado: {$method}");
        }

        /** @var \Illuminate\Http\Client\PendingRequest $client */
        return $client->{$method}($uri, $payload);
    }

    protected function apiToken(): ?string
    {
        $token = session('api_token');

        if ($token) {
            return $token;
        }

        $user = auth()->user();

        return $user?->remember_token;
    }

    public function estadoLabel(string $estado): string
    {
        return Arr::first($this->estadosDisponibles, fn ($option) => $option['value'] === $estado)['label'] ?? ucfirst(strtolower(str_replace('_', ' ', $estado)));
    }
}

