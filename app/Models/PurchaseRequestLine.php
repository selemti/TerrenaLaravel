<?php

namespace App\Models;

use App\Models\Catalogs\Proveedor;
use App\Models\Inventory\Item;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PurchaseRequestLine extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'purchase_request_lines';
    protected $guarded = [];

    protected $casts = [
        'qty' => 'decimal:3',
        'last_price' => 'decimal:2',
        'fecha_requerida' => 'date',
        'meta' => 'array',
    ];

    /**
     * Estados posibles de la línea
     */
    const ESTADO_PENDIENTE = 'PENDIENTE';
    const ESTADO_COTIZADA = 'COTIZADA';
    const ESTADO_ORDENADA = 'ORDENADA';
    const ESTADO_RECIBIDA = 'RECIBIDA';
    const ESTADO_CANCELADA = 'CANCELADA';

    // ==================== RELATIONSHIPS ====================

    /**
     * Solicitud de compra principal
     */
    public function purchaseRequest(): BelongsTo
    {
        return $this->belongsTo(PurchaseRequest::class, 'request_id');
    }

    /**
     * Item solicitado
     */
    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    /**
     * Proveedor preferido (si se especificó)
     */
    public function preferredVendor(): BelongsTo
    {
        return $this->belongsTo(Proveedor::class, 'preferred_vendor_id', 'id');
    }

    /**
     * Líneas de cotización relacionadas
     */
    public function quoteLines(): HasMany
    {
        return $this->hasMany(VendorQuoteLine::class, 'request_line_id');
    }

    /**
     * Líneas de orden relacionadas
     */
    public function orderLines(): HasMany
    {
        return $this->hasMany(PurchaseOrderLine::class, 'request_line_id');
    }

    // ==================== ACCESSORS ====================

    /**
     * Badge HTML del estado
     */
    public function getEstadoBadgeAttribute(): string
    {
        return match($this->estado) {
            self::ESTADO_PENDIENTE => '<span class="badge bg-warning">Pendiente</span>',
            self::ESTADO_COTIZADA => '<span class="badge bg-info">Cotizada</span>',
            self::ESTADO_ORDENADA => '<span class="badge bg-primary">Ordenada</span>',
            self::ESTADO_RECIBIDA => '<span class="badge bg-success">Recibida</span>',
            self::ESTADO_CANCELADA => '<span class="badge bg-danger">Cancelada</span>',
            default => '<span class="badge bg-secondary">' . $this->estado . '</span>',
        };
    }

    /**
     * Monto estimado de la línea
     */
    public function getMontoEstimadoAttribute(): float
    {
        return $this->qty * ($this->last_price ?? 0);
    }

    /**
     * Total de cotizaciones recibidas para esta línea
     */
    public function getTotalQuotesAttribute(): int
    {
        return $this->quoteLines()->count();
    }

    /**
     * Mejor precio recibido en cotizaciones
     */
    public function getBestPriceAttribute(): ?float
    {
        return $this->quoteLines()->min('precio_unitario');
    }

    /**
     * Indica si tiene cotizaciones
     */
    public function getHasQuotesAttribute(): bool
    {
        return $this->quoteLines()->exists();
    }

    /**
     * Indica si está ordenada
     */
    public function getIsOrdenadaAttribute(): bool
    {
        return $this->orderLines()->exists();
    }

    // ==================== SCOPES ====================

    /**
     * Scope para líneas pendientes
     */
    public function scopePendiente($query)
    {
        return $query->where('estado', self::ESTADO_PENDIENTE);
    }

    /**
     * Scope para líneas cotizadas
     */
    public function scopeCotizada($query)
    {
        return $query->where('estado', self::ESTADO_COTIZADA);
    }

    /**
     * Scope para líneas ordenadas
     */
    public function scopeOrdenada($query)
    {
        return $query->where('estado', self::ESTADO_ORDENADA);
    }

    /**
     * Scope por item
     */
    public function scopePorItem($query, int $itemId)
    {
        return $query->where('item_id', $itemId);
    }

    /**
     * Scope por proveedor preferido
     */
    public function scopePorProveedorPreferido($query, int $vendorId)
    {
        return $query->where('preferred_vendor_id', $vendorId);
    }

    /**
     * Scope por fecha requerida próxima
     */
    public function scopeProximasVencer($query, int $dias = 7)
    {
        return $query->where('fecha_requerida', '<=', now()->addDays($dias))
                     ->where('fecha_requerida', '>=', now())
                     ->where('estado', '!=', self::ESTADO_RECIBIDA);
    }
}
