<?php

namespace App\Models;

use App\Models\Inv\Batch;
use App\Models\Inv\Item;
use Illuminate\Database\Eloquent\Model;

class InventoryCountLine extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.inventory_count_lines';

    protected $primaryKey = 'id';

    public $incrementing = true;

    protected $keyType = 'int';

    public $timestamps = true;

    protected $fillable = [
        'inventory_count_id',
        'item_id',
        'inventory_batch_id',
        'qty_teorica',
        'qty_contada',
        'qty_variacion',
        'uom',
        'motivo',
        'meta',
    ];

    protected $casts = [
        'qty_teorica' => 'decimal:6',
        'qty_contada' => 'decimal:6',
        'qty_variacion' => 'decimal:6',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'meta' => 'array',
    ];

    public function inventoryCount()
    {
        return $this->belongsTo(InventoryCount::class, 'inventory_count_id', 'id');
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    public function batch()
    {
        return $this->belongsTo(Batch::class, 'inventory_batch_id');
    }
}
