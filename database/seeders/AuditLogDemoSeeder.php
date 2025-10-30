<?php

namespace Database\Seeders;

use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AuditLogDemoSeeder extends Seeder
{
    /**
     * Poblar la tabla selemti.audit_log con datos de demostración
     * para pruebas del dashboard /audit/logs.
     */
    public function run(): void
    {
        $now = Carbon::now();

        $entries = [
            [
                'timestamp' => $now->copy()->subHours(4),
                'user_id' => 7, // gerente_almacen
                'accion' => 'TRANSFER_SHIP',
                'entidad' => 'transfer',
                'entidad_id' => 10234,
                'motivo' => 'Salida programada hacia Sucursal Centro',
                'evidencia_url' => 'https://cdn.terrena.mx/audit/transfer_ship_10234.jpg',
                'payload_json' => json_encode([
                    'origen' => 'CEDIS Norte',
                    'destino' => 'Sucursal Centro',
                    'folio' => 'TRF-2025-00123',
                    'transportista' => 'Logística Terrena',
                    'palets' => 3,
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
            [
                'timestamp' => $now->copy()->subHours(3)->addMinutes(15),
                'user_id' => 12, // cajero_cafeteria que recibe
                'accion' => 'TRANSFER_RECEIVE',
                'entidad' => 'transfer',
                'entidad_id' => 10234,
                'motivo' => 'Transferencia recibida sin incidencias',
                'evidencia_url' => 'https://cdn.terrena.mx/audit/transfer_receive_10234.jpg',
                'payload_json' => json_encode([
                    'destino' => 'Sucursal Centro',
                    'folio' => 'TRF-2025-00123',
                    'palets_recibidos' => 3,
                    'observaciones' => 'Sellos intactos',
                    'requires_investigation' => false,
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
            [
                'timestamp' => $now->copy()->subHours(2)->addMinutes(40),
                'user_id' => 7,
                'accion' => 'TRANSFER_RECEIVE',
                'entidad' => 'transfer',
                'entidad_id' => 10258,
                'motivo' => 'Diferencias al recibir transferencia nocturna',
                'evidencia_url' => 'https://cdn.terrena.mx/audit/transfer_receive_10258.jpg',
                'payload_json' => json_encode([
                    'destino' => 'Sucursal Reforma',
                    'folio' => 'TRF-2025-00131',
                    'palets_recibidos' => 2,
                    'observaciones' => 'Faltan 2 cajas de MP-LAC-00012',
                    'differences' => [
                        [
                            'codigo' => 'MP-LAC-00012',
                            'esperado' => 12,
                            'recibido' => 10,
                            'comentario' => 'derrame durante traslado',
                        ],
                    ],
                    'requires_investigation' => true,
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
            [
                'timestamp' => $now->copy()->subHours(2),
                'user_id' => 7,
                'accion' => 'INVENTORY_ADJUST',
                'entidad' => 'inventory_adjustment',
                'entidad_id' => 554,
                'motivo' => 'Ajuste por caducidad de lácteos',
                'evidencia_url' => 'https://cdn.terrena.mx/audit/inventory_adjust_554.jpg',
                'payload_json' => json_encode([
                    'almacen' => 'Sucursal Centro',
                    'categoria' => 'Perecederos',
                    'items' => [
                        ['codigo' => 'MP-LAC-00008', 'cantidad' => -4, 'motivo' => 'caducado'],
                        ['codigo' => 'MP-LAC-00015', 'cantidad' => -2, 'motivo' => 'mal olor'],
                    ],
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
            [
                'timestamp' => $now->copy()->subHours(1)->addMinutes(30),
                'user_id' => 7,
                'accion' => 'RECEPTION_POST',
                'entidad' => 'purchase_reception',
                'entidad_id' => 8815,
                'motivo' => 'Recepción de lácteos proveedor Lácteos del Bajío',
                'evidencia_url' => 'https://cdn.terrena.mx/audit/reception_post_8815.pdf',
                'payload_json' => json_encode([
                    'proveedor' => 'Lácteos del Bajío',
                    'po' => 'OC-2025-00098',
                    'documento' => 'remisión 3845',
                    'tolerancia_fuera' => false,
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
            [
                'timestamp' => $now->copy()->subHour(),
                'user_id' => 7,
                'accion' => 'RECEPTION_POST',
                'entidad' => 'purchase_reception',
                'entidad_id' => 8822,
                'motivo' => 'Recepción con merma por golpe en pallet',
                'evidencia_url' => 'https://cdn.terrena.mx/audit/reception_post_8822.jpg',
                'payload_json' => json_encode([
                    'proveedor' => 'Verduras Frescas SA',
                    'po' => 'OC-2025-00102',
                    'documento' => 'remisión VF-2211',
                    'tolerancia_fuera' => true,
                    'differences' => [
                        [
                            'codigo' => 'MP-VER-00044',
                            'esperado' => 20,
                            'recibido' => 17,
                            'comentario' => 'daño en caja durante traslado',
                        ],
                    ],
                    'requires_investigation' => true,
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
            [
                'timestamp' => $now->copy()->subMinutes(45),
                'user_id' => 7,
                'accion' => 'PRODUCTION_POST_BATCH',
                'entidad' => 'production_batch',
                'entidad_id' => 3304,
                'motivo' => 'Producción de salsa verde lote matutino',
                'evidencia_url' => 'https://cdn.terrena.mx/audit/production_post_3304.jpg',
                'payload_json' => json_encode([
                    'receta' => 'Salsa verde base',
                    'lote' => 'PRD-2025-02-15-01',
                    'rendimiento_litros' => 18.5,
                    'merma_pct' => 3.2,
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
            [
                'timestamp' => $now->copy()->subMinutes(30),
                'user_id' => 12,
                'accion' => 'POS_REPROCESS',
                'entidad' => 'pos_ticket',
                'entidad_id' => 451223,
                'motivo' => 'Reproceso por ticket duplicado en POS',
                'evidencia_url' => 'https://cdn.terrena.mx/audit/pos_reprocess_451223.pdf',
                'payload_json' => json_encode([
                    'ticket_original' => 'TCK-451223',
                    'ticket_reprocesado' => 'TCK-451223-R1',
                    'razon' => 'duplicado por falla en pinpad',
                    'monto' => 184.50,
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
            [
                'timestamp' => $now->copy()->subMinutes(25),
                'user_id' => 1,
                'accion' => 'INSUMO_CREATE',
                'entidad' => 'insumo',
                'entidad_id' => 912,
                'motivo' => 'Alta de envase biodegradable 500ml',
                'evidencia_url' => 'https://cdn.terrena.mx/audit/insumo_create_912.png',
                'payload_json' => json_encode([
                    'codigo' => 'EM-ENV-00042',
                    'categoria_codigo' => 'EM',
                    'subcategoria_codigo' => 'ENV',
                    'nombre' => 'Vaso biodegradable 500ml',
                    'um_id' => 12,
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
            [
                'timestamp' => $now->copy()->subMinutes(12),
                'user_id' => 1, // soporte
                'accion' => 'USER_DISABLE',
                'entidad' => 'user',
                'entidad_id' => 18,
                'motivo' => 'Suspensión temporal por investigación interna',
                'evidencia_url' => null,
                'payload_json' => json_encode([
                    'target_user_id' => 18,
                    'new_status' => 'DISABLED',
                    'requires_investigation' => true,
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
            [
                'timestamp' => $now->copy()->subMinutes(5),
                'user_id' => 1,
                'accion' => 'USER_ENABLE',
                'entidad' => 'user',
                'entidad_id' => 18,
                'motivo' => 'Reactivación tras cierre de investigación',
                'evidencia_url' => null,
                'payload_json' => json_encode([
                    'target_user_id' => 18,
                    'new_status' => 'ENABLED',
                    'comentario' => 'Investigación cerrada sin hallazgos',
                ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            ],
        ];

        DB::connection('pgsql')->table('audit_log')->insert($entries);
    }
}
