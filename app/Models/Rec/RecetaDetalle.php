<?php

namespace App\Models\Rec;

use App\Models\Item;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RecetaDetalle extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.receta_det';

    protected $primaryKey = 'id';

    public $timestamps = false;

    protected $fillable = [
        'receta_version_id',
        'item_id',
        'cantidad',
        'unidad_medida',
        'merma_porcentaje',
        'instrucciones_especificas',
        'orden',
        'created_at',
    ];

    protected $casts = [
        'cantidad' => 'decimal:4',
        'merma_porcentaje' => 'decimal:2',
    ];

    public function version(): BelongsTo
    {
        return $this->belongsTo(RecetaVersion::class, 'receta_version_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }
}
