<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\ReplenishmentSuggestion;
use App\Models\Item;
use App\Models\Sucursal;
use Illuminate\Support\Facades\DB;

class ReplenishmentSeedTestData extends Command
{
    protected $signature = 'replenishment:seed-test-data
                            {--count=10 : Número de sugerencias a crear}';

    protected $description = 'Crea datos de prueba para el sistema de reposición';

    public function handle()
    {
        $count = (int) $this->option('count');

        $this->info("🌱 Generando {$count} sugerencias de prueba...");
        $this->newLine();

        // Verificar que hay items y sucursales
        $items = Item::activo()->take(20)->get();
        $sucursales = Sucursal::where('activo', true)->get();

        if ($items->isEmpty()) {
            $this->error('❌ No hay items activos en la BD. Por favor crea items primero.');
            return Command::FAILURE;
        }

        if ($sucursales->isEmpty()) {
            $this->error('❌ No hay sucursales activas en la BD.');
            return Command::FAILURE;
        }

        $this->info("✓ Encontrados {$items->count()} items y {$sucursales->count()} sucursales");
        $this->newLine();

        $created = 0;
        $tipos = [ReplenishmentSuggestion::TIPO_COMPRA, ReplenishmentSuggestion::TIPO_PRODUCCION];
        $prioridades = [
            ReplenishmentSuggestion::PRIORIDAD_URGENTE,
            ReplenishmentSuggestion::PRIORIDAD_ALTA,
            ReplenishmentSuggestion::PRIORIDAD_NORMAL,
            ReplenishmentSuggestion::PRIORIDAD_BAJA,
        ];
        $estados = [
            ReplenishmentSuggestion::ESTADO_PENDIENTE,
            ReplenishmentSuggestion::ESTADO_REVISADA,
            ReplenishmentSuggestion::ESTADO_APROBADA,
        ];

        DB::connection('pgsql')->transaction(function () use ($count, $items, $sucursales, $tipos, $prioridades, $estados, &$created) {
            for ($i = 0; $i < $count; $i++) {
                $item = $items->random();
                $sucursal = $sucursales->random();
                $tipo = $tipos[array_rand($tipos)];
                $prioridad = $prioridades[array_rand($prioridades)];
                $estado = $estados[array_rand($estados)];

                $stockActual = rand(0, 50);
                $stockMin = rand(10, 30);
                $stockMax = $stockMin + rand(50, 100);
                $qtySugerida = $stockMax - $stockActual;
                $consumoPromedio = rand(5, 20) + (rand(0, 99) / 100);
                $diasRestantes = $consumoPromedio > 0 ? floor($stockActual / $consumoPromedio) : 999;

                $sugerencia = ReplenishmentSuggestion::create([
                    'folio' => 'TEST-' . str_pad($i + 1, 6, '0', STR_PAD_LEFT),
                    'item_id' => $item->id,
                    'sucursal_id' => $sucursal->id,
                    'almacen_id' => null,
                    'tipo' => $tipo,
                    'prioridad' => $prioridad,
                    'estado' => $estado,
                    'origen' => ReplenishmentSuggestion::ORIGEN_MANUAL,
                    'stock_actual' => $stockActual,
                    'stock_min' => $stockMin,
                    'stock_max' => $stockMax,
                    'qty_sugerida' => $qtySugerida,
                    'qty_aprobada' => $estado === ReplenishmentSuggestion::ESTADO_APROBADA ? $qtySugerida : null,
                    'uom' => $item->uom_salida_codigo ?? 'PZA',
                    'consumo_promedio_diario' => $consumoPromedio,
                    'dias_stock_restante' => $diasRestantes,
                    'fecha_agotamiento_estimada' => now()->addDays($diasRestantes),
                    'sugerido_en' => now()->subDays(rand(0, 7)),
                    'caduca_en' => now()->addDays(rand(7, 30)),
                    'proveedor_sugerido_id' => null,
                    'costo_estimado' => rand(50, 500) + (rand(0, 99) / 100),
                    'notas' => $i % 3 === 0 ? 'Sugerencia de prueba #' . ($i + 1) : null,
                    'meta' => json_encode([
                        'test' => true,
                        'generated_at' => now()->toIso8601String(),
                    ]),
                ]);

                $created++;

                if ($created % 5 === 0) {
                    $this->line("  • Creadas {$created}/{$count}...");
                }
            }
        });

        $this->newLine();
        $this->info("✅ {$created} sugerencias de prueba creadas exitosamente");
        $this->newLine();

        // Mostrar resumen
        $this->table(
            ['Estado', 'Cantidad'],
            [
                ['Pendientes', ReplenishmentSuggestion::pendiente()->count()],
                ['Urgentes', ReplenishmentSuggestion::urgentes()->count()],
                ['Compras', ReplenishmentSuggestion::compra()->count()],
                ['Producciones', ReplenishmentSuggestion::produccion()->count()],
            ]
        );

        return Command::SUCCESS;
    }
}
