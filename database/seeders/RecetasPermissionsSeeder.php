<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Guard;

/**
 * Seeder for Recetas module permissions.
 *
 * @version 2.1
 * @author Gemini
 */
class RecetasPermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $permissions = [
            'can_reprocess_sales',
            'can_view_recipe_dashboard',
            'can_edit_production_order',
        ];

        foreach ($permissions as $permission) {
            Permission::findOrCreate($permission, 'web');
        }
    }
}
