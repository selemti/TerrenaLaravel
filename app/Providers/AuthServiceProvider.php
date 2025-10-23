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

        $safe = static function (callable $callback, bool $default = false) {
            return rescue($callback, $default, report: false);
        };

        Gate::before(function ($user, string $ability) use ($safe) {
            if (! $user) {
                return null;
            }

            if ($safe(fn () => method_exists($user, 'hasRole') && $user->hasRole('Super Admin'))) {
                return true;
            }
        });

        // Define gates para los permisos del sistema
        // Estos coinciden con los usados en personal.blade.php

        Gate::define('people.view', function ($user) use ($safe) {
            if (! $user) {
                return false;
            }

            return $safe(fn () => method_exists($user, 'hasPermissionTo') && $user->hasPermissionTo('people.view'));
        });

        Gate::define('people.users.manage', function ($user) use ($safe) {
            if (! $user) {
                return false;
            }

            return $safe(fn () => method_exists($user, 'hasPermissionTo') && $user->hasPermissionTo('people.users.manage'));
        });

        Gate::define('people.roles.manage', function ($user) use ($safe) {
            if (! $user) {
                return false;
            }

            return $safe(fn () => method_exists($user, 'hasPermissionTo') && $user->hasPermissionTo('people.roles.manage'));
        });

        Gate::define('people.permissions.manage', function ($user) use ($safe) {
            if (! $user) {
                return false;
            }

            return $safe(fn () => method_exists($user, 'hasPermissionTo') && $user->hasPermissionTo('people.permissions.manage'));
        });

        Gate::define('inventory.prices.manage', function ($user) use ($safe) {
            if (! $user) {
                return false;
            }

            if ($safe(fn () => method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['Super Admin', 'Ops Manager', 'inventario.manager']))){
                return true;
            }

            return $safe(fn () => method_exists($user, 'hasPermissionTo') && $user->hasPermissionTo('inventory.prices.manage'));
        });

        Gate::define('alerts.view', function ($user) use ($safe) {
            if (! $user) {
                return false;
            }

            if ($safe(fn () => method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['Super Admin', 'Ops Manager', 'inventario.manager', 'viewer', 'purchasing', 'kitchen']))){
                return true;
            }

            return $safe(fn () => method_exists($user, 'hasPermissionTo') && $user->hasPermissionTo('alerts.view'));
        });

        Gate::define('inventory.alerts.manage', function ($user) use ($safe) {
            if (! $user) {
                return false;
            }

            if ($safe(fn () => method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['Super Admin', 'Ops Manager', 'inventario.manager']))){
                return true;
            }

            return $safe(fn () => method_exists($user, 'hasPermissionTo') && $user->hasPermissionTo('alerts.manage'));
        });

        Gate::define('admin.access', function ($user) use ($safe) {
            if (! $user) {
                return false;
            }

            if ($safe(fn () => method_exists($user, 'hasRole') && $user->hasRole('Super Admin'))) {
                return true;
            }

            return $safe(fn () => method_exists($user, 'hasPermissionTo') && $user->hasPermissionTo('admin.access'));
        });
    }
}
