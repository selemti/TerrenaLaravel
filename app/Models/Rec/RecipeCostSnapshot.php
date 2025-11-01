<?php

namespace App\Models\Rec;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RecipeCostSnapshot extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.recipe_cost_snapshots';

    public const UPDATED_AT = null;

    public const REASON_MANUAL = 'MANUAL';
    public const REASON_AUTO_THRESHOLD = 'AUTO_THRESHOLD';
    public const REASON_INGREDIENT_CHANGE = 'INGREDIENT_CHANGE';
    public const REASON_SCHEDULED = 'SCHEDULED';

    protected $fillable = [
        'recipe_id',
        'snapshot_date',
        'cost_total',
        'cost_per_portion',
        'portions',
        'cost_breakdown',
        'reason',
        'created_by_user_id',
    ];

    protected $casts = [
        'snapshot_date' => 'datetime',
        'cost_total' => 'decimal:4',
        'cost_per_portion' => 'decimal:4',
        'portions' => 'decimal:3',
        'cost_breakdown' => 'array',
        'created_at' => 'datetime',
    ];

    public function recipe(): BelongsTo
    {
        return $this->belongsTo(Receta::class, 'recipe_id', 'id');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function scopeForRecipe(Builder $query, string $recipeId): Builder
    {
        return $query->where('recipe_id', $recipeId);
    }

    public function scopeBeforeDate(Builder $query, Carbon $date): Builder
    {
        return $query->where('snapshot_date', '<=', $date);
    }

    public function scopeLatestPerRecipe(Builder $query): Builder
    {
        return $query->whereIn('id', function ($subquery) {
            $subquery->selectRaw('MAX(id) as max_id')
                ->from('selemti.recipe_cost_snapshots')
                ->groupBy('recipe_id');
        });
    }

    public static function getForRecipeAtDate(string $recipeId, Carbon $date): ?self
    {
        return static::forRecipe($recipeId)
            ->beforeDate($date)
            ->orderByDesc('snapshot_date')
            ->orderByDesc('id')
            ->first();
    }

    public static function getLatestForRecipe(string $recipeId): ?self
    {
        return static::forRecipe($recipeId)
            ->orderByDesc('snapshot_date')
            ->orderByDesc('id')
            ->first();
    }
}
