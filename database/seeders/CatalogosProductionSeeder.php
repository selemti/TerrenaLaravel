<?php

namespace Database\Seeders;

use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CatalogosProductionSeeder extends Seeder
{
    public function run(): void
    {
        DB::connection('pgsql')->beginTransaction();

        try {
            $this->seedUnidades();
            $this->seedSucursales();
            $this->seedAlmacenes();
            $this->seedCategorias();
            $this->seedProveedores();

            DB::connection('pgsql')->commit();

            $this->command?->info('✅ Catálogos de producción cargados.');
        } catch (\Throwable $exception) {
            DB::connection('pgsql')->rollBack();
            $this->command?->error('❌ Error sembrando catálogos: ' . $exception->getMessage());
            throw $exception;
        }
    }

    private function seedUnidades(): void
    {
        $now = Carbon::now();

        $canonicas = [
            ['clave' => 'KG', 'nombre' => 'Kilogramo'],
            ['clave' => 'GR', 'nombre' => 'Gramo'],
            ['clave' => 'LT', 'nombre' => 'Litro'],
            ['clave' => 'ML', 'nombre' => 'Mililitro'],
            ['clave' => 'L', 'nombre' => 'Litro (legacy)'],
            ['clave' => 'PZ', 'nombre' => 'Pieza'],
            ['clave' => 'PZA', 'nombre' => 'Pieza (legacy)'],
            ['clave' => 'PAQ', 'nombre' => 'Paquete'],
            ['clave' => 'CAJ', 'nombre' => 'Caja'],
        ];

        $canonicasRows = array_map(fn ($unidad) => array_merge($unidad, [
            'activo' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]), $canonicas);

        $this->upsertRows(
            'selemti.cat_unidades',
            $canonicasRows,
            ['clave'],
            ['nombre', 'activo', 'updated_at']
        );

        if ($this->tableExists('selemti.unidades_medida_legacy')) {
            $legacyRows = [
                ['codigo' => 'KG', 'nombre' => 'Kilogramo', 'tipo' => 'PESO', 'categoria' => 'METRICO', 'es_base' => true, 'factor_conversion_base' => 1.0, 'decimales' => 3],
                ['codigo' => 'GR', 'nombre' => 'Gramo', 'tipo' => 'PESO', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 0.001, 'decimales' => 2],
                ['codigo' => 'MG', 'nombre' => 'Miligramo', 'tipo' => 'PESO', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 0.000001, 'decimales' => 0],
                ['codigo' => 'LB', 'nombre' => 'Libra', 'tipo' => 'PESO', 'categoria' => 'IMPERIAL', 'es_base' => false, 'factor_conversion_base' => 0.453592, 'decimales' => 3],
                ['codigo' => 'OZ', 'nombre' => 'Onza', 'tipo' => 'PESO', 'categoria' => 'IMPERIAL', 'es_base' => false, 'factor_conversion_base' => 0.02835, 'decimales' => 2],
                ['codigo' => 'LT', 'nombre' => 'Litro', 'tipo' => 'VOLUMEN', 'categoria' => 'METRICO', 'es_base' => true, 'factor_conversion_base' => 1.0, 'decimales' => 3],
                ['codigo' => 'ML', 'nombre' => 'Mililitro', 'tipo' => 'VOLUMEN', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 0.001, 'decimales' => 0],
                ['codigo' => 'CUP', 'nombre' => 'Taza', 'tipo' => 'VOLUMEN', 'categoria' => 'CULINARIO', 'es_base' => false, 'factor_conversion_base' => 0.24, 'decimales' => 2],
                ['codigo' => 'CDSP', 'nombre' => 'Cucharada Sopera', 'tipo' => 'VOLUMEN', 'categoria' => 'CULINARIO', 'es_base' => false, 'factor_conversion_base' => 0.015, 'decimales' => 1],
                ['codigo' => 'CDTA', 'nombre' => 'Cucharadita', 'tipo' => 'VOLUMEN', 'categoria' => 'CULINARIO', 'es_base' => false, 'factor_conversion_base' => 0.005, 'decimales' => 1],
                ['codigo' => 'FLOZ', 'nombre' => 'Onza Fluida', 'tipo' => 'VOLUMEN', 'categoria' => 'IMPERIAL', 'es_base' => false, 'factor_conversion_base' => 0.029574, 'decimales' => 2],
                ['codigo' => 'GAL', 'nombre' => 'Galón', 'tipo' => 'VOLUMEN', 'categoria' => 'IMPERIAL', 'es_base' => false, 'factor_conversion_base' => 3.78541, 'decimales' => 3],
                ['codigo' => 'PZ', 'nombre' => 'Pieza', 'tipo' => 'UNIDAD', 'categoria' => 'METRICO', 'es_base' => true, 'factor_conversion_base' => 1.0, 'decimales' => 0],
                ['codigo' => 'PZA', 'nombre' => 'Pieza', 'tipo' => 'UNIDAD', 'categoria' => 'METRICO', 'es_base' => true, 'factor_conversion_base' => 1.0, 'decimales' => 0],
                ['codigo' => 'PAQ', 'nombre' => 'Paquete', 'tipo' => 'UNIDAD', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 1.0, 'decimales' => 0],
                ['codigo' => 'CAJA', 'nombre' => 'Caja', 'tipo' => 'UNIDAD', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 1.0, 'decimales' => 0],
                ['codigo' => 'PORC', 'nombre' => 'Porción', 'tipo' => 'UNIDAD', 'categoria' => 'CULINARIO', 'es_base' => false, 'factor_conversion_base' => 1.0, 'decimales' => 0],
            ];

            $legacyRows = array_map(static function (array $row) use ($now) {
                return array_merge($row, [
                    'created_at' => $now,
                ]);
            }, $legacyRows);

            $this->upsertRows(
                'selemti.unidades_medida_legacy',
                $legacyRows,
                ['codigo'],
                ['nombre', 'tipo', 'categoria', 'es_base', 'factor_conversion_base', 'decimales']
            );
        }

        $this->command?->info('  ➜ Unidades: ' . count($canonicasRows) . ' registros.');
    }

    private function seedSucursales(): void
    {
        $now = Carbon::now();

        $sucursales = [
            [
                'clave' => 'SUC-01',
                'nombre' => 'Sucursal Principal',
                'ubicacion' => 'Pendiente de registrar',
                'activo' => true,
            ],
        ];

        $rows = array_map(fn ($sucursal) => array_merge($sucursal, [
            'created_at' => $now,
            'updated_at' => $now,
        ]), $sucursales);

        $this->upsertRows(
            'selemti.cat_sucursales',
            $rows,
            ['clave'],
            ['nombre', 'ubicacion', 'activo', 'updated_at']
        );

        $this->command?->info('  ➜ Sucursales: ' . count($rows) . ' registros.');
    }

    private function seedAlmacenes(): void
    {
        $now = Carbon::now();

        $sucursalId = DB::connection('pgsql')
            ->table('selemti.cat_sucursales')
            ->where('clave', 'SUC-01')
            ->value('id');

        if (! $sucursalId) {
            $this->command?->warn('  ⚠️  No se encontró la sucursal SUC-01, se omiten almacenes.');

            return;
        }

        $almacenes = [
            [
                'clave' => 'ALM-GEN',
                'nombre' => 'Almacén General',
                'sucursal_id' => $sucursalId,
                'activo' => true,
            ],
            [
                'clave' => 'ALM-FRIO',
                'nombre' => 'Almacén Refrigerados',
                'sucursal_id' => $sucursalId,
                'activo' => true,
            ],
        ];

        $rows = array_map(fn ($almacen) => array_merge($almacen, [
            'created_at' => $now,
            'updated_at' => $now,
        ]), $almacenes);

        $this->upsertRows(
            'selemti.cat_almacenes',
            $rows,
            ['clave'],
            ['nombre', 'sucursal_id', 'activo', 'updated_at']
        );

        $this->command?->info('  ➜ Almacenes: ' . count($rows) . ' registros.');
    }

    private function seedCategorias(): void
    {
        $now = Carbon::now();

        $categorias = [
            ['codigo' => 'CAT-CAR', 'nombre' => 'Carnes', 'prefijo' => 'CAR'],
            ['codigo' => 'CAT-LAC', 'nombre' => 'Lácteos', 'prefijo' => 'LAC'],
            ['codigo' => 'CAT-VEG', 'nombre' => 'Vegetales', 'prefijo' => 'VEG'],
            ['codigo' => 'CAT-HAR', 'nombre' => 'Harinas y Granos', 'prefijo' => 'HAR'],
            ['codigo' => 'CAT-BEB', 'nombre' => 'Bebidas', 'prefijo' => 'BEB'],
            ['codigo' => 'CAT-CON', 'nombre' => 'Condimentos', 'prefijo' => 'CON'],
        ];

        $rows = array_map(function ($categoria) use ($now) {
            return [
                'codigo' => $categoria['codigo'],
                'nombre' => $categoria['nombre'],
                'slug' => Str::slug($categoria['nombre']),
                'prefijo' => $categoria['prefijo'],
                'descripcion' => null,
                'activo' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }, $categorias);

        $this->upsertRows(
            'selemti.item_categories',
            $rows,
            ['codigo'],
            ['nombre', 'slug', 'prefijo', 'activo', 'updated_at']
        );

        $this->command?->info('  ➜ Categorías: ' . count($rows) . ' registros.');
    }

    private function seedProveedores(): void
    {
        $now = Carbon::now();

        $proveedores = [
            [
                'rfc' => 'PGE000101000',
                'nombre' => 'Proveedor General',
                'telefono' => '0000000000',
                'email' => 'proveedor@terrena.com',
                'activo' => true,
            ],
        ];

        $rows = array_map(fn ($proveedor) => array_merge($proveedor, [
            'created_at' => $now,
            'updated_at' => $now,
        ]), $proveedores);

        $this->upsertRows(
            'selemti.cat_proveedores',
            $rows,
            ['rfc'],
            ['nombre', 'telefono', 'email', 'activo', 'updated_at']
        );

        $this->command?->info('  ➜ Proveedores: ' . count($rows) . ' registros.');
    }

    private function tableExists(string $qualifiedTable): bool
    {
        [$schema, $table] = $this->splitQualifiedTable($qualifiedTable);

        $result = DB::connection('pgsql')->selectOne(
            'SELECT table_type FROM information_schema.tables WHERE table_schema = ? AND table_name = ? LIMIT 1',
            [$schema, $table]
        );

        return isset($result->table_type) && strtoupper($result->table_type) === 'BASE TABLE';
    }

    private function upsertRows(string $table, array $rows, array $uniqueBy, array $updateColumns): void
    {
        if (empty($rows)) {
            return;
        }

        $columns = $this->getTableColumns($table);

        if (empty($columns)) {
            return;
        }

        $columnLookup = array_flip($columns);
        $filteredRows = [];

        foreach ($rows as $row) {
            $filtered = array_intersect_key($row, $columnLookup);

            if (! empty($filtered)) {
                $filteredRows[] = $filtered;
            }
        }

        if (empty($filteredRows)) {
            return;
        }

        $filteredUpdateColumns = array_values(array_intersect($updateColumns, $columns));

        if (empty($filteredUpdateColumns)) {
            $filteredUpdateColumns = array_values(array_diff(array_keys($filteredRows[0]), $uniqueBy));
        }

        $builder = DB::connection('pgsql')->table($table);

        if (empty($filteredUpdateColumns)) {
            $builder->insertOrIgnore($filteredRows);

            return;
        }

        $builder->upsert($filteredRows, $uniqueBy, $filteredUpdateColumns);
    }

    private function getTableColumns(string $qualifiedTable): array
    {
        [$schema, $table] = $this->splitQualifiedTable($qualifiedTable);

        $results = DB::connection('pgsql')->select(
            'SELECT column_name FROM information_schema.columns WHERE table_schema = ? AND table_name = ?',
            [$schema, $table]
        );

        return array_map(static fn ($row) => $row->column_name, $results);
    }

    private function splitQualifiedTable(string $qualifiedTable): array
    {
        if (str_contains($qualifiedTable, '.')) {
            return explode('.', $qualifiedTable, 2);
        }

        return ['public', $qualifiedTable];
    }
}
