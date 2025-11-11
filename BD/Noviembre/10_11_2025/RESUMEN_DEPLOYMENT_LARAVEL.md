# Deployment Laravel 12 + Vite a Ubuntu con Multi-IP Support
## Fecha: 10 de Noviembre 2025

---

## 📋 Resumen Ejecutivo

**Objetivo:** Desplegar la aplicación Laravel 12 + Vite en servidor Ubuntu con Apache, accesible desde múltiples IPs (LAN y Tailscale VPN) sin conflictos de redirección.

**Resultado:** ✅ Deployment exitoso con acceso desde:
- **LAN**: http://192.168.1.235/terrena2
- **Tailscale VPN**: http://100.126.124.101/terrena2

---

## 🏗️ Arquitectura del Servidor

### Servidor de Producción
- **OS**: Ubuntu (versión actual)
- **Servidor Web**: Apache 2.4.58 (libphp, NO php-fpm)
- **Base de Datos**: PostgreSQL 9.5 (puerto 5432) + MySQL
- **PHP**: Versión compatible con Laravel 12
- **Red**:
  - IP LAN: 192.168.1.235
  - IP Tailscale: 100.126.124.101
  - Gateway: 192.168.1.251

### Path del Proyecto
- **Servidor**: `/var/www/kds/terrenaPos`
- **URL Base**: `/terrena2/`
- **DocumentRoot**: `/var/www/kds/terrenaPos/public`

---

## 🚀 Proceso de Deployment

### 1. Configuración de Apache

**Archivo**: `/etc/apache2/sites-available/kds.conf`

```apache
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot /var/www/kds

    # Rutas existentes (NO modificadas)
    Alias /barra /var/www/kds/barra
    Alias /cocina /var/www/kds/cocina
    Alias /voceo /var/www/kds/voceo
    Alias /terrena /var/www/kds/terrena

    # Nueva ruta Laravel (AGREGADA)
    Alias /terrena2 /var/www/kds/terrenaPos/public
    <Directory /var/www/kds/terrenaPos/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        DirectoryIndex index.php

        <FilesMatch "^\.env">
            Require all denied
        </FilesMatch>
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/kds_error.log
    CustomLog ${APACHE_LOG_DIR}/kds_access.log combined
</VirtualHost>
```

**Comandos ejecutados:**
```bash
sudo systemctl restart apache2
```

---

### 2. Configuración de Laravel (.env)

**Archivo**: `/var/www/kds/terrenaPos/.env`

```env
APP_NAME="Terrena POS"
APP_ENV=production
APP_DEBUG=false
APP_TIMEZONE=America/Mexico_City
APP_URL=http://192.168.1.235/terrena2
APP_LOCALE=es

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=pos
DB_USERNAME=postgres
DB_PASSWORD="T3rr3n4#p0s"

SESSION_DRIVER=database
SESSION_PATH=/terrena2

ASSET_URL=${APP_URL}
LIVEWIRE_APP_URL=${APP_URL}
LIVEWIRE_ASSET_URL=${APP_URL}
```

**Nota importante**: La contraseña PostgreSQL debe estar entrecomillada debido a caracteres especiales.

---

### 3. Configuración de Vite

**Archivo Local**: `C:\xampp3\htdocs\TerrenaLaravel\vite.config.js`

```javascript
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    base: '/terrena2/',  // ← CRÍTICO para subdirectorio
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
});
```

**Build ejecutado localmente:**
```bash
cd C:\xampp3\htdocs\TerrenaLaravel
npm run build
```

**Archivos generados en**: `public/build/`

---

### 4. Fix del .htaccess

**Problema encontrado**: El `.htaccess` tenía `RewriteBase /TerrenaLaravel/` del entorno local.

**Archivo**: `/var/www/kds/terrenaPos/public/.htaccess`

```apache
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    # Force UTF-8 encoding
    AddDefaultCharset UTF-8
    <FilesMatch "\.(htm|html|css|js|php)$">
        AddCharset UTF-8 .htm .html .css .js .php
    </FilesMatch>

    RewriteEngine On
    RewriteBase /terrena2/  # ← CAMBIADO de /TerrenaLaravel/

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect Trailing Slashes If Not A Folder...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    # Send Requests To Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
```

---

### 5. Solución Multi-IP: DynamicUrlMiddleware

**Problema**: Acceder desde Tailscale (100.126.124.101) redirigía a la IP LAN (192.168.1.235), inaccesible desde fuera.

**Solución**: Middleware que detecta la IP del request y ajusta las URLs dinámicamente.

**Archivo**: `app/Http/Middleware/DynamicUrlMiddleware.php`

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\URL;
use Symfony\Component\HttpFoundation\Response;

class DynamicUrlMiddleware
{
    /**
     * Handle an incoming request.
     *
     * Dynamically sets the application URL based on the incoming request's
     * scheme and host. This allows the application to work correctly when
     * accessed from multiple IPs (e.g., LAN and Tailscale VPN).
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Solo aplicar en producción (no en desarrollo local)
        if (app()->environment('production')) {
            // Detectar host y scheme desde el request actual
            $url = $request->getSchemeAndHttpHost() . '/terrena2';
            URL::forceRootUrl($url);
        }

        return $next($request);
    }
}
```

**Registro del Middleware**: `bootstrap/app.php`

```php
->withMiddleware(function (Middleware $middleware): void {
    // Middleware global para detección dinámica de URL (multi-IP support)
    $middleware->prepend(\App\Http\Middleware\DynamicUrlMiddleware::class);

    $middleware->alias([
        'permission' => \Spatie\Permission\Middleware\PermissionMiddleware::class,
        'role' => \Spatie\Permission\Middleware\RoleMiddleware::class,
        'role_or_permission' => \Spatie\Permission\Middleware\RoleOrPermissionMiddleware::class,
    ]);
})
```

**Funcionamiento:**
- En **local** (`APP_ENV=local`): NO modifica URLs → mantiene `/TerrenaLaravel/`
- En **producción** (`APP_ENV=production`): detecta IP del request → ajusta URLs a `/terrena2/`

---

## 📦 Archivos Subidos al Servidor

### Mediante pscp (Windows → Ubuntu)

```bash
# Rutas
pscp -r -pw T3rr3n4#123 routes terrena@100.126.124.101:/var/www/kds/terrenaPos/

# Build assets
pscp -r -pw T3rr3n4#123 public/build terrena@100.126.124.101:/var/www/kds/terrenaPos/public/

# Middleware y bootstrap
pscp -pw T3rr3n4#123 app/Http/Middleware/DynamicUrlMiddleware.php terrena@100.126.124.101:/tmp/
pscp -pw T3rr3n4#123 bootstrap/app.php terrena@100.126.124.101:/tmp/

# Views (comprimidas)
cd resources && tar czf /tmp/views.tar.gz views
pscp -pw T3rr3n4#123 /tmp/views.tar.gz terrena@100.126.124.101:/tmp/
```

### En el servidor
```bash
# Mover archivos
cp /tmp/DynamicUrlMiddleware.php /var/www/kds/terrenaPos/app/Http/Middleware/
cp /tmp/app.php /var/www/kds/terrenaPos/bootstrap/app.php

# Extraer views
cd /var/www/kds/terrenaPos/resources
tar xzf /tmp/views.tar.gz

# Permisos
chown -R terrena:www-data /var/www/kds/terrenaPos
chmod -R 755 /var/www/kds/terrenaPos
chmod -R 775 /var/www/kds/terrenaPos/storage
chmod -R 775 /var/www/kds/terrenaPos/bootstrap/cache
```

---

## 🗄️ Configuración de Base de Datos

### PostgreSQL

**Puerto**: 5432
**Base de datos**: `pos`
**Usuario**: `postgres`
**Contraseña**: `T3rr3n4#p0s`

**Comandos ejecutados:**
```bash
# Cambiar contraseña de postgres
sudo -u postgres psql
ALTER USER postgres PASSWORD 'T3rr3n4#p0s';
\q

# Verificar conexión
psql -h localhost -U postgres -d pos -c "SELECT version();"
```

### Migraciones
```bash
cd /var/www/kds/terrenaPos
php artisan migrate
```

**Resultado**: 34 migraciones ejecutadas exitosamente.

---

## 🌐 Problema y Solución de Tailscale

### Problema Encontrado

**Síntoma**: No se podía conectar al servidor vía Tailscale (100.126.124.101)

**Diagnóstico:**
```bash
# Status mostraba offline
tailscale status
# 100.126.124.101  pos-terrena  gjselem@  linux    offline

# Ping a Internet fallaba
ping -c 3 8.8.8.8
# 100% packet loss
```

**Causa raíz**: El servidor perdió conexión a Internet temporalmente, causando que Tailscale no pudiera comunicarse con los servidores de control.

### Solución Aplicada

```bash
# 1. Reiniciar Tailscale
sudo tailscale down
sudo tailscale up

# 2. Verificar reconexión
tailscale status
# 100.126.124.101  pos-terrena  gjselem@  linux    active
# 100.98.146.92    lap-tavo     gjselem@  windows  active
```

### Solución Permanente: Auto-Start Service

**Creamos servicio systemd para auto-conexión**

**Archivo**: `/etc/systemd/system/tailscale-up.service`

```ini
[Unit]
Description=Tailscale auto-connect on boot
After=tailscaled.service
Wants=tailscaled.service

[Service]
Type=oneshot
ExecStart=/usr/bin/tailscale up
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

**Habilitar servicio:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable tailscale-up.service
```

---

## ⚙️ Servicios Configurados para Auto-Start

### Verificación Final

```bash
systemctl is-enabled apache2 postgresql mysql tailscaled tailscale-up ssh ufw
```

### Resultado: Todos Habilitados ✅

| Servicio | Estado | Descripción |
|----------|--------|-------------|
| **apache2** | enabled | Servidor web (Laravel app) |
| **postgresql** | enabled | Base de datos (Floreant POS) |
| **mysql** | enabled | Base de datos adicional |
| **tailscaled** | enabled | Daemon de Tailscale |
| **tailscale-up** | enabled | Auto-conexión Tailscale |
| **ssh** | enabled | Servidor SSH |
| **ufw** | enabled | Firewall |

### Orden de Inicio al Reiniciar

1. **tailscaled** → Inicia el daemon de Tailscale
2. **tailscale-up** → Ejecuta `tailscale up` para conectarse
3. **apache2** → Inicia el servidor web
4. **postgresql** + **mysql** → Inician las bases de datos
5. **ssh** → Permite acceso remoto
6. **ufw** → Activa el firewall

---

## 🧪 Pruebas y Verificación

### Test 1: Acceso desde LAN
```bash
curl -I http://192.168.1.235/terrena2/
# HTTP/1.1 302 Found
# Location: http://192.168.1.235/terrena2/login
```
✅ Redirige correctamente a la misma IP

### Test 2: Acceso desde Tailscale
```bash
curl -I http://100.126.124.101/terrena2/
# HTTP/1.1 302 Found
# Location: http://100.126.124.101/terrena2/login
```
✅ Redirige correctamente a la misma IP (NO a 192.168.1.235)

### Test 3: Página de Login
```bash
curl -sL http://100.126.124.101/terrena2/login | grep '<title>'
# <title>Acceder a TerrenaPOS</title>
```
✅ Laravel renderiza correctamente

### Test 4: Assets URLs
```bash
curl -sL http://100.126.124.101/terrena2/login | grep -o 'http://[^"]*terrena2[^"]*' | head -5
```
Resultado:
```
http://100.126.124.101/terrena2/assets/css/bootstrap.min.css
http://100.126.124.101/terrena2/assets/fontawesome-free-7.0.1-web/css/all.min.css
http://100.126.124.101/terrena2/assets/css/terrena.css
http://100.126.124.101/terrena2/assets/img/logo.svg
```
✅ Todos los assets usan la IP correcta del request

---

## 🐛 Problemas Encontrados y Soluciones

### Problema 1: SSH Deshabilitado
**Error**: `ssh.service: disabled`
**Solución**:
```bash
sudo systemctl enable ssh
```

### Problema 2: Composer Install Falla
**Error**: `require(routes/api.php): Failed to open stream`
**Causa**: Faltaba el directorio `routes/` en el servidor
**Solución**: Subir directorio completo vía pscp

### Problema 3: View Not Found
**Error**: `View [auth.login] not found`
**Causa**: Faltaba el directorio `resources/views/` en el servidor
**Solución**: Comprimir y subir views

### Problema 4: 404 en Todas las Rutas
**Error**: Apache 404 en `/terrena2/login`
**Causa**: `.htaccess` con `RewriteBase /TerrenaLaravel/`
**Solución**: Cambiar a `RewriteBase /terrena2/`

### Problema 5: Redirección a IP Incorrecta
**Error**: Desde 100.126.124.101 redirige a 192.168.1.235
**Causa**: Laravel usa `APP_URL` estático del `.env`
**Solución**: Implementar `DynamicUrlMiddleware`

### Problema 6: Middleware Afecta Desarrollo Local
**Error**: Local redirige de `/TerrenaLaravel/` a `/terrena2/`
**Causa**: Middleware se ejecuta en todos los entornos
**Solución**: Agregar condición `if (app()->environment('production'))`

---

## 📝 Comandos Útiles

### Comandos de Deployment
```bash
# En local (Windows)
cd C:\xampp3\htdocs\TerrenaLaravel
npm run build
pscp -r -pw T3rr3n4#123 public/build terrena@100.126.124.101:/var/www/kds/terrenaPos/public/

# En servidor (Ubuntu)
cd /var/www/kds/terrenaPos
composer install --no-dev --optimize-autoloader
php artisan config:clear
php artisan route:clear
php artisan view:clear
sudo systemctl restart apache2
```

### Comandos de Verificación
```bash
# Verificar servicios
systemctl is-enabled apache2 postgresql tailscaled ssh
systemctl status apache2

# Verificar Tailscale
tailscale status
tailscale ping 100.126.124.101

# Logs
sudo tail -f /var/log/apache2/kds_error.log
tail -f /var/www/kds/terrenaPos/storage/logs/laravel.log
sudo journalctl -u tailscaled -f
```

### Comandos de Troubleshooting
```bash
# Test conectividad red
ping -c 3 8.8.8.8
ping -c 3 192.168.1.251  # Gateway

# Verificar rutas Laravel
php artisan route:list --path=login

# Test HTTP directo
curl -I http://localhost/terrena2/
curl -I http://192.168.1.235/terrena2/
curl -I http://100.126.124.101/terrena2/
```

---

## 🔐 Credenciales y Accesos

### SSH
- **Usuario**: `terrena`
- **Contraseña**: `T3rr3n4#123`
- **IPs**:
  - LAN: `ssh terrena@192.168.1.235`
  - Tailscale: `ssh terrena@100.126.124.101`

### PostgreSQL
- **Usuario**: `postgres`
- **Contraseña**: `T3rr3n4#p0s`
- **Puerto**: `5432`
- **Base de datos**: `pos`
- **Conexión**: `psql -h localhost -U postgres -d pos`

### Laravel App
- **URL LAN**: http://192.168.1.235/terrena2
- **URL Tailscale**: http://100.126.124.101/terrena2

---

## 📚 Documentación de Referencia

### Laravel
- Subdirectory Deployment: https://laravel.com/docs/12.x/deployment
- Configuration: https://laravel.com/docs/12.x/configuration
- Middleware: https://laravel.com/docs/12.x/middleware

### Vite
- Base Path Configuration: https://vite.dev/config/shared-options.html#base
- Laravel Integration: https://laravel.com/docs/12.x/vite

### Apache
- Alias Directive: https://httpd.apache.org/docs/2.4/mod/mod_alias.html
- .htaccess: https://httpd.apache.org/docs/2.4/howto/htaccess.html

### Tailscale
- Linux Setup: https://tailscale.com/kb/1031/install-linux
- Auto-start: https://tailscale.com/kb/1189/systemd

---

## ✅ Checklist de Deployment

- [x] Configurar Apache VirtualHost con Alias
- [x] Configurar .env de producción
- [x] Ajustar vite.config.js con base path
- [x] Hacer build de Vite localmente
- [x] Subir archivos al servidor (routes, views, build)
- [x] Instalar dependencias PHP (composer install)
- [x] Ejecutar migraciones
- [x] Configurar permisos de storage y cache
- [x] Ajustar .htaccess con RewriteBase correcto
- [x] Implementar DynamicUrlMiddleware
- [x] Registrar middleware en bootstrap/app.php
- [x] Restaurar conexión Tailscale
- [x] Crear servicio tailscale-up
- [x] Habilitar SSH para auto-start
- [x] Verificar todos los servicios auto-start
- [x] Probar acceso desde LAN
- [x] Probar acceso desde Tailscale
- [x] Verificar que los assets cargan correctamente
- [x] Confirmar que las redirecciones usan IP correcta

---

## 🎯 Resultado Final

### ✅ Deployment Completado Exitosamente

**Aplicación accesible desde:**
- LAN: http://192.168.1.235/terrena2 ✓
- Tailscale VPN: http://100.126.124.101/terrena2 ✓

**Características implementadas:**
- ✓ Multi-IP support sin conflictos de redirección
- ✓ Detección dinámica de URL por request
- ✓ Entorno local intacto (no afectado)
- ✓ Todos los servicios configurados para auto-start
- ✓ Tailscale con reconexión automática
- ✓ Rutas existentes preservadas (/barra, /cocina, etc.)

**Beneficios:**
- Acceso remoto seguro vía Tailscale VPN
- Sin necesidad de IP pública o port forwarding
- Alta disponibilidad (servicios auto-start)
- Desarrollo local no interrumpido
- URLs y assets siempre correctos independiente del origen

---

## 📞 Contacto y Soporte

**Desarrollado por**: Claude Code (AI Assistant)
**Fecha**: 10 de Noviembre 2025
**Sesión**: Deployment Laravel 12 + Multi-IP Support

---

**Nota**: Este documento debe ser guardado como referencia para futuros deployments y troubleshooting.
