<?php

namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class RecetaVersion extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.receta_version';

    protected $primaryKey = 'id';

    public $timestamps = false;

    protected $fillable = [
        'receta_id',
        'version',
        'descripcion_cambios',
        'fecha_efectiva',
        'version_publicada',
        'usuario_publicador',
        'fecha_publicacion',
        'created_at',
    ];

    protected $casts = [
        'fecha_efectiva' => 'date',
        'version_publicada' => 'boolean',
        'fecha_publicacion' => 'datetime',
    ];

    public function receta(): BelongsTo
    {
        return $this->belongsTo(Receta::class, 'receta_id', 'id');
    }

    public function detalles(): HasMany
    {
        return $this->hasMany(RecetaDetalle::class, 'receta_version_id');
    }
}
