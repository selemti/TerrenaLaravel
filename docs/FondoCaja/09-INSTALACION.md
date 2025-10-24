# 09 - GUÍA DE INSTALACIÓN Y CONFIGURACIÓN

## 🚀 Instalación Completa

### Prerrequisitos

✅ **Software Requerido:**
- PHP 8.2 o superior
- Composer 2.x
- PostgreSQL 9.5 o superior
- Node.js 18.x o superior (para Vite)
- Git

✅ **Extensiones PHP:**
- pdo_pgsql
- mbstring
- openssl
- tokenizer
- xml
- fileinfo

✅ **Datos Previos:**
- Usuarios creados en tabla `users`
- Sucursales en `selemti.cat_sucursales`
- Base de datos PostgreSQL configurada

---

## 📦 Paso 1: Clonar/Actualizar Repositorio

```bash
# Si es un proyecto nuevo
git clone https://github.com/tu-org/TerrenaLaravel.git
cd TerrenaLaravel

# Si ya existe el proyecto
cd TerrenaLaravel
git pull origin main
```

---

## ⚙️ Paso 2: Configurar Entorno

### 2.1 Copiar archivo de configuración

```bash
cp .env.example .env
```

### 2.2 Editar `.env`

```env
APP_NAME="TerrenaLaravel"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost/TerrenaLaravel

DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5433
DB_DATABASE=pos
DB_USERNAME=postgres
DB_PASSWORD=tu_password_aqui

FILESYSTEM_DISK=public

SESSION_DRIVER=database
CACHE_STORE=database
```

### 2.3 Generar clave de aplicación

```bash
php artisan key:generate
```

---

## 📚 Paso 3: Instalar Dependencias

### 3.1 PHP (Composer)

```bash
composer install --optimize-autoloader --no-dev
```

**Para desarrollo:**
```bash
composer install
```

### 3.2 JavaScript (NPM)

```bash
npm install
npm run build
```

**Para desarrollo:**
```bash
npm install
npm run dev
```

---

## 🗄️ Paso 4: Base de Datos

### 4.1 Ejecutar Migraciones

```bash
# Ver estado de migraciones
php artisan migrate:status

# Ejecutar migraciones pendientes
php artisan migrate

# Si necesitas empezar de cero (¡CUIDADO en producción!)
php artisan migrate:fresh
```

### 4.2 Verificar Tablas Creadas

```bash
"/c/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" -h localhost -p 5433 -U postgres -d pos -c "\dt selemti.cash*"
```

Deberías ver:
- `selemti.cash_funds`
- `selemti.cash_fund_movements`
- `selemti.cash_fund_arqueos`
- `selemti.cash_fund_movement_audit_log`

---

## 📁 Paso 5: Storage y Permisos

### 5.1 Crear Symlink de Storage

```bash
php artisan storage:link
```

Esto crea: `public/storage` → `storage/app/public`

### 5.2 Crear Directorios

```bash
mkdir -p storage/app/public/cash_fund_attachments
chmod -R 775 storage
chmod -R 775 bootstrap/cache
```

**En Windows (XAMPP):**
Los permisos generalmente no son problema, pero asegúrate de que Apache tenga acceso de lectura/escritura.

---

## 🔐 Paso 6: Configurar Permisos

### 6.1 Método Rápido (Tinker)

```bash
php artisan tinker
```

```php
// Crear permisos
\Spatie\Permission\Models\Permission::create(['name' => 'approve-cash-funds']);
\Spatie\Permission\Models\Permission::create(['name' => 'close-cash-funds']);

// Asignar a un usuario de prueba (ajusta el ID)
$user = \App\Models\User::find(1);
$user->givePermissionTo(['approve-cash-funds', 'close-cash-funds']);

exit
```

### 6.2 Método Formal (Seeder)

Ver archivo `07-PERMISOS.md` para seeders completos.

---

## 🔧 Paso 7: Configuración de Aplicación

### 7.1 Optimizar para Producción

```bash
# Cache de configuración
php artisan config:cache

# Cache de rutas
php artisan route:cache

# Cache de vistas
php artisan view:cache

# Optimizar autoloader
composer dump-autoload --optimize
```

### 7.2 Para Desarrollo

```bash
# Limpiar caches
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear
```

---

## 🌐 Paso 8: Configuración de Servidor Web

### Apache (XAMPP)

**Virtual Host (opcional pero recomendado):**

`C:\xampp\apache\conf\extra\httpd-vhosts.conf`

```apache
<VirtualHost *:80>
    ServerName terrena.local
    DocumentRoot "C:/xampp/htdocs/TerrenaLaravel/public"

    <Directory "C:/xampp/htdocs/TerrenaLaravel/public">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

**Hosts:**

`C:\Windows\System32\drivers\etc\hosts`

```
127.0.0.1    terrena.local
```

**Reiniciar Apache:**
- Panel de Control XAMPP → Apache → Restart

---

### Nginx

```nginx
server {
    listen 80;
    server_name terrena.local;
    root /var/www/TerrenaLaravel/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

---

## ✅ Paso 9: Verificación

### 9.1 Verificar Instalación

```bash
# Ver versiones
php artisan --version
php artisan migrate:status

# Verificar rutas
php artisan route:list | grep cashfund
```

Deberías ver:
- GET `/cashfund`
- GET `/cashfund/open`
- GET `/cashfund/{id}/movements`
- GET `/cashfund/{id}/arqueo`
- GET `/cashfund/{id}/detail`
- GET `/cashfund/approvals`

### 9.2 Probar en Navegador

```
http://localhost/TerrenaLaravel/cashfund
```

O si configuraste virtual host:
```
http://terrena.local/cashfund
```

**Deberías ver:**
- La lista de fondos (vacía si es primera vez)
- Botón "Abrir fondo"
- Botón "Aprobaciones" (si tienes el permiso)

---

## 🔍 Paso 10: Verificación de Funcionalidad

### Test de Apertura de Fondo

1. Click en "Abrir fondo"
2. Llenar formulario
3. Click "Abrir fondo"
4. Debería redirigir a `/cashfund/{id}/movements`

### Test de Movimiento

1. En la página de movements
2. Registrar un egreso de $100
3. Verificar que aparezca en la lista
4. Verificar que el saldo disponible se actualice

### Test de Adjunto

1. Click en ícono de adjuntar en un movimiento
2. Seleccionar archivo PDF o imagen
3. Subir
4. Verificar que aparezca el ícono verde de "Con comprobante"
5. Click en el ícono verde
6. Debería abrir el archivo en nueva pestaña

### Test de Arqueo

1. Click "Realizar Arqueo"
2. Ingresar monto contado
3. Verificar cálculo de diferencia
4. Click "Confirmar y cerrar"
5. Estado debería cambiar a EN_REVISION

### Test de Aprobaciones

1. Navegar a `/cashfund/approvals`
2. Seleccionar fondo en revisión
3. Verificar datos
4. Click "Aprobar y cerrar definitivamente"
5. Estado debería cambiar a CERRADO

---

## 🐛 Troubleshooting

### Error: "SQLSTATE[08006] Connection refused"

**Causa:** PostgreSQL no está corriendo o configuración incorrecta

**Solución:**
```bash
# Verificar si PostgreSQL está corriendo
sudo systemctl status postgresql

# O en Windows XAMPP: verificar en Panel de Control

# Verificar conexión
psql -h localhost -p 5433 -U postgres -d pos
```

---

### Error: "Class 'Livewire\Component' not found"

**Causa:** Livewire no está instalado

**Solución:**
```bash
composer require livewire/livewire
```

---

### Error: 403 Forbidden al abrir comprobantes

**Causa:** Symlink de storage no existe

**Solución:**
```bash
php artisan storage:link
```

---

### Error: "Permission denied" en storage

**Causa:** Permisos incorrectos

**Solución (Linux/Mac):**
```bash
sudo chown -R www-data:www-data storage
sudo chmod -R 775 storage
```

**Windows:** Verificar que Apache tenga permisos de escritura.

---

### Error: "No such file or directory" en uploads

**Causa:** Directorio de attachments no existe

**Solución:**
```bash
mkdir -p storage/app/public/cash_fund_attachments
chmod -R 775 storage/app/public/cash_fund_attachments
```

---

## 📋 Checklist Post-Instalación

- [ ] Migraciones ejecutadas correctamente
- [ ] Symlink de storage creado
- [ ] Permisos configurados (approve-cash-funds, close-cash-funds)
- [ ] Al menos un usuario con permisos asignados
- [ ] Sucursales existen en `selemti.cat_sucursales`
- [ ] Se puede acceder a `/cashfund`
- [ ] Se puede abrir un fondo de prueba
- [ ] Se puede registrar un movimiento
- [ ] Se puede subir un comprobante
- [ ] Se puede realizar arqueo
- [ ] Se puede aprobar un fondo
- [ ] La impresión funciona correctamente

---

## 📱 Configuración Adicional (Opcional)

### Queue Workers (para jobs en background)

```bash
# Configurar supervisor (Linux)
sudo nano /etc/supervisor/conf.d/terrena-worker.conf
```

```ini
[program:terrena-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/TerrenaLaravel/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/TerrenaLaravel/storage/logs/worker.log
```

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start terrena-worker:*
```

---

### Cron Jobs (para tareas programadas)

```bash
crontab -e
```

```cron
* * * * * cd /var/www/TerrenaLaravel && php artisan schedule:run >> /dev/null 2>&1
```

---

## 🎉 Instalación Completa

Si todos los pasos se completaron correctamente, tu sistema de Fondo de Caja Chica está listo para usar en producción.

**Próximos pasos:**
- Capacitar usuarios
- Definir políticas de uso
- Configurar respaldos automáticos
- Monitorear logs
