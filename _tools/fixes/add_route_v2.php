<?php
// Agregar ruta para reporte v2.0
// Ejecutar: php add_route_v2.php

use Illuminate\Support\Facades\Route;

// Reporte mejorado v2.0 de ítems + modificadores
Route::get('/reports/sales/mods/v2', [\App\Http\Controllers\Reports\SalesModsController::class, 'showV2'])
    ->name('reports.sales.mods.v2');

echo "✅ Ruta agregada: /reports/sales/mods/v2\n";
echo "🌐 Acceso: http://localhost/TerrenaLaravel/reports/sales/mods/v2\n";
echo "📝 Modifica manualmente routes/web.php para agregar esta línea permanentemente:\n";
echo "   Route::get('/mods/v2', [SalesModsController::class, 'showV2'])->name('reports.sales.mods.v2');\n";