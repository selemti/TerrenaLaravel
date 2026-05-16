<?php

namespace App\Models\Inventory;

use App\Models\Inv\Item;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReceptionLine extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.recepcion_det';

    protected $guarded = [];

    protected $casts = [
        'fecha_caducidad' => 'date',
        'qty_presentacion' => 'decimal:4',
        'qty_recibida' => 'decimal:4',
        'pack_size' => 'decimal:4',
        'qty_canonica' => 'decimal:6',
        'cantidad_rechazada' => 'decimal:6',
        'precio_unit' => 'decimal:4',
        'temperatura_recepcion' => 'decimal:2',
        'meta' => 'array',
    ];

    public function reception(): BelongsTo
    {
        return $this->belongsTo(ReceptionHeader::class, 'recepcion_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }
}
