<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seeder for the cat_tipo_mov_inv table.
 *
 * @version 2.1
 * @author Gemini
 */
class CatTipoMovInvSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $movimientos = [
            ['clave' => 'VENTA_POS', 'descripcion' => 'Salida de inventario por venta POS.'],
            ['clave' => 'AJUSTE_REPROCESO_POS', 'descripcion' => 'Ajuste retroactivo por reproceso POS.'],
            ['clave' => 'AJUSTE_REVERSO', 'descripcion' => 'Reversión de movimiento anterior.'],
            ['clave' => 'APERTURA_INVENTARIO', 'descripcion' => 'Carga inicial de inventario al arranque del sistema.'],
            ['clave' => 'AJUSTE_RECETA_ERRONEA', 'descripcion' => 'Corrección por receta mal capturada.'],
            ['clave' => 'AJUSTE_COSTO_BATCH', 'descripcion' => 'Revaluación de lote o corrección de costo.'],
            ['clave' => 'CONSUMO_OPERATIVO', 'descripcion' => 'Consumo no vendible (limpieza, empaque).'],
            ['clave' => 'PRODUCCION_SALIDA_CRUDO', 'descripcion' => 'Salida de materia prima para producción interna.'],
            ['clave' => 'PRODUCCION_ENTRADA_ELABORADO', 'descripcion' => 'Entrada de subreceta o producto elaborado.'],
        ];

        foreach ($movimientos as $movimiento) {
            DB::connection('pgsql')->table('selemti.cat_tipo_mov_inv')->updateOrInsert(
                ['clave' => $movimiento['clave']],
                $movimiento
            );
        }
    }
}