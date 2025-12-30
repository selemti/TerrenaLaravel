<?php
// Script para examinar la estructura de tablas de menús y modificadores

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

    // 1. Verificar todas las tablas en el esquema público que contengan menú o modificador
    echo "\n1. Tablas relacionadas con menú y modificadores en el esquema público:\n";
    $tables = DB::connection('pgsql')->select("
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND (table_name ILIKE '%menu%' OR table_name ILIKE '%modif%')
        ORDER BY table_name;
    ");
    foreach ($tables as $table) {
        echo "- {$table->table_name}\n";
    }

    // 2. Revisar la estructura de cada tabla encontrada
    foreach ($tables as $table) {
        echo "\n2. Estructura de la tabla {$table->table_name}:\n";
        $columns = DB::connection('pgsql')->select("
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = ?
            ORDER BY ordinal_position;
        ", [$table->table_name]);
        
        foreach ($columns as $column) {
            echo "  - {$column->column_name}: {$column->data_type}" . ($column->is_nullable === 'YES' ? ' (nullable)' : '') . "\n";
        }
    }

    // 3. Verificar valores en la tabla menu_modifier_group
    echo "\n3. Contenido de la tabla menu_modifier_group:\n";
    $modifierGroups = DB::connection('pgsql')->select("SELECT id, name FROM public.menu_modifier_group ORDER BY id;");
    foreach ($modifierGroups as $group) {
        echo "  - ID: {$group->id}, Nombre: {$group->name}\n";
    }

    // 4. Verificar posibles relaciones entre menú items y grupos de modificadores
    echo "\n4. Explorando posibles relaciones entre menú items y grupos de modificadores:\n";
    
    // Verificar si hay una columna directa en menu_item que relacione con grupos de modificadores
    $menuItemColumns = DB::connection('pgsql')->select("
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'menu_item'
        AND (column_name ILIKE '%modifier%' OR column_name ILIKE '%group%')
    ");
    echo "  Columnas en menu_item relacionadas con modificadores/grupos:\n";
    foreach ($menuItemColumns as $col) {
        echo "    - {$col->column_name}: {$col->data_type}\n";
    }

    // 5. Verificar si hay una tabla de relación muchos a muchos entre menú items y grupos de modificadores
    echo "\n5. Verificando tablas de relación que podrían conectar menu_item con menu_modifier_group:\n";
    $potentialJunctionTables = DB::connection('pgsql')->select("
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND (table_name ILIKE '%menu_item%' AND table_name ILIKE '%modifier%')
        OR (table_name ILIKE '%menu%' AND table_name ILIKE '%modifier%' AND table_name ILIKE '%group%')
    ");
    foreach ($potentialJunctionTables as $table) {
        echo "  - {$table->table_name}\n";
    }

    // 6. Verificar columnas específicas en ticket_item_modifier
    echo "\n6. Estructura de ticket_item_modifier (tabla usada en reportes):\n";
    $ticketItemModifierCols = DB::connection('pgsql')->select("
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'ticket_item_modifier'
        ORDER BY ordinal_position;
    ");
    foreach ($ticketItemModifierCols as $col) {
        echo "  - {$col->column_name}: {$col->data_type}" . ($col->is_nullable === 'YES' ? ' (nullable)' : '') . "\n";
    }

} catch (Exception $e) {
    echo "Error al conectar a la base de datos: " . $e->getMessage() . "\n";
}