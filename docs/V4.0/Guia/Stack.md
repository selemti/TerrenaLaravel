# Stack & Convenciones V4.0

## 1. Propósito y fuentes

Esta guía consolida los lineamientos transversales que cada módulo debe seguir antes de escribir código o documentación. Se alimenta de `AGENTS.md`, `docs/V4.0/Arquitectura/README.md`, `composer.json:8-72`, `package.json:1-27`, y los planos UI (`docs/V4.0/Frontend/{Layout,Componentes}.md`). Cualquier ajuste de stack debe documentarse aquí y en el índice general (`docs/V4.0/README.md`) antes de mergear.

## 2. Visión general del stack

| Capa | Tecnología | Referencia |
|------|------------|------------|
| Backend | Laravel 12 + PHP 8.2 (`composer.json:8-19`) | Código en `app/`, rutas en `routes/{web,api}.php`. |
| UI | Blade + Livewire 3.7 + Alpine.js + Bootstrap 5 + Tailwind tokens (`resources/views`, `package.json:5-25`) | Layouts `resources/views/layouts/{terrena,app,guest}.blade.php`, componentes `<x-ui.*>`. |
| Build tools | Composer 2, Vite 7, Node ≥ 20 (requerido por Vite), npm | Scripts en `composer.json:65-72`, `package.json:5-8`. |
| Datos | PostgreSQL 9.5+ (schema `selemti`), Redis para colas/cache | Credenciales vía `.env`, host `172.24.240.1` desde WSL (local Windows/Mac: `127.0.0.1`). |
| Auth/security | Laravel Sanctum, Spatie Permission (`composer.json:12-18`), JWT para integraciones | Tokens de sesión expuestos a JS vía `window.TerrenaApiToken` (layout Terrena). |

## 3. Tooling y preparación local

1. **Sistema operativo:** se recomienda WSL2 + Ubuntu 22.04 o macOS. En WSL la BD se expone en `172.24.240.1`; en hosts nativos usar `127.0.0.1` (usuario solicitó 121.0.0.1, validar contra `.env` real).
2. **Prerequisitos:** PHP 8.2, Composer 2, Node 20+, npm 10, PostgreSQL client (`psql` o Beekeeper), Redis local para colas.
3. **Bootstrap de proyecto:**
   ```bash
   cp .env.example .env
   composer install
   npm install
   php artisan key:generate
   php artisan migrate --seed   # requerido para caja chica y pedidos (AGENTS.md)
   ```
4. **Ejecución en desarrollo:**  
   - Manual: `php artisan serve` + `npm run dev` + (opcional) `php artisan queue:work`.  
   - Integrado: `composer run dev` lanza servidor, cola (`queue:listen`), logger (`artisan pail`) y Vite simultáneamente (`composer.json:65-68`).
5. **Build de assets:** `npm run build` (Vite).  
6. **Caches/config:** después de cambios en `.env` correr `php artisan config:clear` o `php artisan config:cache`. No edites archivos cacheados manualmente.

## 4. Convenciones de código y Git

- PHP sigue PSR-12, 4 espacios, llaves en la siguiente línea y propiedades tipadas por defecto (`AGENTS.md`). Ejecutar `./vendor/bin/pint` antes de subir cambios.
- Blade: archivos en minúsculas con guiones (`resources/views/caja-chica/index.blade.php`). Cualquier vista nueva debe apuntar al layout correcto (`docs/V4.0/Frontend/Layout.md`).
- Componentes UI: usa `<x-ui.*>` y registra cambios en `docs/V4.0/Frontend/Componentes.md`.
- Livewire y clases: nombres en StudlyCase (`*Controller`, `*Service`, `*Job`). Mantén namespaces consistentes.
- Commits: formato `<type>(<scope>): summary` con `type ∈ {feat, fix, docs, chore}` y menciona ticket cuando aplique (AGENTS.md). Incluye en el PR el checklist de migraciones/seeds y enlaces a docs actualizados.
- Regla de documentación: antes de trabajar un módulo lee los archivos existentes en `docs/V4.0/` y actualízalos en el mismo PR; cualquier fuente legacy se marca como histórica.

## 5. Configuración de ambientes y seguridad

- **Variables de entorno:** nunca publiques `.env`. Replica con `cp .env.example .env` y rellena credenciales locales. Campos críticos: `DB_HOST`, `DB_DATABASE`, `APP_URL`, `FILESYSTEM_DISK`, `QUEUE_CONNECTION`, `SANCTUM_STATEFUL_DOMAINS`.
- **Base de datos:** desde WSL conecta a `172.24.240.1` para reutilizar la instancia de Windows. Si trabajas fuera de WSL, usa el host local configurado (por defecto `127.0.0.1`). Verifica esquema `selemti.*` antes de añadir columnas o vistas.
- **Colas:** setea `QUEUE_CONNECTION=redis` al probar procesos asíncronos (recepciones, alertas). Arranca trabajadores con `php artisan queue:work` o mediante `composer run dev`.
- **Storage:** archivos locales en `storage/app`, públicos en `storage/app/public` (usa `php artisan storage:link`). Para S3-compatible usa variables `AWS_*` y corre `php artisan config:cache` después de cambios.
- **Permisos:** todas las rutas sensibles deben tener `auth:sanctum` + permisos Spatie (`config/permissions.php`). En front usa `window.TerrenaHasPerm` emitido por `layouts/terrena.blade.php` para ocultar acciones.
- **Tokens/API:** el layout Terrena genera tokens de sesión vía `/session/api-token`; cualquier endpoint nuevo debe respetar este flujo y nunca exponer datos sin validar permisos.

## 6. Build, pruebas y QA

- **Pruebas PHP:** `php artisan test` (o `composer test`) limpia la configuración y corre PHPUnit (`phpunit.xml`). Usa `php artisan test --testsuite=Feature --coverage-html storage/coverage` en módulos críticos (AGENTS.md). Tests con BD deben incluir `RefreshDatabase` y sembrar solo lo necesario.
- **Lint/format:** `./vendor/bin/pint` para PHP, `npm run lint` no existe aún; usa ESLint/Tailwind plugins si se incorporan.
- **Seeds y migraciones:** agrupa cambios por dominio en `database/migrations` y `seeders`. Ejecuta `php artisan migrate --seed` luego de rebasar; documenta cualquier SQL externo en `docs/BD/*`.
- **Assets:** `npm run dev` para watch, `npm run build` para empaquetado. No cometas `public/build`; Vite los genera en despliegue.

## 7. Seguridad operativa y políticas

- Mantén `php artisan config:cache`/`config:clear` para propagar cambios de configuración; jamás edites los archivos generados.
- Revisa cada endpoint nuevo contra `docs/V4.0/Arquitectura/README.md` para asegurar que use middleware adecuado y tablas reales.
- Cuando un módulo toque datos sensibles (Caja, POS, compras) valida siempre contra la BD real (host `172.24.240.1`) antes de describir campos en los docs.
- Si necesitas nuevas dependencias, agrega la justificación en el PR y actualiza esta guía si afecta lineamientos globales.

## 8. Checklist previo a merge

- [ ] `composer install` y `npm install` actualizados; sin archivos sin trackear en `vendor/` ni `node_modules/`.
- [ ] `php artisan test` y `npm run build` (si aplica) ejecutados sin errores.
- [ ] `./vendor/bin/pint` corrido y sin diffs posteriores.
- [ ] `.env` no modificado; credenciales documentadas solo en esta guía o instructivos seguros.
- [ ] Documentaste los cambios en la ficha correspondiente (`docs/V4.0/...`) y citaste rutas/controladores/tablas reales.
- [ ] Validaste conexiones a BD usando el host correcto para tu entorno (WSL vs local).
- [ ] Confirmaste que nuevos endpoints usan `auth:sanctum` + permisos Spatie y que el frontend oculta acciones mediante `TerrenaHasPerm`.

Cumpliendo esta guía mantenemos coherencia entre código, documentación y procesos operativos en Terrena V4.0.
