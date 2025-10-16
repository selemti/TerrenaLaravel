<?php
namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    protected $table = 'items';
    protected $guarded = [];
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = true;

    protected $fillable = [
        'id', 'nombre', 'descripcion', 'categoria_id', 'unidad_medida', 
        'perishable', 'temperatura_min', 'temperatura_max', 'costo_promedio', 
        'activo', 'unidad_medida_id', 'factor_conversion', 'unidad_compra_id', 
        'factor_compra', 'tipo', 'unidad_salida_id'
    ];

    protected $casts = [
        'perishable' => 'boolean',
        'costo_promedio' => 'decimal:2',
        'activo' => 'boolean',
        'factor_conversion' => 'decimal:6',
        'factor_compra' => 'decimal:6',
    ];

    public function uom()       { return $this->belongsTo(Unidad::class, 'unidad_medida_id'); }
    public function uomCompra() { return $this->belongsTo(Unidad::class, 'unidad_compra_id'); }
    public function uomSalida() { return $this->belongsTo(Unidad::class, 'unidad_salida_id'); }
		public function unidadCanonico(){ return $this->belongsTo(Unidad::class, 'unidad_medida_id');}
}



