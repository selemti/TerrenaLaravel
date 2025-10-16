<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class MovimientoInventario extends Model
{
    protected $table = 'selemti.mov_inv';
    protected $primaryKey = 'id';
    // public $incrementing = true; // BIGSERIAL
    public $timestamps = false; // Solo usa created_at

    protected $fillable = [
        'ts', 'item_id', 'lote_id', 'cantidad', 'qty_original', 
        'uom_original_id', 'costo_unit', 'tipo', 'ref_tipo', 'ref_id', 
        'sucursal_id', 'usuario_id', 'created_at'
    ];

    protected $casts = [
        'ts' => 'datetime',
        'cantidad' => 'decimal:6',
        'qty_original' => 'decimal:6',
        'costo_unit' => 'decimal:6',
        'created_at' => 'datetime',
    ];

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    public function lote()
    {
        return $this->belongsTo(Batch::class, 'lote_id');
    }
}