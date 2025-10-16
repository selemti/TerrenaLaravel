<?php

namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Model;
use App\Models\Inv\Item;

class RecetaDetalle extends Model
{
    protected $table = 'selemti.receta_det';
    protected $primaryKey = 'id';
    public $timestamps = false; // Solo usa created_at

    protected $fillable = [
        'receta_version_id', 'item_id', 'cantidad', 'unidad_medida', 
        'merma_porcentaje', 'instrucciones_especificas', 'orden', 'created_at'
    ];

    protected $casts = [
        'cantidad' => 'decimal:4',
        'merma_porcentaje' => 'decimal:2',
        'created_at' => 'datetime',
    ];

    public function version()
    {
        return $this->belongsTo(RecetaVersion::class, 'receta_version_id');
    }
    
    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }
}