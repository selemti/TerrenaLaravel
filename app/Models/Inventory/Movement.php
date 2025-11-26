<?php

namespace App\Models\Inventory;

use Illuminate\Database\Eloquent\Model;

class Movement extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.mov_inv';

    public $timestamps = false;

    protected $fillable = [
        'ts',
        'item_id',
        'lote_id',          // Renombrado de 'lote_codigo'
        'cantidad',         // Renombrado de 'qty'
        'qty_original',
        'uom_original_id',
        'costo_unit',
        'tipo',
        'ref_tipo',
        'ref_id',
        'sucursal_id',
        'usuario_id',       // Renombrado de 'created_by'
        'created_at',
    ];
}
