<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Item extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'items';
    protected $guarded = [];
    public $incrementing = false;
    protected $keyType = 'string';

    protected $casts = [
        'perishable' => 'boolean',
        'activo' => 'boolean',
        'costo_promedio' => 'decimal:2',
        'factor_conversion' => 'decimal:6',
        'factor_compra' => 'decimal:6',
    ];

    /**
     * Políticas de stock para este item
     */
    public function stockPolicies(): HasMany
    {
        return $this->hasMany(StockPolicy::class, 'item_id', 'id');
    }

    /**
     * Sugerencias de reposición
     */
    public function replenishmentSuggestions(): HasMany
    {
        return $this->hasMany(ReplenishmentSuggestion::class, 'item_id', 'id');
    }

    /**
     * Scope para items activos
     */
    public function scopeActivo($query)
    {
        return $query->where('activo', true);
    }
}
