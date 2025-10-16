<?php

namespace App\Models\Core;

use Illuminate\Database\Eloquent\Model;

class Auditoria extends Model
{
    protected $table = 'selemti.auditoria';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'quien', 'que', 'payload', 'creado_en'
    ];

    protected $casts = [
        'creado_en' => 'datetime',
        'payload' => 'json',
    ];

    public function usuario()
    {
        return $this->belongsTo(\App\Models\User::class, 'quien');
    }
}