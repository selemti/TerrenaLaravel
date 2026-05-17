<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class PosModifierInvMapping extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.pos_modifier_inv_mapping';

    protected $fillable = [
        'menu_modifier_id',
        'modifier_name_trim',
        'menu_modifier_group_id',
        'menu_modifier_group_name',
        'item_id',
        'qty_por_unidad',
        'uom',
        'qty_source',
        'recipe_id',
        'tipo_efecto',
        'afecta_costo',
        'activo',
    ];

    protected $casts = [
        'qty_por_unidad' => 'decimal:6',
        'afecta_costo' => 'boolean',
        'activo' => 'boolean',
    ];
}
