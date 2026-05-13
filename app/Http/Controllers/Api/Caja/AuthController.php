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
        $validated = $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        try {
            $user = User::where('email', $validated['email'])->first();

            // Verificar credenciales (ajusta según tu esquema)
            if (! $user || ! Hash::check($validated['password'], $user->password)) {
                return response()->json([
                    'error' => 'Unauthorized',
                    'message' => 'Credenciales inválidas',
                ], 401);
            }

            // Generar token (usando Laravel Sanctum)
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
            'message' => 'Use POST con { "email": "string", "password": "string" } para autenticarse.',
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
