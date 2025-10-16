<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class TicketItem extends Model
{
    protected $table = 'public.ticket_item';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'item_id', 'item_count', 'item_quantity', 'item_name', 
        'item_price', 'sub_total', 'total_price', 'ticket_id', 'pg_id'
    ];

    protected $casts = [
        'item_count' => 'integer',
        'item_quantity' => 'decimal:3',
        'item_price' => 'decimal:2',
        'sub_total' => 'decimal:2',
        'total_price' => 'decimal:2',
    ];

    public function ticket()
    {
        return $this->belongsTo(Ticket::class, 'ticket_id');
    }
}