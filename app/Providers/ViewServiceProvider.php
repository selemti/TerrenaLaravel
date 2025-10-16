<?php

namespace App\Providers;

use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class ViewServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        View::composer('*', function ($view) {
            $routeName = optional(request()->route())->getName();

            $menuMap = [
                'dashboard' => 'dashboard',
                'caja.cortes' => 'cortes',

                'inventario' => 'inventario',
                'compras' => 'compras',

                'rec.index' => 'recetas',
                'rec.editor' => 'recetas',
                'recetas' => 'recetas',

                'produccion' => 'produccion',
                'reportes' => 'reportes',
                'admin' => 'config',
                'personal' => 'personal',

                'inventory.items.index' => 'inventario',
                'inv.receptions' => 'inventario',
                'inv.lots' => 'inventario',
            ];

            $view->with('active', $menuMap[$routeName] ?? '');
        });
    }
}
