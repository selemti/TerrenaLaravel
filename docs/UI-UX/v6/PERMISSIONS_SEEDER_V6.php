<?php

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PermissionsSeederV6 extends Seeder
{
    public function run()
    {
        $perms = [
            'inventory.items.view',
            'inventory.items.manage',
            'inventory.uoms.view',
            'inventory.uoms.manage',
            'inventory.uoms.convert.manage',
            'inventory.receptions.view',
            'inventory.receptions.post',
            'inventory.counts.view',
            'inventory.counts.open',
            'inventory.counts.close',
            'inventory.moves.view',
            'inventory.moves.adjust',
            'inventory.snapshot.generate',
            'inventory.snapshot.view',
            'purchasing.suggested.view',
            'purchasing.orders.manage',
            'purchasing.orders.approve',
            'recipes.view',
            'recipes.manage',
            'recipes.costs.recalc.schedule',
            'recipes.costs.snapshot',
            'pos.map.view',
            'pos.map.manage',
            'pos.audit.run',
            'pos.reprocess.run',
            'production.orders.view',
            'production.orders.close',
            'cashier.preclose.run',
            'cashier.close.run',
            'reports.kpis.view',
            'reports.audit.view',
            'system.users.view',
            'system.templates.manage',
            'system.permissions.direct.manage',
        ];

        foreach ($perms as $clave) {
            $exists = DB::table('selemti.permissions')->where('clave', $clave)->exists();
            if (!$exists) {
                DB::table('selemti.permissions')->insert(['clave' => $clave]);
            }
        }

        $plantillas = [
            'Almacenista' => [
                'inventory.items.view',
                'inventory.counts.view',
                'inventory.counts.open',
                'inventory.counts.close',
                'inventory.moves.view',
                'inventory.snapshot.view',
            ],
            'Jefe de Almacén' => [
                'inventory.items.view',
                'inventory.counts.view',
                'inventory.counts.open',
                'inventory.counts.close',
                'inventory.moves.view',
                'inventory.moves.adjust',
                'inventory.receptions.view',
                'inventory.receptions.post',
                'pos.map.view',
            ],
            'Compras' => [
                'purchasing.suggested.view',
                'purchasing.orders.manage',
                'purchasing.orders.approve',
                'inventory.receptions.view',
            ],
            'Costos / Recetas' => [
                'recipes.view',
                'recipes.manage',
                'recipes.costs.recalc.schedule',
                'recipes.costs.snapshot',
                'pos.map.manage',
            ],
            'Producción' => [
                'production.orders.view',
                'production.orders.close',
                'inventory.items.view',
            ],
            'Auditoría / Reportes' => [
                'reports.kpis.view',
                'reports.audit.view',
                'pos.audit.run',
                'inventory.snapshot.view',
            ],
            'Administrador del Sistema' => ['*'],
        ];

        foreach ($plantillas as $nombre => $permsPlantilla) {
            $tpl = DB::table('selemti.plantillas')->where('nombre', $nombre)->first();
            if (!$tpl) {
                DB::table('selemti.plantillas')->insert(['nombre' => $nombre]);
                $tpl = DB::table('selemti.plantillas')->where('nombre', $nombre)->first();
            }

            if ($permsPlantilla === ['*']) {
                $permIds = DB::table('selemti.permissions')->pluck('id')->all();
            } else {
                $permIds = DB::table('selemti.permissions')->whereIn('clave', $permsPlantilla)->pluck('id')->all();
            }

            foreach ($permIds as $pid) {
                $exists = DB::table('selemti.plantilla_permission')
                    ->where('plantilla_id', $tpl->id)
                    ->where('permiso_id', $pid)
                    ->exists();
                if (!$exists) {
                    DB::table('selemti.plantilla_permission')->insert([
                        'plantilla_id' => $tpl->id,
                        'permiso_id' => $pid,
                    ]);
                }
            }
        }
    }
}
