<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CajaFondoController;
use App\Http\Controllers\Produccion\SolicitudesController;
use App\Http\Controllers\Produccion\OrdenesController;
use App\Http\Controllers\TransferenciasController;

Route::middleware('auth:sanctum')->group(function(){
  // Caja chica
  Route::post('/caja-fondo', [CajaFondoController::class,'store']);
  Route::post('/caja-fondo/{id}/mov', [CajaFondoController::class,'storeMov']);
  Route::post('/caja-fondo/mov/{id}/aprobar', [CajaFondoController::class,'aprobarMov']);
  Route::post('/caja-fondo/{id}/arqueo', [CajaFondoController::class,'arqueo']);
  Route::post('/caja-fondo/{id}/cerrar', [CajaFondoController::class,'cerrar']);
  Route::get('/caja-fondo/reportes', [CajaFondoController::class,'reportes']);

  // Producción
  Route::apiResource('/produccion/solicitudes', SolicitudesController::class);
  Route::apiResource('/produccion/ordenes', OrdenesController::class);
  Route::post('/produccion/ordenes/{id}/aprobar', [OrdenesController::class,'aprobar']);

  // Transferencias
  Route::apiResource('/transferencias', TransferenciasController::class);
  Route::post('/transferencias/{id}/despachar', [TransferenciasController::class,'despachar']);
  Route::post('/transferencias/{id}/recibir', [TransferenciasController::class,'recibir']);
});