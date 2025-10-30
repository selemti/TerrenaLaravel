<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;

/**
 * Model: UomConversion
 *
 * Canonical table: selemti.cat_uom_conversion
 *
 * @property int $id
 * @property int $origen_id
 * @property int $destino_id
 * @property float $factor
 * @property bool $is_exact
 * @property string $scope 'global' or 'house'
 * @property string|null $notes
 * @property \Carbon\Carbon|null $created_at
 * @property \Carbon\Carbon|null $updated_at
 */
class UomConversion extends Model
{
    /**
     * PostgreSQL connection
     */
    protected $connection = 'pgsql';

    /**
     * Canonical table (normalización 2025-10-29)
     */
    protected $table = 'selemti.cat_uom_conversion';

    protected $primaryKey = 'id';
    public $incrementing = true;
    public $timestamps = true;

    protected $fillable = [
        'origen_id',
        'destino_id',
        'factor',
        'is_exact',
        'scope',
        'notes',
    ];

    protected $casts = [
        'origen_id' => 'integer',
        'destino_id' => 'integer',
        'factor' => 'decimal:6',
        'is_exact' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // =====================================================
    // RELATIONSHIPS
    // =====================================================

    public function origen()
    {
        return $this->belongsTo(Unidad::class, 'origen_id', 'id');
    }

    public function destino()
    {
        return $this->belongsTo(Unidad::class, 'destino_id', 'id');
    }

    // =====================================================
    // SCOPES
    // =====================================================

    public function scopeExactas($query)
    {
        return $query->where('is_exact', true);
    }

    public function scopeAproximadas($query)
    {
        return $query->where('is_exact', false);
    }

    public function scopeGlobal($query)
    {
        return $query->where('scope', 'global');
    }

    public function scopeHouse($query)
    {
        return $query->where('scope', 'house');
    }

    public function scopeEntre($query, string $origenClave, string $destinoClave)
    {
        return $query->whereHas('origen', function ($q) use ($origenClave) {
            $q->where('clave', strtoupper($origenClave));
        })->whereHas('destino', function ($q) use ($destinoClave) {
            $q->where('clave', strtoupper($destinoClave));
        });
    }

    // =====================================================
    // HELPERS
    // =====================================================

    public function apply(float $value): float
    {
        return $value * (float) $this->factor;
    }

    public function getInverseFactor(): float
    {
        return 1.0 / (float) $this->factor;
    }

    public function isExact(): bool
    {
        return $this->is_exact === true;
    }

    public function isGlobal(): bool
    {
        return $this->scope === 'global';
    }
}
