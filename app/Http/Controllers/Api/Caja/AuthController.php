<?php

namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AuthController extends Controller
{
    /**
     * Login endpoint para la API de caja
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        try {
            // Buscar usuario en la base de datos
            $user = User::where('username', $validated['username'])->first();

            // Verificar credenciales (ajusta según tu esquema)
            if (!$user || !Hash::check($validated['password'], $user->password)) {
                return response()->json([
                    'error' => 'Unauthorized',
                    'message' => 'Credenciales inválidas'
                ], 401);
            }

            // Generar token (usando Laravel Sanctum)
            $token = $user->createToken('pos-token')->plainTextToken;

            return response()->json([
                'ok' => true,
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'username' => $user->username,
                    'name' => $user->name ?? "{$user->first_name} {$user->last_name}",
                    'role' => $user->role ?? 'cajero',
                ],
            ]);

        } catch (\Throwable $e) {
            \Log::error("Error en auth/login: " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'Error interno',
                'message' => config('app.debug') ? $e->getMessage() : 'Error en autenticación'
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
            'message' => 'Use POST con { "username": "string", "password": "string" } para autenticarse.',
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
            'message' => 'Sesión cerrada exitosamente'
        ]);
    }
}