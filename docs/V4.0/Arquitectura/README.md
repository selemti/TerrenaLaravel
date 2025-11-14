# Terrena V4.0 · Arquitectura y Stack

## 1. Alcance y fuentes

Fuente única para entender cómo está armado Terrena en V4.0. Se apoya en:

- Código real (`app/`, `routes/`, `config/`, `resources/views/`).
- `docs/Arquitectura/ROUTES_CONTROLLERS_VIEWS-20251017-0251.md` (mapa de rutas/controladores).
- `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md` (§2.1 Stack actual).
- Configuración de entorno (`.env`, `config/database.php`, `config/queue.php`).

Cualquier cambio arquitectónico debe reflejarse aquí antes de mergear código.

---

## 2. Stack resumido

| Capa | Tecnología | Notas |
|------|------------|-------|
| Backend | Laravel 10, PHP 8.2 | Estructura estándar app/ (Http, Models, Services, Jobs). |
| Frontend | Blade + Livewire + Alpine.js | Layout principal `resources/views/layouts/terrena.blade.php`; componentes en `resources/views/components/`. |
| Estilos | Tailwind (componentes modernos) + Bootstrap 5 (legacy) + `public/assets/css/terrena.css`. |
| DB | PostgreSQL 9.5+ con esquema `selemti` (141 tablas normalizadas). |
| Cache/Queue | Redis (`QUEUE_CONNECTION=redis` recomendado) + almacenamiento local/ S3 para archivos. |
| Permisos | Spatie Laravel-Permission (`config/permissions.php`, `app/Providers/AuthServiceProvider.php`). |

Ambiente local corre típicamente en WSL. Para acceder a la base desde WSL usar `DB_HOST=172.24.240.1`; fuera de WSL `127.0.0.1`.

---

## 3. Capas de la aplicación

### 3.1 Entrada (HTTP)

- **Rutas web**: `routes/web.php` amarra páginas Livewire (`Route::get(..., Component::class)`) y vistas Blade clásicas (login, dashboard).
- **Rutas API**: `routes/api.php` expone CRUDs (`/api/inventory/*`, `/api/caja/*`, `/api/unidades/*`). En el mapa 20251017 se detectaron endpoints sin middleware `auth`; antes de abrir nuevos módulos, protegerlos con guardias y políticas.
- **Middleware**: estándares de Laravel + `EnsureEmailIsVerified`, `auth`, `verified`. Cualquier restricción adicional se maneja por permisos en controllers/components (`->can` o policy).

### 3.2 Presentación (Livewire/Blade)

- Componentes en `app/Livewire/*` (Inventario, Purchasing, CashFund, InventoryCount). Cada componente renderiza vistas en `resources/views/livewire/...`.
- Layouts descritos en `docs/V4.0/Frontend/Layout.md`. Todo V4.0 debe usar `layouts.terrena` (autenticado) o `layouts.guest`.
- Componentes UI comunes documentados en `docs/V4.0/Frontend/Componentes.md` y alojados en `resources/views/components/ui/*`.

### 3.3 Servicios y dominio

- Directorio `app/Services/` aloja lógica de negocio (Inventory, Purchasing, Production, POS). Ej: `app/Services/Inventory/TransferService.php`, `InventoryCountService.php`.
- Modelos Eloquent en `app/Models/` y subcarpetas (`app/Models/Inv/Item.php`, `app/Models/InventoryCount.php`) apuntan a las tablas `selemti.*`.
- Jobs/Listeners (`app/Jobs`, `app/Listeners`) manejan procesos asíncronos cuando se habilitan colas.

### 3.4 Infraestructura

- Configuración en `config/*` (cache, queue, broadcasting). `config/queue.php` ya trae driver redis.
- Scripts CLI en `artisan` + `artisan` commands custom (`app/Console/Commands/*`).
- Storage: `storage/app` para archivos locales; `config/filesystems.php` define drivers (local, s3). Asegurar `APP_URL`/`FILESYSTEM_DISK` correctos antes de subir archivos.

---

## 4. Datos y esquemas

| Recurso | Detalle |
|---------|---------|
| Postgres schemas | `selemti` (principal), `public` (legacy compat). Migraciones modernas prefijan `Schema::connection('pgsql')->table('selemti.xxx')`. |
| Inventario | Tablas `selemti.items`, `item_categories`, `inventory_batch`, `inventory_counts`, `mov_inv`. Flujos documentados en `docs/V4.0/Inventario/*.md`. |
| Purchasing | `selemti.purchase_orders`, `purchase_requests`, `vendors`. |
| Caja | `selemti.cash_sessions`, `cash_movements`, etc. Documentado en `docs/CajaChica/FondoCaja/`. |
| Auditoría | Triggers mencionados en el plan maestro; logs accesibles vía `audit_log` y servicios en `app/Services/Audit`. |

**Regla de conexión**: No editar `.env` ajeno. Usa `DB_HOST=172.24.240.1` desde WSL o `127.0.0.1` local, y confirma credenciales antes de ejecutar migraciones. Para validar esquema, consulta directamente la DB (psql/Beekeeper) y ajusta modelos/migraciones en consecuencia.

---

## 5. Colas, eventos y jobs

- Driver recomendado: Redis (`QUEUE_CONNECTION=redis`). Actualmente `.env` tiene `sync`; al habilitar procesos asíncronos (recepciones, alertas, recalculo recetas) cambiar a redis y correr `php artisan queue:work`.
- Jobs clave: `app/Jobs/ProcessInventoryTransfer.php`, `RecalcularCostosRecetasJob`, etc. Revisa `app/Jobs` antes de crear nuevos.
- Events/Listeners en `app/Events`, `app/Listeners` (ej. auditoría). Usa `php artisan event:list` para inventariar.
- Para tareas programadas usa `app/Console/Kernel.php` (`schedule()->command(...)`).

---

## 6. Integraciones externas

| Integración | Descripción | Punto de contacto |
|-------------|-------------|-------------------|
| Floreant POS | Lectura de tickets y existencias. Servicios en `app/Services/PosConsumption/` y docs `docs/PosConsumption`. |
| Reportes (BaseReportController) | Resúmenes ventas/kpis (`docs/BD/NoviembreDocs/VentasReport/...`). Usa colores configurados en `config/reports.php`. |
| Webhooks/Alertas | Pendientes; hoy alertas se alimentan desde `/api/caja/alertas`. |

Cualquier nueva integración debe documentar endpoints, permisos y esquema bajo `docs/V4.0/Integraciones/<nombre>.md`.

---

## 7. Seguridad y permisos

- Roles/permisos gestionados vía Spatie. Mapa de permisos en `config/permissions_map.php` y docs `docs/UI-UX/MASTER/07_DELEGACION_AI/...`.
- Rutas y menús usan `window.TerrenaHasPerm`. Para APIs, valida en controladores (`$this->authorize(...)` o middleware `can`).
- Tokens API: layout Terrena obtiene `window.TerrenaApiToken` vía `/session/api-token`. Si se agregan endpoints nuevos, asegúrate de respetar este flujo.
- Nunca expongas `/api/*` sin `auth:sanctum` o token de sesión. El documento legacy de rutas resaltó endpoints abiertos; deben cerrarse.

---

## 8. Entornos y despliegues

| Entorno | Detalle |
|---------|---------|
| Local (WSL) | Usa este repositorio, `php artisan serve`, `npm run dev`. Base conectada a host Windows `172.24.240.1`. |
| Local (Windows/Mac) | `DB_HOST=127.0.0.1`. Para front, `npm run dev` lanza Vite. |
| QA/Staging | Pendiente documentar pipeline (posible XAMPP). Añadir sección cuando exista CI/CD. |

Checklist antes de subir cambios:
1. `composer install && npm install` (si cambiaste dependencias).
2. `php artisan test` o suites específicas (`test --testsuite=Feature`).
3. `npm run build` para assets productivos.
4. `./vendor/bin/pint` para PSR-12.

---

## 9. Procedimiento de actualización

1. **Verificar fuente**: antes de tocar arquitectura, revisa esta ficha, el mapa de rutas y el código correspondiente.
2. **Documentar primero**: describe el cambio aquí (ej. nuevo servicio en `app/Services/Inventory/ReceivingService.php`) y luego implementa.
3. **Validar contra BD y config**: siempre confirma que modelos y servicios usan tablas reales (`\DB::table('selemti.xxx')`).
4. **Control de cambios**: registra en el PR qué se tocó y qué se actualizó de la doc. Si el cambio afecta layout o componentes, sincroniza también `docs/V4.0/Frontend/*.md`.
5. **Revisión cruzada**: después de merge, anota en `docs/V4.0/README.md` si se publicó un módulo nuevo o se cerró un pendiente.

Cumpliendo estos pasos mantenemos la arquitectura alineada con el código y evitamos divergencias entre documentación y realidad.
