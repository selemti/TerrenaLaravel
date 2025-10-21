<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;

class Sucursal extends Model
{
    protected $table = 'cat_sucursales';

    protected $fillable = [
        'clave',
        'nombre',
        'ubicacion',
        'activo',
    ];

    protected $casts = [
        'activo' => 'boolean',
    ];

    public function almacenes()
    {
        return $this->hasMany(Almacen::class, 'sucursal_id');
    }
}

