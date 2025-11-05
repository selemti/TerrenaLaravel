#!/usr/bin/env php
<?php

/**
 * GUARDIAN DE BASE DE DATOS
 * 
 * Este script monitorea la base de datos y previene/alerta sobre borrados masivos
 */

echo "\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "                    🛡️  GUARDIAN DE BASE DE DATOS 🛡️                              \n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";

// Cargar Laravel
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

// Estado esperado
$EXPECTED_TABLES = 250;
$EXPECTED_MIGRATIONS = 77;
$MIN_TABLES = 200;

// Verificar tablas actuales
$actualTables = DB::select("
    SELECT COUNT(*) as total
    FROM information_schema.tables 
    WHERE table_schema IN ('public', 'selemti')
    AND table_type = 'BASE TABLE'
");

$tableCount = $actualTables[0]->total;

// Verificar migraciones
$migrations = DB::table('migrations')->count();

echo "📊 ESTADO ACTUAL:\n";
echo str_repeat("─", 80) . "\n";
printf("   Tablas encontradas:       %d (esperadas: ~%d)\n", $tableCount, $EXPECTED_TABLES);
printf("   Migraciones ejecutadas:   %d (esperadas: %d)\n", $migrations, $EXPECTED_MIGRATIONS);
echo str_repeat("─", 80) . "\n\n";

// Evaluar estado
if ($tableCount < $MIN_TABLES) {
    echo "🚨 ALERTA CRÍTICA: BASE DE DATOS CASI VACÍA!\n";
    echo "═══════════════════════════════════════════════════════════════════════════════════\n";
    echo "   La base de datos tiene solo $tableCount tablas.\n";
    echo "   Esto indica que fue BORRADA o RESTAURADA a un estado inicial.\n";
    echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";
    
    echo "⚠️  ACCIONES RECOMENDADAS:\n";
    echo "   1. NO ejecutar ningún comando 'migrate' aún\n";
    echo "   2. Verificar si hay backups recientes disponibles\n";
    echo "   3. Restaurar desde el backup más reciente\n";
    echo "   4. Investigar quién/qué causó el borrado\n\n";
    
    // Verificar backups disponibles
    echo "📁 BACKUPS DISPONIBLES:\n";
    echo str_repeat("─", 80) . "\n";
    
    $backups = glob(__DIR__ . '/backup*.sql');
    usort($backups, function($a, $b) {
        return filemtime($b) - filemtime($a);
    });
    
    $count = 0;
    foreach (array_slice($backups, 0, 5) as $backup) {
        $count++;
        $size = filesize($backup) / 1024 / 1024; // MB
        $time = date('Y-m-d H:i:s', filemtime($backup));
        $name = basename($backup);
        
        printf("   %d. %s\n", $count, $name);
        printf("      Fecha: %s | Tamaño: %.2f MB\n", $time, $size);
    }
    
    echo str_repeat("─", 80) . "\n\n";
    
    echo "💡 COMANDOS PARA RESTAURAR:\n";
    echo "   1. Crear backup del estado actual (por si acaso):\n";
    echo "      pg_dump -h 127.0.0.1 -p 5433 -U postgres -d pos > backup_antes_restaurar.sql\n\n";
    echo "   2. Restaurar desde backup:\n";
    echo "      psql -h 127.0.0.1 -p 5433 -U postgres -d pos < [nombre_backup.sql]\n\n";
    
    exit(1);
    
} elseif ($tableCount < $EXPECTED_TABLES * 0.8) {
    echo "⚠️  ADVERTENCIA: Base de datos incompleta\n";
    echo "   Faltan ~" . ($EXPECTED_TABLES - $tableCount) . " tablas.\n";
    echo "   Considera ejecutar: php artisan migrate\n\n";
    exit(2);
    
} else {
    echo "✅ BASE DE DATOS OK\n";
    echo "   La base de datos parece estar completa.\n\n";
    exit(0);
}
