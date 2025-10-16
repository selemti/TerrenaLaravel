<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class DrawerHistory extends Model
{
    protected $table = 'public.drawer_assigned_history';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'time', 'operation', 'a_user'
    ];

    protected $casts = [
        'time' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(UsuarioPos::class, 'a_user', 'auto_id');
    }
}