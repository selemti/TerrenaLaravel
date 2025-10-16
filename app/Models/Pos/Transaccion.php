<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class Transaccion extends Model
{
    protected $table = 'public.transactions';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'payment_type', 'transaction_time', 'amount', 'tips_amount', 
        'transaction_type', 'voided', 'terminal_id', 'ticket_id', 'user_id'
    ];

    protected $casts = [
        'transaction_time' => 'datetime',
        'amount' => 'decimal:2',
        'tips_amount' => 'decimal:2',
        'voided' => 'boolean',
    ];
}