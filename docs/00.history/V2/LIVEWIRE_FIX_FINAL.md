# 🔧 Corrección Final de Livewire para Subdirectorio

## Problema Identificado

Livewire intentaba cargar recursos desde `/livewire/update` en lugar de `/TerrenaLaravel/livewire/update` causando errores 404.

```
❌ POST http://localhost/livewire/update 404 (Not Found)
✅ POST http://localhost/TerrenaLaravel/livewire/update 200 OK
```

---

## Soluciones Implementadas

### 1. Configuración del Service Provider

**Archivo:** `app/Providers/AppServiceProvider.php`

```php
use Illuminate\Support\Facades\Route;
use Livewire\Livewire;

public function boot(): void
{
    // Fuerza la raíz para que route(), url(), asset() respeten /TerrenaLaravel
    if ($root = config('app.url')) {
        URL::forceRootUrl($root);
    }

    // Configurar Livewire para subdirectorio
    $basePath = parse_url(config('app.url'), PHP_URL_PATH);
    if ($basePath && $basePath !== '/') {
        $prefix = rtrim($basePath, '/');

        // Configurar rutas de Livewire con prefijo de subdirectorio
        Livewire::setUpdateRoute(function ($handle) use ($prefix) {
            return Route::post($prefix . '/livewire/update', $handle);
        });

        Livewire::setScriptRoute(function ($handle) use ($prefix) {
            return Route::get($prefix . '/livewire/livewire.js', $handle);
        });
    }

    // Configurar Livewire para que use el APP_URL completo
    config(['livewire.asset_url' => config('app.url')]);
}
```

### 2. Configuración de Paginación

**Archivo:** `config/livewire.php`

```php
'pagination_theme' => 'bootstrap',  // Cambiado de 'tailwind'
```

### 3. Hook JavaScript para Peticiones

**Archivo:** `resources/views/layouts/terrena.blade.php`

Agregado después de `@livewireScripts`:

```html
<script>
  // Configurar Livewire para subdirectorio
  document.addEventListener('livewire:init', () => {
    Livewire.hook('request', ({ uri, options, payload, respond, succeed, fail }) => {
      // Asegurar que las peticiones usen el subdirectorio correcto
      const basePath = '{{ config('app.url') }}';
      if (uri.startsWith('/livewire/')) {
        uri = basePath + uri;
      }
      return { uri, options, payload, respond, succeed, fail };
    });
  });
</script>
```

**Importante:** Este hook intercepta TODAS las peticiones de Livewire en el cliente y agrega el prefijo del subdirectorio automáticamente.

---

## Verificación

### 1. Verificar Rutas Registradas

```bash
php artisan route:list | grep livewire
```

**Resultado Esperado:**
```
✅ GET|HEAD  TerrenaLaravel/livewire/livewire.js
✅ POST      TerrenaLaravel/livewire/update
```

### 2. Verificar en el Navegador

1. Abrir: http://localhost/TerrenaLaravel/catalogos/sucursales
2. Abrir Chrome DevTools → Console
3. Realizar una acción (Editar, Eliminar, Buscar)
4. Verificar en Network Tab:

**ANTES (ERROR):**
```
❌ POST http://localhost/livewire/update - 404 Not Found
```

**DESPUÉS (CORRECTO):**
```
✅ POST http://localhost/TerrenaLaravel/livewire/update - 200 OK
```

### 3. Limpiar Cachés

**IMPORTANTE:** Después de realizar cambios, siempre ejecutar:

```bash
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear
```

### 4. Limpiar Caché del Navegador

**MUY IMPORTANTE:** Limpiar el caché del navegador o abrir en modo incógnito:

1. Chrome DevTools → Application → Clear Storage → Clear site data
2. O usar Ctrl+Shift+Del → Eliminar caché e imágenes
3. O probar en ventana de incógnito (Ctrl+Shift+N)

---

## Pruebas Funcionales

### Test 1: Editar Sucursal

1. Ir a: http://localhost/TerrenaLaravel/catalogos/sucursales
2. Clic en botón "Editar" de cualquier registro
3. **Resultado esperado:**
   - ✅ Modal se abre sin error 404
   - ✅ Formulario de edición visible
   - ✅ Campos poblados con datos
   - ✅ Botón "Guardar" funcional

### Test 2: Eliminar Registro

1. Clic en botón "Eliminar" de cualquier registro
2. **Resultado esperado:**
   - ✅ Confirmación aparece
   - ✅ Sin iframe de error 404
   - ✅ Registro se elimina correctamente

### Test 3: Búsqueda en Tiempo Real

1. Escribir en el campo de búsqueda
2. **Resultado esperado:**
   - ✅ Resultados filtrados en tiempo real
   - ✅ Sin errores 404 en console
   - ✅ Paginación funcional

### Test 4: Paginación

1. Si hay múltiples páginas, clic en número de página
2. **Resultado esperado:**
   - ✅ Cambia de página sin recargar
   - ✅ Estilo Bootstrap (no Tailwind)
   - ✅ Sin errores en console

---

## Diagnóstico de Problemas

### Problema: Sigue apareciendo error 404

**Solución:**
1. Limpiar TODOS los cachés de Laravel
2. **Limpiar caché del navegador** (muy importante)
3. Verificar que `APP_URL` en `.env` sea correcto:
   ```env
   APP_URL=http://localhost/TerrenaLaravel
   ```
4. Probar en modo incógnito

### Problema: Modal muestra "Call to a member function getName() on string"

**Solución:**
Verificar que en `AppServiceProvider.php` se esté retornando un objeto Route:
```php
// ❌ INCORRECTO
return $prefix . '/livewire/update';

// ✅ CORRECTO
return Route::post($prefix . '/livewire/update', $handle);
```

### Problema: JavaScript hook no funciona

**Solución:**
1. Verificar que el script esté DESPUÉS de `@livewireScripts`
2. Verificar en console que no hay errores de sintaxis JavaScript
3. Usar `console.log()` para debug:
```javascript
Livewire.hook('request', ({ uri, options, payload, respond, succeed, fail }) => {
  console.log('URI original:', uri);
  const basePath = '{{ config('app.url') }}';
  if (uri.startsWith('/livewire/')) {
    uri = basePath + uri;
  }
  console.log('URI modificada:', uri);
  return { uri, options, payload, respond, succeed, fail };
});
```

---

## Archivos Modificados

1. ✅ `app/Providers/AppServiceProvider.php` - Configuración de rutas Livewire
2. ✅ `config/livewire.php` - Tema de paginación
3. ✅ `resources/views/layouts/terrena.blade.php` - Hook JavaScript

---

## Comandos de Verificación

```bash
# Verificar rutas Livewire
php artisan route:list | grep livewire

# Verificar configuración
php artisan tinker
>>> config('app.url')
=> "http://localhost/TerrenaLaravel"

# Limpiar todo
php artisan config:clear && php artisan route:clear && php artisan view:clear && php artisan cache:clear
```

---

## Catálogos a Probar

Probar CRUD completo en cada uno:

1. ✅ Sucursales: http://localhost/TerrenaLaravel/catalogos/sucursales
2. ✅ Almacenes: http://localhost/TerrenaLaravel/catalogos/almacenes
3. ✅ Unidades: http://localhost/TerrenaLaravel/catalogos/unidades
4. ✅ Proveedores: http://localhost/TerrenaLaravel/catalogos/proveedores
5. ✅ Políticas Stock: http://localhost/TerrenaLaravel/catalogos/stock-policy
6. ✅ Conversiones UOM: http://localhost/TerrenaLaravel/catalogos/uom

**Otros componentes Livewire:**
7. ✅ Items: http://localhost/TerrenaLaravel/inventory/items
8. ✅ Lotes: http://localhost/TerrenaLaravel/inventory/lots
9. ✅ Recepciones: http://localhost/TerrenaLaravel/inventory/receptions
10. ✅ Recetas: http://localhost/TerrenaLaravel/recipes
11. ✅ KDS: http://localhost/TerrenaLaravel/kds

---

## Notas Técnicas

### ¿Por qué hay rutas duplicadas?

Al ejecutar `php artisan route:list | grep livewire` verás rutas duplicadas:

```
TerrenaLaravel/livewire/update  ← Rutas personalizadas (usadas)
livewire/update                  ← Rutas default de Livewire (ignoradas)
```

Esto es **NORMAL**. Livewire registra sus rutas por defecto, y nosotros agregamos las personalizadas con prefijo. El JavaScript hook asegura que siempre se usen las rutas con prefijo.

### ¿Qué hace el hook JavaScript?

El hook intercepta cada petición AJAX de Livewire **antes** de enviarla al servidor y modifica la URI para agregar el subdirectorio:

```
Petición original: /livewire/update
Hook detecta:     uri.startsWith('/livewire/')
Modifica a:       http://localhost/TerrenaLaravel/livewire/update
Servidor recibe:  POST /TerrenaLaravel/livewire/update ✅
```

---

## ✅ Resultado Esperado

Después de aplicar TODOS los cambios y limpiar cachés:

1. ✅ Todos los catálogos Livewire funcionales
2. ✅ Editar abre modal correctamente
3. ✅ Eliminar funciona sin errores
4. ✅ Búsqueda en tiempo real operativa
5. ✅ Paginación con estilo Bootstrap
6. ✅ Console sin errores 404 de Livewire
7. ✅ Network Tab muestra peticiones a `/TerrenaLaravel/livewire/update`

---

**Fecha:** 2025-10-21
**Versión:** 2.1 (Fix Final)
**Estado:** LISTO PARA PRUEBAS
