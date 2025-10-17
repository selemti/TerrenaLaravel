Rutas, Controladores y Vistas — Mapa

Fecha: 20251017-0251

A) Rutas (agrupadas por módulo)
- Fuente: php artisan route:list --json.
- Nota: muchas rutas /api/* usan middleware "api" sin "auth".

Caja (API)
- GET /api/caja/cajas [api] → CajasController@index (sin auth)
- GET /api/caja/sesiones/activa [api] → SesionesController@getActiva (sin auth)
- Precortes: preflight (GET|POST), create (POST), show (GET), update (POST), enviar (POST), status (GET|POST), totales (GET) [api] (sin auth)
- Postcortes: create (POST), show (GET), update (POST), detalle (GET) [api] (sin auth)
- Conciliación: GET /api/caja/conciliacion/{sesion_id} [api] (sin auth)
- Formas de pago: GET /api/caja/formas-pago [api] (sin auth)

Inventario (API)
- /api/inventory/items [GET,POST,GET/{id},PUT,DELETE] [api] (sin auth)
- /api/inventory/items/{id}/batches,kardex,vendors [GET/POST] [api] (sin auth)
- /api/inventory/stock [GET] [api] (sin auth)

Catálogos/Unidades (API)
- /api/unidades [GET,POST,GET/{id},PUT/{id},DELETE/{id}] [api] (sin auth)
- /api/unidades/conversiones [GET,POST,PUT/{id},DELETE/{id}] [api] (sin auth)

Auth/Health/Swagger
- /api/auth/login [POST|GET] [api] (sin auth)
- /api/health [GET] [api]
- /api/documentation [GET] [swagger]

Web/Blade
- /, /dashboard, /inventario, /compras, /recetas, /produccion, /personal [web]
- /caja/cortes [web] → view 'caja.cortes'

Rutas sin 'auth':
- Todas las rutas anteriores que muestran [api] están sin 'auth'. Recomendado proteger /api/caja/* y endpoints sensibles.

B) Controladores (métodos y FormRequests)
- Api\Caja\CajasController: index(Request) → JSON (sesiones/terminales)
- Api\Caja\PrecorteController: preflight, createLegacy, updateLegacy, show, resumenLegacy, statusLegacy, enviar, totalesPorSesion → Request (sin FormRequest dedicado)
- Api\Caja\PostcorteController: create, update, show, detalle → Request (sin FormRequest dedicado)
- Api\Caja\SesionesController: getActiva → Request
- Api\Caja\ConciliacionController: getBySesion → Request
- Api\Caja\FormasPagoController: index/listar → (sin FormRequest)
- Api\Inventory\ItemController: index,show,store,update,destroy → Request
- Api\Inventory\StockController: kardex,batches,stockByItem → Request
- Api\Inventory\VendorController: byItem,attach → Request
- Api\Unidades\UnidadController: index,show,store,update,destroy → Request
- Api\Unidades\ConversionController: index,store,update,destroy → Request
- Auth controllers (Breeze): Vistas auth (login/register/forgot/reset), usan FormRequests de Breeze.

FormRequests asociados
- Auth\LoginRequest, ProfileUpdateRequest presentes; para Caja (precorte/postcorte) no hay FormRequests específicos (recomendado crear).

Vistas referenciadas desde controladores
- CajaController@index (web): retorna view('caja.cortes')
- Breeze Auth controllers: auth/*.blade.php
- Livewire retorna vistas en app/Livewire/** (no listadas como controladores API).

C) Vistas (por módulo) y parciales
- Caja: resources/views/caja/cortes.blade.php; _anulaciones.blade.php; _wizard_modals.php
  - includes detectados en cortes: @include('caja._wizard_modals'), @include('caja._anulaciones')
  - VERIFICACIÓN: 'caja/_wizard_modals.blade.php' NO existe; existe 'caja/_wizard_modals.php'. Reporte: parcial faltante o extensión incorrecta.
- Layouts: resources/views/layouts/{terrena,app,guest,navigation}.blade.php
- Inventario: resources/views/inventory/{items-index,lots-index,receptions-index,receptions-create}.blade.php
- Livewire: resources/views/livewire/** (catálogos, inventario, recetas, kds)
- Auth: resources/views/auth/*.blade.php
- Dashboard y estáticas: dashboard.blade.php, compras.blade.php, inventario.blade.php, etc.

D) Matrices
- Ruta ↔ Controller@method ↔ Vista(s)
  - /caja/cortes [web] → view caja.cortes → incluye parciales caja/_wizard_modals, caja/_anulaciones
  - /api/caja/* [api] → controladores bajo Api\Caja (retornan JSON; no vistas)
  - /api/inventory/* [api] → controladores Api\Inventory (JSON)
  - /api/unidades/* [api] → controladores Api\Unidades (JSON)
  - /auth y /profile (web) → controladores Breeze + vistas auth/* y profile/*

- Rutas definidas sin vista (web):
  - Ninguna adicional detectada fuera de /caja/cortes; el resto son APIs o vistas web simples.

- Vistas sin ruta:
  - Varias vistas Livewire (se acceden por componentes/rutas Livewire en web.php). Las vistas parciales (partials/*) y components/* son consumidas por layouts.

Notas de seguridad
- Marcar endpoints /api/caja/*, /api/inventory/*, /api/unidades/* para proteger con 'auth' y autorización por roles/permisos.
- Añadir policies/abilities ('can:...') en rutas o authorize() en controladores para operaciones sensibles.
