<?php

namespace App\Livewire\CashFund;

use App\Models\CashFund;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

/**
 * Componente para ver detalle completo de un fondo de caja chica
 * en modo SOLO LECTURA
 *
 * Propósito:
 * - Consultar fondos cerrados
 * - Ver histórico completo
 * - Exportar información (futuro)
 *
 * No permite modificaciones
 */
class Detail extends Component
{
    public string $fondoId;
    public ?CashFund $fondo = null;

    public function mount(string $id)
    {
        $this->fondoId = $id;
        $this->loadFondo();

        if (!$this->fondo) {
            abort(404, 'Fondo no encontrado');
        }
    }

    public function downloadAttachment(int $movementId)
    {
        $movimiento = $this->fondo->movements()->find($movementId);

        if (!$movimiento || !$movimiento->adjunto_path) {
            $this->dispatch('toast',
                type: 'warning',
                body: 'Este movimiento no tiene comprobante'
            );
            return;
        }

        return response()->download(
            storage_path('app/public/' . $movimiento->adjunto_path)
        );
    }

    public function render()
    {
        if (!$this->fondo) {
            abort(404, 'Fondo no encontrado');
        }

        // Información general del fondo
        $sucursalNombre = $this->getSucursalNombre($this->fondo->sucursal_id);

        // Resumen financiero
        $totalEgresos = $this->fondo->total_egresos;
        $totalReintegros = $this->fondo->total_reintegros;
        $saldoFinal = $this->fondo->saldo_disponible;

        // Movimientos detallados
        $movimientos = $this->fondo->movements()
            ->with('createdBy')
            ->orderBy('created_at', 'asc') // Orden cronológico
            ->get()
            ->map(function($mov) {
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

        // Resúmenes financieros
        $resumenPorTipo = [
            'EGRESO' => $movimientos->where('tipo', 'EGRESO')->sum('monto'),
            'REINTEGRO' => $movimientos->where('tipo', 'REINTEGRO')->sum('monto'),
            'DEPOSITO' => $movimientos->where('tipo', 'DEPOSITO')->sum('monto'),
        ];

        $resumenPorMetodo = [
            'EFECTIVO' => $movimientos->where('metodo', 'EFECTIVO')->sum('monto'),
            'TRANSFER' => $movimientos->where('metodo', 'TRANSFER')->sum('monto'),
        ];

        $totalSinComprobante = $movimientos->where('tiene_comprobante', false)->count();
        $totalConComprobante = $movimientos->where('tiene_comprobante', true)->count();

        // Arqueo
        $arqueo = $this->fondo->arqueo;
        $arqueoData = null;
        if ($arqueo) {
            $arqueoData = [
                'monto_esperado' => $arqueo->monto_esperado,
                'monto_contado' => $arqueo->monto_contado,
                'diferencia' => $arqueo->diferencia,
                'estado' => $arqueo->estado,
                'observaciones' => $arqueo->observaciones,
                'creado_por' => $arqueo->createdBy->nombre_completo ?? 'Sistema',
                'fecha' => $arqueo->created_at->format('d/m/Y H:i'),
            ];
        }

        // Timeline de eventos
        $timeline = $this->buildTimeline();

        // Obtener nombres de usuarios directamente desde la BD sin cargar relaciones
        $responsableNombre = 'N/A';
        if ($this->fondo->responsable_user_id) {
            $responsableUser = \App\Models\User::find($this->fondo->responsable_user_id);
            if ($responsableUser) {
                $responsableNombre = $responsableUser->nombre_completo ??
                                    $responsableUser->name ??
                                    'Usuario #' . $this->fondo->responsable_user_id;
            }
        }

        $creadoPorNombre = 'Sistema';
        if ($this->fondo->created_by_user_id) {
            $creadoPorUser = \App\Models\User::find($this->fondo->created_by_user_id);
            if ($creadoPorUser) {
                $creadoPorNombre = $creadoPorUser->nombre_completo ??
                                  $creadoPorUser->name ??
                                  'Usuario #' . $this->fondo->created_by_user_id;
            }
        }

        return view('livewire.cash-fund.detail', [
            'fondo' => [
                'id' => $this->fondo->id,
                'sucursal_nombre' => $sucursalNombre,
                'fecha' => $this->fondo->fecha->format('d/m/Y'),
                'monto_inicial' => $this->fondo->monto_inicial,
                'moneda' => $this->fondo->moneda,
                'descripcion' => $this->fondo->descripcion,
                'estado' => $this->fondo->estado,
                'responsable' => $responsableNombre,
                'creado_por' => $creadoPorNombre,
                'fecha_creacion' => $this->fondo->created_at->format('d/m/Y H:i'),
                'fecha_cierre' => $this->fondo->closed_at ? $this->fondo->closed_at->format('d/m/Y H:i') : null,
            ],
            'totalEgresos' => $totalEgresos,
            'totalReintegros' => $totalReintegros,
            'saldoFinal' => $saldoFinal,
            'movimientos' => $movimientos,
            'resumenPorTipo' => $resumenPorTipo,
            'resumenPorMetodo' => $resumenPorMetodo,
            'totalSinComprobante' => $totalSinComprobante,
            'totalConComprobante' => $totalConComprobante,
            'arqueo' => $arqueoData,
            'timeline' => $timeline,
        ])
        ->layout('layouts.terrena', [
            'active' => 'caja',
            'title' => 'Detalle · Caja Chica',
            'pageTitle' => "Fondo #{$this->fondoId} - Detalle Completo",
        ]);
    }

    /**
     * Construir timeline de eventos del fondo
     */
    protected function buildTimeline(): array
    {
        $events = [];

        // Evento 1: Apertura
        $events[] = [
            'tipo' => 'APERTURA',
            'descripcion' => 'Fondo abierto',
            'fecha' => $this->fondo->created_at->format('d/m/Y H:i'),
            'usuario' => $this->fondo->createdBy->nombre_completo ?? 'Sistema',
            'detalle' => "Monto inicial: $" . number_format($this->fondo->monto_inicial, 2),
            'icono' => 'fa-plus-circle',
            'color' => 'success',
        ];

        // Evento 2: Movimientos
        foreach ($this->fondo->movements as $mov) {
            $events[] = [
                'tipo' => 'MOVIMIENTO',
                'descripcion' => $mov->tipo . ' registrado',
                'fecha' => $mov->created_at->format('d/m/Y H:i'),
                'usuario' => $mov->createdBy->nombre_completo ?? 'Sistema',
                'detalle' => $mov->concepto . " - $" . number_format($mov->monto, 2),
                'icono' => $mov->tipo === 'EGRESO' ? 'fa-arrow-down' : 'fa-arrow-up',
                'color' => $mov->tipo === 'EGRESO' ? 'danger' : 'success',
            ];
        }

        // Evento 3: Arqueo
        if ($this->fondo->arqueo) {
            $events[] = [
                'tipo' => 'ARQUEO',
                'descripcion' => 'Arqueo realizado',
                'fecha' => $this->fondo->arqueo->created_at->format('d/m/Y H:i'),
                'usuario' => $this->fondo->arqueo->createdBy->nombre_completo ?? 'Sistema',
                'detalle' => "Diferencia: $" . number_format(abs($this->fondo->arqueo->diferencia), 2) .
                           ($this->fondo->arqueo->diferencia > 0 ? ' (a favor)' : ($this->fondo->arqueo->diferencia < 0 ? ' (faltante)' : ' (cuadra)')),
                'icono' => 'fa-calculator',
                'color' => abs($this->fondo->arqueo->diferencia) < 0.01 ? 'success' : 'warning',
            ];
        }

        // Evento 4: Cierre
        if ($this->fondo->closed_at) {
            $events[] = [
                'tipo' => 'CIERRE',
                'descripcion' => 'Fondo cerrado definitivamente',
                'fecha' => $this->fondo->closed_at->format('d/m/Y H:i'),
                'usuario' => 'Usuario autorizado',
                'detalle' => 'Estado: CERRADO',
                'icono' => 'fa-lock',
                'color' => 'secondary',
            ];
        }

        return $events;
    }

    protected function loadFondo(): void
    {
        // NO cargar las relaciones responsable y createdBy para evitar serialización
        $this->fondo = CashFund::with(['movements.createdBy', 'arqueo.createdBy'])
            ->find($this->fondoId);
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
