<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class PerdidaLog extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.perdida_log';

    protected $primaryKey = 'id';

    public $timestamps = false;

    protected $fillable = [
        'ts', 'item_id', 'lote_id', 'sucursal_id', 'clase', 'motivo',
        'qty_canonica', 'qty_original', 'uom_original_id', 'evidencia_url',
        'usuario_id', 'ref_tipo', 'ref_id', 'created_at',
    ];

    protected $casts = [
        'ts' => 'datetime',
        'qty_canonica' => 'decimal:6',
        'qty_original' => 'decimal:6',
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

    public function unidadOriginal()
    {
        return $this->belongsTo(\App\Models\Catalogs\Unidad::class, 'uom_original_id');
    }
}
