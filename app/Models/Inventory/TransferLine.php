<?php

namespace App\Models\Inventory;

use App\Models\Inv\Item;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TransferLine extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';
    protected $table = 'selemti.transfer_det';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'transfer_id',
        'item_id',
        'cantidad_solicitada',
        'cantidad_despachada',
        'cantidad_recibida',
        'unidad_medida',
        'observaciones',
        'observaciones_recepcion',
        'created_at',
    ];

    protected $casts = [
        'cantidad_solicitada' => 'decimal:4',
        'cantidad_despachada' => 'decimal:4',
        'cantidad_recibida' => 'decimal:4',
        'created_at' => 'datetime',
    ];

    public function header(): BelongsTo
    {
        return $this->belongsTo(TransferHeader::class, 'transfer_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id');
    }

    public function getVarianzaAttribute(): float
    {
        if (!$this->cantidad_recibida || !$this->cantidad_despachada) {
            return 0;
        }
        
        return (float) ($this->cantidad_recibida - $this->cantidad_despachada);
    }

    public function getVarianzaPorcentajeAttribute(): float
    {
        if (!$this->cantidad_despachada || $this->cantidad_despachada == 0) {
            return 0;
        }
        
        $varianza = $this->getVarianzaAttribute();
        return ($varianza / (float) $this->cantidad_despachada) * 100;
    }

    public function hasVariance(): bool
    {
        return abs($this->getVarianzaAttribute()) > 0.0001;
    }
}
