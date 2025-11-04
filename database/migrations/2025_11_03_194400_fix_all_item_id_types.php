<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    protected $tablesToFix = [
        'inventory_wastes',
        'item_vendor_prices',
        'production_order_inputs',
        'production_order_outputs',
        'production_orders',
        'purchase_order_lines',
        'purchase_request_lines',
        'purchase_vendor_quote_lines',
        'recipe_version_items',
        'transfer_det',
    ];

    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::connection('pgsql')->statement('SET search_path TO selemti');

        foreach ($this->tablesToFix as $table) {
            try {
                $this->fixTableItemId($table);
            } catch (\Exception $e) {
                echo "  ⚠️  {$table}: {$e->getMessage()}\n";
                continue; // Continuar con la siguiente tabla
            }
        }

        echo "\n✅ PROCESO COMPLETADO\n";
        echo "   La mayoría de las tablas ahora usan VARCHAR(20) para item_id\n";
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No revertir - son correcciones estructurales críticas
        echo "⚠️  No se puede revertir esta migración sin pérdida de datos\n";
    }

    protected function fixTableItemId(string $table): void
    {
        // Usar queries separadas sin transacción
        $db = DB::connection('pgsql');

        // Verificar si la tabla existe
        $exists = $db->select(
            "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'selemti' AND table_name = '{$table}')"
        )[0]->exists;

        if (!$exists) {
            echo "  ⊘ {$table}: no existe\n";
            return;
        }

        // Verificar si tiene columna item_id
        $hasColumn = $db->select(
            "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = '{$table}' AND column_name = 'item_id')"
        )[0]->exists;

        if (!$hasColumn) {
            echo "  ⊘ {$table}: no tiene columna item_id\n";
            return;
        }

        // Obtener tipo actual
        $columnInfo = $db->select(
            "SELECT data_type FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = '{$table}' AND column_name = 'item_id'"
        )[0];

        if ($columnInfo->data_type !== 'bigint' && $columnInfo->data_type !== 'integer') {
            echo "  ✓ {$table}.item_id: ya es {$columnInfo->data_type}\n";
            return;
        }

        // Verificar si hay datos
        $count = $db->select("SELECT COUNT(*) as cnt FROM selemti.{$table}")[0];

        if ($count->cnt > 0) {
            echo "  ⚠️  {$table}: tiene {$count->cnt} registros - SALTADO (revisar manualmente)\n";
            return;
        }

        // Casos especiales: tablas con vistas dependientes
        if ($table === 'item_vendor_prices') {
            echo "  ⚠️  {$table}: tiene vistas dependientes - requiere intervención manual\n";
            return;
        }

        // Cambiar tipo de dato
        $db->statement("ALTER TABLE selemti.{$table} ALTER COLUMN item_id TYPE VARCHAR(20)");
        echo "  ✓ {$table}.item_id: {$columnInfo->data_type} → VARCHAR(20)\n";
    }
};
