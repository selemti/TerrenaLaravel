<?php

namespace App\Models\Core;

use Illuminate\Database\Eloquent\Model;

class UserRole extends Model
{
    protected $table = 'selemti.user_roles';
    public $timestamps = false;
    protected $primaryKey = ['user_id', 'role_id'];
    public $incrementing = false;
    
    protected $fillable = [
        'user_id', 'role_id', 'assigned_at', 'assigned_by'
    ];

    protected $casts = [
        'assigned_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(\App\Models\User::class, 'user_id');
    }
}