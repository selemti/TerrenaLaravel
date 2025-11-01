<?php

namespace App\Models\Rec;

use App\Models\Item;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RecetaDetalle extends Model
{
    protected $table = 'selemti.receta_det';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'receta_id',
        'item_id',
        'receta_id_ingrediente',
        'cantidad',
        'unidad_id',
        'orden',
    ];

    protected $casts = [
        'cantidad' => 'decimal:4',
    ];

    public function receta(): BelongsTo
    {
        return $this->belongsTo(Receta::class, 'receta_id', 'id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    public function subreceta(): BelongsTo
    {
        return $this->belongsTo(Receta::class, 'receta_id_ingrediente', 'id');
    }

    public function isSubRecipe(): bool
    {
        return ! is_null($this->receta_id_ingrediente);
    }
}