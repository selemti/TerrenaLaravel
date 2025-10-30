<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Modelo Eloquent para la tabla de auditoría operacional
 * 
 * Registra todas las acciones sensibles del sistema para trazabilidad completa
 */
class AuditLog extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.audit_log';
    protected $primaryKey = 'id';
    
    public $timestamps = false;

    protected $fillable = [
        'timestamp',
        'user_id',
        'accion',
        'entidad',
        'entidad_id',
        'motivo',
        'evidencia_url',
        'payload_json',
    ];

    protected $casts = [
        'timestamp' => 'datetime',
        'payload_json' => 'array',
    ];

    /**
     * Usuario que realizó la acción
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Obtener el nombre amigable del módulo basado en la entidad
     */
    public function getModuleNameAttribute(): string
    {
        $entityMap = [
            'recepcion' => 'Inventario',
            'transferencia' => 'Transferencias',
            'ticket_pos' => 'POS',
            'caja_chica' => 'Caja Chica',
            'receta' => 'Recetas',
            'produccion' => 'Producción',
            'batch' => 'Producción',
            'inventario' => 'Inventario',
            'item' => 'Inventario',
        ];

        return $entityMap[$this->entidad] ?? ucfirst(str_replace('_', ' ', $this->entidad));
    }

    /**
     * Obtener descripción amigable de la entidad afectada
     */
    public function getEntityDescriptionAttribute(): string
    {
        $entityType = $this->entidad;
        $entityId = $this->entidad_id;

        if (!$entityType || !$entityId) {
            return '—';
        }

        // Formato amigable para mostrar en la tabla
        $displayNameMap = [
            'recepcion' => 'recepción',
            'transferencia' => 'transferencia',
            'ticket_pos' => 'ticket POS',
            'caja_chica' => 'caja chica',
            'receta' => 'receta',
            'produccion' => 'producción',
            'batch' => 'batch',
            'inventario' => 'inventario',
            'item' => 'item',
        ];

        $displayName = $displayNameMap[$entityType] ?? $entityType;
        return "{$displayName} #{$entityId}";
    }
}