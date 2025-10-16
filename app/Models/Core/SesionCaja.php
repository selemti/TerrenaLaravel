<?php

namespace App\Models\Core;

use Illuminate\Database\Eloquent\Model;
use App\Models\Pos\Terminal;

class SesionCaja extends Model
{
    protected $table = 'sesion_cajon'; // Asume DB_SCHEMA=selemti
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'sucursal', 'terminal_id', 'terminal_nombre', 'cajero_usuario_id', 
        'apertura_ts', 'cierre_ts', 'estatus', 'opening_float', 'closing_float',
        'dah_evento_id', 'skipped_precorte'
    ];

    protected $casts = [
        'apertura_ts' => 'datetime',
        'cierre_ts' => 'datetime',
        'opening_float' => 'decimal:2',
        'closing_float' => 'decimal:2',
        'skipped_precorte' => 'boolean',
    ];

    public function terminal()
    {
        return $this->belongsTo(Terminal::class, 'terminal_id', 'id');
    }
}