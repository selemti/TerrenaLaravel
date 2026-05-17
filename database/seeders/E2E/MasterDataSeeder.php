<?php

namespace Database\Seeders\E2E;

use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Siembra los datos maestros necesarios para la corrida E2E:
 * - cat_unidades (UOMs canónicas)
 * - cat_sucursales + cat_almacenes
 * - item_categories
 * - cat_proveedores
 * - items (25 insumos con UOM y factor_compra)
 * - recipes + recipe_versions + recipe_version_items (8 recetas con sub-recetas)
 *
 * Idempotente: usa updateOrInsert. Seguro de re-ejecutar.
 */
class MasterDataSeeder extends Seeder
{
    private Carbon $now;

    public function run(): void
    {
        $this->now = Carbon::now();

        DB::connection('pgsql')->beginTransaction();

        try {
            $this->seedUoms();
            $this->seedSucursalesAlmacenes();
            $this->seedCategorias();
            $this->seedProveedores();
            $this->seedItems();
            $this->seedRecetas();
            $this->seedPosModifierMapping();

            DB::connection('pgsql')->commit();
            $this->command?->info('✅ MasterDataSeeder completado.');
        } catch (\Throwable $e) {
            DB::connection('pgsql')->rollBack();
            $this->command?->error('❌ MasterDataSeeder falló: '.$e->getMessage());
            throw $e;
        }
    }

    // -------------------------------------------------------------------------

    private function seedUoms(): void
    {
        $uoms = [
            ['clave' => 'KG',  'nombre' => 'Kilogramo',  'categoria' => 'BASE'],
            ['clave' => 'L',   'nombre' => 'Litro',       'categoria' => 'BASE'],
            ['clave' => 'PZ',  'nombre' => 'Pieza',       'categoria' => 'BASE'],
            ['clave' => 'GR',  'nombre' => 'Gramo',       'categoria' => 'BASE'],
            ['clave' => 'ML',  'nombre' => 'Mililitro',   'categoria' => 'BASE'],
            ['clave' => 'PAQ', 'nombre' => 'Paquete',     'categoria' => 'COMPRA'],
            ['clave' => 'CAJ', 'nombre' => 'Caja',        'categoria' => 'COMPRA'],
        ];

        foreach ($uoms as $uom) {
            DB::connection('pgsql')->table('selemti.cat_unidades')->updateOrInsert(
                ['clave' => $uom['clave']],
                array_merge($uom, ['activo' => true, 'created_at' => $this->now, 'updated_at' => $this->now])
            );
        }

        $this->command?->info('  ➜ cat_unidades: '.count($uoms).' registros.');
    }

    private function seedSucursalesAlmacenes(): void
    {
        DB::connection('pgsql')->table('selemti.cat_sucursales')->updateOrInsert(
            ['clave' => 'SUC-01'],
            [
                'clave' => 'SUC-01',
                'nombre' => 'Terrena Centro',
                'ubicacion' => 'Av. Reforma 100, Col. Centro',
                'activo' => true,
                'created_at' => $this->now, 'updated_at' => $this->now,
            ]
        );

        $sucursalId = DB::connection('pgsql')
            ->table('selemti.cat_sucursales')->where('clave', 'SUC-01')->value('id');

        $almacenes = [
            ['clave' => 'ALM-GEN', 'nombre' => 'Almacén General'],
            ['clave' => 'ALM-COC', 'nombre' => 'Cocina'],
        ];

        foreach ($almacenes as $alm) {
            DB::connection('pgsql')->table('selemti.cat_almacenes')->updateOrInsert(
                ['sucursal_id' => $sucursalId, 'nombre' => $alm['nombre']],
                [
                    'clave' => $alm['clave'],
                    'nombre' => $alm['nombre'],
                    'sucursal_id' => $sucursalId,
                    'activo' => true,
                    'created_at' => $this->now, 'updated_at' => $this->now,
                ]
            );
        }

        $this->command?->info('  ➜ Sucursales: 1 | Almacenes: 2.');
    }

    private function seedCategorias(): void
    {
        $cats = [
            ['codigo' => 'CARNES',      'nombre' => 'Carnes y Aves'],
            ['codigo' => 'LACTEOS',     'nombre' => 'Lácteos y Derivados'],
            ['codigo' => 'VEGETALES',   'nombre' => 'Vegetales y Hortalizas'],
            ['codigo' => 'ABARROTES',   'nombre' => 'Abarrotes y Granos'],
            ['codigo' => 'BEBIDAS',     'nombre' => 'Bebidas'],
            ['codigo' => 'CONDIMENTOS', 'nombre' => 'Condimentos y Especias'],
        ];

        foreach ($cats as $cat) {
            DB::connection('pgsql')->table('selemti.item_categories')->updateOrInsert(
                ['codigo' => $cat['codigo']],
                array_merge($cat, ['created_at' => $this->now, 'updated_at' => $this->now])
            );
        }

        $this->command?->info('  ➜ Categorías: '.count($cats).'.');
    }

    private function seedProveedores(): void
    {
        $data = require __DIR__.'/RestaurantDataArrays.php';
        $provs = $data['proveedores'];

        foreach ($provs as $prov) {
            DB::connection('pgsql')->table('selemti.cat_proveedores')->updateOrInsert(
                ['rfc' => $prov['rfc']],
                [
                    'nombre' => $prov['nombre'],
                    'razon_social' => $prov['nombre'],
                    'rfc' => $prov['rfc'],
                    'activo' => true,
                    'created_at' => $this->now, 'updated_at' => $this->now,
                ]
            );
        }

        $this->command?->info('  ➜ Proveedores: '.count($provs).'.');
    }

    private function seedItems(): void
    {
        $data = require __DIR__.'/RestaurantDataArrays.php';
        $items = $data['items'];

        $uomIds = DB::connection('pgsql')
            ->table('selemti.cat_unidades')
            ->pluck('id', 'clave');

        $insumoIdx = 0;
        $producibleIdx = 0;

        foreach ($items as $item) {
            $esProducible = (bool) ($item['es_producible'] ?? false);

            // Insumos: IDs 1001–1025  |  Producibles: IDs 2001–2015
            if ($esProducible) {
                $numericId = (string) (2001 + $producibleIdx);
                $producibleIdx++;
            } else {
                $numericId = (string) (1001 + $insumoIdx);
                $insumoIdx++;
            }

            $uomBaseId = $uomIds[$item['uom_base']] ?? null;
            $uomCompraId = $uomIds[$item['uom_compra']] ?? null;

            DB::connection('pgsql')->table('selemti.items')->updateOrInsert(
                ['item_code' => $item['codigo']],
                [
                    'id' => $numericId,
                    'item_code' => $item['codigo'],
                    'codigo' => $item['codigo'],
                    'clave' => $item['codigo'],
                    'nombre' => $item['nombre'],
                    'categoria_id' => $item['categoria'],
                    'unidad_medida' => $item['uom_base'],
                    'unidad_medida_id' => $uomBaseId,
                    'unidad_compra_id' => $uomCompraId,
                    'factor_compra' => $item['factor_compra'],
                    'costo_promedio' => $item['costo_promedio'],
                    'activo' => true,
                    'perishable' => in_array($item['categoria'], ['CARNES', 'LACTEOS', 'VEGETALES']),
                    'es_consumible_operativo' => false,
                    'es_producible' => $esProducible,
                    'tipo_venta_pos' => $item['tipo_venta_pos'] ?? null,
                    'created_at' => $this->now, 'updated_at' => $this->now,
                ]
            );
        }

        $this->command?->info("  ➜ Items: {$insumoIdx} insumos + {$producibleIdx} producibles.");
    }

    private function seedRecetas(): void
    {
        $data = require __DIR__.'/RestaurantDataArrays.php';
        $recetas = $data['recetas'];

        // Resolve item ids by codigo (items.id = codigo string)
        $itemIds = DB::connection('pgsql')
            ->table('selemti.items')
            ->pluck('id', 'codigo'); // id is varchar = codigo

        $uomIds = DB::connection('pgsql')
            ->table('selemti.cat_unidades')
            ->pluck('id', 'clave');

        // First pass: insert recipe headers (needed for sub_recipe_id FK)
        $recipeDbIds = [];
        foreach ($recetas as $receta) {
            DB::connection('pgsql')->table('selemti.recipes')->updateOrInsert(
                ['codigo' => $receta['codigo']],
                [
                    'codigo' => $receta['codigo'],
                    'nombre' => $receta['nombre'],
                    'tipo' => $receta['tipo'],
                    'yield_portions' => $receta['porciones'],
                    'uom_salida' => $receta['uom_salida'] ?? 'PZ',
                    'activo' => true,
                    'meta' => json_encode([
                        'tiempo_min' => $receta['tiempo_min'] ?? null,
                        'item_producido_codigo' => $receta['item_producido_codigo'] ?? $receta['item_producido'] ?? null,
                        'item_producido' => $receta['item_producido'] ?? $receta['item_producido_codigo'] ?? null,
                    ]),
                    'created_at' => $this->now, 'updated_at' => $this->now,
                ]
            );

            $recipeDbIds[$receta['codigo']] = DB::connection('pgsql')
                ->table('selemti.recipes')
                ->where('codigo', $receta['codigo'])
                ->value('id');
        }

        // Second pass: insert versions + ingredient lines
        foreach ($recetas as $receta) {
            $recipeId = $recipeDbIds[$receta['codigo']];

            // Version
            $existsVersion = DB::connection('pgsql')
                ->table('selemti.recipe_versions')
                ->where('recipe_id', $recipeId)
                ->where('version_no', 1)
                ->exists();

            if (! $existsVersion) {
                DB::connection('pgsql')->table('selemti.recipe_versions')->insert([
                    'recipe_id' => $recipeId,
                    'version_no' => 1,
                    'notes' => 'Versión inicial corrida E2E',
                    'valid_from' => now()->subDays(14)->toDateString(),
                    'valid_to' => null,
                    'created_at' => $this->now,
                ]);
            }

            $versionId = DB::connection('pgsql')
                ->table('selemti.recipe_versions')
                ->where('recipe_id', $recipeId)
                ->where('version_no', 1)
                ->value('id');

            // Clear existing lines (idempotent)
            DB::connection('pgsql')
                ->table('selemti.recipe_version_items')
                ->where('recipe_version_id', $versionId)
                ->delete();

            // Ingredient lines (items)
            foreach ($receta['ingredientes'] as $ing) {
                DB::connection('pgsql')->table('selemti.recipe_version_items')->insert([
                    'recipe_version_id' => $versionId,
                    'item_id' => $itemIds[$ing['item_codigo']] ?? null,
                    'sub_recipe_id' => null,
                    'qty' => $ing['qty'],
                    'uom_receta' => $ing['uom'],
                ]);
            }

            // Sub-recipe lines
            foreach ($receta['sub_recetas'] as $sub) {
                DB::connection('pgsql')->table('selemti.recipe_version_items')->insert([
                    'recipe_version_id' => $versionId,
                    'item_id' => null,
                    'sub_recipe_id' => $recipeDbIds[$sub['sub_recipe_codigo']] ?? null,
                    'qty' => $sub['qty'],
                    'uom_receta' => $sub['uom'],
                ]);
            }
        }

        $platillos = count(array_filter($recetas, fn ($r) => $r['tipo'] === 'PLATILLO'));
        $prodRecetas = count(array_filter($recetas, fn ($r) => str_starts_with($r['tipo'], 'PROD_')));
        $this->command?->info("  ➜ Recetas: {$platillos} platillos + {$prodRecetas} producción.");
    }

    private function seedPosModifierMapping(): void
    {
        $data = require __DIR__.'/RestaurantDataArrays.php';

        // Verificar que las tablas de mapping existen antes de sembrar
        $tableExists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='pos_modifier_inv_mapping'"
        );

        if (! $tableExists) {
            $this->command?->warn('  ⚠ pos_modifier_inv_mapping no existe — omitiendo (ejecutar migración Gemini phase1-pos-modifier-tables primero).');

            return;
        }

        // Resolver item_ids por codigo
        $itemIds = DB::connection('pgsql')
            ->table('selemti.items')
            ->pluck('id', 'codigo');

        $mappings = $data['pos_modifier_mapping'] ?? [];
        $inserted = 0;

        foreach ($mappings as $m) {
            $itemId = $m['item_codigo'] !== null ? ($itemIds[$m['item_codigo']] ?? null) : null;

            DB::connection('pgsql')->table('selemti.pos_modifier_inv_mapping')->updateOrInsert(
                ['menu_modifier_id' => $m['menu_modifier_id']],
                [
                    'menu_modifier_id' => $m['menu_modifier_id'],
                    'modifier_name_trim' => $m['modifier_name_trim'],
                    'menu_modifier_group_id' => $m['group_id'],
                    'menu_modifier_group_name' => $m['group_name'],
                    'item_id' => $itemId,
                    'qty_por_unidad' => $m['qty'],
                    'uom' => $m['uom'],
                    'qty_source' => 'MANUAL',
                    'tipo_efecto' => $m['tipo'],
                    'afecta_costo' => true,
                    'activo' => true,
                    'created_at' => $this->now, 'updated_at' => $this->now,
                ]
            );
            $inserted++;
        }

        // Sembrar pos_menu_item_recipe_mapping
        $menuItemMappings = $data['pos_menu_item_recipe_mapping'] ?? [];
        $recipeIds = DB::connection('pgsql')
            ->table('selemti.recipes')
            ->pluck('id', 'codigo');

        $tableExists2 = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='pos_menu_item_recipe_mapping'"
        );

        if ($tableExists2) {
            foreach ($menuItemMappings as $m) {
                $recipeId = $recipeIds[$m['recipe_codigo']] ?? null;
                if (! $recipeId) {
                    continue;
                }

                DB::connection('pgsql')->table('selemti.pos_menu_item_recipe_mapping')->updateOrInsert(
                    ['menu_item_id' => $m['menu_item_id']],
                    [
                        'menu_item_id' => $m['menu_item_id'],
                        'menu_item_name' => $m['menu_item_name'],
                        'recipe_id' => $recipeId,
                        'porciones_por_orden' => $m['porciones_por_orden'],
                        'activo' => true,
                        'created_at' => $this->now, 'updated_at' => $this->now,
                    ]
                );
            }
            $this->command?->info('  ➜ pos_menu_item_recipe_mapping: '.count($menuItemMappings).' registros.');
        }

        $this->command?->info("  ➜ pos_modifier_inv_mapping: {$inserted} registros.");
    }
}
