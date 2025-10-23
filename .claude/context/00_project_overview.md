# Terrena POS · Panorama

TerrenaLaravel reescribe el POS Terrena sobre Laravel 12 + Livewire 3 con una arquitectura dual: PostgreSQL `selemti` conserva el legado operativo y el esquema `public` alberga catálogos modernos y migraciones idempotentes (`docs/V2/02_Database`). Las definiciones vigentes provienen del despliegue v3 (`BD/DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148-safe.sql`), por lo que cualquier ambiente debe cargar esas tablas, funciones y vistas antes de ejecutar módulos.

Estado actual por dominio:
- **Caja** (`app/Http/Controllers/Api/Caja`, `app/Models/Caja`): wizard de precorte → conciliación → postcorte funcionando contra tablas v3 `sesion_cajon`, `precorte`, `postcorte`. Mantiene rutas modernizadas y un prefijo `/api/legacy/*` para clientes Slim.
- **Inventario** (`app/Models/Inv`, `App\Services\Inventory\ReceptionService`): CRUD de items, lotes y kardex usa objetos `selemti.items`, `inventory_batch`, `mov_inv`. Las vistas KPI (`vw_stock_actual`, `vw_stock_valorizado`) se generan desde los parches v3 y se consumen en `/api/inventory/*`.
- **Catálogos** (`app/Models/Catalogs`, Livewire `resources/views/catalogos`): tablas `public.cat_*` complementan catálogos POS; la sincronización con `selemti` sigue abierta y debe documentarse por cambio.
- **Reportes** (`App\Http\Controllers\Api\ReportsController`): endpoints listados en `routes/api.php` dependen de vistas aún en construcción; marcar como experimental.
- **Autenticación**: `Api\Caja\AuthController` ya usa tokens Sanctum aunque el proyecto mantiene `tymon/jwt-auth` para la futura estandarización JWT.

El monorepo también incluye recetas, compras y KDS, pero su documentación permanece en `docs/V2/04_Frontend` y no es prioritaria para la CLI. Antes de cualquier release ejecutar `composer test`, `npm run build` y `php artisan catalogs:verify-tables --details` para comprobar integridad entre código y base de datos.
