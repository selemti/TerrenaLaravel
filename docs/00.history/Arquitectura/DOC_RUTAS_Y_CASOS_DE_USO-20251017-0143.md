Rutas y Casos de Uso — Con salida artisan

Fecha: 2025-10-17 01:43

Resumen de rutas (agrupado, desde `php artisan route:list`)
- Caja (API):
  - GET /api/caja/cajas → CajasController@index
  - GET /api/caja/conciliacion/{sesion_id} → ConciliacionController@getBySesion
  - GET /api/caja/formas-pago → FormasPagoController@index
  - Precortes: preflight (GET|POST), create (POST), show (GET), update (POST), enviar (POST), status (GET|POST), totales (GET)
  - Postcortes: create (POST), show (GET), update (POST), detalle (GET)
  - Sesiones: GET /api/caja/sesiones/activa → SesionesController@getActiva
- Legacy (compat): rutas /api/legacy/* para precortes/postcortes y estilos .php
- Inventory (API): items CRUD; stock endpoints; vendor attach/byItem
- Unidades (API): unidad CRUD; conversiones CRUD
- Web/Blade: /, /dashboard, /caja/cortes, /inventario, /compras, /recetas, /produccion, /personal; KDS /kds

Middlewares (desde `route:list --json`)
- Grupo `api` presente en rutas /api/*, pero sin `auth` explícito.
- Rutas web con middleware `web`.

Casos de uso (Caja)
- Listado de cajas del día → GET /api/caja/cajas?date=YYYY-MM-DD
- Wizard de cortes → precorte (preflight → create/update), conciliación, postcorte (create/update validado)

Notas
- Recomendado: proteger /api/caja/* con `auth` y autorización por rol/permisos.

