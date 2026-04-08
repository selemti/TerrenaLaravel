#!/usr/bin/env php
<?php
/**
 * health_check_sales_exceptions.php
 * 
 * Script de verificación de salud del módulo de Sales Exceptions Report
 * 
 * Uso: php health_check_sales_exceptions.php
 */

require_once __DIR__.'/vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Inicializar aplicación Laravel
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

class SalesExceptionsHealthChecker
{
    public function check(): array
    {
        echo "🏥 Iniciando verificación de salud del módulo Sales Exceptions...\n\n";
        
        $results = [
            'timestamp' => now()->toISOString(),
            'checks' => []
        ];
        
        // 1. Verificar disponibilidad de datos
        $results['checks']['data_availability'] = $this->checkDataAvailability();
        
        // 2. Verificar índices críticos
        $results['checks']['performance_indices'] = $this->checkPerformanceIndices();
        
        // 3. Verificar rendimiento
        $results['checks']['performance'] = $this->checkPerformance();
        
        // 4. Verificar integridad de tablas
        $results['checks']['table_integrity'] = $this->checkTableIntegrity();
        
        // 5. Calcular estado general
        $results['overall_status'] = $this->calculateOverallStatus($results['checks']);
        
        return $results;
    }
    
    private function checkDataAvailability(): array
    {
        echo "🔍 Verificando disponibilidad de datos...\n";
        
        try {
            $stats = DB::connection('pgsql')->select("
                SELECT 
                    COUNT(*) as total_tickets,
                    MIN(closing_date) as oldest_date,
                    MAX(closing_date) as newest_date
                FROM public.ticket
                WHERE paid = true AND voided = false
            ");
            
            $result = [
                'status' => 'healthy',
                'message' => 'Datos suficientes disponibles',
                'data' => [
                    'total_tickets' => $stats[0]->total_tickets,
                    'date_range' => [
                        'oldest' => $stats[0]->oldest_date,
                        'newest' => $stats[0]->newest_date
                    ]
                ]
            ];
            
            if ($stats[0]->total_tickets == 0) {
                $result['status'] = 'warning';
                $result['message'] = 'No hay tickets disponibles para análisis';
            }
            
            echo "   - Tickets disponibles: {$stats[0]->total_tickets}\n";
            echo "   - Rango de fechas: {$stats[0]->oldest_date} a {$stats[0]->newest_date}\n";
            echo "   - Estado: {$result['status']} - {$result['message']}\n\n";
            
        } catch (Exception $e) {
            $result = [
                'status' => 'error',
                'message' => 'Error verificando disponibilidad de datos: ' . $e->getMessage()
            ];
            echo "   ❌ Error: {$result['message']}\n\n";
        }
        
        return $result;
    }
    
    private function checkPerformanceIndices(): array
    {
        echo "🔍 Verificando índices de rendimiento...\n";
        
        $indices = [
            'idx_transactions_ticket_id',
            'idx_ticket_discount_ticket_id',
            'idx_ticket_item_discount_itemid'
        ];
        
        $found = 0;
        $total = count($indices);
        
        foreach ($indices as $index) {
            try {
                $exists = DB::connection('pgsql')->select("
                    SELECT EXISTS (
                        SELECT FROM pg_indexes 
                        WHERE indexname = ?
                    ) AS index_exists;
                ", [$index]);
                
                if ($exists[0]->index_exists) {
                    $found++;
                    echo "   - ✅ $index\n";
                } else {
                    echo "   - ❌ $index\n";
                }
            } catch (Exception $e) {
                echo "   - ❌ $index (error: {$e->getMessage()})\n";
            }
        }
        
        $result = [
            'status' => $found === $total ? 'healthy' : 'error',
            'message' => "$found de $total índices críticos encontrados",
            'data' => [
                'indices_found' => $found,
                'indices_total' => $total
            ]
        ];
        
        echo "   - Estado: {$result['status']} - {$result['message']}\n\n";
        
        return $result;
    }
    
    private function checkPerformance(): array
    {
        echo "🔍 Verificando rendimiento...\n";
        
        try {
            // Probar con un rango pequeño primero
            $start = now()->subDays(1)->startOfDay();
            $end = now()->subDays(1)->endOfDay();
            
            $inicio = microtime(true);
            
            // Simular la carga que haría el servicio de reportes
            $tickets = DB::connection('pgsql')->select("
                SELECT t.id, t.closing_date, t.branch_key, t.terminal_id,
                       t.paid, t.voided, t.sub_total, t.total_price,
                       t.total_discount, t.closing_date
                FROM public.ticket t
                WHERE t.closing_date BETWEEN ? AND ?
                  AND t.paid = true AND t.voided = false
                LIMIT 100
            ", [$start->toDateString(), $end->toDateString()]);
            
            $tiempo = (microtime(true) - $inicio) * 1000;
            $ticket_count = count($tickets);
            
            $result = [
                'status' => $tiempo < 500 ? 'healthy' : 'warning',
                'message' => "Consulta de $ticket_count tickets en {$tiempo}ms",
                'data' => [
                    'execution_time_ms' => round($tiempo, 2),
                    'tickets_processed' => $ticket_count,
                    'performance_target_met' => $tiempo < 500
                ]
            ];
            
            echo "   - Tickets procesados: $ticket_count\n";
            echo "   - Tiempo de ejecución: {$tiempo} ms\n";
            echo "   - Estado: {$result['status']} - {$result['message']}\n\n";
            
        } catch (Exception $e) {
            $result = [
                'status' => 'error',
                'message' => 'Error verificando rendimiento: ' . $e->getMessage()
            ];
            echo "   ❌ Error: {$result['message']}\n\n";
        }
        
        return $result;
    }
    
    private function checkTableIntegrity(): array
    {
        echo "🔍 Verificando integridad de tablas...\n";
        
        $tables = [
            'public.ticket',
            'public.transactions',
            'public.ticket_discount',
            'public.ticket_item',
            'public.ticket_item_discount'
        ];
        
        $ok = 0;
        $total = count($tables);
        
        foreach ($tables as $table) {
            try {
                $exists = DB::connection('pgsql')->select("
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_schema = ? AND table_name = ?
                    ) AS table_exists;
                ", [explode('.', $table)[0], explode('.', $table)[1]]);
                
                if ($exists[0]->table_exists) {
                    $ok++;
                    echo "   - ✅ $table\n";
                } else {
                    echo "   - ❌ $table\n";
                }
            } catch (Exception $e) {
                echo "   - ❌ $table (error: {$e->getMessage()})\n";
            }
        }
        
        $result = [
            'status' => $ok === $total ? 'healthy' : 'error',
            'message' => "$ok de $total tablas críticas existen",
            'data' => [
                'tables_ok' => $ok,
                'tables_total' => $total
            ]
        ];
        
        echo "   - Estado: {$result['status']} - {$result['message']}\n\n";
        
        return $result;
    }
    
    private function calculateOverallStatus(array $checks): string
    {
        $statuses = array_column($checks, 'status');
        
        if (in_array('error', $statuses)) {
            return 'error';
        }
        
        if (in_array('warning', $statuses)) {
            return 'warning';
        }
        
        return 'healthy';
    }
    
    public function printResults(array $results): void
    {
        echo "📊 RESULTADOS DE VERIFICACIÓN:\n";
        echo "=============================\n";
        
        echo "Timestamp: {$results['timestamp']}\n";
        echo "Estado general: {$results['overall_status']}\n\n";
        
        foreach ($results['checks'] as $check_name => $check_result) {
            $status_emoji = match ($check_result['status']) {
                'healthy' => '✅',
                'warning' => '⚠️ ',
                'error' => '❌',
                default => '❓'
            };
            
            echo "{$status_emoji} " . ucfirst(str_replace('_', ' ', $check_name)) . "\n";
            echo "   - Estado: {$check_result['status']}\n";
            echo "   - Mensaje: {$check_result['message']}\n";
            
            if (isset($check_result['data'])) {
                echo "   - Datos: " . json_encode($check_result['data']) . "\n";
            }
            
            echo "\n";
        }
        
        echo "=============================\n";
        echo "VERIFICACIÓN COMPLETADA\n\n";
        
        if ($results['overall_status'] === 'healthy') {
            echo "🎉 ¡Todo está funcionando correctamente!\n";
            echo "✅ El módulo de Sales Exceptions Report está listo para operar\n";
        } elseif ($results['overall_status'] === 'warning') {
            echo "⚠️  El módulo funciona pero con advertencias\n";
            echo "👉 Revise los detalles anteriores\n";
        } else {
            echo "❌ El módulo tiene problemas críticos\n";
            echo "🚨 Requiere atención inmediata\n";
        }
    }
}

// Ejecutar la verificación
$checker = new SalesExceptionsHealthChecker();
$results = $checker->check();
$checker->printResults($results);