# Terrena Laravel - Project Documentation

## Project Overview

TerrenaUI (also known as Project Terrena) is a comprehensive inventory and resource management system built with **Laravel 12** and **Livewire 3**. It's designed to run on a Windows/XAMPP environment with a **PostgreSQL 9.5** database.

The application's primary purpose is to manage inventory, recipes, purchasing, and petty cash ("Caja Chica") for a business, likely in the food and beverage or retail sector. The UI is built with a focus on dynamic, real-time components using Livewire, styled with **TailwindCSS** and **Bootstrap 5**.

### Key Technologies:
- **Backend:** Laravel 12, PHP 8.2
- **Frontend:** Livewire 3, Alpine.js, TailwindCSS, Bootstrap 5, Vite
- **Database:** PostgreSQL 9.5
- **Authentication:** Laravel Breeze, Spatie/laravel-permission for roles/permissions
- **API:** JWT-Auth for API services and Laravel Sanctum for session tokens
- **API Documentation:** L5-Swagger for API documentation
- **File Uploads:** Cleave.js for form formatting

### Architecture:
The project follows a standard Laravel structure. Business logic is organized into Livewire components (`app/Livewire`), Eloquent models, and potentially service classes. The database is split into two main schemas:
- `selemti`: The primary workspace for application data
- `public`: Used for critical production data and should be treated as read-only during development

## Key Features

### 1. Petty Cash Management (Caja Chica)
- Complete lifecycle management from fund opening to closure
- Multiple movement types (EGRESO, REINTEGRO, DEPOSITO)
- Physical cash counting (arqueo) with difference tracking
- Approval workflow for movements without receipts
- File attachments for receipts and documentation

### 2. Inventory Management
- Item management and categorization
- Receiving and stock tracking
- Lot management and traceability
- Inventory alerts and notifications
- Counting processes with capture and review workflows

### 3. Recipe Management
- Dynamic recipe creation and editing
- Ingredient management with yield calculations
- Recipe visualization and editing interface

### 4. Purchasing Module
- Purchase request management
- Purchase order processing
- Replenishment dashboard for suggested orders
- Supplier management

### 5. Transfers
- Internal warehouse transfer management
- Dispatch and receive workflows

### 6. Catalog Management
- Units of measure and conversions
- Warehouses (almacenes)
- Suppliers (proveedores)
- Branches (sucursales)
- Stock policy management

### 7. Production & KDS
- Kitchen Display System (KDS) for production tracking

## Database Structure

The application uses a PostgreSQL 9.5 database with specific schema requirements:
- Primary schema: `selemti` - for application-specific tables that can be modified
- Critical schema: `public` - for production-critical data, read-only during development

### Key Database Tables (selemti schema):
- `cash_funds` - Petty cash fund records
- `cash_fund_movements` - Petty cash movement records
- `cash_fund_arqueos` - Petty cash counting records
- `inventory_items` - Inventory items
- `inventory_receptions` - Goods receiving records
- `recipes` - Recipe definitions
- `users` - User accounts with permission system

## Building and Running

### Environment Setup
1. **Copy Environment File:** If `.env` does not exist, copy it from `.env.example`:
   ```bash
   copy .env.example .env
   ```
2. **Database Credentials:** Ensure the `.env` file has the correct database credentials for your local PostgreSQL 9.5 instance. The current settings are:
   ```ini
   DB_CONNECTION=pgsql
   DB_HOST=127.0.0.1
   DB_PORT=5433
   DB_DATABASE=pos
   DB_USERNAME=postgres
   DB_PASSWORD="T3rr3n4#p0s"
   DB_SCHEMA=selemti,public
   ```
3. **Install Dependencies:**
   ```bash
   composer install
   npm install
   ```
4. **Generate App Key:**
   ```bash
   php artisan key:generate
   ```
5. **Run Migrations:** To set up the database schema.
   ```bash
   php artisan migrate
   ```

### Running the Application
The project includes a concurrent script to run all necessary development processes.

- **Run Development Servers:**
  ```bash
  composer run dev
  ```
  This command, found in `composer.json`, simultaneously starts:
  - The PHP development server (`php artisan serve`)
  - The queue worker (`php artisan queue:listen`)
  - The log watcher (`php artisan pail`)
  - The Vite frontend server (`npm run dev`)

### Running Tests
The project uses PHPUnit for testing.

- **Run Test Suite:**
  ```bash
  php artisan test
  ```

## Development Conventions

### Database
- **Primary Schema:** All development and application-specific tables reside in the `selemti` schema. This schema can be freely modified.
- **Critical Schema:** The `public` schema is for production-critical data and must NOT be modified without explicit authorization. Only `SELECT` operations are permitted.
- **PostgreSQL 9.5 Compatibility:** All migrations and SQL queries must be compatible with PostgreSQL 9.5. Avoid using modern syntax not supported by this version.
- **Destructive Operations:** Always seek confirmation before running `DROP`, `TRUNCATE`, or deleting critical data, even within the `selemti` schema.

### Code and Workflow
- **Agent Coordination:** All development work is coordinated through `.gemini/WORK_ASSIGNMENTS.md`. Check this file before starting any task to avoid conflicts.
- **Branching & Commits:**
    - Use feature branches for new modules
    - Commit messages should be in Spanish technical language
- **Routing:** Routes are defined in `routes/web.php` and heavily utilize Livewire page components
- **Permissions:** Authorization is handled by `spatie/laravel-permission`. Use the `can:` middleware in routes and `@can` directives in Blade views
- **Localization:** The application is configured for Spanish (`es`) as the primary locale
- **Timezone:** The application uses Mexico City timezone (`America/Mexico_City`)

### Key File Locations
- **Livewire Components:** `app/Livewire/`
- **Routes:** `routes/web.php`
- **Database Migrations:** `database/migrations/`
- **Frontend Assets:** `resources/css/`, `resources/js/`
- **Views:** `resources/views/`
- **Configuration:** `config/`
- **API Controllers:** `app/Http/Controllers/Api/`
- **Models:** `app/Models/` (with specific caja models in `app/Models/Caja/`)
- **API Caja Controllers:** `app/Http/Controllers/Api/Caja/`

### API Endpoints
- Swagger documentation available (darkaonline/l5-swagger)
- Session API tokens via `/session/api-token` endpoints
- Caja API endpoints under `/api/caja/`

### Helper Functions
- Custom helpers available in `app/Helpers/CajaHelper.php`

## Key Modules Structure

### Caja Chica (Petty Cash)
- Components in `app/Livewire/CashFund/`
- Models in `app/Models/CashFund.php`, `app/Models/CashFundMovement.php`, `app/Models/CashFundArqueo.php`
- Database tables: `cash_funds`, `cash_fund_movements`, `cash_fund_arqueos`

### Inventory Management
- Components in `app/Livewire/Inventory/` and `app/Livewire/InventoryCount/`
- Models in `app/Models/Inventory/`

### Purchasing
- Components in `app/Livewire/Purchasing/`
- Models in `app/Models/Purchasing/`

### Recipes
- Components in `app/Livewire/Recipes/`
- Models in `app/Models/Recipes/`

### Transfers
- Components in `app/Livewire/Transfers/`
- Models in `app/Models/Transfers/`

### Catalogs
- Components in `app/Livewire/Catalogs/`
- Models in `app/Models/Catalogs/`

## Project-Specific Notes

- The application was created by `artisan` command and is configured for Windows/XAMPP environment
- The project includes custom development workflow documentation in `DEV_ONBOARDING.md`
- The system is designed with a multi-agent AI development approach (Claude for UI, Codex for Backend, Gemini for DB/ops)
- The application has specific lifecycle documentation for the caja chica module in `CAJA_CHICA_LIFECYCLE.md`
- Several feature-specific documentation files exist (FASE2_ARQUEO_DETALLADO.md, FASE3_APROBACIONES.md, MEJORAS_CAJA_CHICA.md, PERMISOS_CAJA_CHICA.md, VERIFICACION_IMPLEMENTACION.md)
- Frontend build process uses Vite with Tailwind CSS and Bootstrap

## Development Commands

- `composer run dev` - Run all development servers concurrently
- `php artisan test` - Run PHP tests
- `php artisan migrate` - Run database migrations
- `php artisan serve` - Start the development server
- `npm run dev` - Start the Vite development server
- `npm run build` - Build production assets
- `php artisan key:generate` - Generate new application key
- `php artisan config:clear` - Clear configuration cache
- `php artisan route:clear` - Clear route cache
- `php artisan cache:clear` - Clear application cache

## Important Files

- `composer.json` - PHP dependencies and scripts
- `package.json` - Node.js dependencies and scripts
- `routes/web.php` - Main web routes
- `routes/api.php` - API routes
- `config/app.php` - Application configuration
- `config/database.php` - Database configuration
- `config/permission.php` - Permission configuration
- `.env` - Environment configuration
- `app/Providers/AppServiceProvider.php` - Service provider
- `app/Models/` - Eloquent models
- `app/Livewire/` - Livewire components