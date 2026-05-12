# DEPLOYMENT CHEATSHEET - Terrena v4.0
**Referencia Rápida para Actualizar Producción**

---

## 🚀 PROCESO RÁPIDO (3 pasos)

### 1. PRE-DEPLOYMENT (Local)
```bash
# En C:\xampp3\htdocs\TerrenaLaravel\
npm run build
composer install --no-dev --optimize-autoloader
php artisan config:clear && php artisan cache:clear
git add . && git commit -m "feat: descripción" && git push
```

### 2. COPIAR ARCHIVOS (WinSCP)
**Host:** 100.126.124.101  
**User:** terrena  
**Destino:** `/var/www/kds/terrenaPos/`

**Copiar solo:**
- ✅ `app/`
- ✅ `resources/views/`
- ✅ `routes/`
- ✅ `public/build/`
- ✅ `composer.json` + `composer.lock` (si cambió)

**NO copiar:**
- ❌ `.env`
- ❌ `vendor/`
- ❌ `node_modules/`
- ❌ `storage/logs/`

### 3. POST-DEPLOYMENT (SSH)
```bash
ssh terrena@100.126.124.101
cd /var/www/kds/terrenaPos

# Permisos
echo 'T3rr3n4#123' | sudo -S chown -R www-data:www-data .
echo 'T3rr3n4#123' | sudo -S chmod -R 775 storage bootstrap/cache

# Cache Laravel
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan view:clear

# Optimizar (opcional)
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
```

---

## 🔧 CONFIGURACIÓN CRÍTICA

### .htaccess (debe tener)
```apache
RewriteBase /terrena2/
```

### Apache Alias (YA CONFIGURADO - no tocar)
```apache
Alias /terrena2 /var/www/kds/terrenaPos/public
```

### URLs Producción
- **Tailscale:** http://100.126.124.101/terrena2/
- **Red Local:** http://192.168.1.235/terrena2/

---

## 🆘 TROUBLESHOOTING RÁPIDO

### Error 404
```bash
# Verificar .htaccess
cat /var/www/kds/terrenaPos/public/.htaccess | grep RewriteBase
# Debe decir: RewriteBase /terrena2/

# Corregir si está mal:
cd /var/www/kds/terrenaPos/public
echo 'T3rr3n4#123' | sudo -S sed -i 's|RewriteBase /TerrenaLaravel/|RewriteBase /terrena2/|g' .htaccess
```

### Error 500
```bash
# Ver logs
sudo tail -50 /var/log/apache2/kds_error.log
tail -50 /var/www/kds/terrenaPos/storage/logs/laravel.log

# Limpiar cache
cd /var/www/kds/terrenaPos
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
```

### Permisos rotos
```bash
cd /var/www/kds
echo 'T3rr3n4#123' | sudo -S chown -R www-data:www-data terrenaPos/
echo 'T3rr3n4#123' | sudo -S find terrenaPos/ -type d -exec chmod 755 {} \;
echo 'T3rr3n4#123' | sudo -S find terrenaPos/ -type f -exec chmod 644 {} \;
echo 'T3rr3n4#123' | sudo -S chmod -R 775 terrenaPos/storage terrenaPos/bootstrap/cache
```

---

## 📋 CHECKLIST POST-DEPLOYMENT

- [ ] URL funciona: http://100.126.124.101/terrena2/
- [ ] Login funciona
- [ ] Dashboard carga
- [ ] Sin errores en logs
- [ ] Assets cargan (CSS/JS)

---

## 📚 DOCUMENTACIÓN COMPLETA

Ver: `docs/V4.0/Guia/Deployment.md`
