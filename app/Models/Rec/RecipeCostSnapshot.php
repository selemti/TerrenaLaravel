<?php

namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Recipe Cost Snapshot Model
 *
 * Representa snapshots históricos de costos de recetas
 * Tabla: selemti.recipe_cost_history
 */
class RecipeCostSnapshot extends Model
{
    use HasFactory;

    protected $table = 'selemti.recipe_cost_history';

    protected $connection = 'pgsql';

    protected $primaryKey = 'id';

    public $timestamps = false;

    protected $fillable = [
        'recipe_id',
        'recipe_version_id',
        'snapshot_at',
        'currency_code',
        'batch_cost',
        'portion_cost',
        'batch_size',
        'yield_portions',
        'notes',
        'created_at',
    ];

    protected $casts = [
        'recipe_id' => 'integer',
        'recipe_version_id' => 'integer',
        'snapshot_at' => 'datetime',
        'batch_cost' => 'decimal:6',
        'portion_cost' => 'decimal:6',
        'batch_size' => 'decimal:6',
        'yield_portions' => 'decimal:6',
        'created_at' => 'datetime',
    ];

    // Relationships

    public function receta()
    {
        return $this->belongsTo(Receta::class, 'recipe_id', 'id');
    }

    public function version()
    {
        return $this->belongsTo(RecetaVersion::class, 'recipe_version_id', 'id');
    }

    // Scopes

    public function scopeForRecipe($query, int $recipeId)
    {
        return $query->where('recipe_id', $recipeId);
    }

    public function scopeLatest($query)
    {
        return $query->orderBy('snapshot_at', 'desc');
    }

    public function scopeBetweenDates($query, string $from, string $to)
    {
        return $query->whereBetween('snapshot_at', [$from, $to]);
    }

    // Accessors

    public function getCostChangePercentageAttribute(): ?float
    {
        $previous = static::forRecipe($this->recipe_id)
            ->where('snapshot_at', '<', $this->snapshot_at)
            ->latest()
            ->first();

        if (! $previous || $previous->portion_cost == 0) {
            return null;
        }

        return (($this->portion_cost - $previous->portion_cost) / $previous->portion_cost) * 100;
    }
}
