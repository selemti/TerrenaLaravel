<?php

namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Model;

class Receta extends Model
{
    protected $table = 'receta_cab'; // Asume DB_SCHEMA=selemti
    protected $primaryKey = 'id';
    public $incrementing = false; // El ID es VARCHAR(20)
    protected $keyType = 'string';
    public $timestamps = true; // Tiene created_at y updated_at

    protected $fillable = [
        'id', 'nombre_plato', 'codigo_plato_pos', 'categoria_plato', 
        'porciones_standard', 'instrucciones_preparacion', 'tiempo_preparacion_min', 
        'costo_standard_porcion', 'precio_venta_sugerido', 'activo',
    ];

    protected $casts = [
        'porciones_standard' => 'integer',
        'tiempo_preparacion_min' => 'integer',
        'costo_standard_porcion' => 'decimal:4', // Costos suelen ser precisos
        'precio_venta_sugerido' => 'decimal:2',
        'activo' => 'boolean',
    ];

    public function versiones()
    {
        return $this->hasMany(RecetaVersion::class, 'receta_id', 'id');
    }

    public function publishedVersion()
    {
        return $this->hasOne(RecetaVersion::class, 'receta_id', 'id')
            ->where('version_publicada', true)
            ->orderByDesc('fecha_efectiva')
            ->limit(1);
    }

    public function latestVersion()
    {
        return $this->hasOne(RecetaVersion::class, 'receta_id', 'id')
            ->orderByDesc('version')
            ->limit(1);
    }
}
