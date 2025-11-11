<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\URL;
use Symfony\Component\HttpFoundation\Response;

class DynamicUrlMiddleware
{
    /**
     * Handle an incoming request.
     *
     * Dynamically sets the application URL based on the incoming request's
     * scheme and host. This allows the application to work correctly when
     * accessed from multiple IPs (e.g., LAN and Tailscale VPN).
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Solo aplicar en producción (no en desarrollo local)
        if (app()->environment('production')) {
            // Detectar host y scheme desde el request actual
            $url = $request->getSchemeAndHttpHost() . '/terrena2';
            URL::forceRootUrl($url);
        }

        return $next($request);
    }
}
