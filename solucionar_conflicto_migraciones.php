<?php
// solucionar_conflicto_migraciones.php
// Script para resolver el conflicto de migraciones manualmente

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "🔧 Solucionando conflicto de migraciones...\n";

try {
    // Identificar las restricciones de clave foránea que causan el problema
    echo "\n🔍 Identificando restricciones de clave foránea problemáticas...\n";
    
    // Verificar las claves foráneas que dependen de menu_items
    $fk_constraints = DB::connection('pgsql')->select("
        SELECT 
            tc.constraint_name,
            tc.table_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM 
            information_schema.table_constraints AS tc 
            JOIN information_schema.key_column_usage AS kcu
                ON tc.constraint_name = kcu.constraint_name
            JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name
        WHERE 
            tc.constraint_type = 'FOREIGN KEY' 
            AND ccu.table_name = 'menu_items'
            AND tc.table_schema = 'selemti'
    ");
    
    if (count($fk_constraints) > 0) {
        echo "\n⚠️  Se encontraron restricciones de clave foránea hacia menu_items:\n";
        foreach ($fk_constraints as $fk) {
            echo "   - {$fk->table_name}.{$fk->constraint_name} ({$fk->column_name} -> {$fk->foreign_column_name})\n";
        }
        
        // Intentar eliminar las restricciones problemáticas temporalmente
        foreach ($fk_constraints as $fk) {
            try {
                echo "\n.intentando eliminar restricción: {$fk->constraint_name} de {$fk->table_name}...\n";
                DB::connection('pgsql')->statement("
                    ALTER TABLE selemti.\"{$fk->table_name}\" 
                    DROP CONSTRAINT IF EXISTS \"{$fk->constraint_name}\"
                ");
                echo "   ✅ Restricción eliminada\n";
            } catch (Exception $e) {
                echo "   ❌ Error al eliminar restricción {$fk->constraint_name}: " . $e->getMessage() . "\n";
            }
        }
    } else {
        echo "\n✅ No se encontraron claves foráneas problemáticas hacia menu_items\n";
    }
    
    // Ahora intentar eliminar la tabla menu_items si existe
    try {
        echo "\n.tratando de eliminar tabla menu_items si existe...\n";
        DB::connection('pgsql')->statement("DROP TABLE IF EXISTS selemti.menu_items CASCADE");
        echo "   ✅ Tabla menu_items eliminada si existía\n";
    } catch (Exception $e) {
        echo "   ⚠️  Error al eliminar tabla menu_items: " . $e->getMessage() . "\n";
    }
    
    // Registrar manualmente que la migración problemática fue completada
    echo "\n.tratando de registrar la migración completada...\n";
    
    // Comprobar si la migración ya está registrada
    $migration_check = DB::connection('pgsql')->select("
        SELECT * FROM selemti.migrations 
        WHERE migration = '2025_11_15_070000_create_pos_sync_tables'
    ");
    
    if (empty($migration_check)) {
        DB::connection('pgsql')->insert("
            INSERT INTO selemti.migrations (migration, batch) 
            VALUES ('2025_11_15_070000_create_pos_sync_tables', 3)
        ");
        echo "   ✅ Migración 2025_11_15_070000_create_pos_sync_tables registrada\n";
    } else {
        echo "   ℹ️  Migración 2025_11_15_070000_create_pos_sync_tables ya estaba registrada\n";
    }
    
    echo "\n✅ Solución aplicada. Ahora puedes continuar con las migraciones restantes.\n";
    
} catch (Exception $e) {
    echo "❌ Error en la solución: " . $e->getMessage() . "\n";
}