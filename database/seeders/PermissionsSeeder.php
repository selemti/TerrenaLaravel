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
            'recipes.view',
            'recipes.manage',
            'recipes.costs.view',
            'production.manage',
            'reports.view',
            'alerts.view',
            'alerts.manage',
            'vendors.view',
            'vendors.manage',
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
                'recipes.view',
                'recipes.manage',
                'recipes.costs.view',
                'production.manage',
                'reports.view',
                'alerts.view',
                'alerts.manage',
                'vendors.view',
                'vendors.manage',
            ],
            'inventario.manager' => [
                'inventory.view',
                'inventory.items.manage',
                'inventory.prices.manage',
                'inventory.receivings.manage',
                'inventory.counts.manage',
                'inventory.moves.manage',
                'reports.view',
                'alerts.view',
                'alerts.manage',
                'vendors.view',
            ],
            'purchasing' => [
                'inventory.view',
                'inventory.receivings.manage',
                'inventory.prices.manage',
                'vendors.view',
                'vendors.manage',
            ],
            'kitchen' => [
                'inventory.view',
                'recipes.view',
                'recipes.manage',
                'recipes.costs.view',
                'production.manage',
                'alerts.view',
            ],
            'cashier' => [
                'inventory.view',
                'reports.view',
            ],
            'viewer' => [
                'inventory.view',
                'recipes.view',
                'reports.view',
                'alerts.view',
                'vendors.view',
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

