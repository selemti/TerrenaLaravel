<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class ItemProveedor extends Model
{
    protected $table = 'selemti.item_vendor';
    public $timestamps = false;
    protected $primaryKey = ['item_id', 'vendor_id', 'presentacion'];
    public $incrementing = false;

    protected $fillable = [
        'item_id', 'vendor_id', 'presentacion', 'unidad_presentacion_id', 
        'factor_a_canonica', 'costo_ultimo', 'moneda', 'lead_time_dias', 
        'codigo_proveedor', 'activo', 'created_at'
    ];

    protected $casts = [
        'factor_a_canonica' => 'decimal:6',
        'costo_ultimo' => 'decimal:2',
        'activo' => 'boolean',
        'created_at' => 'datetime',
    ];

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }
}