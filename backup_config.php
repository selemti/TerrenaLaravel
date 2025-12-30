<?php
// backup_config.php
// Archivo de configuración para backups automáticos

return [
    'database' => [
        'host' => env('DB_HOST', 'localhost'),
        'port' => env('DB_PORT', '5433'),
        'name' => env('DB_DATABASE', 'pos'),
        'username' => env('DB_USERNAME', 'postgres'),
        'password' => env('DB_PASSWORD', 'T3rr3n4#p0s'),
    ],
    
    'backup' => [
        'directory' => __DIR__ . '/backups',
        'retention_days' => 7,  // Días a mantener los backups
        'max_files' => 10,      // Máximo número de archivos a mantener
        'schemas' => ['public', 'selemti'],  // Esquemas a respaldar
    ],
    
    'schedule' => [
        'time' => '02:00',  // Hora de ejecución en formato 24h
        'frequency' => 'daily',  // daily, weekly, monthly
    ],
    
    'notifications' => [
        'email_on_success' => false,  // Enviar email en éxito
        'email_on_failure' => true,   // Enviar email en fallo
        'email_recipients' => [env('BACKUP_NOTIFY_EMAIL', 'admin@selemti.com')],
    ],
];