<?php

namespace App\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InventoryCount extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.inventory_counts';

    protected $primaryKey = 'id';

    public $incrementing = true;

    protected $keyType = 'int';

    public $timestamps = true;

    protected $fillable = [
        'folio',
        'sucursal_id',
        'almacen_id',
        'estado',
        'programado_para',
        'iniciado_en',
        'cerrado_en',
        'creado_por',
        'cerrado_por',
        'notas',
        'total_items',
        'total_variacion',
        'meta',
    ];

    protected $casts = [
        'programado_para' => 'datetime',
        'iniciado_en' => 'datetime',
        'cerrado_en' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'total_items' => 'decimal:4',
        'total_variacion' => 'decimal:6',
        'meta' => 'array',
    ];

    public function lines()
    {
        return $this->hasMany(InventoryCountLine::class, 'inventory_count_id', 'id');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creado_por');
    }

    public function closedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'cerrado_por');
    }
}
