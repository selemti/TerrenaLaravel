<?php

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


use App\Livewire\Recipes\RecipesIndex        as RecipesIndexLW;
use App\Livewire\Recipes\RecipeEditor        as RecipeEditorLW;

use App\Livewire\Kds\Board                   as KdsBoard;

/* =========================================================================
|  HOME (UNA sola definición, limpia y canónica)
|========================================================================= */
Route::get('/', function () {
    return auth()->check()
        ? redirect()->route('dashboard')
        : redirect()->route('login');
})->name('home');

/* =========================================================================
|  BLADES “estáticos” del menú principal
|========================================================================= */
Route::middleware('auth')->group(function () {
    Route::view('/dashboard',  'dashboard')->name('dashboard');
    Route::view('/compras',    'compras')->name('compras');
    Route::view('/inventario', 'inventario')->name('inventario'); // TU vista Blade
    Route::view('/personal',   'personal')->name('personal');
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
