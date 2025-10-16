<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\URL;   // <-- AGREGA ESTA LÍNEA

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // deja aquí lo que ya tienes
    }

    public function boot(): void
    {
        // Fuerza la raíz de generación de URLs para respetar /terrena/ui
        $appUrl = config('app.url'); // ej: http://localhost/terrena/ui
        if ($appUrl) {
            URL::forceRootUrl($appUrl);
        }

        // Si usas HTTPS en prod:
        // URL::forceScheme('https');
    }
}
