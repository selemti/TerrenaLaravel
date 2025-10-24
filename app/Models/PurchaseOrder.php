<?php

namespace App\Models;

use App\Models\Catalogs\Proveedor;
use App\Models\Catalogs\Sucursal;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PurchaseOrder extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'purchase_orders';
    protected $guarded = [];

    protected $casts = [
        'fecha_promesa' => 'date',
        'aprobado_en' => 'datetime',
        'subtotal' => 'decimal:2',
        'descuento' => 'decimal:2',
        'impuestos' => 'decimal:2',
        'total' => 'decimal:2',
        'meta' => 'array',
    ];

    /**
     * Estados posibles de la orden
     */
    const ESTADO_BORRADOR = 'BORRADOR';
    const ESTADO_APROBADA = 'APROBADA';
    const ESTADO_ENVIADA = 'ENVIADA';
    const ESTADO_RECIBIDA = 'RECIBIDA';
    const ESTADO_CERRADA = 'CERRADA';
    const ESTADO_CANCELADA = 'CANCELADA';

    // ==================== RELATIONSHIPS ====================

    /**
     * Cotización de la cual se generó esta orden (si aplica)
     */
    public function vendorQuote(): BelongsTo
    {
        return $this->belongsTo(VendorQuote::class, 'quote_id');
    }

    /**
     * Proveedor de la orden
     */
    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Proveedor::class, 'vendor_id', 'id');
    }

    /**
     * Sucursal asociada (si aplica)
     */
    public function sucursal(): BelongsTo
    {
        return $this->belongsTo(Sucursal::class, 'sucursal_id', 'id');
    }

    /**
     * Líneas de la orden
     */
    public function lines(): HasMany
    {
        return $this->hasMany(PurchaseOrderLine::class, 'order_id');
    }

    /**
     * Usuario que creó la orden
     */
    public function creadoPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creado_por');
    }

    /**
     * Usuario que aprobó la orden
     */
    public function aprobadoPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'aprobado_por');
    }

    /**
     * Documentos adjuntos
     */
    public function documents(): HasMany
    {
        return $this->hasMany(PurchaseDocument::class, 'order_id');
    }

    // ==================== ACCESSORS ====================

    /**
     * Badge HTML del estado
     */
    public function getEstadoBadgeAttribute(): string
    {
        return match($this->estado) {
            self::ESTADO_BORRADOR => '<span class="badge bg-secondary">Borrador</span>',
            self::ESTADO_APROBADA => '<span class="badge bg-success">Aprobada</span>',
            self::ESTADO_ENVIADA => '<span class="badge bg-info">Enviada</span>',
            self::ESTADO_RECIBIDA => '<span class="badge bg-primary">Recibida</span>',
            self::ESTADO_CERRADA => '<span class="badge bg-dark">Cerrada</span>',
            self::ESTADO_CANCELADA => '<span class="badge bg-danger">Cancelada</span>',
            default => '<span class="badge bg-secondary">' . $this->estado . '</span>',
        };
    }

    /**
     * Total de líneas en la orden
     */
    public function getTotalLineasAttribute(): int
    {
        return $this->lines()->count();
    }

    /**
     * Total de items ordenados
     */
    public function getTotalItemsAttribute(): float
    {
        return $this->lines()->sum('qty');
    }

    /**
     * Indica si está aprobada
     */
    public function getIsAprobadaAttribute(): bool
    {
        return in_array($this->estado, [
            self::ESTADO_APROBADA,
            self::ESTADO_ENVIADA,
            self::ESTADO_RECIBIDA,
            self::ESTADO_CERRADA
        ]);
    }

    /**
     * Indica si se puede editar
     */
    public function getIsEditableAttribute(): bool
    {
        return in_array($this->estado, [self::ESTADO_BORRADOR]);
    }

    /**
     * Indica si se puede enviar
     */
    public function getCanEnviarAttribute(): bool
    {
        return $this->estado === self::ESTADO_APROBADA;
    }

    /**
     * Indica si se puede cancelar
     */
    public function getCanCancelAttribute(): bool
    {
        return !in_array($this->estado, [
            self::ESTADO_RECIBIDA,
            self::ESTADO_CERRADA,
            self::ESTADO_CANCELADA
        ]);
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

    /**
     * Días hasta fecha promesa
     */
    public function getDiasHastaPromesaAttribute(): ?int
    {
        if (!$this->fecha_promesa) return null;
        return now()->diffInDays($this->fecha_promesa, false);
    }

    /**
     * Indica si está vencida la promesa
     */
    public function getIsVencidaAttribute(): bool
    {
        if (!$this->fecha_promesa) return false;
        return now()->isAfter($this->fecha_promesa) && !in_array($this->estado, [
            self::ESTADO_RECIBIDA,
            self::ESTADO_CERRADA,
            self::ESTADO_CANCELADA
        ]);
    }

    // ==================== SCOPES ====================

    /**
     * Scope para órdenes en borrador
     */
    public function scopeBorrador($query)
    {
        return $query->where('estado', self::ESTADO_BORRADOR);
    }

    /**
     * Scope para órdenes aprobadas
     */
    public function scopeAprobada($query)
    {
        return $query->where('estado', self::ESTADO_APROBADA);
    }

    /**
     * Scope para órdenes enviadas
     */
    public function scopeEnviada($query)
    {
        return $query->where('estado', self::ESTADO_ENVIADA);
    }

    /**
     * Scope para órdenes recibidas
     */
    public function scopeRecibida($query)
    {
        return $query->where('estado', self::ESTADO_RECIBIDA);
    }

    /**
     * Scope para órdenes cerradas
     */
    public function scopeCerrada($query)
    {
        return $query->where('estado', self::ESTADO_CERRADA);
    }

    /**
     * Scope por proveedor
     */
    public function scopePorVendor($query, int $vendorId)
    {
        return $query->where('vendor_id', $vendorId);
    }

    /**
     * Scope por sucursal
     */
    public function scopePorSucursal($query, string $sucursalId)
    {
        return $query->where('sucursal_id', $sucursalId);
    }

    /**
     * Scope para órdenes vencidas
     */
    public function scopeVencidas($query)
    {
        return $query->where('fecha_promesa', '<', now())
                     ->whereNotIn('estado', [
                         self::ESTADO_RECIBIDA,
                         self::ESTADO_CERRADA,
                         self::ESTADO_CANCELADA
                     ]);
    }

    /**
     * Scope por rango de fechas de creación
     */
    public function scopePorFechas($query, $desde, $hasta)
    {
        return $query->whereBetween('created_at', [$desde, $hasta]);
    }
}
