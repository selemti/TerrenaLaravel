<?php
// Script para verificar la estructura de menús y modificadores

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

    // 1. Consultar la información de la empanada (menú item con ID 6)
    echo "\n1. Información del menú item 'Empanada' (ID 6):\n";
    $menuItem = DB::connection('pgsql')->select('SELECT mi.id, mi.name, mi.price, mi.group_id, mg.name as group_name
                                                   FROM public.menu_item mi
                                                   LEFT JOIN public.menu_group mg ON mg.id = mi.group_id
                                                   WHERE mi.id = 6');
    foreach ($menuItem as $item) {
        echo "ID: {$item->id}, Nombre: {$item->name}, Grupo ID: {$item->group_id}, Grupo: {$item->group_name}, Precio: {$item->price}\n";
    }

    // 2. Consultar información del grupo de menú "Antojitos" (ID 1)
    echo "\n2. Información del grupo de menú 'Antojitos' (ID 1):\n";
    $menuGroup = DB::connection('pgsql')->select('SELECT mg.id, mg.name
                                                  FROM public.menu_group mg
                                                  WHERE mg.id = 1');
    foreach ($menuGroup as $group) {
        echo "ID: {$group->id}, Nombre: {$group->name}\n";
    }

    // 3. Consultar información del grupo de modificadores "Relleno Empanada" (ID 3)
    echo "\n3. Información del grupo de modificadores 'Relleno Empanada' (ID 3):\n";
    $modifierGroup = DB::connection('pgsql')->select('SELECT id, name FROM public.menu_modifier_group WHERE id = 3');
    foreach ($modifierGroup as $group) {
        echo "ID: {$group->id}, Nombre: {$group->name}\n";
    }

    // 4. Consultar los modificadores "pollo", "picadillo" y "queso" (IDs 1,2,3) en el grupo "Relleno Empanada"
    echo "\n4. Modificadores con IDs 1, 2, 3:\n";
    $modifiers = DB::connection('pgsql')->select('SELECT id, name, group_id FROM public.menu_modifier WHERE id IN (1, 2, 3)');
    foreach ($modifiers as $mod) {
        echo "ID: {$mod->id}, Nombre: {$mod->name}, Grupo ID: {$mod->group_id}\n";
    }

    // 5. Verificar si hay modificadores asociados a empanadas en tickets
    echo "\n5. Grupos de modificadores asociados con empanadas en tickets (sin filtrar por fecha):\n";
    $ticketItems = DB::connection('pgsql')->select("
        SELECT DISTINCT tim.group_id, mmg.name as group_name
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = tim.group_id
        WHERE ti.item_id = 6  -- Empanada
    ");
    foreach ($ticketItems as $item) {
        echo "Grupo de modificador ID: {$item->group_id}, Nombre: {$item->group_name}\n";
    }

    // 6. Consultar modificadores específicos usados con empanadas (sin filtrar por fecha)
    echo "\n6. Modificadores usados con empanadas (sin filtrar por fecha):\n";
    $allMods = DB::connection('pgsql')->select("
        SELECT tim.modifier_name, tim.group_id, mmg.name as group_name, COUNT(*) as count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = tim.group_id
        WHERE ti.item_id = 6  -- Empanada
        GROUP BY tim.modifier_name, tim.group_id, mmg.name
        ORDER BY count DESC
    ");
    foreach ($allMods as $mod) {
        echo "Modificador: {$mod->modifier_name}, Grupo ID: {$mod->group_id}, Grupo Nombre: {$mod->group_name}, Cantidad: {$mod->count}\n";
    }

    // 7. Busquemos información de tickets de noviembre 2025 para encontrar modificadores de empanadas en ese periodo
    echo "\n7. Modificadores usados con empanadas en noviembre 2025 (buscando en la tabla ticket):\n";
    $novemberMods = DB::connection('pgsql')->select("
        SELECT tim.modifier_name, tim.group_id, mmg.name as group_name, COUNT(*) as count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = tim.group_id
        WHERE ti.item_id = 6  -- Empanada
        AND t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        GROUP BY tim.modifier_name, tim.group_id, mmg.name
        ORDER BY count DESC
    ");
    foreach ($novemberMods as $mod) {
        echo "Modificador: {$mod->modifier_name}, Grupo ID: {$mod->group_id}, Grupo Nombre: {$mod->group_name}, Cantidad: {$mod->count}\n";
    }

    // 8. Consulta adicional: revisar si hay alguna configuración que defina qué grupos de modificadores están asociados a cada ítem de menú
    echo "\n8. Verificar si existe una tabla que defina qué grupos de modificadores están asociados a cada ítem de menú:\n";
    $menuModifierRelations = DB::connection('pgsql')->select("
        SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name = 'menu_item_modifier_group'
        ) AS table_exists;
    ");
    foreach ($menuModifierRelations as $result) {
        echo "Existe tabla de relación menú-modificador: " . ($result->table_exists ? 'Sí' : 'No') . "\n";
    }

} catch (Exception $e) {
    echo "Error al conectar a la base de datos: " . $e->getMessage() . "\n";
}