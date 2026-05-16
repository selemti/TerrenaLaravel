<?php

namespace App\Models\Inventory;

use App\Models\Catalogs\Almacen;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TransferHeader extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';

    protected $table = 'selemti.traspaso_cab';

    protected $primaryKey = 'id';

    public const STATUS_SOLICITADA = 'SOLICITADA';

    public const STATUS_APROBADA = 'APROBADA';

    public const STATUS_EN_TRANSITO = 'EN_TRANSITO';

    public const STATUS_RECIBIDA = 'RECIBIDA';

    public const STATUS_POSTEADA = 'POSTEADA';

    public const STATUS_CANCELADA = 'CANCELADA';

    protected $fillable = [
        'from_bodega_id',
        'to_bodega_id',
        'estado',
        'usuario_id',
        'validada_por',
        'validada_at',
        'despachada_por',
        'despachada_at',
        'guia',
        'recibida_por',
        'recibida_at',
        'posteada_por',
        'posteada_at',
        'meta',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function origenAlmacen(): BelongsTo
    {
        return $this->belongsTo(Almacen::class, 'from_bodega_id');
    }

    public function destinoAlmacen(): BelongsTo
    {
        return $this->belongsTo(Almacen::class, 'to_bodega_id');
    }

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    public function creadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    public function validadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'validada_por');
    }

    public function aprobadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'validada_por');
    }

    public function despachadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'despachada_por');
    }

    public function recibidaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recibida_por');
    }

    public function posteadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'posteada_por');
    }

    public function lineas(): HasMany
    {
        return $this->hasMany(TransferLine::class, 'traspaso_id');
    }

    public function scopePendientes($query)
    {
        return $query->whereIn('estado', [
            self::STATUS_SOLICITADA,
            self::STATUS_APROBADA,
            self::STATUS_EN_TRANSITO,
        ]);
    }

    public function scopeCompletadas($query)
    {
        return $query->whereIn('estado', [
            self::STATUS_RECIBIDA,
            self::STATUS_POSTEADA,
        ]);
    }

    public function canApprove(): bool
    {
        return $this->estado === self::STATUS_SOLICITADA;
    }

    public function canShip(): bool
    {
        return $this->estado === self::STATUS_APROBADA;
    }

    public function canReceive(): bool
    {
        return $this->estado === self::STATUS_EN_TRANSITO;
    }

    public function canPost(): bool
    {
        return $this->estado === self::STATUS_RECIBIDA;
    }
}
