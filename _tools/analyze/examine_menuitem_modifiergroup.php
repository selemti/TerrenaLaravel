<?php
// Script para examinar la relación entre menú items y grupos de modificadores

require_once __DIR__.'/vendor/autoload.php';

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Config;

// Inicializar el entorno de Laravel
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Conectar a la base de datos
try {
    // Verificar conexión
    DB::connection('pgsql')->getPdo();
    echo "Conexión exitosa a la base de datos PostgreSQL\n";

    // 1. Ver la estructura de la tabla menuitem_modifiergroup
    echo "\n1. Detalles de la tabla menuitem_modifiergroup:\n";
    $structure = DB::connection('pgsql')->select("
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'menuitem_modifiergroup'
        ORDER BY ordinal_position;
    ");
    foreach ($structure as $col) {
        echo "  - {$col->column_name}: {$col->data_type}" . ($col->is_nullable === 'YES' ? ' (nullable)' : '') . "\n";
    }

    // 2. Ver si hay una relación directa entre menú item y grupo de modificador
    echo "\n2. Relaciones existentes en menuitem_modifiergroup:\n";
    $relations = DB::connection('pgsql')->select("
        SELECT mim.id, mi.name as menu_item_name, mi.id as menu_item_id, 
               mmg.name as modifier_group_name, mmg.id as modifier_group_id,
               mim.min_quantity, mim.max_quantity
        FROM public.menuitem_modifiergroup mim
        LEFT JOIN public.menu_item mi ON mi.id = mim.menuitem_modifiergroup_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
        ORDER BY mi.name, mmg.name
        LIMIT 20;  -- Limitamos a 20 para ver una muestra
    ");
    
    foreach ($relations as $rel) {
        echo "  - ID: {$rel->id}, Menú: {$rel->menu_item_name} ({$rel->menu_item_id}), Grupo Modificador: {$rel->modifier_group_name} ({$rel->modifier_group_id}), ";
        echo "Min: {$rel->min_quantity}, Max: {$rel->max_quantity}\n";
    }

    // 3. Buscar específicamente si hay relación para la empanada (ID 6)
    echo "\n3. Relaciones específicas para Empanada (ID 6):\n";
    $empanadaRelations = DB::connection('pgsql')->select("
        SELECT mim.id, mi.name as menu_item_name, mi.id as menu_item_id, 
               mmg.name as modifier_group_name, mmg.id as modifier_group_id,
               mim.min_quantity, mim.max_quantity
        FROM public.menuitem_modifiergroup mim
        LEFT JOIN public.menu_item mi ON mi.id = mim.menuitem_modifiergroup_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
        WHERE mi.id = 6
        ORDER BY mmg.name;
    ");
    
    if (empty($empanadaRelations)) {
        echo "  - No se encontraron relaciones definidas para la Empanada (ID 6) en la tabla menuitem_modifiergroup\n";
    } else {
        foreach ($empanadaRelations as $rel) {
            echo "  - ID: {$rel->id}, Menú: {$rel->menu_item_name} ({$rel->menu_item_id}), Grupo Modificador: {$rel->modifier_group_name} ({$rel->modifier_group_id}), ";
            echo "Min: {$rel->min_quantity}, Max: {$rel->max_quantity}\n";
        }
    }

    // 4. Buscar todas las relaciones de "Relleno Empanada" (ID 3)
    echo "\n4. Items de menú que usan el grupo 'Relleno Empanada' (ID 3):\n";
    $rellenoEmpanadaItems = DB::connection('pgsql')->select("
        SELECT mim.id, mi.name as menu_item_name, mi.id as menu_item_id, 
               mmg.name as modifier_group_name, mmg.id as modifier_group_id,
               mim.min_quantity, mim.max_quantity
        FROM public.menuitem_modifiergroup mim
        LEFT JOIN public.menu_item mi ON mi.id = mim.menuitem_modifiergroup_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
        WHERE mmg.id = 3
        ORDER BY mi.name;
    ");
    
    if (empty($rellenoEmpanadaItems)) {
        echo "  - No se encontraron items de menú que usen el grupo 'Relleno Empanada' (ID 3) en la tabla menuitem_modifiergroup\n";
    } else {
        foreach ($rellenoEmpanadaItems as $rel) {
            echo "  - ID: {$rel->id}, Menú: {$rel->menu_item_name} ({$rel->menu_item_id}), Grupo Modificador: {$rel->modifier_group_name} ({$rel->modifier_group_id}), ";
            echo "Min: {$rel->min_quantity}, Max: {$rel->max_quantity}\n";
        }
    }

    // 5. Buscar todas las relaciones de "Salsa Picada" (ID 8)
    echo "\n5. Items de menú que usan el grupo 'Salsa Picada' (ID 8):\n";
    $salsaPicadaItems = DB::connection('pgsql')->select("
        SELECT mim.id, mi.name as menu_item_name, mi.id as menu_item_id, 
               mmg.name as modifier_group_name, mmg.id as modifier_group_id,
               mim.min_quantity, mim.max_quantity
        FROM public.menuitem_modifiergroup mim
        LEFT JOIN public.menu_item mi ON mi.id = mim.menuitem_modifiergroup_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
        WHERE mmg.id = 8
        ORDER BY mi.name;
    ");
    
    if (empty($salsaPicadaItems)) {
        echo "  - No se encontraron items de menú que usen el grupo 'Salsa Picada' (ID 8) en la tabla menuitem_modifiergroup\n";
    } else {
        foreach ($salsaPicadaItems as $rel) {
            echo "  - ID: {$rel->id}, Menú: {$rel->menu_item_name} ({$rel->menu_item_id}), Grupo Modificador: {$rel->modifier_group_name} ({$rel->modifier_group_id}), ";
            echo "Min: {$rel->min_quantity}, Max: {$rel->max_quantity}\n";
        }
    }

    // 6. Buscamos si hay alguna otra tabla que haga la relación entre menú y grupo de modificadores
    echo "\n6. Explorando la tabla menuitem_modifiergroup con más detalle:\n";
    // Revisamos cómo se usa el campo menuitem_modifiergroup_id - podría apuntar a otro registro en la misma tabla
    $nestedRelations = DB::connection('pgsql')->select("
        SELECT mim1.id, mi.name as menu_item_name, mim1.modifier_group, mmg.name as modifier_group_name,
               mim1.menuitem_modifiergroup_id as parent_id, mim2.menuitem_modifiergroup_id as grandparent_id
        FROM public.menuitem_modifiergroup mim1
        LEFT JOIN public.menu_item mi ON mi.id = mim1.menuitem_modifiergroup_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = mim1.modifier_group
        LEFT JOIN public.menuitem_modifiergroup mim2 ON mim2.id = mim1.menuitem_modifiergroup_id
        WHERE mim1.menuitem_modifiergroup_id <= 100  -- Limitar para ver mejor la estructura
        ORDER BY mim1.id
        LIMIT 20;
    ");
    
    foreach ($nestedRelations as $rel) {
        echo "  - ID: {$rel->id}, Menú: {$rel->menu_item_name}, Grupo: {$rel->modifier_group_name} ({$rel->modifier_group}), ";
        echo "Parent ID: {$rel->parent_id}, Grandparent ID: {$rel->grandparent_id}\n";
    }

} catch (Exception $e) {
    echo "Error al conectar a la base de datos: " . $e->getMessage() . "\n";
}