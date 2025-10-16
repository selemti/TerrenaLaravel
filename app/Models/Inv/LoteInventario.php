<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class LoteInventario extends Model
{
    protected $table = 'selemti.inventory_batch';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'item_id', 'lote_proveedor', 'fecha_recepcion', 'fecha_caducidad', 
        'temperatura_recepcion', 'documento_url', 'cantidad_original', 
        'cantidad_actual', 'estado', 'ubicacion_id'
    ];

    protected $casts = [
        'fecha_recepcion' => 'date',
        'fecha_caducidad' => 'date',
        'temperatura_recepcion' => 'decimal:2',
        'cantidad_original' => 'decimal:3',
        'cantidad_actual' => 'decimal:3',
    ];

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }
}