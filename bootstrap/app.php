<?php

use App\Exceptions\CashFund\CashFundValidationException;
use App\Exceptions\Domain\DomainException;
use App\Exceptions\Inventory\InsufficientStockException;
use App\Exceptions\Inventory\InventoryValidationException;
use App\Exceptions\Inventory\InvalidInventoryStateException;
use App\Exceptions\Inventory\ItemNotFoundException;
use App\Exceptions\Transfer\InvalidTransferStateException;
use App\Exceptions\Transfer\TransferNotFoundException;
use App\Exceptions\Caja\InvalidCajaStateException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\JsonResponse;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'permission' => \Spatie\Permission\Middleware\PermissionMiddleware::class,
            'role' => \Spatie\Permission\Middleware\RoleMiddleware::class,
            'role_or_permission' => \Spatie\Permission\Middleware\RoleOrPermissionMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $jsonDomain = fn (DomainException $e, int $status): JsonResponse => response()->json([
            'ok' => false,
            'error' => $e->errorCode(),
            'message' => $e->getMessage(),
            'timestamp' => now()->toIso8601String(),
        ], $status);

        // 404 — entity not found
        $exceptions->render(fn (ItemNotFoundException $e) => $jsonDomain($e, 404));
        $exceptions->render(fn (TransferNotFoundException $e) => $jsonDomain($e, 404));

        // 409 — state machine conflict
        $exceptions->render(fn (InvalidInventoryStateException $e) => $jsonDomain($e, 409));
        $exceptions->render(fn (InvalidTransferStateException $e) => $jsonDomain($e, 409));
        $exceptions->render(fn (InvalidCajaStateException $e) => $jsonDomain($e, 409));

        // 422 — validation / constraint
        $exceptions->render(fn (InventoryValidationException $e) => $jsonDomain($e, 422));
        $exceptions->render(fn (InsufficientStockException $e) => $jsonDomain($e, 422));
        $exceptions->render(fn (CashFundValidationException $e) => $jsonDomain($e, 422));

        // 400 — any other domain exception
        $exceptions->render(fn (DomainException $e) => $jsonDomain($e, 400));
    })->create();
