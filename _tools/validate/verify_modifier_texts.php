<?php
// Script para verificar si los textos de los modificadores en los tickets están correctos

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

    // 1. Verificar los modificadores específicos para empanadas en tickets
    echo "\n1. Detalle de modificadores para empanadas (ID 6) en tickets de noviembre 2025:\n";
    $empanadaModifiers = DB::connection('pgsql')->select("
        SELECT 
            tim.modifier_name,
            TRIM(tim.modifier_name) as trimmed_name,
            LENGTH(tim.modifier_name) as name_length,
            tim.group_id,
            mmg.name as group_name,
            COUNT(*) as count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = tim.group_id
        WHERE ti.item_id = 6  -- Empanada
        AND t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        GROUP BY tim.modifier_name, tim.group_id, mmg.name
        ORDER BY tim.modifier_name;
    ");
    
    foreach ($empanadaModifiers as $mod) {
        echo "  - Nombre original: '{$mod->modifier_name}' (longitud: {$mod->name_length})\n";
        echo "    - Nombre recortado: '{$mod->trimmed_name}'\n";
        echo "    - Grupo ID: {$mod->group_id} ({$mod->group_name})\n";
        echo "    - Cantidad: {$mod->count}\n";
        echo "\n";
    }

    // 2. Comparar con los modificadores en la tabla de catálogo
    echo "\n2. Modificadores en catálogo para el grupo 'Relleno Empanada' (ID 3):\n";
    $catalogModifiers = DB::connection('pgsql')->select("
        SELECT id, name, group_id
        FROM public.menu_modifier
        WHERE group_id = 3  -- Relleno Empanada
        ORDER BY name;
    ");
    
    foreach ($catalogModifiers as $mod) {
        echo "  - ID: {$mod->id}, Nombre: '{$mod->name}', Grupo ID: {$mod->group_id}\n";
    }

    // 3. Comparar con los modificadores en la tabla de catálogo para el grupo 'Salsa Picada' (ID 8)
    echo "\n3. Modificadores en catálogo para el grupo 'Salsa Picada' (ID 8):\n";
    $catalogModifiersSalsa = DB::connection('pgsql')->select("
        SELECT id, name, group_id
        FROM public.menu_modifier
        WHERE group_id = 8  -- Salsa Picada
        ORDER BY name;
    ");
    
    foreach ($catalogModifiersSalsa as $mod) {
        echo "  - ID: {$mod->id}, Nombre: '{$mod->name}', Grupo ID: {$mod->group_id}\n";
    }

    // 4. Verificar si hay modificadores en tickets que no coinciden exactamente con los del catálogo
    echo "\n4. Comparación entre modificadores en tickets y en catálogo (fuzzy matching):\n";
    $modComparison = DB::connection('pgsql')->select("
        SELECT 
            tim.modifier_name as ticket_modifier,
            TRIM(tim.modifier_name) as trimmed_ticket_modifier,
            mm.name as catalog_modifier,
            tim.group_id as ticket_group_id,
            mmg.name as ticket_group_name,
            mm.group_id as catalog_group_id,
            mmg2.name as catalog_group_name,
            COUNT(*) as count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        LEFT JOIN public.menu_modifier mm ON TRIM(tim.modifier_name) = TRIM(mm.name)
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = tim.group_id
        LEFT JOIN public.menu_modifier_group mmg2 ON mmg2.id = mm.group_id
        WHERE ti.item_id = 6  -- Empanada
        AND t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        GROUP BY tim.modifier_name, TRIM(tim.modifier_name), mm.name, 
                 tim.group_id, mmg.name, mm.group_id, mmg2.name
        ORDER BY tim.modifier_name;
    ");
    
    foreach ($modComparison as $comp) {
        echo "  - Modificador en ticket: '{$comp->ticket_modifier}'\n";
        echo "    - Recortado: '{$comp->trimmed_ticket_modifier}'\n";
        echo "    - Coincide con catálogo: " . ($comp->catalog_modifier ? "'{$comp->catalog_modifier}'" : "NO") . "\n";
        if ($comp->catalog_modifier) {
            echo "    - Grupo en ticket: {$comp->ticket_group_id} ({$comp->ticket_group_name})\n";
            echo "    - Grupo en catálogo: {$comp->catalog_group_id} ({$comp->catalog_group_name})\n";
        }
        echo "    - Cantidad: {$comp->count}\n";
        echo "\n";
    }

} catch (Exception $e) {
    echo "Error al conectar a la base de datos: " . $e->getMessage() . "\n";
}