<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InventoryCount extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.inventory_counts';
    protected $guarded = [];
    protected $primaryKey = 'id';
    public $incrementing = true;
    protected $keyType = 'int';
    public $timestamps = true;

    protected $fillable = [
        'sucursal_id',
        'estado',
        'programado_para',
        'iniciado_en',
        'cerrado_en',
        'notas',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'programado_para' => 'datetime',
        'iniciado_en' => 'datetime',
        'cerrado_en' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function lines()
    {
        return $this->hasMany(InventoryCountLine::class, 'inventory_count_id', 'id');
    }
}