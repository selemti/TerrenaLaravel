<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

/**
 * Modelo para movimientos de inventario (kardex)
 * Tabla: selemti.mov_inv
 */
class Movimiento extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.mov_inv';

    public $timestamps = false;

    protected $fillable = [
        'item_id',
        'almacen_id',
        'lote_id',
        'tipo',
        'cantidad',
        'uom',
        'ref_tipo',
        'ref_id',
        'sucursal_id',
        'ts',
        'created_at',
        'meta',
    ];

    protected $casts = [
        'cantidad' => 'decimal:4',
        'ts' => 'datetime',
        'created_at' => 'datetime',
        'meta' => 'array',
    ];

    /**
     * Relación con Item
     */
    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    /**
     * Relación con Batch/Lote
     */
    public function lote()
    {
        return $this->belongsTo(Batch::class, 'lote_id', 'id');
    }
}
