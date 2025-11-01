<?php

namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RecetaVersion extends Model
{
    use HasFactory;
    protected $table = 'selemti.receta_version';
    protected $primaryKey = 'id';
    public $timestamps = false; // Solo usa created_at

    protected $fillable = [
        'receta_id', 'version', 'descripcion_cambios', 'fecha_efectiva', 
        'version_publicada', 'usuario_publicador', 'fecha_publicacion', 'created_at'
    ];

    protected $casts = [
        'fecha_efectiva' => 'date',
        'version_publicada' => 'boolean',
        'fecha_publicacion' => 'datetime',
    ];

    public function receta()
    {
        return $this->belongsTo(Receta::class, 'receta_id', 'id');
    }
    
    public function detalles()
    {
        return $this->hasMany(RecetaDetalle::class, 'receta_version_id');
    }
}