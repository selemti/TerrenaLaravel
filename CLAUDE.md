# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**TerrenaLaravel** is a Laravel 12 restaurant management system (ERP) for a multi-location restaurant business. It integrates with a legacy PostgreSQL database (Floreant POS) while managing inventory, recipes, production, purchasing, and cash register operations.

**Tech Stack:**
- Laravel 12 (PHP 8.2+)
- Livewire 3.7 (beta) for reactive UI components
- Vite + Bootstrap 5 + Alpine.js for frontend (some legacy Tailwind CSS 3)
- PostgreSQL 9.5 for POS/Caja module (legacy Floreant POS integration)
- SQLite for local development
- JWT authentication (tymon/jwt-auth)
- Spatie Laravel Permission for RBAC
- L5-Swagger for API documentation

## Development Commands

### Environment Setup
```bash
# Install dependencies
composer install
npm install

# Environment configuration
cp .env.example .env
php artisan key:generate

# Database setup (SQLite by default)
php artisan migrate
php artisan db:seed
```

### Development Server
```bash
# Start all development services (recommended)
composer dev
# This runs: server + queue worker + pail logs + vite (concurrently)

# Or start individually:
php artisan serve              # Web server
npm run dev                    # Vite dev server
php artisan queue:listen       # Queue worker
php artisan pail               # Real-time logs
```

### Testing
```bash
# Run all tests
composer test
# Or: php artisan test

# Run specific test suite
php artisan test --testsuite=Feature
php artisan test --testsuite=Unit

# Run specific test file
php artisan test tests/Feature/InventoryTest.php

# Run with coverage (if configured)
php artisan test --coverage
```

### Code Quality
```bash
# Format code with Laravel Pint
./vendor/bin/pint

# Specific file/directory
./vendor/bin/pint app/Http/Controllers
```

### Frontend Build
```bash
npm run dev      # Development with HMR
npm run build    # Production build
```

### Database
```bash
# Migrations
php artisan migrate
php artisan migrate:fresh      # Fresh migration (drops all tables)
php artisan migrate:rollback   # Rollback last batch

# Seeding
php artisan db:seed
php artisan db:seed --class=UsersSeeder
```

## Architecture

### Module Organization

The application is organized into domain modules under `app/Models/`:

- **Caja/** - Cash register operations (POS integration)
  - Connects to PostgreSQL (legacy Floreant POS database)
  - Models: `SesionCajon`, `Precorte`, `Postcorte`, `Terminal`, `FormasPago`
  - Handles drawer sessions, pre-closing, post-closing, reconciliation

- **Inv/** - Inventory management
  - Models: `Item`, `Batch`, `MovimientoInventario`, `Unidad`, `ConversionUnidad`
  - Tracks stock levels, lot/batch management, unit conversions
  - Core table: `mov_inv` (kardex/movement log)

- **Rec/** - Recipe management
  - Models: `Receta`, `RecetaDetalle`, `RecetaVersion`, `Modificador`, `OrdenProduccion`
  - Recipe versioning and production order tracking

- **Pos/** - Point of Sale entities
  - Models: `Ticket`, `TicketItem`, `MenuItem`, `MenuCategory`, `Transaccion`
  - POS transactions, menu items, categories

- **Core/** - Cross-cutting concerns
  - Models: `Auditoria`, `SesionCaja`, `PreCorte`, `PostCorte`, `UserRole`, `PerdidaLog`

- **Purchasing/** - Procurement management (NEW - Oct 2025)
  - Models: `PurchaseRequest`, `PurchaseRequestLine`, `VendorQuote`, `VendorQuoteLine`, `PurchaseOrder`, `PurchaseOrderLine`, `PurchaseDocument`
  - Complete procurement workflow from requisition to order
  - Integrates with `PurchasingService` (backend by Codex)
  - UI: 5 Livewire components with Bootstrap 5

- **Catalogs/** - Master data catalogs
  - Unit of measure, warehouses, suppliers, branches, stock policies

- **CashFund/** - Petty cash management (Caja Chica)
  - Models: `CashFund`, `CashFundMovement`, `CashFundSettlement`
  - Complete audit trail with state machine
  - 6 Livewire components with full CRUD

- **InventoryCount/** - Physical inventory counting
  - Models: `InventoryCount`, `InventoryCountLine`
  - Integrates with `InventoryCountService` (backend by Codex)
  - 5 Livewire components for count workflow

### Dual Database Architecture

**SQLite** (default for app models):
- Used for: Inventory, Recipes, Catalogs, Users
- Connection: `database` (default)

**PostgreSQL 9.5** (legacy Floreant POS):
- Used for: Caja module (cash register operations), Purchasing, Inventory operations
- Connection: `pgsql`
- Models explicitly set: `protected $connection = 'pgsql';`
- Schemas:
  - `selemti` - Work schema (freely modifiable, managed by Gemini CLI)
  - `public` - Floreant POS production (READ-ONLY, no modifications without confirmation)

**Important**: When creating models that use PostgreSQL, always specify the connection:
```php
protected $connection = 'pgsql';
protected $table = 'selemti.table_name';  // or just 'table_name' if using selemti schema
```

**Schema Access Rules** (Multi-Agent Coordination):
- `selemti` - Working schema for new features, freely modifiable
- `public` - Legacy POS system in production, requires explicit confirmation for any write operation

### API Structure

**Primary API Routes** (`/api/*`):
- `/api/caja/*` - Cash register operations (precortes, postcortes, sesiones, conciliación)
- `/api/unidades/*` - Units of measure and conversions
- `/api/inventory/*` - Inventory items, stock, vendors, kardex

**Legacy API Routes** (`/api/legacy/*`):
- Maintains backward compatibility with old Slim PHP endpoints
- Supports `.php` extensions in URLs for gradual migration
- Should eventually be deprecated once frontend updates

**Authentication**:
- JWT-based via `/api/auth/login`
- Currently no middleware applied for development (see routes/api.php:33)

### Response Standards

All API responses use `ApiResponseMiddleware` which enforces:
- JSON responses with consistent structure: `{ok: bool, data?: any, error?: string, timestamp: string}`
- CORS headers in local environment
- API versioning header: `X-API-Version: 2.0`
- Standardized error responses (500+ errors return JSON)

Helper available: `CajaHelper::J()` for creating responses (though prefer Laravel's `response()->json()`)

### Frontend Architecture

**Livewire Components** - Primary UI layer:
- Located in: `app/Livewire/`
- Catalogs: `UnidadesIndex`, `AlmacenesIndex`, `ProveedoresIndex`, `StockPolicyIndex`
- Inventory: `ItemsIndex`, `ReceptionsIndex`, `ReceptionCreate`, `LotsIndex`, Count components
- Purchasing: `Requests/Index`, `Requests/Create`, `Requests/Detail`, `Orders/Index`, `Orders/Detail`
- CashFund: `Index`, `Detail`, `Create`, `Movements`, `Settlements`, `Approvals`
- Recipes: `RecipesIndex`, `RecipeEditor`
- KDS: `Board` (Kitchen Display System)

**Blade Views**:
- Main layout: `resources/views/layouts/terrena.blade.php` (Bootstrap 5 with sidebar navigation)
- Legacy layout: `resources/views/layouts/app.blade.php` (Tailwind CSS)
- Static pages: `dashboard.blade.php`, `inventario.blade.php`, `compras.blade.php`, etc.
- Livewire views: `resources/views/livewire/`
- **Design Standard**: Bootstrap 5 for all new components (responsive, cards, modals, badges)

**JavaScript**:
- Minimal custom JS (Alpine.js handles interactivity)
- Entry: `resources/js/app.js`
- Libraries: Alpine.js, Cleave.js (input formatting), Bootstrap 5, Popper.js
- Chart.js for data visualization

### Service Layer Pattern

Services are used for complex business logic. Key services:

**`app/Services/Inventory/ReceptionService.php`**:
- Handles inventory reception transactions
- Creates reception records, batch entries, and kardex movements atomically
- Pattern: `createReception(array $header, array $lines): int`
- Always uses DB transactions for multi-table operations

**`app/Services/Purchasing/PurchasingService.php`** (Codex):
- Manages complete procurement workflow
- Methods: `createRequest()`, `addQuote()`, `createOrderFromQuote()`
- State transitions for requests and orders
- Integrates with inventory system

**`app/Services/Inventory/InventoryCountService.php`** (Codex):
- Physical count workflow management
- Variance calculation and adjustment creation
- Multi-warehouse support

### Unit Conversion System

Central to inventory operations:
- Items have multiple UOMs: base (canonical), purchase, output
- `ConversionUnidad` model stores conversion factors
- `Item` relationships: `uom()`, `uomCompra()`, `uomSalida()`
- Reception quantities normalized to base UOM before recording in kardex

### URL Configuration

**Important**: This app runs in a subdirectory (`/TerrenaLaravel`) under XAMPP.

**Config**: `app/Providers/AppServiceProvider.php` forces root URL from `config('app.url')`:
```php
URL::forceRootUrl($root);
```

**htaccess**: Custom configuration in `public/.htaccess` handles subdirectory routing.

Routes use named routes for URL generation:
```php
route('dashboard')        // Generates: /TerrenaLaravel/dashboard
url('inventory/items')    // Generates: /TerrenaLaravel/inventory/items
```

### Helper Functions

**`app/Helpers/CajaHelper.php`** (auto-loaded via composer.json):
- `qp(Request, string $key, $default)` - Reads from query params OR body (flexible param handling)
- `J(JsonResponse, array $data, int $code)` - JSON response shorthand
- `ver(float $d)` - Variance check for cash reconciliation ('CUADRA', 'A_FAVOR', 'EN_CONTRA')

## Development Guidelines

### Model Conventions
- Use explicit `$table` property (many tables don't follow Laravel naming)
- Use `$guarded = []` or explicit `$fillable` arrays
- Cast numeric fields: `'costo_promedio' => 'decimal:2'`
- Date fields: `'fecha' => 'datetime'`
- Boolean fields: `'activo' => 'boolean'`

### API Controller Pattern
```php
// Return JSON with standardized structure
return response()->json([
    'ok' => true,
    'data' => $result,
    'timestamp' => now()->toIso8601String()
]);

// Errors
return response()->json([
    'ok' => false,
    'error' => 'error_code',
    'message' => 'Human readable message',
    'timestamp' => now()->toIso8601String()
], 400);
```

### Inventory Transactions
When creating inventory movements:
1. Always use DB transactions
2. Record in `mov_inv` table (kardex)
3. Include: `item_id`, `batch_id`, `tipo`, `qty`, `uom`, `ref_tipo`, `ref_id`, `ts`
4. Normalize quantities to base UOM
5. Link to batch/lot for traceability

### Migrations
- Prefix with date: `YYYY_MM_DD_HHMMSS_description`
- Use string IDs where appropriate (many tables use UUIDs or custom IDs)
- Include indexes for foreign keys and frequently queried columns
- Document complex table relationships in migration comments

### Testing
- Feature tests should test full HTTP request/response cycle
- Use `RefreshDatabase` trait for database tests
- Mock external services (POS database queries in tests)
- Test API responses include proper JSON structure

### Permissions
Using Spatie Laravel Permission:
- Roles defined via `UserRole` model
- Assign permissions to roles, not directly to users
- Check with: `$user->hasPermissionTo('edit-items')` or `@can('edit-items')`

## Multi-Agent Coordination

This project uses multiple AI agents for development:

**Claude Code** (this instance):
- Role: UI/UX, Livewire components, Blade views, frontend integration
- Creates complete module UIs with Bootstrap 5
- Integrates with backend services created by Codex
- Documents modules comprehensively
- See: `.claude/` configuration

**Codex** (GitHub Copilot Agent):
- Role: Backend services, business logic, API development
- Creates Service layer classes with complex business logic
- Develops Eloquent models with relationships
- Creates database migrations
- Backend PRs merged from separate branches

**Gemini CLI**:
- Role: Database operations, schema management, bug fixes
- Direct PostgreSQL operations on `selemti` schema
- Fixes database-code inconsistencies
- Optimizes queries and indexes
- See: `.gemini/GEMINI.md` and `.gemini/WORK_ASSIGNMENTS.md`

**Coordination Guidelines**:
1. **Before creating new UI**: Verify backend service and models exist
2. **Database changes**: Coordinate with Gemini via `.gemini/WORK_ASSIGNMENTS.md`
3. **Model creation**: Check if Codex already created models in a PR
4. **Module development flow**: Backend (Codex) → DB validation (Gemini) → UI (Claude)
5. **Schema modifications**: Only `selemti` schema is freely modifiable; `public` requires confirmation

**Reference**: `.gemini/WORK_ASSIGNMENTS.md` tracks ongoing work by each agent

## Common Pitfalls

1. **Forgetting database connection in PostgreSQL models** - Always set `protected $connection = 'pgsql';` for Caja, Purchasing, and Inventory models
2. **Hard-coding URLs** - Use named routes and `url()` helper for subdirectory compatibility
3. **Skipping transactions for multi-table operations** - Use `DB::transaction()` for data integrity
4. **Not normalizing UOM quantities** - Always convert to base UOM when recording in kardex
5. **Mixing query param and body params** - Use `CajaHelper::qp()` for legacy endpoint compatibility
6. **Testing with SQLite when using PostgreSQL models** - Configure test database connections appropriately
7. **Creating UI before validating backend** - Always verify Service layer, models, and database tables exist before creating Livewire components
8. **Wrong layout** - Use `terrena.blade.php` for new Bootstrap 5 components, not `app.blade.php` (Tailwind legacy)
9. **Modifying `public` schema without coordination** - The `public` schema is Floreant POS production; coordinate with team before any modifications
