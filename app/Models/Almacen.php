<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Almacen extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'cat_almacenes';
    protected $guarded = [];

    protected $casts = [
        'activo' => 'boolean',
    ];

    /**
     * Sucursal a la que pertenece
     */
    public function sucursal(): BelongsTo
    {
        return $this->belongsTo(Sucursal::class, 'sucursal_id', 'id');
    }

    /**
     * Sugerencias de reposición para este almacén
     */
    public function replenishmentSuggestions(): HasMany
    {
        return $this->hasMany(ReplenishmentSuggestion::class, 'almacen_id', 'id');
    }
}
