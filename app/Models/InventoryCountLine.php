<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InventoryCountLine extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'inventory_count_lines';

    protected $guarded = [];

    protected $casts = [
        'qty_teorica' => 'decimal:6',
        'qty_contada' => 'decimal:6',
        'qty_variacion' => 'decimal:6',
        'meta' => 'array',
    ];

    /**
     * Relación con el conteo principal
     */
    public function inventoryCount(): BelongsTo
    {
        return $this->belongsTo(InventoryCount::class, 'inventory_count_id');
    }

    /**
     * Relación con el item
     */
    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id');
    }

    /**
     * Relación con el lote
     */
    public function batch(): BelongsTo
    {
        return $this->belongsTo(InventoryBatch::class, 'inventory_batch_id');
    }

    /**
     * Accessor: Variación absoluta
     */
    public function getVariacionAbsolutaAttribute(): float
    {
        return abs($this->qty_variacion);
    }

    /**
     * Accessor: Porcentaje de variación
     */
    public function getPorcentajeVariacionAttribute(): float
    {
        if ($this->qty_teorica == 0) {
            return $this->qty_contada > 0 ? 100.0 : 0.0;
        }

        return ($this->qty_variacion / $this->qty_teorica) * 100;
    }

    /**
     * Accessor: Tipo de variación (FALTANTE, SOBRANTE, EXACTO)
     */
    public function getTipoVariacionAttribute(): string
    {
        if (abs($this->qty_variacion) < 0.000001) {
            return 'EXACTO';
        }

        return $this->qty_variacion > 0 ? 'SOBRANTE' : 'FALTANTE';
    }

    /**
     * Accessor: Badge de variación
     */
    public function getVariacionBadgeAttribute(): string
    {
        $tipo = $this->tipo_variacion;

        return match($tipo) {
            'EXACTO' => '<span class="badge bg-success">Exacto</span>',
            'SOBRANTE' => '<span class="badge bg-info">+' . number_format($this->qty_variacion, 2) . '</span>',
            'FALTANTE' => '<span class="badge bg-warning text-dark">' . number_format($this->qty_variacion, 2) . '</span>',
            default => '<span class="badge bg-secondary">' . $tipo . '</span>',
        };
    }

    /**
     * Accessor: ¿Está contado?
     */
    public function getEstaContadoAttribute(): bool
    {
        return $this->qty_contada !== null && $this->qty_contada != $this->qty_teorica;
    }

    /**
     * Scope: Solo líneas con variación
     */
    public function scopeConVariacion($query)
    {
        return $query->whereRaw('ABS(qty_variacion) > 0.000001');
    }

    /**
     * Scope: Solo líneas exactas
     */
    public function scopeExactas($query)
    {
        return $query->whereRaw('ABS(qty_variacion) < 0.000001');
    }

    /**
     * Scope: Faltantes
     */
    public function scopeFaltantes($query)
    {
        return $query->where('qty_variacion', '<', 0);
    }

    /**
     * Scope: Sobrantes
     */
    public function scopeSobrantes($query)
    {
        return $query->where('qty_variacion', '>', 0);
    }
}
