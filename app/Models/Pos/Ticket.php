<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class Ticket extends Model
{
    protected $table = 'public.ticket';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'global_id', 'create_date', 'closing_date', 'paid', 'voided', 
        'sub_total', 'total_price', 'terminal_id', 'owner_id', 
        'folio_date', 'branch_key', 'daily_folio'
    ];

    protected $casts = [
        'create_date' => 'datetime',
        'closing_date' => 'datetime',
        'paid' => 'boolean',
        'voided' => 'boolean',
        'sub_total' => 'decimal:2',
        'total_price' => 'decimal:2',
        'folio_date' => 'date',
    ];
}