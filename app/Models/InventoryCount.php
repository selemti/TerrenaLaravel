<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class InventoryCount extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'inventory_counts';

    protected $guarded = [];

    protected $casts = [
        'programado_para' => 'datetime',
        'iniciado_en' => 'datetime',
        'cerrado_en' => 'datetime',
        'total_items' => 'decimal:4',
        'total_variacion' => 'decimal:6',
        'meta' => 'array',
    ];

    /**
     * Relación con las líneas del conteo
     */
    public function lines(): HasMany
    {
        return $this->hasMany(InventoryCountLine::class, 'inventory_count_id');
    }

    /**
     * Relación con el usuario que creó el conteo
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creado_por');
    }

    /**
     * Relación con el usuario que cerró el conteo
     */
    public function closedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'cerrado_por');
    }

    /**
     * Accessor: Total de items con variación
     */
    public function getTotalConVariacionAttribute(): int
    {
        return $this->lines()
            ->whereRaw('ABS(qty_variacion) > 0.000001')
            ->count();
    }

    /**
     * Accessor: Porcentaje de exactitud
     */
    public function getPorcentajeExactitudAttribute(): float
    {
        $total = $this->lines()->count();
        if ($total === 0) {
            return 100.0;
        }

        $conVariacion = $this->total_con_variacion;
        $exactos = $total - $conVariacion;

        return ($exactos / $total) * 100;
    }

    /**
     * Accessor: Estado con formato
     */
    public function getEstadoBadgeAttribute(): string
    {
        return match($this->estado) {
            'BORRADOR' => '<span class="badge bg-secondary">Borrador</span>',
            'EN_PROCESO' => '<span class="badge bg-primary">En Proceso</span>',
            'AJUSTADO' => '<span class="badge bg-success">Ajustado</span>',
            'CANCELADO' => '<span class="badge bg-danger">Cancelado</span>',
            default => '<span class="badge bg-secondary">' . $this->estado . '</span>',
        };
    }

    /**
     * Scope: Conteos abiertos
     */
    public function scopeEnProceso($query)
    {
        return $query->where('estado', 'EN_PROCESO');
    }

    /**
     * Scope: Conteos cerrados
     */
    public function scopeAjustados($query)
    {
        return $query->where('estado', 'AJUSTADO');
    }

    /**
     * Scope: Por sucursal
     */
    public function scopePorSucursal($query, $sucursalId)
    {
        return $query->where('sucursal_id', $sucursalId);
    }

    /**
     * Scope: Por almacén
     */
    public function scopePorAlmacen($query, $almacenId)
    {
        return $query->where('almacen_id', $almacenId);
    }
}
