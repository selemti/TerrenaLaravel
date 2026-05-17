<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class PosMenuItemRecipeMapping extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.pos_menu_item_recipe_mapping';

    protected $fillable = [
        'menu_item_id',
        'menu_item_name',
        'recipe_id',
        'porciones_por_orden',
        'activo',
    ];

    protected $casts = [
        'activo' => 'boolean',
        'porciones_por_orden' => 'integer',
    ];
}
