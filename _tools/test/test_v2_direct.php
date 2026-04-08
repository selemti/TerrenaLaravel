<?php
require_once 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Simular request
$request = new \Illuminate\Http\Request([
    'start_date' => '2025-12-15',
    'end_date' => '2025-12-15',
    'view' => 'item_mod_combos',
    'include_empty' => '1'
]);

// Crear instancia del controlador
$controller = new \App\Http\Controllers\Reports\SalesModsController();

// Usar reflection para acceder al método protegido
$reflection = new ReflectionClass($controller);
$showMethod = $reflection->getMethod('show', ReflectionMethod::PUBLIC);

// Invocar el método show (que usará la vista v2)
$response = $showMethod->invoke($controller, $request);

echo "=== RESPUESTA DEL CONTROLADOR ===\n";
echo "Status: " . $response->getStatusCode() . "\n";

if ($response instanceof \Illuminate\View\View) {
    echo "View Name: " . $response->getName() . "\n";

    // Extraer datos de la vista
    $data = $response->getData();
    echo "Rows Count: " . count($data['rows'] ?? []) . "\n";
    echo "View: " . ($data['view'] ?? 'N/A') . "\n";

    if (isset($data['rows'])) {
        echo "=== DATOS DEL REPORTE ===\n";
        foreach ($data['rows'] as $index => $row) {
            echo sprintf(
                "%d. %s | %s | %s | %s | \$%.2f | \$%.2f | %s\n",
                $index + 1,
                $row->categoria ?? 'N/A',
                $row->grupo_menu ?? 'N/A',
                $row->menu_item ?? 'N/A',
                $row->combo ?? 'N/A',
                $row->ingreso_base ?? 0,
                $row->costo_modificadores ?? 0,
                $row->ingreso_total ?? 0
            );
        }
    }

    echo "\n=== ACCESO A VISTA V2 ===\n";
    echo "Para ver la interfaz completa, visita:\n";
    echo "http://localhost/TerrenaLaravel/reports/sales/mods/v2?start_date=2025-12-15&end_date=2025-12-15&view=item_mod_combos&include_empty=1\n";

} else {
    echo "Response type: " . get_class($response) . "\n";
    echo "Content: " . $response->getContent() . "\n";
}