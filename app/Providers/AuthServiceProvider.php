<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AuthServiceProvider extends ServiceProvider
{
    /**
     * The model to policy mappings for the application.
     *
     * @var array<class-string, class-string>
     */
    protected $policies = [
        // 'App\Models\Model' => 'App\Policies\ModelPolicy',
    ];

    /**
     * Register any authentication / authorization services.
     */
    public function boot(): void
    {
        $this->registerPolicies();

        // Define gates para los permisos del sistema
        // Estos coinciden con los usados en personal.blade.php
        
        Gate::define('people.employees.manage', function ($user) {
            // LÃ³gica real: verificar rol/permisos desde BD
            // Por ahora retornamos true para desarrollo
            return $user && in_array($user->role ?? '', ['admin', 'gerente']);
        });

        Gate::define('people.roles.manage', function ($user) {
            return $user && in_array($user->role ?? '', ['admin', 'gerente']);
        });

        Gate::define('people.permissions.manage', function ($user) {
            return $user && ($user->role ?? '') === 'admin';
        });

        Gate::define('people.schedules.manage', function ($user) {
            return $user && in_array($user->role ?? '', ['admin', 'gerente']);
        });

        Gate::define('people.audit.view', function ($user) {
            return $user && in_array($user->role ?? '', ['admin', 'gerente']);
        });

        // Puedes agregar mÃ¡s gates segÃºn necesites:
        // Gate::define('inventory.view', fn($user) => /* lÃ³gica */);
        // Gate::define('inventory.move', fn($user) => /* lÃ³gica */);
        // Gate::define('purchasing.view', fn($user) => /* lÃ³gica */);
        // Gate::define('cashcuts.view', fn($user) => /* lÃ³gica */);
    }
}
