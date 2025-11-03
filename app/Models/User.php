<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasRoles;

    protected $guard_name = 'web';
    protected $connection = 'pgsql';
    protected $table = 'selemti.users';
    protected $primaryKey = 'id';

    // La tabla selemti.users usa 'username' y 'password_hash' en lugar de 'name' y 'password'
    protected $fillable = [
        'username',
        'password_hash',
        'email',
        'nombre_completo',
        'sucursal_id',
        'activo',
        'fecha_ultimo_login',
        'intentos_login',
        'bloqueado_hasta',
    ];

    /**
     * The attributes that should be hidden for serialization.
     */
    protected $hidden = [
        'password_hash',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     */
    protected $casts = [
        'activo' => 'boolean',
        'fecha_ultimo_login' => 'datetime',
        'bloqueado_hasta' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'intentos_login' => 'integer',
    ];

    /**
     * Get the password for the user.
     * Laravel espera 'password' pero la tabla usa 'password_hash'
     */
    public function getAuthPassword()
    {
        return $this->password_hash;
    }

    /**
     * Accessor para compatibilidad con código que use 'name'
     */
    public function getNameAttribute()
    {
        return $this->username ?? $this->nombre_completo;
    }

    public function legacyRoles()
    {
        return $this->hasMany(Core\UserRole::class, 'user_id');
    }
}