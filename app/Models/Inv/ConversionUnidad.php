<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class ConversionUnidad extends Model
{
    protected $table = 'conversiones_unidad'; // Asume DB_SCHEMA=selemti
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'unidad_origen_id', 'unidad_destino_id', 'factor_conversion', 
        'formula_directa', 'precision_estimada', 'activo', 'created_at'
    ];
    
    protected $casts = [
        'factor_conversion' => 'decimal:6',
        'precision_estimada' => 'decimal:2',
        'activo' => 'boolean',
        'created_at' => 'datetime',
    ];

    public function unidadOrigen()
    {
        return $this->belongsTo(Unidad::class, 'unidad_origen_id');
    }
    
    public function unidadDestino()
    {
        return $this->belongsTo(Unidad::class, 'unidad_destino_id');
    }
}