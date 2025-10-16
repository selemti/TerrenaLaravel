<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class MenuCategory extends Model
{
    protected $table = 'public.menu_category';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'name', 'translated_name', 'visible', 'beverage', 'sort_order'
    ];
    
    protected $casts = [
        'visible' => 'boolean',
        'beverage' => 'boolean',
    ];
}