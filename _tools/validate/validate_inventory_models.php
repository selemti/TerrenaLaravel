<?php
/**
 * Script de Validación: Detecta columnas fantasma en modelos de inventario
 * Uso: php validate_inventory_models.php
 */

require_once 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

// ANSI Colors
const RED = "\033[0;31m";
const GREEN = "\033[0;32m";
const YELLOW = "\033[1;33m";
const NC = "\033[0m"; // No Color

echo "🔍 VALIDACIÓN DE MODELOS DE INVENTARIO\n";
echo str_repeat("=", 60) . "\n\n";

$modelsToCheck = [
    [
        'class' => 'App\Models\Inv\Item',
        'table' => 'items',
        'critical_fields' => ['id', 'nombre', 'unidad_medida_id', 'activo']
    ],
    [
        'class' => 'App\Models\Inv\Batch',
        'table' => 'inventory_batch',
        'critical_fields' => ['id', 'item_id', 'lote_proveedor', 'fecha_recepcion']
    ],
    [
        'class' => 'App\Models\Inv\MovimientoInventario',
        'table' => 'mov_inv',
        'critical_fields' => ['id', 'item_id', 'cantidad', 'tipo']
    ],
    [
        'class' => 'App\Models\Inventory\TransferHeader',
        'table' => 'transfer_cab',
        'critical_fields' => ['id', 'origen_almacen_id', 'destino_almacen_id', 'estado']
    ],
    [
        'class' => 'App\Models\Inventory\TransferLine',
        'table' => 'transfer_det',
        'critical_fields' => ['id', 'transfer_id', 'item_id', 'cantidad']
    ],
];

$totalIssues = 0;

foreach ($modelsToCheck as $modelConfig) {
    $className = $modelConfig['class'];
    $tableName = $modelConfig['table'];

    echo "📋 Validando: {$className}\n";
    echo "   Tabla BD: selemti.{$tableName}\n";

    try {
        // Verificar que el modelo existe
        if (!class_exists($className)) {
            echo RED . "   ❌ CLASE NO EXISTE\n" . NC;
            $totalIssues++;
            continue;
        }

        $model = new $className();

        // Obtener fillable
        $fillable = $model->getFillable();
        if (empty($fillable)) {
            // Verificar si usa guarded
            if (method_exists($model, 'getGuarded')) {
                $guarded = $model->getGuarded();
                if (empty($guarded)) {
                    echo YELLOW . "   ⚠️  Usa guarded=[] (permite todo)\n" . NC;
                } else {
                    echo YELLOW . "   ⚠️  No tiene fillable definido\n" . NC;
                }
            }
        }

        // Obtener columnas reales de BD
        $columns = DB::connection('pgsql')->select("
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'selemti' AND table_name = ?
            ORDER BY ordinal_position
        ", [$tableName]);

        if (empty($columns)) {
            echo RED . "   ❌ TABLA NO EXISTE EN BD\n" . NC;
            $totalIssues++;
            continue;
        }

        $dbColumns = array_map(fn($col) => $col->column_name, $columns);

        // Verificar campos críticos
        $missingCritical = [];
        foreach ($modelConfig['critical_fields'] as $field) {
            if (!in_array($field, $dbColumns)) {
                $missingCritical[] = $field;
            }
        }

        if (!empty($missingCritical)) {
            echo RED . "   ❌ CAMPOS CRÍTICOS FALTANTES EN BD: " . implode(', ', $missingCritical) . "\n" . NC;
            $totalIssues++;
        }

        // Verificar columnas fantasma (fillable no existe en BD)
        if (!empty($fillable)) {
            $phantomColumns = [];
            foreach ($fillable as $field) {
                if (!in_array($field, $dbColumns)) {
                    $phantomColumns[] = $field;
                }
            }

            if (!empty($phantomColumns)) {
                echo RED . "   ❌ COLUMNAS FANTASMA: " . implode(', ', $phantomColumns) . "\n" . NC;
                $totalIssues += count($phantomColumns);
            } else {
                echo GREEN . "   ✅ Sin columnas fantasma\n" . NC;
            }
        }

        // Verificar connection
        $connection = $model->getConnectionName();
        if ($connection !== 'pgsql') {
            echo YELLOW . "   ⚠️  Connection incorrecta: '{$connection}' (debería ser 'pgsql')\n" . NC;
            $totalIssues++;
        }

        echo "\n";

    } catch (Exception $e) {
        echo RED . "   ❌ ERROR: " . $e->getMessage() . "\n" . NC;
        $totalIssues++;
        echo "\n";
    }
}

// Verificar modelos duplicados
echo "\n" . str_repeat("=", 60) . "\n";
echo "🔍 VERIFICANDO MODELOS DUPLICADOS\n\n";

$duplicateChecks = [
    ['app/Models/Inv/Movimiento.php', 'app/Models/Inv/MovimientoInventario.php', 'mov_inv'],
    ['app/Models/Inv/ItemProveedor.php', 'app/Models/Inv/ItemVendor.php', 'item_vendor'],
    ['app/Models/Inv/Batch.php', 'app/Models/Inv/LoteInventario.php', 'inventory_batch'],
    ['app/Models/Inventory/Item.php', 'app/Models/Inv/Item.php', 'items'],
    ['app/Models/Inventory/Movement.php', 'app/Models/Inv/MovimientoInventario.php', 'mov_inv'],
];

foreach ($duplicateChecks as [$file1, $file2, $table]) {
    $exists1 = file_exists($file1);
    $exists2 = file_exists($file2);

    if ($exists1 && $exists2) {
        echo YELLOW . "⚠️  DUPLICADOS para tabla '{$table}':\n" . NC;
        echo "   - {$file1}\n";
        echo "   - {$file2}\n";
        $totalIssues++;
    }
}

// Resumen final
echo "\n" . str_repeat("=", 60) . "\n";
if ($totalIssues === 0) {
    echo GREEN . "✅ VALIDACIÓN EXITOSA - Sin problemas detectados\n" . NC;
} else {
    echo RED . "❌ VALIDACIÓN FALLÓ - {$totalIssues} problema(s) detectado(s)\n" . NC;
    echo "\nVer documentación en:\n";
    echo "- docs/V4.0/Code/ANALISIS_COLUMNAS_FANTASMA_INVENTARIO.md\n";
    echo "- docs/V4.0/Code/RESUMEN_COLUMNAS_FANTASMA.md\n";
}
echo str_repeat("=", 60) . "\n";

exit($totalIssues > 0 ? 1 : 0);
