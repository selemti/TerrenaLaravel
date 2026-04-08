<?php
// verificar_funcionalidad_sales_exceptions.php
// Script para verificar la funcionalidad del reporte de Sales Exceptions

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "🔍 Verificando funcionalidad del reporte de Sales Exceptions...\n";

try {
    // 1. Verificar existencia de datos de prueba
    echo "\n1. VERIFICANDO DATOS DE PRUEBA:\n";
    echo "===============================\n";
    
    $ticket_stats = DB::connection('pgsql')->select("
        SELECT 
            COUNT(*) as total_tickets,
            MIN(closing_date) as fecha_mas_antigua,
            MAX(closing_date) as fecha_mas_reciente
        FROM public.ticket
        WHERE paid = true
          AND voided = false
          AND closing_date >= '2025-11-01'
    ");
    
    $stats = $ticket_stats[0];
    echo "Total tickets (pagados/no anulados desde Nov 1): {$stats->total_tickets}\n";
    echo "Fecha más antigua: {$stats->fecha_mas_antigua}\n";
    echo "Fecha más reciente: {$stats->fecha_mas_reciente}\n";
    
    if ($stats->total_tickets == 0) {
        // Buscar en un rango más amplio
        $extended_stats = DB::connection('pgsql')->select("
            SELECT 
                COUNT(*) as total_tickets,
                MIN(closing_date) as fecha_mas_antigua,
                MAX(closing_date) as fecha_mas_reciente
            FROM public.ticket
            WHERE paid = true
              AND voided = false
        ");
        
        $ext_stats = $extended_stats[0];
        echo "\nBuscar en todo el historial:\n";
        echo "Total tickets (pagados/no anulados): {$ext_stats->total_tickets}\n";
        echo "Fecha más antigua: {$ext_stats->fecha_mas_antigua}\n";
        echo "Fecha más reciente: {$ext_stats->fecha_mas_reciente}\n";
    }
    
    // 2. Probar el servicio de reporte
    echo "\n2. PROBANDO SERVICIO DE REPORTES:\n";
    echo "=================================\n";

    try {
        $service = app(App\Services\Reports\SalesExceptionsReportService::class);
        echo "✅ Servicio SalesExceptionsReportService instanciado correctamente\n";
        
        // Probar con un día específico
        $start_date = new DateTime('2025-11-24');
        $end_date = new DateTime('2025-11-24');
        
        $inicio = microtime(true);
        $tickets = $service->fetch($start_date, $end_date, []);
        $tiempo_fetch = (microtime(true) - $inicio) * 1000;
        
        echo "✅ Fetch completado en: " . round($tiempo_fetch, 2) . " ms\n";
        echo "Tickets obtenidos: " . $tickets->count() . "\n";
        
        if ($tickets->count() > 0) {
            $inicio = microtime(true);
            $report = $service->summarize($tickets);
            $tiempo_summarize = (microtime(true) - $inicio) * 1000;
            
            echo "✅ Summarize completado en: " . round($tiempo_summarize, 2) . " ms\n";
            echo "Categorías encontradas: " . $report['categories']->count() . "\n";
            echo "Excepciones totales: " . $report['summary']['total_records'] . "\n";
            echo "Tickets con excepciones: " . $report['summary']['total_tickets'] . "\n";
            echo "Impacto total: $" . number_format($report['summary']['impact_sum'], 2) . "\n";
        } else {
            echo "ℹ️  No hay tickets para la fecha seleccionada, probando con otra fecha...\n";
            
            // Buscar una fecha que tenga datos
            $available_date = DB::connection('pgsql')->select("
                SELECT closing_date::date as date
                FROM public.ticket
                WHERE paid = true
                  AND voided = false
                ORDER BY closing_date DESC
                LIMIT 1
            ");
            
            if (!empty($available_date)) {
                $test_date = new DateTime($available_date[0]->date);
                $inicio = microtime(true);
                $tickets = $service->fetch($test_date, $test_date, []);
                $tiempo_fetch = (microtime(true) - $inicio) * 1000;
                
                echo "✅ Fetch para $test_date->date completado en: " . round($tiempo_fetch, 2) . " ms\n";
                echo "Tickets obtenidos: " . $tickets->count() . "\n";
                
                if ($tickets->count() > 0) {
                    $inicio = microtime(true);
                    $report = $service->summarize($tickets);
                    $tiempo_summarize = (microtime(true) - $inicio) * 1000;
                    
                    echo "✅ Summarize completado en: " . round($tiempo_summarize, 2) . " ms\n";
                    echo "Categorías encontradas: " . $report['categories']->count() . "\n";
                    echo "Excepciones totales: " . $report['summary']['total_records'] . "\n";
                }
            } else {
                echo "⚠️  No se encontraron fechas con tickets válidos\n";
            }
        }
        
    } catch (Exception $e) {
        echo "❌ Error probando el servicio: " . $e->getMessage() . "\n";
    }
    
    // 3. Probar rendimiento con 10 días
    echo "\n3. PROBANDO RENDIMIENTO (10 días):\n";
    echo "===================================\n";
    
    try {
        $end_date = new DateTime('2025-11-24');
        $start_date = clone $end_date;
        $start_date->modify('-9 days'); // 10 días incluyendo el día final
        
        echo "Rango de prueba: {$start_date->format('Y-m-d')} a {$end_date->format('Y-m-d')}\n";
        
        $inicio = microtime(true);
        $tickets = $service->fetch($start_date, $end_date, []);
        $tiempo_fetch = (microtime(true) - $inicio) * 1000;
        
        echo "✅ Fetch 10 días completado en: " . round($tiempo_fetch, 2) . " ms\n";
        echo "Tickets obtenidos: " . $tickets->count() . "\n";
        
        if ($tickets->count() > 0) {
            $inicio = microtime(true);
            $report = $service->summarize($tickets);
            $tiempo_summarize = (microtime(true) - $inicio) * 1000;
            
            echo "✅ Summarize 10 días completado en: " . round($tiempo_summarize, 2) . " ms\n";
            echo "Excepciones totales: " . $report['summary']['total_records'] . "\n";
            echo "Impacto total: $" . number_format($report['summary']['impact_sum'], 2) . "\n";
            
            $tiempo_total = $tiempo_fetch + $tiempo_summarize;
            echo "📊 Tiempo total (fetch + summarize): " . round($tiempo_total, 2) . " ms\n";
            
            if ($tiempo_total < 500) {
                echo "✅ PERFECTO: Tiempo inferior a 500ms para 10 días (rendimiento objetivo)\n";
            } else if ($tiempo_total < 2000) {
                echo "✅ BUENO: Tiempo inferior a 2000ms para 10 días\n";
            } else {
                echo "⚠️  Tiempo superior a lo esperado para 10 días\n";
            }
        }
    } catch (Exception $e) {
        echo "❌ Error en prueba de rendimiento: " . $e->getMessage() . "\n";
    }
    
    // 4. Verificar existencia de tests
    echo "\n4. VERIFICANDO TESTS AUTOMÁTICOS:\n";
    echo "================================\n";
    
    $test_paths = [
        'tests/Unit/Services/Reports/SalesExceptionsReportServiceTest.php',
        'tests/Feature/Reports/SalesExceptionsExportTest.php'
    ];
    
    foreach ($test_paths as $path) {
        if (file_exists($path)) {
            echo "✅ Test encontrado: $path\n";
        } else {
            echo "❌ Test no encontrado: $path\n";
        }
    }
    
    echo "\n✅ VERIFICACIÓN DE FUNCIONALIDAD COMPLETADA\n";

} catch (Exception $e) {
    echo "❌ Error en la verificación: " . $e->getMessage() . "\n";
}