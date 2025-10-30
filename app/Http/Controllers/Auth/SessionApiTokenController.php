<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controller for generating Sanctum tokens for authenticated web users.
 * This allows the frontend to make authenticated API calls using Bearer tokens.
 */
class SessionApiTokenController extends Controller
{
    /**
     * Generate a new Sanctum API token for the authenticated user.
     *
     * @route GET /session/api-token
     * @middleware auth (web)
     * @param Request $request
     * @return JsonResponse
     */
    public function generate(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'error' => 'Unauthenticated',
                'message' => 'No hay usuario autenticado en la sesión web.',
            ], 401);
        }

        // Revoke previous browser tokens to avoid accumulation
        $user->tokens()->where('name', 'browser-dashboard')->delete();

        // Create new token
        $token = $user->createToken('browser-dashboard');

        return response()->json([
            'token' => $token->plainTextToken,
            'user_id' => $user->id,
            'username' => $user->username ?? $user->name,
        ]);
    }

    /**
     * Revoke the current browser token.
     *
     * @route POST /session/api-token/revoke
     * @middleware auth (web)
     * @param Request $request
     * @return JsonResponse
     */
    public function revoke(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['error' => 'Unauthenticated'], 401);
        }

        // Revoke all browser tokens
        $deleted = $user->tokens()->where('name', 'browser-dashboard')->delete();

        return response()->json([
            'message' => 'Tokens revocados exitosamente.',
            'revoked_count' => $deleted,
        ]);
    }
}
