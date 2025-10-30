<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InventoryCountLine extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.inventory_count_lines';
    protected $guarded = [];
    protected $primaryKey = 'id';
    public $incrementing = true;
    protected $keyType = 'int';
    public $timestamps = true;

    protected $fillable = [
        'inventory_count_id',
        'item_id',
        'qty_teorica',
        'qty_contada',
        'uom_id',
        'notas',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'qty_teorica' => 'decimal:4',
        'qty_contada' => 'decimal:4',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function inventoryCount()
    {
        return $this->belongsTo(InventoryCount::class, 'inventory_count_id', 'id');
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }
}