<?php

namespace App\Models\Purchasing;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PurchaseRequest extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.purchase_requests';

    protected $fillable = [
        'folio',
        'sucursal_id',
        'created_by',
        'requested_by',
        'requested_at',
        'estado',
        'importe_estimado',
        'notas',
        'meta',
        'fecha_requerida',
        'almacen_destino_id',
        'justificacion',
        'urgente',
        'origen_suggestion_id',
    ];

    protected $casts = [
        'requested_at' => 'datetime',
        'importe_estimado' => 'decimal:6',
        'meta' => 'array',
        'fecha_requerida' => 'date',
        'urgente' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(\App\Models\User::class, 'created_by');
    }

    public function requestedBy(): BelongsTo
    {
        return $this->belongsTo(\App\Models\User::class, 'requested_by');
    }

    public function almacenDestino(): BelongsTo
    {
        return $this->belongsTo(\App\Models\Catalogs\Almacen::class, 'almacen_destino_id');
    }

    public function origenSuggestion(): BelongsTo
    {
        return $this->belongsTo(PurchaseSuggestion::class, 'origen_suggestion_id');
    }

    public function lines(): HasMany
    {
        return $this->hasMany(PurchaseRequestLine::class, 'purchase_request_id');
    }
}
