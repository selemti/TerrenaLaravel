<?php
// Script para usar la tabla menuitem_modifiergroup como fuente de verdad para corregir agrupaciones

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

    // 1. Consulta que usa menuitem_modifiergroup como fuente definitiva para corregir agrupaciones
    echo "\n1. Consulta usando menuitem_modifiergroup como fuente de verdad:\n";
    $correctedData = DB::connection('pgsql')->select("
        SELECT 
            ti.item_id,
            mi.name as menu_item_name,
            TRIM(tim.modifier_name) as modifier_name,
            COALESCE(
                (SELECT mim.modifier_group 
                 FROM public.menuitem_modifiergroup mim 
                 WHERE mim.menuitem_modifiergroup_id = ti.item_id 
                 AND EXISTS (
                     SELECT 1 FROM public.menu_modifier mm 
                     WHERE mm.group_id = mim.modifier_group 
                     AND TRIM(mm.name) = TRIM(tim.modifier_name)
                 )
                ), 
                tim.group_id  -- Mantener el grupo original si no se encuentra en la configuración
            ) as corrected_group_id,
            COALESCE(
                (SELECT mmg.name
                 FROM public.menuitem_modifiergroup mim 
                 JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
                 WHERE mim.menuitem_modifiergroup_id = ti.item_id 
                 AND EXISTS (
                     SELECT 1 FROM public.menu_modifier mm 
                     WHERE mm.group_id = mim.modifier_group 
                     AND TRIM(mm.name) = TRIM(tim.modifier_name)
                 )
                ), 
                mmg_orig.name  -- Mantener el nombre original si no se encuentra en la configuración
            ) as corrected_group_name,
            tim.group_id as original_group_id,
            mmg_orig.name as original_group_name,
            COUNT(*) as sales_count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        JOIN public.menu_item mi ON mi.id = ti.item_id
        LEFT JOIN public.menu_modifier_group mmg_orig ON mmg_orig.id = tim.group_id
        WHERE t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        GROUP BY ti.item_id, mi.name, TRIM(tim.modifier_name), tim.group_id, mmg_orig.name
        ORDER BY ti.item_id, sales_count DESC
        LIMIT 50;  -- Limitar para visualización
    ");
    
    echo "ID\tMenú\t\tModificador\tGrupo Corregido\t\t\tNombre Grupo Corregido\t\tGrupo Original\t\tNombre Grupo Original\tVentas\n";
    echo str_repeat("-", 150) . "\n";
    
    foreach ($correctedData as $data) {
        $menuName = strlen($data->menu_item_name) > 10 ? substr($data->menu_item_name, 0, 10)."..." : $data->menu_item_name;
        $modifierName = strlen($data->modifier_name) > 10 ? substr($data->modifier_name, 0, 10)."..." : $data->modifier_name;
        $correctedGroupName = $data->corrected_group_name ? (strlen($data->corrected_group_name) > 20 ? substr($data->corrected_group_name, 0, 20)."..." : $data->corrected_group_name) : "NULL";
        $originalGroupName = $data->original_group_name ? (strlen($data->original_group_name) > 20 ? substr($data->original_group_name, 0, 20)."..." : $data->original_group_name) : "NULL";
        
        echo "{$data->item_id}\t{$menuName}\t\t{$modifierName}\t\t{$data->corrected_group_id}\t\t\t\t{$correctedGroupName}\t\t\t{$data->original_group_id}\t\t\t{$originalGroupName}\t\t{$data->sales_count}\n";
    }

    // 2. Consulta para identificar discrepancias específicas
    echo "\n2. Discrepancias identificadas (grupo corregido diferente al original):\n";
    $discrepancies = DB::connection('pgsql')->select("
        SELECT 
            ti.item_id,
            mi.name as menu_item_name,
            TRIM(tim.modifier_name) as modifier_name,
            tim.group_id as original_group_id,
            mmg_orig.name as original_group_name,
            corrected_mim.modifier_group as corrected_group_id,
            mmg_corr.name as corrected_group_name,
            COUNT(*) as sales_count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        JOIN public.menu_item mi ON mi.id = ti.item_id
        LEFT JOIN public.menu_modifier_group mmg_orig ON mmg_orig.id = tim.group_id
        LEFT JOIN public.menuitem_modifiergroup corrected_mim ON (
            corrected_mim.menuitem_modifiergroup_id = ti.item_id
            AND EXISTS (
                SELECT 1 FROM public.menu_modifier mm 
                WHERE mm.group_id = corrected_mim.modifier_group 
                AND TRIM(mm.name) = TRIM(tim.modifier_name)
            )
        )
        LEFT JOIN public.menu_modifier_group mmg_corr ON mmg_corr.id = corrected_mim.modifier_group
        WHERE t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        AND tim.group_id != corrected_mim.modifier_group
        AND corrected_mim.modifier_group IS NOT NULL
        GROUP BY ti.item_id, mi.name, TRIM(tim.modifier_name), 
                 tim.group_id, mmg_orig.name, corrected_mim.modifier_group, mmg_corr.name
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

    // 3. Consulta específica para el caso de empanadas
    echo "\n3. Caso específico de empanadas (ID 6) con la lógica basada en menuitem_modifiergroup:\n";
    $empanadaData = DB::connection('pgsql')->select("
        SELECT 
            ti.item_id,
            mi.name as menu_item_name,
            TRIM(tim.modifier_name) as modifier_name,
            tim.group_id as original_group_id,
            mmg_orig.name as original_group_name,
            corrected_mim.modifier_group as corrected_group_id,
            mmg_corr.name as corrected_group_name,
            COUNT(*) as sales_count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        JOIN public.menu_item mi ON mi.id = ti.item_id
        LEFT JOIN public.menu_modifier_group mmg_orig ON mmg_orig.id = tim.group_id
        LEFT JOIN public.menuitem_modifiergroup corrected_mim ON (
            corrected_mim.menuitem_modifiergroup_id = ti.item_id
            AND EXISTS (
                SELECT 1 FROM public.menu_modifier mm 
                WHERE mm.group_id = corrected_mim.modifier_group 
                AND TRIM(mm.name) = TRIM(tim.modifier_name)
            )
        )
        LEFT JOIN public.menu_modifier_group mmg_corr ON mmg_corr.id = corrected_mim.modifier_group
        WHERE ti.item_id = 6  -- Empanada
        AND t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        GROUP BY ti.item_id, mi.name, TRIM(tim.modifier_name), 
                 tim.group_id, mmg_orig.name, corrected_mim.modifier_group, mmg_corr.name
        ORDER BY sales_count DESC;
    ");
    
    foreach ($empanadaData as $data) {
        echo "  - Modificador: '{$data->modifier_name}'\n";
        echo "    - Original: Grupo {$data->original_group_id} ('{$data->original_group_name}')\n";
        echo "    - Corregido: Grupo {$data->corrected_group_id} ('{$data->corrected_group_name}')\n";
        echo "    - Ventas: {$data->sales_count}\n\n";
    }

} catch (Exception $e) {
    echo "Error al conectar a la base de datos: " . $e->getMessage() . "\n";
}