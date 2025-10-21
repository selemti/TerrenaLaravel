<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\URL;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // aquí lo que ya tengas de bindings/registrations
    }

    public function boot(): void
    {
        // Fuerza la raíz para que route(), url(), asset() respeten /TerrenaLaravel
        if ($root = config('app.url')) {
            URL::forceRootUrl($root);
        }

        // Si en producción usas HTTPS, descomenta:
        // URL::forceScheme('https');

        // Forzar encoding UTF-8 en PostgreSQL
        if (! $this->app->runningInConsole() && config('database.default') === 'pgsql') {
            \DB::statement("SET NAMES 'UTF8'");
        }
    }
}
