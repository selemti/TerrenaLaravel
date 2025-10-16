<?php
namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class Movimiento extends Model
{
    protected $table = 'mov_inv';
    public $timestamps = false;
    protected $guarded = [];
}
