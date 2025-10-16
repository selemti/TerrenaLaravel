<?php

namespace App\Models\Caja;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FormasPago extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';
    protected $table = 'formas_pago';
    protected $schema = 'selemti'; // Especifica schema si no está en conexión
    public $timestamps = false; // Ajusta si usas created_at/updated_at

    protected $fillable = [
        'id', 'codigo', 'payment_type', 'transaction_type', 'payment_sub_type',
        'custom_name', 'custom_ref', 'activo', 'prioridad', 'creado_en',
    ];

    protected $casts = [
        'activo' => 'boolean',
        'prioridad' => 'integer',
        'creado_en' => 'datetime',
    ];
}