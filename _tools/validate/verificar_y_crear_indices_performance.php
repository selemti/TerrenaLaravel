<?php
// verificar_y_crear_indices_performance.php
// Script para verificar y crear índices críticos de rendimiento para el reporte de Sales Exceptions

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "🔍 Verificando índices de rendimiento críticos...\n";

try {
    // 1. Verificar si los índices críticos existen
    $critical_indices = [
        'idx_ticket_item_ticket_id',
        'idx_ticket_item_modifier_ticket_item_id', 
        'idx_ticket_payment_ticket_id'
    ];
    
    echo "\n1. VERIFICANDO ÍNDICES CRÍTICOS:\n";
    echo "=============================\n";
    
    foreach ($critical_indices as $index_name) {
        $index_exists = DB::connection('pgsql')->select("
            SELECT EXISTS (
                SELECT FROM pg_indexes 
                WHERE indexname = ?
            ) AS index_exists;
        ", [$index_name]);
        
        $exists = $index_exists[0]->index_exists;
        $status = $exists ? "✅ EXISTE" : "❌ FALTA";
        echo "$status - $index_name\n";
    }
    
    // 2. Crear índices que no existen
    echo "\n2. CREANDO ÍNDICES FALTANTES:\n";
    echo "=============================\n";
    
    $indices_to_create = [
        [
            'name' => 'idx_ticket_item_ticket_id',
            'table' => 'public.ticket_item',
            'column' => 'ticket_id'
        ],
        [
            'name' => 'idx_ticket_item_modifier_ticket_item_id',
            'table' => 'public.ticket_item_modifier',
            'column' => 'ticket_item_id'
        ],
        [
            'name' => 'idx_ticket_payment_ticket_id',
            'table' => 'public.ticket_payment',
            'column' => 'ticket_id'
        ]
    ];
    
    foreach ($indices_to_create as $index_info) {
        $index_exists = DB::connection('pgsql')->select("
            SELECT EXISTS (
                SELECT FROM pg_indexes 
                WHERE indexname = ?
            ) AS index_exists;
        ", [$index_info['name']]);
        
        if (!$index_exists[0]->index_exists) {
            try {
                $sql = "CREATE INDEX IF NOT EXISTS {$index_info['name']} ON {$index_info['table']}({$index_info['column']});";
                DB::connection('pgsql')->statement($sql);
                echo "✅ Índice creado: {$index_info['name']} ON {$index_info['table']}({$index_info['column']})\n";
            } catch (Exception $e) {
                echo "❌ Error creando índice {$index_info['name']}: " . $e->getMessage() . "\n";
            }
        } else {
            echo "ℹ️  Índice ya existe: {$index_info['name']}\n";
        }
    }
    
    // 3. Verificar existencia de tablas relacionadas
    echo "\n3. VERIFICANDO TABLAS RELACIONADAS:\n";
    echo "==================================\n";
    
    $related_tables = [
        'public.ticket_item',
        'public.ticket_item_modifier',
        'public.ticket_payment'  // Esta tabla posiblemente no exista en este sistema
    ];
    
    foreach ($related_tables as $table) {
        $parts = explode('.', $table);
        $schema = $parts[0];
        $table_name = $parts[1];
        
        $table_exists = DB::connection('pgsql')->select("
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = ? AND table_name = ?
            ) AS table_exists;
        ", [$schema, $table_name]);
        
        $exists = $table_exists[0]->table_exists;
        $status = $exists ? "✅" : "❌";
        echo "$status - $table\n";
        
        if ($exists) {
            // Contar registros
            $count_result = DB::connection('pgsql')->select("SELECT COUNT(*) as count FROM $table LIMIT 1;");
            // Nota: Usamos LIMIT 1 porque COUNT(*) podría tardar en tablas grandes
            echo "  - Registro de existencia verificado\n";
        }
    }
    
    // 4. Verificar si la tabla ticket_payment existe, si no, verificar si se llama diferente
    echo "\n4. BUSCANDO TABLAS DE PAGO ALTERNATIVAS:\n";
    echo "========================================\n";
    
    $possible_payment_tables = [
        'public.transactions',  // Posible tabla de transacciones/pagos
        'public.ticket_transaction',
        'public.payments'
    ];
    
    foreach ($possible_payment_tables as $table) {
        $parts = explode('.', $table);
        $schema = $parts[0];
        $table_name = $parts[1];
        
        $table_exists = DB::connection('pgsql')->select("
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = ? AND table_name = ?
            ) AS table_exists;
        ", [$schema, $table_name]);
        
        if ($table_exists[0]->table_exists) {
            echo "✅ Tabla de pago alternativa encontrada: $table\n";
            
            // Verificar si tiene una columna de ticket_id
            $has_ticket_id = DB::connection('pgsql')->select("
                SELECT EXISTS (
                    SELECT FROM information_schema.columns 
                    WHERE table_schema = ? AND table_name = ? AND column_name = 'ticket_id'
                ) AS has_ticket_id;
            ", [$schema, $table_name]);
            
            if ($has_ticket_id[0]->has_ticket_id) {
                echo "  - Tiene columna ticket_id\n";
                
                // Crear índice si no existe
                $index_exists = DB::connection('pgsql')->select("
                    SELECT EXISTS (
                        SELECT FROM pg_indexes 
                        WHERE indexname = 'idx_{$table_name}_ticket_id'
                    ) AS index_exists;
                ", []);
                
                if (!$index_exists[0]->index_exists) {
                    $index_name = "idx_{$table_name}_ticket_id";
                    try {
                        $sql = "CREATE INDEX IF NOT EXISTS {$index_name} ON {$table}(ticket_id);";
                        DB::connection('pgsql')->statement($sql);
                        echo "  - Índice creado: $index_name\n";
                    } catch (Exception $e) {
                        echo "  - Error creando índice {$index_name}: " . $e->getMessage() . "\n";
                    }
                } else {
                    echo "  - Índice ya existente: idx_{$table_name}_ticket_id\n";
                }
            } else {
                echo "  - No tiene columna ticket_id\n";
            }
        }
    }
    
    // 5. Actualizar estadísticas
    echo "\n5. ACTUALIZANDO ESTADÍSTICAS:\n";
    echo "=============================\n";
    
    $tables_to_analyze = [
        'public.ticket',
        'public.ticket_item',
        'public.ticket_item_modifier',
        'public.transactions'  // Usamos transactions en lugar de ticket_payment
    ];
    
    foreach ($tables_to_analyze as $table) {
        try {
            DB::connection('pgsql')->statement("ANALYZE {$table};");
            echo "✅ Estadísticas actualizadas para $table\n";
        } catch (Exception $e) {
            echo "⚠️  Error actualizando estadísticas para $table: " . $e->getMessage() . "\n";
        }
    }
    
    echo "\n✅ VERIFICACIÓN Y ACTUALIZACIÓN DE ÍNDICES COMPLETADA\n";

} catch (Exception $e) {
    echo "❌ Error en la verificación de índices: " . $e->getMessage() . "\n";
}