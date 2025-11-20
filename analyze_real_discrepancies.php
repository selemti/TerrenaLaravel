<?php
// Análisis de discrepancias entre modelos y base de datos - Versión mejorada
require_once __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

echo "ANÁLISIS REAL DE DISCREPANCIAS ENTRE MODELOS Y BASE DE DATOS\n";
echo "===========================================================\n\n";

// Obtener estructura real de tablas
echo "1. Obteniendo estructura de tablas desde BD...\n";
$bdColumns = [];
$tables = DB::connection('pgsql')->select("
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'selemti' 
    AND table_type = 'BASE TABLE'
    ORDER BY table_name
");

foreach ($tables as $table) {
    $tableName = $table->table_name;
    $columns = DB::connection('pgsql')->select("
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_schema = 'selemti' 
        AND table_name = ?
        ORDER BY ordinal_position
    ", [$tableName]);
    
    $bdColumns[$tableName] = array_map(function($col) {
        return $col->column_name;
    }, $columns);
}

echo "   -> " . count($bdColumns) . " tablas analizadas en BD\n";

// Función para analizar un archivo de modelo
function analyzeModelFile($filePath) {
    $content = file_get_contents($filePath);
    
    // Extraer nombre de clase
    if (preg_match('/class\s+(\w+)\s+extends/', $content, $matches)) {
        $className = $matches[1];
        
        // Buscar definición de tabla
        if (preg_match('/protected\s+\$table\s*=\s*[\'"]([^\'"]*selemti\.([^\'"]+))[\'"]/', $content, $tableMatches)) {
            $fullTable = $tableMatches[1];
            $tableName = $tableMatches[2];
            
            // Extraer fillable
            $fillable = [];
            if (preg_match('/protected\s+\$fillable\s*=.*?\[(.*?)\]/s', $content, $matches)) {
                $fieldsStr = $matches[1];
                preg_match_all("/[\'\"]([^\s\'\"=>,]+)[\'\"]/s", $fieldsStr, $fieldMatches);
                $fillable = array_unique($fieldMatches[1]);
            }
            
            // Extraer guarded
            $guarded = [];
            if (preg_match('/protected\s+\$guarded\s*=.*?\[(.*?)\]/s', $content, $matches)) {
                $fieldsStr = $matches[1];
                preg_match_all("/[\'\"]([^\s\'\"=>,]+)[\'\"]/s", $fieldsStr, $fieldMatches);
                $guarded = array_unique($fieldMatches[1]);
            }
            
            return [
                'className' => $className,
                'tableName' => $tableName,
                'fullTable' => $fullTable,
                'fillable' => $fillable,
                'guarded' => $guarded
            ];
        }
    }
    
    return null;
}


echo "\n2. Analizando archivos de modelos...\n";
$discrepancies = [
    'fantasmas' => [],
    'missing' => []
];

$directories = [
    'app/Models',
    'app/Models/Caja',
    'app/Models/Catalogs', 
    'app/Models/Core',
    'app/Models/Inv',
    'app/Models/Inventory',
    'app/Models/Pos',
    'app/Models/Purchasing',
    'app/Models/Rec',
    'app/Models/Reports'
];

foreach ($directories as $dir) {
    if (is_dir($dir)) {
        $phpFiles = glob("$dir/*.php");
        foreach ($phpFiles as $file) {
            $modelInfo = analyzeModelFile($file);
            if ($modelInfo && isset($bdColumns[$modelInfo['tableName']])) {
                $dbCols = $bdColumns[$modelInfo['tableName']];
                
                // Campos en modelo pero no en BD (fantasmas)
                $allModelFields = array_unique(array_merge($modelInfo['fillable'], $modelInfo['guarded']));
                
                foreach ($allModelFields as $field) {
                    if (!in_array($field, $dbCols)) {
                        $discrepancies['fantasmas'][] = [
                            'table' => $modelInfo['tableName'],
                            'field' => $field,
                            'model' => $modelInfo['className'],
                            'source' => in_array($field, $modelInfo['fillable']) ? 'fillable' : 'guarded',
                            'filePath' => $file
                        ];
                    }
                }
                
                // Campos en BD pero no en modelo (salvo campos estándar)
                foreach ($dbCols as $field) {
                    if (!in_array($field, $allModelFields) && 
                        !in_array($field, ['id', 'created_at', 'updated_at', 'deleted_at', 'created_by', 'updated_by'])) {
                        $discrepancies['missing'][] = [
                            'table' => $modelInfo['tableName'],
                            'field' => $field,
                            'model' => $modelInfo['className'],
                            'filePath' => $file
                        ];
                    }
                }
            }
        }
    }
}

echo "   -> " . (count($discrepancies['fantasmas']) + count($discrepancies['missing'])) . " discrepancias encontradas\n";

// Generar contenido del archivo
$content = "# MAPA DE CORRELACIÓN CAMPOS: BASE DE DATOS → CÓDIGO\n";
$content .= "**Versión**: 1.0  \n";
$content .= "**Fecha**: 14 Noviembre 2025  \n";
$content .= "**Orquestador**: Claude Code  \n";
$content .= "**Fuente**: Análisis directo de modelos PHP vs estructura real de BD (esquema `selemti`)  \n";
$content .= "**Objetivo**: Mapear campos de base de datos con su uso en código para detectar discrepancias y proporcionar una visión integral del sistema Terrena.\n\n";

$content .= "---\n\n";

$content .= "## 1. RESUMEN EJECUTIVO\n\n";

$totalFantasmas = count($discrepancies['fantasmas']);
$totalMissing = count($discrepancies['missing']);

$content .= "### 1.1 Estado General\n";
$content .= "Durante el análisis real de la base de datos y el código se identificaron **" . $totalFantasmas . " campos fantasmas** (en código/modelo pero no en BD) y **" . $totalMissing . " campos que existen en BD pero faltan en modelos**.\n\n";

$content .= "### 1.2 Tipos de Discrepancias\n";
$content .= "- **FANTASMA**: Campo está en código/modelo pero no existe en BD (riesgo de error)\n";
$content .= "- **MISSING**: Campo existe en BD pero no está reflejado en modelo (información no accesible)\n\n";

$content .= "### 1.3 Hallazgos Clave\n";
if ($totalFantasmas > 0) {
$content .= "- **" . $totalFantasmas . "** campos fantasmas identificados que podrían causar errores en tiempo de ejecución\n";
}
if ($totalMissing > 0) {
$content .= "- **" . $totalMissing . "** campos en BD que no están representados en modelos, lo que impide su acceso programático\n";
}
$content .= "- Se recomienda revisión de modelos Eloquent para alineación con estructura real de BD\n\n";

$content .= "---\n\n";

$content .= "## 2. DETALLES POR MÓDULO\n\n";

// Agrupar por módulos basados en los nombres de las tablas
$moduleGroups = [
    'INVENTARIO' => ['item', 'mov_inv', 'inventory', 'stock', 'batch', 'lote', 'cat_'],
    'RECETAS' => ['receta', 'recipe'],
    'PRODUCCIÓN' => ['prod', 'production'],
    'POS' => ['ticket', 'pos_'],
    'COMPRAS' => ['purchase', 'compra', 'vendor', 'requisition', 'quote'],
    'CAJA CHICA' => ['cash_fund', 'caja'],
    'CATÁLOGOS' => ['cat_', 'unidad', 'almacen', 'sucursal', 'proveedor'],
    'REPORTES' => ['report', 'dashboard'],
    'USUARIOS Y PERMISOS' => ['user', 'role', 'permission'],
    'AUDITORÍA' => ['audit', 'log'],
    'CORTES' => ['precorte', 'postcorte', 'sesion'],
    'CONSUMOS POS' => ['inv_consumo', 'ticket_venta']
];

foreach ($moduleGroups as $moduleName => $tablePatterns) {
    $moduleDiscrepancies = [];
    
    // Filtrar discrepancias para este módulo
    foreach ($discrepancies['fantasmas'] as $d) {
        foreach ($tablePatterns as $pattern) {
            if (stripos($d['table'], $pattern) !== false) {
                $moduleDiscrepancies[] = $d + ['type' => 'FANTASMA'];
                break;
            }
        }
    }
    
    foreach ($discrepancies['missing'] as $d) {
        foreach ($tablePatterns as $pattern) {
            if (stripos($d['table'], $pattern) !== false) {
                $moduleDiscrepancies[] = $d + ['type' => 'MISSING'];
                break;
            }
        }
    }
    
    if (!empty($moduleDiscrepancies)) {
        $content .= "### 2.1 Módulo: " . $moduleName . "\n\n";
        $content .= "| tabla_bd | columna_bd | modelo_php | tipo |\n";
        $content .= "|----------|------------|------------|------|\n";
        
        foreach ($moduleDiscrepancies as $disc) {
            if ($disc['type'] === 'FANTASMA') {
                $content .= "| " . $disc['table'] . " | " . $disc['field'] . " | " . $disc['model'] . " | FANTASMA |\n";
            } else {
                $content .= "| " . $disc['table'] . " | " . $disc['field'] . " | " . $disc['model'] . " | MISSING |\n";
            }
        }
        
        $content .= "\n";
    }
}

$content .= "---\n\n";

if ($totalFantasmas > 0) {
    $content .= "## 3. TOP " . min(20, $totalFantasmas) . " CAMPOS FANTASMA (MÁS PELIGROSOS)\n\n";

    $content .= "| # | tabla_bd | campo_fantasma | modelo | origen |\n";
    $content .= "|---|----------|----------------|--------|--------|\n";
    
    $count = 0;
    foreach ($discrepancies['fantasmas'] as $phantom) {
        if ($count >= 20) break;
        $content .= "| " . ($count+1) . " | " . $phantom['table'] . " | " . $phantom['field'] . " | " . $phantom['model'] . " | " . $phantom['source'] . " |\n";
        $count++;
    }
    $content .= "\n";
} else {
    $content .= "## 3. CAMPOS FANTASMA\n\n";
    $content .= "No se encontraron campos fantasmas.\n\n";
}

$content .= "---\n\n";

$content .= "## 4. EJEMPLOS DESTACADOS DE DISCREPANCIAS CRÍTICAS\n\n";

if ($totalFantasmas > 0 || $totalMissing > 0) {
    $content .= "| Tabla | Campo | Tipo | Impacto |\n";
    $content .= "|-------|-------|------|---------|\n";
    
    // Tomar algunos ejemplos de los primeros registros
    $examples = array_slice(array_merge($discrepancies['fantasmas'], array_slice($discrepancies['missing'], 0, 5)), 0, 6);
    foreach ($examples as $example) {
        $type = isset($example['source']) ? 'FANTASMA' : 'MISSING';
        $field = $example['field'];
        $table = $example['table'];
        $content .= "| " . $table . " | " . $field . " | " . $type . " | Potencial causa de error |\n";
    }
} else {
    $content .= "No se encontraron discrepancias críticas.\n";
}
$content .= "\n";

$content .= "---\n\n";

$content .= "## 5. RECOMENDACIONES POR MÓDULO\n\n";

foreach ($moduleGroups as $moduleName => $tablePatterns) {
    $moduleFantasmas = 0;
    $moduleMissing = 0;
    
    foreach ($discrepancies['fantasmas'] as $d) {
        foreach ($tablePatterns as $pattern) {
            if (stripos($d['table'], $pattern) !== false) {
                $moduleFantasmas++;
                break;
            }
        }
    }
    
    foreach ($discrepancies['missing'] as $d) {
        foreach ($tablePatterns as $pattern) {
            if (stripos($d['table'], $pattern) !== false) {
                $moduleMissing++;
                break;
            }
        }
    }
    
    if ($moduleFantasmas > 0 || $moduleMissing > 0) {
        $content .= "### 5.1 Recomendaciones para " . $moduleName . "\n";
        if ($moduleFantasmas > 0) {
            $content .= "- Campos fantasmas identificados: **" . $moduleFantasmas . "** (corregir en modelos)\n";
        }
        if ($moduleMissing > 0) {
            $content .= "- Campos faltantes en modelos: **" . $moduleMissing . "** (agregar a modelos)\n";
        }
        $content .= "- Revisar los modelos para asegurar consistencia con estructura de BD\n";
        if ($moduleFantasmas > 0) {
            $content .= "- Priorizar corrección de campos fantasmas para evitar errores de ejecución\n";
        }
        if ($moduleMissing > 0) {
            $content .= "- Considerar inclusión de campos faltantes que puedan ser relevantes para la funcionalidad\n";
        }
        $content .= "\n";
    }
}

$content .= "---\n\n";

$content .= "## 6. VERIFICACIÓN TÉCNICA\n\n";
$content .= "### 6.1 Proceso de Validación\n";
$content .= "Este análisis se realizó leyendo directamente los archivos de modelos PHP en `app/Models/` y comparando los campos definidos en `\$fillable` o `\$guarded` con los campos reales existentes en la base de datos PostgreSQL en el esquema `selemti`.\n\n";

$content .= "### 6.2 Cobertura\n";
$content .= "- Tablas analizadas en BD: " . count($bdColumns) . "\n";
$content .= "- Archivos de modelo analizados: " . count(glob("app/Models/*.php")) . "\n";
$content .= "- Campos fantasmas: " . $totalFantasmas . "\n";
$content .= "- Campos faltantes en modelos: " . $totalMissing . "\n\n";

$content .= "### 6.3 Metodología\n";
$content .= "Se utilizaron expresiones regulares para extraer definiciones de modelos PHP, incluyendo el nombre de la tabla, campos fillable y guarded. Luego se compararon estos campos con la estructura real de la base de datos para identificar discrepancias.\n\n";

echo "\nContenido generado. Total discrepancias encontradas:\n";
echo "- Campos fantasmas: " . $totalFantasmas . "\n";
echo "- Campos faltantes en modelo: " . $totalMissing . "\n\n";

echo $content;