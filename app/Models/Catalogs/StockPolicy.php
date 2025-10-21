<?php

namespace App\Models\Catalogs;

use App\Models\Catalogs\Sucursal;
use App\Models\Inv\Item;
use Illuminate\Database\Eloquent\Model;

class StockPolicy extends Model
{
    protected $table = 'inv_stock_policy';

    protected $fillable = [
        'item_id',
        'sucursal_id',
        'min_qty',
        'max_qty',
        'reorder_qty',
        'activo',
    ];

    protected $casts = [
        'min_qty'     => 'decimal:6',
        'max_qty'     => 'decimal:6',
        'reorder_qty' => 'decimal:6',
        'activo'      => 'boolean',
    ];

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id');
    }

    public function sucursal()
    {
        return $this->belongsTo(Sucursal::class, 'sucursal_id');
    }
}
