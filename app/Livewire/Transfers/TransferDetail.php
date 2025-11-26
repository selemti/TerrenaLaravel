<?php

namespace App\Livewire\Transfers;

use App\Services\Inventory\TransferService;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class TransferDetail extends Component
{
    public int $transferId;

    public string $estado = 'SOLICITADA';

    public array $lineas = [];

    public array $cabecera = [];

    public bool $canApprove = false;

    public bool $canPost = false;

    public ?string $flashMessage = null;

    public ?string $errorMessage = null;

    public function mount($id): void
    {
        $this->transferId = (int) $id;
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
            $this->canApprove = in_array('inventory.transfers.approve', $perms, true);
            $this->canPost = in_array('inventory.transfers.post', $perms, true);
        }

        try {
            $cab = DB::connection('pgsql')
                ->table('selemti.transfer_cab as t')
                ->leftJoin('selemti.cat_almacenes as ao', 'ao.id', '=', 't.origen_almacen_id')
                ->leftJoin('selemti.cat_almacenes as ad', 'ad.id', '=', 't.destino_almacen_id')
                ->leftJoin('users as u', 'u.id', '=', 't.creada_por')
                ->select([
                    't.id',
                    't.estado',
                    't.guia',
                    't.created_at',
                    'ao.nombre as almacen_origen',
                    'ad.nombre as almacen_destino',
                    'u.nombre_completo as creado_por',
                ])
                ->where('t.id', $this->transferId)
                ->first();

            if ($cab) {
                $this->estado = $cab->estado ?? $this->estado;
                $this->cabecera = [
                    'almacen_origen' => $cab->almacen_origen,
                    'almacen_destino' => $cab->almacen_destino,
                    'guia' => $cab->guia,
                    'creado_por' => $cab->creado_por,
                    'created_at' => $cab->created_at,
                ];

                $detalles = DB::connection('pgsql')
                    ->table('selemti.transfer_det as d')
                    ->leftJoin('selemti.items as i', 'i.id', '=', 'd.item_id')
                    ->select([
                        'd.item_id',
                        'i.nombre as item_nombre',
                        'd.cantidad',
                        'd.cantidad_despachada',
                        'd.cantidad_recibida',
                    ])
                    ->where('d.transfer_id', $this->transferId)
                    ->orderBy('d.id')
                    ->get()
                    ->map(function ($row) {
                        return [
                            'item_id' => $row->item_id,
                            'item_nombre' => $row->item_nombre ?? $row->item_id,
                            'cantidad' => number_format((float) $row->cantidad, 4, '.', ''),
                            'cantidad_despachada' => number_format((float) ($row->cantidad_despachada ?? 0), 4, '.', ''),
                            'cantidad_recibida' => number_format((float) ($row->cantidad_recibida ?? 0), 4, '.', ''),
                        ];
                    })
                    ->toArray();

                $this->lineas = $detalles;
            }
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }
    }

    public function actionApprove(TransferService $service): void
    {
        try {
            $service->approveTransfer($this->transferId, auth()->id() ?? 1);
            $this->flashMessage = 'Transferencia aprobada.';
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }

        $this->refreshData();
    }

    public function actionPost(TransferService $service): void
    {
        try {
            $service->postTransferToInventory($this->transferId, auth()->id() ?? 1);
            $this->flashMessage = 'Transferencia posteada a inventario.';
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }

        $this->refreshData();
    }

    public function render()
    {
        return view('livewire.transfers.detail')
            ->layout('layouts.terrena', [
                'active' => 'inventario',
                'title' => 'Detalle de transferencia',
                'pageTitle' => 'Detalle de transferencia',
            ]);
    }
}
