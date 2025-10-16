<?php

namespace App\Models\Core;

use Illuminate\Database\Eloquent\Model;

class JobRecalculo extends Model
{
    protected $table = 'selemti.job_recalc_queue';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'scope_type', 'scope_from', 'scope_to', 'item_id', 'receta_id', 'sucursal_id', 
        'reason', 'created_ts', 'status', 'result'
    ];

    protected $casts = [
        'scope_from' => 'date',
        'scope_to' => 'date',
        'created_ts' => 'datetime',
        'result' => 'json',
    ];
}