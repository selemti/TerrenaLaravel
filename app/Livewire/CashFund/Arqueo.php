<?php

namespace App\Livewire\CashFund;

use App\Models\CashFund;
use App\Models\CashFundArqueo;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

/**
 * Componente para arqueo y cierre de fondo de caja chica
 *
 * Proceso:
 * 1. Contar efectivo físico
 * 2. Comparar con saldo teórico
 * 3. Cambiar estado a EN_REVISION
 * 4. Opcionalmente cerrar definitivamente (CERRADO)
 */
class Arqueo extends Component
{
    public string $fondoId;
    public ?CashFund $fondo = null;
    public bool $loading = false;
    public bool $showConfirmModal = false;

    public array $arqueoForm = [
        'efectivo_contado' => '',
        'observaciones' => '',
    ];

    public function mount(string $id)
    {
        $this->fondoId = $id;
        $this->loadFondo();

        // Validar que el fondo esté abierto
        if (!$this->fondo->canDoArqueo()) {
            $this->dispatch('toast',
                type: 'warning',
                body: 'El fondo ya no está abierto para arqueo'
            );
            return redirect()->route('cashfund.movements', ['id' => $id]);
        }
    }

    public function openConfirm(): void
    {
        $this->validate($this->rules(), $this->messages());
        $this->showConfirmModal = true;
    }

    public function closeConfirm(): void
    {
        $this->showConfirmModal = false;
    }

    public function guardarArqueo()
    {
        $this->validate($this->rules(), $this->messages());

        $this->loading = true;

        try {
            DB::transaction(function () {
                $efectivoContado = (float) $this->arqueoForm['efectivo_contado'];
                $saldoTeorico = $this->fondo->saldo_disponible;
                $diferencia = $efectivoContado - $saldoTeorico;

                // Crear registro de arqueo
                CashFundArqueo::create([
                    'cash_fund_id' => $this->fondo->id,
                    'monto_esperado' => $saldoTeorico,
                    'monto_contado' => $efectivoContado,
                    'diferencia' => $diferencia,
                    'observaciones' => $this->arqueoForm['observaciones'] ?: null,
                    'created_by_user_id' => Auth::id(),
                ]);

                // Cambiar estado del fondo a EN_REVISION
                $this->fondo->update([
                    'estado' => 'EN_REVISION',
                ]);

                $message = abs($diferencia) < 0.01
                    ? 'Arqueo registrado. El fondo cuadra perfectamente. Estado: EN REVISIÓN'
                    : "Arqueo registrado con diferencia de $" . number_format(abs($diferencia), 2) . '. Estado: EN REVISIÓN';

                $this->dispatch('toast',
                    type: 'success',
                    body: $message
                );

                // Redirigir a movements
                return redirect()->route('cashfund.movements', ['id' => $this->fondoId]);
            });
        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al guardar arqueo: ' . $e->getMessage()
            );
        } finally {
            $this->loading = false;
            $this->showConfirmModal = false;
        }
    }

    public function render()
    {
        if (!$this->fondo) {
            abort(404, 'Fondo no encontrado');
        }

        $totalEgresos = $this->fondo->total_egresos;
        $totalReintegros = $this->fondo->total_reintegros;
        $saldoTeorico = $this->fondo->saldo_disponible;
        $efectivoContado = (float) ($this->arqueoForm['efectivo_contado'] ?: 0);
        $diferencia = $efectivoContado - $saldoTeorico;

        // Obtener movimientos
        $movimientos = $this->fondo->movements()
            ->with('createdBy')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function($mov) {
                return [
                    'id' => $mov->id,
                    'tipo' => $mov->tipo,
                    'concepto' => $mov->concepto,
                    'monto' => $mov->monto,
                    'creado_por' => $mov->createdBy->nombre_completo ?? 'Sistema',
                ];
            });

        // Obtener nombre de sucursal
        $sucursalNombre = $this->getSucursalNombre($this->fondo->sucursal_id);

        return view('livewire.cash-fund.arqueo', [
            'totalEgresos' => $totalEgresos,
            'totalReintegros' => $totalReintegros,
            'saldoTeorico' => $saldoTeorico,
            'efectivoContado' => $efectivoContado,
            'diferencia' => $diferencia,
            'movimientos' => $movimientos,
            'fondo' => [
                'id' => $this->fondo->id,
                'sucursal_nombre' => $sucursalNombre,
                'fecha' => $this->fondo->fecha->format('Y-m-d'),
                'monto_inicial' => $this->fondo->monto_inicial,
                'moneda' => $this->fondo->moneda,
                'estado' => $this->fondo->estado,
            ],
        ])
        ->layout('layouts.terrena', [
            'active' => 'caja',
            'title' => 'Arqueo · Caja Chica',
            'pageTitle' => "Fondo #{$this->fondoId} - Arqueo y Cierre",
        ]);
    }

    protected function rules(): array
    {
        return [
            'arqueoForm.efectivo_contado' => 'required|numeric|min:0|max:999999.99',
            'arqueoForm.observaciones' => 'nullable|string|max:500',
        ];
    }

    protected function messages(): array
    {
        return [
            'arqueoForm.efectivo_contado.required' => 'El efectivo contado es obligatorio',
            'arqueoForm.efectivo_contado.min' => 'El efectivo debe ser mayor o igual a cero',
            'arqueoForm.observaciones.max' => 'Las observaciones no pueden exceder 500 caracteres',
        ];
    }

    protected function loadFondo(): void
    {
        $this->fondo = CashFund::with(['movements'])->find($this->fondoId);

        if (!$this->fondo) {
            abort(404, 'Fondo no encontrado');
        }
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
