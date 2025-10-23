<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Log de auditoría para cambios en movimientos de caja chica
 *
 * Registra todos los cambios realizados a los movimientos para trazabilidad completa
 */
class CashFundMovementAuditLog extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.cash_fund_movement_audit_log';

    public $timestamps = false; // Solo usamos created_at

    protected $fillable = [
        'movement_id',
        'action',
        'field_changed',
        'old_value',
        'new_value',
        'observaciones',
        'changed_by_user_id',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];

    /**
     * Movimiento relacionado
     */
    public function movement(): BelongsTo
    {
        return $this->belongsTo(CashFundMovement::class, 'movement_id');
    }

    /**
     * Usuario que hizo el cambio
     */
    public function changedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'changed_by_user_id');
    }

    /**
     * Registrar un cambio en el log
     */
    public static function logChange(
        int $movementId,
        string $action,
        ?string $fieldChanged = null,
        ?string $oldValue = null,
        ?string $newValue = null,
        ?string $observaciones = null,
        ?int $userId = null
    ): self {
        return self::create([
            'movement_id' => $movementId,
            'action' => $action,
            'field_changed' => $fieldChanged,
            'old_value' => $oldValue,
            'new_value' => $newValue,
            'observaciones' => $observaciones,
            'changed_by_user_id' => $userId ?? auth()->id(),
        ]);
    }
}
