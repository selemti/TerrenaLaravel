# API Workflow · Estándares

**Topología de rutas**
- Todas las rutas viven en `routes/api.php` y se agrupan por prefijo: `/reports`, `/auth`, `/caja`, `/unidades`, `/inventory`, `/catalogs`, más `/legacy` para compatibilidad Slim.
- Controladores siguen el patrón `App\Http\Controllers\Api\<Dominio>\*Controller`; cada grupo coincide con la estructura de carpetas.

**Formato de respuesta**
- Convención `{ ok: bool, data?, error?, message?, timestamp? }` documentada en `docs/V2/03_Backend/routes_api.md`. Listados usan paginación estándar (`current_page`, `data`, `total`).
- Errores se devuelven con códigos HTTP apropiados (400 para validaciones, 401 login, 404 recursos). Añadir `timestamp` donde falte para trazabilidad.

**Autenticación y seguridad**
- `POST /api/auth/login` llama a `Api\Caja\AuthController@login`, valida credenciales y emite tokens Sanctum (`createToken('pos-token')`). JWT (`tymon/jwt-auth`) está instalado pero aún no se integra; definir estrategia antes de publicar.
- No hay middleware aplicado aún (`Route::middleware('auth:sanctum')` pendiente). Antes de producción, proteger `/api/caja/*`, `/api/inventory/*`, `/api/catalogs/*`, y configurar rate limiting (`throttle:60,1`).
- `loginHelp` responde 405 con hint. `logout` existe pero requiere proteger rutas con Sanctum para que funcione.

**Dominios principales**
- **Caja**: rutas `precortes`, `postcortes`, `conciliacion`, `sesiones`, `cajas`, `formas-pago`. Dependen de tablas/vistas v3 (`sesion_cajon`, `precorte`, `postcorte`, `vw_conciliacion_sesion`); si falta algún objeto del deploy v3, las respuestas regresan 500.
- **Inventario**: `StockController` (kpis, stock, movimientos), `ItemController`, `VendorController`. Vistas `vw_stock_actual`, `vw_stock_valorizado`, `vw_stock_brechas` deben existir (ver `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148-safe.sql`).
- **Unidades**: CRUD sobre `public.cat_unidades` y `public.cat_uom_conversion`; conversión Legacy vs Terrena documentada en `docs/V2/02_Database/schema_public.md`.
- **Reportes**: endpoints declarados pero muchos dependen de materializaciones pendientes; mantener bandera experimental.
- **Legacy**: `/api/legacy/*` mantiene URLs `.php` para clientes antiguos; comparten la misma lógica que los controladores modernos.

**Buenas prácticas**
- Añadir pruebas de contrato cuando se cierren endpoints críticos; aprovechar `darkaonline/l5-swagger` para publicar especificaciones.
- Registrar cualquier cambio de payload en `.claude/context` y actualizar `docs/V2/03_Backend/routes_api.md`.
- Validar parámetros con `Request::validate` (actualmente faltan en varios métodos de inventario); considerar Form Requests.
