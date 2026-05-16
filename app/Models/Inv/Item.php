<?php

namespace App\Models\Inv;

use App\Models\Catalogs\StockPolicy;
use App\Models\Catalogs\Unidad;
use App\Models\Inventory\ItemCategory;
use App\Models\ReplenishmentSuggestion;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Item extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';

    protected $table = 'selemti.items';

    protected $guarded = [];

    protected $primaryKey = 'id';

    public $incrementing = false;

    protected $keyType = 'string';

    public $timestamps = true;

    protected $fillable = [
        'id', 'item_code', 'nombre', 'descripcion', 'categoria_id', 'unidad_medida',
        'perishable', 'temperatura_min', 'temperatura_max', 'costo_promedio',
        'activo', 'unidad_medida_id', 'factor_conversion', 'unidad_compra_id',
        'factor_compra', 'tipo', 'unidad_salida_id', 'es_producible',
        'es_consumible_operativo', 'es_empaque_to_go',
    ];

    protected $casts = [
        'perishable' => 'boolean',
        'activo' => 'boolean',
        'costo_promedio' => 'decimal:2',
        'factor_conversion' => 'decimal:6',
        'factor_compra' => 'decimal:6',
        'es_producible' => 'boolean',
        'es_consumible_operativo' => 'boolean',
        'es_empaque_to_go' => 'boolean',
    ];

    // --- UOM Relations ---

    public function uom(): BelongsTo
    {
        return $this->belongsTo(Unidad::class, 'unidad_medida_id');
    }

    public function uomCompra(): BelongsTo
    {
        return $this->belongsTo(Unidad::class, 'unidad_compra_id');
    }

    public function uomSalida(): BelongsTo
    {
        return $this->belongsTo(Unidad::class, 'unidad_salida_id');
    }

    public function unidadCanonico(): BelongsTo
    {
        return $this->belongsTo(Unidad::class, 'unidad_medida_id');
    }

    // --- Domain Relations ---

    public function category(): BelongsTo
    {
        return $this->belongsTo(ItemCategory::class, 'categoria_id', 'id');
    }

    public function stockPolicies(): HasMany
    {
        return $this->hasMany(StockPolicy::class, 'item_id', 'id');
    }

    public function replenishmentSuggestions(): HasMany
    {
        return $this->hasMany(ReplenishmentSuggestion::class, 'item_id', 'id');
    }

    public function proveedores(): HasMany
    {
        return $this->hasMany(ItemProveedor::class, 'item_id', 'id');
    }

    // --- Scopes ---

    public function scopeActivo($query)
    {
        return $query->where('activo', true);
    }
}
