Controladores y Vistas — Inventario, Caja, Catálogos

Fecha: 2025-10-17 01:26

Controladores (selección por módulo)
- Caja — app/Http/Controllers/Api/Caja
  - CajasController@index — Lista terminales/sesiones y flags de corte.
  - PrecorteController@preflight, @createLegacy, @updateLegacy, @show, @statusLegacy, @resumenLegacy, @totalesPorSesion.
  - PostcorteController@create, @update, @show, @detalle.
  - SesionesController@getActiva.
  - ConciliacionController@getBySesion.
  - FormasPagoController@index, @listar (alias legacy).
- Inventory — app/Http/Controllers/Api/Inventory
  - ItemController@index/show/store/update/destroy.
  - StockController@kardex, @batches, @stockByItem.
  - VendorController@byItem, @attach.
- Unidades — app/Http/Controllers/Api/Unidades
  - UnidadController CRUD; ConversionController CRUD.
- Auth — app/Http/Controllers/Auth (Breeze) — login/registro/password.

FormRequests
- Auth\LoginRequest — reglas para login.
- ProfileUpdateRequest — reglas de perfil.
- StorePrecorteRequest — NO utilizado; authorize() devuelve false (debería eliminarse o integrarse con reglas reales si se usa).

Vistas
- Layout: resources/views/layouts/terrena.blade.php — Sidebar/Topbar, assets (Bootstrap, FA, CSS), expone `window.__BASE__`.
- Caja:
  - resources/views/caja/cortes.blade.php — KPIs, tabla, botón Wizard por fila, incluye `caja/_wizard_modals.php` y `_anulaciones.blade.php`.
  - resources/views/caja/_wizard_modals.php — HTML del modal con pasos 1–3.
  - resources/views/caja/_anulaciones.blade.php — parcial adicional (no analizado en detalle).
- Vistas “menú” básicas: `dashboard`, `inventario`, `compras`, `recetas`, `produccion`, `personal`.

Assets vinculados en vistas Caja
- JS: `public/assets/js/caja/main.js` (importa `wizard.js`, `mainTable.js`, `helpers.js`, `state.js`, `config.js`).
- CSS: `public/assets/css/caja.css`.

Estado actual
- Caja:
  - Flujo wizard implementado, con selectores alternativos; requiere unificación de IDs del modal e implementación del guard de acciones.
  - Endpoints API listos (precorte/postcorte/conciliación), sin auth explícita.
- Inventario/Catálogos/Recetas: presentes (Livewire) pero no auditados en detalle aquí; se requiere repaso de reglas/validaciones y políticas.

Faltantes/Mejoras
- Políticas (Policies) y autorización por rol/permisos en controladores API, idealmente con spatie/permission.
- Validaciones en endpoints Caja (usar FormRequests dedicados en create/update precorte/postcorte).
- Limpieza de encoding en vistas/JS (acentos).
- Consolidar assets (Vite vs `public/assets`) o documentar estrategia de build/hot-reload.

