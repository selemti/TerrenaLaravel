<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class PoliticaStock extends Model
{
    protected $table = 'selemti.stock_policy';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'item_id', 'sucursal_id', 'almacen_id', 'min_qty', 
        'max_qty', 'reorder_lote', 'activo'
    ];

    protected $casts = [
        'min_qty' => 'decimal:6',
        'max_qty' => 'decimal:6',
        'reorder_lote' => 'decimal:6',
        'activo' => 'boolean',
    ];

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }
}