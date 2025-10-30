<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\Replenishment\ReplenishmentService;

class ReplenishmentGenerateCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'replenishment:generate
                            {--sucursal= : ID de sucursal específica}
                            {--almacen= : ID de almacén específico}
                            {--dias=7 : Días de análisis para consumo promedio}
                            {--auto-approve : Auto-aprobar sugerencias urgentes}
                            {--dry-run : Simular sin guardar en base de datos}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Genera sugerencias de reposición automáticas basadas en políticas de stock';

    protected ReplenishmentService $service;

    public function __construct()
    {
        parent::__construct();
        $this->service = new ReplenishmentService();
    }

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('🔄 Generando sugerencias de reposición...');
        $this->newLine();

        $options = [
            'sucursal_id' => $this->option('sucursal'),
            'almacen_id' => $this->option('almacen'),
            'dias_analisis' => (int) $this->option('dias'),
            'auto_aprobar' => $this->option('auto-approve'),
            'dry_run' => $this->option('dry-run'),
        ];

        if ($options['dry_run']) {
            $this->warn('⚠️  Modo DRY-RUN: No se guardarán datos');
            $this->newLine();
        }

        $startTime = now();

        try {
            $resultado = $this->service->generateDailySuggestions($options);

            $duration = now()->diffInSeconds($startTime);

            $this->newLine();
            $this->info('✅ Proceso completado en ' . $duration . ' segundos');
            $this->newLine();

            // Mostrar resumen
            $this->table(
                ['Métrica', 'Cantidad'],
                [
                    ['Total sugerencias', $resultado['total']],
                    ['Compras', $resultado['compras']],
                    ['Producciones', $resultado['producciones']],
                    ['Urgentes', $resultado['urgentes']],
                    ['Normales', $resultado['normales']],
                    ['Errores', count($resultado['errors'])],
                ]
            );

            // Mostrar detalles de sugerencias urgentes
            if ($resultado['urgentes'] > 0) {
                $this->newLine();
                $this->warn('⚠️  Sugerencias URGENTES generadas:');
                $this->newLine();

                $urgentes = collect($resultado['sugerencias'])
                    ->filter(fn($s) => ($s['prioridad'] ?? $s->prioridad) === 'URGENTE')
                    ->take(10);

                $rows = [];
                foreach ($urgentes as $s) {
                    $rows[] = [
                        $s['folio'] ?? $s->folio,
                        $s['tipo'] ?? $s->tipo,
                        $s['item_id'] ?? $s->item_id,
                        number_format($s['stock_actual'] ?? $s->stock_actual, 2),
                        $s['dias_stock_restante'] ?? $s->dias_stock_restante,
                    ];
                }

                $this->table(
                    ['Folio', 'Tipo', 'Item', 'Stock Actual', 'Días Rest.'],
                    $rows
                );
            }

            // Mostrar errores si hay
            if (count($resultado['errors']) > 0) {
                $this->newLine();
                $this->error('❌ Errores durante el proceso:');
                $this->newLine();

                foreach ($resultado['errors'] as $error) {
                    $this->line("  • Item {$error['item_id']}: {$error['error']}");
                }
            }

            if ($options['dry_run']) {
                $this->newLine();
                $this->info('💡 Para ejecutar realmente, ejecute el comando sin --dry-run');
            }

            return Command::SUCCESS;

        } catch (\Exception $e) {
            $this->error('❌ Error fatal: ' . $e->getMessage());
            $this->error($e->getTraceAsString());
            return Command::FAILURE;
        }
    }
}
