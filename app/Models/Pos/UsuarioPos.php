<?php

namespace App\Models\Pos;

use Illuminate\Database\Eloquent\Model;

class UsuarioPos extends Model
{
    protected $table = 'public.users'; 
    protected $primaryKey = 'auto_id'; // Clave primaria es auto_id
    public $timestamps = false;

    protected $fillable = [
        'user_id', 'user_pass', 'first_name', 'last_name', 'active', 'shift_id', 'currentterminal', 'n_user_type'
    ];

    protected $casts = [
        'active' => 'boolean',
        'clocked_in' => 'boolean',
    ];
}