<?php

namespace App\Models\Inventory;

use Illuminate\Database\Eloquent\Model;

class Movement extends Model
{
    protected $table = 'selemti.mov_inv';
    public $timestamps = false;

    protected $fillable = [
        'ts','item_id','sucursal_id','sucursal_dest','lote_codigo','caducidad',
        'qty','udm','costo_unit','tipo','ref_tipo','ref_id','notas','created_by'
    ];
}
