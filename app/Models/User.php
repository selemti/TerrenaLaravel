<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasFactory, Notifiable, HasRoles;

    protected $guard_name = 'web';
    protected $connection = 'pgsql';
    protected $table = 'selemti.users';
    protected $primaryKey = 'id';
    
    protected $fillable = [
        'username',
        'password_hash',
        'remember_token',
        'email',
        'nombre_completo',
        'sucursal_id',
        'activo',
        'fecha_ultimo_login',
        'intentos_login',
        'bloqueado_hasta',
        'created_at',
        'updated_at',
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
        // Nota: 'password_hash' debe manejarse externamente, no con 'hashed'.
    ];
    
    /**
     * Define la columna que contiene el hash de la contraseña para Laravel Auth.
     */
    public function getAuthPassword()
    {
        return $this->password_hash;
    }

    public function getNameAttribute(): string
    {
        return $this->attributes['nombre_completo']
            ?? $this->attributes['username']
            ?? $this->attributes['email']
            ?? '';
    }

    public function getEmailAttribute($value): ?string
    {
        return $value ?: null;
    }

    public function setEmailAttribute($value): void
    {
        $this->attributes['email'] = $value ? strtolower(trim($value)) : null;
    }

    public function legacyRoles()
    {
        return $this->hasMany(Core\UserRole::class, 'user_id');
    }
}