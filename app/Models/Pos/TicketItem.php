<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class TicketItem extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'public.ticket_item';

    protected $primaryKey = 'id';

    public $timestamps = false;

    protected $fillable = [
        'item_id', 'item_count', 'item_quantity', 'item_name',
        'item_price', 'sub_total', 'total_price', 'ticket_id', 'pg_id',
        'has_modiiers',
    ];

    protected $casts = [
        'item_count' => 'integer',
        'item_quantity' => 'decimal:3',
        'item_price' => 'decimal:2',
        'sub_total' => 'decimal:2',
        'total_price' => 'decimal:2',
        'has_modiiers' => 'boolean',
    ];

    public function ticket()
    {
        return $this->belongsTo(Ticket::class, 'ticket_id');
    }

    public function getHasModifiersAttribute(): bool
    {
        return $this->has_modiiers;
    }

    public function setHasModifiersAttribute(bool $value): void
    {
        $this->attributes['has_modiiers'] = $value;
    }
}
