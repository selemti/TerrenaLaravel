<?php

namespace App\Models\Catalogs;

use App\Models\CatUnidad;
use Illuminate\Database\Eloquent\Model;

class UomConversion extends Model
{
    protected $table = 'cat_uom_conversion';

    protected $fillable = [
        'origen_id',
        'destino_id',
        'factor',
    ];

    protected $casts = [
        'factor' => 'decimal:6',
    ];

    public function origen()
    {
        return $this->belongsTo(CatUnidad::class, 'origen_id');
    }

    public function destino()
    {
        return $this->belongsTo(CatUnidad::class, 'destino_id');
    }
}

