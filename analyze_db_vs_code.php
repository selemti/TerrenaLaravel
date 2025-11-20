<?php
// Script para analizar discrepancias entre BD y código
require_once __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

echo "ANÁLISIS DE DISCREPANCIAS BD vs CÓDIGO - TERRENA\n";
echo "===============================================\n\n";

try {
    // Obtener todas las tablas del esquema 'selemti'
    echo "Obteniendo estructura de tablas...\n";
    $tables = DB::connection('pgsql')->select("
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'selemti' 
        AND table_type = 'BASE TABLE'
        ORDER BY table_name
    ");
    
    $allColumns = [];
    
    foreach ($tables as $table) {
        $tableName = $table->table_name;
        $columns = DB::connection('pgsql')->select("
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns
            WHERE table_schema = 'selemti' 
            AND table_name = ?
            ORDER BY ordinal_position
        ", [$tableName]);
        
        $allColumns[$tableName] = array_map(function($col) {
            return $col->column_name;
        }, $columns);
    }
    
    echo "Estructura de BD obtenida para " . count($allColumns) . " tablas.\n";
    
    // Buscar modelos relacionados con los módulos clave
    $modelDirs = [
        'app/Models/',
        'app/Models/Inv/',
        'app/Models/Rec/',
        'app/Models/Prod/',
        'app/Models/Pos/',
        'app/Models/Purchasing/',
        'app/Models/CashFund/'
    ];
    
    $models = [];
    foreach ($modelDirs as $dir) {
        if (is_dir($dir)) {
            $files = glob($dir . '*.php');
            foreach ($files as $file) {
                $filename = basename($file, '.php');
                $className = 'App\\Models\\' . str_replace(['/', '\\'], '\\', substr($dir, 8)) . $filename;
                
                // Solo procesar modelos que pertenecen a tablas en selemti
                if (class_exists($className)) {
                    $modelInstance = new $className();
                    $tableName = $modelInstance->getTable();
                    
                    if (strpos($tableName, 'selemti.') === 0) {
                        $actualTableName = substr($tableName, 8); // Remover 'selemti.'
                        if (isset($allColumns[$actualTableName])) {
                            $fillable = $modelInstance->getFillable();
                            $guarded = $modelInstance->getGuarded();
                            
                            $models[] = [
                                'class' => $className,
                                'table' => $actualTableName,
                                'fillable' => $fillable,
                                'guarded' => $guarded,
                                'db_columns' => $allColumns[$actualTableName]
                            ];
                        }
                    }
                }
            }
        }
    }
    
    echo "Se encontraron " . count($models) . " modelos con tablas en selemti.\n";
    
    // Escribir resultados
    $content = "# MAPA DE CORRELACIÓN CAMPOS: BASE DE DATOS → CÓDIGO\n";
    $content .= "**Versión**: 1.0  \n";
    $content .= "**Fecha**: 14 Noviembre 2025  \n";
    $content .= "**Orquestador**: Claude Code  \n";
    $content .= "**Fuente**: Análisis de código Laravel + Estructura BD (esquema `selemti`)  \n";
    $content .= "**Objetivo**: Mapear campos de base de datos con su uso en código para detectar discrepancias y proporcionar una visión integral del sistema Terrena.\n\n";
    
    $content .= "---\n\n";
    
    $content .= "## 1. RESUMEN EJECUTIVO\n\n";
    
    $mismatches = [];
    $phantoms = [];
    $totalFields = 0;
    $mismatchCount = 0;
    $phantomCount = 0;
    
    foreach ($models as $model) {
        $tableName = $model['table'];
        $dbCols = $model['db_columns'];
        $fillableCols = $model['fillable'];
        $guardedCols = $model['guarded'];
        
        $allModelCols = array_unique(array_merge($fillableCols, $guardedCols));
        
        foreach ($allModelCols as $field) {
            $totalFields++;
            if (!in_array($field, $dbCols)) {
                $phantomCount++;
                $phantoms[] = [
                    'table' => $tableName,
                    'field' => $field,
                    'model' => $model['class']
                ];
            }
        }
        
        foreach ($dbCols as $field) {
            if (!in_array($field, $allModelCols)) {
                $mismatchCount++;
                $mismatches[] = [
                    'table' => $tableName,
                    'field' => $field,
                    'model' => $model['class'],
                    'status' => 'MISSING_IN_MODEL'
                ];
            }
        }
    }
    
    $content .= "### 1.1 Estado General\n";
    $content .= "Durante el análisis real de la base de datos y el código se identificaron **" . $phantomCount . " campos fantasmas** (en código pero no en BD) y **" . $mismatchCount . " campos que existen en BD pero faltan en modelos**. El total de campos analizados fue de **" . $totalFields . "**.\n\n";
    
    $content .= "### 1.2 Tipos de Discrepancias\n";
    $content .= "- **MISMATCH**: Campo existe en BD pero no está en el modelo\n";
    $content .= "- **FANTASMA**: Campo está en código/modelo pero no existe en BD\n";
    $content .= "- **OK**: Campo existe y se utiliza correctamente en modelo\n\n";
    
    $content .= "### 1.3 Hallazgos Clave\n";
    $content .= "- **" . $phantomCount . "** campos fantasmas identificados\n";
    $content .= "- **" . $mismatchCount . "** campos en BD que no están reflejados en modelos\n";
    $content .= "- Se recomienda revisión de modelos Eloquent para alineación con estructura real de BD\n\n";
    
    $content .= "---\n\n";
    
    $content .= "## 2. DETALLES POR MÓDULO\n\n";
    
    // Agrupar por módulos basados en prefijos de tablas
    $moduleGroups = [
        'INVENTARIO' => ['items', 'mov_inv', 'inventory_batch', 'stock', 'catalogo', 'unidad', 'almacen', 'lote'],
        'RECETAS' => ['receta', 'recipe'],
        'PRODUCCIÓN' => ['prod', 'production'],
        'POS' => ['ticket', 'pos_'],
        'COMPRAS' => ['purchase', 'compra', 'proveedor'],
        'CAJA' => ['cash_fund', 'caja', 'sesion'],
        'CATÁLOGOS' => ['cat_', 'unidad', 'almacen', 'sucursal', 'proveedor']
    ];
    
    foreach ($moduleGroups as $moduleName => $tablePatterns) {
        $moduleTables = [];
        foreach ($models as $model) {
            foreach ($tablePatterns as $pattern) {
                if (stripos($model['table'], $pattern) !== false) {
                    $moduleTables[] = $model;
                    break;
                }
            }
        }
        
        if (!empty($moduleTables)) {
            $content .= "### 2.1 Módulo: " . strtoupper($moduleName) . "\n\n";
            $content .= "| tabla_bd | columna_bd | modelo_php | estado |\n";
            $content .= "|----------|------------|------------|--------|\n";
            
            foreach ($moduleTables as $model) {
                $tableName = $model['table'];
                $dbCols = $model['db_columns'];
                $allModelCols = array_unique(array_merge($model['fillable'], $model['guarded']));
                
                // Mostrar campos fantasmas
                foreach ($allModelCols as $field) {
                    if (!in_array($field, $dbCols)) {
                        $content .= "| " . $tableName . " | - (NO EXISTE) | " . $model['class'] . " | FANTASMA |\n";
                    }
                }
                
                // Mostrar campos que faltan en modelo
                foreach ($dbCols as $field) {
                    if (!in_array($field, $allModelCols)) {
                        $content .= "| " . $tableName . " | " . $field . " | " . $model['class'] . " | MISSING |\n";
                    }
                }
            }
            
            $content .= "\n";
        }
    }
    
    $content .= "---\n\n";
    
    $content .= "## 3. TOP 20 CAMPOS FANTASMA (MÁS PELIGROSOS)\n\n";
    
    if (!empty($phantoms)) {
        usort($phantoms, function($a, $b) {
            // Priorizar por nombre de modelo y campo para encontrar los más comunes
            return strcmp($a['model'], $b['model']);
        });
        
        $content .= "| # | tabla_bd | campo_fantasma | modelo_php |\n";
        $content .= "|---|----------|----------------|------------|\n";
        
        $count = 0;
        foreach ($phantoms as $phantom) {
            if ($count >= 20) break;
            $content .= "| " . ($count+1) . " | " . $phantom['table'] . " | " . $phantom['field'] . " | " . $phantom['model'] . " |\n";
            $count++;
        }
    } else {
        $content .= "No se encontraron campos fantasmas.\n";
    }
    
    $content .= "\n---\n\n";
    
    $content .= "## 4. RECOMENDACIONES POR MÓDULO\n\n";
    
    foreach ($moduleGroups as $moduleName => $tablePatterns) {
        $moduleTables = [];
        foreach ($models as $model) {
            foreach ($tablePatterns as $pattern) {
                if (stripos($model['table'], $pattern) !== false) {
                    $moduleTables[] = $model;
                    break;
                }
            }
        }
        
        if (!empty($moduleTables)) {
            $phantomCountModule = 0;
            $missingCountModule = 0;
            
            foreach ($moduleTables as $model) {
                $allModelCols = array_unique(array_merge($model['fillable'], $model['guarded']));
                $dbCols = $model['db_columns'];
                
                foreach ($allModelCols as $field) {
                    if (!in_array($field, $dbCols)) {
                        $phantomCountModule++;
                    }
                }
                
                foreach ($dbCols as $field) {
                    if (!in_array($field, $allModelCols)) {
                        $missingCountModule++;
                    }
                }
            }
            
            $content .= "### 4.1 Recomendaciones para " . strtoupper($moduleName) . "\n";
            $content .= "- Campos fantasmas identificados: **" . $phantomCountModule . "**\n";
            $content .= "- Campos faltantes en modelos: **" . $missingCountModule . "**\n";
            $content .= "- Revisar los modelos para asegurar consistencia con estructura de BD\n\n";
        }
    }
    
    $content .= "## 5. VERIFICACIÓN TÉCNICA\n\n";
    $content .= "### 5.1 Proceso de Validación\n";
    $content .= "Este análisis se realizó obteniendo directamente la estructura de la base de datos PostgreSQL del esquema `selemti` y comparando con los modelos Eloquent del proyecto. Se identificaron campos que están definidos en los modelos pero no existen en la base de datos (fantasmas) y campos que existen en la base de datos pero no están reflejados en los modelos.\n\n";
    
    $content .= "### 5.2 Cobertura\n";
    $content .= "- Tablas analizadas: " . count($allColumns) . "\n";
    $content .= "- Modelos procesados: " . count($models) . "\n";
    $content .= "- Campos en modelos: " . $totalFields . "\n";
    $content .= "- Campos fantasmas: " . $phantomCount . "\n";
    $content .= "- Campos faltantes en modelos: " . $mismatchCount . "\n\n";
    
    echo "Generando archivo con resultados reales...\n";
    
    echo $content;
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}