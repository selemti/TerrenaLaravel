Auditoría técnica — Código (Laravel/JS/CSS)

Fecha: 2025-10-17 01:18

Resumen
- Proyecto Laravel con front Blade + assets estáticos en `public/assets` y Livewire para catálogos/inventario.
- Backoffice incluye módulo de Caja (cortes) con endpoints JSON en `routes/api.php` bajo prefijo `/api/caja`.
- No se encontraron Policies; Requests básicos; Middleware API custom presente pero Kernel no estándar.

Estructura clave
- Rutas web: `routes/web.php:1` — Vistas: `dashboard`, `compras`, `inventario`, `personal`, `produccion`, `recetas`. Caja: `Route::view('/caja/cortes', 'caja.cortes')`.
- Rutas API: `routes/api.php:1` — Prefijos: `/api/caja` (cajas, sesiones, precortes, postcortes, conciliación, formas de pago); `/api/legacy` compatibilidad.
- Controladores Caja: `app/Http/Controllers/Api/Caja/*.php`
  - `CajasController.php:1` — lista terminales/sesiones (JOIN `public.terminal`, `public.users`, `selemti.sesion_cajon`).
  - `PrecorteController.php:1` — preflight; create/update precorte (`selemti.precorte`, `precorte_efectivo`, `precorte_otros`).
  - `PostcorteController.php:1` — create/update postcorte (`selemti.postcorte`) y cierre de sesión.
  - `SesionesController.php:1` — obtener sesión activa.
  - `ConciliacionController.php:1` — vista `selemti.vw_conciliacion_sesion`.
  - `FormasPagoController.php:1` — `selemti.formas_pago` activas.
- Vistas Caja: `resources/views/caja/cortes.blade.php:1`
  - Incluye `caja._wizard_modals` (archivo real: `resources/views/caja/_wizard_modals.php`) y `_anulaciones.blade.php`.
  - Carga `public/assets/js/caja/main.js` (ES modules) y usa layout `resources/views/layouts/terrena.blade.php:1`.
- Assets Caja (JS): `public/assets/js/caja/`
  - `main.js`, `mainTable.js`, `wizard.js`, `config.js`, `state.js`, `helpers.js`.
  - CSS: `public/assets/css/caja.css`.
- Livewire (otros módulos): `app/Livewire/**` (catálogos, inventario, recetas, KDS).

Middleware y Auth
- Middleware API custom: `app/Http/Middleware/ApiResponseMiddleware.php:1` (Forzar Accept JSON, CORS dev, cabeceras, fallback 500 JSON).
- Kernel no estándar en `app/Http/Middleware/Kernel.php:1`. En Laravel debe ser `app/Http/Kernel.php`; es probable que este Kernel no sea usado y que el middleware API no se aplique.
- Rutas API carecen de `auth`/`sanctum` explícito. `routes/api.php:1` declara login pero no protege `/api/caja/*`.

Requests / Policies
- Requests: `app/Http/Requests/Auth/LoginRequest.php:1` (válido), `app/Http/Requests/ProfileUpdateRequest.php:1`.
- `app/Http/Requests/StorePrecorteRequest.php:1` tiene `authorize(): false` y reglas vacías; no está integrado en controladores.
- Policies: no se encontraron archivos en `app/Policies`.

Observaciones de calidad y riesgos
- Mismatch IDs modal Wizard: `wizard.js` inicializa con `#czModalPrecorte`, mientras el modal es `#wizardPrecorte` (`_wizard_modals.php:1`). Aunque hay selectores de fallback en varias consultas, la inicialización del Modal podría fallar.
- `mainTable.js:1` — `puedeWizard()` retorna `true` siempre (comentado el filtro real), habilitando el botón de wizard en cualquier estado.
- Endpoints de Caja escriben directamente en esquema `selemti` con SQL crudo dentro de controladores (transaccional en `updateLegacy`, correcto). Requiere controles de auth/roles para operar en producción.
- Encoding con mojibake en textos (e.g., “Administraci�n”) en varias vistas/JS. Revisar codificación/UTF-8.
- `store` hardcodeado en `mainTable.js:1` (`const store = 1;`).
- Assets estáticos en `public/assets` conviven con Vite (`vite.config.js`); no se aprecia pipeline de build unificado.

Recomendaciones
- Mover/crear `app/Http/Kernel.php` y registrar `ApiResponseMiddleware` en `api` group. Proteger `/api/caja/*` con `auth:sanctum` o similar.
- Armonizar IDs del modal Wizard y los selectores en `wizard.js`/`state.js` para una fuente de verdad.
- Restaurar lógica de `puedeWizard()` para mostrar el botón solo cuando aplique.
- Sustituir hardcode `store=1` por valor del backend o configuración.
- Revisar `.env` y `config/app.php` para `APP_URL`/`URL::forceRootUrl` si hay despliegues en subcarpetas (usa `window.__BASE__` en layout).
- Normalizar encoding en fuentes (UTF‑8 sin BOM) y contenidos blade.

Archivos relevantes adicionales
- Layout: `resources/views/layouts/terrena.blade.php:1` (sidebar, topbar, assets, `window.__BASE__`).
- Web rutas a livewire: `routes/web.php:1` (Catálogos, Inventario, Recetas, KDS).

