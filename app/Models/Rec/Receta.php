<?php

namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Receta extends Model
{
    use HasFactory;

    protected $table = 'receta_cab';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = true;

    protected $fillable = [
        'id',
        'nombre_plato',
        'codigo_plato_pos',
        'categoria_plato',
        'porciones_standard',
        'instrucciones_preparacion',
        'tiempo_preparacion_min',
        'costo_standard_porcion',
        'precio_venta_sugerido',
        'activo',
    ];

    protected $casts = [
        'porciones_standard' => 'integer',
        'tiempo_preparacion_min' => 'integer',
        'costo_standard_porcion' => 'decimal:4',
        'precio_venta_sugerido' => 'decimal:2',
        'activo' => 'boolean',
    ];

    public function versiones(): HasMany
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

    public function detalles(): HasMany
    {
        return $this->hasMany(RecetaDetalle::class, 'receta_id', 'id');
    }

    protected static function newFactory()
    {
        return \Database\Factories\Rec\RecetaFactory::new();
    }
}
