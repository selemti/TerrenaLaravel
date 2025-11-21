# Comando Artisan de Recálculo de Costos

## Descripción

El comando `recetas:recalcular-costos` permite ejecutar manualmente o programadamente el proceso de recálculo de costos de recetas.

## Uso del Comando

### Ejecución Manual

```bash
# Ejecutar con la fecha de ayer (por defecto)
php artisan recetas:recalcular-costos

# Ejecutar con una fecha específica
php artisan recetas:recalcular-costos --date=2024-12-31

# Ejecutar con una sucursal específica
php artisan recetas:recalcular-costos --branch=1

# Ejecutar con ambos parámetros
php artisan recetas:recalcular-costos --date=2024-12-31 --branch=1
```

### Opciones Disponibles

- `--date` (opcional): Fecha objetivo para el recálculo en formato YYYY-MM-DD. Si no se especifica, se usa la fecha de ayer.
- `--branch` (opcional): ID de la sucursal sobre la cual realizar el recálculo. Si no se especifica, se procesan todas las sucursales.

## Programación del Comando

### Programación Automática

El comando está programado para ejecutarse diariamente a las 01:10 hora de México City:

```php
// En app/Console/Kernel.php
protected function schedule(Schedule $schedule): void
{
    $schedule->command('close:daily')->dailyAt('22:00')->timezone('America/Mexico_City');
    $schedule->command('recetas:recalcular-costos')->dailyAt('01:10')->timezone('America/Mexico_City');
}
```

### Configuración del Scheduler

Para que la programación funcione, debe estar configurado el cron job en el servidor:

```
* * * * * cd /path-to-your-project && php artisan schedule:run >> /dev/null 2>&1
```

## Resultados de Ejecución

El comando muestra mensajes informativos según el resultado:

### Éxito
```
Iniciando recálculo de costos para la fecha: 2024-12-31
Recálculo de costos completado exitosamente para la fecha 2024-12-31
Items afectados: 5
Subrecetas afectadas: 3
Recetas afectadas: 7
Alertas generadas: 1
```

### Error o Proceso en Curso
```
Iniciando recálculo de costos para la fecha: 2024-12-31
Proceso ya en ejecución para la fecha 2024-12-31
```

## Implementación Técnica

### Clase del Comando

La implementación se encuentra en `App\Console\Commands\RecalcularCostosRecetasCommand`:

```php
class RecalcularCostosRecetasCommand extends Command
{
    protected $signature = 'recetas:recalcular-costos 
                            {--date= : Fecha objetivo para el recálculo (formato YYYY-MM-DD, por defecto ayer)} 
                            {--branch= : ID de la sucursal (opcional)}';
    
    protected $description = 'Recalcular el costo unitario de recetas publicadas y subrecetas cuyo insumo cambió de precio el día anterior, y propagar costo a padres';
    
    public function handle(RecalcularCostosRecetasService $service)
    {
        // Implementación del comando
    }
}
```

### Registro del Comando

El comando está registrado en `app/Console\Kernel.php`:

```php
protected $commands = [
    \App\Console\Commands\InspectCatalogos::class,
    \App\Console\Commands\CheckLegacyLinks::class,
    \App\Console\Commands\RecalcularCostosRecetasCommand::class,
];
```

## Consideraciones de Producción

### Recursos del Sistema

El comando puede consumir recursos significativos dependiendo del volumen de datos:
- Número de insumos con cambios de costo
- Número de recetas afectadas
- Profundidad de la jerarquía de recetas

### Monitoreo

Puedes monitorear la ejecución del comando a través de:

1. Logs de Laravel en `storage/logs/laravel.log`
2. Estado de Redis para verificar locks
3. Tablas de alertas (si existen) para monitorear márgenes negativos

### Mantenimiento

- Verifica periódicamente que las tablas necesarias existan
- Revisa los logs para detectar posibles errores
- Ajusta la hora de ejecución si es necesario según los horarios de cierre de operaciones