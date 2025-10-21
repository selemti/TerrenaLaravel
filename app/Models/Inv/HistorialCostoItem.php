<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class HistorialCostoItem extends Model
{
    protected $table = 'selemti.historial_costos_item';
    public $timestamps = false;

    protected $fillable = [
        'item_id',
        'fecha_efectiva',
        'fecha_registro',
        'costo_anterior',
        'costo_nuevo',
        'tipo_cambio',
        'referencia_id',
        'referencia_tipo',
        'usuario_id',
        'valid_from',
        'valid_to',
        'sys_from',
        'sys_to',
        'costo_wac',
        'costo_peps',
        'costo_ueps',
        'costo_estandar',
        'algoritmo_principal',
        'version_datos',
        'recalculado',
        'fuente_datos',
        'metadata_calculo',
        'created_at',
    ];

    protected $casts = [
        'fecha_efectiva'   => 'date',
        'fecha_registro'   => 'datetime',
        'valid_from'       => 'date',
        'valid_to'         => 'date',
        'sys_from'         => 'datetime',
        'sys_to'           => 'datetime',
        'costo_anterior'   => 'decimal:2',
        'costo_nuevo'      => 'decimal:2',
        'costo_wac'        => 'decimal:4',
        'costo_peps'       => 'decimal:4',
        'costo_ueps'       => 'decimal:4',
        'costo_estandar'   => 'decimal:4',
        'version_datos'    => 'integer',
        'recalculado'      => 'boolean',
        'metadata_calculo' => 'array',
        'created_at'       => 'datetime',
    ];
}
