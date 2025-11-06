<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=============================================================\n";
echo "   CREANDO TODAS LAS VISTAS FALTANTES DEL SISTEMA SELEMTI\n";
echo "=============================================================\n\n";

try {
    // Verificar vistas antes
    $viewsBefore = DB::connection('pgsql')->select("
        SELECT COUNT(*) as total
        FROM pg_views 
        WHERE schemaname = 'selemti'
    ");
    
    echo "Vistas existentes antes: {$viewsBefore[0]->total}\n\n";
    echo "Ejecutando script SQL...\n";
    
    $sql = file_get_contents(__DIR__.'/BD/create_missing_views.sql');
    
    // Ejecutar el SQL
    DB::connection('pgsql')->unprepared($sql);
    
    echo "✓ Script ejecutado exitosamente\n\n";
    
    // Verificar vistas después
    $viewsAfter = DB::connection('pgsql')->select("
        SELECT COUNT(*) as total
        FROM pg_views 
        WHERE schemaname = 'selemti'
    ");
    
    $created = $viewsAfter[0]->total - $viewsBefore[0]->total;
    
    echo "Vistas existentes después: {$viewsAfter[0]->total}\n";
    echo "Vistas creadas: $created\n\n";
    
    // Listar todas las vistas del dashboard
    echo "=============================================================\n";
    echo "   VISTAS DE DASHBOARD DISPONIBLES\n";
    echo "=============================================================\n";
    
    $dashboardViews = DB::connection('pgsql')->select("
        SELECT viewname 
        FROM pg_views 
        WHERE schemaname = 'selemti'
        AND viewname LIKE 'vw_dashboard%'
        ORDER BY viewname
    ");
    
    foreach ($dashboardViews as $view) {
        echo "  ✓ {$view->viewname}\n";
    }
    
    echo "\n";
    echo "=============================================================\n";
    echo "   OTRAS VISTAS IMPORTANTES\n";
    echo "=============================================================\n";
    
    $otherViews = DB::connection('pgsql')->select("
        SELECT viewname 
        FROM pg_views 
        WHERE schemaname = 'selemti'
        AND viewname NOT LIKE 'vw_dashboard%'
        AND viewname LIKE 'vw_%'
        ORDER BY viewname
    ");
    
    foreach ($otherViews as $view) {
        echo "  ✓ {$view->viewname}\n";
    }
    
    echo "\n";
    echo "=============================================================\n";
    echo "   ¡PROCESO COMPLETADO EXITOSAMENTE!\n";
    echo "=============================================================\n";
    echo "\nTodas las vistas del sistema están disponibles.\n";
    echo "Los endpoints de reportes ahora funcionarán correctamente.\n\n";
    
} catch (Exception $e) {
    echo "\n✗ ERROR: " . $e->getMessage() . "\n\n";
    echo "Detalles:\n";
    echo $e->getTraceAsString() . "\n";
    exit(1);
}
