<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ModifierGroup extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'public.menu_modifier_group';

    protected $primaryKey = 'id';

    public $timestamps = false;

    protected $fillable = [
        'name',
        'translated_name',
        'sort_order',
    ];

    public function modifiers(): HasMany
    {
        return $this->hasMany(MenuModifier::class, 'group_id', 'id');
    }
}
