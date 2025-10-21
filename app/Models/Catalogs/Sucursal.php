<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;

class Sucursal extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.cat_sucursales';

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

