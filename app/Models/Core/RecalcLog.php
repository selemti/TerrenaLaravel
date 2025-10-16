<?php

namespace App\Models\Core;

use Illuminate\Database\Eloquent\Model;

class RecalcLog extends Model
{
    protected $table = 'recalc_log';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'job_id', 'step', 'started_ts', 'ended_ts', 'ok', 'details'
    ];

    protected $casts = [
        'started_ts' => 'datetime',
        'ended_ts' => 'datetime',
        'ok' => 'boolean',
        'details' => 'json',
    ];

    public function job()
    {
        return $this->belongsTo(JobRecalculo::class, 'job_id');
    }
}