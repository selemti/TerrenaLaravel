<?php

/**
 * Script para registrar migraciones seguras en la tabla migrations
 * 
 * Este script registra migraciones cuyas tablas/cambios YA EXISTEN
 * en la base de datos, evitando errores de "tabla ya existe".
 * 
 * IMPORTANTE: Ejecutar ANTES de correr php artisan migrate
 */

require __DIR__ . '/../vendor/autoload.php';

$app = require_once __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "        REGISTRAR MIGRACIONES SEGURAS (CAMBIOS YA APLICADOS)                       \n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";

$safeMigrations = [
    '2025_10_24_015559_add_fecha_recepcion_to_recepcion_cab_table',
    '2025_10_24_100000_create_replenishment_suggestions_table',
    '2025_10_24_120000_create_purchase_suggestions_table',
    '2025_10_24_120101_create_purchase_suggestion_lines_table',
    '2025_10_26_000004_add_unit_cost_to_inventory_batch',
    '2025_10_26_000005_create_pos_map_table',
    '2025_10_26_000006_create_ticket_item_modifiers_table',
    '2025_10_27_100239_create_pos_reverse_log_table',
    '2025_10_27_100252_create_pos_reprocess_log_table',
    '2025_10_27_153528_create_personal_access_tokens_table',
    '2025_10_28_000001_update_inv_consumo_flags',
    '2025_10_28_000002_drop_public_ticket_trigger',
    '2025_10_28_000010_create_audit_log_table',
    '2025_10_28_200000_add_indexes_to_audit_log_table',
    '2025_10_28_200001_add_foreign_key_to_audit_log_table',
    '2025_10_30_000000_add_remember_token_to_selemti_users',
];

echo "Se registrarán " . count($safeMigrations) . " migraciones seguras...\n\n";

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
    
    echo "¿Confirmar cambios? (y/n): ";
    $handle = fopen("php://stdin", "r");
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
    echo "\n✗ ERROR: " . $e->getMessage() . "\n\n";
    exit(1);
}

echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "SIGUIENTE PASO:\n";
echo "  php artisan migrate\n";
echo "  (Ejecutará solo las migraciones que realmente faltan)\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";
