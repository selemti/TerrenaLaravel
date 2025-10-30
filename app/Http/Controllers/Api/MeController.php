<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\Permission\Models\Permission;

/**
 * Controller to expose permissions for the authenticated user.
 */
class MeController extends Controller
{
    /**
     * Returns the list of effective permissions for the current user.
     *
     * @route GET /api/me/permissions
     * @param Request $request
     * @return JsonResponse
     */
    public function permissions(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['error' => 'Unauthenticated'], 401);
        }

        $userPerms = $user->getAllPermissions()->pluck('name')->toArray();

        if ($user->hasRole('Super Admin')) {
            $allPerms = Permission::all()->pluck('name')->toArray();
            $effective = array_values(array_unique(array_merge($userPerms, $allPerms)));
        } else {
            $effective = $userPerms;
        }

        return response()->json([
            'user_id' => $user->id,
            'username' => $user->username ?? $user->name,
            'permissions' => $effective,
        ]);
    }
}
