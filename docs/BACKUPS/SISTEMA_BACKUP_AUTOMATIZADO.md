# Sistema de Backup Automatizado PostgreSQL

## Descripción
Sistema de backup automatizado para la base de datos PostgreSQL que contiene los esquemas `public` y `selemti`. Realiza backups diarios de ambos esquemas y mantiene un historial rotativo de backups.

## Características del Sistema

### Periodicidad
- **Frecuencia**: Diaria a las 2:00 AM
- **Días de ejecución**: Todos los días

### Componentes del Sistema

#### 1. Archivo Principal
- `scripts/backup_postgresql.php` - Script PHP de backup automatizado

#### 2. Archivo de Tarea Programada
- `scripts/backup_diario.bat` - Script batch para ejecutar el backup

#### 3. Directorios de Almacenamiento
- `database/backups/daily/` - Backups diarios (mantiene los últimos 7 días)
- `database/backups/weekly/` - Backups semanales (mantiene los últimos 4 domingos)
- `database/backups/logs/` - Logs de ejecución (mantiene los últimos 30 días)

### Esquemas Incluidos
- `public` - Datos generales de la aplicación POS
- `selemti` - Datos específicos del sistema de control

## Configuración de la Tarea Programada

Para configurar la tarea automáticamente en Windows, ejecutar en PowerShell como Administrador:

```powershell
$action = New-ScheduledTaskAction -Execute "C:\xampp3\htdocs\TerrenaLaravel\scripts\backup_diario.bat"
$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontWakeToRun -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "Backup_POS_Automatizado" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Backup automatizado de la base de datos POS"

# Verificar que se haya creado
Get-ScheduledTask -TaskName "Backup_POS_Automatizado"
```

## Validación del Sistema

### Prueba de Ejecución Manual
Para probar el sistema manualmente:

```bash
php scripts/backup_postgresql.php
```

### Verificación de Backups
Consultar los archivos de backup en `database/backups/daily/` y su correspondiente archivo de log en `database/backups/logs/backup_log_*.txt`

### Validación de Integridad
El sistema incluye validación automática que:
1. Comprueba que el backup contenga datos de ambos esquemas (public y selemti)
2. Verifica que el archivo haya sido creado con éxito
3. Muestra el tamaño del archivo generado

## Política de Retención

### Backups Diarios
- Se mantienen los últimos **7 backups diarios**
- Eliminación automática de backups más antiguos

### Backups Semanales
- Se crean automáticamente los **domingos**
- Se mantienen los últimos **4 backups semanales**
- Eliminación automática de backups semanales más antiguos

## Monitoreo

### Logs
- Se crean logs diarios en `database/backups/logs/`
- Cada log contiene información detallada de la ejecución
- Archivos nombrados como `backup_log_YYYY-MM-DD.txt`

### Métricas
- Tamaño del archivo de backup
- Fecha y hora de creación
- Estado de la operación (éxito/error)
- Validación de esquemas incluidos

## Recuperación de Datos

Para restaurar desde un backup:

```bash
psql -h localhost -p 5433 -U postgres -d pos -f "path/to/backup_file.sql"
```

Advertencia: Al restaurar, se sobrescribirán los datos actuales. Asegúrese de tener permisos y hacer copias de seguridad adicionales si es necesario.

## Notificación de Problemas

Si el sistema falla en crear los backups diarios, verificar:

1. Disponibilidad de espacio en disco en el directorio de backups
2. Conexión a la base de datos PostgreSQL
3. Permisos de escritura en los directorios
4. Estado de la tarea programada de Windows

## Mantenimiento

### Espacio de almacenamiento
- Revisar periódicamente el espacio utilizado por los archivos de backup
- Ajustar la política de retención según requerimientos de espacio

### Verificación periódica
- Probar restauración desde backups antiguos al menos mensualmente
- Verificar integridad de los backups más antiguos

## Componentes del Sistema

- **Creador**: Asistente de IA con experiencia en sistemas de backup
- **Fecha de creación**: 29 de noviembre de 2025
- **Versión**: 1.0
- **Tecnologías**: PHP 8.2, PostgreSQL 9.5, pg_dump

## Seguridad

- La contraseña de la base de datos se maneja como variable de entorno
- Los backups se almacenan localmente con control de acceso basado en permisos de sistema
- El script se ejecuta con privilegios del sistema operativo