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

        Gate::before(function ($user, string $ability) {
            if ($user && method_exists($user, 'hasRole') && $user->hasRole('Super Admin')) {
                return true;
            }
        });

        // Define gates para los permisos del sistema
        // Estos coinciden con los usados en personal.blade.php

        Gate::define('people.view', function ($user) {
            return $user && $user->can('people.view');
        });

        Gate::define('people.users.manage', function ($user) {
            return $user && $user->can('people.users.manage');
        });

        Gate::define('people.roles.manage', function ($user) {
            return $user && $user->can('people.roles.manage');
        });

        Gate::define('people.permissions.manage', function ($user) {
            return $user && $user->can('people.permissions.manage');
        });

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

        Gate::define('admin.access', function ($user) {
            if (! $user) {
                return false;
            }

            if (method_exists($user, 'hasRole') && $user->hasRole('Super Admin')) {
                return true;
            }

            return method_exists($user, 'hasPermissionTo') && $user->hasPermissionTo('admin.access');
        });
    }
}
