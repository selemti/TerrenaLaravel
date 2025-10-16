<?php

namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Model;

class Modificador extends Model
{
    protected $table = 'modificadores_pos'; // Asume DB_SCHEMA=selemti
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'codigo_pos', 'nombre', 'tipo', 'precio_extra', 'receta_modificador_id', 'activo'
    ];

    protected $casts = [
        'precio_extra' => 'decimal:2',
        'activo' => 'boolean',
    ];

    public function subReceta()
    {
        return $this->belongsTo(Receta::class, 'receta_modificador_id', 'id');
    }
}