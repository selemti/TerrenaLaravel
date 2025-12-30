<?php

namespace App\Models\Caja;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Postcorte extends Model
{
    use HasFactory;

    protected $table = 'postcorte';

    protected $schema = 'selemti';

    public $timestamps = true;

    protected $fillable = [
        'sesion_id',
        'sistema_efectivo_esperado', 'declarado_efectivo', 'diferencia_efectivo', 'veredicto_efectivo',
        'sistema_tarjetas', 'declarado_tarjetas', 'diferencia_tarjetas', 'veredicto_tarjetas',
        'sistema_transferencias', 'declarado_transferencias', 'diferencia_transferencias', 'veredicto_transferencias',

        // Nuevos campos de descuentos y ventas
        'total_ventas_brutas', 'total_ventas_netas',
        'total_descuentos_drawer', 'total_descuentos_reales', 'diferencia_descuentos',
        'porcentaje_error_descuentos', 'calidad_reporte_descuentos',

        // Campos existentes
        'notas', 'validado', 'validado_por', 'validado_en', 'creado_por',
        'requiere_aprobacion', 'aprobado_por', 'aprobado_en',
        'motivo_irregular', 'rechazado', 'motivo_rechazo'
    ];

    protected $casts = [
        'sistema_efectivo_esperado' => 'decimal:2',
        'declarado_efectivo' => 'decimal:2',
        'diferencia_efectivo' => 'decimal:2',
        'sistema_tarjetas' => 'decimal:2',
        'declarado_tarjetas' => 'decimal:2',
        'diferencia_tarjetas' => 'decimal:2',
        'sistema_transferencias' => 'decimal:2',
        'declarado_transferencias' => 'decimal:2',
        'diferencia_transferencias' => 'decimal:2',

        // Nuevos campos de descuentos y ventas
        'total_ventas_brutas' => 'decimal:2',
        'total_ventas_netas' => 'decimal:2',
        'total_descuentos_drawer' => 'decimal:2',
        'total_descuentos_reales' => 'decimal:2',
        'diferencia_descuentos' => 'decimal:2',
        'porcentaje_error_descuentos' => 'decimal:2',

        // Campos booleanos y fechas
        'validado' => 'boolean',
        'requiere_aprobacion' => 'boolean',
        'rechazado' => 'boolean',
        'validado_en' => 'datetime',
        'aprobado_en' => 'datetime',
    ];

    public function sesion()
    {
        return $this->belongsTo(SesionCajon::class, 'sesion_id', 'id');
    }

    // Métodos para métricas de descuentos
    public function getPorcentajeDescuentoDrawerSobreVentasAttribute()
    {
        if ($this->total_ventas_brutas > 0) {
            return round(($this->total_descuentos_drawer / $this->total_ventas_brutas) * 100, 2);
        }
        return 0;
    }

    public function getPorcentajeDescuentoRealesSobreVentasAttribute()
    {
        if ($this->total_ventas_brutas > 0) {
            return round(($this->total_descuentos_reales / $this->total_ventas_brutas) * 100, 2);
        }
        return 0;
    }

    public function getNivelAlertaDescuentosAttribute()
    {
        switch ($this->calidad_reporte_descuentos) {
            case 'EXCELENTE':
            case 'BUENO':
                return 'VERDE';
            case 'ACEPTABLE':
                return 'AMARILLO';
            default:
                return 'ROJO';
        }
    }

    public function tieneErroresCriticosDescuentos()
    {
        return in_array($this->calidad_reporte_descuentos, ['REVISAR', 'CRITICO']);
    }

    // Scope para filtrar por calidad de descuentos
    public function scopeConErroresCriticos($query)
    {
        return $query->whereIn('calidad_reporte_descuentos', ['REVISAR', 'CRITICO']);
    }

    public function scopeConCalidadDescuentos($query, $calidad)
    {
        return $query->where('calidad_reporte_descuentos', $calidad);
    }
}
