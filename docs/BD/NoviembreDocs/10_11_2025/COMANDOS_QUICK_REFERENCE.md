# Comandos Quick Reference - Laravel Deployment
## Servidor: 192.168.1.235 / 100.126.124.101

---

## 🔌 Conexión SSH

```bash
# Desde LAN
ssh terrena@192.168.1.235

# Desde Tailscale
ssh terrena@100.126.124.101

# Contraseña
T3rr3n4#123
```

---

## 🔄 Deployment desde Local a Producción

### 1. Build Local
```bash
cd C:\xampp3\htdocs\TerrenaLaravel
npm run build
```

### 2. Subir Build al Servidor
```bash
pscp -r -pw T3rr3n4#123 public/build terrena@100.126.124.101:/var/www/kds/terrenaPos/public/
```

### 3. Limpiar Caché en Servidor
```bash
ssh terrena@100.126.124.101
cd /var/www/kds/terrenaPos
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

---

## 🌐 Servicios

### Apache
```bash
# Reiniciar
sudo systemctl restart apache2

# Ver status
sudo systemctl status apache2

# Ver logs
sudo tail -f /var/log/apache2/kds_error.log
```

### Tailscale
```bash
# Ver status
tailscale status

# Reconectar
sudo tailscale down
sudo tailscale up

# Ver logs
sudo journalctl -u tailscaled -f
```

### PostgreSQL
```bash
# Conectar
psql -h localhost -U postgres -d pos

# Ver status
sudo systemctl status postgresql

# Reiniciar
sudo systemctl restart postgresql
```

---

## 🧪 Testing de URLs

```bash
# Test LAN
curl -I http://192.168.1.235/terrena2/

# Test Tailscale
curl -I http://100.126.124.101/terrena2/

# Test login page
curl -sL http://100.126.124.101/terrena2/login | grep '<title>'
```

---

## 🔧 Troubleshooting

### Problema: Laravel muestra errores
```bash
# Ver logs
tail -f /var/www/kds/terrenaPos/storage/logs/laravel.log

# Limpiar cachés
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Verificar permisos
sudo chown -R terrena:www-data /var/www/kds/terrenaPos
sudo chmod -R 755 /var/www/kds/terrenaPos
sudo chmod -R 775 /var/www/kds/terrenaPos/storage
sudo chmod -R 775 /var/www/kds/terrenaPos/bootstrap/cache
```

### Problema: No hay conexión Tailscale
```bash
# Verificar Internet
ping -c 3 8.8.8.8

# Verificar gateway
ping -c 3 192.168.1.251

# Reconectar Tailscale
sudo tailscale down
sleep 2
sudo tailscale up

# Verificar status
tailscale status
```

### Problema: Apache no inicia
```bash
# Ver configuración
sudo apache2ctl -t

# Ver logs de error
sudo tail -50 /var/log/apache2/error.log

# Verificar puertos
sudo netstat -tlnp | grep :80
```

---

## 📦 Composer

```bash
# Instalar dependencias
cd /var/www/kds/terrenaPos
composer install --no-dev --optimize-autoloader

# Update (si es necesario)
composer update --no-dev

# Dump autoload
composer dump-autoload -o
```

---

## 🗄️ Base de Datos

### PostgreSQL
```bash
# Conectar
psql -h localhost -U postgres -d pos

# Password
T3rr3n4#p0s

# Ejecutar migraciones
php artisan migrate

# Ver tablas
psql -h localhost -U postgres -d pos -c "\dt"

# Backup
pg_dump -h localhost -U postgres pos > backup_$(date +%Y%m%d).sql
```

### Seeders
```bash
# Ejecutar seeder específico (producción requiere --force)
php artisan db:seed --class=PermissionsSeeder --force

# Ejecutar todos los seeders
php artisan db:seed --force

# Verificar permisos poblados
php artisan tinker --execute="echo 'role_has_permissions: ' . DB::connection('pgsql')->table('selemti.role_has_permissions')->count();"
php artisan tinker --execute="echo 'model_has_roles: ' . DB::connection('pgsql')->table('selemti.model_has_roles')->count();"
```

---

## 🔑 Verificar Servicios Auto-Start

```bash
systemctl is-enabled apache2 postgresql mysql tailscaled tailscale-up ssh ufw
```

Todos deben mostrar: `enabled`

---

## 📁 Paths Importantes

```
Aplicación:      /var/www/kds/terrenaPos
Public:          /var/www/kds/terrenaPos/public
Logs Laravel:    /var/www/kds/terrenaPos/storage/logs/laravel.log
Logs Apache:     /var/log/apache2/kds_error.log
Config Apache:   /etc/apache2/sites-available/kds.conf
.env:            /var/www/kds/terrenaPos/.env
```

---

## 🌍 URLs

```
LAN:             http://192.168.1.235/terrena2
Tailscale:       http://100.126.124.101/terrena2
Login:           /terrena2/login
Dashboard:       /terrena2/dashboard
```

---

## 📤 Subir Archivos al Servidor

### Via pscp (Windows)
```bash
# Un archivo
pscp -pw T3rr3n4#123 archivo.php terrena@100.126.124.101:/tmp/

# Un directorio
pscp -r -pw T3rr3n4#123 directorio terrena@100.126.124.101:/tmp/

# Mover desde /tmp a destino final (en servidor)
ssh terrena@100.126.124.101
sudo cp /tmp/archivo.php /var/www/kds/terrenaPos/path/destino/
```

### Via tar (para muchos archivos)
```bash
# Local
cd C:\xampp3\htdocs\TerrenaLaravel
tar czf /tmp/archivos.tar.gz directorio/
pscp -pw T3rr3n4#123 /tmp/archivos.tar.gz terrena@100.126.124.101:/tmp/

# Servidor
ssh terrena@100.126.124.101
cd /var/www/kds/terrenaPos
tar xzf /tmp/archivos.tar.gz
```

---

## ⚠️ Notas Importantes

1. **Siempre hacer build localmente** antes de subir assets
2. **Limpiar cachés de Laravel** después de cambios en config/routes
3. **Verificar permisos** después de subir archivos nuevos
4. **NO modificar** rutas existentes: /barra, /cocina, /voceo, /terrena
5. **Usar `APP_ENV=production`** en servidor, `local` en desarrollo
6. **El middleware DynamicUrlMiddleware** solo funciona en production

---

## 🆘 Contactos de Emergencia

**Si algo falla:**

1. Ver logs Laravel: `tail -f storage/logs/laravel.log`
2. Ver logs Apache: `sudo tail -f /var/log/apache2/kds_error.log`
3. Verificar servicios: `systemctl status apache2 postgresql tailscaled`
4. Reconectar Tailscale: `sudo tailscale down && sudo tailscale up`
5. Reiniciar Apache: `sudo systemctl restart apache2`

---

**Última actualización**: 10 Noviembre 2025
