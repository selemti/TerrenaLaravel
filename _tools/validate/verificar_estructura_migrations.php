<?php
// verificar_estructura_migrations.php
// Verificar la estructura de la tabla de migraciones

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "🔍 Verificando estructura de la tabla 'migrations'...\n";

try {
    // Verificar columnas de la tabla migrations
    $columns = DB::connection('pgsql')->select("
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_schema = 'selemti' 
        AND table_name = 'migrations'
        ORDER BY ordinal_position
    ");
    
    echo "\n📋 Estructura actual de la tabla migrations:\n";
    echo "--------------------------------------\n";
    foreach ($columns as $col) {
        echo "- {$col->column_name}: {$col->data_type} (" . ($col->is_nullable === 'YES' ? 'nullable' : 'not nullable') . ")\n";
    }
    
    // Verificar si tiene created_at
    $has_created_at = false;
    $has_updated_at = false;
    foreach ($columns as $col) {
        if ($col->column_name === 'created_at') {
            $has_created_at = true;
        }
        if ($col->column_name === 'updated_at') {
            $has_updated_at = true;
        }
    }
    
    echo "\n🔍 Columnas especiales:\n";
    echo "- created_at: " . ($has_created_at ? 'SI' : 'NO') . "\n";
    echo "- updated_at: " . ($has_updated_at ? 'SI' : 'NO') . "\n";
    
    // Verificar migraciones existentes
    $migration_count = DB::connection('pgsql')->select("
        SELECT COUNT(*) as count FROM selemti.migrations
    ");
    
    echo "\n📊 Total de migraciones registradas: {$migration_count[0]->count}\n";
    
    // Obtener las últimas migraciones
    $recent_migrations = DB::connection('pgsql')->select("
        SELECT * FROM selemti.migrations ORDER BY id DESC LIMIT 5
    ");
    
    echo "\nÚltimas 5 migraciones registradas:\n";
    foreach ($recent_migrations as $mig) {
        echo "- ID: {$mig->id}, Migration: {$mig->migration}, Batch: {$mig->batch}\n";
    }
    
    echo "\n✅ Verificación completada\n";

} catch (Exception $e) {
    echo "❌ Error al verificar estructura: " . $e->getMessage() . "\n";
}