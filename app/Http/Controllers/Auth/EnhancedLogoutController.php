<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EnhancedLogoutController extends Controller
{
    /**
     * Revoca el token Sanctum y cierra la sesión.
     *
     * @route POST /logout/enhanced
     * @middleware auth
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        
        if ($user) {
            // Revocar tokens Sanctum de navegador
            $user->tokens()->where('name', 'browser-dashboard')->delete();
        }
        
        // Cerrar sesión web
        Auth::guard('web')->logout();
        
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        
        return response()->json([
            'message' => 'Sesión cerrada exitosamente',
            'cache_cleared' => true
        ]);
    }
}