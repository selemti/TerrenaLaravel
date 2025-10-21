<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\Route;
use Livewire\Livewire;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // aquí lo que ya tengas de bindings/registrations
    }

    public function boot(): void
    {
        // Ajustar conexión PG para entorno remoto (asegura configuración incluso con config cache)
        config([
            'database.connections.pgsql.host' => env('DB_HOST', '172.24.240.1'),
            'database.connections.pgsql.port' => env('DB_PORT', '5433'),
            'database.connections.pgsql.database' => env('DB_DATABASE', 'pos'),
            'database.connections.pgsql.username' => env('DB_USERNAME', 'postgres'),
            'database.connections.pgsql.password' => env('DB_PASSWORD', 'T3rr3n4#p0s'),
            'database.connections.pgsql.search_path' => env('DB_SCHEMA', 'selemti,public'),
        ]);

        // Fuerza la raíz para que route(), url(), asset() respeten /TerrenaLaravel
        if ($root = config('app.url')) {
            URL::forceRootUrl($root);
        }

        // Configurar Livewire para subdirectorio
        $basePath = parse_url(config('app.url'), PHP_URL_PATH);
        if ($basePath && $basePath !== '/') {
            $prefix = rtrim($basePath, '/');

            // Configurar rutas de Livewire con prefijo de subdirectorio
            Livewire::setUpdateRoute(function ($handle) use ($prefix) {
                return Route::post($prefix . '/livewire/update', $handle);
            });

            Livewire::setScriptRoute(function ($handle) use ($prefix) {
                return Route::get($prefix . '/livewire/livewire.js', $handle);
            });
        }

        // Configurar Livewire para que use el APP_URL completo
        config(['livewire.asset_url' => config('app.url')]);

        // Si en producción usas HTTPS, descomenta:
        // URL::forceScheme('https');

        // Forzar encoding UTF-8 en PostgreSQL
        if (! $this->app->runningInConsole() && config('database.default') === 'pgsql') {
            \DB::statement("SET NAMES 'UTF8'");
        }
    }
}
