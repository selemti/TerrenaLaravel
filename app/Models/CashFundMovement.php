<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Modelo para movimientos de caja chica
 *
 * Tipos:
 * - EGRESO: Salida de efectivo
 * - REINTEGRO: Devolución de efectivo no utilizado
 * - DEPOSITO: Aporte adicional al fondo
 *
 * Estatus:
 * - APROBADO: Movimiento aprobado (tiene comprobante o no lo requiere)
 * - POR_APROBAR: Pendiente de aprobación gerencial (sin comprobante)
 * - RECHAZADO: Rechazado por gerencia
 */
class CashFundMovement extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';
    protected $table = 'selemti.cash_fund_movements';

    protected $fillable = [
        'cash_fund_id',
        'tipo',
        'concepto',
        'proveedor_id',
        'monto',
        'metodo',
        'estatus',
        'requiere_comprobante',
        'tiene_comprobante',
        'adjunto_path',
        'created_by_user_id',
        'approved_by_user_id',
        'approved_at',
    ];

    protected $casts = [
        'monto' => 'decimal:2',
        'requiere_comprobante' => 'boolean',
        'tiene_comprobante' => 'boolean',
        'approved_at' => 'datetime',
    ];

    /**
     * Fondo al que pertenece
     */
    public function cashFund(): BelongsTo
    {
        return $this->belongsTo(CashFund::class);
    }

    /**
     * Usuario que creó el movimiento
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    /**
     * Usuario que aprobó el movimiento
     */
    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by_user_id');
    }

    /**
     * Log de auditoría de cambios
     */
    public function auditLogs(): HasMany
    {
        return $this->hasMany(CashFundMovementAuditLog::class, 'movement_id');
    }

    /**
     * Scope: movimientos aprobados
     */
    public function scopeAprobado($query)
    {
        return $query->where('estatus', 'APROBADO');
    }

    /**
     * Scope: movimientos por aprobar
     */
    public function scopePorAprobar($query)
    {
        return $query->where('estatus', 'POR_APROBAR');
    }

    /**
     * Scope: egresos
     */
    public function scopeEgresos($query)
    {
        return $query->where('tipo', 'EGRESO');
    }

    /**
     * Scope: reintegros y depósitos
     */
    public function scopeIngresos($query)
    {
        return $query->whereIn('tipo', ['REINTEGRO', 'DEPOSITO']);
    }

    /**
     * Obtener nombre del proveedor desde PostgreSQL
     */
    public function getProveedorNombreAttribute(): ?string
    {
        if (!$this->proveedor_id) {
            return null;
        }

        try {
            $proveedor = \DB::connection('pgsql')
                ->table('selemti.cat_proveedores')
                ->where('id', $this->proveedor_id)
                ->first();

            return $proveedor ? $proveedor->nombre : null;
        } catch (\Exception $e) {
            return null;
        }
    }
}
