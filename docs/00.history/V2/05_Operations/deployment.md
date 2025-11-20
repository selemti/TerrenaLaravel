# Operaciones · Despliegue y Entorno

## 1. Requisitos

- PHP 8.2.x con extensiones: `pdo_pgsql`, `mbstring`, `openssl`, `intl`, `fileinfo`, `gd`.
- Composer 2.8+, Node.js 18+ (`npm`), PostgreSQL 9.5.
- Acceso a esquemas `public` y `selemti` con privilegios DDL/DML.
- Variables `.env` configuradas (`DB_SCHEMA=selemti,public`, credenciales JWT, mail, etc.).

## 2. Pasos de Despliegue (Manual)

1. `composer install --no-dev` (en producción).  
2. `npm ci && npm run build`.  
3. `php artisan key:generate` (solo primera vez).  
4. `php artisan migrate --force` (migraciones idempotentes).  
5. Ejecutar scripts SQL adicionales desde `docs/V2/02_Database/scripts/` según checklist.  
6. `php artisan catalogs:verify-tables --details` (validar catálogos).  
7. Cache recomendado: `php artisan config:cache`, `route:cache`, `view:cache`.  
8. Configurar supervisor/servicios para `queue:listen` si se habilitan colas.  
9. Verificar health (`/api/health`) y dashboard principal.

## 3. Automatización Sugerida

- Pipeline CI/CD con etapas:
  1. Lint/Tests (`php artisan test`, `npm run build`).  
  2. Empaquetado artefactos.  
  3. Deploy (rsync/ssh) + ejecución de migraciones + seeders.  
  4. Smoke tests (`/__probe`, `/api/ping`).  
- Scripts PowerShell/Bash para ejecutar secuencia de SQL (`psql -f ...`).

## 4. Backups y Rollback

- Mantener scripts de backup automático (ver `BD/backup_pre_deploy_*`).  
- Documentar en `docs/V2/02_Database/scripts/README.md` pasos de rollback.  
- Recomendado: snapshot de base de datos previo a migraciones críticas.

## 5. Archivos y Configuración Sensible

- `.env` (no versionado).  
- Llaves JWT (`config/jwt.php`), credenciales mail/queue.  
- Certificados SSL (si aplica).  
- Configuración de storage (`php artisan storage:link`).  
- Permisos en directorios `storage/` y `bootstrap/cache/`.

## 6. Checklist Post-Deploy

- [ ] Migraciones ejecutadas sin errores.  
- [ ] Comando `catalogs:verify-tables` OK.  
- [ ] Interfaces clave accesibles (`/dashboard`, `/catalogos/*`, `/inventory/items`).  
- [ ] APIs responden (`/api/ping`, `/api/caja/...`).  
- [ ] Logs limpios (`storage/logs/laravel.log`).  
- [ ] Documentación actualizada (`PROJECT_STATUS.md`).  

Actualiza este documento conforme se agreguen nuevas dependencias o se automatice el pipeline.
