# Guía de Deployment · Terrena V4.0
**Versión:** 2.0  
**Fecha:** 2025-11-14  
**Autor:** Equipo Terrena

---

## Propósito

Este documento describe el proceso completo para desplegar actualizaciones desde el entorno de **desarrollo local (Windows + XAMPP)** hacia el **servidor de producción (Ubuntu + Apache)**.

---

## Tabla de Contenidos

1. [Arquitectura de Ambientes](#1-arquitectura-de-ambientes)
2. [Pre-requisitos](#2-pre-requisitos)
3. [Checklist Pre-Deployment](#3-checklist-pre-deployment)
4. [Proceso de Deployment](#4-proceso-de-deployment)
5. [Configuración del Servidor](#5-configuración-del-servidor)
6. [Verificación Post-Deployment](#6-verificación-post-deployment)
7. [Troubleshooting](#7-troubleshooting)
8. [Rollback](#8-rollback)

---

## 1. Arquitectura de Ambientes

### 1.1 Ambiente Local (Desarrollo)

```yaml
Sistema Operativo: Windows 10/11
Servidor Web: Apache 2.4 (XAMPP)
PHP: 8.3
Base de Datos: PostgreSQL 14+ (puerto 5433)
  - Host: 127.0.0.1 (local) o 172.24.240.1 (WSL)
  - Esquema: selemti
  - Usuario: postgres
Ruta Proyecto: C:\xampp3\htdocs\TerrenaLaravel\
URL Local: http://localhost/TerrenaLaravel
```

### 1.2 Ambiente Producción (Ubuntu Server)

```yaml
Sistema Operativo: Ubuntu 22.04 LTS
Servidor Web: Apache 2.4.58
PHP: 8.x
Base de Datos: PostgreSQL 14+ (puerto 5432)
  - Host: localhost
  - Esquema: selemti
  - Usuario: [según .env producción]
Ruta Proyecto: /var/www/kds/terrenaPos/
URLs Acceso:
  - Red Local: http://192.168.1.235/terrena2/
  - Tailscale VPN: http://100.126.124.101/terrena2/
Usuario SSH: terrena
Permisos: terrena tiene sudo
```

### 1.3 Diferencias Clave

| Concepto | Local | Producción |
|----------|-------|------------|
| URL Base | `/TerrenaLaravel` | `/terrena2` |
| Document Root | `C:\xampp3\htdocs\TerrenaLaravel\public` | `/var/www/kds/terrenaPos/public` |
| Configuración Apache | VirtualHost directo | **Alias** `/terrena2` |
| Usuario Web | Sistema | `www-data` |
| Permisos Archivos | 755/644 (Windows) | 755/644 (Linux, owner: www-data) |
| Storage Owner | Usuario Windows | `www-data` |
| .env | `APP_ENV=local` | `APP_ENV=production` |

---

## 2. Pre-requisitos

### 2.1 Herramientas Necesarias

- ✅ **WinSCP** (transferencia archivos SFTP)
- ✅ **PuTTY** o **plink** (conexión SSH)
- ✅ **Git** (control de versiones)
- ✅ **Composer** (local para generar lock actualizado)
- ✅ **npm** (local para build assets)

### 2.2 Credenciales Requeridas

```bash
# SSH Producción
Host: 100.126.124.101 (o 192.168.1.235 en red local)
Usuario: terrena
Password: [solicitar a admin]
```

### 2.3 Accesos Base de Datos

**Local:**
```env
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5433
DB_DATABASE=pos
DB_USERNAME=postgres
DB_PASSWORD="[local password]"
DB_SCHEMA=selemti,public
```

**Producción:** (NO modificar, ya está configurado)
```bash
# Ver en servidor: /var/www/kds/terrenaPos/.env
# NO copiar .env desde local
```

---

## 3. Checklist Pre-Deployment

### 3.1 Verificación Local

- [ ] **Tests ejecutados:** `php artisan test`
- [ ] **Código limpio:** `./vendor/bin/pint` (PSR-12)
- [ ] **Migraciones probadas:** `php artisan migrate:status`
- [ ] **Seeders funcionales** (si aplica)
- [ ] **Assets compilados:** `npm run build` (producción)
- [ ] **Composer actualizado:** `composer install --no-dev --optimize-autoloader`
- [ ] **Cache limpiado:** 
  ```bash
  php artisan config:clear
  php artisan cache:clear
  php artisan route:clear
  php artisan view:clear
  ```
- [ ] **Git limpio:** 
  ```bash
  git status
  git add .
  git commit -m "feat: [descripción cambios]"
  git push origin main
  ```

### 3.2 Backup Producción

Antes de cualquier deployment:

```bash
# Conectar SSH
ssh terrena@100.126.124.101

# Backup Base de Datos
cd /var/www/kds/terrenaPos
php artisan backup:database

# Backup Archivos (manual)
cd /var/www/kds
sudo tar -czf terrenaPos_backup_$(date +%Y%m%d_%H%M%S).tar.gz terrenaPos/
```

---

## 4. Proceso de Deployment

### 4.1 Identificar Archivos a Copiar

**IMPORTANTE:** NO copiar TODA la carpeta. Solo archivos modificados.

#### Archivos que SÍ se copian:

```
✅ app/                          # Código PHP (controllers, models, services, livewire)
✅ resources/views/              # Vistas Blade/Livewire
✅ resources/js/                 # JavaScript (si cambió)
✅ resources/css/                # CSS (si cambió)
✅ routes/                       # Rutas web/api
✅ config/                       # Configuraciones (excepto .env)
✅ database/migrations/          # Nuevas migraciones
✅ database/seeders/             # Seeders actualizados
✅ public/build/                 # Assets compilados (npm run build)
✅ composer.json                 # Si hay nuevas dependencias
✅ composer.lock                 # SIEMPRE copiar con composer.json
✅ package.json                  # Si hay nuevas dependencias JS
✅ package-lock.json             # SIEMPRE copiar con package.json
```

#### Archivos que NO se copian:

```
❌ .env                          # Producción tiene su propia configuración
❌ vendor/                       # Se regenera con composer install
❌ node_modules/                 # Se regenera con npm install
❌ storage/logs/                 # Logs del servidor no se sobrescriben
❌ storage/framework/cache/      # Cache del servidor
❌ storage/framework/sessions/   # Sesiones activas
❌ .git/                         # Control de versiones (opcional)
❌ tests/                        # Tests no van a producción
❌ .gitignore, .editorconfig     # Configuración desarrollo
```

### 4.2 Método 1: Copia Manual con WinSCP (Recomendado)

1. **Abrir WinSCP**
   - Protocolo: SFTP
   - Host: `100.126.124.101`
   - Puerto: `22`
   - Usuario: `terrena`
   - Password: `[credencial]`

2. **Navegar a directorio remoto:**
   ```
   /var/www/kds/terrenaPos/
   ```

3. **Sincronizar carpetas modificadas:**
   - Arrastrar carpetas desde local a servidor
   - WinSCP pregunta si sobrescribir → Confirmar
   - **Verificar permisos** después de copiar (ver sección 4.5)

4. **Carpetas típicas a sincronizar:**
   ```
   C:\xampp3\htdocs\TerrenaLaravel\app\              → /var/www/kds/terrenaPos/app/
   C:\xampp3\htdocs\TerrenaLaravel\resources\views\  → /var/www/kds/terrenaPos/resources/views/
   C:\xampp3\htdocs\TerrenaLaravel\routes\           → /var/www/kds/terrenaPos/routes/
   C:\xampp3\htdocs\TerrenaLaravel\public\build\     → /var/www/kds/terrenaPos/public/build/
   ```

### 4.3 Método 2: Rsync (Avanzado)

Si tienes `rsync` en Windows (WSL):

```bash
# Desde WSL
rsync -avz --exclude='.env' --exclude='vendor/' --exclude='node_modules/' \
  /mnt/c/xampp3/htdocs/TerrenaLaravel/ \
  terrena@100.126.124.101:/var/www/kds/terrenaPos/
```

### 4.4 Método 3: Git Pull (Si hay repo configurado)

```bash
# En servidor
ssh terrena@100.126.124.101
cd /var/www/kds/terrenaPos
git pull origin main
```

### 4.5 Ajuste de Permisos Post-Copia

**CRÍTICO:** Después de copiar archivos, ajustar permisos:

```bash
# Conectar SSH
ssh terrena@100.126.124.101

# Cambiar owner a www-data (usuario Apache)
cd /var/www/kds
sudo chown -R www-data:www-data terrenaPos/

# Ajustar permisos directorios
sudo find terrenaPos/ -type d -exec chmod 755 {} \;

# Ajustar permisos archivos
sudo find terrenaPos/ -type f -exec chmod 644 {} \;

# Permisos especiales storage y bootstrap/cache
sudo chmod -R 775 terrenaPos/storage
sudo chmod -R 775 terrenaPos/bootstrap/cache
sudo chown -R www-data:www-data terrenaPos/storage
sudo chown -R www-data:www-data terrenaPos/bootstrap/cache
```

---

## 5. Configuración del Servidor

### 5.1 Configuración Apache (YA CONFIGURADO - NO MODIFICAR)

Archivo: `/etc/apache2/sites-enabled/kds.conf`

```apache
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot /var/www/kds

    # Alias para Terrena (CONFIGURACIÓN ACTIVA)
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

**Verificar que esté activo:**
```bash
sudo apache2ctl configtest
sudo systemctl status apache2
```

### 5.2 Configuración .htaccess (YA CONFIGURADO)

Archivo: `/var/www/kds/terrenaPos/public/.htaccess`

**CONFIGURACIÓN CORRECTA PARA ALIAS:**

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
    RewriteBase /terrena2/    # ← CRÍTICO: Debe coincidir con Alias Apache

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

**⚠️ ADVERTENCIA:**
- Si copia `.htaccess` desde local, debe tener `RewriteBase /terrena2/`
- Si dice `RewriteBase /TerrenaLaravel/` → ERROR 404

### 5.3 Variables .env Producción (NO MODIFICAR)

El servidor tiene su propio `.env` configurado:

```bash
# Ver (sin exponer passwords):
ssh terrena@100.126.124.101
cat /var/www/kds/terrenaPos/.env | grep -v PASSWORD
```

**Variables críticas que deben estar:**
```env
APP_ENV=production
APP_DEBUG=false
APP_URL=http://192.168.1.235/terrena2

DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=[nombre_bd_prod]
DB_USERNAME=[user_prod]
DB_SCHEMA=selemti,public

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=database
```

---

## 6. Verificación Post-Deployment

### 6.1 Comandos Post-Deployment (SIEMPRE ejecutar)

```bash
# Conectar SSH
ssh terrena@100.126.124.101
cd /var/www/kds/terrenaPos

# 1. Actualizar dependencias Composer (si composer.json cambió)
sudo -u www-data composer install --no-dev --optimize-autoloader

# 2. Ejecutar migraciones nuevas (si hay)
sudo -u www-data php artisan migrate --force

# 3. Limpiar caché Laravel
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan view:clear

# 4. Optimizar para producción
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache

# 5. Reiniciar queue workers (si usa colas)
sudo -u www-data php artisan queue:restart

# 6. Verificar permisos storage
ls -la storage/
ls -la bootstrap/cache/
```

### 6.2 Checklist de Verificación

- [ ] **URL funciona:** http://100.126.124.101/terrena2/ (o 192.168.1.235)
- [ ] **Login funciona**
- [ ] **Dashboard carga sin errores**
- [ ] **Módulos principales accesibles:**
  - [ ] Inventario → Items
  - [ ] Recetas
  - [ ] Compras
  - [ ] POS
  - [ ] Reportes
  - [ ] Caja
- [ ] **Sin errores en logs:**
  ```bash
  sudo tail -50 /var/log/apache2/kds_error.log
  tail -50 /var/www/kds/terrenaPos/storage/logs/laravel.log
  ```
- [ ] **Assets cargan (CSS/JS):** Ver red del navegador (F12)
- [ ] **Base de datos conecta:** Verificar datos reales

### 6.3 Tests de Humo (Smoke Tests)

```bash
# Desde local o Postman
curl -I http://100.126.124.101/terrena2/
# Debe retornar: HTTP/1.1 200 OK o 302 (redirect login)

# Probar API
curl http://100.126.124.101/terrena2/api/ping
# Debe retornar: {"ok":true,"timestamp":"..."}
```

---

## 7. Troubleshooting

### 7.1 Error: 404 Not Found

**Causas comunes:**

1. **RewriteBase incorrecto en .htaccess**
   ```bash
   # Verificar
   cat /var/www/kds/terrenaPos/public/.htaccess | grep RewriteBase
   # Debe decir: RewriteBase /terrena2/
   
   # Corregir si está mal:
   sudo sed -i 's|RewriteBase /TerrenaLaravel/|RewriteBase /terrena2/|g' \
     /var/www/kds/terrenaPos/public/.htaccess
   ```

2. **Alias Apache mal configurado**
   ```bash
   # Verificar
   cat /etc/apache2/sites-enabled/kds.conf | grep terrena2
   # Debe tener: Alias /terrena2 /var/www/kds/terrenaPos/public
   ```

3. **Directorio Windows copiado por error**
   ```bash
   # Eliminar si existe:
   sudo rm -rf '/var/www/kds/terrenaPos/C:\xampp3'
   ```

### 7.2 Error: 500 Internal Server Error

**Verificar logs:**

```bash
# Log Apache
sudo tail -50 /var/log/apache2/kds_error.log

# Log Laravel
tail -50 /var/www/kds/terrenaPos/storage/logs/laravel.log
```

**Causas comunes:**

1. **Permisos storage/bootstrap:**
   ```bash
   sudo chmod -R 775 /var/www/kds/terrenaPos/storage
   sudo chmod -R 775 /var/www/kds/terrenaPos/bootstrap/cache
   sudo chown -R www-data:www-data /var/www/kds/terrenaPos/storage
   sudo chown -R www-data:www-data /var/www/kds/terrenaPos/bootstrap/cache
   ```

2. **Cache corrupto:**
   ```bash
   sudo -u www-data php artisan config:clear
   sudo -u www-data php artisan cache:clear
   sudo -u www-data php artisan view:clear
   ```

3. **Dependencias faltantes:**
   ```bash
   sudo -u www-data composer install --no-dev
   ```

### 7.3 Error: Página en blanco

**Verificar:**

1. **APP_DEBUG en .env (temporalmente):**
   ```bash
   sudo nano /var/www/kds/terrenaPos/.env
   # Cambiar temporalmente: APP_DEBUG=true
   # Recargar página para ver error
   # IMPORTANTE: Volver a false después
   ```

2. **Permisos index.php:**
   ```bash
   ls -la /var/www/kds/terrenaPos/public/index.php
   # Debe ser: -rwxr-xr-x www-data www-data
   ```

### 7.4 Error: Assets no cargan (CSS/JS rotos)

**Verificar:**

1. **Assets compilados:**
   ```bash
   ls -la /var/www/kds/terrenaPos/public/build/
   # Debe tener archivos .css y .js
   ```

2. **Regenerar assets en servidor (si aplica):**
   ```bash
   cd /var/www/kds/terrenaPos
   npm install
   npm run build
   sudo chown -R www-data:www-data public/build/
   ```

3. **APP_URL correcto en .env:**
   ```bash
   grep APP_URL /var/www/kds/terrenaPos/.env
   # Debe coincidir con URL acceso
   ```

### 7.5 Error: Base de datos no conecta

```bash
# Probar conexión directa
sudo -u www-data php artisan tinker
>>> DB::connection()->getPdo();
>>> DB::select('SELECT 1 as test');

# Si falla, verificar .env:
cat /var/www/kds/terrenaPos/.env | grep DB_
```

---

## 8. Rollback

Si algo falla críticamente y necesitas revertir:

### 8.1 Restaurar desde Backup

```bash
# Conectar SSH
ssh terrena@100.126.124.101

# Detener Apache (opcional)
sudo systemctl stop apache2

# Restaurar archivos
cd /var/www/kds
sudo tar -xzf terrenaPos_backup_YYYYMMDD_HHMMSS.tar.gz

# Ajustar permisos
sudo chown -R www-data:www-data terrenaPos/
sudo chmod -R 755 terrenaPos/

# Iniciar Apache
sudo systemctl start apache2
```

### 8.2 Revertir Migraciones

```bash
cd /var/www/kds/terrenaPos

# Ver migraciones ejecutadas
sudo -u www-data php artisan migrate:status

# Revertir última migración
sudo -u www-data php artisan migrate:rollback

# Revertir N migraciones
sudo -u www-data php artisan migrate:rollback --step=3
```

### 8.3 Restaurar Base de Datos

```bash
# Si hiciste backup BD
sudo -u www-data php artisan db:restore backup_YYYYMMDD_HHMMSS.sql
```

---

## 9. Buenas Prácticas

### 9.1 Antes de Cada Deployment

1. ✅ **Probar en local:** Todo debe funcionar al 100%
2. ✅ **Backup producción:** Siempre hacer backup antes
3. ✅ **Deployment en horas valle:** Evitar horarios pico
4. ✅ **Comunicar:** Avisar al equipo que habrá deployment
5. ✅ **Planificar rollback:** Saber cómo revertir si falla

### 9.2 Durante Deployment

1. ✅ **Copiar solo lo necesario:** No toda la carpeta
2. ✅ **Verificar permisos:** Siempre después de copiar
3. ✅ **Limpiar cache:** Comandos artisan cache:clear
4. ✅ **Probar inmediatamente:** No dejar para después

### 9.3 Post-Deployment

1. ✅ **Verificar logs:** Ver si hay errores
2. ✅ **Smoke tests:** Probar funcionalidades críticas
3. ✅ **Monitorear 1 hora:** Ver que no haya problemas
4. ✅ **Documentar cambios:** Actualizar changelog

---

## 10. Comandos Rápidos (Cheatsheet)

### Conectar SSH
```bash
ssh terrena@100.126.124.101
```

### Ir a directorio proyecto
```bash
cd /var/www/kds/terrenaPos
```

### Permisos completos (después de copiar)
```bash
sudo chown -R www-data:www-data /var/www/kds/terrenaPos
sudo find /var/www/kds/terrenaPos -type d -exec chmod 755 {} \;
sudo find /var/www/kds/terrenaPos -type f -exec chmod 644 {} \;
sudo chmod -R 775 /var/www/kds/terrenaPos/storage
sudo chmod -R 775 /var/www/kds/terrenaPos/bootstrap/cache
```

### Limpiar cache Laravel
```bash
cd /var/www/kds/terrenaPos
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan view:clear
```

### Optimizar producción
```bash
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache
```

### Ver logs
```bash
# Laravel
tail -50 /var/www/kds/terrenaPos/storage/logs/laravel.log

# Apache
sudo tail -50 /var/log/apache2/kds_error.log
```

### Reiniciar Apache
```bash
sudo systemctl restart apache2
```

---

## 11. Contactos y Soporte

**Administrador Servidor:**
- Usuario SSH: `terrena`
- Acceso: Tailscale VPN requerida para IP 100.126.124.101

**Documentación Relacionada:**
- `docs/V4.0/Arquitectura/README.md` - Stack técnico
- `docs/V4.0/Guia/Stack.md` - Stack y convenciones
- `docs/V4.0/README.md` - Índice general

**Logs y Monitoreo:**
- Apache: `/var/log/apache2/kds_error.log`
- Laravel: `/var/www/kds/terrenaPos/storage/logs/laravel.log`

---

**Última actualización:** 2025-11-14  
**Revisado por:** Equipo DevOps Terrena
