<?php

namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;

class Receta extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';

    protected $table = 'selemti.receta_cab';

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
        'costo_standard_porcion' => 'decimal:2',
        'precio_venta_sugerido' => 'decimal:2',
        'activo' => 'boolean',
    ];

    public function versiones(): HasMany
    {
        return $this->hasMany(RecetaVersion::class, 'receta_id', 'id')
            ->orderByDesc('version');
    }

    public function detalles(): HasManyThrough
    {
        return $this->hasManyThrough(
            RecetaDetalle::class,
            RecetaVersion::class,
            'receta_id',
            'receta_version_id',
            'id',
            'id'
        );
    }

    public function scopeActivas($query)
    {
        return $query->where('activo', true);
    }

    protected static function newFactory()
    {
        return \Database\Factories\Rec\RecetaFactory::new();
    }
}
