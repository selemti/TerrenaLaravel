# Instrucciones para Configurar Backup Automático Diario

## Método 1: Usando Task Scheduler de Windows (Recomendado)

### Paso 1: Asegúrate de que el script de backup funciona
Prueba el script batch manualmente:
```
C:\xampp3\htdocs\TerrenaLaravel\backup_diario.bat
```

### Paso 2: Crea una tarea programada en Windows
1. Abre "Task Scheduler" (Programador de tareas) en Windows
2. Click en "Create Basic Task..." (Crear tarea básica)
3. Nombre: "Backup Diario de TerrenaLaravel"
4. Descripción: "Respaldo automático diario de la base de datos de TerrenaLaravel"
5. Trigger (Disparador): "Daily" (Diario)
6. Time: Elige la hora que desees (recomendado: 2:00 AM cuando no se usa el sistema)
7. Action (Acción): "Start a program" (Iniciar un programa)
8. Program/script: `C:\xampp3\htdocs\TerrenaLaravel\backup_diario.bat`

### Paso 3: Configuración avanzada opcional (en la pestaña "Settings")
- Marca "Allow task to be run on demand" 
- Marca "Run task as soon as possible after a scheduled start is missed"
- Marca "Stop the task if it runs longer than: 1 hour"

## Método 2: Usando un comando desde PHP con Laravel Artisan

También puedes crear un comando de Laravel para automatizar esto:

```php
<?php
// Archivo: app/Console/Commands/DailyBackupCommand.php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class DailyBackupCommand extends Command
{
    protected $signature = 'db:backup-daily';
    protected $description = 'Realiza un backup diario de la base de datos';

    public function handle()
    {
        $this->info('Iniciando backup diario...');
        
        $config = [
            'host' => config('database.connections.pgsql.host', 'localhost'),
            'port' => config('database.connections.pgsql.port', '5433'),
            'database' => config('database.connections.pgsql.database', 'pos'),
            'username' => config('database.connections.pgsql.username', 'postgres'),
            'password' => config('database.connections.pgsql.password', 'T3rr3n4#p0s')
        ];
        
        $timestamp = now()->format('Y-m-d_His');
        $filename = storage_path("backups/backup_{$timestamp}.sql");
        
        // Crear directorio de backups si no existe
        if (!is_dir(storage_path('backups'))) {
            mkdir(storage_path('backups'), 0755, true);
        }
        
        $command = sprintf(
            'pg_dump -h %s -p %s -U %s -d %s -F p -v -f "%s" --schema=public --schema=selemti',
            $config['host'],
            $config['port'],
            $config['username'],
            $config['database'],
            $filename
        );
        
        putenv("PGPASSWORD=" . $config['password']);
        
        $output = [];
        $return_code = 0;
        exec($command, $output, $return_code);
        
        if ($return_code === 0) {
            $this->info("✅ Backup completado: {$filename}");
            
            // Limpieza de backups antiguos (más de 7 días)
            $this->cleanOldBackups();
            
            return 0;
        } else {
            $this->error("❌ Error en el backup");
            foreach ($output as $line) {
                $this->error($line);
            }
            return 1;
        }
    }
    
    private function cleanOldBackups()
    {
        $files = glob(storage_path('backups/backup_*.sql'));
        $sevenDaysAgo = time() - (7 * 24 * 60 * 60);
        
        foreach ($files as $file) {
            if (filemtime($file) < $sevenDaysAgo) {
                unlink($file);
                $this->info("🗑️ Eliminado backup antiguo: " . basename($file));
            }
        }
    }
}
```

## Método 3: Integración con Laravel Scheduler (Opcional)

Si usas Laravel, puedes agregarlo al kernel del scheduler:

```php
// En app/Console/Kernel.php
protected function schedule(Schedule $schedule)
{
    // Ejecutar backup diario a las 2:00 AM
    $schedule->command('db:backup-daily')->daily()->at('02:00');
    
    // Opcional: Verificar integridad cada 6 horas
    $schedule->command('db:verify-integrity')->everySixHours();
}
```

## Directorio de Backups

Los backups se almacenarán en:
- `C:\xampp3\htdocs\TerrenaLaravel\backups\`

## Mantenimiento

- El sistema mantiene automáticamente solo los últimos 7 días de backups
- Se recomienda revisar periódicamente el espacio en disco
- Los archivos de backup están comprimidos para ahorrar espacio

## Importante

- Asegúrate de que PostgreSQL esté corriendo cuando se ejecute la tarea
- El script está configurado para respaldar ambos esquemas: public y selemti
- Puedes ajustar la hora de ejecución según tus necesidades