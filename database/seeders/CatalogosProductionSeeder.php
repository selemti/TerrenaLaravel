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

        $unidades = [
            ['clave' => 'KG', 'nombre' => 'Kilogramo'],
            ['clave' => 'GR', 'nombre' => 'Gramo'],
            ['clave' => 'LT', 'nombre' => 'Litro'],
            ['clave' => 'ML', 'nombre' => 'Mililitro'],
            ['clave' => 'PZ', 'nombre' => 'Pieza'],
            ['clave' => 'PAQ', 'nombre' => 'Paquete'],
            ['clave' => 'CAJ', 'nombre' => 'Caja'],
        ];

        $rows = array_map(fn ($unidad) => array_merge($unidad, [
            'activo' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]), $unidades);

        $this->upsertRows(
            'selemti.cat_unidades',
            $rows,
            ['clave'],
            ['nombre', 'activo', 'updated_at']
        );

        $this->command?->info('  ➜ Unidades: ' . count($rows) . ' registros.');
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
