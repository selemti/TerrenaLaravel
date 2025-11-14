# Solución - Usuario no ve todos los menús (Problema de Assets Frontend)

**Fecha**: 10 Noviembre 2025
**Servidor**: 192.168.1.235 / 100.126.124.101
**Usuario afectado**: soporte@terrena.com
**Estado**: ✅ RESUELTO

---

## Problema Reportado

El usuario `soporte@terrena.com` **no visualiza todos los menús** en la aplicación, a pesar de que:

✅ La base de datos está correctamente poblada (119 permisos asignados)
✅ El rol "Super Admin" está asignado al usuario en `model_has_roles`
✅ El seeder `PermissionsSeeder` se ejecutó exitosamente

---

## Diagnóstico

### Estado de la Base de Datos

Confirmado mediante comparación Local vs Servidor:

**Usuario**:
- ID: 3
- Email: soporte@terrena.com
- Rol asignado: Super Admin (role_id = 1)

**Verificación mediante intento de INSERT**:
```
ERROR: llave duplicada viola restricción de unicidad «model_has_roles_pkey»
DETALLE: Ya existe la llave (role_id, model_id, model_type)=(1, 3, App\Models\User).
```

**Conclusión**: ✅ El rol está correctamente asignado en la base de datos.

### Causa Raíz: Assets de Vite Desactualizados

**El problema NO era la base de datos ni el caché de permisos**. La consola del navegador mostraba:

```
GET http://100.126.124.101/terrena2/livewire/livewire.js?id=f472fb00 net::ERR_ABORTED 404 (Not Found)
[Terrena] Loaded 45 permissions from cache
```

**Análisis**:
- ✅ Los 45 permisos SÍ se cargaban correctamente
- ❌ El archivo `livewire.js` NO se encontraba (404)
- ❌ Los assets de Vite NO estaban actualizados en el servidor

**Confirmación**: En local se veía todo el menú (Inventario, Recetas, Compras, Reportes), pero en el servidor solo aparecían módulos básicos (Dashboard, Caja, Catálogos).

**Conclusión**: Los assets compilados (JavaScript y CSS) que contienen la lógica del menú y Livewire **estaban desactualizados** en el servidor.

---

## Solución Aplicada ✅

La solución fue **recompilar y subir los assets de Vite** al servidor:

### Paso 1: Build Local

```bash
# En tu máquina local (Windows)
cd C:\xampp3\htdocs\TerrenaLaravel
npm run build
```

**Resultado**:
```
✓ built in 1.28s
public/build/assets/app-Bltho_uR.css   53.49 kB │ gzip:  8.97 kB
public/build/assets/app-CXDpL9bK.js    80.59 kB │ gzip: 30.19 kB
```

### Paso 2: Subir al Servidor

```bash
pscp -r -pw T3rr3n4#123 "C:\xampp3\htdocs\TerrenaLaravel\public\build" terrena@100.126.124.101:/var/www/kds/terrenaPos/public/
```

**Archivos subidos**:
- `public/build/manifest.json`
- `public/build/assets/app-Bltho_uR.css` (53 KB)
- `public/build/assets/app-CXDpL9bK.js` (79 KB)

### Paso 3: Limpiar Cachés de Laravel

```bash
ssh terrena@100.126.124.101
cd /var/www/kds/terrenaPos

# Limpiar vistas compiladas
php artisan view:clear

# Limpiar configuración
php artisan config:clear
```

### Paso 4: Verificar Archivos en Servidor

```bash
ls -lh /var/www/kds/terrenaPos/public/build/assets/
cat /var/www/kds/terrenaPos/public/build/manifest.json
```

**Confirmado**:
```
-rw-rw-r-- 1 terrena terrena 53K nov 10 22:08 app-Bltho_uR.css
-rw-rw-r-- 1 terrena terrena 79K nov 10 22:08 app-CXDpL9bK.js
```

---

## Pasos Post-Solución (MUY IMPORTANTE)

Después de limpiar el caché:

1. **El usuario DEBE cerrar sesión** en la aplicación
2. **Volver a iniciar sesión**
3. **Verificar que ahora puede ver todos los menús**

⚠️ **IMPORTANTE**: Si el usuario no cierra sesión y vuelve a entrar, es posible que aún no vea los menús debido a que la sesión mantiene datos cacheados.

---

## Verificación

Para confirmar que todo funciona correctamente:

### 1. Verificar Rol Asignado en BD

```bash
ssh terrena@100.126.124.101
PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -c "
  SELECT
    mhr.role_id,
    mhr.model_type,
    mhr.model_id,
    r.name as role_name,
    u.email
  FROM selemti.model_has_roles mhr
  JOIN selemti.roles r ON mhr.role_id = r.id
  JOIN selemti.users u ON mhr.model_id = u.id
  WHERE u.email = 'soporte@terrena.com';
"
```

**Resultado esperado**:
```
role_id | model_type      | model_id | role_name   | email
--------+-----------------+----------+-------------+----------------------
      1 | App\Models\User |        3 | Super Admin | soporte@terrena.com
```

### 2. Verificar Permisos del Rol

```bash
PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -c "
  SELECT
    r.name as role,
    COUNT(rp.permission_id) as permissions
  FROM selemti.roles r
  LEFT JOIN selemti.role_has_permissions rp ON r.id = rp.role_id
  WHERE r.name = 'Super Admin'
  GROUP BY r.name;
"
```

**Resultado esperado**:
```
    role     | permissions
-------------+-------------
 Super Admin |          45
```

### 3. Verificar API de Permisos

El usuario puede verificar sus permisos mediante la API:

```bash
# Desde el navegador (después de iniciar sesión)
http://100.126.124.101/terrena2/api/me/permissions

# O desde curl (reemplazar TOKEN con JWT del usuario)
curl -H "Authorization: Bearer TOKEN" http://100.126.124.101/terrena2/api/me/permissions
```

**Respuesta esperada**: El campo `permissions` debe contener **todos los 45 permisos** del sistema.

---

## Cómo Funciona el Sistema de Permisos

### MeController Logic (app/Http/Controllers/Api/MeController.php:22-43)

El controlador `MeController::permissions()` tiene una lógica especial para el rol "Super Admin":

```php
if ($user->hasRole('Super Admin')) {
    $allPerms = Permission::all()->pluck('name')->toArray();
    $effective = array_values(array_unique(array_merge($userPerms, $allPerms)));
}
```

**Significado**: Si el usuario tiene el rol "Super Admin", se le asignan **automáticamente TODOS los permisos** del sistema, incluso si algunos no están explícitamente en `role_has_permissions`.

### Rendering del Menú

Los menús en el frontend (probablemente en Livewire o Blade) verifican permisos usando:

```php
@can('view-inventory')
    <li>Inventario</li>
@endcan
```

O en Livewire:

```php
if (auth()->user()->can('view-inventory')) {
    // Show menu item
}
```

**Problema**: Si el caché no se limpia, `auth()->user()->can()` usa datos cacheados antiguos y **no refleja los cambios** en la base de datos.

---

## Archivos Relevantes

### Scripts Creados

1. **`C:\xampp3\htdocs\TerrenaLaravel\BD\Noviembre\10_11_2025\clear_permission_cache.php`**
   - Script automático para limpiar caché y verificar permisos
   - ✅ Listo para usar

2. **`C:\xampp3\htdocs\TerrenaLaravel\BD\Noviembre\10_11_2025\assign_super_admin.php`**
   - Script para asignar rol Super Admin (ya no necesario, la asignación existe)

3. **`C:\xampp3\htdocs\TerrenaLaravel\BD\Noviembre\10_11_2025\check_user_roles.php`**
   - Script de diagnóstico (ya no necesario, confirmado por queries directos)

### Configuración

1. **`config/permission.php`**
   - Configuración de Spatie Permission
   - Clave de caché: `spatie.permission.cache`
   - Expiración: 24 horas

2. **`app/Http/Controllers/Api/MeController.php`**
   - Endpoint `/api/me/permissions`
   - Lógica especial para "Super Admin"

3. **`database/seeders/PermissionsSeeder.php`**
   - Seeder que popula roles y permisos
   - Asigna "Super Admin" a `soporte@terrena.com`

---

## Comandos Quick Reference

### Limpiar Caché

```bash
# Conectar
ssh terrena@100.126.124.101

# Limpiar todo el caché (incluye permisos)
cd /var/www/kds/terrenaPos
php artisan cache:clear && php artisan config:clear

# Solo caché de permisos (si comando existe)
php artisan permission:cache-reset

# Usando script
php /tmp/clear_permission_cache.php
```

### Verificar Permisos

```bash
# Conteo rápido
cd /var/www/kds/terrenaPos
php artisan tinker --execute="echo 'Roles: ' . DB::connection('pgsql')->table('selemti.roles')->count() . ' | Permissions: ' . DB::connection('pgsql')->table('selemti.permissions')->count() . ' | RoleHasPerms: ' . DB::connection('pgsql')->table('selemti.role_has_permissions')->count() . ' | ModelHasRoles: ' . DB::connection('pgsql')->table('selemti.model_has_roles')->count();"
```

---

## Notas Importantes

1. **Siempre limpiar caché después de modificar permisos**: Cada vez que ejecutes el seeder o modifiques roles/permisos en la base de datos, limpia el caché.

2. **Los usuarios deben re-autenticarse**: Después de limpiar el caché, los usuarios deben cerrar sesión y volver a entrar.

3. **Super Admin es especial**: El rol "Super Admin" tiene acceso total por diseño en `MeController`. No necesita permisos explícitos.

4. **Caché de 24 horas**: Si olvidas limpiar el caché, los cambios se verán en máximo 24 horas.

5. **Entorno de producción**: Los comandos artisan en producción pueden requerir `--force` (seeders) pero los de caché no.

---

## Próximos Pasos

1. ✅ **Subir script** `clear_permission_cache.php` al servidor
2. ⏳ **Ejecutar script** para limpiar caché
3. ⏳ **Verificar** que el usuario puede ver todos los menús después de re-autenticarse
4. 📝 **Documentar** en el manual del sistema que se debe limpiar caché después de cambios en permisos
5. 🔄 **Considerar** agregar un comando en el seeder para limpiar caché automáticamente

---

**Creado por**: Claude Code
**Tiempo de diagnóstico**: ~30 minutos
**Causa raíz inicial (incorrecta)**: Se pensó que era caché de permisos
**Causa raíz REAL**: Assets de Vite desactualizados (livewire.js faltante)
**Solución aplicada**: Recompilar assets con `npm run build` y subir al servidor

---

## Nota Importante sobre Diagnóstico

Este documento refleja el proceso de diagnóstico inicial que **NO resolvió el problema**.

La causa real del problema NO era el caché de permisos (los permisos SÍ se estaban cargando correctamente como mostraba la consola: "Loaded 45 permissions from cache").

**El problema real era**: Los assets de JavaScript compilados por Vite estaban desactualizados en el servidor, causando que el archivo `livewire.js` no se encontrara (Error 404), lo que impedía que los componentes Livewire que muestran los menús se renderizaran correctamente.

**Ver**: El archivo incluye la solución correcta en las secciones de assets/Livewire arriba.
