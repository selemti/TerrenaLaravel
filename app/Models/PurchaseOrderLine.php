<?php

namespace App\Models;

use App\Models\Inventory\Item;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PurchaseOrderLine extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'purchase_order_lines';
    protected $guarded = [];

    protected $casts = [
        'qty' => 'decimal:3',
        'precio_unitario' => 'decimal:2',
        'descuento' => 'decimal:2',
        'impuestos' => 'decimal:2',
        'total' => 'decimal:2',
        'meta' => 'array',
    ];

    // ==================== RELATIONSHIPS ====================

    /**
     * Orden de compra principal
     */
    public function purchaseOrder(): BelongsTo
    {
        return $this->belongsTo(PurchaseOrder::class, 'order_id');
    }

    /**
     * Línea de solicitud relacionada (si aplica)
     */
    public function requestLine(): BelongsTo
    {
        return $this->belongsTo(PurchaseRequestLine::class, 'request_line_id');
    }

    /**
     * Item ordenado
     */
    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    // ==================== ACCESSORS ====================

    /**
     * Subtotal de la línea (sin descuento ni impuestos)
     */
    public function getSubtotalAttribute(): float
    {
        return $this->qty * $this->precio_unitario;
    }

    /**
     * Porcentaje de descuento
     */
    public function getPorcentajeDescuentoAttribute(): float
    {
        $subtotal = $this->subtotal;
        if ($subtotal == 0) return 0;
        return ($this->descuento / $subtotal) * 100;
    }

    /**
     * Porcentaje de impuestos
     */
    public function getPorcentajeImpuestosAttribute(): float
    {
        $subtotal = $this->subtotal;
        if ($subtotal == 0) return 0;
        return ($this->impuestos / $subtotal) * 100;
    }

    /**
     * Total calculado (verificación)
     */
    public function getTotalCalculadoAttribute(): float
    {
        return $this->subtotal - $this->descuento + $this->impuestos;
    }

    /**
     * Indica si el total almacenado coincide con el calculado
     */
    public function getTotalCoincideAttribute(): bool
    {
        return abs($this->total - $this->total_calculado) < 0.01;
    }

    /**
     * Monto ahorrado (descuento aplicado)
     */
    public function getMontoAhorradoAttribute(): float
    {
        return $this->descuento;
    }

    // ==================== SCOPES ====================

    /**
     * Scope por orden
     */
    public function scopePorOrder($query, int $orderId)
    {
        return $query->where('order_id', $orderId);
    }

    /**
     * Scope por item
     */
    public function scopePorItem($query, int $itemId)
    {
        return $query->where('item_id', $itemId);
    }

    /**
     * Scope para líneas con descuento
     */
    public function scopeConDescuento($query)
    {
        return $query->where('descuento', '>', 0);
    }

    /**
     * Scope para líneas de mayor valor
     */
    public function scopeMayorValor($query, int $limit = 10)
    {
        return $query->orderBy('total', 'desc')->limit($limit);
    }
}
