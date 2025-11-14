<?php

/**
 * Script para registrar migraciones seguras - PARTE 2
 *
 * Registra migraciones cuyas tablas YA EXISTEN en la base de datos
 * (segunda tanda del 15 de noviembre)
 */

require __DIR__.'/../vendor/autoload.php';

$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "    REGISTRAR MIGRACIONES SEGURAS - PARTE 2 (Tablas del 15 de Noviembre)          \n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";

$safeMigrations = [
    '2025_11_15_030000_create_pos_consumption_tables',
    '2025_11_15_070000_create_pos_sync_tables',
    '2025_11_15_080000_create_menu_engineering_tables',
    '2025_11_15_100000_create_reporting_tables',
];

echo 'Se registrarán '.count($safeMigrations)." migraciones...\n\n";

// Get next batch number
$nextBatch = DB::table('migrations')->max('batch') + 1;
echo "Batch number: $nextBatch\n\n";

$registered = 0;
$skipped = 0;

DB::beginTransaction();

try {
    foreach ($safeMigrations as $migration) {
        // Check if already registered
        $exists = DB::table('migrations')->where('migration', $migration)->exists();

        if ($exists) {
            echo "  ⊘ SKIP: $migration (ya registrada)\n";
            $skipped++;
        } else {
            DB::table('migrations')->insert([
                'migration' => $migration,
                'batch' => $nextBatch,
            ]);
            echo "  ✓ OK:   $migration\n";
            $registered++;
        }
    }

    echo "\n───────────────────────────────────────────────────────────────────────────────────\n";
    echo "Registradas: $registered\n";
    echo "Omitidas:    $skipped (ya existían)\n";
    echo "───────────────────────────────────────────────────────────────────────────────────\n\n";

    echo '¿Confirmar cambios? (y/n): ';
    $handle = fopen('php://stdin', 'r');
    $line = fgets($handle);
    fclose($handle);

    if (trim(strtolower($line)) === 'y') {
        DB::commit();
        echo "\n✓ Cambios confirmados y guardados.\n\n";
    } else {
        DB::rollBack();
        echo "\n✗ Cambios cancelados. No se registró nada.\n\n";
    }

} catch (Exception $e) {
    DB::rollBack();
    echo "\n✗ ERROR: ".$e->getMessage()."\n\n";
    exit(1);
}

echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "SIGUIENTE PASO:\n";
echo "  1. Corregir archivo SQL de reportes (discount_amount → discount)\n";
echo "  2. php artisan migrate --step (para migraciones restantes)\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";
