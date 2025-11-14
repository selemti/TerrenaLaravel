# Frontend V4.0 · Layouts y estructura base

## 1. Alcance y fuentes

Este documento describe los layouts activos y cómo deben usarse desde cualquier vista Livewire/Blade. Sale directamente de:

- `resources/views/layouts/terrena.blade.php`
- `resources/views/layouts/{app,guest,auth}.blade.php`
- `docs/Front/FRONT_BLUEPRINT.md` (§3 · Arquitectura UI)
- `docs/Front/FRONT_BLUEPRINT_V2.md` (§1 · Control de acceso visual)

Cualquier layout no listado aquí se considera legacy o experimental.

## 2. Catálogo de layouts

| Layout | Uso | Características clave |
|--------|-----|-----------------------|
| `layouts.terrena` | Vista principal autenticada (sidebar Terrena + top bar). | Container flex con sidebar, loader de permisos/API, alertas navbar, helpers JS globales. |
| `layouts.app` | Stack Tailwind heredado de Breeze/Jetstream. | Sidebar simple (`layouts.sidebar`), top bar ligero, `@vite` assets `resources/css/js`. |
| `layouts.guest` | Login, reset y páginas públicas. | Navbar oscuro + footer, guard JS que corrige URLs absolutas, `container` central. |
| `layouts.auth` | Formularios de auth compactos. | Variación minimalista (usa `@vite`) para flujos específicos. |

> Regla: antes de crear un layout nuevo valida si los requisitos caben en `terrena` o `guest`. Mantener uno por tipo evita divergencias de estilos.

## 3. Layout `terrena`: estructura

```
body
└── div.container-fluid.d-flex (min-height:100vh)
    ├── aside#sidebar (solo @auth)
    │   ├── logo + nav (permisos controlados con Alpine)
    │   └── botón collapse
    └── main.main-content.flex-grow-1
        ├── div.top-bar (sticky)
        ├── div.p-3  ← contenido de cada vista (`@yield('content')` / `$slot`)
        └── footer.status-bar (opcional)
```

### Sidebar
- Navigation gerenciado por Alpine (`permsLoaded`) que escucha `terrena:perms-ready`.
- Permisos cargados vía `window.TerrenaHasPerm()`; las rutas visibles son las mismas definidas en `routes/web.php`.
- Idioma iconográfico FontAwesome (`assets/fontawesome-free-7.0.1-web`).

### Contenido
- El layout ya aporta `div.p-3`; **no envuelvas tus vistas con otro `container` o `row` raíz**. Si necesitas grids, inicia con `<div class="row g-3">` directamente dentro del contenido para evitar desplazamientos a la derecha.
- Usa `@section('page-title')` o `$pageTitle` para títulos; si no, cae en “Dashboard”.

### Top bar / footer
- Reloj en vivo, dropdown de alertas (consume `/api/caja/alertas*`), menú de usuario con logout que revoca el token (`handleTerrenaLogout`).
- Footer “status bar” muestra sucursal y hora inferior; extendible para otros indicadores.

## 4. Scripts y assets comunes

- **CSS**: `assets/css/{bootstrap.min.css, terena.css, caja.css}` + FontAwesome. Respetar este orden para no romper overrides.
- **JS** (al final del body):
  - `bootstrap.bundle.min.js`, `chart.js`, `cleave`, `moneda.js`, `terrena.js`.
  - `TerrenaLoadApiToken`, `TerrenaLoadPermissions`, `TerrenaClearAuth` (cargan token/bandeja de permisos y cachean en `sessionStorage`).
  - Ajuste de rutas Livewire (`livewire.hook('request')`) para ambientes detrás de subpaths.
  - Persistencia de collapses (`localStorage` key `terrena_sidebar_collapses`).
  - Sistema de alertas barra superior (polling cada 30s).
- **Livewire hooks**: `@livewireStyles` en `<head>`, `@livewireScripts` antes de los scripts custom para asegurar compatibilidad.

## 5. Buenas prácticas / anti-patterns

1. **Nada de contenedores duplicados**: el flex principal ya divide sidebar y contenido. Si la vista inserta otro `container-fluid` raíz, toda la grilla se pega a la derecha (bug reportado). Únicamente agrega contenedores internos (`w-100`) si necesitas full-width dentro del área asignada.
2. **Slots y secciones**: prioriza `$slot` en componentes Livewire de página completa; usa `@section('content')` solo en blades clásicos. No mezcles ambos sin saber cuál aplica.
3. **Permisos visuales**: reutiliza las funciones globales `TerrenaHasPerm` y escucha `terrena:perms-ready` cuando necesites esconder botones específicos para mantener consistencia con el sidebar.
4. **Dependencias**: cualquier JS/CSS adicional debe ir en `@push('styles')` o `@push('scripts')` para que el layout mantenga el orden. Evita inyectar `<script>` directo en la vista.
5. **Mobile behavior**: usa los toggles provistos (`#sidebarToggleMobile`, `#sidebarCollapse`). No dupliques botones de menú; se manejaría desde el layout.

## 6. Layouts alternos

- `layouts.app`: pensado para vistas internas en Tailwind; provee `@include('layouts.sidebar')` y `header` simple. Úsalo solo si el módulo no depende del branding Terrena o está siendo migrado.
- `layouts.guest`: contiene navbar, guard de URLs y footer. Toda vista pública debe heredar de aquí para evitar inventar wrappers.
- `layouts.navigation` / `layouts.sidebar`: parciales referenciados por `app.blade.php`. No se usan en `terrena` pero se mantienen para compatibilidad con Jetstream.

## 7. Checklist antes de subir una vista

- [ ] Elegiste el layout correcto (autenticado → `terrena`, público → `guest`, admin tailwind → `app`).
- [ ] No agregaste contenedores raíz adicionales; el primer nodo dentro del layout es tu componente Livewire.
- [ ] Tus assets extras van en `@push`.
- [ ] Verificaste que los permisos/links correspondan a `routes/web.php` y se valían con `TerrenaHasPerm`.
- [ ] Probaste en resoluciones móviles (sidebar collapsible) y confirmaste que las filas siguen alineadas.

Cumpliendo estos puntos mantenemos estilos, estructura y scripts compartidos sincronizados en todo V4.0.
