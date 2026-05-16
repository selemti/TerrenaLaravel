<?php

namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * Login endpoint para la API de caja
     */
    public function login(Request $request): JsonResponse
    {
        // Accept either 'email' or 'username' field — legacy POS clients send 'username'
        $request->validate([
            'password' => 'required|string',
        ]);

        $credential = $request->input('email') ?? $request->input('username');

        if (empty($credential)) {
            return response()->json([
                'ok' => false,
                'error' => 'validation_error',
                'message' => 'Se requiere el campo email o username.',
            ], 422);
        }

        try {
            // Try email first, then fall back to name (for username-style logins)
            $user = User::where('email', $credential)->first()
                ?? User::where('name', $credential)->first();

            if (! $user || ! Hash::check($request->input('password'), $user->password)) {
                return response()->json([
                    'error' => 'Unauthorized',
                    'message' => 'Credenciales inválidas',
                ], 401);
            }

            $token = $user->createToken('pos-token')->plainTextToken;

            return response()->json([
                'ok' => true,
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'name' => $user->name,
                    'role' => $user->role ?? 'cajero',
                ],
            ]);

        } catch (\Throwable $e) {
            \Log::error('Error en auth/login: '.$e->getMessage());

            return response()->json([
                'ok' => false,
                'error' => 'Error interno',
                'message' => config('app.debug') ? $e->getMessage() : 'Error en autenticación',
            ], 500);
        }
    }

    /**
     * Endpoint de ayuda cuando se usa método incorrecto
     */
    public function loginHelp(): JsonResponse
    {
        return response()->json([
            'error' => 'Método no permitido',
            'message' => 'Use POST con { "email": "string", "password": "string" } o { "username": "string", "password": "string" } para autenticarse.',
        ], 405)->header('Allow', 'POST');
    }

    /**
     * Logout (opcional - revoca token de Sanctum)
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'ok' => true,
            'message' => 'Sesión cerrada exitosamente',
        ]);
    }
}
