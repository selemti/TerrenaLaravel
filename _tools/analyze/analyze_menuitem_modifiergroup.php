<?php
// Script para analizar la estructura real de la tabla menuitem_modifiergroup

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

    // 1. Ver la estructura de menuitem_modifiergroup
    echo "\n1. Estructura de la tabla menuitem_modifiergroup:\n";
    $structure = DB::connection('pgsql')->select("
        SELECT id, menuitem_modifiergroup_id, modifier_group, min_quantity, max_quantity, sort_order
        FROM public.menuitem_modifiergroup
        ORDER BY menuitem_modifiergroup_id
        LIMIT 30;  -- Limitamos para visualización
    ");
    
    echo "ID\tItem ID\tGrupo Mod\tMin\tMax\tOrden\n";
    echo str_repeat("-", 50) . "\n";
    
    foreach ($structure as $row) {
        echo "{$row->id}\t{$row->menuitem_modifiergroup_id}\t{$row->modifier_group}\t{$row->min_quantity}\t{$row->max_quantity}\t{$row->sort_order}\n";
    }

    // 2. Verificar la relación entre ítem de menú y grupo de modificadores
    echo "\n2. Relación entre ítems de menú y grupos de modificadores:\n";
    $relations = DB::connection('pgsql')->select("
        SELECT mim.id, mim.menuitem_modifiergroup_id as item_id, mi.name as item_name,
               mim.modifier_group as group_id, mmg.name as group_name
        FROM public.menuitem_modifiergroup mim
        JOIN public.menu_item mi ON mi.id = mim.menuitem_modifiergroup_id
        JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
        ORDER BY mi.name, mmg.name
        LIMIT 50;  -- Limitamos para visualización
    ");
    
    echo "Relación ID\tItem ID\tItem Nombre\t\tGrupo ID\tGrupo Nombre\n";
    echo str_repeat("-", 80) . "\n";
    
    foreach ($relations as $rel) {
        $itemName = strlen($rel->item_name) > 15 ? substr($rel->item_name, 0, 15)."..." : $rel->item_name;
        echo "{$rel->id}\t\t{$rel->item_id}\t{$itemName}\t\t{$rel->group_id}\t\t{$rel->group_name}\n";
    }

    // 3. Verificar modificadores específicos para empanadas
    echo "\n3. Modificadores permitidos para empanadas (ID 6):\n";
    $empanadaModifiers = DB::connection('pgsql')->select("
        SELECT mim.id, mi.name as item_name, mmg.name as group_name, mm.name as modifier_name
        FROM public.menuitem_modifiergroup mim
        JOIN public.menu_item mi ON mi.id = mim.menuitem_modifiergroup_id
        JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
        JOIN public.menu_modifier mm ON mm.group_id = mmg.id
        WHERE mim.menuitem_modifiergroup_id = 6  -- Empanada
        ORDER BY mmg.name, mm.name;
    ");
    
    foreach ($empanadaModifiers as $mod) {
        echo "  - Item: {$mod->item_name}, Grupo: {$mod->group_name}, Modificador: {$mod->modifier_name}\n";
    }

    // 4. Verificar modificadores permitidos para taco de guisado
    echo "\n4. Modificadores permitidos para taco de guisado (ID 7):\n";
    $tacoModifiers = DB::connection('pgsql')->select("
        SELECT mim.id, mi.name as item_name, mmg.name as group_name, mm.name as modifier_name
        FROM public.menuitem_modifiergroup mim
        JOIN public.menu_item mi ON mi.id = mim.menuitem_modifiergroup_id
        JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
        JOIN public.menu_modifier mm ON mm.group_id = mmg.id
        WHERE mim.menuitem_modifiergroup_id = 7  -- Taco de Guisado
        ORDER BY mmg.name, mm.name;
    ");
    
    foreach ($tacoModifiers as $mod) {
        echo "  - Item: {$mod->item_name}, Grupo: {$mod->group_name}, Modificador: {$mod->modifier_name}\n";
    }

    // 5. Consulta más precisa para entender la lógica
    echo "\n5. Análisis detallado de la discrepancia en tickets vs configuración:\n";
    $detailedAnalysis = DB::connection('pgsql')->select("
        WITH modifier_item_mapping AS (
            SELECT DISTINCT
                mim.menuitem_modifiergroup_id as item_id,
                TRIM(mm.name) as modifier_name,
                mmg.id as correct_group_id,
                mmg.name as correct_group_name
            FROM public.menuitem_modifiergroup mim
            JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
            JOIN public.menu_modifier mm ON mm.group_id = mmg.id
        )
        SELECT 
            ti.item_id,
            mi.name as menu_item_name,
            TRIM(tim.modifier_name) as modifier_name,
            tim.group_id as original_group_id,
            mmg_orig.name as original_group_name,
            mim.correct_group_id,
            mim.correct_group_name,
            COUNT(*) as sales_count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        JOIN public.menu_item mi ON mi.id = ti.item_id
        LEFT JOIN public.menu_modifier_group mmg_orig ON mmg_orig.id = tim.group_id
        JOIN modifier_item_mapping mim ON (
            mim.item_id = ti.item_id 
            AND mim.modifier_name = TRIM(tim.modifier_name)
        )
        WHERE t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        AND ti.item_id IN (6, 7)  -- Solo empanadas y taco de guisado para análisis
        GROUP BY ti.item_id, mi.name, TRIM(tim.modifier_name), 
                 tim.group_id, mmg_orig.name,
                 mim.correct_group_id, mim.correct_group_name
        ORDER BY ti.item_id, sales_count DESC;
    ");
    
    foreach ($detailedAnalysis as $analysis) {
        echo "  - Item: {$analysis->menu_item_name} ({$analysis->item_id})\n";
        echo "    - Modificador: '{$analysis->modifier_name}'\n";
        echo "    - Grupo en ticket: {$analysis->original_group_id} ('{$analysis->original_group_name}')\n";
        echo "    - Grupo correcto: {$analysis->correct_group_id} ('{$analysis->correct_group_name}')\n";
        echo "    - Ventas: {$analysis->sales_count}\n";
        echo "\n";
    }

} catch (Exception $e) {
    echo "Error al conectar a la base de datos: " . $e->getMessage() . "\n";
}