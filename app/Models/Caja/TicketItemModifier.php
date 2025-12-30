<?php

namespace App\Models\Caja;

use App\Models\Pos\MenuModifier;
use App\Models\Pos\ModifierGroup;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOneThrough;

class TicketItemModifier extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'public.ticket_item_modifier';

    protected $primaryKey = 'id';

    public $timestamps = false;

    protected $casts = [
        'modifier_price' => 'float',
        'subtotal_price' => 'float',
        'total_price' => 'float',
        'modifier_tax_rate' => 'float',
        'info_only' => 'boolean',
        'print_to_kitchen' => 'boolean',
    ];

    protected $guarded = [];

    public function menuModifier(): BelongsTo
    {
        return $this->belongsTo(MenuModifier::class, 'item_id', 'id');
    }

    /**
     * Relación al grupo correcto vía menu_modifier.group_id.
     */
    public function modifierGroup(): HasOneThrough
    {
        return $this->hasOneThrough(
            ModifierGroup::class,
            MenuModifier::class,
            'id',
            'id',
            'item_id',
            'group_id'
        );
    }

    public function getCorrectGroupAttribute(): ?ModifierGroup
    {
        return $this->menuModifier?->modifierGroup;
    }

    public function getIsConsistentAttribute(): bool
    {
        return $this->item_id > 0
            ? ($this->group_id === ($this->correctGroup?->id))
            : true;
    }
}
