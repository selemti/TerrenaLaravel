<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "Creando vistas del dashboard de ventas...\n\n";

try {
    $sql = file_get_contents(__DIR__.'/BD/create_dashboard_views.sql');

    // Ejecutar el SQL
    DB::connection('pgsql')->unprepared($sql);

    echo "✓ Vistas creadas exitosamente\n\n";

    // Verificar que las vistas existen
    $views = DB::connection('pgsql')->select("
        SELECT schemaname, viewname 
        FROM pg_views 
        WHERE schemaname = 'selemti' 
        AND viewname LIKE 'vw_dashboard%'
        ORDER BY viewname
    ");

    echo "Vistas creadas:\n";
    foreach ($views as $view) {
        echo "  ✓ {$view->schemaname}.{$view->viewname}\n";
    }

    echo "\n¡Listo! Ahora puedes probar el endpoint /api/reports/ventas/hora\n";

} catch (Exception $e) {
    echo '✗ Error: '.$e->getMessage()."\n";
    echo "\nStack trace:\n";
    echo $e->getTraceAsString()."\n";
    exit(1);
}
