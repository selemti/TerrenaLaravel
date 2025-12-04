<?php
// Script corregido para usar la tabla menuitem_modifiergroup como fuente de verdad para corregir agrupaciones

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

    // 1. Consulta usando una CTE para relacionar adecuadamente los modificadores con los ítems
    echo "\n1. Consulta usando menuitem_modifiergroup como fuente de verdad:\n";
    $correctedData = DB::connection('pgsql')->select("
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
            COALESCE(mim.correct_group_id, tim.group_id) as corrected_group_id,
            COALESCE(mim.correct_group_name, mmg_orig.name) as corrected_group_name,
            tim.group_id as original_group_id,
            mmg_orig.name as original_group_name,
            COUNT(*) as sales_count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        JOIN public.menu_item mi ON mi.id = ti.item_id
        LEFT JOIN public.menu_modifier_group mmg_orig ON mmg_orig.id = tim.group_id
        LEFT JOIN modifier_item_mapping mim ON (
            mim.item_id = ti.item_id 
            AND mim.modifier_name = TRIM(tim.modifier_name)
        )
        WHERE t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        GROUP BY ti.item_id, mi.name, TRIM(tim.modifier_name), 
                 mim.correct_group_id, mim.correct_group_name,
                 tim.group_id, mmg_orig.name
        ORDER BY ti.item_id, sales_count DESC
        LIMIT 50;  -- Limitar para visualización
    ");
    
    echo "ID\tMenú\t\tModificador\tGrupo Corregido\tNombre Grupo Corregido\tGrupo Original\tNombre Grupo Original\tVentas\n";
    echo str_repeat("-", 120) . "\n";
    
    foreach ($correctedData as $data) {
        $menuName = strlen($data->menu_item_name) > 10 ? substr($data->menu_item_name, 0, 10)."..." : $data->menu_item_name;
        $modifierName = strlen($data->modifier_name) > 10 ? substr($data->modifier_name, 0, 10)."..." : $data->modifier_name;
        $correctedGroupName = $data->corrected_group_name ? (strlen($data->corrected_group_name) > 15 ? substr($data->corrected_group_name, 0, 15)."..." : $data->corrected_group_name) : "NULL";
        $originalGroupName = $data->original_group_name ? (strlen($data->original_group_name) > 15 ? substr($data->original_group_name, 0, 15)."..." : $data->original_group_name) : "NULL";
        
        echo "{$data->item_id}\t{$menuName}\t\t{$modifierName}\t\t{$data->corrected_group_id}\t\t{$correctedGroupName}\t\t{$data->original_group_id}\t\t{$originalGroupName}\t\t{$data->sales_count}\n";
    }

    // 2. Consulta específica para empanadas para verificar la corrección
    echo "\n2. Caso específico de empanadas (ID 6) con la lógica basada en menuitem_modifiergroup:\n";
    $empanadaData = DB::connection('pgsql')->select("
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
            COALESCE(mim.correct_group_id, tim.group_id) as corrected_group_id,
            COALESCE(mim.correct_group_name, mmg_orig.name) as corrected_group_name,
            COUNT(*) as sales_count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        JOIN public.menu_item mi ON mi.id = ti.item_id
        LEFT JOIN public.menu_modifier_group mmg_orig ON mmg_orig.id = tim.group_id
        LEFT JOIN modifier_item_mapping mim ON (
            mim.item_id = ti.item_id 
            AND mim.modifier_name = TRIM(tim.modifier_name)
        )
        WHERE ti.item_id = 6  -- Empanada
        AND t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        GROUP BY ti.item_id, mi.name, TRIM(tim.modifier_name), 
                 tim.group_id, mmg_orig.name,
                 mim.correct_group_id, mim.correct_group_name
        ORDER BY sales_count DESC;
    ");
    
    foreach ($empanadaData as $data) {
        echo "  - Modificador: '{$data->modifier_name}'\n";
        echo "    - Original: Grupo {$data->original_group_id} ('{$data->original_group_name}')\n";
        echo "    - Corregido: Grupo {$data->corrected_group_id} ('{$data->corrected_group_name}')\n";
        echo "    - Ventas: {$data->sales_count}\n\n";
    }

    // 3. Consulta para identificar discrepancias específicas
    echo "\n3. Discrepancias identificadas (grupo corregido diferente al original):\n";
    $discrepancies = DB::connection('pgsql')->select("
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
            mim.correct_group_id as corrected_group_id,
            mim.correct_group_name as corrected_group_name,
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
        AND tim.group_id != mim.correct_group_id
        GROUP BY ti.item_id, mi.name, TRIM(tim.modifier_name), 
                 tim.group_id, mmg_orig.name,
                 mim.correct_group_id, mim.correct_group_name
        ORDER BY sales_count DESC;
    ");
    
    echo "Menú\t\tModificador\tGrupo Orig.\tNombre Orig.\tGrupo Corr.\tNombre Corr.\tVentas\n";
    echo str_repeat("-", 100) . "\n";
    
    foreach ($discrepancies as $disc) {
        $menuName = strlen($disc->menu_item_name) > 10 ? substr($disc->menu_item_name, 0, 10)."..." : $disc->menu_item_name;
        $modifierName = strlen($disc->modifier_name) > 10 ? substr($disc->modifier_name, 0, 10)."..." : $disc->modifier_name;
        $origGroupName = $disc->original_group_name ? (strlen($disc->original_group_name) > 15 ? substr($disc->original_group_name, 0, 15)."..." : $disc->original_group_name) : "NULL";
        $corrGroupName = $disc->corrected_group_name ? (strlen($disc->corrected_group_name) > 15 ? substr($disc->corrected_group_name, 0, 15)."..." : $disc->corrected_group_name) : "NULL";
        
        echo "{$menuName}\t\t{$modifierName}\t\t{$disc->original_group_id}\t\t{$origGroupName}\t\t{$disc->corrected_group_id}\t\t{$corrGroupName}\t\t{$disc->sales_count}\n";
    }

} catch (Exception $e) {
    echo "Error al conectar a la base de datos: " . $e->getMessage() . "\n";
}