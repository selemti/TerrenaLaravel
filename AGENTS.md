# Repository Guidelines

## Project Structure & Module Organization
Core Laravel code lives in `app/` (HTTP controllers, models, jobs) and is wired through `routes/web.php` for UI traffic and `routes/api.php` for programmatic clients. Blade layouts, Alpine/Bootstrap widgets, and Tailwind styles live under `resources/views` and `resources/js|css`, compiled by Vite into `public/build`. Reusable docs (flows, onboarding) are under `docs/` and root-level `.txt` briefs—review them before picking up a feature. Database assets (`database/migrations`, `seeders`, `factories`) define the domain schema; keep feature-specific SQL changes together.

## Build, Test, and Development Commands
- `composer install && npm install` — fresh dependency sync.
- `php artisan serve` — boots the API/UI backend at `http://127.0.0.1:8000`.
- `npm run dev` — runs Vite in watch mode; pairs well with `php artisan serve` via two terminals or `concurrently`.
- `php artisan migrate --seed` — migrates and seeds local data required by caja chica and pedidos flows.
- `npm run build` — generates optimized assets for staging/prod deploys.

## Coding Style & Naming Conventions
Follow PSR-12 (4-space indentation, brace-on-next-line) for PHP, and prefer typed properties/methods on new classes. Blade templates should use lowercase, dash-separated filenames (`resources/views/caja-chica/index.blade.php`). Controllers, events, and jobs follow Laravel’s StudlyCase suffixes (`*Controller`, `*Event`). Vue is not in use—stick to Alpine components and Bootstrap utility classes. Run `./vendor/bin/pint` before committing PHP changes.

## Testing Guidelines
PHPUnit is configured via `phpunit.xml`; keep Feature specs in `tests/Feature` and focused units in `tests/Unit`. Name tests after the scenario (`CajaChicaAuthorizationTest.php`) and mirror namespaces. Run `php artisan test` locally; use `php artisan test --testsuite=Feature --coverage-html storage/coverage` when validating critical modules. When tests hit the database, include `RefreshDatabase` and seed only what the scenario needs.

## Commit & Pull Request Guidelines
Recent history mixes Spanish context with Conventional Commit prefixes (e.g., `feat(replenishment): …`). Keep that pattern: `<type>(<scope>): summary`, where `type` ∈ {feat, fix, docs, chore}. Commits should be scoped to a single concern and reference Jira/Terrena ticket IDs in the body if applicable. Pull requests need: concise summary, checklist of migrations/seeds affected, screenshots or screencasts for UI shifts, and links to any updated docs under `docs/` or the knowledge base.

## Environment & Security Tips
Never commit `.env`; duplicate `cp .env.example .env` and fill credentials for DB, mail, and S3-compatible storage. Queue workers default to Redis—set `QUEUE_CONNECTION=redis` when testing async flows. For sensitive configs (API tokens, fiscal data loaders), use Laravel’s `php artisan config:cache`/`config:clear` commands rather than editing cached PHP files.
