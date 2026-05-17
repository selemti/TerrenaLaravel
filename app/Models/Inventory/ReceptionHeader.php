<?php

namespace App\Models\Inventory;

use App\Exceptions\Inventory\InvalidInventoryStateException;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ReceptionHeader extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.recepcion_cab';

    protected $guarded = [];

    protected $casts = [
        'fecha_recepcion' => 'datetime',
        'total_presentaciones' => 'decimal:4',
        'total_canonico' => 'decimal:6',
        'peso_total_kg' => 'decimal:4',
        'meta' => 'array',
        'validada_at' => 'datetime',
        'posteada_at' => 'datetime',
    ];

    // State machine constants — BORRADOR → VALIDADA → POSTEADA
    public const STATUS_BORRADOR = 'BORRADOR';

    public const STATUS_VALIDADA = 'VALIDADA';

    public const STATUS_POSTEADA = 'POSTEADA';

    public const STATUS_CANCELADA = 'CANCELADA';

    /** Valid forward transitions: from → [allowed targets] */
    private const TRANSITIONS = [
        self::STATUS_BORRADOR => [self::STATUS_VALIDADA, self::STATUS_CANCELADA],
        self::STATUS_VALIDADA => [self::STATUS_POSTEADA, self::STATUS_CANCELADA],
        self::STATUS_POSTEADA => [],
        self::STATUS_CANCELADA => [],
    ];

    public function canValidate(): bool
    {
        return $this->estado === self::STATUS_BORRADOR;
    }

    public function canPost(): bool
    {
        return in_array($this->estado, [self::STATUS_BORRADOR, self::STATUS_VALIDADA], true);
    }

    public function canCancel(): bool
    {
        return in_array($this->estado, [self::STATUS_BORRADOR, self::STATUS_VALIDADA], true);
    }

    public function isPosted(): bool
    {
        return $this->estado === self::STATUS_POSTEADA;
    }

    /**
     * Asserts that a transition to $targetStatus is allowed, throwing if not.
     *
     * @throws InvalidInventoryStateException
     */
    public function assertCanTransitionTo(string $targetStatus): void
    {
        $allowed = self::TRANSITIONS[$this->estado] ?? [];

        if (! in_array($targetStatus, $allowed, true)) {
            throw InvalidInventoryStateException::transition(
                $this->id,
                $this->estado,
                $targetStatus,
            );
        }
    }

    public function lines(): HasMany
    {
        return $this->hasMany(ReceptionLine::class, 'recepcion_id');
    }
}
