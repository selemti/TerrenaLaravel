<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Sucursal extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'cat_sucursales';
    protected $guarded = [];

    protected $casts = [
        'activo' => 'boolean',
    ];

    /**
     * Almacenes de esta sucursal
     */
    public function almacenes(): HasMany
    {
        return $this->hasMany(Almacen::class, 'sucursal_id', 'id');
    }

    /**
     * Sugerencias de reposición para esta sucursal
     */
    public function replenishmentSuggestions(): HasMany
    {
        return $this->hasMany(ReplenishmentSuggestion::class, 'sucursal_id', 'id');
    }
}
