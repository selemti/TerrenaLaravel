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

    protected $table = 'selemti.traspaso_det';

    protected $primaryKey = 'id';

    protected $fillable = [
        'traspaso_id',
        'item_id',
        'qty',
        'um_id',
        'batch_id',
        'cantidad_despachada',
        'cantidad_recibida',
    ];

    protected $casts = [
        'qty' => 'decimal:6',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function header(): BelongsTo
    {
        return $this->belongsTo(TransferHeader::class, 'traspaso_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id');
    }

    public function getVarianzaAttribute(): float
    {
        if (! $this->cantidad_recibida || ! $this->cantidad_despachada) {
            return 0;
        }

        return (float) ($this->cantidad_recibida - $this->cantidad_despachada);
    }

    public function getVarianzaPorcentajeAttribute(): float
    {
        if (! $this->cantidad_despachada || $this->cantidad_despachada == 0) {
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
