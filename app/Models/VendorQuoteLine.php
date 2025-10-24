<?php

namespace App\Models;

use App\Models\Inventory\Item;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VendorQuoteLine extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'purchase_vendor_quote_lines';
    protected $guarded = [];

    protected $casts = [
        'qty_oferta' => 'decimal:3',
        'precio_unitario' => 'decimal:2',
        'pack_size' => 'decimal:3',
        'monto_total' => 'decimal:2',
        'meta' => 'array',
    ];

    // ==================== RELATIONSHIPS ====================

    /**
     * Cotización principal
     */
    public function vendorQuote(): BelongsTo
    {
        return $this->belongsTo(VendorQuote::class, 'quote_id');
    }

    /**
     * Línea de solicitud relacionada
     */
    public function requestLine(): BelongsTo
    {
        return $this->belongsTo(PurchaseRequestLine::class, 'request_line_id');
    }

    /**
     * Item cotizado
     */
    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    // ==================== ACCESSORS ====================

    /**
     * Precio por unidad base (si viene en pack)
     */
    public function getPrecioUnidadBaseAttribute(): float
    {
        if ($this->pack_size > 0) {
            return $this->precio_unitario / $this->pack_size;
        }
        return $this->precio_unitario;
    }

    /**
     * Cantidad en unidad base
     */
    public function getQtyUnidadBaseAttribute(): float
    {
        return $this->qty_oferta * ($this->pack_size ?? 1);
    }

    /**
     * Indicador de mejor precio (comparado con last_price)
     */
    public function getIsBestPriceAttribute(): bool
    {
        $lastPrice = $this->requestLine->last_price ?? 0;
        if ($lastPrice == 0) return null;

        return $this->precio_unitario < $lastPrice;
    }

    /**
     * Diferencia vs precio anterior (%)
     */
    public function getDifVsLastPriceAttribute(): ?float
    {
        $lastPrice = $this->requestLine->last_price ?? 0;
        if ($lastPrice == 0) return null;

        return (($this->precio_unitario - $lastPrice) / $lastPrice) * 100;
    }

    /**
     * Formato de pack (ej: "Caja 12 Unidades")
     */
    public function getPackFormatAttribute(): ?string
    {
        if (!$this->pack_uom || $this->pack_size <= 1) {
            return null;
        }

        return ucfirst($this->pack_uom) . ' ' . number_format($this->pack_size, 0) . ' ' . $this->uom_oferta;
    }

    // ==================== SCOPES ====================

    /**
     * Scope por item
     */
    public function scopePorItem($query, int $itemId)
    {
        return $query->where('item_id', $itemId);
    }

    /**
     * Scope por cotización
     */
    public function scopePorQuote($query, int $quoteId)
    {
        return $query->where('quote_id', $quoteId);
    }

    /**
     * Scope para mejores precios (comparado con request line)
     */
    public function scopeMejoresPrecios($query)
    {
        return $query->whereHas('requestLine', function ($q) {
            $q->whereColumn('purchase_vendor_quote_lines.precio_unitario', '<', 'purchase_request_lines.last_price');
        });
    }
}
