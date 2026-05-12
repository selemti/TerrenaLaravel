<?php

namespace App\Models\Caja;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SesionCajon extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';

    protected $table = 'selemti.sesion_cajon';

    public $timestamps = true;

    protected $fillable = [
        'id', 'terminal_id', 'cajero_usuario_id', 'sucursal',
        'apertura_ts', 'cierre_ts', 'estatus',
        'opening_float', 'closing_float', 'skipped_precorte',
        'dah_evento_id',
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

    public function cajero()
    {
        return $this->belongsTo(User::class, 'cajero_usuario_id');
    }

    public function precorte()
    {
        return $this->hasOne(Precorte::class, 'sesion_id', 'id');
    }

    public function postcorte()
    {
        return $this->hasOne(Postcorte::class, 'sesion_id', 'id');
    }
}
