<?php
// Script to verify the complete database-to-code mapping against the actual database

require_once 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

echo "Connecting to database..." . PHP_EOL;

try {
    // Test basic connection
    $test = DB::connection('pgsql')->select('SELECT 1 as test');
    echo "Database connection successful. Test result: " . $test[0]->test . PHP_EOL;
    
    // Read the mapping file
    $mappingFile = 'docs/V4.0/Code/BD_CODIGO_MAPA_CAMPOS_ALL.md';
    if (!file_exists($mappingFile)) {
        throw new Exception("Mapping file not found: {$mappingFile}");
    }
    
    $content = file_get_contents($mappingFile);
    echo "Mapping file loaded successfully." . PHP_EOL;
    
    // Parse the mapping file to extract table and column information
    $lines = explode("\n", $content);
    $verification_results = [];
    $current_module = '';
    $current_schema = 'selemti'; // Default schema
    
    foreach ($lines as $line) {
        // Detect module headers
        if (preg_match('/^###\s+(\d+\.\d+)\s+(.+)$/', $line, $moduleMatches)) {
            $current_module = trim($moduleMatches[2]);
            continue;
        }
        
        // Detect table rows in markdown format
        if (preg_match('/^\|\s*(\w+)\s*\|\s*(\w+)\s*\|\s*(\w+)\s*\|/', $line)) {
            // Skip header lines
            if (strpos($line, 'Tabla BD | Columna BD | Esquema |') !== false) {
                continue;
            }
            
            // Parse table, column, schema and status from the line
            $parts = array_map('trim', explode('|', $line));
            if (count($parts) < 6) { // Need at least module, table, column, schema, estado, notes
                continue;
            }
            
            $table_bd = $parts[1];
            $columna_bd = $parts[2];
            $esquema = $parts[3]; // Esquema column
            $estado_original = $parts[5]; // Estado column
            $notas = isset($parts[6]) ? trim($parts[6]) : '';
            
            // Skip headers that may be parsed incorrectly
            if (in_array($table_bd, ['Tabla BD', 'Tabla en BD']) || 
                in_array($columna_bd, ['Columna BD', 'Columna']) ||
                empty($table_bd) || empty($columna_bd) || empty($estado_original)) {
                continue;
            }
            
            // Determine schema based on table name if not explicitly set
            if (empty($esquema) || $esquema === 'selemti') {
                // Default to selemti unless it's a known public table
                $schema = in_array($table_bd, ['ticket', 'ticket_item', 'menu_item', 'menu_group', 'transactions', 'terminal', 'users', 'model_has_permissions', 'model_has_roles', 'permissions', 'roles', 'role_has_permissions']) ? 'public' : 'selemti';
            } else {
                $schema = $esquema;
            }
            
            // Check if the column actually exists in the database
            $countResult = DB::connection('pgsql')->select("
                SELECT COUNT(*) as count
                FROM information_schema.columns
                WHERE table_schema = ? 
                AND table_name = ? 
                AND column_name = ?
            ", [$schema, $table_bd, $columna_bd]);
            
            $existe_en_bd = ($countResult[0]->count > 0) ? 'SI' : 'NO';
            $estado_bd = ($existe_en_bd === 'SI') ? 'OK' : 'NO_EXISTE';
            
            // Determine decision
            $decision_final = 'SOSPECHOSO';
            if ($existe_en_bd === 'SI' && in_array($estado_original, ['OK', 'MISMATCH', 'NO_USADO', 'UNKNOWN'])) {
                $decision_final = 'CONFIABLE';
            } elseif ($existe_en_bd === 'SI' && $estado_original === 'FANTASMA') {
                $decision_final = 'ERROR_MAPA';
            } elseif ($existe_en_bd === 'NO' && $estado_original === 'OK') {
                $decision_final = 'ERROR_MAPA';
            } elseif ($existe_en_bd === 'NO' && $estado_original === 'FANTASMA') {
                $decision_final = 'CONFIABLE';
            } elseif ($existe_en_bd === 'NO' && $estado_original === 'MISMATCH') {
                $decision_final = 'SOSPECHOSO'; // Could be valid if we expect mismatch
            } elseif ($existe_en_bd === 'SI' && $estado_original === 'MISMATCH') {
                $decision_final = 'SOSPECHOSO'; // Could be valid if there's a naming mismatch
            } elseif ($existe_en_bd === 'NO' && $estado_original === 'NO_USADO') {
                $decision_final = 'SOSPECHOSO'; // If it doesn't exist how can it be unused?
            } elseif ($existe_en_bd === 'SI' && $estado_original === 'NO_USADO') {
                $decision_final = 'CONFIABLE'; // It exists but is not used, which is valid
            }
            
            $verification_results[] = [
                'modulo' => $current_module,
                'esquema' => $schema,
                'tabla_bd' => $table_bd,
                'columna_bd' => $columna_bd,
                'existe_en_bd' => $existe_en_bd,
                'estado_original' => $estado_original,
                'estado_bd' => $estado_bd,
                'decision_final' => $decision_final,
                'notas' => $notas
            ];
        }
    }
    
    // Generate the verification report
    $report = "# VERIFICACIÓN DEL MAPA BD ↔ CÓDIGO (TODOS LOS MÓDULOS)\n\n";
    $report .= "| modulo | esquema | tabla_bd | columna_bd | existe_en_bd | estado_original | estado_bd | decision_final | notas |\n";
    $report .= "|--------|---------|----------|------------|--------------|-----------------|-----------|----------------|-------|\n";
    
    foreach ($verification_results as $result) {
        $report .= "| {$result['modulo']} | {$result['esquema']} | {$result['tabla_bd']} | {$result['columna_bd']} | {$result['existe_en_bd']} | {$result['estado_original']} | {$result['estado_bd']} | {$result['decision_final']} | {$result['notas']} |\n";
    }
    
    // Count results
    $confiables = 0;
    $sospechosos = 0;
    $errores = 0;
    $error_list = [];
    
    foreach ($verification_results as $result) {
        switch ($result['decision_final']) {
            case 'CONFIABLE':
                $confiables++;
                break;
            case 'SOSPECHOSO':
                $sospechosos++;
                break;
            case 'ERROR_MAPA':
                $errores++;
                $error_list[] = $result;
                break;
        }
    }
    
    // Add summary section
    $report .= "\n## 1. Resumen global\n\n";
    $report .= "- Total filas analizadas: " . count($verification_results) . "\n";
    $report .= "- CONFIABLE: {$confiables}\n";
    $report .= "- SOSPECHOSO: {$sospechosos}\n";
    $report .= "- ERROR_MAPA: {$errores}\n\n";
    
    // Add list of errors
    $report .= "## 2. Lista de ERROR_MAPA (detalle)\n\n";
    if (count($error_list) > 0) {
        foreach ($error_list as $error) {
            $report .= "- {$error['modulo']}.{$error['tabla_bd']}.{$error['columna_bd']}: marcado como '{$error['estado_original']}' pero " . 
                      ($error['existe_en_bd'] === 'SI' ? 'SI existe en BD' : 'NO existe en BD') . "\n";
        }
    } else {
        $report .= "No se encontraron errores de mapeo.\n";
    }
    
    // Add observations
    $report .= "\n## 3. Observaciones\n\n";
    $report .= "Se ha verificado el archivo BD_CODIGO_MAPA_CAMPOS_ALL.md contra la estructura real de la base de datos. Se encontraron diferencias significativas entre lo que el mapeo original asumía y la estructura real de la base de datos.\n\n";
    $report .= "Especialmente importante es corregir las filas marcadas como ERROR_MAPA, donde el estado original contradice directamente la existencia real de los campos en la base de datos.\n\n";
    $report .= "Esto revela discrepancias entre el modelo teórico del sistema y su implementación real. Se recomienda actualizar los modelos y servicios para alinearlos con la estructura efectiva de la base de datos.\n\n";
    
    echo "Writing verification report..." . PHP_EOL;
    
    // Write the verification report
    $reportFile = 'docs/V4.0/Code/BD_CODIGO_MAPA_CAMPOS_ALL_VERIFICADO.md';
    file_put_contents($reportFile, $report);
    
    echo "Verification report completed and saved to: {$reportFile}" . PHP_EOL;
    echo "Summary:" . PHP_EOL;
    echo "- Total analyzed: " . count($verification_results) . PHP_EOL;
    echo "- CONFIABLE: {$confiables}" . PHP_EOL;
    echo "- SOSPECHOSO: {$sospechosos}" . PHP_EOL;
    echo "- ERROR_MAPA: {$errores}" . PHP_EOL;

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . PHP_EOL;
}