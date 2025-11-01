<?php

namespace App\Models\Reports;

use Illuminate\Database\Eloquent\Model;

class ReportFavorite extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'report_favorites';

    protected $fillable = [
        'user_id',
        'report_key',
        'meta',
    ];

    protected $casts = [
        'meta' => 'array',
    ];
}
