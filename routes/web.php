<?php

use App\Http\Controllers\Auth\AuthenticatedSessionController;
use App\Http\Controllers\ProfileController;
use Illuminate\Support\Facades\Route;

/* =========================================================================
|  ENDPOINT DE DIAGNÓSTICO (opcional)
|========================================================================= */
Route::get('/__probe', function () {
    return response()->json([
        'request_full_url'     => request()->fullUrl(),
        'request_base_url'     => request()->getBaseUrl(),
        'request_path'         => request()->path(),
        'scheme_host'          => request()->getSchemeAndHttpHost(),
        'config_app_url'       => config('app.url'),
        'url_to_slash'         => url('/'),
        'url_to_dashboard'     => url('dashboard'),
        'route_dashboard'      => route('dashboard', [], false),
        'route_dashboard_abs'  => route('dashboard'),
        'uri'                  => request()->getRequestUri(),
        'app_url'              => config('app.url'),
        'document'             => $_SERVER['DOCUMENT_ROOT'] ?? null,
        'script'               => $_SERVER['SCRIPT_FILENAME'] ?? null,
        'public_htaccess_hint' => file_exists(public_path('.htaccess')) ? 'public/.htaccess found' : 'public/.htaccess MISSING',
    ]);
});

/* =========================================================================
|  IMPORTS LIVEWIRE
|========================================================================= */
use App\Livewire\Catalogs\UnidadesIndex      as CatalogUnidadesIndex;
use App\Livewire\Catalogs\UomConversionIndex as CatalogUomConversionIndex;
use App\Livewire\Catalogs\AlmacenesIndex     as CatalogAlmacenesIndex;
use App\Livewire\Catalogs\ProveedoresIndex   as CatalogProveedoresIndex;
use App\Livewire\Catalogs\SucursalesIndex    as CatalogSucursalesIndex;
use App\Livewire\Catalogs\StockPolicyIndex   as CatalogStockPolicyIndex;

//use App\Livewire\Inventory\ItemsManage       as InventoryItemsManage;
use App\Livewire\Inventory\ReceptionsIndex   as InventoryReceptionsIndex;
use App\Livewire\Inventory\ReceptionCreate   as InventoryReceptionCreate;
use App\Livewire\Inventory\LotsIndex         as InventoryLotsIndex;
use App\Livewire\Inventory\ItemsManage       as InventoryItemsManage;
use App\Livewire\Inventory\AlertsList        as InventoryAlertsList;
use App\Livewire\InventoryCount\Index        as InventoryCountIndex;
use App\Livewire\InventoryCount\Create       as InventoryCountCreate;
use App\Livewire\InventoryCount\Capture      as InventoryCountCapture;
use App\Livewire\InventoryCount\Review       as InventoryCountReview;
use App\Livewire\InventoryCount\Detail       as InventoryCountDetail;
use App\Livewire\People\UsersIndex           as PeopleUsersIndex;


use App\Livewire\Recipes\RecipesIndex        as RecipesIndexLW;
use App\Livewire\Recipes\RecipeEditor        as RecipeEditorLW;

use App\Livewire\Kds\Board                   as KdsBoard;

use App\Livewire\CashFund\Index             as CashFundIndex;
use App\Livewire\CashFund\Open              as CashFundOpen;
use App\Livewire\CashFund\Movements         as CashFundMovements;
use App\Livewire\CashFund\Arqueo            as CashFundArqueo;
use App\Livewire\CashFund\Approvals         as CashFundApprovals;
use App\Livewire\CashFund\Detail            as CashFundDetail;

use App\Livewire\Transfers\Create           as TransfersCreate;

use App\Livewire\Purchasing\Requests\Index  as PurchasingRequestsIndex;
use App\Livewire\Purchasing\Requests\Create as PurchasingRequestsCreate;
use App\Livewire\Purchasing\Requests\Detail as PurchasingRequestsDetail;
use App\Livewire\Purchasing\Orders\Index    as PurchasingOrdersIndex;
use App\Livewire\Purchasing\Orders\Detail   as PurchasingOrdersDetail;

use App\Livewire\Replenishment\Dashboard   as ReplenishmentDashboard;

/* =========================================================================
|  HOME (UNA sola definición, limpia y canónica)
|========================================================================= */
Route::get('/', function () {
    return auth()->check()
        ? redirect()->route('dashboard')
        : redirect()->route('login');
})->name('home');

Route::get('/dashboard', function () {
    return view('dashboard');
})->middleware('auth')->name('dashboard');

Route::get('/logout', [AuthenticatedSessionController::class, 'destroy'])
    ->middleware('auth')
    ->name('logout.fallback');

/* =========================================================================
|  BLADES “estáticos” del menú principal
|========================================================================= */
Route::middleware('auth')->group(function () {
    Route::view('/compras',    'compras')->name('compras');
    Route::view('/inventario', 'inventario')->name('inventario'); // TU vista Blade
    Route::get('/personal',    PeopleUsersIndex::class)
        ->middleware('can:people.view')
        ->name('personal');
    Route::view('/produccion', 'produccion')->name('produccion');
    Route::view('/recetas',    'recetas')->name('recetas');

    /* =========================================================================
    |  Catálogos (Livewire pages)
    |========================================================================= */
    Route::view('/catalogos', 'catalogos-index')->name('catalogos.index'); // Índice de catálogos

    Route::prefix('catalogos')->group(function () {
        Route::get('/unidades',     CatalogUnidadesIndex::class)->name('cat.unidades');
        Route::get('/uom',          CatalogUomConversionIndex::class)->name('cat.uom');
        Route::get('/almacenes',    CatalogAlmacenesIndex::class)->name('cat.almacenes');
        Route::get('/proveedores',  CatalogProveedoresIndex::class)->name('cat.proveedores');
        Route::get('/sucursales',   CatalogSucursalesIndex::class)->name('cat.sucursales');
        Route::get('/stock-policy', CatalogStockPolicyIndex::class)->name('cat.stockpolicy');
    });

    /* =========================================================================
    |  Inventario (Livewire pages dinámicas)
    |========================================================================= */
    Route::prefix('inventory')->group(function () {
        Route::get('/items',          InventoryItemsManage::class)->name('inventory.items.index');
        Route::get('/receptions',     InventoryReceptionsIndex::class)->name('inv.receptions');
        Route::get('/receptions/new', InventoryReceptionCreate::class)->name('inv.receptions.new');
        Route::get('/lots',           InventoryLotsIndex::class)->name('inv.lots');
        Route::get('/alerts',         InventoryAlertsList::class)->name('inv.alerts');

        // Conteos de Inventario
        Route::get('/counts',              InventoryCountIndex::class)->name('inv.counts.index');
        Route::get('/counts/create',       InventoryCountCreate::class)->name('inv.counts.create');
        Route::get('/counts/{id}/capture', InventoryCountCapture::class)->name('inv.counts.capture');
        Route::get('/counts/{id}/review',  InventoryCountReview::class)->name('inv.counts.review');
        Route::get('/counts/{id}/detail',  InventoryCountDetail::class)->name('inv.counts.detail');
    });

    /* =========================================================================
    |  Recetas (Livewire)
    |========================================================================= */
    Route::get('/recipes',              RecipesIndexLW::class)->name('rec.index');
    Route::get('/recipes/editor/{id?}', RecipeEditorLW::class)->name('rec.editor');

    /* =========================================================================
    |  KDS / Caja / Reportes / Admin
    |========================================================================= */
    Route::get('/kds', KdsBoard::class)->name('kds.board');
    Route::get('/caja/cortes', [App\Http\Controllers\Api\Caja\CajaController::class, 'index'])->name('caja.cortes');

    /* =========================================================================
    |  Caja Chica (Livewire)
    |========================================================================= */
    Route::prefix('cashfund')->group(function () {
        Route::get('/',                    CashFundIndex::class)->name('cashfund.index');
        Route::get('/open',                CashFundOpen::class)->name('cashfund.open');
        Route::get('/{id}/movements',      CashFundMovements::class)->name('cashfund.movements');
        Route::get('/{id}/arqueo',         CashFundArqueo::class)->name('cashfund.arqueo');
        Route::get('/{id}/detail',         CashFundDetail::class)->name('cashfund.detail');
        Route::get('/approvals',           CashFundApprovals::class)
            ->middleware('can:approve-cash-funds')
            ->name('cashfund.approvals');
    });

    /* =========================================================================
    |  Transferencias (Livewire)
    |========================================================================= */
    Route::prefix('transfers')->group(function () {
        Route::get('/',                    \App\Livewire\Transfers\Index::class)->name('transfers.index');
        Route::get('/create',              TransfersCreate::class)->name('transfers.create');
        // TODO: agregar rutas dispatch, receive cuando estén listas
    });

    /* =========================================================================
    |  Purchasing / Compras (Livewire)
    |========================================================================= */
    Route::prefix('purchasing')->group(function () {
        // Pedidos Sugeridos (Reposición Automática)
        Route::get('/replenishment',         ReplenishmentDashboard::class)->name('purchasing.replenishment.dashboard');

        // Solicitudes de Compra
        Route::get('/requests',              PurchasingRequestsIndex::class)->name('purchasing.requests.index');
        Route::get('/requests/create',       PurchasingRequestsCreate::class)->name('purchasing.requests.create');
        Route::get('/requests/{id}/detail',  PurchasingRequestsDetail::class)->name('purchasing.requests.detail');

        // Órdenes de Compra
        Route::get('/orders',                PurchasingOrdersIndex::class)->name('purchasing.orders.index');
        Route::get('/orders/{id}/detail',    PurchasingOrdersDetail::class)->name('purchasing.orders.detail');
    });

    Route::view('/reportes', 'placeholder', ['title'=>'Reportes'])->name('reportes');

    Route::view('/admin', 'placeholder', ['title' => 'Configuración'])
        ->middleware('can:admin.access')
        ->name('admin');

    Route::get('/profile', [ProfileController::class, 'index'])->name('profile.index');
    Route::put('/profile', [ProfileController::class, 'update'])->name('profile.update');
});

/* =========================================================================
|  Auth
|========================================================================= */
require __DIR__.'/auth.php';

// Rutas de autenticación Breeze/Jetstream
