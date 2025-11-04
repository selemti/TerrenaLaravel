<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Corrige el tipo de dato de item_id en tablas que lo tienen como BIGINT
     * cuando debería ser VARCHAR para coincidir con items.id
     */
    public function up(): void
    {
        DB::connection('pgsql')->statement('SET search_path TO selemti');

        // 1. inventory_count_lines.item_id: BIGINT → VARCHAR
        $this->fixInventoryCountLines();

        // 2. Verificar otras tablas con mismo problema
        $this->checkOtherTables();
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::connection('pgsql')->statement('SET search_path TO selemti');

        // Revertir item_id a BIGINT
        $sql = <<<SQL
            ALTER TABLE selemti.inventory_count_lines
            ALTER COLUMN item_id TYPE BIGINT USING item_id::BIGINT;
        SQL;

        DB::connection('pgsql')->statement($sql);
    }

    protected function fixInventoryCountLines(): void
    {
        // Primero verificar si hay datos
        $count = DB::connection('pgsql')
            ->table('selemti.inventory_count_lines')
            ->count();

        if ($count > 0) {
            echo "⚠️  ADVERTENCIA: Hay {$count} registros en inventory_count_lines\n";
            echo "   Verificando integridad antes de cambiar tipo...\n";

            // Verificar que todos los item_id existen en items
            $invalid = DB::connection('pgsql')->select(<<<SQL
                SELECT DISTINCT icl.item_id
                FROM selemti.inventory_count_lines icl
                LEFT JOIN selemti.items i ON icl.item_id::VARCHAR = i.id
                WHERE i.id IS NULL
                LIMIT 5;
            SQL);

            if (count($invalid) > 0) {
                echo "   ❌ Encontrados " . count($invalid) . " item_id inválidos:\n";
                foreach ($invalid as $row) {
                    echo "      - {$row->item_id}\n";
                }
                throw new \Exception('Datos inconsistentes. Corrija manualmente antes de ejecutar.');
            }
        }

        // Cambiar tipo de dato
        $sql = <<<SQL
            ALTER TABLE selemti.inventory_count_lines
            ALTER COLUMN item_id TYPE VARCHAR(20) USING item_id::VARCHAR;
        SQL;

        DB::connection('pgsql')->statement($sql);

        echo "✓ inventory_count_lines.item_id: BIGINT → VARCHAR(20)\n";
    }

    protected function checkOtherTables(): void
    {
        // Listar otras tablas que podrían tener el mismo problema
        $sql = <<<SQL
            SELECT 
                c.table_name,
                c.column_name,
                c.data_type
            FROM information_schema.columns c
            WHERE c.table_schema = 'selemti'
              AND c.column_name = 'item_id'
              AND c.data_type IN ('bigint', 'integer')
              AND c.table_name NOT IN (
                  'inventory_count_lines',
                  'item_vendor',
                  'item_proveedor'
              )
            ORDER BY c.table_name;
        SQL;

        $tables = DB::connection('pgsql')->select($sql);

        if (count($tables) > 0) {
            echo "\n⚠️  OTRAS TABLAS CON item_id NUMERICO:\n";
            foreach ($tables as $table) {
                $countSql = "SELECT COUNT(*) as cnt FROM selemti.{$table->table_name}";
                $result = DB::connection('pgsql')->selectOne($countSql);
                
                echo "   • {$table->table_name}.item_id ({$table->data_type})";
                echo " - {$result->cnt} registros\n";
            }
            echo "\n   💡 RECOMENDACIÓN: Revisar estas tablas manualmente\n";
        } else {
            echo "✓ No se encontraron otras tablas con item_id numérico\n";
        }
    }
};
