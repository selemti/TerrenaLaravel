<?php

namespace App\Models\Caja;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SesionCajon extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';
    protected $table = 'sesion_cajon';
    protected $schema = 'selemti'; // Si usas schema explícito, ajusta en conexión
    public $timestamps = true; // Asumiendo created_at/updated_at mapeados a apertura_ts/cierre_ts

    protected $fillable = [
        'id', 'terminal_id', 'cajero_usuario_id', 'apertura_ts', 'cierre_ts',
        'estatus', 'opening_float', 'closing_float', 'skipped_precorte',
    ];

    protected $casts = [
        'apertura_ts' => 'datetime',
        'cierre_ts' => 'datetime',
        'opening_float' => 'decimal:2',
        'closing_float' => 'decimal:2',
    ];

    public function terminal()
    {
        return $this->belongsTo(Terminal::class, 'terminal_id', 'id');
    }

    public function cajero()
    {
        return $this->belongsTo(User::class, 'cajero_usuario_id', 'auto_id'); // Asumiendo users de Floreant
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