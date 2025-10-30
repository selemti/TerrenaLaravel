<?php

protected $middlewareGroups = [
    'web' => [
        // ... otros middleware
    ],
    
    'api' => [
        \App\Http\Middleware\ApiResponseMiddleware::class,  // 👈 Agregar esta línea
        \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        'throttle:api',
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],
];

// También agregar alias si quieres usarlo individualmente
protected $middlewareAliases = [
    // ... otros alias
    'api.response' => \App\Http\Middleware\ApiResponseMiddleware::class,
    'permission' => \Spatie\Permission\Middlewares\PermissionMiddleware::class,
    'perm' => \App\Http\Middleware\CheckPermission::class,

];
