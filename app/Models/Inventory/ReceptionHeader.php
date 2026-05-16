<?php

namespace App\Models\Inventory;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ReceptionHeader extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.recepcion_cab';

    protected $guarded = [];

    protected $casts = [
        'fecha_recepcion' => 'datetime',
        'total_presentaciones' => 'decimal:4',
        'total_canonico' => 'decimal:6',
        'peso_total_kg' => 'decimal:4',
        'meta' => 'array',
        'validada_at' => 'datetime',
        'posteada_at' => 'datetime',
    ];

    public function lines(): HasMany
    {
        return $this->hasMany(ReceptionLine::class, 'recepcion_id');
    }
}
