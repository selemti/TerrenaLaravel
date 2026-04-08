<?php
// Script para buscar y obtener la definición de la función f_item_mods_on

require_once __DIR__.'/vendor/autoload.php';

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Config;

// Inicializar el entorno de Laravel
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Conectar a la base de datos
try {
    // Verificar conexión
    DB::connection('pgsql')->getPdo();
    echo "Conexión exitosa a la base de datos PostgreSQL\n";

    // 1. Verificar si existe la función f_item_mods_on
    echo "\n1. Buscando la función f_item_mods_on:\n";
    $funcExists = DB::connection('pgsql')->select("
        SELECT n.nspname as schema_name,
               p.proname as function_name,
               pg_get_functiondef(p.oid) as function_definition
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'f_item_mods_on'
    ");
    
    if (empty($funcExists)) {
        echo "La función f_item_mods_on no se encontró.\n";
        
        // Buscar funciones que contengan 'item_mods' o 'mods'
        echo "\nBuscando funciones relacionadas con item_mods:\n";
        $relatedFuncs = DB::connection('pgsql')->select("
            SELECT n.nspname as schema_name,
                   p.proname as function_name,
                   pg_get_functiondef(p.oid) as function_definition
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE p.proname ILIKE '%item_mods%' OR p.proname ILIKE '%mods%'
            ORDER BY p.proname
        ");
        
        foreach ($relatedFuncs as $func) {
            echo "  - {$func->schema_name}.{$func->function_name}\n";
        }
    } else {
        foreach ($funcExists as $func) {
            echo "Función encontrada:\n";
            echo $func->function_definition . "\n";
        }
    }

} catch (Exception $e) {
    echo "Error al conectar a la base de datos: " . $e->getMessage() . "\n";
}