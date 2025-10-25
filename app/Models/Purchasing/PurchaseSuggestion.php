<?php

namespace App\Models\Purchasing;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PurchaseSuggestion extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.purchase_suggestions';

    protected $fillable = [
        'folio',
        'sucursal_id',
        'almacen_id',
        'estado',
        'prioridad',
        'origen',
        'total_items',
        'total_estimado',
        'sugerido_en',
        'sugerido_por_user_id',
        'revisado_por_user_id',
        'revisado_en',
        'convertido_a_request_id',
        'convertido_en',
        'dias_analisis',
        'consumo_promedio_calculado',
        'notas',
        'meta',
    ];

    protected $casts = [
        'total_items' => 'integer',
        'total_estimado' => 'decimal:2',
        'sugerido_en' => 'datetime',
        'revisado_en' => 'datetime',
        'convertido_en' => 'datetime',
        'dias_analisis' => 'integer',
        'consumo_promedio_calculado' => 'boolean',
        'meta' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function lines(): HasMany
    {
        return $this->hasMany(PurchaseSuggestionLine::class, 'suggestion_id');
    }

    public function sugeridoPor(): BelongsTo
    {
        return $this->belongsTo(\App\Models\User::class, 'sugerido_por_user_id');
    }

    public function revisadoPor(): BelongsTo
    {
        return $this->belongsTo(\App\Models\User::class, 'revisado_por_user_id');
    }

    public function purchaseRequest(): BelongsTo
    {
        return $this->belongsTo(PurchaseRequest::class, 'convertido_a_request_id');
    }

    public function sucursal(): BelongsTo
    {
        return $this->belongsTo(\App\Models\Catalogs\Sucursal::class, 'sucursal_id');
    }

    public function almacen(): BelongsTo
    {
        return $this->belongsTo(\App\Models\Catalogs\Almacen::class, 'almacen_id');
    }
}
