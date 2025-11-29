<?php
/**
 * Sistema de Backup Automatizado PostgreSQL - Versión con PATH completo y comillas
 */

// Configuración
$config = [
    'db_host' => 'localhost',
    'db_port' => '5433',
    'db_name' => 'pos',
    'db_user' => 'postgres',
    'db_password' => 'T3rr3n4#p0s',  // Contraseña desde el archivo .env
    'pg_dump_path' => 'C:/Program Files/Odoo 18.0.20250714/PostgreSQL/9.5/bin/pg_dump.exe',
    'psql_path' => 'C:/Program Files/Odoo 18.0.20250714/PostgreSQL/9.5/bin/psql.exe',
    'backup_base_dir' => 'C:/xampp3/htdocs/TerrenaLaravel/database/backups',
    'daily_retention' => 7,   // Días
    'weekly_retention' => 4,  // Semanas
    'schemas' => ['public', 'selemti'],
];

$timestamp = date('Y-m-d_H-i-s');
$date = date('Y-m-d');
$day_of_week = date('w'); // 0 = Domingo

// Directorios
$daily_dir = $config['backup_base_dir'] . '/daily';
$weekly_dir = $config['backup_base_dir'] . '/weekly';
$log_dir = $config['backup_base_dir'] . '/logs';
$daily_backup_file = $daily_dir . '/pos_backup_' . $timestamp . '.sql';

// Crear directorios si no existen
foreach ([$daily_dir, $weekly_dir, $log_dir] as $dir) {
    if (!is_dir($dir)) {
        mkdir($dir, 0777, true);
        echo "Created directory: {$dir}\n";
    }
}

$log_file = $log_dir . '/backup_log_' . $date . '.txt';
echo "Logging to: {$log_file}\n";

// Función de logging
function log_message($message, $log_file) {
    $timestamp = date('Y-m-d H:i:s');
    $log_entry = "[{$timestamp}] {$message}" . PHP_EOL;
    file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
    echo $log_entry;
}

log_message("=== Backup Process Started ===", $log_file);
log_message("Timestamp: {$timestamp}", $log_file);

// Establecer la contraseña como variable de entorno
putenv("PGPASSWORD=" . $config['db_password']);

// Comando para backup con ruta completa protegida
$pg_dump_path = '"' . $config['pg_dump_path'] . '"';
$db_host = $config['db_host'];
$db_port = $config['db_port'];
$db_user = $config['db_user'];
$db_name = $config['db_name'];
$output_file = '"' . $daily_backup_file . '"';

$backup_cmd = "{$pg_dump_path} " .
    "-h {$db_host} " .
    "-p {$db_port} " .
    "-U {$db_user} " .
    "-d {$db_name} " .
    "--schema=public " .
    "--schema=selemti " .
    "-F p " . // Plain text format
    "-f {$output_file}";

log_message("Executing daily backup with command:", $log_file);
log_message("Command: {$backup_cmd}", $log_file);

// Ejecutar el comando con shell_exec en vez de exec
$result = shell_exec($backup_cmd . ' 2>&1');
$return_code = $result === null ? 1 : 0;

// Verificar si el archivo se creó y tiene contenido
$file_exists = file_exists($daily_backup_file);
$file_size = $file_exists ? filesize($daily_backup_file) : 0;

log_message("Command output: " . $result, $log_file);
log_message("File exists: " . ($file_exists ? 'YES' : 'NO'), $log_file);
log_message("File size: {$file_size} bytes", $log_file);

if ($file_size > 0) {
    $file_size_mb = round($file_size / (1024 * 1024), 2);
    log_message("✅ Daily backup successful: {$daily_backup_file} ({$file_size_mb} MB)", $log_file);

    // Validar que el backup contenga datos de ambos esquemas
    $backup_content = file_get_contents($daily_backup_file);
    $has_public_data = stripos($backup_content, 'public.') !== false;
    $has_selemti_data = stripos($backup_content, 'selemti.') !== false;

    if ($has_public_data && $has_selemti_data) {
        log_message("✅ Backup validation: Contains both public and selemti schemas", $log_file);
    } else {
        log_message("⚠️  Backup validation: Missing schema data - public: " . ($has_public_data ? "YES" : "NO") . ", selemti: " . ($has_selemti_data ? "YES" : "NO"), $log_file);
    }

    // Si es domingo, crear backup semanal
    if ($day_of_week == 0) {
        $weekly_backup_file = $weekly_dir . '/pos_weekly_' . $date . '.sql';
        copy($daily_backup_file, $weekly_backup_file);
        log_message("✅ Weekly backup created: {$weekly_backup_file}", $log_file);
    }

} else {
    log_message("❌ Backup FAILED - File not created or empty", $log_file);
    log_message("Result: " . $result, $log_file);
    
    // Intentar con solo el esquema public como fallback
    log_message("Attempting fallback backup of public schema only...", $log_file);
    
    $backup_cmd_fallback = "{$pg_dump_path} " .
        "-h {$db_host} " .
        "-p {$db_port} " .
        "-U {$db_user} " .
        "-d {$db_name} " .
        "-n public " .
        "-F p " .
        "-f {$output_file}";
    
    $result_fallback = shell_exec($backup_cmd_fallback . ' 2>&1');
    $fallback_file_exists = file_exists($daily_backup_file);
    $fallback_file_size = $fallback_file_exists ? filesize($daily_backup_file) : 0;
    
    if ($fallback_file_size > 0) {
        $file_size = $fallback_file_size;
        $file_size_mb = round($file_size / (1024 * 1024), 2);
        log_message("✅ Fallback backup successful: {$daily_backup_file} ({$file_size_mb} MB)", $log_file);
    } else {
        log_message("❌ Fallback backup also FAILED", $log_file);
        log_message("Fallback output: " . $result_fallback, $log_file);
    }
}

// Rotación de backups diarios (mantener solo últimos 7)
log_message("Rotating daily backups (keep last {$config['daily_retention']})...", $log_file);
$daily_files = glob($daily_dir . '/pos_backup_*.sql');
if (count($daily_files) > $config['daily_retention']) {
    usort($daily_files, function($a, $b) {
        return filemtime($a) - filemtime($b);
    });

    $to_delete = array_slice($daily_files, 0, count($daily_files) - $config['daily_retention']);
    foreach ($to_delete as $file) {
        unlink($file);
        log_message("Deleted old daily backup: " . basename($file), $log_file);
    }
}

// Rotación de backups semanales (mantener solo últimos 4)
log_message("Rotating weekly backups (keep last {$config['weekly_retention']})...", $log_file);
$weekly_files = glob($weekly_dir . '/pos_weekly_*.sql');
if (count($weekly_files) > $config['weekly_retention']) {
    usort($weekly_files, function($a, $b) {
        return filemtime($a) - filemtime($b);
    });

    $to_delete = array_slice($weekly_files, 0, count($weekly_files) - $config['weekly_retention']);
    foreach ($to_delete as $file) {
        unlink($file);
        log_message("Deleted old weekly backup: " . basename($file), $log_file);
    }
}

log_message("=== Backup Process Completed ===", $log_file);

// Resumen final
$daily_backup_filename = basename($daily_backup_file);
$file_size_mb = file_exists($daily_backup_file) ? round(filesize($daily_backup_file) / (1024 * 1024), 2) : 0;

$status = (file_exists($daily_backup_file) && filesize($daily_backup_file) > 0) ? 'SUCCESS' : 'FAILED';

$summary = [
    'timestamp' => $timestamp,
    'daily_backup' => $daily_backup_filename,
    'file_size_mb' => $file_size_mb,
    'status' => $status,
    'daily_backups_count' => count(glob($daily_dir . '/pos_backup_*.sql')),
    'weekly_backups_count' => count(glob($weekly_dir . '/pos_weekly_*.sql')),
];

log_message("Summary: " . json_encode($summary, JSON_PRETTY_PRINT), $log_file);
echo "\n" . json_encode($summary, JSON_PRETTY_PRINT) . "\n";
?>