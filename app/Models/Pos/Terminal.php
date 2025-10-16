<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class Terminal extends Model
{
    protected $table = 'public.terminal'; // **IMPORTANTE: Prefijo public.**
    protected $primaryKey = 'id';
    public $timestamps = false; // No tiene created_at/updated_at

    protected $fillable = [
        'name', 'terminal_key', 'opening_balance', 'current_balance', 
        'has_cash_drawer', 'in_use', 'active', 'location', 'floor_id', 'assigned_user'
    ];
    
    protected $casts = [
        'opening_balance' => 'decimal:2',
        'current_balance' => 'decimal:2',
        'has_cash_drawer' => 'boolean',
        'in_use' => 'boolean',
        'active' => 'boolean',
    ];
}