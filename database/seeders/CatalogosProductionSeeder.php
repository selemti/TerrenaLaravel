<?php

namespace Database\Seeders;

use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CatalogosProductionSeeder extends Seeder
{
    public function run(): void
    {
        DB::connection('pgsql')->beginTransaction();

        try {
            $this->seedUnidadesMedida();
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

    private function seedUnidadesMedida(): void
    {
        $now = Carbon::now();

        $unidades = [
            ['codigo' => 'KG', 'nombre' => 'Kilogramo', 'tipo' => 'BASE', 'categoria' => 'MASA', 'es_base' => true, 'factor' => 1.0, 'decimales' => 3],
            ['codigo' => 'GR', 'nombre' => 'Gramo', 'tipo' => 'BASE', 'categoria' => 'MASA', 'es_base' => false, 'factor' => 0.001, 'decimales' => 2],
            ['codigo' => 'LT', 'nombre' => 'Litro', 'tipo' => 'BASE', 'categoria' => 'VOLUMEN', 'es_base' => true, 'factor' => 1.0, 'decimales' => 3],
            ['codigo' => 'ML', 'nombre' => 'Mililitro', 'tipo' => 'BASE', 'categoria' => 'VOLUMEN', 'es_base' => false, 'factor' => 0.001, 'decimales' => 2],
            ['codigo' => 'PZ', 'nombre' => 'Pieza', 'tipo' => 'BASE', 'categoria' => 'UNIDAD', 'es_base' => true, 'factor' => 1.0, 'decimales' => 0],
            ['codigo' => 'PAQ', 'nombre' => 'Paquete', 'tipo' => 'COMPRA', 'categoria' => 'UNIDAD', 'es_base' => false, 'factor' => 1.0, 'decimales' => 0],
            ['codigo' => 'CAJ', 'nombre' => 'Caja', 'tipo' => 'COMPRA', 'categoria' => 'UNIDAD', 'es_base' => false, 'factor' => 1.0, 'decimales' => 0],
        ];

        foreach ($unidades as $unidad) {
            DB::connection('pgsql')->table('selemti.unidades_medida')->updateOrInsert(
                ['codigo' => $unidad['codigo']],
                [
                    'nombre' => $unidad['nombre'],
                    'tipo' => $unidad['tipo'],
                    'categoria' => $unidad['categoria'],
                    'es_base' => $unidad['es_base'],
                    'factor_conversion_base' => $unidad['factor'],
                    'decimales' => $unidad['decimales'],
                    'activo' => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]
            );
        }

        $this->command?->info('  ➜ Unidades de medida: 7 registros.');
    }

    private function seedSucursales(): void
    {
        $now = Carbon::now();

        $sucursales = [
            [
                'clave' => 'SUC-01',
                'nombre' => 'Sucursal Principal',
                'rfc' => 'XAXX010101000',
                'direccion' => 'Por definir',
                'telefono' => '0000000000',
                'email' => 'principal@terrena.com',
                'activo' => true,
            ],
        ];

        foreach ($sucursales as $sucursal) {
            DB::connection('pgsql')->table('selemti.cat_sucursales')->updateOrInsert(
                ['clave' => $sucursal['clave']],
                array_merge($sucursal, ['created_at' => $now, 'updated_at' => $now])
            );
        }

        $this->command?->info('  ➜ Sucursales: 1 registro.');
    }

    private function seedAlmacenes(): void
    {
        $now = Carbon::now();

        $sucursalId = DB::connection('pgsql')
            ->table('selemti.cat_sucursales')
            ->where('clave', 'SUC-01')
            ->value('id');

        if (! $sucursalId) {
            return;
        }

        $almacenes = [
            [
                'sucursal_id' => $sucursalId,
                'nombre' => 'Almacén General',
                'tipo' => 'GENERAL',
                'activo' => true,
            ],
            [
                'sucursal_id' => $sucursalId,
                'nombre' => 'Almacén Refrigerados',
                'tipo' => 'FRIO',
                'activo' => true,
            ],
        ];

        foreach ($almacenes as $almacen) {
            DB::connection('pgsql')->table('selemti.cat_almacenes')->updateOrInsert(
                ['sucursal_id' => $almacen['sucursal_id'], 'nombre' => $almacen['nombre']],
                array_merge($almacen, ['created_at' => $now, 'updated_at' => $now])
            );
        }

        $this->command?->info('  ➜ Almacenes: 2 registros.');
    }

    private function seedCategorias(): void
    {
        $now = Carbon::now();

        $categorias = [
            ['codigo' => 'CAR', 'nombre' => 'Carnes', 'prefijo' => 'CAR'],
            ['codigo' => 'LAC', 'nombre' => 'Lácteos', 'prefijo' => 'LAC'],
            ['codigo' => 'VEG', 'nombre' => 'Vegetales', 'prefijo' => 'VEG'],
            ['codigo' => 'HAR', 'nombre' => 'Harinas y Granos', 'prefijo' => 'HAR'],
            ['codigo' => 'BEB', 'nombre' => 'Bebidas', 'prefijo' => 'BEB'],
            ['codigo' => 'CON', 'nombre' => 'Condimentos', 'prefijo' => 'CON'],
        ];

        foreach ($categorias as $categoria) {
            DB::connection('pgsql')->table('selemti.item_categories')->updateOrInsert(
                ['codigo' => $categoria['codigo']],
                array_merge($categoria, ['created_at' => $now, 'updated_at' => $now])
            );
        }

        $this->command?->info('  ➜ Categorías: 6 registros.');
    }

    private function seedProveedores(): void
    {
        $now = Carbon::now();

        $proveedores = [
            [
                'nombre_comercial' => 'Proveedor General',
                'razon_social' => 'Proveedor General S.A. de C.V.',
                'rfc' => 'PGE000101000',
                'tipo' => 'GENERAL',
                'activo' => true,
            ],
        ];

        foreach ($proveedores as $proveedor) {
            DB::connection('pgsql')->table('selemti.cat_proveedores')->updateOrInsert(
                ['rfc' => $proveedor['rfc']],
                array_merge($proveedor, ['created_at' => $now, 'updated_at' => $now])
            );
        }

        $this->command?->info('  ➜ Proveedores: 1 registro.');
    }
}
