<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PosMap extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.pos_map';
    protected $guarded = [];
    protected $primaryKey = 'id';
    public $incrementing = true;
    protected $keyType = 'int';
    public $timestamps = true;

    protected $fillable = [
        'tipo',
        'plu',
        'receta_id',
        'recipe_version_id',
        'valid_from',
        'valid_to',
        'vigente_desde',
        'sucursal_id',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'valid_from' => 'date',
        'valid_to' => 'date',
        'vigente_desde' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function recipe()
    {
        return $this->belongsTo(\App\Models\Rec\Receta::class, 'receta_id', 'id');
    }
}