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
    protected $table = 'selemti.transfer_cab';
    protected $primaryKey = 'id';

    public const STATUS_SOLICITADA = 'SOLICITADA';
    public const STATUS_APROBADA = 'APROBADA';
    public const STATUS_EN_TRANSITO = 'EN_TRANSITO';
    public const STATUS_RECIBIDA = 'RECIBIDA';
    public const STATUS_POSTEADA = 'POSTEADA';
    public const STATUS_CANCELADA = 'CANCELADA';

    protected $fillable = [
        'origen_almacen_id',
        'destino_almacen_id',
        'estado',
        'creada_por',
        'aprobada_por',
        'despachada_por',
        'recibida_por',
        'posteada_por',
        'numero_guia',
        'fecha_solicitada',
        'fecha_aprobada',
        'fecha_despachada',
        'fecha_recibida',
        'fecha_posteada',
        'observaciones',
        'observaciones_recepcion',
    ];

    protected $casts = [
        'fecha_solicitada' => 'datetime',
        'fecha_aprobada' => 'datetime',
        'fecha_despachada' => 'datetime',
        'fecha_recibida' => 'datetime',
        'fecha_posteada' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function origenAlmacen(): BelongsTo
    {
        return $this->belongsTo(Almacen::class, 'origen_almacen_id');
    }

    public function destinoAlmacen(): BelongsTo
    {
        return $this->belongsTo(Almacen::class, 'destino_almacen_id');
    }

    public function creadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creada_por');
    }

    public function aprobadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'aprobada_por');
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
        return $this->hasMany(TransferLine::class, 'transfer_id');
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
