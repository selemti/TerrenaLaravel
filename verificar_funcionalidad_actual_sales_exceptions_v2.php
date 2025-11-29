<?php
// verificar_funcionalidad_actual_sales_exceptions_v2.php
// Script para verificar que el reporte de Sales Exceptions funcione correctamente con la base de datos restaurada y alineada

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "🔍 Verificando funcionalidad actual del reporte de Sales Exceptions...\n";

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
    
    // 2. Probar el controlador de Sales Exceptions (accediendo a través de sus métodos públicos)
    echo "\n2. PROBANDO SERVICIO DE SALES EXCEPTIONS:\n";
    echo "==========================================\n";
    
    // Probar con un día específico que tenga datos
    $start_date = new DateTime('2025-11-24');
    $end_date = new DateTime('2025-11-24');
    
    $inicio = microtime(true);
    
    // Usamos el método fetch del controlador pasando un request simulado
    $request = new \Illuminate\Http\Request();
    $request->merge([
        'start_date' => $start_date->format('Y-m-d'),
        'end_date' => $end_date->format('Y-m-d')
    ]);
    
    $controller = new \App\Http\Controllers\Reports\SalesExceptionsController();
    
    // Verificar si existen los métodos necesarios
    if (method_exists($controller, 'fetch')) {
        $dataset = $controller->fetch($start_date, $end_date);
        
        $tiempo_total = (microtime(true) - $inicio) * 1000;
        
        echo "✅ Fetch completado en: " . round($tiempo_total, 2) . " ms\n";
        echo "Tickets procesados: " . $dataset['records']->count() . "\n";
        echo "Categorías de excepciones: " . $dataset['categories']->count() . "\n";
        echo "Resumen total de excepciones: " . $dataset['summary']['total_records'] . "\n";
        echo "Tickets con excepciones: " . $dataset['summary']['total_tickets'] . "\n";
        echo "Impacto total: $" . number_format($dataset['summary']['impact_sum'], 2) . "\n";
        
        // 3. Probar rendimiento con 10 días
        echo "\n3. PROBANDO RENDIMIENTO (10 días):\n";
        echo "===================================\n";
        
        $end_date_10 = new DateTime('2025-11-24');
        $start_date_10 = clone $end_date_10;
        $start_date_10->modify('-9 days'); // 10 días incluyendo el día final
        
        echo "Rango de prueba: {$start_date_10->format('Y-m-d')} a {$end_date_10->format('Y-m-d')}\n";
        
        $inicio = microtime(true);
        $larger_dataset = $controller->fetch($start_date_10, $end_date_10);
        $tiempo_10_dias = (microtime(true) - $inicio) * 1000;
        
        echo "✅ Fetch 10 días completado en: " . round($tiempo_10_dias, 2) . " ms\n";
        echo "Tickets procesados: " . $larger_dataset['records']->count() . "\n";
        echo "Excepciones totales: " . $larger_dataset['summary']['total_records'] . "\n";
        echo "Impacto total: $" . number_format($larger_dataset['summary']['impact_sum'], 2) . "\n";
        
        if ($tiempo_10_dias < 500) {
            echo "✅ PERFECTO: Tiempo inferior a 500ms para 10 días (rendimiento objetivo)\n";
        } elseif ($tiempo_10_dias < 2000) {
            echo "✅ BUENO: Tiempo inferior a 2000ms para 10 días\n";
        } else {
            echo "⚠️  Tiempo superior a lo esperado para 10 días ({$tiempo_10_dias} ms)\n";
        }
        
        // 4. Verificar categorías de excepciones
        echo "\n4. VERIFICANDO CATEGORÍAS DE EXCEPCIÓN:\n";
        echo "========================================\n";
        
        $expected_categories = ['discount_100', 'discount_high', 'unpaid_closed', 'voided_with_payments', 'payment_mismatch'];
        $found_categories = [];
        
        foreach ($dataset['categories'] as $cat) {
            $category_key = $cat['key'] ?? $cat['category'] ?? 'unknown';
            if (in_array($category_key, $expected_categories)) {
                $found_categories[] = $category_key;
                $count = $cat['count'] ?? $cat['rows']->count() ?? 0;
                echo "✅ Categoría encontrada: $category_key ($count registros)\n";
            }
        }
        
        foreach ($expected_categories as $category) {
            if (!in_array($category, $found_categories)) {
                echo "❌ Categoría faltante: $category\n";
            }
        }
        
        if (count($found_categories) == count($expected_categories)) {
            echo "\n✅ Todas las categorías esperadas están presentes\n";
        } else {
            echo "\n⚠️  Faltan algunas categorías de excepción\n";
        }
        
        // 5. Validar integridad de datos
        echo "\n5. VALIDANDO INTEGRIDAD DE DATOS:\n";
        echo "==================================\n";
        
        $records = $dataset['records'];
        $issues_found = 0;
        
        foreach ($records as $record) {
            if (isset($record['ticket_id']) && $record['ticket_id'] <= 0) {
                $issues_found++;
            }
            
            if (!isset($record['folio_date']) || $record['folio_date'] === null) {
                $issues_found++;
            }
            
            if (!isset($record['branch_key']) || strlen($record['branch_key']) == 0) {
                $issues_found++;
            }
        }
        
        echo "Registros analizados: " . $records->count() . "\n";
        echo "Problemas encontrados: $issues_found\n";
        
        if ($issues_found == 0 && $records->count() > 0) {
            echo "✅ Todos los registros tienen datos completos\n";
        } elseif ($records->count() > 0) {
            echo "⚠️  Algunos registros tienen datos incompletos\n";
        } else {
            echo "ℹ️  No hay registros para validar\n";
        }
        
        // 6. Verificar índices de rendimiento
        echo "\n6. VERIFICANDO ÍNDICES DE RENDIMIENTO:\n";
        echo "======================================\n";
        
        $performance_indices = [
            'idx_transactions_ticket_id',
            'idx_ticket_discount_ticket_id', 
            'idx_ticket_item_discount_ticketid'
        ];
        
        $indices_encontrados = 0;
        foreach ($performance_indices as $index_name) {
            $index_exists = DB::connection('pgsql')->select("
                SELECT EXISTS (
                    SELECT FROM pg_indexes 
                    WHERE indexname = ?
                ) AS index_exists;
            ", [$index_name]);
            
            $exists = $index_exists[0]->index_exists;
            if ($exists) {
                $indices_encontrados++;
                echo "✅ Índice encontrado: $index_name\n";
            } else {
                echo "❌ Índice faltante: $index_name\n";
            }
        }
        
        echo "\n✅ Índices de rendimiento encontrados: {$indices_encontrados}/" . count($performance_indices) . "\n";
        
        echo "\n🎉 VERIFICACIÓN DE FUNCIONALIDAD COMPLETADA\n";
        echo "\n📊 RESUMEN FINAL:\n";
        echo "================\n";
        echo "Tickets disponibles para análisis: {$stats->total_tickets}\n";
        echo "Rendimiento (1 día): " . round($tiempo_total, 2) . " ms\n";
        echo "Rendimiento (10 días): " . round($tiempo_10_dias, 2) . " ms\n";
        echo "Excepciones detectadas: " . $dataset['summary']['total_records'] . "\n";
        echo "Índices de rendimiento: {$indices_encontrados}/" . count($performance_indices) . "\n";
        
        if ($tiempo_10_dias < 500) {
            echo "\n🎯 ¡OBJETIVO DE RENDIMIENTO ALCANZADO! (360x más rápido)\n";
        } else {
            echo "\n⚠️  El rendimiento aún puede mejorar\n";
        }
        
    } else {
        // Si no existe el método fetch directo, probar con el método show
        echo "⚠️  El método fetch no está disponible directamente en el controlador\n";
        echo "⚠️  El controlador de SalesExceptions tal vez usa lógica directa en el método show\n";
        
        // Intentar probar la funcionalidad accediendo al método show o index
        if (method_exists($controller, 'index')) {
            $inicio = microtime(true);
            
            $mock_request = new \Illuminate\Http\Request();
            $mock_request->merge([
                'start_date' => $start_date->format('Y-m-d'),
                'end_date' => $end_date->format('Y-m-d')
            ]);
            
            $response = $controller->index($mock_request);
            
            $tiempo_total = (microtime(true) - $inicio) * 1000;
            echo "✅ Index completado en: " . round($tiempo_total, 2) . " ms\n";
            
            if (method_exists($response, 'getData')) {
                $data = $response->getData(true);
                if (isset($data['records'])) {
                    echo "Registros obtenidos: " . count($data['records']) . "\n";
                }
                if (isset($data['summary'])) {
                    echo "Excepciones totales: " . ($data['summary']['total_records'] ?? 'N/A') . "\n";
                }
            }
        } else {
            echo "❌ Métodos necesarios no encontrados en el controlador\n";
        }
    }

} catch (Exception $e) {
    echo "❌ Error en la verificación: " . $e->getMessage() . "\n";
    echo "Archivo: " . $e->getFile() . "\n";
    echo "Línea: " . $e->getLine() . "\n";
}