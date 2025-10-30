<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StockPolicy extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'stock_policy';
    protected $guarded = [];

    protected $casts = [
        'min_qty' => 'decimal:2',
        'max_qty' => 'decimal:2',
        'reorder_lote' => 'decimal:2',
        'activo' => 'boolean',
    ];

    /**
     * Item relacionado
     */
    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    /**
     * Sucursal
     */
    public function sucursal(): BelongsTo
    {
        return $this->belongsTo(Sucursal::class, 'sucursal_id', 'id');
    }

    /**
     * Almacén
     */
    public function almacen(): BelongsTo
    {
        return $this->belongsTo(Almacen::class, 'almacen_id', 'id');
    }

    /**
     * Scopes
     */
    public function scopeActivo($query)
    {
        return $query->where('activo', true);
    }

    public function scopePorSucursal($query, $sucursalId)
    {
        return $query->where('sucursal_id', $sucursalId);
    }
}
