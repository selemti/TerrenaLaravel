<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProductionOrder extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'production_orders';
    protected $guarded = [];

    protected $casts = [
        'qty_programada' => 'decimal:2',
        'qty_producida' => 'decimal:2',
        'qty_merma' => 'decimal:2',
        'programado_para' => 'datetime',
        'iniciado_en' => 'datetime',
        'cerrado_en' => 'datetime',
        'meta' => 'array',
    ];

    // Estados
    const ESTADO_BORRADOR = 'BORRADOR';
    const ESTADO_PLANIFICADA = 'PLANIFICADA';
    const ESTADO_EN_PROCESO = 'EN_PROCESO';
    const ESTADO_COMPLETADO = 'COMPLETADO';
    const ESTADO_PAUSADA = 'PAUSADA';
    const ESTADO_CANCELADA = 'CANCELADA';

    /**
     * Item a producir
     */
    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    /**
     * Receta utilizada
     */
    public function recipe(): BelongsTo
    {
        return $this->belongsTo(Recipe::class, 'recipe_id', 'id');
    }

    /**
     * Sucursal donde se produce
     */
    public function sucursal(): BelongsTo
    {
        return $this->belongsTo(Sucursal::class, 'sucursal_id', 'id');
    }

    /**
     * Almacén destino
     */
    public function almacen(): BelongsTo
    {
        return $this->belongsTo(Almacen::class, 'almacen_id', 'id');
    }

    /**
     * Usuario que creó la orden
     */
    public function creador(): BelongsTo
    {
        return $this->belongsTo(\App\Models\User::class, 'creado_por', 'id');
    }

    /**
     * Usuario que aprobó la orden
     */
    public function aprobador(): BelongsTo
    {
        return $this->belongsTo(\App\Models\User::class, 'aprobado_por', 'id');
    }

    /**
     * Badge HTML para el estado
     */
    public function getEstadoBadgeAttribute(): string
    {
        return match($this->estado) {
            self::ESTADO_BORRADOR => '<span class="badge bg-secondary">Borrador</span>',
            self::ESTADO_PLANIFICADA => '<span class="badge bg-warning text-dark">Planificada</span>',
            self::ESTADO_EN_PROCESO => '<span class="badge bg-info">En Proceso</span>',
            self::ESTADO_COMPLETADO => '<span class="badge bg-success">Completado</span>',
            self::ESTADO_PAUSADA => '<span class="badge bg-warning">Pausada</span>',
            self::ESTADO_CANCELADA => '<span class="badge bg-danger">Cancelada</span>',
            default => '<span class="badge bg-secondary">' . $this->estado . '</span>',
        };
    }

    /**
     * Scopes
     */
    public function scopeBorrador($query)
    {
        return $query->where('estado', self::ESTADO_BORRADOR);
    }

    public function scopePlanificada($query)
    {
        return $query->where('estado', self::ESTADO_PLANIFICADA);
    }

    public function scopeEnProceso($query)
    {
        return $query->where('estado', self::ESTADO_EN_PROCESO);
    }

    public function scopeCompletado($query)
    {
        return $query->where('estado', self::ESTADO_COMPLETADO);
    }
}
