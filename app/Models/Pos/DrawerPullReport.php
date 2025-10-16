<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class DrawerPullReport extends Model
{
    protected $table = 'public.drawer_pull_report';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'report_time', 'reg', 'ticket_count', 'begin_cash', 'net_sales', 
        'total_revenue', 'cash_receipt_amount', 'user_id', 'terminal_id'
    ];
    
    protected $casts = [
        'report_time' => 'datetime',
        'total_revenue' => 'decimal:2',
        'begin_cash' => 'decimal:2',
    ];

    public function terminal()
    {
        return $this->belongsTo(Terminal::class, 'terminal_id', 'id');
    }
}