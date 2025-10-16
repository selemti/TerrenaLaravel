<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;
use App\Models\Rec\Receta;

class MenuItem extends Model
{
    protected $table = 'public.menu_item'; // **IMPORTANTE: Prefijo public.**
    protected $primaryKey = 'id';
    public $timestamps = false;
    
    protected $fillable = [
     'name', 'description', 'price', 'group_id', 'visible', 'recepie', // recepie es la FK a la receta
        'default_group_id', 'sort_order'
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'visible' => 'boolean',
				'kitchen_display' => 'boolean', // Si existe esta columna
    ];

    public function selemtiReceta()
    {
        // Asume que la columna 'recepie' guarda el ID de la tabla selemti.receta_cab
        return $this->belongsTo(Receta::class, 'recepie', 'id'); 
    }
		    // Relación con la Categoría del POS
    public function category()
    {
        return $this->belongsTo(MenuCategory::class, 'group_id');
    }
}