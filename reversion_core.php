<?php
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Config;

try {
    echo "=== PASO 1: BACKUPS (DDL y DML) ===\n";
    DB::unprepared("
        CREATE TABLE IF NOT EXISTS selemti.bkp_reversion_postcorte AS SELECT * FROM selemti.postcorte;
    ");
    echo "[x] Datos fisicos respaldados en selemti.bkp_reversion_postcorte\n";

    Config::set('database.connections.pgsql_prod', [
        'driver' => 'pgsql',
        'host' => '100.126.124.101',
        'port' => '5432',
        'database' => env('DB_DATABASE', 'selemti'),
        'username' => env('DB_USERNAME', 'postgres'),
        'password' => env('DB_PASSWORD', ''),
        'charset' => 'utf8',
        'prefix' => '',
        'schema' => 'public',
        'sslmode' => 'prefer',
    ]);
    $prod = DB::connection('pgsql_prod');

    echo "\n=== PASO 2: EXTRACCION DE FUNCIONES DE PRD ===\n";
    $q_fn_gen = "SELECT pg_get_functiondef(p.oid) as def FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'selemti' AND p.proname = 'fn_generar_postcorte'";
    $q_fn_trg = "SELECT pg_get_functiondef(p.oid) as def FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'selemti' AND p.proname = 'fn_postcorte_after_insert'";
    
    $fn_generar_prd = $prod->select($q_fn_gen)[0]->def;
    $fn_trig_prd = $prod->select($q_fn_trg)[0]->def;
    echo "[x] DDL funciones productivas extraidas (".strlen($fn_generar_prd)." bytes, ".strlen($fn_trig_prd)." bytes)\n";

    echo "\n=== PASO 3: RESTAURACION DE FUNCIONES EN LOCAL ===\n";
    DB::unprepared($fn_generar_prd);
    DB::unprepared($fn_trig_prd);
    echo "[x] Motor SQL Local homologado (ya no invoca columnas nuevas)\n";

    echo "\n=== PASO 4: VALIDACION INTERMEDIA ===\n";
    // Fetch a session to test. We can use session 605 as an arbitrary test
    $test_session = DB::table('selemti.sesion_cajon')->whereNotNull('cierre_ts')->orderBy('id', 'desc')->first()->id;
    echo "Probando fn_generar_postcorte en sesion $test_session...\n";
    $result = DB::select("SELECT selemti.fn_generar_postcorte(?) as res", [$test_session])[0]->res;
    echo "[x] Validacion exitosa: retorna ID $result sin errores de columnas faltantes!\n";

    echo "\n=== PASO 5: ELIMINAR COLUMNAS DDL LOCALES ===\n";
    DB::unprepared("
        ALTER TABLE selemti.postcorte 
        DROP COLUMN IF EXISTS calidad_reporte_descuentos CASCADE,
        DROP COLUMN IF EXISTS diferencia_descuentos CASCADE,
        DROP COLUMN IF EXISTS porcentaje_error_descuentos CASCADE,
        DROP COLUMN IF EXISTS total_descuentos_drawer CASCADE,
        DROP COLUMN IF EXISTS total_descuentos_reales CASCADE,
        DROP COLUMN IF EXISTS total_ventas_brutas CASCADE,
        DROP COLUMN IF EXISTS total_ventas_netas CASCADE;
    ");
    echo "[x] Muela del juicio extraida: 7 columnas eliminadas.\n";

    echo "\n=== PASO 6: VALIDACION FINAL POST-AMPUTACION ===\n";
    $final_cols = DB::select("SELECT COUNT(*) as cc FROM information_schema.columns WHERE table_schema='selemti' AND table_name='postcorte'")[0]->cc;
    echo "[!] La tabla postcorte ahora tiene $final_cols columnas. COMPLETO.\n";

} catch (\Exception $e) {
    echo "ERROR FATAL: " . $e->getMessage() . "\n";
    echo "El proceso ha sido detenido para proteger base de datos.\n";
}
