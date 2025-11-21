<?php

namespace App\Models\Inventory;

use Illuminate\Database\Eloquent\Model;

class ItemCategory extends Model
{
    protected $table = 'item_categories';
    protected $guarded = [];
    public $timestamps = false;
}
