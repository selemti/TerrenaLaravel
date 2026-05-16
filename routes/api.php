<?php

use App\Http\Controllers\Api\AlertsController;
use App\Http\Controllers\Api\Caja\AlertasController;
// Controllers
use App\Http\Controllers\Api\Caja\AuthController;
use App\Http\Controllers\Api\Caja\CajasController;
use App\Http\Controllers\Api\Caja\ConciliacionController;
use App\Http\Controllers\Api\Caja\FormasPagoController;
use App\Http\Controllers\Api\Caja\HealthController;
use App\Http\Controllers\Api\Caja\PostcorteController;
use App\Http\Controllers\Api\Caja\PrecorteController;
use App\Http\Controllers\Api\Caja\SesionesController;
use App\Http\Controllers\Api\CatalogsController;
use App\Http\Controllers\Api\Inventory\ItemController;
use App\Http\Controllers\Api\Inventory\KardexController;
use App\Http\Controllers\Api\Inventory\PriceController;
use App\Http\Controllers\Api\Inventory\RecipeCostController;
use App\Http\Controllers\Api\Inventory\StockAlertController;
use App\Http\Controllers\Api\Inventory\StockController;
use App\Http\Controllers\Api\Inventory\TransferApiController;
use App\Http\Controllers\Api\Inventory\VendorController;
use App\Http\Controllers\Api\MeController;
use App\Http\Controllers\Api\Purchasing\ReplenishmentController;
use App\Http\Controllers\Api\ReportsController;
use App\Http\Controllers\Api\Unidades\ConversionController;
use App\Http\Controllers\Api\Unidades\UnidadController;
use App\Http\Controllers\Production\ProductionController;
use App\Http\Controllers\Production\ProductionOrderController;
use App\Http\Controllers\Purchasing\PurchaseSuggestionController;
use App\Http\Controllers\Purchasing\ReceivingController;
use App\Http\Controllers\Purchasing\ReturnController;
use App\Http\Controllers\Reports\MenuUsageController;
use App\Http\Controllers\Reports\SalesBalanceController;
use App\Http\Controllers\Reports\SalesDetailController;
use App\Http\Controllers\Reports\SalesDiagController;
use App\Http\Controllers\Reports\SalesDrawerController;
use App\Http\Controllers\Reports\SalesExceptionsController;
use App\Http\Controllers\Reports\SalesJournalController;
use App\Http\Controllers\Reports\SalesMixController;
use App\Http\Controllers\Reports\SalesModsController;
use App\Http\Controllers\Reports\SalesSummaryController;
use Illuminate\Http\Request;
/*
|--------------------------------------------------------------------------
| MÓDULO: REPORTES (Dashboards)
|--------------------------------------------------------------------------
*/
use Illuminate\Support\Facades\Route;

Route::prefix('reports')->middleware(['auth:sanctum'])->group(function () {
    Route::get('/kpis/sucursal', [ReportsController::class, 'kpisSucursalDia']);
    Route::get('/kpis/terminal', [ReportsController::class, 'kpisTerminalDia']);
    Route::get('/ventas/familia', [ReportsController::class, 'ventasFamilia']);
    Route::get('/ventas/hora', [ReportsController::class, 'ventasPorHora']);
    Route::get('/ventas/top', [ReportsController::class, 'ventasTopProductos']);
    Route::get('/ventas/dia', [ReportsController::class, 'ventasDiarias']);
    Route::get('/ventas/items_resumen', [ReportsController::class, 'ventasItemsResumen']);
    Route::get('/ventas/categorias', [ReportsController::class, 'ventasCategorias']);
    Route::get('/ventas/sucursales', [ReportsController::class, 'ventasPorSucursal']);
    Route::get('/ventas/ordenes_recientes', [ReportsController::class, 'ordenesRecientes']);
    Route::get('/ventas/formas', [ReportsController::class, 'formasPago']);
    Route::get('/ticket/promedio', [ReportsController::class, 'ticketPromedio']);
    Route::get('/stock/val', [ReportsController::class, 'stockValorizado']);
    Route::get('/consumo/vr', [ReportsController::class, 'consumoVsMovimientos']);
    Route::get('/anomalias', [ReportsController::class, 'anomalos']);
    Route::get('/purchasing/late-po', [\App\Http\Controllers\Reports\ReportsController::class, 'purchasingLatePO']);
    Route::get('/inventory/over-tolerance', [\App\Http\Controllers\Reports\ReportsController::class, 'inventoryOverTolerance']);
    Route::get('/inventory/top-urgent', [\App\Http\Controllers\Reports\ReportsController::class, 'inventoryTopUrgent']);

    // Jasper-equivalent reports (lectura)
    Route::get('/sales/detail', [SalesDetailController::class, 'index']);
    Route::get('/sales/summary', [SalesSummaryController::class, 'index']);
    Route::get('/sales/balance', [SalesBalanceController::class, 'index']);
    Route::get('/sales/exceptions', [SalesExceptionsController::class, 'index']);
    Route::get('/menu/usage', [MenuUsageController::class, 'index']);
    Route::get('/sales/journal', [SalesJournalController::class, 'index']);
    Route::get('/journal', [SalesJournalController::class, 'index']);
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
Route::prefix('caja')->middleware(['auth:sanctum'])->group(function () {

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
        // Approval workflow (specific routes BEFORE parameterized routes)
        // NOTE: Middleware temporarily disabled for development
        Route::get('/pendientes-aprobacion', [PostcorteController::class, 'pendientesAprobacion']);

        // CRUD operations
        Route::post('/', [PostcorteController::class, 'create']);
        Route::get('/{id}', [PostcorteController::class, 'show']);
        Route::post('/{id}', [PostcorteController::class, 'update']);
        Route::get('/{id}/detalle', [PostcorteController::class, 'detalle']);
        Route::post('/{id}/aprobar', [PostcorteController::class, 'aprobar']);
        Route::post('/{id}/rechazar', [PostcorteController::class, 'rechazar']);
    });

    // === Alertas ===
    Route::prefix('alertas')->group(function () {
        // NOTE: Middleware temporarily disabled for development
        Route::get('/', [AlertasController::class, 'index']);
        Route::get('/count', [AlertasController::class, 'count']);
        Route::put('/{id}/marcar-leida', [AlertasController::class, 'marcarLeida']);
        Route::put('/marcar-todas-leidas', [AlertasController::class, 'marcarTodasLeidas']);
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
Route::prefix('unidades')->middleware(['auth:sanctum'])->group(function () {
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
Route::prefix('inventory')->middleware(['auth:sanctum'])->group(function () {
    // KPIs Dashboard
    Route::get('/kpis', [StockController::class, 'kpis']);
    Route::get('/alerts', [StockAlertController::class, 'index']);

    // Stock endpoints
    Route::get('/stock', [StockController::class, 'stockByItem']);
    Route::get('/stock/list', [StockController::class, 'stockList']);

    // Movements
    Route::post('/movements', [StockController::class, 'createMovement']);

    Route::prefix('transfers')->group(function () {
        Route::get('/', [TransferApiController::class, 'index']);
        Route::post('/', [TransferApiController::class, 'store']);
        Route::get('/{id}', [TransferApiController::class, 'show']);
        Route::post('/{id}/approve', [TransferApiController::class, 'approve']);
        Route::post('/{id}/ship', [TransferApiController::class, 'ship']);
        Route::post('/{id}/receive', [TransferApiController::class, 'receive']);
        Route::post('/{id}/post', [TransferApiController::class, 'post']);
    });

    // Items
    Route::prefix('items')->group(function () {
        Route::get('/', [ItemController::class, 'index']);
        Route::get('/{id}', [ItemController::class, 'show']);
        Route::post('/', [ItemController::class, 'store']);
        Route::put('/{id}', [ItemController::class, 'update']);
        Route::delete('/{id}', [ItemController::class, 'destroy']);

        // Relacionados con items
        Route::get('/{itemId}/kardex', [KardexController::class, 'show']);
        Route::get('/{id}/batches', [StockController::class, 'batches']);
        Route::get('/{id}/vendors', [VendorController::class, 'byItem']);
        Route::post('/{id}/vendors', [VendorController::class, 'attach']);
    });

    // Precios de proveedores
    Route::post('/prices', [PriceController::class, 'store'])->middleware('throttle:30,1');

    // Orquestador de Inventario
    Route::post('/orquestador/daily-close', function (Request $request, \App\Services\Operations\DailyCloseService $dailyCloseService) {
        $date = $request->input('date', now()->subDay()->format('Y-m-d'));
        $branch = $request->input('branch', '1');

        $status = $dailyCloseService->run($branch, $date);

        return response()->json($status);
    });

    Route::post('/orquestador/recalcular-costos', function (Request $request, \App\Services\Recetas\RecalcularCostosRecetasService $recalcularCostosService) {
        $date = $request->input('date', now()->subDay()->format('Y-m-d'));
        $branch = $request->input('branch');

        $result = $recalcularCostosService->recalcularCostos($branch ? (int) $branch : null, $date);

        return response()->json($result);
    });

    Route::post('/orquestador/generar-snapshot', function (Request $request, \App\Services\Operations\DailyCloseService $dailyCloseService) {
        $date = $request->input('date', now()->subDay()->format('Y-m-d'));
        $branch = $request->input('branch', '1');

        // Para generar solo el snapshot, ejecutamos el servicio con el método específico
        // Simulamos la ejecución del proceso de cierre, pero solo retornamos el estado del snapshot
        $status = $dailyCloseService->run($branch, $date);

        return response()->json([
            'success' => true,
            'message' => 'Snapshot generado exitosamente',
            'date' => $date,
            'branch' => $branch,
            'snapshot_ok' => $status['semaphore']['snapshot_ok'] ?? false,
        ]);
    });
});

// Costeo de recetas
Route::prefix('recipes')->middleware(['auth:sanctum'])->group(function () {
    Route::get('/{id}/cost', [RecipeCostController::class, 'show']);
    // BOM Implosion endpoint
    Route::get('/{id}/bom/implode', [RecipeCostController::class, 'implodeBom']);

    // Cost Snapshots endpoints
    Route::post('/{id}/cost/snapshot', [RecipeCostController::class, 'createSnapshot']);
    Route::get('/{id}/cost/history', [RecipeCostController::class, 'getHistory']);
    Route::get('/{id}/cost/compare', [RecipeCostController::class, 'compareSnapshots']);
});

/*
|--------------------------------------------------------------------------
| MÓDULO: PRODUCCIÓN INTERNA
|--------------------------------------------------------------------------
*/
Route::prefix('production')->middleware(['auth:sanctum'])->group(function () {
    Route::get('/orders', [ProductionOrderController::class, 'index']);
    Route::get('/orders/{id}', [ProductionOrderController::class, 'show']);
    Route::post('/batch/plan', [ProductionController::class, 'plan']);
    Route::post('/batch/{batch_id}/consume', [ProductionController::class, 'consume']);
    Route::post('/batch/{batch_id}/complete', [ProductionController::class, 'complete']);
    Route::post('/batch/{batch_id}/post', [ProductionController::class, 'post']);
});

/*
|--------------------------------------------------------------------------
| MÓDULO: REPLENISHMENT (Motor de Reposición)
|--------------------------------------------------------------------------
*/
Route::prefix('purchasing/replenishment')->middleware(['auth:sanctum'])->group(function () {
    // Listar sugerencias con filtros
    Route::get('/suggestions', [ReplenishmentController::class, 'index']);

    // Ver detalle de una sugerencia
    Route::get('/suggestions/{id}', [ReplenishmentController::class, 'show']);

    // Calcular sugerencias manualmente
    Route::post('/calculate', [ReplenishmentController::class, 'calculate']);

    // Aprobar sugerencia
    Route::post('/suggestions/{id}/approve', [ReplenishmentController::class, 'approve']);

    // Rechazar sugerencia
    Route::post('/suggestions/{id}/reject', [ReplenishmentController::class, 'reject']);

    // Convertir sugerencia a PR o PO
    Route::post('/suggestions/{id}/convert', [ReplenishmentController::class, 'convert']);
});

// Alertas de costos
Route::get('/alerts', [AlertsController::class, 'index']);
Route::post('/alerts/{id}/ack', [AlertsController::class, 'acknowledge']);

/*
|--------------------------------------------------------------------------
| MÓDULO: CATÁLOGOS
|--------------------------------------------------------------------------
*/
Route::prefix('catalogs')->middleware(['auth:sanctum'])->group(function () {
    Route::get('/categories', [CatalogsController::class, 'categories']);
    Route::get('/almacenes', [CatalogsController::class, 'almacenes']);
    Route::get('/sucursales', [CatalogsController::class, 'sucursales']);
    Route::get('/unidades', [CatalogsController::class, 'unidades']);
    Route::get('/movement-types', [CatalogsController::class, 'movementTypes']);
});

Route::middleware('auth:sanctum')
    ->get('/me/permissions', [MeController::class, 'permissions'])
    ->name('api.me.permissions');

Route::prefix('people')->middleware(['auth:sanctum', 'permission:people.users.manage'])->group(function () {
    Route::get('/users', [\App\Http\Controllers\Api\PeopleController::class, 'users']);
    Route::get('/users/{id}/permissions', [\App\Http\Controllers\Api\PeopleController::class, 'userPermissions']);
    Route::post('/users/{id}/permissions', [\App\Http\Controllers\Api\PeopleController::class, 'updateUserPermissions']);
});

/*
|--------------------------------------------------------------------------
| MÓDULO: PURCHASING (COMPRAS)
|--------------------------------------------------------------------------
*/
Route::prefix('purchasing')->middleware(['auth:sanctum'])->group(function () {
    Route::get('/suggestions', [PurchaseSuggestionController::class, 'index']);
    Route::post('/suggestions/{id}/approve', [PurchaseSuggestionController::class, 'approve']);
    Route::post('/suggestions/{id}/convert', [PurchaseSuggestionController::class, 'convert']);

    Route::prefix('receptions')->group(function () {
        Route::post('/create-from-po/{purchase_order_id}', [ReceivingController::class, 'createFromPO']);
        Route::post('/{recepcion_id}/lines', [ReceivingController::class, 'setLines']);
        Route::post('/{recepcion_id}/validate', [ReceivingController::class, 'validateReception']);
        Route::post('/{recepcion_id}/post', [ReceivingController::class, 'postReception']);
        Route::post('/{recepcion_id}/costing', [ReceivingController::class, 'finalizeCosting']);
    });

    Route::prefix('returns')->group(function () {
        Route::post('/create-from-po/{purchase_order_id}', [ReturnController::class, 'createFromPO']);
        Route::post('/{return_id}/approve', [ReturnController::class, 'approve']);
        Route::post('/{return_id}/ship', [ReturnController::class, 'ship']);
        Route::post('/{return_id}/confirm', [ReturnController::class, 'confirm']);
        Route::post('/{return_id}/post', [ReturnController::class, 'post']);
        Route::post('/{return_id}/credit-note', [ReturnController::class, 'creditNote']);
    });
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

// Rutas de auditoría operacional
/*
|--------------------------------------------------------------------------
| MÓDULO: CIERRE DIARIO
|--------------------------------------------------------------------------
*/
Route::prefix('close')->middleware(['auth:sanctum'])->group(function () {
    Route::get('/status', function (Request $request, \App\Services\Operations\DailyCloseService $dailyCloseService) {
        $date = $request->query('date');
        $branch = $request->query('branch');

        if (! $date || ! $branch) {
            return response()->json(['error' => 'date and branch parameters are required'], 400);
        }

        $status = $dailyCloseService->run($branch, $date);

        return response()->json($status);
    });
});

Route::middleware(['auth:sanctum', 'permission:audit.view'])
    ->prefix('audit-log')
    ->group(function () {
        Route::get('/', [App\Http\Controllers\Audit\LogController::class, 'list'])->name('api.audit.log.list');
        Route::get('/{id}', [App\Http\Controllers\Audit\LogController::class, 'show'])->name('api.audit.log.show');
        Route::get('/users', [App\Http\Controllers\Audit\LogController::class, 'users'])->name('api.audit.log.users');
        Route::get('/modules', [App\Http\Controllers\Audit\LogController::class, 'modules'])->name('api.audit.log.modules');
    });

/*
|--------------------------------------------------------------------------
| Reports - Sales Mix (Sin autenticación para pruebas)
|--------------------------------------------------------------------------
*/
Route::prefix('reports/sales')
    ->middleware(['auth:sanctum', 'permission:reports.view'])
    ->group(function () {
        Route::get('/mix', [SalesMixController::class, 'index'])->name('api.reports.sales.mix');
        Route::get('/mix/today', [SalesMixController::class, 'today'])->name('api.reports.sales.mix.today');
        Route::get('/drawer', [SalesDrawerController::class, 'index'])->name('api.reports.sales.drawer');
        Route::get('/diagnostics', [SalesDiagController::class, 'index'])->name('api.reports.sales.diagnostics');
        Route::get('/mods', [SalesModsController::class, 'index'])->name('api.reports.sales.mods');
    });

Route::prefix('reports/tickets')
    ->middleware(['auth:sanctum', 'permission:reports.view'])
    ->group(function () {
        Route::get('/open', [\App\Http\Controllers\Reports\OpenTicketsController::class, 'index'])->name('api.reports.tickets.open');
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
        'timestamp' => now()->toIso8601String(),
    ], 404);
});
