<?php
// Script para validar la configuración actual de la empanada

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

    // 1. Configuración teórica de la empanada
    echo "\n1. Configuración teórica de la empanada (tabla menuitem_modifiergroup):\n";
    $theoreticalConfig = DB::connection('pgsql')->select("
        SELECT mim.id, mi.name as menu_item_name, mi.id as menu_item_id, 
               mmg.name as modifier_group_name, mmg.id as modifier_group_id,
               mim.min_quantity, mim.max_quantity
        FROM public.menuitem_modifiergroup mim
        LEFT JOIN public.menu_item mi ON mi.id = mim.menuitem_modifiergroup_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
        WHERE mi.id = 6
        ORDER BY mmg.name;
    ");
    
    foreach ($theoreticalConfig as $config) {
        echo "  - Menú: {$config->menu_item_name} ({$config->menu_item_id}), Grupo Modificador: {$config->modifier_group_name} ({$config->modifier_group_id}), ";
        echo "Min: {$config->min_quantity}, Max: {$config->max_quantity}\n";
    }

    // 2. Configuración real en los tickets de noviembre 2025
    echo "\n2. Configuración real en los tickets de noviembre 2025:\n";
    $realConfig = DB::connection('pgsql')->select("
        SELECT DISTINCT tim.group_id, mmg.name as group_name
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = tim.group_id
        WHERE ti.item_id = 6  -- Empanada
        AND t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        ORDER BY mmg.name;
    ");
    
    foreach ($realConfig as $config) {
        echo "  - Grupo Modificador ID: {$config->group_id}, Nombre: {$config->group_name}\n";
    }

    // 3. Análisis detallado de los modificadores usados con empanadas en noviembre 2025
    echo "\n3. Análisis detallado de modificadores usados con empanadas en noviembre 2025:\n";
    $detailedAnalysis = DB::connection('pgsql')->select("
        SELECT tim.modifier_name, tim.group_id, mmg.name as group_name, COUNT(*) as count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = tim.group_id
        WHERE ti.item_id = 6  -- Empanada
        AND t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        GROUP BY tim.modifier_name, tim.group_id, mmg.name
        ORDER BY count DESC;
    ");
    
    foreach ($detailedAnalysis as $analysis) {
        echo "  - Modificador: {$analysis->modifier_name}, Grupo ID: {$analysis->group_id}, Grupo Nombre: {$analysis->group_name}, Cantidad: {$analysis->count}\n";
    }

    // 4. Buscar si los modificadores que aparecen en los tickets están en los grupos correctos
    echo "\n4. Verificar si los modificadores que aparecen en tickets pertenecen al grupo correcto:\n";
    $modifierCheck = DB::connection('pgsql')->select("
        SELECT DISTINCT tim.modifier_name, mm.name as actual_modifier_name, 
               mm.group_id as actual_group_id, mmg.name as actual_group_name,
               tim.group_id as ticket_group_id, tim_group.name as ticket_group_name
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        LEFT JOIN public.menu_modifier mm ON mm.name = TRIM(tim.modifier_name)
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = mm.group_id
        LEFT JOIN public.menu_modifier_group tim_group ON tim_group.id = tim.group_id
        WHERE ti.item_id = 6  -- Empanada
        AND t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        ORDER BY tim.modifier_name;
    ");
    
    foreach ($modifierCheck as $check) {
        echo "  - Modificador en ticket: '{$check->modifier_name}'\n";
        echo "    - Nombre en catálogo: '{$check->actual_modifier_name}'\n";
        echo "    - Grupo en catálogo: ID {$check->actual_group_id} ({$check->actual_group_name})\n";
        echo "    - Grupo en ticket: ID {$check->ticket_group_id} ({$check->ticket_group_name})\n";
        echo "\n";
    }

    // 5. Verificar si hay alguna inconsististencia en la configuración del POS
    echo "\n5. Verificar inconsistencias potenciales:\n";
    $inconsistencies = DB::connection('pgsql')->select("
        SELECT 'Grupo Relleno Empanada' as expected_group, 'Salsa Picada' as actual_group, count(*) as occurrences
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        WHERE ti.item_id = 6  -- Empanada
        AND tim.group_id = 8  -- Salsa Picada
        AND t.create_date BETWEEN '2025-11-01' AND '2025-11-30';
    ");
    
    foreach ($inconsistencies as $inconsistency) {
        echo "  - Se esperaba grupo '{$inconsistency->expected_group}' pero se encontraron {$inconsistency->occurrences} ocurrencias del grupo '{$inconsistency->actual_group}' en los tickets\n";
    }

} catch (Exception $e) {
    echo "Error al conectar a la base de datos: " . $e->getMessage() . "\n";
}