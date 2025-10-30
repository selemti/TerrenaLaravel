<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Insumo extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';

    protected $table = 'insumo';

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
