<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * DEPRECATED: Este modelo apunta a la tabla legacy selemti.insumo
 * que ya no se utiliza. Todos los insumos ahora se gestionan
 * mediante el modelo Item (selemti.items).
 * 
 * @deprecated v2.0 Use App\Models\Item instead
 * @see \App\Models\Item
 */
class Insumo extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';

    protected $table = 'selemti.insumo';

    protected $primaryKey = 'id';

    public $timestamps = false;

    protected $fillable = [
        'codigo',
        'categoria_codigo',
        'subcategoria_codigo',
        'consecutivo',
        'nombre',
        'um_id',
        'sku',
        'perecible',
        'merma_pct',
        'activo',
        'meta',
    ];

    protected $casts = [
        'perecible' => 'boolean',
        'activo' => 'boolean',
        'meta' => 'array',
    ];
}
