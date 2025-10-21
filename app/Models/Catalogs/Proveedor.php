<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;

class Proveedor extends Model
{
    protected $table = 'cat_proveedores';

    protected $fillable = [
        'rfc',
        'nombre',
        'telefono',
        'email',
        'activo',
    ];

    protected $casts = [
        'activo' => 'boolean',
    ];
}

