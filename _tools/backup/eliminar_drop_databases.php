<?php
// Script para encontrar y reemplazar comandos DROP DATABASE en archivos SQL

$search_dir = 'C:\xampp3\htdocs\TerrenaLaravel';

echo "Buscando archivos con DROP DATABASE...\n";

// Función para buscar archivos SQL recursivamente
function findSQLFiles($dir) {
    $files = [];
    $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir));
    
    foreach ($iterator as $file) {
        if ($file->getExtension() === 'sql' && $file->isFile()) {
            $files[] = $file->getPathname();
        }
    }
    
    return $files;
}

// Encontrar todos los archivos SQL
$sql_files = findSQLFiles($search_dir);

$dropped_db_found = 0;

foreach ($sql_files as $file) {
    $content = file_get_contents($file);
    
    // Buscar el patrón DROP DATABASE
    if (preg_match_all('/DROP\s+DATABASE\s+pos;/i', $content, $matches)) {
        echo "Encontrado DROP DATABASE en: $file\n";
        $dropped_db_found += count($matches[0]);
        
        // Reemplazar DROP DATABASE con un comentario
        $new_content = preg_replace('/DROP\s+DATABASE\s+pos;/i', '-- DROP DATABASE pos; -- COMENTADO POR SEGURIDAD', $content);
        
        // Guardar el archivo modificado
        file_put_contents($file, $new_content);
        echo "  -> Reemplazado y archivo modificado\n";
    }
    
    // También buscar otros comandos potencialmente destructivos
    if (preg_match_all('/DROP\s+SCHEMA\s+(IF\s+EXISTS\s+)?public/i', $content, $matches)) {
        echo "Encontrado DROP SCHEMA public en: $file\n";
        $new_content = preg_replace('/DROP\s+SCHEMA\s+(IF\s+EXISTS\s+)?public/i', '-- DROP SCHEMA public; -- COMENTADO POR SEGURIDAD', $content);
        file_put_contents($file, $new_content);
        echo "  -> Reemplazado y archivo modificado\n";
    }
    
    if (preg_match_all('/DROP\s+SCHEMA\s+(IF\s+EXISTS\s+)?selemti/i', $content, $matches)) {
        echo "Encontrado DROP SCHEMA selemti en: $file\n";
        $new_content = preg_replace('/DROP\s+SCHEMA\s+(IF\s+EXISTS\s+)?selemti/i', '-- DROP SCHEMA selemti; -- COMENTADO POR SEGURIDAD', $content);
        file_put_contents($file, $new_content);
        echo "  -> Reemplazado y archivo modificado\n";
    }
}

echo "\nResumen:\n";
echo "=======\n";
echo "Archivos SQL procesados: " . count($sql_files) . "\n";
echo "Comandos DROP DATABASE encontrados y reemplazados: $dropped_db_found\n";
echo "Proceso completado. Los comandos DROP DATABASE han sido comentados.\n";