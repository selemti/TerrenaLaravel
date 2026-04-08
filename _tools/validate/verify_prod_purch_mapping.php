<?php
// Script to verify the production and purchasing database-to-code mapping against the actual database

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
    $mappingFile = 'docs/V4.0/Code/BD_CODIGO_MAPA_CAMPOS_PROD_PURCH.md';
    if (!file_exists($mappingFile)) {
        throw new Exception("Mapping file not found: {$mappingFile}");
    }
    
    $content = file_get_contents($mappingFile);
    echo "Mapping file loaded successfully." . PHP_EOL;
    
    // Parse the mapping file to extract table and column information
    $lines = explode("\n", $content);
    $verification_results = [];
    $in_tables_section = false;
    
    foreach ($lines as $line) {
        // Detect table rows (lines with | that contain table info)
        if (preg_match('/^\| (.+?) \| (.+?) \| .+ \| (.+?) \|/', $line, $matches)) {
            // Skip header lines
            if (strpos($line, '| Tabla en BD |') !== false) {
                continue;
            }
            
            $tabla_bd = trim($matches[1]);
            $columna_bd = trim($matches[2]);
            $estado_original = trim($matches[3]);
            
            // Skip if it looks like a header or separator
            if ($tabla_bd === 'Tabla en BD' || strpos($line, '|---') === 0) {
                continue;
            }
            
            if (empty($tabla_bd) || empty($columna_bd) || empty($estado_original)) {
                continue;
            }
            
            // Determine schema based on table name
            $schema = 'selemti'; // Default to selemti
            
            // Check if the column actually exists in the database
            $count = DB::connection('pgsql')->select("
                SELECT COUNT(*) as count
                FROM information_schema.columns
                WHERE table_schema = ? 
                AND table_name = ? 
                AND column_name = ?
            ", [$schema, $tabla_bd, $columna_bd]);
            
            $existe_en_bd = ($count[0]->count > 0) ? 'SI' : 'NO';
            
            // Determine decision
            $decision_final = 'SOSPECHOSO'; // Default
            if ($existe_en_bd === 'SI' && $estado_original === 'OK') {
                $decision_final = 'CONFIABLE';
            } elseif ($existe_en_bd === 'SI' && $estado_original === 'FANTASMA') {
                $decision_final = 'ERROR_MAPA';
            } elseif ($existe_en_bd === 'NO' && $estado_original === 'OK') {
                $decision_final = 'ERROR_MAPA';
            } elseif ($existe_en_bd === 'NO' && $estado_original === 'FANTASMA') {
                $decision_final = 'CONFIABLE';
            } elseif ($existe_en_bd === 'NO' && $estado_original === 'MISMATCH') {
                $decision_final = 'SOSPECHOSO'; // Mismatch could still be valid
            } elseif ($existe_en_bd === 'SI' && $estado_original === 'MISMATCH') {
                $decision_final = 'SOSPECHOSO'; // Mismatch could still be valid
            } elseif ($existe_en_bd === 'NO' && $estado_original === 'NO_USADO') {
                $decision_final = 'SOSPECHOSO'; // If it doesn't exist how can it be unused?
            } else if ($existe_en_bd === 'SI' && $estado_original === 'NO_USADO') {
                $decision_final = 'ERROR_MAPA'; // If it exists but was marked as unused
            }
            
            $estado_bd = ($existe_en_bd === 'SI') ? 'OK' : 'NO_EXISTE';
            
            // Extract notes if available
            $notas = '';
            if (preg_match('/^\| .+? \| .+? \| .+? \| .+? \| (.+)$/', $line, $noteMatches)) {
                $notas = trim($noteMatches[1]);
            }
            
            $verification_results[] = [
                'tabla_bd' => $tabla_bd,
                'columna_bd' => $columna_bd,
                'existe_en_bd' => $existe_en_bd,
                'estado_original' => $estado_original,
                'estado_bd' => $estado_bd,
                'decision_final' => $decision_final,
                'notas' => $notas,
                'schema' => $schema
            ];
        }
    }
    
    // Generate the verification report
    $report = "# VERIFICACIÓN DEL MAPA BD ↔ CÓDIGO (Producción, Purchasing)\n\n";
    $report .= "| tabla_bd | columna_bd | existe_en_bd | estado_original | estado_bd | decision_final | notas |\n";
    $report .= "|----------|------------|--------------|-----------------|-----------|----------------|-------|\n";
    
    foreach ($verification_results as $result) {
        $report .= "| {$result['tabla_bd']} | {$result['columna_bd']} | {$result['existe_en_bd']} | {$result['estado_original']} | {$result['estado_bd']} | {$result['decision_final']} | {$result['notas']} |\n";
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
    $report .= "\n## §1 Resumen\n\n";
    $report .= "- Filas CONFIABLE: {$confiables}\n";
    $report .= "- Filas SOSPECHOSO: {$sospechosos}\n";
    $report .= "- Filas ERROR_MAPA: {$errores}\n\n";
    
    // Add list of errors
    $report .= "## §2 Listado de filas ERROR_MAPA\n\n";
    if (count($error_list) > 0) {
        foreach ($error_list as $error) {
            $report .= "- {$error['tabla_bd']}.{$error['columna_bd']}: marcado como '{$error['estado_original']}' pero " . 
                      ($error['existe_en_bd'] === 'SI' ? 'SI existe en BD' : 'NO existe en BD') . "\n";
        }
    } else {
        $report .= "No se encontraron errores de mapeo.\n";
    }
    
    // Add suggestions
    $report .= "\n## §3 Sugerencias de corrección\n\n";
    $report .= "El archivo original 'BD_CODIGO_MAPA_CAMPOS_PROD_PURCH.md' debe actualizarse para reflejar la realidad de la base de datos. Los errores encontrados indican discrepancias entre lo que el mapeo original asumía y la estructura real de la base de datos.\n\n";
    $report .= "Especialmente importante es corregir las filas marcadas como ERROR_MAPA, donde el estado original contradice directamente la existencia real de los campos en la base de datos.\n\n";
    
    echo "Writing verification report..." . PHP_EOL;
    
    // Write the verification report
    $reportFile = 'docs/V4.0/Code/BD_CODIGO_MAPA_CAMPOS_PROD_PURCH_VERIFICADO.md';
    file_put_contents($reportFile, $report);
    
    echo "Verification report completed and saved to: {$reportFile}" . PHP_EOL;
    echo "Summary:" . PHP_EOL;
    echo "- CONFIABLE: {$confiables}" . PHP_EOL;
    echo "- SOSPECHOSO: {$sospechosos}" . PHP_EOL;
    echo "- ERROR_MAPA: {$errores}" . PHP_EOL;

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . PHP_EOL;
}