<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

use App\Models\Item;

class InventoryWaste extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'inventory_wastes';

    protected $guarded = [];

    protected $casts = [
        'qty' => 'decimal:6',
        'meta' => 'array',
        'registrado_en' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(ProductionOrder::class, 'production_order_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }
}

