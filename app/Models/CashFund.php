<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * Modelo para fondos de caja chica
 *
 * Estados:
 * - ABIERTO: Se pueden registrar movimientos
 * - EN_REVISION: Arqueo realizado, pendiente de cierre final
 * - CERRADO: Fondo cerrado, solo lectura
 */
class CashFund extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';
    protected $table = 'selemti.cash_funds';

    protected $fillable = [
        'sucursal_id',
        'fecha',
        'monto_inicial',
        'moneda',
        'estado',
        'responsable_user_id',
        'created_by_user_id',
        'closed_at',
    ];

    protected $casts = [
        'fecha' => 'date',
        'monto_inicial' => 'decimal:2',
        'closed_at' => 'datetime',
    ];

    /**
     * Usuario responsable del fondo
     */
    public function responsable(): BelongsTo
    {
        return $this->belongsTo(User::class, 'responsable_user_id');
    }

    /**
     * Usuario que creó el fondo
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    /**
     * Movimientos del fondo
     */
    public function movements(): HasMany
    {
        return $this->hasMany(CashFundMovement::class);
    }

    /**
     * Arqueo del fondo
     */
    public function arqueo(): HasOne
    {
        return $this->hasOne(CashFundArqueo::class);
    }

    /**
     * Scope: fondos abiertos
     */
    public function scopeAbierto($query)
    {
        return $query->where('estado', 'ABIERTO');
    }

    /**
     * Scope: fondos en revisión
     */
    public function scopeEnRevision($query)
    {
        return $query->where('estado', 'EN_REVISION');
    }

    /**
     * Scope: fondos cerrados
     */
    public function scopeCerrado($query)
    {
        return $query->where('estado', 'CERRADO');
    }

    /**
     * Calcular total de egresos
     */
    public function getTotalEgresosAttribute(): float
    {
        return $this->movements()
            ->where('tipo', 'EGRESO')
            ->sum('monto');
    }

    /**
     * Calcular total de reintegros/depósitos
     */
    public function getTotalReintegrosAttribute(): float
    {
        return $this->movements()
            ->whereIn('tipo', ['REINTEGRO', 'DEPOSITO'])
            ->sum('monto');
    }

    /**
     * Calcular saldo disponible
     */
    public function getSaldoDisponibleAttribute(): float
    {
        return $this->monto_inicial - $this->total_egresos + $this->total_reintegros;
    }

    /**
     * Verificar si se puede agregar movimientos
     */
    public function canAddMovements(): bool
    {
        return $this->estado === 'ABIERTO';
    }

    /**
     * Verificar si se puede realizar arqueo
     */
    public function canDoArqueo(): bool
    {
        return $this->estado === 'ABIERTO';
    }

    /**
     * Verificar si está cerrado
     */
    public function isClosed(): bool
    {
        return $this->estado === 'CERRADO';
    }
}
