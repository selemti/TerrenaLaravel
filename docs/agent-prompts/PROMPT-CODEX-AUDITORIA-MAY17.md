# PROMPT CODEX — Correcciones Auditoría 2026-05-17

## Contexto del proyecto

TerrenaLaravel — ERP de restaurante. Laravel 12 + Livewire 3.7 + PostgreSQL 9.5.
Branch: `work/inicio-limpio-abril-2026`

**Reglas críticas:**
- NUNCA tocar schema `public` de PostgreSQL (FloreantPOS, READ ONLY)
- NUNCA cambiar `DB_SCHEMA` en `phpunit.xml`
- UI: Bootstrap 5. Layout: `layouts.terrena`
- Al terminar: `php artisan test` y reportar resultado

---

## PRIORIDAD 1 — CRÍTICOS (corregir primero)

---

### BUG-01 — API 500 en `/api/reports/ventas/formas`

**Archivo:** `app/Http/Controllers/Api/ReportsController.php` → método `formasPago()` (línea ~206)

**Síntoma:** El widget "Formas de pago" del Dashboard falla con HTTP 500 para el rango
`desde=2026-04-17&hasta=2026-05-17`.

**Causa probable:** La vista `selemti.vw_dashboard_formas_pago` existe y la query funciona
localmente con datos. El 500 probablemente ocurre cuando la vista retorna NULLs en `codigo_fp`
o cuando el `groupBy('codigo_fp')` recibe filas nulas.

**Fix:**
1. Agregar `->whereNotNull('codigo_fp')` antes del `groupBy`.
2. Envolver la query en try/catch con logging detallado para capturar el error exacto.
3. Si el error es de tipos (casting), agregar `DB::raw('codigo_fp::text')` en el select.

**Código actual:**
```php
// app/Http/Controllers/Api/ReportsController.php:206
public function formasPago(Request $request)
{
    [$desde, $hasta] = $this->range($request);
    $query = $this->pg()->table('selemti.vw_dashboard_formas_pago')
        ->select('codigo_fp', DB::raw('SUM(monto) AS monto'))
        ->whereBetween('fecha', [$desde, $hasta]);
    // ...
}
```

**Fix esperado:**
```php
$query = $this->pg()->table('selemti.vw_dashboard_formas_pago')
    ->select(DB::raw('codigo_fp::text'), DB::raw('SUM(monto) AS monto'))
    ->whereBetween('fecha', [$desde, $hasta])
    ->whereNotNull('codigo_fp');
```

Verificar ejecutando:
```bash
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8001/TerrenaLaravel/api/reports/ventas/formas?desde=2026-04-17&hasta=2026-05-17"
```
Debe retornar 200 con `data: [...]`.

---

### BUG-02 — Alpine `$autoRefreshEnabled` no definido en `/reports`

**Archivo:** `resources/views/livewire/reports/dashboard.blade.php` (líneas ~64 y ~73)

**Síntoma:**
```
[Alpine] Expression Error: $autoRefreshEnabled is not defined
Expression: "$autoRefreshEnabled"  input.me-2
```

**Causa:** El blade usa `:checked="$autoRefreshEnabled"` con sintaxis de Alpine (`:checked`),
pero `$autoRefreshEnabled` es una propiedad Livewire, no una variable Alpine. Alpine no puede
acceder directamente a propiedades Livewire con `$`.

**Código problemático (líneas ~64-73):**
```blade
@if($autoRefreshEnabled)
    ...
<input type="checkbox" class="me-2" wire:click="toggleAutoRefresh" :checked="$autoRefreshEnabled">
```

**Fix:** Reemplazar la sintaxis Alpine por Livewire pura:
```blade
@if($autoRefreshEnabled)
    ...
<input type="checkbox" class="me-2" wire:click="toggleAutoRefresh"
       @checked($autoRefreshEnabled)>
```
O bien usar `wire:model` si el checkbox debe bindear bidireccional:
```blade
<input type="checkbox" class="me-2" wire:model.live="autoRefreshEnabled">
```

La propiedad YA EXISTE en `app/Livewire/Reports/Dashboard.php` (línea 56):
```php
public bool $autoRefreshEnabled = false;
```
Solo hay que corregir la sintaxis del blade.

---

### BUG-03 — Modal "Ver Detalle" en Aprobaciones devuelve campos vacíos

**Archivo:** `app/Http/Controllers/Api/Caja/PostcorteController.php` → método `show()` (línea 149)

**Síntoma:** El modal muestra:
- Terminal: `-`
- Cajero: `N/A`
- Total declarado efectivo: `$0.00`

**Causa:** El método `show()` actual retorna solo el registro crudo de `selemti.postcorte`,
pero la tabla `postcorte` NO tiene `terminal_id` ni `cajero_nombre` directamente — esos campos
vienen de un JOIN con `selemti.sesion_cajon` y `public.employee`.

**Código actual (simplificado):**
```php
public function show($postId): JsonResponse
{
    $postcorte = DB::connection('pgsql')
        ->table('selemti.postcorte')
        ->where('id', $postId)
        ->first();

    return response()->json(['ok' => true, 'data' => $postcorte]);
}
```

**Fix:** Enriquecer el response con los campos que necesita el modal.
El controlador YA tiene la lógica en otros métodos (ver líneas ~324, ~468-470):
```php
// Línea ~468 en el mismo PostcorteController
's.terminal_id',
DB::raw("CONCAT(u.first_name, ' ', u.last_name) as cajero_nombre"),
'p.declarado_efectivo as total_declarado_efectivo',
```

Adaptar `show()` para joinear:
```php
public function show($postId): JsonResponse
{
    try {
        $data = DB::connection('pgsql')->selectOne("
            SELECT
                p.*,
                s.terminal_id,
                s.apertura_ts,
                s.cierre_ts,
                COALESCE(term.name, s.terminal_id::text) AS terminal_nombre,
                CONCAT(u.first_name, ' ', u.last_name) AS cajero_nombre,
                p.declarado_efectivo AS total_declarado_efectivo
            FROM selemti.postcorte p
            JOIN selemti.sesion_cajon s ON s.id = p.sesion_id
            LEFT JOIN public.terminal term ON term.id = s.terminal_id
            LEFT JOIN public.employee u ON u.id = s.cajero_usuario_id
            WHERE p.id = ?
        ", [$postId]);

        if (! $data) {
            return response()->json(['ok' => false, 'error' => 'postcorte_not_found'], 404);
        }

        return response()->json(['ok' => true, 'data' => $data]);
    } catch (\Exception $e) {
        return response()->json([
            'ok' => false, 'error' => 'server_error',
            'detail' => config('app.debug') ? $e->getMessage() : 'Error al obtener postcorte',
        ], 500);
    }
}
```

> **Nota:** Los JOINs a `public.terminal` y `public.employee` son READ ONLY — solo SELECT,
> nunca INSERT/UPDATE/DELETE en `public.*`.

---

## PRIORIDAD 2 — MODERADOS

---

### BUG-04 — 8 títulos de pestaña incorrectos (`<title>` muestra "Dashboard")

Los siguientes módulos muestran "Dashboard" o "SelemTI - TerrenaPOS" en lugar de su nombre real.

**Causa:** Las vistas Livewire usan el layout pasando `'title'` como parámetro, pero el layout
`terrena.blade.php` usa `$title ?? $__env->yieldContent('title', 'SelemTI - TerrenaPOS')`.
Cuando el componente pasa `title` en `->layout('layouts.terrena', ['title' => 'X'])`, debe
funcionar. El problema es que varios componentes NO pasan el parámetro `title`.

**Archivos a corregir** — agregar `'title' => 'Nombre del Módulo'` en el `->layout()` de cada uno:

| Archivo PHP | Title correcto |
|-------------|----------------|
| `app/Livewire/Inventory/LotsIndex.php` | `'Lotes · Inventario'` |
| `app/Livewire/Inventory/InventoryCountsIndex.php` (o similar) | `'Conteos · Inventario'` |
| `app/Livewire/Purchasing/Requests/Index.php` (o similar) | `'Solicitudes · Compras'` |
| `app/Livewire/Purchasing/Orders/Index.php` (o similar) | `'Órdenes · Compras'` |
| `app/Livewire/Recipes/RecipesIndex.php` (o similar) | `'Recetas'` |
| `app/Livewire/AuditLog.php` o `app/Http/Controllers/AuditLogController.php` | `'Auditoría Operacional'` |
| `app/Livewire/Kds/Board.php` | `'KDS · Cocina'` |
| `app/Livewire/Personal/Index.php` (o similar) | `'Personal'` |

Para Livewire el patrón es:
```php
return view('livewire.xxx.yyy')
    ->layout('layouts.terrena', [
        'active' => 'xxx',
        'title'  => 'Nombre · Módulo',   // ← agregar esto
    ]);
```

Para Blade clásico (`@extends`):
```blade
@section('title', 'Nombre del Módulo')
```

Buscar cada archivo listado, verificar que no tenga ya el título, y agregarlo.

---

### BUG-05 — Layout roto en `/audit/logs` (tabla en media pantalla)

**Archivo:** `resources/views/audit/logs.blade.php`

**Síntoma:** La tabla de logs ocupa solo la mitad derecha de la pantalla; la mitad izquierda
queda vacía.

**Causa probable:** La vista usa `col-md-8` o `col-md-9` sin un `row` + `col-12` padre,
o hay un `container` con margen izquierdo excesivo.

**Fix:** Revisar el grid Bootstrap de la vista. El contenido principal debe estar en `col-12`
o usar `container-fluid` sin columnas anidadas que reduzcan el ancho. Ejemplo:
```blade
{{-- ANTES (probable causa) --}}
<div class="col-md-9">
    <div class="card">...</div>
</div>

{{-- DESPUÉS --}}
<div class="col-12">
    <div class="card">...</div>
</div>
```

---

### BUG-06 — Catálogos: barras de progreso sin números

**URL:** `/catalogos`

**Síntoma:** Las tarjetas de Sucursales, Almacenes y Unidades muestran barras de color
sin texto ni conteo de registros.

**Archivos a buscar:** `resources/views/catalogos.blade.php` o el controlador/Livewire
que sirve `/catalogos`. Buscar con:
```bash
grep -rn "sucursal\|almacen\|unidad" routes/web.php | grep catalogos
```

**Fix:** En la vista o controlador, agregar queries de conteo:
```php
$counts = [
    'sucursales' => DB::connection('pgsql')->table('selemti.cat_sucursales')->count(),
    'almacenes'  => DB::connection('pgsql')->table('selemti.cat_almacenes')->count(),
    'unidades'   => DB::connection('pgsql')->table('selemti.cat_unidades')->count(),
];
```
Y en la blade mostrar el número junto a la barra:
```blade
<div class="d-flex justify-content-between mb-1">
    <span>Sucursales</span>
    <strong>{{ $counts['sucursales'] }}</strong>
</div>
<div class="progress" style="height:6px">
    <div class="progress-bar bg-primary" style="width:100%"></div>
</div>
```

---

### BUG-07 — Reposición: "No se pudieron cargar sugerencias"

**Archivo:** `app/Livewire/Replenishment/Dashboard.php`

**Síntoma:** Banner rojo "No se pudieron cargar sugerencias." en cada carga.
En sesión anterior se corrigió el hostname `api` usando `url('/api/...')`, pero el backend
del replenishment puede seguir fallando.

**Investigar:**
1. Ejecutar directamente:
   ```bash
   curl -H "Authorization: Bearer <token>" \
     "http://localhost:8001/TerrenaLaravel/api/purchasing/replenishment/suggestions"
   ```
2. Si retorna 500, revisar el controlador/servicio de replenishment y corregir la query.
3. Si retorna 200 vacío (`data: []`), el banner puede estar mal condicionado — mostrar estado
   vacío en lugar de error cuando `data` es array vacío.

**Fix mínimo (evitar el banner rojo cuando simplemente no hay sugerencias):**
```php
// En loadSuggestions()
if ($response->successful()) {
    $this->suggestions = $response->json('data') ?? [];
    $this->errorMessage = null;  // limpiar error si hay éxito aunque data esté vacío
} else {
    $this->suggestions = [];
    $this->errorMessage = $response->json('message') ?? 'No se pudieron cargar sugerencias.';
}
```

---

### BUG-08 — 401 recurrente en Aprobaciones (refresh de token en cada carga)

**Síntoma:** Cada visita a `/caja/cortes/aprobaciones` genera un 401 en
`/api/caja/postcortes/pendientes-aprobacion` seguido de un refresh automático de token.

**Causa:** El token en caché de `sessionStorage` expira entre navegaciones.

**Archivos:**
- `resources/views/layouts/terrena.blade.php` → función `TerrenaLoadApiToken()` (línea ~38)
- Buscar `STORAGE_TOKEN_KEY` y la función `getCachedValue` / `setCachedValue`

**Fix — refresh proactivo:** Antes de que el token expire, renovarlo automáticamente.
Actualmente el cache TTL probablemente es muy corto. Aumentarlo o agregar lógica de
re-fetch cuando faltan X segundos para expirar:

```js
// Al guardar el token, almacenar también el tiempo de expiración
function setCachedValue(key, value, ttlSeconds = 3600) {  // 1 hora
    const item = {
        value,
        expiry: Date.now() + (ttlSeconds * 1000),
    };
    sessionStorage.setItem(key, JSON.stringify(item));
}

function getCachedValue(key) {
    const raw = sessionStorage.getItem(key);
    if (!raw) return null;
    try {
        const item = JSON.parse(raw);
        // Renovar proactivamente si faltan menos de 5 minutos
        if (item.expiry - Date.now() < 300000) return null;
        return item.value;
    } catch {
        return null;
    }
}
```

---

## PRIORIDAD 3 — UI / HOMOLOGACIÓN (si hay tiempo)

---

### UI-01 — Estados vacíos inconsistentes

Varios módulos usan diferentes formatos para mostrar "sin registros".
Crear un include reutilizable `resources/views/partials/empty-state.blade.php`:

```blade
{{-- resources/views/partials/empty-state.blade.php --}}
<tr>
    <td colspan="{{ $colspan ?? 8 }}" class="text-center text-muted py-5">
        <i class="fa-regular fa-folder-open fa-2x mb-2 d-block"></i>
        <p class="mb-0">{{ $message ?? 'No hay registros.' }}</p>
        @if(isset($action))
            <a href="{{ $action['url'] }}" class="btn btn-sm btn-outline-primary mt-2">
                {{ $action['label'] }}
            </a>
        @endif
    </td>
</tr>
```

Reemplazar los `@empty` inconsistentes en:
- `resources/views/livewire/inventory/receptions-index.blade.php`
- `resources/views/livewire/inventory/lots-index.blade.php` (o similar)
- `resources/views/livewire/transfers/index.blade.php`

---

### UI-02 — Botones de exportación inconsistentes en Reportes

**Síntoma:** Resumen y Detalle de Ventas solo tienen PDF + Imprimir (sin Excel).
Los demás reportes tienen PDF + Excel + Imprimir.

**Fix:** Agregar botón Excel a las vistas que lo faltan:
```blade
<a href="?export=excel&desde={{ $desde }}&hasta={{ $hasta }}"
   class="btn btn-sm btn-outline-success">
    <i class="fa-solid fa-file-excel me-1"></i>Excel
</a>
```
Si el endpoint de Excel no existe, al menos agregar el botón deshabilitado para homologar:
```blade
<button class="btn btn-sm btn-outline-success" disabled title="Próximamente">
    <i class="fa-solid fa-file-excel me-1"></i>Excel
</button>
```

---

## Verificación final

```bash
php artisan test
```

Reportar:
- Tests que pasan / fallan
- Cualquier regresión introducida por los cambios

**No romper tests existentes.** Si un cambio rompe un test, arreglarlo antes de entregar.
