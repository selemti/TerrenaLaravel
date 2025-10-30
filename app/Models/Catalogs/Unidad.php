<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;

/**
 * Model: Unidad (Unit of Measure)
 *
 * Canonical table: selemti.cat_unidades
 *
 * @property int $id
 * @property string $clave Unique code (KG, L, PZ)
 * @property string $nombre Descriptive name
 * @property bool $activo Active status
 * @property \Carbon\Carbon|null $created_at
 * @property \Carbon\Carbon|null $updated_at
 */
class Unidad extends Model
{
    /**
     * PostgreSQL connection
     */
    protected $connection = 'pgsql';

    /**
     * Canonical table (normalización 2025-10-29)
     * Legacy view: selemti.unidades_medida (deprecated, maps to cat_unidades)
     */
    protected $table = 'selemti.cat_unidades';

    protected $primaryKey = 'id';
    public $incrementing = true;
    protected $keyType = 'int';
    public $timestamps = true;

    protected $fillable = [
        'clave',   // VARCHAR(16) UNIQUE NOT NULL
        'nombre',  // VARCHAR(64) NOT NULL
        'activo',  // boolean DEFAULT true
    ];

    protected $casts = [
        'activo' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Boot: Enforce uppercase clave
     */
    protected static function boot()
    {
        parent::boot();

        static::saving(function ($model) {
            if (isset($model->clave)) {
                $model->clave = strtoupper($model->clave);
            }
        });
    }

    // =====================================================
    // RELATIONSHIPS
    // =====================================================

    public function conversionesOrigen()
    {
        return $this->hasMany(UomConversion::class, 'origen_id', 'id');
    }

    public function conversionesDestino()
    {
        return $this->hasMany(UomConversion::class, 'destino_id', 'id');
    }

    // =====================================================
    // SCOPES
    // =====================================================

    public function scopeActivas($query)
    {
        return $query->where('activo', true);
    }

    public function scopePorClave($query, string $clave)
    {
        return $query->where('clave', strtoupper($clave));
    }

    public function scopeBase($query)
    {
        return $query->whereIn('clave', ['KG', 'L', 'PZ']);
    }

    // =====================================================
    // HELPERS
    // =====================================================

    public function isBase(): bool
    {
        return in_array($this->clave, ['KG', 'L', 'PZ']);
    }

    public function getFactorTo($destinoClave, string $preferScope = 'any'): ?float
    {
        if (is_string($destinoClave)) {
            $destino = self::porClave($destinoClave)->first();
            if (!$destino) {
                return null;
            }
            $destinoId = $destino->id;
        } else {
            $destinoId = $destinoClave;
        }

        $query = $this->conversionesOrigen()->where('destino_id', $destinoId);

        if ($preferScope !== 'any') {
            $query->where('scope', $preferScope);
        } else {
            $query->orderByRaw("CASE WHEN scope = 'global' THEN 1 ELSE 2 END");
        }

        $conversion = $query->first();

        return $conversion ? (float) $conversion->factor : null;
    }
}
