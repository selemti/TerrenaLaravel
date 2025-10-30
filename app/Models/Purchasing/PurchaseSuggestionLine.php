<?php

namespace App\Models\Purchasing;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PurchaseSuggestionLine extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.purchase_suggestion_lines';

    protected $fillable = [
        'suggestion_id',
        'item_id',
        'stock_actual',
        'stock_min',
        'stock_max',
        'reorder_point',
        'consumo_promedio_diario',
        'dias_cobertura_actual',
        'demanda_proyectada',
        'qty_sugerida',
        'qty_ajustada',
        'uom',
        'costo_unitario_estimado',
        'costo_total_linea',
        'proveedor_sugerido_id',
        'ultimo_precio_compra',
        'fecha_ultima_compra',
        'notas',
    ];

    protected $casts = [
        'stock_actual' => 'decimal:6',
        'stock_min' => 'decimal:6',
        'stock_max' => 'decimal:6',
        'reorder_point' => 'decimal:6',
        'consumo_promedio_diario' => 'decimal:6',
        'dias_cobertura_actual' => 'integer',
        'demanda_proyectada' => 'decimal:6',
        'qty_sugerida' => 'decimal:6',
        'qty_ajustada' => 'decimal:6',
        'costo_unitario_estimado' => 'decimal:6',
        'costo_total_linea' => 'decimal:2',
        'ultimo_precio_compra' => 'decimal:6',
        'fecha_ultima_compra' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function suggestion(): BelongsTo
    {
        return $this->belongsTo(PurchaseSuggestion::class, 'suggestion_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(\App\Models\Inv\Item::class, 'item_id');
    }

    public function proveedorSugerido(): BelongsTo
    {
        return $this->belongsTo(\App\Models\Catalogs\Proveedor::class, 'proveedor_sugerido_id');
    }
}
