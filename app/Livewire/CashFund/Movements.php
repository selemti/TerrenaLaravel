<?php

namespace App\Livewire\CashFund;

use App\Models\CashFund;
use App\Models\CashFundMovement;
use App\Models\CashFundMovementAuditLog;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Livewire\Component;
use Livewire\WithFileUploads;

/**
 * Componente para gestión de movimientos de caja chica
 * Funcionalidades:
 * - Crear movimientos
 * - Editar movimientos (con auditoría)
 * - Adjuntar/ver/descargar comprobantes
 * - Historial de cambios
 */
class Movements extends Component
{
    use WithFileUploads;

    public string $fondoId;
    public ?CashFund $fondo = null;
    public bool $showMovForm = false;
    public bool $showAttachmentModal = false;
    public bool $showAuditModal = false;
    public bool $loading = false;

    public ?int $editingMovementId = null;
    public ?int $attachmentMovementId = null;
    public ?int $auditMovementId = null;

    public array $movForm = [
        'tipo' => 'EGRESO',
        'concepto' => '',
        'proveedor_id' => null,
        'monto' => '',
        'metodo' => 'EFECTIVO',
        'requiere_comprobante' => false,
    ];

    public $adjunto = null;
    public array $proveedores = [];

    public function mount(string $id): void
    {
        $this->fondoId = $id;
        $this->loadFondo();
        $this->loadProveedores();
    }

    // ==================== CREAR MOVIMIENTO ====================

    public function openMovForm(): void
    {
        if (!$this->fondo || !$this->fondo->canAddMovements()) {
            $this->dispatch('toast',
                type: 'warning',
                body: 'El fondo no está disponible para agregar movimientos'
            );
            return;
        }

        $this->resetMovForm();
        $this->editingMovementId = null;
        $this->showMovForm = true;
    }

    public function closeMovForm(): void
    {
        $this->showMovForm = false;
        $this->resetMovForm();
        $this->editingMovementId = null;
    }

    public function saveMov(): void
    {
        $this->validate($this->movRules(), $this->movMessages());

        $this->fondo->refresh();
        if (!$this->fondo->canAddMovements()) {
            $this->dispatch('toast',
                type: 'error',
                body: 'El fondo ya no está abierto para movimientos'
            );
            return;
        }

        $this->loading = true;

        try {
            DB::transaction(function () {
                if ($this->editingMovementId) {
                    // ACTUALIZAR movimiento existente
                    $this->updateMovement();
                } else {
                    // CREAR nuevo movimiento
                    $this->createMovement();
                }
            });
        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al guardar: ' . $e->getMessage()
            );
        } finally {
            $this->loading = false;
        }
    }

    protected function createMovement(): void
    {
        $tieneComprobante = $this->adjunto !== null;
        $requiereAprobacion = $this->movForm['requiere_comprobante'] && !$tieneComprobante;

        $movimiento = CashFundMovement::create([
            'cash_fund_id' => $this->fondo->id,
            'tipo' => $this->movForm['tipo'],
            'concepto' => $this->movForm['concepto'],
            'proveedor_id' => $this->movForm['proveedor_id'] ?: null,
            'monto' => $this->movForm['monto'],
            'metodo' => $this->movForm['metodo'],
            'estatus' => $requiereAprobacion ? 'POR_APROBAR' : 'APROBADO',
            'requiere_comprobante' => $this->movForm['requiere_comprobante'],
            'tiene_comprobante' => $tieneComprobante,
            'created_by_user_id' => Auth::id(),
        ]);

        if ($this->adjunto) {
            $path = $this->adjunto->store('cash-fund-attachments', 'public');
            $movimiento->update(['adjunto_path' => $path]);
        }

        // LOG de auditoría
        CashFundMovementAuditLog::logChange(
            $movimiento->id,
            'CREATED',
            null,
            null,
            null,
            'Movimiento creado',
            Auth::id()
        );

        $this->dispatch('toast',
            type: 'success',
            body: 'Movimiento registrado correctamente'
        );

        $this->closeMovForm();
        $this->loadFondo();
    }

    protected function updateMovement(): void
    {
        $movimiento = CashFundMovement::findOrFail($this->editingMovementId);

        // Verificar que el movimiento pertenece a este fondo
        if ($movimiento->cash_fund_id !== $this->fondo->id) {
            throw new \Exception('Movimiento no pertenece a este fondo');
        }

        // Registrar cambios en auditoría ANTES de actualizar
        $cambios = [];

        if ($movimiento->concepto !== $this->movForm['concepto']) {
            CashFundMovementAuditLog::logChange(
                $movimiento->id,
                'UPDATED',
                'concepto',
                $movimiento->concepto,
                $this->movForm['concepto'],
                'Concepto modificado'
            );
            $cambios[] = 'concepto';
        }

        if ($movimiento->monto != $this->movForm['monto']) {
            CashFundMovementAuditLog::logChange(
                $movimiento->id,
                'UPDATED',
                'monto',
                (string) $movimiento->monto,
                (string) $this->movForm['monto'],
                'Monto modificado'
            );
            $cambios[] = 'monto';
        }

        if ($movimiento->proveedor_id != $this->movForm['proveedor_id']) {
            CashFundMovementAuditLog::logChange(
                $movimiento->id,
                'UPDATED',
                'proveedor_id',
                (string) $movimiento->proveedor_id,
                (string) $this->movForm['proveedor_id'],
                'Proveedor modificado'
            );
            $cambios[] = 'proveedor';
        }

        if ($movimiento->metodo !== $this->movForm['metodo']) {
            CashFundMovementAuditLog::logChange(
                $movimiento->id,
                'UPDATED',
                'metodo',
                $movimiento->metodo,
                $this->movForm['metodo'],
                'Método de pago modificado'
            );
            $cambios[] = 'método';
        }

        // Actualizar movimiento
        $movimiento->update([
            'concepto' => $this->movForm['concepto'],
            'monto' => $this->movForm['monto'],
            'proveedor_id' => $this->movForm['proveedor_id'] ?: null,
            'metodo' => $this->movForm['metodo'],
        ]);

        // Si hay nuevo adjunto, reemplazar
        if ($this->adjunto) {
            // Eliminar adjunto anterior si existe
            if ($movimiento->adjunto_path) {
                Storage::disk('public')->delete($movimiento->adjunto_path);
            }

            $path = $this->adjunto->store('cash-fund-attachments', 'public');
            $movimiento->update([
                'adjunto_path' => $path,
                'tiene_comprobante' => true,
            ]);

            CashFundMovementAuditLog::logChange(
                $movimiento->id,
                'ATTACHMENT_ADDED',
                'adjunto_path',
                $movimiento->adjunto_path ?? 'ninguno',
                $path,
                'Comprobante actualizado'
            );
        }

        $this->dispatch('toast',
            type: 'success',
            body: 'Movimiento actualizado. Cambios: ' . implode(', ', $cambios)
        );

        $this->closeMovForm();
        $this->loadFondo();
    }

    // ==================== EDITAR MOVIMIENTO ====================

    public function editMovement(int $movementId): void
    {
        if (!$this->fondo->canAddMovements()) {
            $this->dispatch('toast',
                type: 'warning',
                body: 'No se pueden editar movimientos en fondos cerrados'
            );
            return;
        }

        $movimiento = CashFundMovement::findOrFail($movementId);

        $this->editingMovementId = $movementId;
        $this->movForm = [
            'tipo' => $movimiento->tipo,
            'concepto' => $movimiento->concepto,
            'proveedor_id' => $movimiento->proveedor_id,
            'monto' => (string) $movimiento->monto,
            'metodo' => $movimiento->metodo,
            'requiere_comprobante' => $movimiento->requiere_comprobante,
        ];

        $this->showMovForm = true;
    }

    // ==================== GESTIÓN DE COMPROBANTES ====================

    public function openAttachmentModal(int $movementId): void
    {
        $this->attachmentMovementId = $movementId;
        $this->adjunto = null;
        $this->showAttachmentModal = true;
    }

    public function closeAttachmentModal(): void
    {
        $this->showAttachmentModal = false;
        $this->attachmentMovementId = null;
        $this->adjunto = null;
    }

    public function attachFile(): void
    {
        $this->validate([
            'adjunto' => 'required|file|max:5120|mimes:jpg,jpeg,png,pdf',
        ], [
            'adjunto.required' => 'Selecciona un archivo',
            'adjunto.max' => 'El archivo no puede pesar más de 5MB',
            'adjunto.mimes' => 'Solo se permiten archivos JPG, PNG o PDF',
        ]);

        $this->loading = true;

        try {
            DB::transaction(function () {
                $movimiento = CashFundMovement::findOrFail($this->attachmentMovementId);

                // Eliminar adjunto anterior si existe
                $oldPath = $movimiento->adjunto_path;
                if ($oldPath) {
                    Storage::disk('public')->delete($oldPath);
                }

                // Guardar nuevo adjunto
                $path = $this->adjunto->store('cash-fund-attachments', 'public');
                $movimiento->update([
                    'adjunto_path' => $path,
                    'tiene_comprobante' => true,
                ]);

                // LOG de auditoría
                CashFundMovementAuditLog::logChange(
                    $movimiento->id,
                    $oldPath ? 'ATTACHMENT_REPLACED' : 'ATTACHMENT_ADDED',
                    'adjunto_path',
                    $oldPath ?? 'ninguno',
                    $path,
                    'Comprobante adjuntado'
                );

                $this->dispatch('toast',
                    type: 'success',
                    body: 'Comprobante adjuntado correctamente'
                );

                $this->closeAttachmentModal();
                $this->loadFondo();
            });
        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al adjuntar: ' . $e->getMessage()
            );
        } finally {
            $this->loading = false;
        }
    }

    public function downloadAttachment(int $movementId)
    {
        $movimiento = CashFundMovement::findOrFail($movementId);

        if (!$movimiento->adjunto_path) {
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

    // ==================== HISTORIAL DE AUDITORÍA ====================

    public function showAuditHistory(int $movementId): void
    {
        $this->auditMovementId = $movementId;
        $this->showAuditModal = true;
    }

    public function closeAuditModal(): void
    {
        $this->showAuditModal = false;
        $this->auditMovementId = null;
    }

    // ==================== OTROS ====================

    public function irArqueo()
    {
        $this->fondo->refresh();

        if (!$this->fondo->canDoArqueo()) {
            $this->dispatch('toast',
                type: 'warning',
                body: 'El fondo ya no está abierto'
            );
            return;
        }

        return redirect()->route('cashfund.arqueo', ['id' => $this->fondoId]);
    }

    public function render()
    {
        if (!$this->fondo) {
            abort(404, 'Fondo no encontrado');
        }

        $totalEgresos = $this->fondo->total_egresos;
        $totalReintegros = $this->fondo->total_reintegros;
        $saldoDisponible = $this->fondo->saldo_disponible;
        $porcentajeEgresado = $this->fondo->monto_inicial > 0
            ? min(100, ($totalEgresos / $this->fondo->monto_inicial) * 100)
            : 0;

        // Obtener movimientos con información completa
        $movimientos = $this->fondo->movements()
            ->with('createdBy')
            ->orderBy('created_at', 'desc')
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

        // Historial de auditoría si se está viendo
        $auditHistory = [];
        if ($this->auditMovementId) {
            $auditHistory = CashFundMovementAuditLog::where('movement_id', $this->auditMovementId)
                ->with('changedBy')
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function($log) {
                    return [
                        'action' => $log->action,
                        'field_changed' => $log->field_changed,
                        'old_value' => $log->old_value,
                        'new_value' => $log->new_value,
                        'observaciones' => $log->observaciones,
                        'changed_by' => $log->changedBy->nombre_completo ?? 'Sistema',
                        'created_at' => $log->created_at->format('Y-m-d H:i:s'),
                    ];
                })
                ->toArray();
        }

        $sucursalNombre = $this->getSucursalNombre($this->fondo->sucursal_id);

        return view('livewire.cash-fund.movements', [
            'totalEgresos' => $totalEgresos,
            'totalReintegros' => $totalReintegros,
            'saldoDisponible' => $saldoDisponible,
            'porcentajeEgresado' => $porcentajeEgresado,
            'movimientos' => $movimientos,
            'auditHistory' => $auditHistory,
            'fondo' => [
                'id' => $this->fondo->id,
                'sucursal_id' => $this->fondo->sucursal_id,
                'sucursal_nombre' => $sucursalNombre,
                'fecha' => $this->fondo->fecha->format('Y-m-d'),
                'monto_inicial' => $this->fondo->monto_inicial,
                'moneda' => $this->fondo->moneda,
                'estado' => $this->fondo->estado,
                'creado_por' => Auth::id(),
            ],
        ])
        ->layout('layouts.terrena', [
            'active' => 'caja',
            'title' => 'Movimientos · Caja Chica',
            'pageTitle' => "Fondo #{$this->fondoId} - Movimientos",
        ]);
    }

    protected function movRules(): array
    {
        return [
            'movForm.tipo' => 'required|in:EGRESO,REINTEGRO,DEPOSITO',
            'movForm.concepto' => 'required|string|min:5|max:255',
            'movForm.proveedor_id' => 'nullable|integer',
            'movForm.monto' => 'required|numeric|min:0.01|max:999999.99',
            'movForm.metodo' => 'required|in:EFECTIVO,TRANSFER',
            'adjunto' => 'nullable|file|max:5120|mimes:jpg,jpeg,png,pdf',
        ];
    }

    protected function movMessages(): array
    {
        return [
            'movForm.tipo.required' => 'Selecciona el tipo de movimiento',
            'movForm.concepto.required' => 'El concepto es obligatorio',
            'movForm.concepto.min' => 'El concepto debe tener al menos 5 caracteres',
            'movForm.monto.required' => 'El monto es obligatorio',
            'movForm.monto.min' => 'El monto debe ser mayor a cero',
            'adjunto.max' => 'El archivo no puede pesar más de 5MB',
            'adjunto.mimes' => 'Solo se permiten archivos JPG, PNG o PDF',
        ];
    }

    protected function resetMovForm(): void
    {
        $this->movForm = [
            'tipo' => 'EGRESO',
            'concepto' => '',
            'proveedor_id' => null,
            'monto' => '',
            'metodo' => 'EFECTIVO',
            'requiere_comprobante' => false,
        ];
        $this->adjunto = null;
    }

    protected function loadFondo(): void
    {
        $this->fondo = CashFund::with(['movements'])->find($this->fondoId);

        if (!$this->fondo) {
            abort(404, 'Fondo no encontrado');
        }
    }

    protected function loadProveedores(): void
    {
        try {
            $this->proveedores = DB::connection('pgsql')
                ->table('selemti.cat_proveedores')
                ->where('activo', true)
                ->orderBy('nombre')
                ->limit(50)
                ->get(['id', 'nombre'])
                ->map(fn($row) => [
                    'id' => (int) $row->id,
                    'nombre' => $row->nombre,
                ])
                ->toArray();
        } catch (\Exception $e) {
            $this->proveedores = [];
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
