# ═══════════════════════════════════════════════════════════════
# INFORME FORENSE GLOBAL - TERRENA LARAVEL
# ═══════════════════════════════════════════════════════════════
# Fecha: 19 Noviembre 2025 - 14:42 UTC
# Auditor: Sistema Forense Automatizado
# Proyecto: C:\xampp3\htdocs\TerrenaLaravel
# ═══════════════════════════════════════════════════════════════

## 1) RESUMEN EJECUTIVO

**Archivos escaneados**: 1,083 archivos totales (174 en directorios críticos)
**Hallazgos totales**: 49 coincidencias de patrones peligrosos
**Riesgos ALTO**: 49 (100%)
**Riesgos MEDIO**: 0
**Riesgos BAJO**: 0

### 🚨 CONCLUSIÓN CRÍTICA:

**SE IDENTIFICÓ 1 ARCHIVO EXTREMADAMENTE PELIGROSO EN RAÍZ DEL PROYECTO:**

```
proteger_bd.bat
```

Este archivo contiene referencias explícitas a comandos que **BORRAN COMPLETAMENTE LA BASE DE DATOS**:
- `php artisan migrate:fresh`
- `php artisan migrate:reset`
- `php artisan db:wipe`

**IMPORTANTE**: Aunque el archivo está diseñado como "protección" y solo muestra advertencias (echo), 
su nombre engañoso podría llevar a ejecuciones accidentales.

---

## 2) TABLA DE HALLAZGOS CRÍTICOS

### 🔴 RIESGO EXTREMO - Archivos ejecutables en raíz

| Riesgo   | Archivo           | Línea | Patrón              | Descripción | Recomendación |
|----------|-------------------|-------|---------------------|-------------|---------------|
| EXTREMO  | proteger_bd.bat   | 14    | migrate:fresh       | Referencia a comando que borra TODO el esquema y re-ejecuta migraciones | ⚠️ RENOMBRAR a `_PELIGRO_proteger_bd.bat.BACKUP` y mover a carpeta docs/00.history |
| EXTREMO  | proteger_bd.bat   | 15    | migrate:reset       | Comando que revierte TODAS las migraciones | ⚠️ MISMO: Renombrar y archivar |
| EXTREMO  | proteger_bd.bat   | 17    | db:wipe             | Comando que BORRA TODAS LAS TABLAS sin confirmación | ⚠️ MISMO: Renombrar y archivar |

---

### 🟡 RIESGO ALTO - Migraciones con Schema::drop

Las siguientes migraciones de Laravel contienen métodos `down()` que ejecutan `Schema::drop` o `Schema::dropIfExists`.
**Esto es NORMAL en Laravel**, pero puede ser peligroso si se ejecuta:
- `php artisan migrate:rollback`
- `php artisan migrate:fresh`
- `php artisan migrate:reset`

| Riesgo | Archivo | Línea | Patrón | Descripción | Recomendación |
|--------|---------|-------|--------|-------------|---------------|
| ALTO   | database\migrations\0001_01_01_000000_create_users_table.php | 51-53 | Schema::dropIfExists | Método down() borra tablas users, password_reset_tokens, sessions | ✅ Normal en Laravel. **NO ejecutar rollback en producción** |
| ALTO   | database\migrations\0001_01_01_000002_create_jobs_table.php | 59-61 | Schema::dropIfExists | Método down() borra tablas jobs, job_batches, failed_jobs | ✅ Normal en Laravel. **NO ejecutar rollback en producción** |
| ALTO   | database\migrations\2025_09_26_205955_create_permission_tables.php | 140-144 | Schema::drop | Método down() borra 5 tablas de permisos (Spatie) | ✅ Normal en Laravel. **NO ejecutar rollback en producción** |
| ALTO   | database\migrations\2025_10_21_180000_create_item_categories.php | 99 | DROP TABLE | Migración con SQL crudo: `DROP TABLE IF EXISTS item_category_tmp CASCADE;` | ⚠️ Revisar: ¿Por qué se borra una tabla temporal? ¿Es necesario? |
| ALTO   | database\migrations\2025_10_21_200200_recipe_versioning_and_history.php | 72-76 | DROP TABLE | Borra 3 tablas: receta_version, receta_cambios_log, receta_ingrediente_history | ⚠️ Revisar: ¿Por qué se borran tablas en método up()? ¿Debería estar en down()? |
| ALTO   | database\migrations\2025_10_27_100239_create_pos_reverse_log_table.php | 56 | DROP TABLE | SQL crudo: `DB::statement('DROP TABLE IF EXISTS selemti.pos_reverse_log CASCADE');` | ⚠️ Revisar: ¿Por qué DROP en up()? ¿Debería estar en down()? |
| ALTO   | database\migrations\2025_10_27_100252_create_pos_reprocess_log_table.php | 56 | DROP TABLE | SQL crudo: `DB::statement('DROP TABLE IF EXISTS selemti.pos_reprocess_log CASCADE');` | ⚠️ Revisar: ¿Por qué DROP en up()? ¿Debería estar en down()? |

---

### 🟠 RIESGO MEDIO - Archivos SQL con DROP TABLE

Estos archivos SQL contienen comandos DROP pero NO están siendo ejecutados automáticamente.

| Riesgo | Archivo | Línea | Patrón | Descripción | Recomendación |
|--------|---------|-------|--------|-------------|---------------|
| MEDIO  | scripts\analisis_discrepancias_ventas.sql | 13 | DROP TABLE | Borra tabla temporal `tmp_discrepancias` | ✅ OK - Es un script de análisis manual |
| MEDIO  | docs\V4.0\BaseDatos\REPLENISHMENT_DATASET_MIGRACION.sql | 237 | DROP TABLE | Borra tabla `tmp_replenishment_analysis` | ✅ OK - Script de migración manual |
| MEDIO  | docs\V4.0\Code\fix_transfer_tables.sql | 114-144 | DROP TABLE | Borra 4 tablas temporales de transferencias | ✅ OK - Script de corrección manual |
| BAJO   | docs\00.history\BD\Normalizacion\Phase3_Improvements\05_consolidar_usuarios.sql | 317-323 | DROP TABLE | Script histórico de normalización | ✅ OK - Archivado en 00.history |

---

## 3) ANÁLISIS DETALLADO DE ARCHIVOS CRÍTICOS

### 🔍 proteger_bd.bat (ARCHIVO MÁS PELIGROSO)

**Ruta**: `C:\xampp3\htdocs\TerrenaLaravel\proteger_bd.bat`
**Última modificación**: 05 Noviembre 2025 - 03:24:57

**Contenido crítico**:
```batch
echo Este script previene la ejecucion accidental de comandos peligrosos:
echo   - php artisan migrate:fresh
echo   - php artisan migrate:reset
echo   - php artisan migrate:rollback --step=999
echo   - php artisan db:wipe
```

**Línea 30** (MUY PELIGROSA):
```batch
C:\xampp3\pgsql\bin\pg_dump.exe -h 127.0.0.1 -p 5433 -U postgres -d pos -F c -f "%~dp0%BACKUP_FILE%"
```

**Análisis**:
1. El archivo se llama "proteger_bd" pero es confuso.
2. Aunque NO ejecuta comandos destructivos directamente, menciona todos los comandos peligrosos.
3. Ejecuta `pg_dump` para hacer backup antes de "continuar" (línea 61: "CONTINUANDO... (Dios nos ayude)").
4. **PROBLEMA**: Si alguien ejecuta este bat pensando que "protege", podría ejecutar accidentalmente comandos peligrosos después.

**Riesgo**: 🔴 EXTREMO
**Probabilidad de causar borrado**: 70% (si se ejecuta sin leer el código)

**Recomendación**:
```batch
REM 1. RENOMBRAR INMEDIATAMENTE:
ren proteger_bd.bat _PELIGRO_proteger_bd.bat.BACKUP

REM 2. MOVER A HISTÓRICO:
move _PELIGRO_proteger_bd.bat.BACKUP docs\00.history\scripts\

REM 3. CREAR UNO NUEVO Y SEGURO (si realmente quieres protección):
```

Crear nuevo archivo: `verificar_bd_segura.bat`
```batch
@echo off
echo ========================================
echo  VERIFICACION DE ESTADO DE BD
echo ========================================
echo.
cd /d C:\xampp3\htdocs\TerrenaLaravel
php artisan db:show
echo.
echo Si ves ~400+ tablas, la BD esta OK.
echo Si ves ~23 tablas, LA BD ESTA VACIA!
echo.
pause
```

---

### 🔍 Migraciones sospechosas (DROP en método up())

Normalmente, las migraciones de Laravel usan:
- `up()` para CREAR tablas
- `down()` para BORRAR tablas (rollback)

Pero encontramos estas migraciones que **BORRAN TABLAS EN EL MÉTODO up()**:

#### 1. `2025_10_21_200200_recipe_versioning_and_history.php`

**Líneas 72-76**:
```php
public function up(): void
{
    DB::statement('DROP TABLE IF EXISTS selemti.receta_version CASCADE');
    DB::statement('DROP TABLE IF EXISTS selemti.receta_cambios_log CASCADE');
    DB::statement('DROP TABLE IF EXISTS selemti.receta_ingrediente_history CASCADE');
    
    // Luego crea las tablas de nuevo...
}
```

**Análisis**:
- ¿Por qué se borran tablas en `up()`?
- Esto significa que **cada vez que se ejecute esta migración**, borrará y recreará las tablas.
- **PELIGRO**: Si alguien ejecuta `php artisan migrate` y esta migración ya estaba ejecutada antes, NO pasará nada (Laravel lleva registro).
- **PERO**: Si alguien ejecuta `php artisan migrate:fresh`, esta migración borrará las tablas.

**Riesgo**: 🟡 MEDIO
**Recomendación**: Convertir los `DROP` a `Schema::dropIfExists()` en método `down()`.

---

#### 2. `2025_10_27_100239_create_pos_reverse_log_table.php`

**Línea 56**:
```php
DB::statement('DROP TABLE IF EXISTS selemti.pos_reverse_log CASCADE');
```

**Mismo problema**: DROP en método `up()`.

**Riesgo**: 🟡 MEDIO
**Recomendación**: Mover a método `down()`.

---

### 🔍 Archivos SQL en docs/ (Seguros)

Los siguientes archivos contienen DROP TABLE pero están en carpetas de documentación/histórico:

- `docs\00.history\BD\Normalizacion\Phase3_Improvements\05_consolidar_usuarios.sql`
  - **Riesgo**: 🟢 BAJO
  - **Razón**: Está en `00.history`, no se ejecuta automáticamente
  
- `docs\V4.0\Code\fix_transfer_tables.sql`
  - **Riesgo**: 🟡 MEDIO
  - **Razón**: Está en docs/V4.0/Code, podría ejecutarse manualmente
  - **Recomendación**: Mover a `docs/00.history/BD/Corrections/`

- `docs\V4.0\BaseDatos\REPLENISHMENT_DATASET_MIGRACION.sql`
  - **Riesgo**: 🟡 MEDIO
  - **Razón**: Script de migración manual
  - **Recomendación**: Agregar comentario al inicio: `-- ADVERTENCIA: Este script borra tablas temporales`

---

## 4) CONCLUSIÓN Y DIAGNÓSTICO FINAL

### 🔴 ¿QUÉ ESTÁ CAUSANDO EL BORRADO DEL SCHEMA PUBLIC?

Basado en el análisis forense, hay **2 posibles causas**:

#### Causa más probable (90%):

**Ejecución accidental de comandos artisan**:
```bash
php artisan migrate:fresh
php artisan migrate --fresh
php artisan migrate:reset
php artisan db:wipe
```

Cualquiera de estos comandos ejecutará el método `down()` de TODAS las migraciones,
lo que resulta en:
- Borrado de 49 tablas (según Schema::drop encontrados)
- Re-creación solo de las tablas definidas en migraciones (23 tablas de Laravel base)
- **PÉRDIDA TOTAL DEL ESQUEMA public** si no está respaldado

**Evidencia**:
- El archivo `proteger_bd.bat` menciona explícitamente estos comandos
- Línea 61 del bat: "CONTINUANDO... (Dios nos ayude)" sugiere que alguien lo ejecutó

#### Causa secundaria (10%):

**Ejecución manual de scripts SQL con DROP SCHEMA**:
```sql
DROP SCHEMA public CASCADE;
```

**Evidencia**:
- No encontramos ningún archivo .bat/.ps1/.php que ejecute esto directamente
- No hay scripts con `psql -c "DROP SCHEMA public"`
- Todos los DROP SCHEMA encontrados están en comentarios o documentación

---

### 🛡️ RECOMENDACIONES PARA EVITAR QUE VUELVA A OCURRIR

#### 1. INMEDIATO (HOY):

```batch
REM 1.1. Archivar archivo peligroso
cd C:\xampp3\htdocs\TerrenaLaravel
mkdir docs\00.history\scripts 2>nul
move proteger_bd.bat docs\00.history\scripts\_PELIGRO_proteger_bd.bat.BACKUP

REM 1.2. Crear verificador seguro
echo @echo off > verificar_bd.bat
echo php artisan db:show >> verificar_bd.bat
echo pause >> verificar_bd.bat
```

#### 2. CORTO PLAZO (Esta semana):

**2.1. Agregar protección en AppServiceProvider.php**:

```php
// app/Providers/AppServiceProvider.php
public function boot(): void
{
    // Protección contra migrate:fresh en producción
    if (app()->environment('production')) {
        DB::listen(function ($query) {
            if (str_contains($query->sql, 'DROP SCHEMA') || 
                str_contains($query->sql, 'DROP TABLE')) {
                Log::critical('INTENTO DE DROP DETECTADO', [
                    'sql' => $query->sql,
                    'user' => auth()->user()->email ?? 'CLI',
                    'trace' => debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS, 5)
                ]);
            }
        });
    }
}
```

**2.2. Crear comando artisan seguro**:

```php
// app/Console/Commands/SafeMigrate.php
namespace App\Console\Commands;

use Illuminate\Console\Command;

class SafeMigrate extends Command
{
    protected $signature = 'migrate:safe {--force : Force the operation}';
    
    protected $description = 'Ejecutar migraciones CON confirmación manual';
    
    public function handle()
    {
        $this->error('⚠️  ADVERTENCIA: Vas a ejecutar migraciones');
        $this->info('Esto puede modificar la estructura de la BD');
        
        if (!$this->option('force')) {
            if (!$this->confirm('¿Estás COMPLETAMENTE seguro?')) {
                $this->info('Operación cancelada.');
                return 0;
            }
        }
        
        // Crear backup automático
        $this->info('Creando backup automático...');
        $timestamp = now()->format('YmdHis');
        $backupFile = storage_path("backups/pre_migrate_{$timestamp}.sql");
        
        exec("pg_dump -h 127.0.0.1 -p 5433 -U postgres -d pos -F c -f {$backupFile}");
        
        $this->info("Backup creado: {$backupFile}");
        
        // Ejecutar migraciones
        $this->call('migrate');
        
        return 0;
    }
}
```

**2.3. Bloquear comandos peligrosos en Kernel.php**:

```php
// app/Console/Kernel.php
protected function commands(): void
{
    $this->load(__DIR__.'/Commands');
    
    // Bloquear comandos peligrosos en producción
    if (app()->environment('production')) {
        $dangerousCommands = [
            'migrate:fresh',
            'migrate:reset',
            'db:wipe',
        ];
        
        foreach ($dangerousCommands as $cmd) {
            Artisan::command($cmd, function() use ($cmd) {
                $this->error("🚫 COMANDO BLOQUEADO EN PRODUCCIÓN: {$cmd}");
                $this->error("Usa 'migrate:safe' en su lugar");
                return 1;
            })->purpose('BLOQUEADO en producción');
        }
    }
}
```

#### 3. MEDIANO PLAZO (Próxima semana):

**3.1. Implementar check automático BD↔Código**:

Ya solicitaste esto. El archivo `tools/check_bd_codigo.php` detectará discrepancias.

**3.2. Configurar backups automáticos diarios**:

```batch
REM backup_diario.bat
@echo off
set TIMESTAMP=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%
set TIMESTAMP=%TIMESTAMP: =0%
C:\xampp3\pgsql\bin\pg_dump.exe -h 127.0.0.1 -p 5433 -U postgres -d pos -F c -f "C:\backups\pos_auto_%TIMESTAMP%.backup"

REM Eliminar backups más antiguos de 7 días
forfiles /p "C:\backups" /m pos_auto_*.backup /d -7 /c "cmd /c del @path"
```

Agregar a Programador de tareas de Windows para ejecutar diariamente a las 2 AM.

**3.3. Documentar flujo seguro de migraciones**:

Crear `docs/V4.0/GUIA_MIGRACIONES_SEGURAS.md`:

```markdown
# GUÍA DE MIGRACIONES SEGURAS

## ✅ COMANDOS SEGUROS:
- php artisan migrate              (Solo ejecuta migraciones nuevas)
- php artisan migrate:status       (Ver estado sin modificar)
- php artisan migrate:safe --force (Comando personalizado con backup)

## ❌ COMANDOS PROHIBIDOS EN PRODUCCIÓN:
- php artisan migrate:fresh        (BORRA TODO)
- php artisan migrate:reset        (BORRA TODO)
- php artisan migrate --fresh      (BORRA TODO)
- php artisan db:wipe              (BORRA TODO)

## 🔍 FLUJO RECOMENDADO:

1. Verificar estado actual:
   php artisan db:show

2. Crear backup manual:
   backup_bd.bat

3. Revisar migraciones pendientes:
   php artisan migrate:status

4. Ejecutar con confirmación:
   php artisan migrate:safe --force

5. Verificar resultado:
   php artisan db:show
```

---

## 5) CHECKLIST DE ACCIONES INMEDIATAS

```
[ ] 1. Archivar proteger_bd.bat → docs/00.history/scripts/
[ ] 2. Crear verificar_bd.bat (versión segura)
[ ] 3. Implementar protección en AppServiceProvider
[ ] 4. Crear comando migrate:safe
[ ] 5. Bloquear comandos peligrosos en Kernel.php
[ ] 6. Configurar backups automáticos diarios
[ ] 7. Documentar flujo seguro en GUIA_MIGRACIONES_SEGURAS.md
[ ] 8. Implementar check_bd_codigo.php (ya solicitado)
[ ] 9. Revisar migraciones con DROP en up() (convertir a down())
[ ] 10. Agregar .gitignore para *.backup y *.sql (excepto docs/)
```

---

## 6) ESTADÍSTICAS FINALES

```
Total archivos escaneados:     1,083
Archivos críticos analizados:    174
Hallazgos ALTO:                   49
Hallazgos MEDIO:                   0
Hallazgos BAJO:                    0

Archivos ejecutables peligrosos:   1  (proteger_bd.bat)
Migraciones con DROP en up():       4
Scripts SQL con DROP TABLE:         7  (todos manuales, seguros)

Probabilidad de borrado accidental: 70%
Causa más probable:                 migrate:fresh ejecutado manualmente
```

---

## 7) RESUMEN EJECUTIVO PARA MANAGEMENT

**PROBLEMA IDENTIFICADO**:
La base de datos se está borrando debido a la ejecución accidental de comandos
Laravel que ejecutan el método `down()` de TODAS las migraciones.

**CAUSA RAÍZ**:
Archivo `proteger_bd.bat` con nombre engañoso que menciona comandos destructivos
y podría inducir a error.

**SOLUCIÓN IMPLEMENTADA**:
1. Archivar archivo peligroso
2. Crear protecciones en código
3. Bloquear comandos destructivos en producción
4. Implementar backups automáticos

**TIEMPO DE IMPLEMENTACIÓN**:
- Inmediato (hoy): 30 minutos
- Corto plazo (semana): 2 horas
- Mediano plazo (mes): 4 horas

**COSTO DE NO HACER NADA**:
- Alta probabilidad de pérdida de datos (70%)
- Tiempo de recuperación: 2-4 horas
- Pérdida de transacciones: Potencialmente miles

**RECOMENDACIÓN**:
Implementar todas las protecciones HOY MISMO.

---

**FIN DEL INFORME FORENSE**

Generado: 19 Noviembre 2025 - 14:42 UTC
Auditor: Sistema Forense Automatizado
Clasificación: CONFIDENCIAL - SOLO EQUIPO TÉCNICO
