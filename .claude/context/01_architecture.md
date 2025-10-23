# Arquitectura Técnica

**Dual database real**
- `config/database.php` arranca en SQLite para entornos locales, pero ambientes Terrena deben usar `DB_CONNECTION=pgsql` y `DB_SCHEMA=selemti,public` para fijar el `search_path`. Modelos sensibles (`App\Models\Inv\Item`, `Caja\SesionCajon`, `Inventory\Batch`) califican tablas `selemti.*` cuando requieren un esquema explícito.
- Estructuras y restricciones actualizadas provienen de `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148-safe.sql`: incluye checks en `items`, `inventory_batch`, `mov_inv`, `sesion_cajon`, `precorte`, `postcorte`, funciones `fn_precorte_*`, vistas `vw_stock_*`, etc. Complementar con `docs/V2/02_Database/schema_{selemti,public}.md` para entender los mapeos.
- Migraciones Laravel solo crean catálogos en `public` (`cat_unidades`, `cat_uom_conversion`, `cat_proveedores`, `inv_stock_policy`). La sincronización con tablas POS queda como tarea explícita en `schema_public.md`.

**Organización del código**
- `app/Models` está particionado por dominio (`Caja`, `Inv`, `Catalogs`, `Rec`, `Pos`). Muchos modelos heredan `Model` sin factories; revisar `fillable/casts` antes de habilitar mass assignment.
- Controladores API residen en `app/Http/Controllers/Api/<Dominio>` y coinciden con los grupos definidos en `routes/api.php` (caja, inventario, unidades, reportes, legacy).
- Servicios: `App\Services\Inventory\ReceptionService` agrupa transacciones multitabla; no hay servicios equivalentes para caja (la lógica vive en controladores con SQL crudo `DB::connection('pgsql')`).
- Frontend: Livewire en `app/Livewire`, blades en `resources/views`, scripts heredados en `public/assets/js` (especialmente `caja/`).

**Patrones y pendientes**
- Validación: se usa `Request::validate` inline (ej. `Api\Caja\AuthController`). No existen Form Requests dedicados; agregar cuando se endurezcan endpoints.
- Respuestas API siguen convenio `{ ok, data?, error?, message? }` documentado en `docs/V2/03_Backend/routes_api.md`; paginación estándar de Laravel en listados de inventario.
- Autenticación: Sanctum activo para login, JWT pendiente. Añadir middleware `auth:sanctum`/`throttle` cuando el flujo esté decidido.
- Scripts `composer.json`: `composer run dev` lanza servidor, colas, `php artisan pail` y `npm run dev`; `composer test` limpia config y ejecuta PHPUnit 11. Documentar cualquier script nuevo en `.claude/agents/laravel_architect.md`.
- Pendientes estructurales: migrar lógica SQL crítica a comandos Artisan versionados, consolidar catálogos `public` ↔︎ `selemti`, y asegurar que vistas/materializaciones v3 se desplieguen junto al código para evitar fallas en endpoints.
