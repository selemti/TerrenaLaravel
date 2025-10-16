<?php

namespace App\Models\Caja;

use Illuminate\Database\Eloquent\Model;

class Terminal extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'terminal';  // Schema 'public' asumido en conexión
    public $timestamps = false;

    protected $fillable = ['id', 'name', 'location'];

    public function sesiones()
    {
        return $this->hasMany(SesionCajon::class, 'terminal_id', 'id');
    }
}