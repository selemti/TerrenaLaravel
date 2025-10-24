<?php

namespace App\Models;

use App\Models\Catalogs\Sucursal;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PurchaseRequest extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'purchase_requests';
    protected $guarded = [];

    protected $casts = [
        'requested_at' => 'datetime',
        'importe_estimado' => 'decimal:2',
        'meta' => 'array',
    ];

    /**
     * Estados posibles de la solicitud
     */
    const ESTADO_BORRADOR = 'BORRADOR';
    const ESTADO_COTIZADA = 'COTIZADA';
    const ESTADO_APROBADA = 'APROBADA';
    const ESTADO_ORDENADA = 'ORDENADA';
    const ESTADO_CANCELADA = 'CANCELADA';

    // ==================== RELATIONSHIPS ====================

    /**
     * Líneas de la solicitud
     */
    public function lines(): HasMany
    {
        return $this->hasMany(PurchaseRequestLine::class, 'request_id');
    }

    /**
     * Cotizaciones recibidas para esta solicitud
     */
    public function quotes(): HasMany
    {
        return $this->hasMany(VendorQuote::class, 'request_id');
    }

    /**
     * Usuario que creó la solicitud
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Usuario que solicitó la compra
     */
    public function requestedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by');
    }

    /**
     * Sucursal asociada (si aplica)
     */
    public function sucursal(): BelongsTo
    {
        return $this->belongsTo(Sucursal::class, 'sucursal_id', 'id');
    }

    // ==================== ACCESSORS ====================

    /**
     * Badge HTML del estado
     */
    public function getEstadoBadgeAttribute(): string
    {
        return match($this->estado) {
            self::ESTADO_BORRADOR => '<span class="badge bg-secondary">Borrador</span>',
            self::ESTADO_COTIZADA => '<span class="badge bg-info">Cotizada</span>',
            self::ESTADO_APROBADA => '<span class="badge bg-success">Aprobada</span>',
            self::ESTADO_ORDENADA => '<span class="badge bg-primary">Ordenada</span>',
            self::ESTADO_CANCELADA => '<span class="badge bg-danger">Cancelada</span>',
            default => '<span class="badge bg-secondary">' . $this->estado . '</span>',
        };
    }

    /**
     * Total de líneas en la solicitud
     */
    public function getTotalLineasAttribute(): int
    {
        return $this->lines()->count();
    }

    /**
     * Total de items solicitados (suma de cantidades)
     */
    public function getTotalItemsAttribute(): float
    {
        return $this->lines()->sum('qty');
    }

    /**
     * Cotización aprobada (si existe)
     */
    public function getQuoteAprobadaAttribute(): ?VendorQuote
    {
        return $this->quotes()->where('estado', VendorQuote::ESTADO_APROBADA)->first();
    }

    /**
     * Total de cotizaciones recibidas
     */
    public function getTotalQuotesAttribute(): int
    {
        return $this->quotes()->count();
    }

    /**
     * Indica si está en estado editable
     */
    public function getIsEditableAttribute(): bool
    {
        return in_array($this->estado, [self::ESTADO_BORRADOR]);
    }

    /**
     * Indica si se puede enviar a cotizar
     */
    public function getCanEnviarAttribute(): bool
    {
        return $this->estado === self::ESTADO_BORRADOR && $this->lines()->count() > 0;
    }

    /**
     * Indica si se puede cancelar
     */
    public function getCanCancelAttribute(): bool
    {
        return !in_array($this->estado, [self::ESTADO_ORDENADA, self::ESTADO_CANCELADA]);
    }

    // ==================== SCOPES ====================

    /**
     * Scope para solicitudes en borrador
     */
    public function scopeBorrador($query)
    {
        return $query->where('estado', self::ESTADO_BORRADOR);
    }

    /**
     * Scope para solicitudes cotizadas
     */
    public function scopeCotizada($query)
    {
        return $query->where('estado', self::ESTADO_COTIZADA);
    }

    /**
     * Scope para solicitudes aprobadas
     */
    public function scopeAprobada($query)
    {
        return $query->where('estado', self::ESTADO_APROBADA);
    }

    /**
     * Scope para solicitudes ordenadas
     */
    public function scopeOrdenada($query)
    {
        return $query->where('estado', self::ESTADO_ORDENADA);
    }

    /**
     * Scope para solicitudes canceladas
     */
    public function scopeCancelada($query)
    {
        return $query->where('estado', self::ESTADO_CANCELADA);
    }

    /**
     * Scope por sucursal
     */
    public function scopePorSucursal($query, string $sucursalId)
    {
        return $query->where('sucursal_id', $sucursalId);
    }

    /**
     * Scope por rango de fechas
     */
    public function scopePorFechas($query, $desde, $hasta)
    {
        return $query->whereBetween('requested_at', [$desde, $hasta]);
    }
}
