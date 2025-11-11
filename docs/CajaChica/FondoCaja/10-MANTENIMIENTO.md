# 10 - MANTENIMIENTO Y SOLUCIÓN DE PROBLEMAS

## 🔧 Mantenimiento Regular

### Diario

**✅ Verificar logs de errores**
```bash
tail -f storage/logs/laravel.log
```

**✅ Monitorear espacio en disco (archivos adjuntos)**
```bash
du -sh storage/app/public/cash_fund_attachments
```

---

### Semanal

**✅ Respaldo de base de datos**
```bash
pg_dump -h localhost -p 5433 -U postgres -d pos \
  -t selemti.cash_funds \
  -t selemti.cash_fund_movements \
  -t selemti.cash_fund_arqueos \
  -t selemti.cash_fund_movement_audit_log \
  > backup_caja_$(date +%Y%m%d).sql
```

**✅ Limpiar logs antiguos**
```bash
find storage/logs -name "*.log" -mtime +30 -delete
```

**✅ Verificar integridad de archivos**
```php
// Script de verificación
php artisan tinker

$movimientos = \App\Models\CashFundMovement::where('tiene_comprobante', true)->get();

foreach ($movimientos as $mov) {
    $path = storage_path('app/public/' . $mov->adjunto_path);
    if (!file_exists($path)) {
        echo "FALTA: Movimiento #{$mov->id} - {$mov->adjunto_path}\n";
    }
}
```

---

### Mensual

**✅ Analizar métricas**
```sql
-- Fondos del mes
SELECT
    COUNT(*) as total_fondos,
    SUM(monto_inicial) as total_inicial,
    AVG(monto_inicial) as promedio_inicial
FROM selemti.cash_funds
WHERE DATE_TRUNC('month', fecha) = DATE_TRUNC('month', CURRENT_DATE);

-- Movimientos del mes
SELECT
    tipo,
    COUNT(*) as cantidad,
    SUM(monto) as total
FROM selemti.cash_fund_movements cfm
JOIN selemti.cash_funds cf ON cf.id = cfm.cash_fund_id
WHERE DATE_TRUNC('month', cf.fecha) = DATE_TRUNC('month', CURRENT_DATE)
GROUP BY tipo;
```

**✅ Optimizar base de datos**
```sql
-- Vacuum y analizar tablas
VACUUM ANALYZE selemti.cash_funds;
VACUUM ANALYZE selemti.cash_fund_movements;
VACUUM ANALYZE selemti.cash_fund_arqueos;
VACUUM ANALYZE selemti.cash_fund_movement_audit_log;
```

**✅ Archivar fondos antiguos (opcional)**
```sql
-- Mover fondos de hace más de 2 años a tabla de archivo
CREATE TABLE IF NOT EXISTS selemti.cash_funds_archivo AS
SELECT * FROM selemti.cash_funds WHERE 1=0;

INSERT INTO selemti.cash_funds_archivo
SELECT * FROM selemti.cash_funds
WHERE fecha < CURRENT_DATE - INTERVAL '2 years'
AND estado = 'CERRADO';

-- Similar para movimientos, arqueos, audit logs
```

---

## 🐛 Problemas Comunes y Soluciones

### Problema 1: Archivos adjuntos no se muestran (403 Forbidden)

**Síntoma:** Al hacer click en comprobante aparece "403 Forbidden"

**Causa:** Symlink de storage no existe

**Solución:**
```bash
# Verificar si existe
ls -la public/storage

# Si no existe, crear
php artisan storage:link

# Verificar
ls -la public/storage
# Debería mostrar: storage -> ../storage/app/public
```

---

### Problema 2: Error al subir archivos

**Síntoma:** "The file exceeds maximum upload size"

**Causa:** Límite de PHP muy bajo

**Solución:**

Editar `php.ini`:
```ini
upload_max_filesize = 10M
post_max_size = 10M
max_execution_time = 300
```

Reiniciar Apache/PHP-FPM

---

### Problema 3: Arqueo no se guarda

**Síntoma:** Botón "Confirmar y cerrar" no hace nada

**Causa:** Constraint UNIQUE en `cash_fund_id` cuando se intenta crear segundo arqueo

**Solución:** Ya implementada con `updateOrCreate()` en `Arqueo.php:72`

**Verificar:**
```php
// Debería usar updateOrCreate, NO create
CashFundArqueo::updateOrCreate(
    ['cash_fund_id' => $this->fondo->id],
    [/* datos */]
);
```

---

### Problema 4: "Class 'Livewire\Component' not found"

**Síntoma:** Error al cargar componentes

**Causa:** Livewire no instalado o autoload desactualizado

**Solución:**
```bash
composer require livewire/livewire
composer dump-autoload
php artisan config:clear
php artisan cache:clear
```

---

### Problema 5: Información de usuario muestra JSON

**Síntoma:** En Detail view muestra `{"id":2,"username":"..."}` en lugar de nombre

**Causa:** Livewire está serializando el objeto User

**Solución:** Ya implementada en `Detail.php:120-139`

Extraer valores antes de pasar a vista:
```php
$responsableNombre = 'N/A';
if ($this->fondo->responsable_user_id) {
    $responsableUser = User::find($this->fondo->responsable_user_id);
    if ($responsableUser) {
        $responsableNombre = $responsableUser->nombre_completo;
    }
}
```

---

### Problema 6: Permisos no funcionan

**Síntoma:** Usuario con permiso recibe "No autorizado"

**Causa:** Cache de permisos desactualizado

**Solución:**
```bash
php artisan permission:cache-reset
php artisan config:clear
php artisan cache:clear
```

---

### Problema 7: Diferencia en arqueo no se calcula

**Síntoma:** Diferencia siempre muestra $0.00

**Causa:** No se está usando `wire:model.live`

**Verificar en `arqueo.blade.php`:**
```blade
<input type="number"
       wire:model.live="arqueoForm.efectivo_contado"
       <!-- debe ser .live, NO .defer -->
```

---

### Problema 8: Modal no se cierra después de acción

**Síntoma:** Modal permanece abierto después de guardar

**Causa:** No se está seteando la variable a `false`

**Solución:**
```php
public function updateMovimiento()
{
    try {
        // Lógica de actualización
        $this->showEditModal = false; // ← IMPORTANTE
    } catch (\Exception $e) {
        // Error handling
    }
}
```

---

### Problema 9: Slow performance en lista de fondos

**Síntoma:** Index tarda mucho en cargar con muchos fondos

**Causa:** N+1 queries

**Solución:** Usar eager loading en `Index.php:34`
```php
$query = CashFund::with(['responsable', 'createdBy', 'movements'])
    ->orderBy('fecha', 'desc')
    ->orderBy('id', 'desc');
```

---

### Problema 10: Error "Too many open files"

**Síntoma:** Error al subir muchos comprobantes

**Causa:** Límite de archivos abiertos muy bajo

**Solución (Linux):**
```bash
# Temporal
ulimit -n 65536

# Permanente
sudo nano /etc/security/limits.conf
# Añadir:
* soft nofile 65536
* hard nofile 65536
```

---

## 📊 Monitoreo y Logs

### Habilitar Query Logging

```php
// En AppServiceProvider.php boot()
if (config('app.debug')) {
    \DB::listen(function ($query) {
        \Log::debug('Query: ' . $query->sql);
        \Log::debug('Bindings: ' . json_encode($query->bindings));
        \Log::debug('Time: ' . $query->time . 'ms');
    });
}
```

---

### Log de Acciones Importantes

Ya implementado en `CashFundMovementAuditLog`, pero para acciones del sistema:

```php
use Illuminate\Support\Facades\Log;

// En Approvals::approveFund()
Log::info('Fondo aprobado', [
    'fondo_id' => $this->selectedFondo->id,
    'aprobado_por' => Auth::id(),
    'timestamp' => now()
]);
```

---

### Monitorear Espacio en Disco

```bash
# Script para cron
#!/bin/bash
USAGE=$(df -h /var/www/TerrenaLaravel/storage | tail -1 | awk '{print $5}' | sed 's/%//')

if [ $USAGE -gt 80 ]; then
    echo "ALERTA: Disco al $USAGE%" | mail -s "Disco lleno" admin@terrena.com
fi
```

---

## 🔍 Debugging

### Habilitar Debug Mode (Solo desarrollo)

```env
APP_DEBUG=true
```

**⚠️ NUNCA en producción**

---

### Laravel Debugbar (Desarrollo)

```bash
composer require barryvdh/laravel-debugbar --dev
```

---

### Livewire Debugging

```blade
@if(config('app.debug'))
    <div class="alert alert-warning">
        <h6>Debug Info:</h6>
        <pre>{{ json_encode($fondo, JSON_PRETTY_PRINT) }}</pre>
    </div>
@endif
```

---

## 🔒 Seguridad

### Verificar Permisos de Archivos

```bash
# Storage debe ser writable
ls -la storage/app/public
# drwxr-xr-x para directorios
# -rw-r--r-- para archivos

# Corregir si es necesario
chmod -R 775 storage
chown -R www-data:www-data storage
```

---

### Actualizar Dependencias

```bash
# Ver outdated
composer outdated

# Actualizar Laravel
composer update laravel/framework

# Actualizar Livewire
composer update livewire/livewire

# Actualizar todo (con precaución)
composer update
```

---

### SQL Injection Protection

✅ Eloquent ORM protege automáticamente
✅ Siempre usar binding de parámetros
❌ NUNCA concatenar SQL directamente

```php
// ✅ BIEN
$fondos = CashFund::where('sucursal_id', $id)->get();

// ❌ MAL
$fondos = DB::select("SELECT * FROM cash_funds WHERE sucursal_id = {$id}");
```

---

## 📈 Performance Optimization

### Índices de Base de Datos

Verificar que existan índices en:
```sql
-- Ver índices
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'selemti'
AND tablename LIKE 'cash%';
```

Deberían existir índices en:
- `cash_funds.sucursal_id`
- `cash_funds.fecha`
- `cash_funds.estado`
- `cash_fund_movements.cash_fund_id`
- `cash_fund_movements.tipo`
- `cash_fund_arqueos.cash_fund_id` (UNIQUE)
- `audit_log.movement_id`

---

### Cache de Config

```bash
# En producción
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Al hacer cambios
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

---

### Optimizar Composer

```bash
composer dump-autoload --optimize
composer install --optimize-autoloader --no-dev
```

---

## 💾 Respaldos

### Script de Respaldo Automático

```bash
#!/bin/bash
# backup-caja-chica.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/terrena"
DB_NAME="pos"

# Crear directorio si no existe
mkdir -p $BACKUP_DIR

# Respaldo de BD
pg_dump -h localhost -p 5433 -U postgres -d $DB_NAME \
    -t selemti.cash_funds \
    -t selemti.cash_fund_movements \
    -t selemti.cash_fund_arqueos \
    -t selemti.cash_fund_movement_audit_log \
    > $BACKUP_DIR/db_caja_$DATE.sql

# Respaldo de archivos
tar -czf $BACKUP_DIR/attachments_$DATE.tar.gz \
    storage/app/public/cash_fund_attachments

# Eliminar backups antiguos (>30 días)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completado: $DATE"
```

**Agregar a cron:**
```cron
# Respaldo diario a las 2 AM
0 2 * * * /var/www/scripts/backup-caja-chica.sh >> /var/log/backup-caja.log 2>&1
```

---

## 📞 Soporte

### Reportar Bugs

1. Verificar logs: `storage/logs/laravel.log`
2. Reproducir el error
3. Documentar pasos exactos
4. Crear issue en GitHub con:
   - Descripción del error
   - Pasos para reproducir
   - Logs relevantes
   - Versión de Laravel/Livewire

---

### Contacto

- **Email:** soporte@terrena.com
- **GitHub:** https://github.com/tu-org/TerrenaLaravel/issues
- **Documentación:** `docs/CajaChica/FondoCaja/`
