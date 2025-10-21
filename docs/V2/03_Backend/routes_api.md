# Rutas API (REST + Legacy)

Fuente: `routes/api.php` (Laravel 12).

## 1. Salud y Autenticación

- `GET /api/ping` → `{"ok": true, "timestamp": ...}`  
- `GET /api/health` → `Api\Caja\HealthController@check` (pendiente robustecer).  
- `POST /api/auth/login` → `Api\Caja\AuthController@login` (JWT; requiere completar flujo).  
- `GET /api/auth/login` → helper para navegadores (HEAD/OPTIONS).

## 2. Reportes (`/api/reports/*`)

| Endpoint | Controlador | Estado |
|----------|-------------|--------|
| `/kpis/sucursal`, `/kpis/terminal` | `ReportsController` | Consultas pendientes. |
| `/ventas/familia`, `/ventas/hora`, `/ventas/top`, `/ventas/dia`, `/ventas/items_resumen`, `/ventas/formas`, `/ticket/promedio` | `ReportsController` | Requieren vistas/materializadas. |
| `/stock/val`, `/consumo/vr`, `/anomalias` | `ReportsController` | En diseño. |

## 3. Caja (`/api/caja/*`)

### Cajas & Tickets

- `GET /api/caja/cajas` → `CajasController@index`
- `GET /api/caja/ticket/{id}` → `CajaController@getTicketDetail`
- `GET /api/caja/sesiones/activa` → `SesionesController@getActiva`

### Precortes

| Método | Ruta | Acción |
|--------|------|--------|
| `match GET|POST` | `/api/caja/precortes/preflight/{sesion_id?}` | Verifica tickets abiertos |
| `POST` | `/api/caja/precortes` | `PrecorteController@createLegacy` |
| `GET` | `/api/caja/precortes/{id}` | `show` |
| `POST` | `/api/caja/precortes/{id}` | `updateLegacy` |
| `GET` | `/api/caja/precortes/{id}/totales` | `resumenLegacy` |
| `match GET|POST` | `/api/caja/precortes/{id}/status` | `statusLegacy` |
| `POST` | `/api/caja/precortes/{id}/enviar` | Enviar por lote |
| `GET` | `/api/caja/precortes/sesion/{sesion_id}/totales` | Totales por sesión |

### Postcortes

- `POST /api/caja/postcortes` → `PostcorteController@create`
- `GET /api/caja/postcortes/{id}` → `show`
- `POST /api/caja/postcortes/{id}` → `update`
- `GET /api/caja/postcortes/{id}/detalle` → `detalle`

### Otros

- `GET /api/caja/conciliacion/{sesion_id}` → `ConciliacionController@getBySesion`
- `GET /api/caja/formas-pago` → `FormasPagoController@index`

## 4. Unidades (`/api/unidades/*`)

- CRUD de unidades → `Api\Unidades\UnidadController`
- CRUD de conversiones → `Api\Unidades\ConversionController`

## 5. Inventario (`/api/inventory/*`)

| Ruta | Controlador | Notas |
|------|-------------|-------|
| `/api/inventory/items` (GET/POST/PUT/DELETE) | `ItemController` | Falta definir policies y validaciones finales. |
| `/api/inventory/items/{id}/kardex` | `StockController@kardex` | Requiere vistas. |
| `/api/inventory/items/{id}/batches` | `StockController@batches` | Depende de datos de lotes. |
| `/api/inventory/items/{id}/vendors` (GET/POST) | `VendorController` | Adjunta proveedores a ítems. |
| `/api/inventory/stock` | `StockController@stockByItem` | KPI stock total. |

## 6. Legacy (`/api/legacy/*`)

- Endpoints compatibles con Slim/PHP anterior (`/caja/cajas.php`, `/caja/precorte_*.php`, `/precortes`, `/postcortes`, `/sprecorte/*`).  
- Objetivo: deprecarlos una vez que el nuevo frontend consuma las rutas modernas.

## 7. Respuestas y Errores

- JSON estándar: `{ ok: bool, data?, error?, message?, timestamp }`.  
- Falta middleware de autenticación/roles; actualmente expuestos sin guard.  
- Tareas: documentar códigos de error, throttling y versionado (`/api/v1/*`).

Actualiza este archivo cuando cambien los endpoints o se agregue autenticación.
