<?php

namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Model;

class OrdenProduccion extends Model
{
    protected $table = 'selemti.op_produccion_cab';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'receta_version_id', 'cantidad_planeada', 'cantidad_real', 
        'fecha_produccion', 'estado', 'lote_resultado', 'usuario_responsable'
    ];

    protected $casts = [
        'cantidad_planeada' => 'decimal:3',
        'cantidad_real' => 'decimal:3',
        'fecha_produccion' => 'date',
    ];

    public function version()
    {
        return $this->belongsTo(RecetaVersion::class, 'receta_version_id');
    }
}