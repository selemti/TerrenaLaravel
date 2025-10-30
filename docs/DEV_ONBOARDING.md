# GEMINI.md - Project Terrena Analysis

## 1. Project Overview

**TerrenaUI** is a comprehensive inventory and resource management system built with **Laravel 12** and **Livewire 3**. It's designed to run on a Windows/XAMPP environment with a **PostgreSQL 9.5** database.

The application's primary purpose is to manage inventory, recipes, purchasing, and petty cash ("Caja Chica") for a business, likely in the food and beverage or retail sector. The UI is built with a focus on dynamic, real-time components using Livewire, styled with **TailwindCSS** and **Bootstrap 5**.

### Key Technologies:
- **Backend:** Laravel 12, PHP 8.2
- **Frontend:** Livewire 3, Alpine.js, TailwindCSS, Bootstrap 5, Vite
- **Database:** PostgreSQL 9.5
- **Authentication:** Laravel Breeze, Spatie/laravel-permission for roles/permissions.
- **API:** Evidence of JWT-Auth for potential API services.

### Architecture:
The project follows a standard Laravel structure. Business logic is organized into Livewire components (`app/Livewire`), Eloquent models, and potentially service classes. The database is split into two main schemas:
- `selemti`: The primary workspace for application data.
- `public`: Used for critical production data and should be treated as read-only during development.

A multi-agent development workflow is in place, with responsibilities split between different AI agents (Claude for UI, Codex for Backend, Gemini for DB/ops), coordinated via the `.gemini/WORK_ASSIGNMENTS.md` file.

## 2. Building and Running

### Environment Setup
1.  **Copy Environment File:** If `.env` does not exist, copy it from `.env.example`:
    ```bash
    copy .env.example .env
    ```
2.  **Database Credentials:** Ensure the `.env` file has the correct database credentials for your local PostgreSQL 9.5 instance. The current settings are:
    ```ini
    DB_CONNECTION=pgsql
    DB_HOST=127.0.0.1
    DB_PORT=5433
    DB_DATABASE=pos
    DB_USERNAME=postgres
    DB_PASSWORD="T3rr3n4#p0s"
    DB_SCHEMA=selemti,public
    ```
3.  **Install Dependencies:**
    ```bash
    composer install
    npm install
    ```
4.  **Generate App Key:**
    ```bash
    php artisan key:generate
    ```
5.  **Run Migrations:** To set up the database schema.
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

## 3. Development Conventions

### Database
- **Primary Schema:** All development and application-specific tables reside in the `selemti` schema. This schema can be freely modified.
- **Critical Schema:** The `public` schema is for production-critical data and must NOT be modified without explicit authorization. Only `SELECT` operations are permitted.
- **PostgreSQL 9.5 Compatibility:** All migrations and SQL queries must be compatible with PostgreSQL 9.5. Avoid using modern syntax not supported by this version.
- **Destructive Operations:** Always seek confirmation before running `DROP`, `TRUNCATE`, or deleting critical data, even within the `selemti` schema.

### Code and Workflow
- **Agent Coordination:** All development work is coordinated through `.gemini/WORK_ASSIGNMENTS.md`. Check this file before starting any task to avoid conflicts.
- **Branching & Commits:**
    - Use feature branches for new modules.
    - Commit messages should be in Spanish technical language.
- **Routing:** Routes are defined in `routes/web.php` and heavily utilize Livewire page components.
- **Permissions:** Authorization is handled by `spatie/laravel-permission`. Use the `can:` middleware in routes and `@can` directives in Blade views.
- **Localization:** The application is configured for Spanish (`es`) as the primary locale.

### Key File Locations
- **Livewire Components:** `app/Livewire/`
- **Routes:** `routes/web.php`
- **Database Migrations:** `database/migrations/`
- **Frontend Assets:** `resources/css/`, `resources/js/`
- **Views:** `resources/views/`
- **Configuration:** `config/`
