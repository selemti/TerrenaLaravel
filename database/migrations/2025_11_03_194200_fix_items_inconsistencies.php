<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $exists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='items' LIMIT 1"
        );
        if (! $exists) {
            return;
        }

        DB::connection('pgsql')->statement('SET search_path TO selemti');

        // 1. Backfill unidad_medida_id para items que solo tienen unidad_medida (legacy)
        $this->backfillUnidadMedidaId();

        // 2. Completar campo tipo para items sin tipo
        $this->backfillTipo();

        // 3. Asegurar que todos los items tengan category_id consistente
        $this->fixCategoryIds();

        // 4. Normalizar códigos de unidades legacy LT → L
        $this->normalizeUnidadMedida();
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No revertir, son correcciones de datos
    }

    protected function backfillUnidadMedidaId(): void
    {
        $sql = <<<'SQL'
            UPDATE selemti.items i
            SET unidad_medida_id = u.id
            FROM selemti.cat_unidades u
            WHERE i.unidad_medida_id IS NULL
              AND i.unidad_medida IS NOT NULL
              AND u.clave = CASE 
                  WHEN i.unidad_medida = 'LT' THEN 'L'
                  WHEN i.unidad_medida = 'PZ' THEN 'PZ'
                  WHEN i.unidad_medida = 'KG' THEN 'KG'
                  ELSE i.unidad_medida
              END;
        SQL;

        $affected = DB::connection('pgsql')->affectingStatement($sql);
        echo "✓ Backfilled unidad_medida_id para {$affected} items\n";
    }

    protected function backfillTipo(): void
    {
        $sql = <<<'SQL'
            UPDATE selemti.items
            SET tipo = 'MATERIA_PRIMA'
            WHERE tipo IS NULL
              AND categoria_id IN ('CAT-0001', 'CAT-MP', 'CAT-LACT', 'CAT-ABARR');
        SQL;

        DB::connection('pgsql')->statement($sql);

        $sql2 = <<<'SQL'
            UPDATE selemti.items
            SET tipo = 'ELABORADO'
            WHERE tipo IS NULL
              AND categoria_id IN ('CAT-0002', 'CAT-PT', 'CAT-ELAB');
        SQL;

        DB::connection('pgsql')->statement($sql2);

        // Para items sin categoría clara
        $sql3 = <<<'SQL'
            UPDATE selemti.items
            SET tipo = 'MATERIA_PRIMA'
            WHERE tipo IS NULL;
        SQL;

        DB::connection('pgsql')->statement($sql3);

        echo "✓ Completado campo tipo para items\n";
    }

    protected function fixCategoryIds(): void
    {
        // Primero obtener el mapeo real de categorías
        $categories = DB::connection('pgsql')
            ->table('selemti.item_categories')
            ->get(['id', 'nombre'])
            ->keyBy('nombre');

        // Mapear categorías legacy a nombres y luego a IDs
        $mappings = [
            'CAT-LACT' => 'Lácteos',
            'CAT-ABARR' => 'Abarrotes',
        ];

        foreach ($mappings as $catId => $nombre) {
            if (isset($categories[$nombre])) {
                $numId = $categories[$nombre]->id;

                $sql = <<<'SQL'
                    UPDATE selemti.items
                    SET category_id = ?
                    WHERE categoria_id = ?
                      AND (category_id IS NULL OR category_id != ?);
                SQL;

                $affected = DB::connection('pgsql')->update($sql, [$numId, $catId, $numId]);
                echo "✓ Actualizados {$affected} items: {$catId} → category_id={$numId}\n";
            }
        }

        // Para items sin categoría específica, usar la primera disponible
        $firstCat = DB::connection('pgsql')
            ->table('selemti.item_categories')
            ->where('activo', true)
            ->orderBy('id')
            ->first();

        if ($firstCat) {
            $sql = <<<'SQL'
                UPDATE selemti.items
                SET category_id = ?
                WHERE category_id IS NULL;
            SQL;

            $affected = DB::connection('pgsql')->update($sql, [$firstCat->id]);
            if ($affected > 0) {
                echo "✓ Asignados {$affected} items sin categoría a: {$firstCat->nombre}\n";
            }
        }
    }

    protected function normalizeUnidadMedida(): void
    {
        // Primero eliminar el constraint temporalmente
        DB::connection('pgsql')->statement(
            'ALTER TABLE selemti.items DROP CONSTRAINT IF EXISTS items_unidad_medida_check'
        );

        echo "✓ Constraint eliminado temporalmente\n";

        // Actualizar los datos LT → L
        $sqlUpdate = <<<'SQL'
            UPDATE selemti.items
            SET unidad_medida = 'L'
            WHERE unidad_medida = 'LT';
        SQL;

        $affected = DB::connection('pgsql')->update($sqlUpdate);
        echo "✓ Actualizado {$affected} registros: unidad_medida LT → L\n";

        // Recrear el constraint con los valores correctos
        DB::connection('pgsql')->statement(<<<'SQL'
            ALTER TABLE selemti.items
            ADD CONSTRAINT items_unidad_medida_check
            CHECK (unidad_medida IN ('KG', 'L', 'PZ', 'BULTO', 'CAJA'))
        SQL);

        echo "✓ Constraint recreado: ahora usa 'L' en lugar de 'LT'\n";
    }
};
