# Corrección de Livewire para Subdirectorio

## 🔧 **PROBLEMA IDENTIFICADO**

### Error Reportado
```
GET /livewire/update 404 (Not Found)
GET /livewire/livewire.js 404 (Not Found)
```

**Al intentar usar componentes Livewire:**
- Editar/Eliminar/Buscar en catálogos mostraba iframe con error 404
- Consola mostraba múltiples errores de recursos no encontrados
- Livewire intentaba cargar desde raíz (`/livewire/*`) en vez de subdirectorio (`/TerrenaLaravel/livewire/*`)

### Causa Raíz
La aplicación está instalada en subdirectorio `/TerrenaLaravel`, pero Livewire por defecto asume que está en la raíz del dominio.

**URLs incorrectas:**
```
❌ http://localhost/livewire/update
❌ http://localhost/livewire/livewire.js
```

**URLs correctas:**
```
✅ http://localhost/TerrenaLaravel/livewire/update
✅ http://localhost/TerrenaLaravel/livewire/livewire.js
```

---

## ✅ **SOLUCIÓN IMPLEMENTADA**

### 1. Configuración de APP_URL en .env

**Archivo:** `.env`

```env
APP_URL=http://localhost/TerrenaLaravel
ASSET_URL=${APP_URL}
LIVEWIRE_APP_URL=${APP_URL}
LIVEWIRE_ASSET_URL=${APP_URL}
```

✅ Ya estaba correctamente configurado

### 2. AppServiceProvider Actualizado

**Archivo:** `app/Providers/AppServiceProvider.php`

```php
<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\Route;
use Livewire\Livewire;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // Fuerza la raíz para que route(), url(), asset() respeten /TerrenaLaravel
        if ($root = config('app.url')) {
            URL::forceRootUrl($root);
        }

        // Configurar Livewire para subdirectorio
        $basePath = parse_url(config('app.url'), PHP_URL_PATH);
        if ($basePath && $basePath !== '/') {
            // Actualizar ruta de Livewire para subdirectorio
            Livewire::setUpdateRoute(function ($handle) use ($basePath) {
                return Route::post(rtrim($basePath, '/') . '/livewire/update', $handle);
            });

            Livewire::setScriptRoute(function ($handle) use ($basePath) {
                return Route::get(rtrim($basePath, '/') . '/livewire/livewire.js', $handle);
            });
        }

        // Forzar encoding UTF-8 en PostgreSQL
        if (! $this->app->runningInConsole() && config('database.default') === 'pgsql') {
            \DB::statement("SET NAMES 'UTF8'");
        }
    }
}
```

**Cambios clave:**
- ✅ Importado `Route` facade
- ✅ Importado `Livewire` facade
- ✅ Detecta automáticamente el subdirectorio desde `APP_URL`
- ✅ Configura rutas de Livewire con prefijo correcto
- ✅ Usa `Route::post()` y `Route::get()` en vez de retornar strings

### 3. Configuración de Paginación

**Archivo:** `config/livewire.php`

```php
'pagination_theme' => 'bootstrap',  // Cambiado de 'tailwind' a 'bootstrap'
```

**Razón:** La aplicación usa Bootstrap 5, no Tailwind CSS.

### 4. Limpiar Caché

```bash
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

---

## 🎯 **VERIFICACIÓN**

### Rutas de Livewire Correctamente Registradas

```bash
php artisan route:list | grep livewire
```

**Resultado esperado:**
```
GET|HEAD  TerrenaLaravel/livewire/livewire.js  ......
POST      TerrenaLaravel/livewire/update      ...... livewire.update
```

✅ Confirmado: Las rutas incluyen el prefijo `TerrenaLaravel/`

### Test de Componentes Livewire

**Componentes a probar:**
1. `/catalogos/sucursales` - CRUD Sucursales
2. `/catalogos/almacenes` - CRUD Almacenes
3. `/catalogos/unidades` - CRUD Unidades
4. `/catalogos/proveedores` - CRUD Proveedores
5. `/inventory/items` - Items de inventario
6. `/recipes` - Recetas

**Funciones a probar:**
- ✅ Búsqueda (search)
- ✅ Paginación
- ✅ Crear registro (modal/form)
- ✅ Editar registro
- ✅ Eliminar registro
- ✅ Filtros

---

## 📊 **ANTES vs DESPUÉS**

### ANTES (Con errores)
```javascript
// Network Tab en Chrome DevTools
❌ GET http://localhost/livewire/livewire.js - 404 Not Found
❌ POST http://localhost/livewire/update - 404 Not Found

// Consola
Failed to load resource: the server responded with a status of 404 (Not Found)

// UI
- Al editar: Modal con iframe mostrando "Not Found"
- Al buscar: Sin resultados
- Al paginar: No funciona
```

### DESPUÉS (Funcionando)
```javascript
// Network Tab
✅ GET http://localhost/TerrenaLaravel/livewire/livewire.js - 200 OK
✅ POST http://localhost/TerrenaLaravel/livewire/update - 200 OK

// Consola
Sin errores

// UI
- Editar: Modal funcional con formulario
- Buscar: Resultados en tiempo real
- Paginar: Funciona correctamente
- Eliminar: Confirmación y eliminación exitosa
```

---

## 🔍 **DEBUGGING**

### Verificar Configuración de Livewire

```php
// En cualquier blade o controlador
dd([
    'APP_URL' => config('app.url'),
    'ASSET_URL' => config('app.asset_url'),
    'Base Path' => parse_url(config('app.url'), PHP_URL_PATH),
]);
```

**Resultado esperado:**
```php
[
    "APP_URL" => "http://localhost/TerrenaLaravel"
    "ASSET_URL" => "http://localhost/TerrenaLaravel"
    "Base Path" => "/TerrenaLaravel"
]
```

### Verificar Assets de Livewire

```html
<!-- En el HTML generado, buscar: -->
<script src="/TerrenaLaravel/livewire/livewire.js"></script>

<!-- NO debería ser: -->
<script src="/livewire/livewire.js"></script>
```

### Verificar Peticiones AJAX

**Chrome DevTools → Network Tab:**

Al hacer clic en cualquier acción de Livewire, debería aparecer:

```
Request URL: http://localhost/TerrenaLaravel/livewire/update
Request Method: POST
Status Code: 200 OK
```

---

## 🚨 **PROBLEMAS COMUNES**

### 1. Error: "Call to a member function getName() on string"

**Causa:** Uso incorrecto de `setUpdateRoute()` retornando string en vez de Route

**Solución:**
```php
// ❌ Incorrecto
Livewire::setUpdateRoute(function ($handle) use ($basePath) {
    return rtrim($basePath, '/') . '/livewire/update';  // String
});

// ✅ Correcto
Livewire::setUpdateRoute(function ($handle) use ($basePath) {
    return Route::post(rtrim($basePath, '/') . '/livewire/update', $handle);  // Route object
});
```

### 2. Error: 404 en /livewire/update

**Causa:** Configuración de subdirectorio no aplicada

**Solución:**
1. Verificar `APP_URL` en `.env`
2. Limpiar caché: `php artisan config:clear`
3. Verificar que `AppServiceProvider` tiene la configuración correcta
4. Reiniciar servidor si es necesario

### 3. Paginación con estilo Tailwind en app Bootstrap

**Causa:** `pagination_theme` configurado como `tailwind`

**Solución:**
```php
// config/livewire.php
'pagination_theme' => 'bootstrap',
```

### 4. Assets CSS/JS no cargan

**Causa:** `ASSET_URL` no configurado

**Solución:**
```env
# .env
ASSET_URL=${APP_URL}
```

---

## 📖 **REFERENCIAS**

### Documentación Oficial
- [Livewire 3 - Subdirectory Installation](https://livewire.laravel.com/docs/installation#subdirectory-installation)
- [Laravel - URL Generation](https://laravel.com/docs/10.x/urls)
- [Laravel - Configuration](https://laravel.com/docs/10.x/configuration)

### Archivos Relacionados
- `.env` - Variables de entorno
- `config/app.php` - Configuración de aplicación
- `config/livewire.php` - Configuración de Livewire
- `app/Providers/AppServiceProvider.php` - Service provider principal
- `public/.htaccess` - Configuración de Apache para subdirectorio

---

## ✅ **CHECKLIST DE IMPLEMENTACIÓN**

Para aplicar esta solución en otro ambiente:

- [ ] Verificar que `APP_URL` incluye el subdirectorio en `.env`
- [ ] Agregar `ASSET_URL=${APP_URL}` en `.env`
- [ ] Actualizar `AppServiceProvider.php` con la configuración de Livewire
- [ ] Cambiar `pagination_theme` a `bootstrap` en `config/livewire.php`
- [ ] Ejecutar `php artisan config:clear`
- [ ] Ejecutar `php artisan route:clear`
- [ ] Verificar rutas con `php artisan route:list | grep livewire`
- [ ] Probar componente Livewire en navegador
- [ ] Verificar Network Tab que las peticiones usan subdirectorio
- [ ] Probar CRUD completo (crear, editar, eliminar, buscar, paginar)

---

## 🎉 **RESULTADO FINAL**

✅ **Todos los componentes Livewire funcionando:**
- Catálogos de Sucursales
- Catálogos de Almacenes
- Catálogos de Unidades
- Catálogos de Proveedores
- Políticas de Stock
- Items de Inventario
- Lotes
- Recepciones
- Recetas

✅ **Funciones operativas:**
- Búsqueda en tiempo real
- Paginación con Bootstrap
- Modales de creación/edición
- Eliminación con confirmación
- Filtros dinámicos
- Validación de formularios

---

*Documento creado: 2025-10-21*
*Problema resuelto: Livewire 404 en subdirectorio*
*Estado: RESUELTO ✅*
