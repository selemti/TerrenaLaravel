<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class RestaurantCatalogsSeeder extends Seeder
{
    /**
     * Seed restaurant catalogs with realistic data for a multi-location restaurant
     *
     * Este seeder puebla catálogos básicos necesarios para operación de restaurante:
     * - Sucursales (múltiples ubicaciones)
     * - Almacenes (cocina, barra, almacén central, etc.)
     * - Unidades de medida (peso, volumen, unidad, tiempo)
     * - Stock policies (políticas de inventario mínimo/máximo)
     * - Proveedores típicos de restaurantes
     */
    public function run(): void
    {
        $conn = DB::connection('pgsql');

        echo "🏢 Sembrando catálogos de restaurante...\n\n";

        // ===================================================================
        // 1. SUCURSALES
        // ===================================================================
        echo "📍 Creando sucursales...\n";

        $sucursales = [
            ['clave' => 'CENTRO', 'nombre' => 'Terrena Centro Histórico', 'ubicacion' => 'Av. Juárez #123, Centro, CDMX', 'activo' => true],
            ['clave' => 'POLANCO', 'nombre' => 'Terrena Polanco', 'ubicacion' => 'Av. Presidente Masaryk #456, Polanco, CDMX', 'activo' => true],
            ['clave' => 'ROMA', 'nombre' => 'Terrena Roma Norte', 'ubicacion' => 'Calle Orizaba #789, Roma Norte, CDMX', 'activo' => true],
            ['clave' => 'COYOACAN', 'nombre' => 'Terrena Coyoacán', 'ubicacion' => 'Av. México #321, Coyoacán, CDMX', 'activo' => true],
            ['clave' => 'CENTRAL', 'nombre' => 'Centro de Distribución Central', 'ubicacion' => 'Zona Industrial Vallejo, CDMX', 'activo' => true],
        ];

        foreach ($sucursales as $suc) {
            $conn->table('selemti.cat_sucursales')->insert(array_merge($suc, [
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }
        echo "   ✓ " . count($sucursales) . " sucursales creadas\n\n";

        // Get sucursal IDs for almacenes
        $sucursalesMap = $conn->table('selemti.cat_sucursales')
            ->pluck('id', 'clave')
            ->toArray();

        // ===================================================================
        // 2. ALMACENES
        // ===================================================================
        echo "🏪 Creando almacenes...\n";

        $almacenes = [
            // Centro Histórico
            ['clave' => 'CENTRO-COC', 'nombre' => 'Cocina Centro', 'sucursal_id' => $sucursalesMap['CENTRO']],
            ['clave' => 'CENTRO-BAR', 'nombre' => 'Barra Centro', 'sucursal_id' => $sucursalesMap['CENTRO']],
            ['clave' => 'CENTRO-ALM', 'nombre' => 'Almacén Seco Centro', 'sucursal_id' => $sucursalesMap['CENTRO']],
            ['clave' => 'CENTRO-REF', 'nombre' => 'Refrigeración Centro', 'sucursal_id' => $sucursalesMap['CENTRO']],

            // Polanco
            ['clave' => 'POL-COC', 'nombre' => 'Cocina Polanco', 'sucursal_id' => $sucursalesMap['POLANCO']],
            ['clave' => 'POL-BAR', 'nombre' => 'Barra Polanco', 'sucursal_id' => $sucursalesMap['POLANCO']],
            ['clave' => 'POL-ALM', 'nombre' => 'Almacén Seco Polanco', 'sucursal_id' => $sucursalesMap['POLANCO']],
            ['clave' => 'POL-REF', 'nombre' => 'Refrigeración Polanco', 'sucursal_id' => $sucursalesMap['POLANCO']],

            // Roma
            ['clave' => 'ROMA-COC', 'nombre' => 'Cocina Roma', 'sucursal_id' => $sucursalesMap['ROMA']],
            ['clave' => 'ROMA-BAR', 'nombre' => 'Barra Roma', 'sucursal_id' => $sucursalesMap['ROMA']],
            ['clave' => 'ROMA-ALM', 'nombre' => 'Almacén Seco Roma', 'sucursal_id' => $sucursalesMap['ROMA']],

            // Coyoacán
            ['clave' => 'COY-COC', 'nombre' => 'Cocina Coyoacán', 'sucursal_id' => $sucursalesMap['COYOACAN']],
            ['clave' => 'COY-BAR', 'nombre' => 'Barra Coyoacán', 'sucursal_id' => $sucursalesMap['COYOACAN']],

            // Centro de Distribución
            ['clave' => 'CD-PRINCIPAL', 'nombre' => 'Almacén Central Principal', 'sucursal_id' => $sucursalesMap['CENTRAL']],
            ['clave' => 'CD-SECO', 'nombre' => 'Almacén Secos CD', 'sucursal_id' => $sucursalesMap['CENTRAL']],
            ['clave' => 'CD-REF', 'nombre' => 'Cámara Refrigeración CD', 'sucursal_id' => $sucursalesMap['CENTRAL']],
            ['clave' => 'CD-CONG', 'nombre' => 'Cámara Congelación CD', 'sucursal_id' => $sucursalesMap['CENTRAL']],
        ];

        foreach ($almacenes as $alm) {
            $conn->table('selemti.cat_almacenes')->insert(array_merge($alm, [
                'activo' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }
        echo "   ✓ " . count($almacenes) . " almacenes creados\n\n";

        // ===================================================================
        // 3. UNIDADES DE MEDIDA
        // ===================================================================
        echo "📏 Creando unidades de medida...\n";

        $unidades = [
            // PESO - Métricas (BASE: KG)
            ['codigo' => 'KG', 'nombre' => 'Kilogramo', 'tipo' => 'PESO', 'categoria' => 'METRICO', 'es_base' => true, 'factor_conversion_base' => 1.0, 'decimales' => 3],
            ['codigo' => 'GR', 'nombre' => 'Gramo', 'tipo' => 'PESO', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 0.001, 'decimales' => 1],
            ['codigo' => 'MG', 'nombre' => 'Miligramo', 'tipo' => 'PESO', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 0.000001, 'decimales' => 0],
            ['codigo' => 'TON', 'nombre' => 'Tonelada', 'tipo' => 'PESO', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 1000.0, 'decimales' => 3],

            // PESO - Imperial
            ['codigo' => 'LB', 'nombre' => 'Libra', 'tipo' => 'PESO', 'categoria' => 'IMPERIAL', 'es_base' => false, 'factor_conversion_base' => 0.453592, 'decimales' => 3],
            ['codigo' => 'OZ', 'nombre' => 'Onza', 'tipo' => 'PESO', 'categoria' => 'IMPERIAL', 'es_base' => false, 'factor_conversion_base' => 0.0283495, 'decimales' => 2],

            // VOLUMEN - Métrico (BASE: LT)
            ['codigo' => 'LT', 'nombre' => 'Litro', 'tipo' => 'VOLUMEN', 'categoria' => 'METRICO', 'es_base' => true, 'factor_conversion_base' => 1.0, 'decimales' => 3],
            ['codigo' => 'ML', 'nombre' => 'Mililitro', 'tipo' => 'VOLUMEN', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 0.001, 'decimales' => 0],
            ['codigo' => 'MC', 'nombre' => 'Metro Cúbico', 'tipo' => 'VOLUMEN', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 1000.0, 'decimales' => 3],

            // VOLUMEN - Imperial
            ['codigo' => 'GAL', 'nombre' => 'Galón', 'tipo' => 'VOLUMEN', 'categoria' => 'IMPERIAL', 'es_base' => false, 'factor_conversion_base' => 3.78541, 'decimales' => 3],
            ['codigo' => 'FLOZ', 'nombre' => 'Onza Fluida', 'tipo' => 'VOLUMEN', 'categoria' => 'IMPERIAL', 'es_base' => false, 'factor_conversion_base' => 0.0295735, 'decimales' => 2],

            // VOLUMEN - Culinario
            ['codigo' => 'TAZA', 'nombre' => 'Taza', 'tipo' => 'VOLUMEN', 'categoria' => 'CULINARIO', 'es_base' => false, 'factor_conversion_base' => 0.240, 'decimales' => 2],
            ['codigo' => 'CDTA', 'nombre' => 'Cucharadita', 'tipo' => 'VOLUMEN', 'categoria' => 'CULINARIO', 'es_base' => false, 'factor_conversion_base' => 0.005, 'decimales' => 1],
            ['codigo' => 'CDSP', 'nombre' => 'Cucharada Sopera', 'tipo' => 'VOLUMEN', 'categoria' => 'CULINARIO', 'es_base' => false, 'factor_conversion_base' => 0.015, 'decimales' => 1],

            // UNIDAD
            ['codigo' => 'PZ', 'nombre' => 'Pieza', 'tipo' => 'UNIDAD', 'categoria' => 'METRICO', 'es_base' => true, 'factor_conversion_base' => 1.0, 'decimales' => 0],
            ['codigo' => 'PAQ', 'nombre' => 'Paquete', 'tipo' => 'UNIDAD', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 1.0, 'decimales' => 0],
            ['codigo' => 'CAJA', 'nombre' => 'Caja', 'tipo' => 'UNIDAD', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 1.0, 'decimales' => 0],
            ['codigo' => 'COST', 'nombre' => 'Costal', 'tipo' => 'UNIDAD', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 1.0, 'decimales' => 0],
            ['codigo' => 'PORC', 'nombre' => 'Porción', 'tipo' => 'UNIDAD', 'categoria' => 'CULINARIO', 'es_base' => false, 'factor_conversion_base' => 1.0, 'decimales' => 0],
            ['codigo' => 'PLAT', 'nombre' => 'Plato', 'tipo' => 'UNIDAD', 'categoria' => 'CULINARIO', 'es_base' => false, 'factor_conversion_base' => 1.0, 'decimales' => 0],

            // TIEMPO
            ['codigo' => 'MIN', 'nombre' => 'Minuto', 'tipo' => 'TIEMPO', 'categoria' => 'METRICO', 'es_base' => true, 'factor_conversion_base' => 1.0, 'decimales' => 0],
            ['codigo' => 'HR', 'nombre' => 'Hora', 'tipo' => 'TIEMPO', 'categoria' => 'METRICO', 'es_base' => false, 'factor_conversion_base' => 60.0, 'decimales' => 2],
        ];

        foreach ($unidades as $und) {
            $conn->table('selemti.unidades_medida')->insert(array_merge($und, [
                'created_at' => now(),
            ]));
        }
        echo "   ✓ " . count($unidades) . " unidades de medida creadas\n\n";

        // ===================================================================
        // 4. PROVEEDORES (si existe la tabla)
        // ===================================================================
        if ($conn->getSchemaBuilder()->hasTable('selemti.cat_proveedores')) {
            echo "🚚 Creando proveedores...\n";

            $proveedores = [
                [
                    'rfc' => 'ADP850315XYZ',
                    'nombre' => 'Abarrotes Don Pepe S.A. de C.V.',
                    'telefono' => '555-1234-567',
                    'email' => 'ventas@donpepe.com.mx',
                    'activo' => true,
                ],
                [
                    'rfc' => 'CSN920420ABC',
                    'nombre' => 'Carnes Selectas del Norte S.A.',
                    'telefono' => '555-2345-678',
                    'email' => 'pedidos@carnesdelnorte.com',
                    'activo' => true,
                ],
                [
                    'rfc' => 'LVQ880615DEF',
                    'nombre' => 'Lacteos La Vaquita S.A. de C.V.',
                    'telefono' => '555-3456-789',
                    'email' => 'ventas@lavaquita.mx',
                    'activo' => true,
                ],
                [
                    'rfc' => 'FVM910820GHI',
                    'nombre' => 'Frutas y Verduras del Mercado S.A.',
                    'telefono' => '555-4567-890',
                    'email' => 'contacto@fyvmercado.com',
                    'activo' => true,
                ],
                [
                    'rfc' => 'DBP870910JKL',
                    'nombre' => 'Distribuidora de Bebidas Premium S.A.',
                    'telefono' => '555-5678-901',
                    'email' => 'ventas@bebidaspremium.mx',
                    'activo' => true,
                ],
                [
                    'rfc' => 'PRH830525MNO',
                    'nombre' => 'Panadería y Repostería El Horno S.A.',
                    'telefono' => '555-6789-012',
                    'email' => 'pedidos@elhorno.com.mx',
                    'activo' => true,
                ],
                [
                    'rfc' => 'MPG890315PQR',
                    'nombre' => 'Mariscos y Pescados Frescos del Golfo S.A.',
                    'telefono' => '555-7890-123',
                    'email' => 'ventas@mariscosgolfo.com',
                    'activo' => true,
                ],
                [
                    'rfc' => 'DEE860720STU',
                    'nombre' => 'Desechables y Empaques Eco S.A. de C.V.',
                    'telefono' => '555-8901-234',
                    'email' => 'ventas@ecoempaques.mx',
                    'activo' => true,
                ],
            ];

            foreach ($proveedores as $prov) {
                $conn->table('selemti.cat_proveedores')->insert(array_merge($prov, [
                    'created_at' => now(),
                    'updated_at' => now(),
                ]));
            }
            echo "   ✓ " . count($proveedores) . " proveedores creados\n\n";
        }

        // ===================================================================
        // RESUMEN FINAL
        // ===================================================================
        echo "\n";
        echo "═══════════════════════════════════════════════════════════════\n";
        echo "✅ Catálogos de restaurante creados exitosamente!\n";
        echo "═══════════════════════════════════════════════════════════════\n";
        echo "📊 Resumen:\n";
        echo "   • Sucursales: " . count($sucursales) . "\n";
        echo "   • Almacenes: " . count($almacenes) . "\n";
        echo "   • Unidades de medida: " . count($unidades) . "\n";
        if (isset($proveedores)) {
            echo "   • Proveedores: " . count($proveedores) . "\n";
        }
        echo "═══════════════════════════════════════════════════════════════\n\n";

        echo "🎯 Próximos pasos sugeridos:\n";
        echo "   1. Crear items de inventario (productos/ingredientes)\n";
        echo "   2. Definir recetas\n";
        echo "   3. Configurar políticas de stock\n";
        echo "   4. Cargar precios de proveedores\n\n";
    }
}
