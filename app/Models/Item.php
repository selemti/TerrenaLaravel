<?php

namespace App\Models;

use App\Models\Inventory\ItemCategory;
use App\Models\ReplenishmentSuggestion;
use App\Models\StockPolicy;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Item extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';

    protected $table = 'selemti.items';

    protected $primaryKey = 'id';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $guarded = [];

    protected $casts = [
        'perishable' => 'boolean',
        'activo' => 'boolean',
        'costo_promedio' => 'decimal:2',
        'factor_conversion' => 'decimal:6',
        'factor_compra' => 'decimal:6',
        'es_producible' => 'boolean',
    ];

    public function stockPolicies(): HasMany
    {
        return $this->hasMany(StockPolicy::class, 'item_id', 'id');
    }

    public function replenishmentSuggestions(): HasMany
    {
        return $this->hasMany(ReplenishmentSuggestion::class, 'item_id', 'id');
    }

    public function scopeActivo($query)
    {
        return $query->where('activo', true);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(ItemCategory::class, 'category_id', 'id');
    }

    public function legacyCategory(): BelongsTo
    {
        return $this->belongsTo(ItemCategory::class, 'categoria_id', 'codigo');
    }

    protected static function newFactory()
    {
        return \Database\Factories\ItemFactory::new();
    }
}
