<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class PermissionsSeeder extends Seeder
{
    public function run(): void
    {
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        $permissions = [
            'inventory.view',
            'inventory.items.manage',
            'inventory.prices.manage',
            'inventory.receivings.manage',
            'inventory.counts.manage',
            'inventory.moves.manage',
            'inventory.lots.view',
            'recipes.view',
            'recipes.manage',
            'recipes.costs.view',
            'recipes.production.manage',
            'production.manage',
            'purchasing.view',
            'purchasing.manage',
            'menu.engineering.view',
            'menu.engineering.manage',
            'reports.view',
            'reports.manage',
            'alerts.view',
            'alerts.manage',
            'alerts.assign',
            'vendors.view',
            'vendors.manage',
            'pos.sync.manage',
            'cashfund.view',
            'cashfund.manage',
            'people.view',
            'people.users.manage',
            'people.roles.manage',
            'people.permissions.manage',
            'admin.access',
        ];

        foreach ($permissions as $name) {
            Permission::firstOrCreate([
                'name' => $name,
                'guard_name' => 'web',
            ]);
        }

        $roles = [
            'Super Admin' => ['*'],
            'Ops Manager' => [
                'inventory.view',
                'inventory.items.manage',
                'inventory.prices.manage',
                'inventory.receivings.manage',
                'inventory.counts.manage',
                'inventory.moves.manage',
                'inventory.lots.view',
                'recipes.view',
                'recipes.manage',
                'recipes.costs.view',
                'recipes.production.manage',
                'production.manage',
                'purchasing.view',
                'purchasing.manage',
                'menu.engineering.view',
                'menu.engineering.manage',
                'reports.view',
                'reports.manage',
                'alerts.view',
                'alerts.manage',
                'alerts.assign',
                'vendors.view',
                'vendors.manage',
                'pos.sync.manage',
                'cashfund.view',
                'cashfund.manage',
                'people.view',
                'people.users.manage',
                'people.roles.manage',
            ],
            'inventario.manager' => [
                'inventory.view',
                'inventory.items.manage',
                'inventory.prices.manage',
                'inventory.receivings.manage',
                'inventory.counts.manage',
                'inventory.moves.manage',
                'inventory.lots.view',
                'recipes.view',
                'recipes.costs.view',
                'recipes.production.manage',
                'production.manage',
                'reports.view',
                'alerts.view',
                'alerts.manage',
                'vendors.view',
                'people.view',
            ],
            'purchasing' => [
                'inventory.view',
                'inventory.receivings.manage',
                'inventory.prices.manage',
                'purchasing.view',
                'purchasing.manage',
                'vendors.view',
                'vendors.manage',
                'people.view',
            ],
            'kitchen' => [
                'inventory.view',
                'inventory.lots.view',
                'recipes.view',
                'recipes.manage',
                'recipes.costs.view',
                'recipes.production.manage',
                'production.manage',
                'alerts.view',
                'people.view',
            ],
            'cashier' => [
                'inventory.view',
                'inventory.lots.view',
                'reports.view',
                'cashfund.view',
                'people.view',
            ],
            'viewer' => [
                'inventory.view',
                'inventory.lots.view',
                'recipes.view',
                'reports.view',
                'alerts.view',
                'vendors.view',
                'people.view',
            ],
        ];

        foreach ($roles as $roleName => $rolePermissions) {
            $role = Role::firstOrCreate([
                'name' => $roleName,
                'guard_name' => 'web',
            ]);

            if (in_array('*', $rolePermissions, true)) {
                $role->syncPermissions(Permission::all());
            } else {
                $role->syncPermissions($rolePermissions);
            }
        }
    }
}

