<?php

namespace App\Providers;

use App\Events\Inventory\ReceptionPosted;
use App\Events\Inventory\TransferPosted;
use App\Events\Pos\PosTicketIngested;
use App\Listeners\Inventory\InvalidateStockCache;
use App\Listeners\Inventory\LogReceptionPosted;
use App\Listeners\Inventory\LogTransferPosted;
use App\Listeners\Pos\LogPosTicketIngested;
use App\Support\Permissions\NullPermissionRegistrar;
use Illuminate\Cache\CacheManager;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;
use Livewire\Livewire;
use Spatie\Permission\PermissionRegistrar;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        if ($this->app->runningUnitTests()) {
            $this->app->extend(PermissionRegistrar::class, function ($service, $app) {
                return new NullPermissionRegistrar($app->make(CacheManager::class));
            });
        }
    }

    public function boot(): void
    {
        Event::listen(ReceptionPosted::class, LogReceptionPosted::class);
        Event::listen(ReceptionPosted::class, InvalidateStockCache::class);
        Event::listen(TransferPosted::class, LogTransferPosted::class);
        Event::listen(TransferPosted::class, InvalidateStockCache::class);
        Event::listen(PosTicketIngested::class, LogPosTicketIngested::class);

        require_once app_path('Support/features.php');

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
                return Route::post($prefix.'/livewire/update', $handle);
            });

            Livewire::setScriptRoute(function ($handle) use ($prefix) {
                return Route::get($prefix.'/livewire/livewire.js', $handle);
            });
        }

        // Si en producción usas HTTPS, descomenta:
        // URL::forceScheme('https');

        // Forzar encoding UTF-8 en PostgreSQL
        if (config('database.default') === 'pgsql') {
            rescue(fn () => DB::connection('pgsql')->statement('SET search_path TO selemti,public'), report: false);

            if (! $this->app->runningInConsole()) {
                rescue(fn () => DB::connection('pgsql')->statement("SET NAMES 'UTF8'"), report: false);
            }
        }
    }
}
