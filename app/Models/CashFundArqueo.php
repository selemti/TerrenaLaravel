<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Modelo para arqueo de caja chica
 *
 * Representa el conteo físico del efectivo y el cierre del fondo
 */
class CashFundArqueo extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';
    protected $table = 'selemti.cash_fund_arqueos';

    protected $fillable = [
        'cash_fund_id',
        'monto_esperado',
        'monto_contado',
        'diferencia',
        'observaciones',
        'created_by_user_id',
    ];

    protected $casts = [
        'monto_esperado' => 'decimal:2',
        'monto_contado' => 'decimal:2',
        'diferencia' => 'decimal:2',
    ];

    /**
     * Fondo al que pertenece
     */
    public function cashFund(): BelongsTo
    {
        return $this->belongsTo(CashFund::class);
    }

    /**
     * Usuario que realizó el arqueo
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    /**
     * Determinar el estado del arqueo basado en la diferencia
     */
    public function getEstadoAttribute(): string
    {
        $diff = abs($this->diferencia);

        if ($diff < 0.01) {
            return 'CUADRA';
        } elseif ($this->diferencia > 0) {
            return 'A_FAVOR'; // Sobra dinero
        } else {
            return 'EN_CONTRA'; // Falta dinero
        }
    }

    /**
     * Verificar si el arqueo cuadra (sin diferencias significativas)
     */
    public function cuadra(): bool
    {
        return abs($this->diferencia) < 0.01;
    }
}
