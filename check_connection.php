<?php
// Verificar conexión a la base de datos
require_once __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

echo "Verificando conexión a la base de datos...\n";

try {
    // Probar conexión
    $result = DB::connection('pgsql')->select('SELECT 1 as test');
    echo "✅ Conexión a PostgreSQL exitosa\n";
    
    // Verificar esquema selemti
    $schemas = DB::connection('pgsql')->select("SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'selemti'");
    if (count($schemas) > 0) {
        echo "✅ Esquema 'selemti' encontrado\n";
        
        // Contar tablas en selemti
        $tables = DB::connection('pgsql')->select("SELECT table_name FROM information_schema.tables WHERE table_schema = 'selemti'");
        echo "📊 Número de tablas en esquema 'selemti': " . count($tables) . "\n";
        
        // Obtener algunas tablas como ejemplo
        echo "📋 Primeras 10 tablas encontradas:\n";
        $i = 0;
        foreach ($tables as $table) {
            if ($i++ < 10) {
                echo "   - " . $table->table_name . "\n";
            }
        }
    } else {
        echo "❌ Esquema 'selemti' no encontrado\n";
    }
    
} catch (Exception $e) {
    echo "❌ Error de conexión: " . $e->getMessage() . "\n";
}