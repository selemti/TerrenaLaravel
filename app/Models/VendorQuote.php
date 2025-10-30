<?php

namespace App\Models;

use App\Models\Catalogs\Proveedor;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class VendorQuote extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'purchase_vendor_quotes';
    protected $guarded = [];

    protected $casts = [
        'enviada_en' => 'datetime',
        'recibida_en' => 'datetime',
        'aprobada_en' => 'datetime',
        'subtotal' => 'decimal:2',
        'descuento' => 'decimal:2',
        'impuestos' => 'decimal:2',
        'total' => 'decimal:2',
        'meta' => 'array',
    ];

    /**
     * Estados posibles de la cotización
     */
    const ESTADO_RECIBIDA = 'RECIBIDA';
    const ESTADO_APROBADA = 'APROBADA';
    const ESTADO_RECHAZADA = 'RECHAZADA';
    const ESTADO_VENCIDA = 'VENCIDA';

    // ==================== RELATIONSHIPS ====================

    /**
     * Solicitud de compra asociada
     */
    public function purchaseRequest(): BelongsTo
    {
        return $this->belongsTo(PurchaseRequest::class, 'request_id');
    }

    /**
     * Proveedor que envió la cotización
     */
    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Proveedor::class, 'vendor_id', 'id');
    }

    /**
     * Líneas de la cotización
     */
    public function lines(): HasMany
    {
        return $this->hasMany(VendorQuoteLine::class, 'quote_id');
    }

    /**
     * Usuario que capturó la cotización
     */
    public function capturadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'capturada_por');
    }

    /**
     * Usuario que aprobó la cotización
     */
    public function aprobadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'aprobada_por');
    }

    /**
     * Orden de compra generada (si aplica)
     */
    public function purchaseOrder(): HasOne
    {
        return $this->hasOne(PurchaseOrder::class, 'quote_id');
    }

    // ==================== ACCESSORS ====================

    /**
     * Badge HTML del estado
     */
    public function getEstadoBadgeAttribute(): string
    {
        return match($this->estado) {
            self::ESTADO_RECIBIDA => '<span class="badge bg-info">Recibida</span>',
            self::ESTADO_APROBADA => '<span class="badge bg-success">Aprobada</span>',
            self::ESTADO_RECHAZADA => '<span class="badge bg-danger">Rechazada</span>',
            self::ESTADO_VENCIDA => '<span class="badge bg-secondary">Vencida</span>',
            default => '<span class="badge bg-secondary">' . $this->estado . '</span>',
        };
    }

    /**
     * Total de líneas en la cotización
     */
    public function getTotalLineasAttribute(): int
    {
        return $this->lines()->count();
    }

    /**
     * Total de items cotizados
     */
    public function getTotalItemsAttribute(): float
    {
        return $this->lines()->sum('qty_oferta');
    }

    /**
     * Indica si está aprobada
     */
    public function getIsAprobadaAttribute(): bool
    {
        return $this->estado === self::ESTADO_APROBADA;
    }

    /**
     * Indica si se puede aprobar
     */
    public function getCanAprobarAttribute(): bool
    {
        return $this->estado === self::ESTADO_RECIBIDA;
    }

    /**
     * Indica si se puede rechazar
     */
    public function getCanRechazarAttribute(): bool
    {
        return in_array($this->estado, [self::ESTADO_RECIBIDA]);
    }

    /**
     * Indica si ya generó orden
     */
    public function getHasOrderAttribute(): bool
    {
        return $this->purchaseOrder()->exists();
    }

    /**
     * Porcentaje de descuento
     */
    public function getPorcentajeDescuentoAttribute(): float
    {
        if ($this->subtotal == 0) return 0;
        return ($this->descuento / $this->subtotal) * 100;
    }

    /**
     * Porcentaje de impuestos
     */
    public function getPorcentajeImpuestosAttribute(): float
    {
        if ($this->subtotal == 0) return 0;
        return ($this->impuestos / $this->subtotal) * 100;
    }

    // ==================== SCOPES ====================

    /**
     * Scope para cotizaciones recibidas
     */
    public function scopeRecibida($query)
    {
        return $query->where('estado', self::ESTADO_RECIBIDA);
    }

    /**
     * Scope para cotizaciones aprobadas
     */
    public function scopeAprobada($query)
    {
        return $query->where('estado', self::ESTADO_APROBADA);
    }

    /**
     * Scope para cotizaciones rechazadas
     */
    public function scopeRechazada($query)
    {
        return $query->where('estado', self::ESTADO_RECHAZADA);
    }

    /**
     * Scope por proveedor
     */
    public function scopePorVendor($query, int $vendorId)
    {
        return $query->where('vendor_id', $vendorId);
    }

    /**
     * Scope por solicitud
     */
    public function scopePorRequest($query, int $requestId)
    {
        return $query->where('request_id', $requestId);
    }

    /**
     * Scope por rango de fechas de recepción
     */
    public function scopePorFechasRecepcion($query, $desde, $hasta)
    {
        return $query->whereBetween('recibida_en', [$desde, $hasta]);
    }

    /**
     * Scope para cotizaciones pendientes de aprobar
     */
    public function scopePendientesAprobar($query)
    {
        return $query->where('estado', self::ESTADO_RECIBIDA)
                     ->whereNull('aprobada_en');
    }
}
