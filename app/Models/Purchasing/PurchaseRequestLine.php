<?php

namespace App\Models\Purchasing;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PurchaseRequestLine extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.purchase_request_lines';

    protected $fillable = [
        'request_id',
        'item_id',
        'qty',
        'uom',
        'fecha_requerida',
        'preferred_vendor_id',
        'last_price',
        'estado',
        'meta',
    ];

    protected $casts = [
        'qty'             => 'decimal:6',
        'last_price'      => 'decimal:6',
        'fecha_requerida' => 'date',
        'meta'            => 'array',
        'created_at'      => 'datetime',
        'updated_at'      => 'datetime',
    ];

    public function request(): BelongsTo
    {
        return $this->belongsTo(PurchaseRequest::class, 'request_id');
    }

    public function item(): BelongsTo
    {
        // Ajusta el namespace real de tu modelo Item si es diferente
        return $this->belongsTo(\App\Models\Inv\Item::class, 'item_id');
    }

    public function preferredVendor(): BelongsTo
    {
        // Ajusta el namespace real del modelo Proveedor si es diferente
        return $this->belongsTo(\App\Models\Catalogs\Proveedor::class, 'preferred_vendor_id');
    }
}
