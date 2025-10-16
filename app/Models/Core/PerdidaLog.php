<?php

namespace App\Models\Core; // O App\Models\Inv si lo mueves ahí

use Illuminate\Database\Eloquent\Model;
use App\Models\Inv\Item;
use App\Models\Inv\Batch;
use App\Models\Inv\Unidad;

class PerdidaLog extends Model
{
    protected $table = 'selemti.perdida_log'; 
    protected $primaryKey = 'id';
    public $timestamps = false; // Solo usa created_at

    protected $fillable = [
        'ts', 'item_id', 'lote_id', 'sucursal_id', 'clase', 'motivo', 
        'qty_canonica', 'qty_original', 'uom_original_id', 'evidencia_url', 
        'usuario_id', 'ref_tipo', 'ref_id', 'created_at'
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
        return $this->belongsTo(Unidad::class, 'uom_original_id');
    }
}