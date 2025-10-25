<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;

// Controllers
use App\Http\Controllers\Api\Caja\CajasController;
use App\Http\Controllers\Api\Caja\PrecorteController;
use App\Http\Controllers\Api\Caja\PostcorteController;
use App\Http\Controllers\Api\Caja\SesionesController;
use App\Http\Controllers\Api\Caja\ConciliacionController;
use App\Http\Controllers\Api\Caja\FormasPagoController;
use App\Http\Controllers\Api\Caja\AuthController;
use App\Http\Controllers\Api\Caja\HealthController;

use App\Http\Controllers\Api\Unidades\UnidadController;
use App\Http\Controllers\Api\Unidades\ConversionController;

use App\Http\Controllers\Api\AlertsController;
use App\Http\Controllers\Api\Inventory\ItemController;
use App\Http\Controllers\Api\Inventory\PriceController;
use App\Http\Controllers\Api\Inventory\RecipeCostController;
use App\Http\Controllers\Api\Inventory\StockController;
use App\Http\Controllers\Api\Inventory\VendorController;
use App\Http\Controllers\Api\CatalogsController;
use App\Http\Controllers\Purchasing\PurchaseSuggestionController;

/*
|--------------------------------------------------------------------------
| MÓDULO: REPORTES (Dashboards)
|--------------------------------------------------------------------------
*/
use App\Http\Controllers\Api\ReportsController;
Route::prefix('reports')->group(function () {
    Route::get('/kpis/sucursal',        [ReportsController::class, 'kpisSucursalDia']);
    Route::get('/kpis/terminal',        [ReportsController::class, 'kpisTerminalDia']);
    Route::get('/ventas/familia',       [ReportsController::class, 'ventasFamilia']);
    Route::get('/ventas/hora',          [ReportsController::class, 'ventasPorHora']);
    Route::get('/ventas/top',           [ReportsController::class, 'ventasTopProductos']);
    Route::get('/ventas/dia',           [ReportsController::class, 'ventasDiarias']);
    Route::get('/ventas/items_resumen', [ReportsController::class, 'ventasItemsResumen']);
    Route::get('/ventas/categorias',    [ReportsController::class, 'ventasCategorias']);
    Route::get('/ventas/sucursales',    [ReportsController::class, 'ventasPorSucursal']);
    Route::get('/ventas/ordenes_recientes', [ReportsController::class, 'ordenesRecientes']);
    Route::get('/ventas/formas',        [ReportsController::class, 'formasPago']);
    Route::get('/ticket/promedio',      [ReportsController::class, 'ticketPromedio']);
    Route::get('/stock/val',            [ReportsController::class, 'stockValorizado']);
    Route::get('/consumo/vr',           [ReportsController::class, 'consumoVsMovimientos']);
    Route::get('/anomalias',            [ReportsController::class, 'anomalos']);
});

/*
|--------------------------------------------------------------------------
| Health Check
|--------------------------------------------------------------------------
*/
Route::get('/ping', fn () => response()->json(['ok' => true, 'timestamp' => now()]));
Route::get('/health', [HealthController::class, 'check']);

/*
|--------------------------------------------------------------------------
| Authentication (sin middleware para desarrollo)
|--------------------------------------------------------------------------
*/
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::get('/login', [AuthController::class, 'loginHelp']); // Para HEAD/OPTIONS
});

/*
|--------------------------------------------------------------------------
| MÓDULO: CAJA
|--------------------------------------------------------------------------
*/
Route::prefix('caja')->group(function () {

    // === Cajas ===
    Route::get('/cajas', [CajasController::class, 'index']);

    // === Tickets ===
    Route::get('/ticket/{id}', [App\Http\Controllers\Api\Caja\CajaController::class, 'getTicketDetail']);
    
    // === Sesiones ===
    Route::get('/sesiones/activa', [SesionesController::class, 'getActiva']);
    
    // === Precortes ===
    Route::prefix('precortes')->group(function () {
        // Preflight - verificar tickets abiertos
        Route::match(['get', 'post'], '/preflight/{sesion_id?}', [PrecorteController::class, 'preflight']);

        // CRUD principal
        Route::post('/', [PrecorteController::class, 'createLegacy']);
        Route::get('/{id}', [PrecorteController::class, 'show']);
        Route::post('/{id}', [PrecorteController::class, 'updateLegacy']);

        // Acciones específicas
        Route::get('/{id}/totales', [PrecorteController::class, 'resumenLegacy']);
        Route::match(['get', 'post'], '/{id}/status', [PrecorteController::class, 'statusLegacy']);
        Route::post('/{id}/enviar', [PrecorteController::class, 'enviar']);

        // Totales por sesión
        Route::get('/sesion/{sesion_id}/totales', [PrecorteController::class, 'totalesPorSesion']);
    });
    
    // === Postcortes ===
    Route::prefix('postcortes')->group(function () {
        Route::post('/', [PostcorteController::class, 'create']);
        Route::get('/{id}', [PostcorteController::class, 'show']);
        Route::post('/{id}', [PostcorteController::class, 'update']);
        Route::get('/{id}/detalle', [PostcorteController::class, 'detalle']);
    });
    
    // === Conciliación ===
    Route::get('/conciliacion/{sesion_id}', [ConciliacionController::class, 'getBySesion']);
    
    // === Formas de Pago ===
    Route::get('/formas-pago', [FormasPagoController::class, 'index']);
});

/*
|--------------------------------------------------------------------------
| MÓDULO: UNIDADES
|--------------------------------------------------------------------------
*/
Route::prefix('unidades')->group(function () {
    Route::get('/', [UnidadController::class, 'index']);
    Route::get('/{id}', [UnidadController::class, 'show']);
    Route::post('/', [UnidadController::class, 'store']);
    Route::put('/{id}', [UnidadController::class, 'update']);
    Route::delete('/{id}', [UnidadController::class, 'destroy']);
    
    // Conversiones
    Route::prefix('conversiones')->group(function () {
        Route::get('/', [ConversionController::class, 'index']);
        Route::post('/', [ConversionController::class, 'store']);
        Route::put('/{id}', [ConversionController::class, 'update']);
        Route::delete('/{id}', [ConversionController::class, 'destroy']);
    });
});

/*
|--------------------------------------------------------------------------
| MÓDULO: INVENTORY
|--------------------------------------------------------------------------
*/
Route::prefix('inventory')->group(function () {
    // KPIs Dashboard
    Route::get('/kpis', [StockController::class, 'kpis']);

    // Stock endpoints
    Route::get('/stock', [StockController::class, 'stockByItem']);
    Route::get('/stock/list', [StockController::class, 'stockList']);

    // Movements
    Route::post('/movements', [StockController::class, 'createMovement']);

    // Items
    Route::prefix('items')->group(function () {
        Route::get('/', [ItemController::class, 'index']);
        Route::get('/{id}', [ItemController::class, 'show']);
        Route::post('/', [ItemController::class, 'store']);
        Route::put('/{id}', [ItemController::class, 'update']);
        Route::delete('/{id}', [ItemController::class, 'destroy']);

        // Relacionados con items
        Route::get('/{id}/kardex', [StockController::class, 'kardex']);
        Route::get('/{id}/batches', [StockController::class, 'batches']);
        Route::get('/{id}/vendors', [VendorController::class, 'byItem']);
        Route::post('/{id}/vendors', [VendorController::class, 'attach']);
    });

    // Precios de proveedores
    Route::post('/prices', [PriceController::class, 'store'])->middleware('throttle:30,1');
});

// Costeo de recetas
Route::get('/recipes/{id}/cost', [RecipeCostController::class, 'show']);

// Alertas de costos
Route::get('/alerts', [AlertsController::class, 'index']);
Route::post('/alerts/{id}/ack', [AlertsController::class, 'acknowledge']);

/*
|--------------------------------------------------------------------------
| MÓDULO: CATÁLOGOS
|--------------------------------------------------------------------------
*/
Route::prefix('catalogs')->group(function () {
    Route::get('/categories', [CatalogsController::class, 'categories']);
    Route::get('/almacenes', [CatalogsController::class, 'almacenes']);
    Route::get('/sucursales', [CatalogsController::class, 'sucursales']);
    Route::get('/unidades', [CatalogsController::class, 'unidades']);
    Route::get('/movement-types', [CatalogsController::class, 'movementTypes']);
});

/*
|--------------------------------------------------------------------------
| MÓDULO: PURCHASING (COMPRAS)
|--------------------------------------------------------------------------
*/
Route::prefix('purchasing')->group(function () {
    Route::get('/suggestions', [PurchaseSuggestionController::class, 'index']);
    Route::post('/suggestions/{id}/approve', [PurchaseSuggestionController::class, 'approve']);
    Route::post('/suggestions/{id}/convert', [PurchaseSuggestionController::class, 'convert']);
});

/*
|--------------------------------------------------------------------------
| ENDPOINTS LEGACY (Compatibilidad temporal - DEPRECADOS)
|--------------------------------------------------------------------------
| Estos endpoints mantienen compatibilidad con el sistema anterior
| Deberían ser removidos una vez que el frontend se actualice
*/
Route::prefix('legacy')->group(function () {
    
    // Rutas estilo Slim PHP original (.php en URL)
    Route::get('/caja/cajas.php', [CajasController::class, 'index']);
    Route::post('/caja/precorte_create.php', [PrecorteController::class, 'createLegacy']);
    Route::post('/caja/precorte_update.php', [PrecorteController::class, 'updateLegacy']);
    Route::get('/caja/precorte_totales.php', [PrecorteController::class, 'resumenLegacy']);
    Route::get('/caja/precorte_status.php', [PrecorteController::class, 'statusLegacy']);
    Route::get('/caja/formas_pago', [FormasPagoController::class, 'listar']);
    
    // Rutas sprecorte (compatibilidad con wizard)
    Route::prefix('sprecorte')->group(function () {
        Route::match(['get', 'post'], '/preflight/{sesion_id?}', [PrecorteController::class, 'preflight']);
        Route::match(['get', 'post'], '/totales/{id?}', [PrecorteController::class, 'resumenLegacy']);
        Route::match(['get', 'post'], '/totales/sesion/{sesion_id?}', [PrecorteController::class, 'totalesPorSesion']);
        Route::match(['get', 'post'], '/create/{id?}', [PrecorteController::class, 'createLegacy']);
        Route::match(['get', 'post'], '/update/{id?}', [PrecorteController::class, 'updateLegacy']);
    });
    
    // Rutas flexibles con parámetros opcionales
    Route::post('/precortes[/{id}]', [PrecorteController::class, 'createOrUpdateLegacy'])
        ->where('id', '[0-9]+');
    Route::post('/postcortes[/{id}]', [PostcorteController::class, 'createOrUpdateLegacy'])
        ->where('id', '[0-9]+');
});

/*
|--------------------------------------------------------------------------
| Fallback - 404 JSON
|--------------------------------------------------------------------------
*/
Route::fallback(function () {
    return response()->json([
        'ok' => false,
        'error' => 'endpoint_not_found',
        'message' => 'El endpoint solicitado no existe',
        'timestamp' => now()->toIso8601String()
    ], 404);
});
