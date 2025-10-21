<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;

class Almacen extends Model
{
    protected $table = 'cat_almacenes';

    protected $fillable = [
        'clave',
        'nombre',
        'sucursal_id',
        'activo',
    ];

    protected $casts = [
        'activo' => 'boolean',
    ];

    public function sucursal()
    {
        return $this->belongsTo(Sucursal::class, 'sucursal_id');
    }
}

