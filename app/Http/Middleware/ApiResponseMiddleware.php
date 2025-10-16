<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ApiResponseMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Forzar Accept header para APIs
        if (!$request->headers->has('Accept')) {
            $request->headers->set('Accept', 'application/json');
        }
        
        $response = $next($request);
        
        // Agregar headers de respuesta
        $response->headers->set('X-API-Version', '2.0');
        $response->headers->set('Cache-Control', 'no-cache, no-store, must-revalidate');
        
        // CORS headers (ajustar según necesidad)
        if (config('app.env') === 'local') {
            $response->headers->set('Access-Control-Allow-Origin', '*');
            $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
            $response->headers->set('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, X-CSRF-Token, Authorization');
        }
        
        // Asegurar que errores 500 devuelvan JSON
        if ($response->getStatusCode() >= 500 && !$response->headers->has('Content-Type')) {
            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'message' => config('app.debug') ? $response->getContent() : 'Error interno del servidor',
                'timestamp' => now()->toIso8601String()
            ], 500);
        }
        
        return $response;
    }
}