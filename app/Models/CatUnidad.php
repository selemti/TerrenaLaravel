<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CatUnidad extends Model
{
    protected $table = 'cat_unidades';
    protected $fillable = ['clave', 'nombre', 'activo'];
    protected $casts = ['activo' => 'boolean'];
}
