# PROMPT CODEX — Errores #1, #6, #7/#8, #10, #11, #12

## Contexto del proyecto

TerrenaLaravel es un ERP de restaurante en **Laravel 12 + Livewire 3.7 + PostgreSQL 9.5**.

**Reglas críticas (no romper bajo ningún concepto):**
- NUNCA tocar el schema `public` de PostgreSQL — es FloreantPOS, READ ONLY
- NUNCA agregar `"public"` a `DB_SCHEMA` en `phpunit.xml`
- UI: Bootstrap 5 (NO Tailwind para componentes nuevos)
- Layout: `layouts.terrena` (no `layouts.app`)
- Al terminar: ejecutar `php artisan test` y reportar resultado

Branch actual: `work/inicio-limpio-abril-2026`

---

## ERROR #1 — Dashboard: fecha range bug en `terrena.js`

**Síntoma:** El dashboard muestra charts rotos porque el rango de fechas tiene `desde > hasta`
(la fecha de inicio es posterior a la fecha de fin).

**Archivo:** Buscar en `resources/views/layouts/terrena.blade.php` o en scripts inline del dashboard
la función `initDashboardCharts`, `loadDashboardData`, o similar que construye el rango de fechas.

**Fix:** Asegurarse de que al construir el rango de fechas por defecto:
```js
// El patrón correcto (desde = hoy - N días, hasta = hoy)
const hasta = new Date();
const desde = new Date();
desde.setDate(desde.getDate() - 30);
// desde < hasta → correcto
```

Verificar que no hay lógica invertida (p.ej. `setDate(getDate() + 30)` cuando debería ser `-30`).

---

## ERROR #6 — 401 en `/api/caja/alertas/count` (token no enviado)

**Síntoma:** El fetch a `/api/caja/alertas/count` retorna 401 porque el header `Authorization`
no se incluye en la petición.

**Archivo:** `resources/views/layouts/terrena.blade.php` — función `fetchAlertsCount()` (línea ~715).

**Código actual (el problema):**
```js
async function fetchAlertsCount() {
  try {
    const response = await fetch(basePath + '/api/caja/alertas/count', {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
        // FALTA: Authorization: Bearer ${token}
      }
    });
```

**Fix:** Agregar el token al header. El token vive en `window.TerrenaApiToken` (cargado por
`TerrenaLoadApiToken()` que ya existe en el layout):

```js
async function fetchAlertsCount() {
  try {
    const token = window.TerrenaApiToken;
    const headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    const response = await fetch(basePath + '/api/caja/alertas/count', {
      method: 'GET',
      headers,
    });
```

---

## ERRORES #7 y #8 — Links de menú sin permission guard

**Síntoma:** Los links "Alertas" (de inventario, línea ~302) y "Auditoría" (línea ~447) en el sidebar
aparecen para todos los usuarios sin verificar permisos.

**Archivo:** `resources/views/layouts/terrena.blade.php`

### Error #7 — "Alertas" de Inventario (línea ~301-303)

```blade
{{-- ACTUAL - sin guard --}}
<a class="nav-link submenu-link" href="{{ route('inv.alerts') }}">
  <i class="fa-solid fa-bell"></i> <span class="label">Alertas</span>
</a>
```

**Fix:** Agregar guard Alpine.js consistente con el patrón del resto del menú:
```blade
<a class="nav-link submenu-link"
   href="{{ route('inv.alerts') }}"
   x-show="permsLoaded && window.TerrenaHasPerm('can_view_inventory')"
   x-cloak>
  <i class="fa-solid fa-bell"></i> <span class="label">Alertas</span>
</a>
```

> Usar el permission slug `'can_view_inventory'` — ya existe en la tabla `permissions` de selemti.
> Si no existe, usar `'admin.access'` como fallback temporal y documentarlo.

### Error #8 — "Auditoría" (línea ~446-452)

```blade
{{-- ACTUAL - ya tiene x-show pero verificar que funcione --}}
<a class="nav-link ..."
   href="{{ route('audit.log.index') }}"
   x-show="permsLoaded && window.TerrenaHasPerm('audit.view')"
   x-cloak>
```

Verificar que el permission slug `'audit.view'` existe en `selemti.permissions`.
Si no existe, crearlo con:
```sql
INSERT INTO selemti.permissions (name, guard_name, created_at, updated_at)
VALUES ('audit.view', 'web', NOW(), NOW())
ON CONFLICT DO NOTHING;
```
Y asignarlo al role `admin`.

---

## ERRORES #10 y #11 — KDS: mensaje en inglés y sin layout al negar acceso

**Archivos:**
- `app/Livewire/Kds/Board.php` — componente Livewire (actualmente vacío / stub)
- `resources/views/livewire/kds/board.blade.php` — vista (actualmente solo un comentario)

**Síntoma #10:** El mensaje de "acceso denegado" aparece en inglés (Laravel default: "This action is unauthorized.")

**Síntoma #11:** Cuando el usuario no tiene permiso, la página no tiene el layout de terrena
(aparece como página en blanco o error puro).

**Fix — `app/Livewire/Kds/Board.php`:**

```php
<?php

namespace App\Livewire\Kds;

use Livewire\Component;

class Board extends Component
{
    public bool $hasAccess = false;

    public function mount(): void
    {
        $this->hasAccess = auth()->check() && (
            auth()->user()->hasPermissionTo('kitchen.view_kds') ||
            auth()->user()->hasPermissionTo('can_edit_production_order')
        );
    }

    public function render()
    {
        return view('livewire.kds.board')
            ->layout('layouts.terrena', ['active' => 'kds']);
    }
}
```

**Fix — `resources/views/livewire/kds/board.blade.php`:**

```blade
<div class="container-fluid py-4">
    @if(! $hasAccess)
        <div class="alert alert-danger d-flex align-items-center gap-3">
            <i class="fa-solid fa-lock fa-2x"></i>
            <div>
                <h5 class="mb-1">Acceso restringido</h5>
                <p class="mb-0">No tienes permiso para ver el panel de cocina (KDS).
                    Contacta al administrador del sistema.</p>
            </div>
        </div>
    @else
        <div class="text-center text-muted py-5">
            <i class="fa-solid fa-desktop fa-3x mb-3"></i>
            <h4>Panel KDS</h4>
            <p>Módulo en construcción.</p>
        </div>
    @endif
</div>
```

---

## ERROR #12 — `/admin/tickets/management` muestra contenido vacío

**Síntoma:** La página carga sin errores pero no muestra tickets en la tabla.

**Archivos:**
- `app/Http/Controllers/Admin/TicketManagementController.php` — método `index()` y
  `getProblematicTickets()` (línea ~235)
- `resources/views/admin/tickets/management.blade.php`

**Investigar:**

1. Revisar `getProblematicTickets()`: la query busca en `public.ticket` (READ ONLY, correcto).
   Verificar que la query retorna datos ejecutándola directamente en psql:
   ```sql
   SELECT COUNT(*) FROM public.ticket WHERE voided = false;
   ```

2. Si la query retorna 0 filas: es porque la BD local no tiene tickets de `public.ticket`
   (el schema `public` es producción). En local, la tabla puede estar vacía.
   **Fix:** En la vista, mostrar un mensaje explicativo cuando `$tickets` está vacío:

   En `resources/views/admin/tickets/management.blade.php`, buscar el `@forelse` de la tabla
   de tickets y asegurarse que el `@empty` muestra algo legible:

   ```blade
   @empty
       <tr>
           <td colspan="8" class="text-center text-muted py-5">
               <i class="fa-regular fa-folder-open fa-2x mb-2 d-block"></i>
               No hay tickets problemáticos en este momento.
           </td>
       </tr>
   @endforelse
   ```

3. Si la query falla silenciosamente: agregar `dd($tickets)` temporalmente para depurar,
   luego removerlo.

4. Verificar que `$stats` se pasa a la vista correctamente y que los `stat-card` no generan
   errores PHP cuando las propiedades del objeto son `null` (usar `?->cantidad ?? 0`).

---

## Verificación final

```bash
php artisan test
```

Reportar:
- Número de tests que pasan / fallan
- Si algún test nuevo o existente rompió por los cambios

**No romper tests existentes.** Si un cambio rompe un test, arreglarlo antes de entregar.
