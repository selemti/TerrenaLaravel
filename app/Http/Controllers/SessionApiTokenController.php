<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class SessionApiTokenController extends Controller
{
    /**
     * Create a new Sanctum token for the authenticated user.
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function tokenForJs(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['error' => 'Unauthenticated'], 401);
        }

        $token = $user->createToken('browser-dashboard')->plainTextToken;

        return response()->json([
            'token' => $token,
        ]);
    }
}