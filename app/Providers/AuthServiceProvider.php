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
            // Logica real: verificar rol/permisos desde BD
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

        // Puedes agregar mas gates segun necesites:
        // Gate::define('inventory.view', fn($user) => /* logica */);
        // Gate::define('inventory.move', fn($user) => /* logica */);
        // Gate::define('purchasing.view', fn($user) => /* logica */);
        // Gate::define('cashcuts.view', fn($user) => /* logica */);

        Gate::define('inventory.prices.manage', function ($user) {
            if (! $user) {
                return false;
            }

            if ($user->hasAnyRole(['Super Admin', 'Ops Manager', 'inventario.manager'])) {
                return true;
            }

            return $user->can('inventory.prices.manage');
        });

        Gate::define('alerts.view', function ($user) {
            if (! $user) {
                return false;
            }

            if ($user->hasAnyRole(['Super Admin', 'Ops Manager', 'inventario.manager', 'viewer', 'purchasing', 'kitchen'])) {
                return true;
            }

            return $user->can('alerts.view');
        });

        Gate::define('inventory.alerts.manage', function ($user) {
            if (! $user) {
                return false;
            }

            if ($user->hasAnyRole(['Super Admin', 'Ops Manager', 'inventario.manager'])) {
                return true;
            }

            return $user->can('alerts.manage');
        });
    }
}
