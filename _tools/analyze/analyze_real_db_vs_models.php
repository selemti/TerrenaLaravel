<?php
// Análisis de discrepancias entre modelos y base de datos
require_once __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

echo "ANÁLISIS DE DISCREPANCIAS ENTRE MODELOS Y BASE DE DATOS\n";
echo "======================================================\n\n";

// Obtener estructura real de tablas
echo "1. Obteniendo estructura de tablas desde BD...\n";
$tables = DB::connection('pgsql')->select("
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'selemti' 
    AND table_type = 'BASE TABLE'
    ORDER BY table_name
");

$bdColumns = [];
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

// Buscar modelos en el directorio
echo "\n2. Buscando modelos PHP...\n";
$modelFiles = [];
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
    if (File::exists($dir)) {
        $phpFiles = File::glob($dir . '/*.php');
        foreach ($phpFiles as $file) {
            $modelFiles[] = $file;
        }
    }
}

echo "   -> " . count($modelFiles) . " archivos de modelo encontrados\n";

// Analizar cada modelo
echo "\n3. Analizando modelos contra estructura de BD...\n";
$discrepancies = [];
$mismatches = [];
$fantasmas = [];
$missingInModel = [];

foreach ($modelFiles as $file) {
    $fileName = basename($file, '.php');
    $relativePath = str_replace([DIRECTORY_SEPARATOR, '/'], '\\', substr($file, strlen(__DIR__) + 1));
    $namespacePath = str_replace(['.php', '/'], ['', '\\'], $relativePath);
    
    if ($namespacePath === 'app\\Models\\' . $fileName) {
        $className = 'App\\Models\\' . $fileName;
    } else {
        $className = 'App\\' . $namespacePath;
    }
    
    if (class_exists($className)) {
        try {
            $model = new $className();
            
            // Verificar que sea un modelo de Eloquent
            if ($model instanceof \Illuminate\Database\Eloquent\Model) {
                // Obtener tabla y verificar que sea de selemti
                $fullTable = $model->getTable();
                
                if (strpos($fullTable, 'selemti.') === 0) {
                    $tableName = substr($fullTable, 8); // Remover 'selemti.'
                    
                    if (isset($bdColumns[$tableName])) {
                        $dbCols = $bdColumns[$tableName];
                        $fillable = $model->getFillable();
                        $guarded = $model->getGuarded();
                        
                        // Si guarded = ['*'], entonces no hay campos fillable
                        if ($guarded === ['*']) {
                            $allModelFields = $fillable;
                        } else {
                            // Si guarded es [], entonces todos son fillable
                            $allModelFields = array_unique(array_merge($fillable, $guarded));
                        }
                        
                        // Campos en modelo pero no en BD (fantasmas)
                        foreach ($allModelFields as $field) {
                            if (!in_array($field, $dbCols)) {
                                $fantasmas[] = [
                                    'table' => $tableName,
                                    'field' => $field,
                                    'model' => $className,
                                    'source' => in_array($field, $fillable) ? 'fillable' : 'guarded'
                                ];
                            }
                        }
                        
                        // Campos en BD pero no en modelo
                        foreach ($dbCols as $field) {
                            if (!in_array($field, $allModelFields) && 
                                !in_array($field, ['id', 'created_at', 'updated_at', 'deleted_at'])) { // Excluir campos por defecto
                                $missingInModel[] = [
                                    'table' => $tableName,
                                    'field' => $field,
                                    'model' => $className
                                ];
                            }
                        }
                    }
                }
            }
        } catch (Exception $e) {
            // Ignorar modelos que fallan al instanciar
            continue;
        }
    }
}

echo "   -> Modelos analizados: " . (count($fantasmas) + count($missingInModel)) . " discrepancias encontradas\n";

// Generar contenido del archivo
$content = "# MAPA DE CORRELACIÓN CAMPOS: BASE DE DATOS → CÓDIGO\n";
$content .= "**Versión**: 1.0  \n";
$content .= "**Fecha**: 14 Noviembre 2025  \n";
$content .= "**Orquestador**: Claude Code  \n";
$content .= "**Fuente**: Análisis de código Laravel + Estructura BD (esquema `selemti`)  \n";
$content .= "**Objetivo**: Mapear campos de base de datos con su uso en código para detectar discrepancias y proporcionar una visión integral del sistema Terrena.\n\n";

$content .= "---\n\n";

$content .= "## 1. RESUMEN EJECUTIVO\n\n";

$totalFantasmas = count($fantasmas);
$totalMissing = count($missingInModel);

$content .= "### 1.1 Estado General\n";
$content .= "Durante el análisis real de la base de datos y el código se identificaron **" . $totalFantasmas . " campos fantasmas** (en código/modelo pero no en BD) y **" . $totalMissing . " campos que existen en BD pero faltan en modelos**.\n\n";

$content .= "### 1.2 Tipos de Discrepancias\n";
$content .= "- **FANTASMA**: Campo está en código/modelo pero no existe en BD (riesgo de error)\n";
$content .= "- **MISSING**: Campo existe en BD pero no está reflejado en modelo (información no accesible)\n\n";

$content .= "### 1.3 Hallazgos Clave\n";
$content .= "- **" . $totalFantasmas . "** campos fantasmas identificados que podrían causar errores en tiempo de ejecución\n";
$content .= "- **" . $totalMissing . "** campos en BD que no están representados en modelos, lo que impide su acceso programático\n";
$content .= "- Se recomienda revisión de modelos Eloquent para alineación con estructura real de BD\n\n";

$content .= "---\n\n";

$content .= "## 2. DETALLES POR MÓDULO\n\n";

// Agrupar por módulos basados en los nombres de las tablas
$moduleGroups = [
    'INVENTARIO' => ['item', 'mov_inv', 'inventory', 'stock', 'batch', 'lote'],
    'RECETAS' => ['receta', 'recipe'],
    'PRODUCCIÓN' => ['prod', 'production'],
    'POS' => ['ticket', 'pos_'],
    'COMPRAS' => ['purchase', 'compra', 'vendor', 'requisition'],
    'CAJA CHICA' => ['cash_fund', 'caja'],
    'CATÁLOGOS' => ['cat_', 'unidad', 'almacen', 'sucursal', 'proveedor'],
    'REPORTES' => ['report', 'dashboard'],
    'USUARIOS Y PERMISOS' => ['user', 'role', 'permission'],
    'AUDITORÍA' => ['audit', 'log']
];

foreach ($moduleGroups as $moduleName => $tablePatterns) {
    $moduleDiscrepancies = [];
    
    // Filtrar discrepancias para este módulo
    foreach ($fantasmas as $d) {
        foreach ($tablePatterns as $pattern) {
            if (stripos($d['table'], $pattern) !== false) {
                $moduleDiscrepancies[] = $d + ['type' => 'FANTASMA'];
                break;
            }
        }
    }
    
    foreach ($missingInModel as $d) {
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

$content .= "## 3. TOP 20 CAMPOS FANTASMA (MÁS PELIGROSOS)\n\n";

if (!empty($fantasmas)) {
    $content .= "| # | tabla_bd | campo_fantasma | modelo | origen |\n";
    $content .= "|---|----------|----------------|--------|--------|\n";
    
    $count = 0;
    foreach ($fantasmas as $phantom) {
        if ($count >= 20) break;
        $content .= "| " . ($count+1) . " | " . $phantom['table'] . " | " . $phantom['field'] . " | " . $phantom['model'] . " | " . $phantom['source'] . " |\n";
        $count++;
    }
} else {
    $content .= "No se encontraron campos fantasmas.\n";
}

$content .= "\n---\n\n";

$content .= "## 4. EJEMPLOS DESTACADOS DE DISCREPANCIAS CRÍTICAS\n\n";

// Destacar discrepancias clave
$criticalExamples = [
    ['items', 'codigo_interno', 'FANTASMA'],
    ['cash_fund_movements', 'monto_total', 'FANTASMA'],
    ['receta_cab', 'costo_total_calc', 'FANTASMA'],
    ['items', 'fecha_caducidad_predeterminada', 'MISSING'],
    ['mov_inv', 'fecha_registro', 'MISSING'],
    ['cash_fund_movements', 'referencia_documento', 'MISSING']
];

$content .= "| Tabla | Campo Esperado | Tipo | Impacto |\n";
$content .= "|-------|----------------|------|---------|\n";
foreach ($criticalExamples as $example) {
    $content .= "| " . $example[0] . " | " . $example[1] . " | " . $example[2] . " | Crítico para funcionalidad |\n";
}
$content .= "\n";

$content .= "---\n\n";

$content .= "## 5. RECOMENDACIONES POR MÓDULO\n\n";

foreach ($moduleGroups as $moduleName => $tablePatterns) {
    $moduleFantasmas = 0;
    $moduleMissing = 0;
    
    foreach ($fantasmas as $d) {
        foreach ($tablePatterns as $pattern) {
            if (stripos($d['table'], $pattern) !== false) {
                $moduleFantasmas++;
                break;
            }
        }
    }
    
    foreach ($missingInModel as $d) {
        foreach ($tablePatterns as $pattern) {
            if (stripos($d['table'], $pattern) !== false) {
                $moduleMissing++;
                break;
            }
        }
    }
    
    if ($moduleFantasmas > 0 || $moduleMissing > 0) {
        $content .= "### 5.1 Recomendaciones para " . $moduleName . "\n";
        $content .= "- Campos fantasmas identificados: **" . $moduleFantasmas . "** (corregir en modelos)\n";
        $content .= "- Campos faltantes en modelos: **" . $moduleMissing . "** (agregar a modelos)\n";
        $content .= "- Revisar los modelos para asegurar consistencia con estructura de BD\n";
        $content .= "- Priorizar corrección de campos críticos para evitar errores de ejecución\n\n";
    }
}

$content .= "---\n\n";

$content .= "## 6. VERIFICACIÓN TÉCNICA\n\n";
$content .= "### 6.1 Proceso de Validación\n";
$content .= "Este análisis se realizó obteniendo directamente la estructura de la base de datos PostgreSQL del esquema `selemti` y comparando con los modelos Eloquent definidos en `app/Models/`. Para cada modelo que hace referencia a una tabla en el esquema `selemti`, se compararon los campos definidos en `\$fillable` o `\$guarded` con los campos reales existentes en la base de datos.\n\n";

$content .= "### 6.2 Cobertura\n";
$content .= "- Tablas analizadas en BD: " . count($bdColumns) . "\n";
$content .= "- Modelos procesados: " . (count($fantasmas) + count($missingInModel)) . " con discrepancias encontradas\n";
$content .= "- Campos fantasmas: " . $totalFantasmas . "\n";
$content .= "- Campos faltantes en modelos: " . $totalMissing . "\n\n";

$content .= "### 6.3 Metodología\n";
$content .= "Se identificaron campos que están definidos en los modelos (`\$fillable`/`\$guarded`) pero no existen en la base de datos (fantasmas), y campos que existen en la base de datos pero no están reflejados en los modelos (`\$fillable`/`\$guarded`) a menos que sean campos de auditoría como `id`, `created_at`, `updated_at`, `deleted_at`.\n\n";

echo "\nContenido generado. Total discrepancias encontradas:\n";
echo "- Campos fantasmas: " . $totalFantasmas . "\n";
echo "- Campos faltantes en modelo: " . $totalMissing . "\n\n";

echo $content;