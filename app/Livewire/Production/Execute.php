<?php

namespace App\Livewire\Production;

use App\Models\ProductionOrder;
use Illuminate\Contracts\View\View;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Livewire\Component;

class Execute extends Component
{
    public ProductionOrder $order;

    public int $currentStep = 1;

    /** @var array<int, array<string, mixed>> */
    public array $consumos = [];

    /** @var array<int, array<string, mixed>> */
    public array $producciones = [];

    /** @var array<int, array<string, mixed>> */
    public array $mermas = [];

    public bool $processing = false;

    public ?string $apiError = null;

    public function mount(int $id): void
    {
        $this->order = ProductionOrder::with(['inputs.item', 'outputs.item', 'wastes.item', 'recipe', 'sucursal', 'almacen'])
            ->findOrFail($id);

        $this->consumos = $this->order->inputs
            ->map(fn ($input) => [
                'line_id' => $input->id,
                'item_id' => $input->item_id,
                'item' => $input->item?->nombre ?? $input->item_id,
                'cantidad' => (float) $input->qty,
                'uom' => $input->uom,
                'inventory_batch_id' => $input->inventory_batch_id,
            ])->values()->all();

        $this->producciones = $this->order->outputs
            ->map(fn ($output) => [
                'line_id' => $output->id,
                'item_id' => $output->item_id,
                'item' => $output->item?->nombre ?? $output->item_id,
                'cantidad' => (float) $output->qty,
                'uom' => $output->uom,
                'lote' => $output->lote_producido,
                'caducidad' => optional($output->fecha_caducidad)?->format('Y-m-d'),
            ])->values()->all();

        $this->mermas = $this->order->wastes
            ->map(fn ($waste) => [
                'item_id' => $waste->item_id,
                'item' => $waste->item?->nombre ?? $waste->item_id,
                'cantidad' => (float) $waste->qty,
                'uom' => $waste->uom,
                'motivo' => $waste->motivo,
            ])->values()->all();
    }

    public function render(): View
    {
        return view('livewire.production.execute')->layout('layouts.terrena', [
            'active' => 'produccion',
            'title' => 'Ejecución de orden de producción',
            'pageTitle' => 'Ejecución de Orden',
        ]);
    }

    public function goToStep(int $step): void
    {
        $target = max(1, min(3, $step));

        if ($target > $this->currentStep) {
            $this->validateCurrentStep();
        }

        $this->currentStep = $target;
    }

    public function saveConsumption(): void
    {
        $this->validateConsumption();
        $this->processing = true;
        $this->apiError = null;

        try {
            $payload = [
                'lineas' => array_map(fn ($line) => [
                    'line_id' => $line['line_id'] ?? null,
                    'item_id' => $line['item_id'],
                    'cantidad' => (float) $line['cantidad'],
                    'uom' => $line['uom'],
                    'inventory_batch_id' => $line['inventory_batch_id'] ?? null,
                ], $this->consumos),
            ];

            $response = $this->sendApi('post', "/api/production/orders/{$this->order->id}/consume", $payload);

            if ($response && $response->successful()) {
                session()->flash('ok', 'Consumo registrado correctamente.');
                $this->currentStep = 2;
            } else {
                $this->apiError = $response?->json('message') ?? 'No fue posible registrar el consumo.';
                session()->flash('error', $this->apiError);
            }
        } catch (\Throwable $e) {
            Log::error('Error registrando consumo de producción', [
                'order' => $this->order->id,
                'message' => $e->getMessage(),
            ]);
            $this->apiError = 'Ocurrió un error al comunicar el consumo.';
            session()->flash('error', $this->apiError);
        } finally {
            $this->processing = false;
        }
    }

    public function saveProduction(): void
    {
        $this->validateProduction();
        $this->processing = true;
        $this->apiError = null;

        try {
            $payload = [
                'outputs' => array_map(fn ($line) => [
                    'line_id' => $line['line_id'] ?? null,
                    'item_id' => $line['item_id'],
                    'cantidad' => (float) $line['cantidad'],
                    'uom' => $line['uom'],
                    'lote' => $line['lote'] ?? null,
                    'fecha_caducidad' => $line['caducidad'] ?? null,
                ], $this->producciones),
                'wastes' => array_map(fn ($line) => [
                    'item_id' => $line['item_id'],
                    'cantidad' => (float) $line['cantidad'],
                    'uom' => $line['uom'],
                    'motivo' => $line['motivo'] ?? null,
                ], $this->mermas),
            ];

            $response = $this->sendApi('post', "/api/production/orders/{$this->order->id}/complete", $payload);

            if ($response && $response->successful()) {
                session()->flash('ok', 'Orden marcada como completada.');
                $this->currentStep = 3;
            } else {
                $this->apiError = $response?->json('message') ?? 'No fue posible completar la orden.';
                session()->flash('error', $this->apiError);
            }
        } catch (\Throwable $e) {
            Log::error('Error completando orden de producción', [
                'order' => $this->order->id,
                'message' => $e->getMessage(),
            ]);
            $this->apiError = 'Ocurrió un error al completar la orden.';
            session()->flash('error', $this->apiError);
        } finally {
            $this->processing = false;
        }
    }

    public function postOrder(): void
    {
        $this->processing = true;
        $this->apiError = null;

        try {
            $response = $this->sendApi('post', "/api/production/orders/{$this->order->id}/post");

            if ($response && $response->successful()) {
                session()->flash('ok', 'Orden posteada a inventario.');
                $this->redirectRoute('production.detail', ['id' => $this->order->id], navigate: true);
                return;
            }

            $this->apiError = $response?->json('message') ?? 'No fue posible postear la orden.';
            session()->flash('error', $this->apiError);
        } catch (\Throwable $e) {
            Log::error('Error posteando orden de producción', [
                'order' => $this->order->id,
                'message' => $e->getMessage(),
            ]);
            $this->apiError = 'Error al postear la orden en inventario.';
            session()->flash('error', $this->apiError);
        } finally {
            $this->processing = false;
        }
    }

    protected function validateCurrentStep(): void
    {
        if ($this->currentStep === 1) {
            $this->validateConsumption();
        } elseif ($this->currentStep === 2) {
            $this->validateProduction();
        }
    }

    protected function validateConsumption(): void
    {
        $this->validate([
            'consumos' => ['required', 'array', 'min:1'],
            'consumos.*.item_id' => ['required', 'string'],
            'consumos.*.cantidad' => ['required', 'numeric', 'gt:0'],
            'consumos.*.uom' => ['required', 'string'],
        ]);
    }

    protected function validateProduction(): void
    {
        $this->validate([
            'producciones' => ['required', 'array', 'min:1'],
            'producciones.*.item_id' => ['required', 'string'],
            'producciones.*.cantidad' => ['required', 'numeric', 'gt:0'],
            'producciones.*.uom' => ['required', 'string'],
            'mermas.*.item_id' => ['nullable', 'string'],
            'mermas.*.cantidad' => ['nullable', 'numeric', 'gte:0'],
        ]);
    }

    protected function sendApi(string $method, string $uri, array $payload = [])
    {
        $token = session('api_token') ?? auth()->user()?->remember_token;

        if (! $token) {
            return null;
        }

        $client = Http::withToken($token)->acceptJson()->baseUrl(config('app.url'));

        if (! method_exists($client, $method)) {
            throw new \InvalidArgumentException("Método HTTP no soportado: {$method}");
        }

        /** @var \Illuminate\Http\Client\PendingRequest $client */
        return $client->{$method}($uri, $payload);
    }

    public function addProductionLine(): void
    {
        $this->producciones[] = [
            'line_id' => null,
            'item_id' => '',
            'item' => '',
            'cantidad' => 0,
            'uom' => 'PZ',
            'lote' => null,
            'caducidad' => null,
        ];
    }

    public function removeProductionLine(int $index): void
    {
        unset($this->producciones[$index]);
        $this->producciones = array_values($this->producciones);
    }

    public function addWasteLine(): void
    {
        $this->mermas[] = [
            'item_id' => '',
            'item' => '',
            'cantidad' => 0,
            'uom' => 'PZ',
            'motivo' => null,
        ];
    }

    public function removeWasteLine(int $index): void
    {
        unset($this->mermas[$index]);
        $this->mermas = array_values($this->mermas);
    }

    public function varianceForLine(array $line): ?float
    {
        $planned = (float) ($line['planned'] ?? 0);
        $actual = (float) ($line['cantidad'] ?? 0);

        if ($planned <= 0) {
            return null;
        }

        return (($actual - $planned) / $planned) * 100;
    }
}

