<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Models\Item;
use App\Models\Sucursal;
use App\Models\Almacen;
use App\Models\PurchaseRequest;
use App\Models\ProductionOrder;

class ReplenishmentSuggestion extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'replenishment_suggestions';
    protected $guarded = [];

    protected $casts = [
        'stock_actual' => 'decimal:2',
        'stock_min' => 'decimal:2',
        'stock_max' => 'decimal:2',
        'qty_sugerida' => 'decimal:2',
        'qty_aprobada' => 'decimal:2',
        'consumo_promedio_diario' => 'decimal:2',
        'dias_stock_restante' => 'integer',
        'fecha_agotamiento_estimada' => 'date',
        'sugerido_en' => 'datetime',
        'revisado_en' => 'datetime',
        'convertido_en' => 'datetime',
        'caduca_en' => 'datetime',
        'meta' => 'array',
    ];

    // ==========================================
    // CONSTANTES DE ESTADOS
    // ==========================================

    const ESTADO_PENDIENTE = 'PENDIENTE';
    const ESTADO_REVISADA = 'REVISADA';
    const ESTADO_APROBADA = 'APROBADA';
    const ESTADO_RECHAZADA = 'RECHAZADA';
    const ESTADO_CONVERTIDA = 'CONVERTIDA';
    const ESTADO_CADUCADA = 'CADUCADA';

    const TIPO_COMPRA = 'COMPRA';
    const TIPO_PRODUCCION = 'PRODUCCION';

    const PRIORIDAD_URGENTE = 'URGENTE';
    const PRIORIDAD_ALTA = 'ALTA';
    const PRIORIDAD_NORMAL = 'NORMAL';
    const PRIORIDAD_BAJA = 'BAJA';

    const ORIGEN_AUTO = 'AUTO';
    const ORIGEN_MANUAL = 'MANUAL';
    const ORIGEN_EVENTO_ESPECIAL = 'EVENTO_ESPECIAL';

    // ==========================================
    // RELACIONES
    // ==========================================

    /**
     * Item relacionado
     */
    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    /**
     * Sucursal donde se sugiere reponer
     */
    public function sucursal(): BelongsTo
    {
        return $this->belongsTo(Sucursal::class, 'sucursal_id', 'id');
    }

    /**
     * Almacén específico
     */
    public function almacen(): BelongsTo
    {
        return $this->belongsTo(Almacen::class, 'almacen_id', 'id');
    }

    /**
     * Solicitud de compra generada
     */
    public function purchaseRequest(): BelongsTo
    {
        return $this->belongsTo(PurchaseRequest::class, 'purchase_request_id', 'id');
    }

    /**
     * Orden de producción generada
     */
    public function productionOrder(): BelongsTo
    {
        return $this->belongsTo(ProductionOrder::class, 'production_order_id', 'id');
    }

    /**
     * Usuario que revisó la sugerencia
     */
    public function revisadoPor(): BelongsTo
    {
        return $this->belongsTo(\App\Models\User::class, 'revisado_por', 'id');
    }

    // ==========================================
    // ACCESSORS
    // ==========================================

    /**
     * Badge HTML para el estado
     */
    public function getEstadoBadgeAttribute(): string
    {
        return match($this->estado) {
            self::ESTADO_PENDIENTE => '<span class="badge bg-warning text-dark">Pendiente</span>',
            self::ESTADO_REVISADA => '<span class="badge bg-info">Revisada</span>',
            self::ESTADO_APROBADA => '<span class="badge bg-success">Aprobada</span>',
            self::ESTADO_RECHAZADA => '<span class="badge bg-danger">Rechazada</span>',
            self::ESTADO_CONVERTIDA => '<span class="badge bg-primary">Convertida</span>',
            self::ESTADO_CADUCADA => '<span class="badge bg-secondary">Caducada</span>',
            default => '<span class="badge bg-secondary">' . $this->estado . '</span>',
        };
    }

    /**
     * Badge HTML para el tipo
     */
    public function getTipoBadgeAttribute(): string
    {
        return match($this->tipo) {
            self::TIPO_COMPRA => '<span class="badge bg-info"><i class="fa-solid fa-shopping-cart me-1"></i>Compra</span>',
            self::TIPO_PRODUCCION => '<span class="badge bg-success"><i class="fa-solid fa-industry me-1"></i>Producción</span>',
            default => '<span class="badge bg-secondary">' . $this->tipo . '</span>',
        };
    }

    /**
     * Badge HTML para la prioridad
     */
    public function getPrioridadBadgeAttribute(): string
    {
        return match($this->prioridad) {
            self::PRIORIDAD_URGENTE => '<span class="badge bg-danger"><i class="fa-solid fa-exclamation-triangle me-1"></i>Urgente</span>',
            self::PRIORIDAD_ALTA => '<span class="badge bg-warning text-dark">Alta</span>',
            self::PRIORIDAD_NORMAL => '<span class="badge bg-secondary">Normal</span>',
            self::PRIORIDAD_BAJA => '<span class="badge bg-light text-dark">Baja</span>',
            default => '<span class="badge bg-secondary">' . $this->prioridad . '</span>',
        };
    }

    /**
     * Nivel de urgencia basado en días restantes
     */
    public function getNivelUrgenciaAttribute(): string
    {
        if (!$this->fecha_agotamiento_estimada) {
            return 'DESCONOCIDO';
        }

        $dias = now()->diffInDays($this->fecha_agotamiento_estimada, false);

        if ($dias <= 0) return 'CRITICO';
        if ($dias <= 3) return 'URGENTE';
        if ($dias <= 7) return 'PROXIMO';

        return 'NORMAL';
    }

    /**
     * Icono de urgencia
     */
    public function getUrgenciaIconoAttribute(): string
    {
        return match($this->nivel_urgencia) {
            'CRITICO' => '<i class="fa-solid fa-circle-exclamation text-danger"></i>',
            'URGENTE' => '<i class="fa-solid fa-triangle-exclamation text-warning"></i>',
            'PROXIMO' => '<i class="fa-solid fa-info-circle text-info"></i>',
            default => '<i class="fa-solid fa-check-circle text-success"></i>',
        };
    }

    /**
     * Porcentaje de stock actual vs mínimo
     */
    public function getPorcentajeStockAttribute(): float
    {
        if ($this->stock_min <= 0) {
            return 100;
        }

        return round(($this->stock_actual / $this->stock_min) * 100, 2);
    }

    /**
     * Indica si la sugerencia está caducada
     */
    public function getEsCaducadaAttribute(): bool
    {
        return $this->caduca_en && now()->isAfter($this->caduca_en) && $this->estado === self::ESTADO_PENDIENTE;
    }

    /**
     * Indica si puede ser aprobada
     */
    public function getPuedeAprobarseAttribute(): bool
    {
        return in_array($this->estado, [self::ESTADO_PENDIENTE, self::ESTADO_REVISADA]);
    }

    /**
     * Indica si ya fue procesada
     */
    public function getFueProcesadaAttribute(): bool
    {
        return in_array($this->estado, [self::ESTADO_CONVERTIDA, self::ESTADO_RECHAZADA, self::ESTADO_CADUCADA]);
    }

    // ==========================================
    // SCOPES
    // ==========================================

    /**
     * Sugerencias pendientes de revisar
     */
    public function scopePendiente($query)
    {
        return $query->where('estado', self::ESTADO_PENDIENTE);
    }

    /**
     * Sugerencias revisadas
     */
    public function scopeRevisada($query)
    {
        return $query->where('estado', self::ESTADO_REVISADA);
    }

    /**
     * Sugerencias aprobadas
     */
    public function scopeAprobada($query)
    {
        return $query->where('estado', self::ESTADO_APROBADA);
    }

    /**
     * Sugerencias convertidas
     */
    public function scopeConvertida($query)
    {
        return $query->where('estado', self::ESTADO_CONVERTIDA);
    }

    /**
     * Sugerencias rechazadas
     */
    public function scopeRechazada($query)
    {
        return $query->where('estado', self::ESTADO_RECHAZADA);
    }

    /**
     * Sugerencias de compra
     */
    public function scopeCompra($query)
    {
        return $query->where('tipo', self::TIPO_COMPRA);
    }

    /**
     * Sugerencias de producción
     */
    public function scopeProduccion($query)
    {
        return $query->where('tipo', self::TIPO_PRODUCCION);
    }

    /**
     * Sugerencias urgentes o críticas
     */
    public function scopeUrgentes($query)
    {
        return $query->where(function ($q) {
            $q->where('prioridad', self::PRIORIDAD_URGENTE)
              ->orWhere('dias_stock_restante', '<=', 3)
              ->orWhere('fecha_agotamiento_estimada', '<=', now()->addDays(3));
        });
    }

    /**
     * Sugerencias por sucursal
     */
    public function scopePorSucursal($query, $sucursalId)
    {
        return $query->where('sucursal_id', $sucursalId);
    }

    /**
     * Sugerencias generadas automáticamente
     */
    public function scopeAutomaticas($query)
    {
        return $query->where('origen', self::ORIGEN_AUTO);
    }

    /**
     * Sugerencias manuales
     */
    public function scopeManuales($query)
    {
        return $query->where('origen', self::ORIGEN_MANUAL);
    }

    /**
     * Sugerencias que requieren atención
     */
    public function scopeRequierenAtencion($query)
    {
        return $query->where(function ($q) {
            $q->where('estado', self::ESTADO_PENDIENTE)
              ->where(function ($q2) {
                  $q2->where('prioridad', self::PRIORIDAD_URGENTE)
                     ->orWhere('dias_stock_restante', '<=', 2);
              });
        });
    }

    // ==========================================
    // MÉTODOS AUXILIARES
    // ==========================================

    /**
     * Marcar como revisada
     */
    public function marcarRevisada(int $userId): void
    {
        $this->update([
            'estado' => self::ESTADO_REVISADA,
            'revisado_en' => now(),
            'revisado_por' => $userId,
        ]);
    }

    /**
     * Marcar como aprobada
     */
    public function marcarAprobada(int $userId, ?float $qtyAjustada = null): void
    {
        $this->update([
            'estado' => self::ESTADO_APROBADA,
            'revisado_en' => now(),
            'revisado_por' => $userId,
            'qty_aprobada' => $qtyAjustada ?? $this->qty_sugerida,
        ]);
    }

    /**
     * Marcar como rechazada
     */
    public function marcarRechazada(int $userId, string $motivo): void
    {
        $this->update([
            'estado' => self::ESTADO_RECHAZADA,
            'revisado_en' => now(),
            'revisado_por' => $userId,
            'motivo_rechazo' => $motivo,
        ]);
    }

    /**
     * Marcar como convertida
     */
    public function marcarConvertida(?int $purchaseRequestId = null, ?int $productionOrderId = null): void
    {
        $this->update([
            'estado' => self::ESTADO_CONVERTIDA,
            'convertido_en' => now(),
            'purchase_request_id' => $purchaseRequestId,
            'production_order_id' => $productionOrderId,
        ]);
    }
}
