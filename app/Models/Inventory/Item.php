<?php

namespace App\Models\Inventory;

use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    protected $table = 'selemti.items';
    protected $primaryKey = 'id';
    public $incrementing = false;
    public $timestamps = false;
    protected $keyType = 'string';
}
