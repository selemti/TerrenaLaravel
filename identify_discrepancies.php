<?php
// Script para identificar otros casos similares de malas asignaciones de modificadores

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

    // 1. Obtener todas las relaciones teóricas menú-item y grupo-modificador
    echo "\n1. Relaciones teóricas (configuración correcta):\n";
    $theoreticalRelations = DB::connection('pgsql')->select("
        SELECT mim.menuitem_modifiergroup_id as menu_item_id, mi.name as menu_item_name,
               mim.modifier_group as modifier_group_id, mmg.name as modifier_group_name
        FROM public.menuitem_modifiergroup mim
        LEFT JOIN public.menu_item mi ON mi.id = mim.menuitem_modifiergroup_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = mim.modifier_group
        ORDER BY mi.name, mmg.name;
    ");
    
    // Crear un mapa de relaciones teóricas
    $theoreticalMap = [];
    foreach ($theoreticalRelations as $rel) {
        if (!isset($theoreticalMap[$rel->menu_item_id])) {
            $theoreticalMap[$rel->menu_item_id] = [];
        }
        $theoreticalMap[$rel->menu_item_id][] = [
            'group_id' => $rel->modifier_group_id,
            'group_name' => $rel->modifier_group_name
        ];
    }
    
    // 2. Obtener las relaciones reales en los tickets de noviembre 2025
    echo "\n2. Relaciones reales en los tickets de noviembre 2025 (posibles malas asignaciones):\n";
    $realRelations = DB::connection('pgsql')->select("
        SELECT DISTINCT ti.item_id, mi.name as menu_item_name,
               tim.group_id, mmg.name as group_name,
               COUNT(*) as occurrence_count
        FROM public.ticket_item_modifier tim
        JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
        JOIN public.ticket t ON t.id = ti.ticket_id
        LEFT JOIN public.menu_item mi ON mi.id = ti.item_id
        LEFT JOIN public.menu_modifier_group mmg ON mmg.id = tim.group_id
        WHERE t.create_date BETWEEN '2025-11-01' AND '2025-11-30'
        GROUP BY ti.item_id, mi.name, tim.group_id, mmg.name
        ORDER BY ti.item_id, occurrence_count DESC;
    ");
    
    // 3. Comparar relaciones teóricas vs reales para encontrar discrepancias
    echo "\n3. Discrepancias encontradas (menú items con grupos de modificadores no esperados):\n";
    $discrepancies = [];
    foreach ($realRelations as $real) {
        $menuItemId = $real->item_id;
        
        // Verificar si el grupo de modificador real está en las relaciones teóricas
        $expectedGroupIds = [];
        if (isset($theoreticalMap[$menuItemId])) {
            foreach ($theoreticalMap[$menuItemId] as $expected) {
                $expectedGroupIds[] = $expected['group_id'];
            }
        }
        
        // Si el grupo real no está en los esperados, es una discrepancia
        if (!in_array($real->group_id, $expectedGroupIds)) {
            $expectedGroupsStr = $expectedGroupIds ? 
                implode(', ', array_map(function($id) use ($theoreticalMap, $menuItemId) {
                    foreach ($theoreticalMap[$menuItemId] as $expected) {
                        if ($expected['group_id'] == $id) {
                            return $expected['group_name'] . " (ID: $id)";
                        }
                    }
                    return "ID: $id";
                }, $expectedGroupIds)) : "Ninguno";
            
            echo "  - Menú: {$real->menu_item_name} (ID: {$menuItemId})\n";
            echo "    - Grupo real: {$real->group_name} (ID: {$real->group_id}) - ocurrencias: {$real->occurrence_count}\n";
            echo "    - Grupos esperados: $expectedGroupsStr\n";
            echo "\n";
            
            $discrepancies[] = [
                'menu_item_id' => $menuItemId,
                'menu_item_name' => $real->menu_item_name,
                'real_group_id' => $real->group_id,
                'real_group_name' => $real->group_name,
                'expected_group_ids' => $expectedGroupIds,
                'occurrence_count' => $real->occurrence_count
            ];
        }
    }
    
    // 4. Mostrar resumen de discrepancias
    echo "\n4. Resumen de discrepancias:\n";
    echo "   Total de discrepancias encontradas: " . count($discrepancies) . "\n";
    
    if (!empty($discrepancies)) {
        echo "\n   Las discrepancias más comunes:\n";
        // Agrupar por tipo de discrepancia
        $discrepancyTypes = [];
        foreach ($discrepancies as $disc) {
            $type = $disc['menu_item_name'] . " -> " . $disc['real_group_name'];
            if (!isset($discrepancyTypes[$type])) {
                $discrepancyTypes[$type] = [
                    'count' => 0,
                    'total_occurrences' => 0,
                    'examples' => []
                ];
            }
            $discrepancyTypes[$type]['count']++;
            $discrepancyTypes[$type]['total_occurrences'] += $disc['occurrence_count'];
            $discrepancyTypes[$type]['examples'][] = [
                'menu_item_id' => $disc['menu_item_id'],
                'occurrences' => $disc['occurrence_count']
            ];
        }
        
        arsort($discrepancyTypes);
        $count = 0;
        foreach ($discrepancyTypes as $type => $info) {
            echo "   - $type: {$info['count']} menú(s), {$info['total_occurrences']} ocurrencias totales\n";
            if (++$count >= 10) break; // Mostrar solo las 10 primeras
        }
    }

} catch (Exception $e) {
    echo "Error al conectar a la base de datos: " . $e->getMessage() . "\n";
}