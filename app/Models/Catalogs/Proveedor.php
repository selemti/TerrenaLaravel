<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;

class Proveedor extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.cat_proveedores';

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
