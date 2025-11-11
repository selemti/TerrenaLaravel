Rutas y Casos de Uso — Resumen

Fecha: 2025-10-17 01:26

Nota: Se puede adjuntar salida de `php artisan route:list` (y `--json`) si lo apruebas. Por ahora, se mapean rutas desde archivos.

Módulo Caja (API JSON)
- GET `/api/caja/cajas` → CajasController@index — Lista terminales/sesiones/datos de estado por fecha (`?date=YYYY-MM-DD`).
- GET `/api/caja/sesiones/activa` → SesionesController@getActiva — Sesión activa por terminal/usuario.
- Precortes (PrecorteController):
  - MATCH GET|POST `/api/caja/precortes/preflight/{sesion_id?}` → preflight.
  - POST `/api/caja/precortes` → createLegacy (idempotente por sesión).
  - GET `/api/caja/precortes/{id}` → show.
  - POST `/api/caja/precortes/{id}` → updateLegacy.
  - GET `/api/caja/precortes/{id}/totales` → resumenLegacy.
  - MATCH GET|POST `/api/caja/precortes/{id}/status` → statusLegacy.
  - GET `/api/caja/precortes/sesion/{sesion_id}/totales` → totalesPorSesion.
- Postcortes (PostcorteController):
  - POST `/api/caja/postcortes` → create.
  - GET `/api/caja/postcortes/{id}` → show.
  - POST `/api/caja/postcortes/{id}` → update (opcional validar/cerrar).
  - GET `/api/caja/postcortes/{id}/detalle` → detalle.
- Conciliación: GET `/api/caja/conciliacion/{sesion_id}` → ConciliacionController@getBySesion.
- Formas de pago: GET `/api/caja/formas-pago` → FormasPagoController@index.
- Legacy compat: `/api/legacy/...` (mantener hasta migración completa del front).

Módulo Caja (Web/Blade)
- GET `/caja/cortes` → view `caja.cortes` (layout `layouts.terrena`). Carga JS `assets/js/caja/main.js` y parciales del Wizard.

Otros módulos (Web/Livewire)
- Dashboard/menú: `/dashboard`, `/compras`, `/inventario`, `/personal`, `/produccion`, `/recetas` → Route::view (o Livewire en subrutas).
- Catálogos: `/catalogos/{unidades,uom,almacenes,proveedores,sucursales,stock-policy}` → Livewire components.
- Inventario: `/inventory/{items,receptions,receptions/new,lots}` → Livewire.
- KDS: `/kds` → Livewire Board.

Middlewares y auth previstos
- Grupo `api` debería incluir throttle y bindings; aplicación del Middleware `ApiResponseMiddleware` depende de que el Kernel correcto esté registrado (ver doc general).
- No se observa `auth`/`sanctum` aplicado explícitamente en `/api/caja/*`.

Casos de uso (Caja)
- “Listar cajas del día”: Front GET `/api/caja/cajas?date=YYYY-MM-DD` y render tabla con KPIs.
- “Abrir wizard de corte”: Botón fila → `abrirWizard()` con `store_id`, `terminal_id`, `user_id`, `sesion_id`, `bdate`.
- “Precorte (declaración)”: Preflight → create/obtener `precorte_id` → updateLegacy con denoms + no-efectivo + notas.
- “Conciliación”: GET `/api/caja/conciliacion/{sesion_id}`; evaluar banner de “falta corte POS”.
- “Postcorte y validación”: POST create o POST update (validado=true) → cerrar sesión.

Pendiente (si apruebas)
- Adjuntar `php artisan route:list` (texto y/o --json) agrupado por prefijo/módulo y revisión de middlewares efectivos.

