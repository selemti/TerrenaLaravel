<?php
/**
 * Script para extraer información de la base de datos PostgreSQL
 * de TerrenaLaravel
 */

// Cargar configuración de Laravel para usar su configuración de base de datos
require_once __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

echo "Extrayendo información de la base de datos TerrenaLaravel\n";
echo str_repeat("=", 60) . "\n\n";

try {
    // 1. Verificar conexión
    echo "✓ Conexión a la base de datos: ";
    $pdo = DB::connection()->getPdo();
    echo "Conectado a " . $pdo->getAttribute(PDO::ATTR_SERVER_VERSION) . "\n\n";
    
    // 2. Listar todas las tablas en el esquema selemti
    echo "📋 TABLAS EN EL ESQUEMA SELEMTI:\n";
    echo str_repeat("-", 40) . "\n";
    
    $tables = DB::select("
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'selemti' 
        ORDER BY table_name
    ");
    
    foreach ($tables as $table) {
        $rowCount = DB::selectOne("SELECT COUNT(*) as count FROM selemti.{$table->table_name}");
        echo sprintf("- %s (registros: %d)\n", $table->table_name, $rowCount->count);
    }
    
    echo "\n";
    
    // 3. Ver vistas disponibles
    echo "👁️ VISTAS EN EL ESQUEMA SELEMTI:\n";
    echo str_repeat("-", 40) . "\n";
    
    $views = DB::select("
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'selemti' 
        ORDER BY table_name
    ");
    
    foreach ($views as $view) {
        echo "- " . $view->table_name . "\n";
    }
    
    echo "\n";
    
    // 4. Información sobre tablas importantes
    echo "📊 TABLAS PRINCIPALES:\n";
    echo str_repeat("-", 40) . "\n";
    
    $importantTables = [
        'items' => ['id', 'nombre', 'categoria_id', 'costo_promedio', 'activo'],
        'receta_cab' => ['id', 'nombre_plato', 'categoria_plato', 'costo_standard_porcion'],
        'receta_version' => ['id', 'receta_id', 'version', 'version_publicada'],
        'receta_det' => ['id', 'receta_version_id', 'item_id', 'cantidad'],
        'inventory_batch' => ['id', 'item_id', 'cantidad_actual', 'lote_proveedor'],
        'mov_inv' => ['id', 'item_id', 'qty', 'tipo', 'ref_tipo'],
        'production_orders' => ['id', 'recipe_id', 'qty_programada', 'estado'],
        'selemti.users' => ['id', 'username', 'nombre_completo', 'activo']
    ];
    
    foreach ($importantTables as $tableName => $columns) {
        echo "\nTabla: $tableName\n";
        try {
            $count = DB::selectOne("SELECT COUNT(*) as total FROM selemti." . str_replace('selemti.', '', $tableName));
            echo "  Registros: {$count->total}\n";
            
            // Obtener algunos registros de ejemplo
            $sample = DB::select("SELECT " . implode(', ', $columns) . " FROM selemti." . str_replace('selemti.', '', $tableName) . " LIMIT 3");
            foreach ($sample as $row) {
                echo "  " . json_encode((array)$row) . "\n";
            }
        } catch (Exception $e) {
            echo "  Error al leer: " . $e->getMessage() . "\n";
        }
    }
    
    echo "\n";
    
    // 5. Ver funciones y procedimientos
    echo "⚙️ FUNCIONES Y PROCEDIMIENTOS EN SELEMTI:\n";
    echo str_repeat("-", 40) . "\n";
    
    $functions = DB::select("
        SELECT routine_name, routine_type
        FROM information_schema.routines
        WHERE routine_schema = 'selemti'
        ORDER BY routine_type, routine_name
    ");
    
    foreach ($functions as $function) {
        echo "- {$function->routine_type}: {$function->routine_name}\n";
    }
    
    echo "\n";
    
    // 6. Ver triggers
    echo " 🔔 TRIGGERS EN SELEMTI:\n";
    echo str_repeat("-", 40) . "\n";
    
    $triggers = DB::select("
        SELECT trigger_name, event_manipulation, event_object_table
        FROM information_schema.triggers
        WHERE trigger_schema = 'selemti'
        ORDER BY event_object_table, trigger_name
    ");
    
    foreach ($triggers as $trigger) {
        echo "- {$trigger->trigger_name} ({$trigger->event_manipulation} en {$trigger->event_object_table})\n";
    }
    
    echo "\n";
    echo str_repeat("=", 60) . "\n";
    echo "✅ Información extraída exitosamente\n";

} catch (Exception $e) {
    echo "❌ Error de conexión: " . $e->getMessage() . "\n";
}