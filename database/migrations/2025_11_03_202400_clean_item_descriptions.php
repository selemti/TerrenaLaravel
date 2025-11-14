<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Limpia descripciones de items que contienen información de presentación
     * La presentación debe estar SOLO en item_vendor, NO en items.descripcion
     */
    public function up(): void
    {
        DB::connection('pgsql')->statement('SET search_path TO selemti');

        echo "Limpiando descripciones con información de presentación...\n";

        // Casos detectados:
        $corrections = [
            // Aceite Nutrioli
            [
                'id' => 'ACEITE-NUTRIOLI-01',
                'old_desc' => 'Aceite vegetal de soya, presentación 3 pzas de 946 ml',
                'new_desc' => 'Aceite vegetal de soya 100% puro',
            ],
            [
                'id' => 'ACEITE-NUT-01',
                'old_desc' => 'Aceite vegetal 3 pzas × 946 ml (2.838 L total)',
                'new_desc' => 'Aceite vegetal de soya 100% puro',
            ],
            // Leche Member's Mark
            [
                'id' => 'LECHE-MEMBERS-01',
                'old_desc' => 'Leche deslactosada marca Member\'s Mark, presentación 12 pzas de 1 L',
                'new_desc' => 'Leche deslactosada reducida en lactosa',
            ],
            [
                'id' => 'LECHE-MEM-01',
                'old_desc' => 'Leche deslactosada marca Member\'s Mark, presentación 12 pzas de 1 L (12 L total)',
                'new_desc' => 'Leche deslactosada reducida en lactosa',
            ],
            // Leche Nutri
            [
                'id' => 'LECHE-NUTRI-01',
                'old_desc' => 'Producto lácteo deslactosado, presentación 12 pzas de 1.5 L',
                'new_desc' => 'Producto lácteo deslactosado sabor natural',
            ],
            [
                'id' => 'LECHE-NUT-01',
                'old_desc' => 'Producto lácteo 12 pzas × 1.5 L (18 L total)',
                'new_desc' => 'Producto lácteo deslactosado sabor natural',
            ],
        ];

        $updated = 0;
        foreach ($corrections as $item) {
            // Verificar que existe
            $exists = DB::connection('pgsql')
                ->table('selemti.items')
                ->where('id', $item['id'])
                ->exists();

            if (! $exists) {
                echo "  ⊘ {$item['id']}: no existe\n";

                continue;
            }

            // Actualizar
            DB::connection('pgsql')
                ->table('selemti.items')
                ->where('id', $item['id'])
                ->update([
                    'descripcion' => $item['new_desc'],
                    'updated_at' => now(),
                ]);

            echo "  ✓ {$item['id']}: descripción limpiada\n";
            $updated++;
        }

        echo "\n✅ Limpiados {$updated} items\n";
        echo "💡 Las presentaciones ahora deben capturarse en item_vendor\n";
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No revertir - son correcciones de datos
        echo "⚠️  No se puede revertir - correcciones de estructura\n";
    }
};
