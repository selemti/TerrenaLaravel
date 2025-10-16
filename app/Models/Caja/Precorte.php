<?php

namespace App\Models\Caja;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Precorte extends Model
{
    use HasFactory;

    protected $table = 'precorte';
    protected $schema = 'selemti';
    public $timestamps = true;

    protected $fillable = [
        'id', 'sesion_id', 'estatus', 'efectivo_declarado', 'tarjetas_declaradas', // etc., ajusta campos
        'denominaciones', 'notas', 'enviado_en', 'aprobado_en',
    ];

    protected $casts = [
        'denominaciones' => 'array', // JSON para denoms
        'efectivo_declarado' => 'decimal:2',
    ];

    public function sesion()
    {
        return $this->belongsTo(SesionCajon::class, 'sesion_id', 'id');
    }
}