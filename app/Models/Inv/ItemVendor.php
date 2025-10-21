<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class ItemVendor extends Model // O ItemProveedor
{
    protected $table = 'selemti.item_vendor';
    public $timestamps = false;
    // Clave primaria compuesta, debe definirse así o usar un ID simple
    // Para PKs compuestas, solo funciona en algunos casos sin una clave 'id'
    // La definimos como compuesta para mayor claridad:
    protected $primaryKey = ['item_id', 'vendor_id', 'presentacion'];
    public $incrementing = false; 

    protected $fillable = [
        'item_id', 'vendor_id', 'presentacion', 'unidad_presentacion_id', 
        'factor_a_canonica', 'costo_ultimo', 'moneda', 'lead_time_dias', 
        'codigo_proveedor', 'activo', 'preferente', 'created_at'
    ];

    protected $casts = [
        'factor_a_canonica' => 'decimal:6',
        'costo_ultimo' => 'decimal:2',
        'activo' => 'boolean',
        'preferente' => 'boolean',
        'lead_time_dias' => 'integer',
        'created_at' => 'datetime',
    ];

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    // Requiere un modelo Vendor/Proveedor
    // public function vendor()
    // {
    //     return $this->belongsTo(Vendor::class, 'vendor_id');
    // }
}
