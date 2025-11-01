<?php

namespace App\Models\Inventory;

use App\Models\Catalogs\Unidad;
use App\Models\Inv\Item;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TransferLine extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';
    protected $table = 'selemti.transfer_det';
    public $timestamps = false;

    protected $fillable = [
        'transfer_id',
        'linea',
        'item_id',
        'cantidad_solicitada',
        'cantidad_despachada',
        'cantidad_recibida',
        'uom_id',
        'costo_unitario',
        'lote',
        'observaciones',
    ];

    protected $casts = [
        'cantidad_solicitada' => 'decimal:3',
        'cantidad_despachada' => 'decimal:3',
        'cantidad_recibida' => 'decimal:3',
        'costo_unitario' => 'decimal:4',
    ];

    public function header(): BelongsTo
    {
        return $this->belongsTo(TransferHeader::class, 'transfer_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    public function uom(): BelongsTo
    {
        return $this->belongsTo(Unidad::class, 'uom_id');
    }

    public function getDiferenciaAttribute(): float
    {
        $despachada = (float) ($this->cantidad_despachada ?? 0);
        $recibida = (float) ($this->cantidad_recibida ?? 0);

        return $recibida - $despachada;
    }

    public function getVarianzaPorcentajeAttribute(): ?float
    {
        $despachada = (float) ($this->cantidad_despachada ?? 0);
        if ($despachada == 0.0) {
            return null;
        }

        return (($this->cantidad_recibida ?? 0) - $despachada) / $despachada * 100;
    }
}
