<?php

namespace App\Livewire\CashFund;

use App\Models\CashFund;
use App\Models\CashFundMovement;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

/**
 * Componente para aprobar y cerrar fondos de caja chica
 *
 * Permisos requeridos:
 * - 'approve-cash-funds' - Para aprobar/rechazar fondos EN_REVISION
 * - 'close-cash-funds' - Para cerrar definitivamente fondos (CERRADO)
 *
 * Funcionalidades:
 * - Listar fondos EN_REVISION
 * - Ver detalle completo del fondo
 * - Aprobar y cerrar definitivamente (EN_REVISION → CERRADO)
 * - Rechazar y regresar a ABIERTO (con comentario)
 * - Historial de acciones
 */
class Approvals extends Component
{
    public ?int $selectedFondoId = null;
    public ?CashFund $selectedFondo = null;
    public bool $showDetailModal = false;
    public bool $showRejectModal = false;
    public bool $showApproveModal = false;
    public bool $loading = false;

    public string $rejectReason = '';

    public function mount()
    {
        // Verificar permisos
        if (!Auth::user()->can('approve-cash-funds')) {
            abort(403, 'No tienes permisos para aprobar fondos de caja chica');
        }
    }

    public function selectFondo(int $fondoId): void
    {
        $this->selectedFondoId = $fondoId;
        $this->selectedFondo = CashFund::with(['movements', 'arqueo'])->find($fondoId);
        $this->showDetailModal = true;
    }

    public function closeDetailModal(): void
    {
        $this->showDetailModal = false;
        $this->selectedFondoId = null;
        $this->selectedFondo = null;
    }

    public function openRejectModal(): void
    {
        $this->rejectReason = '';
        $this->showRejectModal = true;
    }

    public function closeRejectModal(): void
    {
        $this->showRejectModal = false;
        $this->rejectReason = '';
    }

    public function openApproveModal(): void
    {
        // Verificar que todos los movimientos sin comprobante estén justificados
        $movimientosSinComprobante = $this->selectedFondo->movements()
            ->where('tiene_comprobante', false)
            ->where('estatus', 'POR_APROBAR')
            ->count();

        if ($movimientosSinComprobante > 0) {
            $this->dispatch('toast',
                type: 'warning',
                body: "Hay {$movimientosSinComprobante} movimiento(s) sin comprobante que requieren aprobación explícita primero"
            );
            return;
        }

        $this->showApproveModal = true;
    }

    public function closeApproveModal(): void
    {
        $this->showApproveModal = false;
    }

    /**
     * Aprobar movimiento individual sin comprobante
     */
    public function approveMovement(int $movementId): void
    {
        if (!Auth::user()->can('approve-cash-funds')) {
            $this->dispatch('toast', type: 'error', body: 'No tienes permisos para esta acción');
            return;
        }

        $this->loading = true;

        try {
            DB::transaction(function () use ($movementId) {
                $movement = CashFundMovement::findOrFail($movementId);

                // Verificar que el movimiento pertenece al fondo seleccionado
                if ($this->selectedFondo && $movement->cash_fund_id !== $this->selectedFondo->id) {
                    throw new \Exception('El movimiento no pertenece a este fondo');
                }

                $movement->update([
                    'estatus' => 'APROBADO',
                    'approved_by_user_id' => Auth::id(),
                    'approved_at' => now(),
                ]);

                $this->dispatch('toast',
                    type: 'success',
                    body: "Movimiento #{$movementId} aprobado correctamente"
                );

                // Recargar fondo para actualizar vista
                if ($this->selectedFondo) {
                    $this->selectedFondo->refresh();
                }
            });
        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al aprobar movimiento: ' . $e->getMessage()
            );
        } finally {
            $this->loading = false;
        }
    }

    /**
     * Rechazar movimiento individual sin comprobante
     */
    public function rejectMovement(int $movementId, string $reason): void
    {
        if (!Auth::user()->can('approve-cash-funds')) {
            $this->dispatch('toast', type: 'error', body: 'No tienes permisos para esta acción');
            return;
        }

        if (empty($reason)) {
            $this->dispatch('toast', type: 'warning', body: 'Debes proporcionar una razón para el rechazo');
            return;
        }

        $this->loading = true;

        try {
            DB::transaction(function () use ($movementId, $reason) {
                $movement = CashFundMovement::findOrFail($movementId);

                $movement->update([
                    'estatus' => 'RECHAZADO',
                    'approved_by_user_id' => Auth::id(),
                    'approved_at' => now(),
                ]);

                // Aquí podrías guardar el reason en una tabla de comentarios o en el modelo si tuviera ese campo

                $this->dispatch('toast',
                    type: 'success',
                    body: "Movimiento #{$movementId} rechazado"
                );

                // Recargar fondo
                if ($this->selectedFondo) {
                    $this->selectedFondo->refresh();
                }
            });
        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al rechazar movimiento: ' . $e->getMessage()
            );
        } finally {
            $this->loading = false;
        }
    }

    /**
     * Rechazar el fondo completo y regresar a ABIERTO
     */
    public function rejectFund(): void
    {
        $this->validate([
            'rejectReason' => 'required|string|min:10|max:500',
        ], [
            'rejectReason.required' => 'Debes proporcionar una razón para el rechazo',
            'rejectReason.min' => 'La razón debe tener al menos 10 caracteres',
            'rejectReason.max' => 'La razón no puede exceder 500 caracteres',
        ]);

        if (!Auth::user()->can('approve-cash-funds')) {
            $this->dispatch('toast', type: 'error', body: 'No tienes permisos para esta acción');
            return;
        }

        $this->loading = true;

        try {
            DB::transaction(function () {
                // Actualizar estado del fondo
                $this->selectedFondo->update([
                    'estado' => 'ABIERTO',
                ]);

                // Aquí podrías guardar el motivo del rechazo en una tabla de auditoría

                $this->dispatch('toast',
                    type: 'success',
                    body: "Fondo #{$this->selectedFondo->id} rechazado y reabierto. El cajero puede corregir y volver a arquear."
                );

                $this->closeRejectModal();
                $this->closeDetailModal();
            });
        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al rechazar fondo: ' . $e->getMessage()
            );
        } finally {
            $this->loading = false;
        }
    }

    /**
     * Aprobar y cerrar definitivamente el fondo
     */
    public function approveFund(): void
    {
        if (!Auth::user()->can('close-cash-funds')) {
            $this->dispatch('toast',
                type: 'error',
                body: 'No tienes permisos para cerrar fondos definitivamente'
            );
            return;
        }

        // Verificar que todos los movimientos sin comprobante estén aprobados o rechazados
        $movimientosPendientes = $this->selectedFondo->movements()
            ->where('tiene_comprobante', false)
            ->where('estatus', 'POR_APROBAR')
            ->count();

        if ($movimientosPendientes > 0) {
            $this->dispatch('toast',
                type: 'warning',
                body: "Hay {$movimientosPendientes} movimiento(s) sin comprobante pendientes de aprobación"
            );
            return;
        }

        $this->loading = true;

        try {
            DB::transaction(function () {
                // Cambiar estado a CERRADO
                $this->selectedFondo->update([
                    'estado' => 'CERRADO',
                    'closed_at' => now(),
                ]);

                $this->dispatch('toast',
                    type: 'success',
                    body: "Fondo #{$this->selectedFondo->id} cerrado definitivamente"
                );

                $this->closeApproveModal();
                $this->closeDetailModal();
            });
        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al cerrar fondo: ' . $e->getMessage()
            );
        } finally {
            $this->loading = false;
        }
    }

    public function render()
    {
        // Obtener fondos EN_REVISION
        $fondosEnRevision = CashFund::where('estado', 'EN_REVISION')
            ->with(['arqueo', 'responsable'])
            ->orderBy('fecha', 'desc')
            ->get()
            ->map(function ($fondo) {
                $arqueo = $fondo->arqueo;
                $totalMovimientos = $fondo->movements->count();
                $movimientosSinComprobante = $fondo->movements->where('tiene_comprobante', false)->count();
                $movimientosPorAprobar = $fondo->movements->where('estatus', 'POR_APROBAR')->count();

                return [
                    'id' => $fondo->id,
                    'sucursal_id' => $fondo->sucursal_id,
                    'sucursal_nombre' => $this->getSucursalNombre($fondo->sucursal_id),
                    'fecha' => $fondo->fecha->format('d/m/Y'),
                    'monto_inicial' => $fondo->monto_inicial,
                    'moneda' => $fondo->moneda,
                    'responsable' => $fondo->responsable->nombre_completo ?? 'N/A',
                    'total_movimientos' => $totalMovimientos,
                    'sin_comprobante' => $movimientosSinComprobante,
                    'por_aprobar' => $movimientosPorAprobar,
                    'diferencia_arqueo' => $arqueo ? $arqueo->diferencia : 0,
                    'estado_arqueo' => $arqueo ? $arqueo->estado : 'Sin arqueo',
                ];
            });

        // Preparar detalle del fondo seleccionado
        $fondoDetail = null;
        if ($this->selectedFondo) {
            $movimientos = $this->selectedFondo->movements()
                ->with('createdBy')
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($mov) {
                    return [
                        'id' => $mov->id,
                        'tipo' => $mov->tipo,
                        'concepto' => $mov->concepto,
                        'proveedor_nombre' => $mov->proveedor_nombre,
                        'monto' => $mov->monto,
                        'metodo' => $mov->metodo,
                        'fecha_hora' => $mov->created_at->format('Y-m-d H:i'),
                        'tiene_comprobante' => $mov->tiene_comprobante,
                        'adjunto_path' => $mov->adjunto_path,
                        'estatus' => $mov->estatus,
                        'creado_por' => $mov->createdBy->nombre_completo ?? 'Sistema',
                    ];
                });

            $arqueo = $this->selectedFondo->arqueo;

            $fondoDetail = [
                'id' => $this->selectedFondo->id,
                'sucursal_nombre' => $this->getSucursalNombre($this->selectedFondo->sucursal_id),
                'fecha' => $this->selectedFondo->fecha->format('d/m/Y'),
                'monto_inicial' => $this->selectedFondo->monto_inicial,
                'moneda' => $this->selectedFondo->moneda,
                'responsable' => $this->selectedFondo->responsable->nombre_completo ?? 'N/A',
                'total_egresos' => $this->selectedFondo->total_egresos,
                'total_reintegros' => $this->selectedFondo->total_reintegros,
                'saldo_disponible' => $this->selectedFondo->saldo_disponible,
                'movimientos' => $movimientos,
                'arqueo' => $arqueo ? [
                    'monto_esperado' => $arqueo->monto_esperado,
                    'monto_contado' => $arqueo->monto_contado,
                    'diferencia' => $arqueo->diferencia,
                    'estado' => $arqueo->estado,
                    'observaciones' => $arqueo->observaciones,
                    'creado_por' => $arqueo->createdBy->nombre_completo ?? 'Sistema',
                ] : null,
            ];
        }

        return view('livewire.cash-fund.approvals', [
            'fondos' => $fondosEnRevision,
            'fondoDetail' => $fondoDetail,
            'canApprove' => Auth::user()->can('approve-cash-funds'),
            'canClose' => Auth::user()->can('close-cash-funds'),
        ])
        ->layout('layouts.terrena', [
            'active' => 'caja',
            'title' => 'Aprobaciones · Caja Chica',
            'pageTitle' => 'Aprobación de Fondos',
        ]);
    }

    protected function getSucursalNombre(int $sucursalId): string
    {
        try {
            $sucursal = DB::connection('pgsql')
                ->table('selemti.cat_sucursales')
                ->where('id', $sucursalId)
                ->first(['nombre', 'clave']);

            if ($sucursal) {
                return trim(($sucursal->clave ? "{$sucursal->clave} - " : '') . $sucursal->nombre);
            }

            return "Sucursal #{$sucursalId}";
        } catch (\Exception $e) {
            return "Sucursal #{$sucursalId}";
        }
    }
}
