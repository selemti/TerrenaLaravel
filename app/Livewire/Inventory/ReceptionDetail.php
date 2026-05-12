<?php

namespace App\Livewire\Inventory;

use App\Services\Inventory\ReceptionService;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class ReceptionDetail extends Component
{
    public int $recepcionId;

    public string $estado = 'BORRADOR';

    public array $lineas = [];

    public bool $canValidate = false;

    public bool $canPost = false;

    public ?string $flashMessage = null;

    public ?string $errorMessage = null;

    /**
     * Inicializa el componente con la recepción objetivo.
     *
     * @param  int|string  $id
     */
    public function mount($id): void
    {
        $this->recepcionId = (int) $id;
        $this->refreshData();
    }

    private function refreshData(): void
    {
        $this->flashMessage = null;
        $this->errorMessage = null;

        if (auth()->check()) {
            $perms = method_exists(auth()->user(), 'getAllPermissions')
                ? auth()->user()->getAllPermissions()->pluck('name')->toArray()
                : [];
            $this->canValidate = in_array('inventory.receptions.validate', $perms, true);
            $this->canPost = in_array('inventory.receptions.post', $perms, true);
        }

        try {
            $cabecera = DB::table('selemti.recepcion_cab')->where('id', $this->recepcionId)->first();

            if ($cabecera) {
                $this->estado = $cabecera->estado ?? $this->estado;

                $detalles = DB::table('selemti.recepcion_det as d')
                    ->leftJoin('selemti.items as i', 'i.id', '=', 'd.item_id')
                    ->select([
                        'd.item_id',
                        'i.nombre as item_nombre',
                        'd.qty as qty_recibida',
                        'd.qty_ordenada',
                        'd.doc_url',
                        'd.meta',
                    ])
                    ->where('d.recepcion_id', $this->recepcionId)
                    ->orderBy('d.id')
                    ->limit(200)
                    ->get()
                    ->map(function ($row) {
                        $meta = $row->meta ? json_decode($row->meta, true) : [];
                        $qtyOrdenada = $row->qty_ordenada ?? $meta['qty_ordenada'] ?? $row->qty_recibida;
                        $qtyRecibida = $row->qty_recibida ?? 0;
                        $difference = $qtyOrdenada ? (($qtyRecibida - $qtyOrdenada) / $qtyOrdenada) * 100 : 0;

                        return [
                            'item_id' => $row->item_id,
                            'item_nombre' => $row->item_nombre ?? $row->item_id,
                            'qty_ordenada' => number_format((float) $qtyOrdenada, 6, '.', ''),
                            'qty_recibida' => number_format((float) $qtyRecibida, 6, '.', ''),
                            'diferencia_pct' => $difference,
                            'fuera_tolerancia' => abs($difference) > (config('inventory.reception_tolerance_pct', 5)),
                            'doc_url' => $row->doc_url ?? ($meta['doc_url'] ?? null),
                        ];
                    })
                    ->toArray();

                $this->lineas = $detalles;
            }
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }
    }

    public function actionValidate(ReceptionService $service): void
    {
        try {
            $service->validateReception($this->recepcionId, (int) auth()->id());
            $this->flashMessage = 'Recepción validada.';
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }

        $this->refreshData();
    }

    public function actionPost(ReceptionService $service): void
    {
        try {
            $service->postReception($this->recepcionId, (int) auth()->id());
            $this->flashMessage = 'Recepción posteada a inventario.';
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }

        $this->refreshData();
    }

    public function render()
    {
        return view('livewire.inventory.reception-detail')
            ->layout('layouts.terrena', [
                'active' => 'inventario',
                'title' => 'Detalle de recepción',
                'pageTitle' => 'Detalle de recepción',
            ]);
    }
}
