<?php
/**
 * Script de Backup Configurable
 * 
 * Este script utiliza configuraciones externas para hacer backups
 * y puede ser fácilmente personalizado y programado
 */

require_once 'vendor/autoload.php';

// Configuración
$config = require_once 'backup_config.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

function performBackup($config) {
    $db_config = $config['database'];
    $backup_config = $config['backup'];
    
    $timestamp = date('Y-m-d_His');
    $backupDir = $backup_config['directory'];
    
    // Crear directorio de backups si no existe
    if (!is_dir($backupDir)) {
        mkdir($backupDir, 0755, true);
    }
    
    $filename = $backupDir . '/auto_backup_' . $timestamp . '.sql';
    
    // Especificar esquemas a incluir en el backup
    $schema_params = '';
    foreach ($backup_config['schemas'] as $schema) {
        $schema_params .= "--schema={$schema} ";
    }
    
    // Comando para crear backup con pg_dump
    $command = sprintf(
        'pg_dump -h %s -p %s -U %s -d %s -F p -v -f "%s" %s',
        $db_config['host'],
        $db_config['port'],
        $db_config['username'],
        $db_config['name'],
        $filename,
        $schema_params
    );
    
    // Configurar variable de entorno para contraseña
    putenv("PGPASSWORD=" . $db_config['password']);
    
    $output = [];
    $return_code = 0;
    exec($command, $output, $return_code);
    
    if ($return_code === 0) {
        echo "✅ Backup creado exitosamente: $filename\n";
        
        // Mantener solo los backups recientes
        cleanOldBackups($backupDir, $backup_config['retention_days'], $backup_config['max_files']);
        
        // Enviar notificación de éxito si está configurado
        if (isset($config['notifications']['email_on_success']) && $config['notifications']['email_on_success']) {
            sendNotification($config, true, $filename);
        }
        
        return $filename;
    } else {
        echo "❌ Error creando backup\n";
        foreach ($output as $line) {
            echo $line . "\n";
        }
        
        // Enviar notificación de error si está configurado
        if (isset($config['notifications']['email_on_failure']) && $config['notifications']['email_on_failure']) {
            sendNotification($config, false, $filename, $output);
        }
        
        return false;
    }
}

function cleanOldBackups($backupDir, $retentionDays, $maxFiles) {
    $files = glob($backupDir . '/auto_backup_*.sql');
    
    // Ordenar por tiempo de modificación (más reciente primero)
    usort($files, function($a, $b) {
        return filemtime($b) <=> filemtime($a);
    });
    
    // Eliminar backups anteriores al período de retención
    $cutoffTime = time() - ($retentionDays * 24 * 60 * 60);
    
    foreach ($files as $file) {
        if (filemtime($file) < $cutoffTime) {
            unlink($file);
            echo "🗑️  Eliminado backup antiguo: " . basename($file) . "\n";
        }
    }
    
    // Si hay más archivos que el máximo permitido, eliminar los más antiguos
    $files = glob($backupDir . '/auto_backup_*.sql');  // Recargar lista
    if (count($files) > $maxFiles) {
        // Ordenar de nuevo y eliminar los más antiguos
        usort($files, function($a, $b) {
            return filemtime($a) <=> filemtime($b); // Menor tiempo primero (más antiguo)
        });
        
        // Eliminar los que exceden el máximo
        for ($i = 0; $i < count($files) - $maxFiles; $i++) {
            unlink($files[$i]);
            echo "🗑️  Eliminado backup excedente: " . basename($files[$i]) . "\n";
        }
    }
}

function sendNotification($config, $success, $filename, $error = null) {
    // Esta función enviaría una notificación (correo electrónico o log)
    // Por simplicidad en este ejemplo, solo lo registramos
    
    $status = $success ? "ÉXITO" : "FALLO";
    $message = $success 
        ? "Backup completado exitosamente: " . basename($filename)
        : "Fallo en el backup: " . ($error ? implode(", ", array_slice($error, 0, 3)) : "desconocido");
    
    $logEntry = date('Y-m-d H:i:s') . " - BACKUP {$status}: {$message}\n";
    file_put_contents($config['backup']['directory'] . '/backup_log.txt', $logEntry, FILE_APPEND);
    
    echo "📧 Notificación registrada: $message\n";
}

// Ejecutar backup
echo "🚀 Iniciando backup automático configurado...\n";
echo "📅 Fecha y hora: " . date('Y-m-d H:i:s') . "\n";

$result = performBackup($config);

if ($result) {
    echo "✨ Backup automático configurado completado exitosamente\n";
} else {
    echo "💥 Error en el backup automático configurado\n";
    exit(1);
}