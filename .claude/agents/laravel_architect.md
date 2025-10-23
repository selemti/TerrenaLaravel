# Guía Rápida · Arquitecto Laravel

**Stack verificado**
- Laravel 12 sobre PHP 8.2, Livewire 3.7.0-beta.1, Tailwind + Bootstrap vía Vite.
- Autenticación híbrida: Sanctum activo en `Api\Caja\AuthController`, `tymon/jwt-auth` instalado para futura migración.
- Bases de datos: PostgreSQL 9.5+ con esquemas `selemti` (legacy) + `public` (catálogos Terrena) y SQLite local (`.env.example`).

**Arquitectura dual**
- `config/database.php` fija `search_path` desde `DB_SCHEMA` (usar `selemti,public` en ambientes reales). Modelos críticos (`App\Models\Inv\Item`, `Caja\SesionCajon`, etc.) referencian tablas totalmente calificadas cuando necesitan un esquema fijo.
- Estructuras v3 confirmadas en `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148-safe.sql` (tablas `sesion_cajon`, `precorte`, `items`, `mov_inv`, `inventory_batch`). Complementar con `docs/V2/02_Database/schema_public.md` y `schema_selemti.md` para mapeos `public` ↔︎ `selemti`.
- Mantén sincronizados los catálogos duplicados (`cat_*`, `conversiones_unidad`, `stock_policy`) ejecutando scripts de `BD/patches/` antes de habilitar módulos.

**Organización clave**
- Modelos divididos por dominio en `app/Models/{Caja,Inv,Catalogs,Rec}`; controladores REST bajo `app/Http/Controllers/Api/*` reflejan `routes/api.php`.
- Servicios críticos: `App\Services\Inventory\ReceptionService` (recepciones + lotes), controladores de caja con SQL legada (`DB::selectOne` sobre `selemti`).
- Assets Livewire en `resources/views` y `app/Livewire`; scripts POS heredados en `public/assets/js`.

**Comandos imprescindibles**
1. `composer install && npm install`
2. `cp .env.example .env && php artisan key:generate`
3. Configura PostgreSQL en `.env` (`DB_CONNECTION=pgsql`, `DB_SCHEMA=selemti,public`, credenciales reales)
4. `php artisan migrate --graceful` (usa `--force` en despliegue)
5. `composer run dev` (serve + queue + logs + Vite) o `php artisan serve` + `npm run dev`
6. `composer test` (limpia config y ejecuta PHPUnit 11)

**Alertas operativas**
- Validar que objetos v3 estén presentes (funciones `fn_precorte_*`, vistas `vw_stock_*`, índices nuevos) antes de correr controladores.
- Documentar cualquier ajuste estructural en `.claude/context` y `docs/V2` para mantener la documentación modular alineada con código y base de datos actuales.
