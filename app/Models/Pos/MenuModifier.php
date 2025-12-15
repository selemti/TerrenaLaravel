<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MenuModifier extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'public.menu_modifier';

    protected $primaryKey = 'id';

    public $timestamps = false;

    protected $fillable = [
        'name', 'translated_name', 'price', 'extra_price', 'group_id',
        'enable', 'fixed_price', 'print_to_kitchen',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'extra_price' => 'decimal:2',
        'enable' => 'boolean',
        'fixed_price' => 'boolean',
    ];

    public function modifierGroup(): BelongsTo
    {
        return $this->belongsTo(ModifierGroup::class, 'group_id', 'id');
    }
}
