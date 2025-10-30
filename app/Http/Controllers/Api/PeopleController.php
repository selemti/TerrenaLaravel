<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Spatie\Permission\Models\Permission;

class PeopleController extends Controller
{
    /**
     * GET /api/people/users
     * Devuelve una lista básica de usuarios con roles.
     */
    public function users(Request $request)
    {
        // TODO: protección con auth:sanctum + permission:people.users.manage en routes/api.php
        $list = User::query()
            ->select('id', 'username', 'nombre_completo')
            ->with(['roles:id,name'])
            ->get()
            ->map(function ($user) {
                return [
                    'id' => $user->id,
                    'username' => $user->username,
                    'name' => $user->nombre_completo,
                    'roles' => $user->roles->pluck('name')->toArray(),
                ];
            });

        return response()->json([
            'data' => $list,
        ]);
    }

    /**
     * GET /api/people/users/{id}/permissions
     * Devuelve permisos heredados por rol, asignados directos y efectivos.
     */
    public function userPermissions(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $direct = $user->permissions->pluck('name')->toArray();

        $rolePerms = [];
        foreach ($user->roles as $role) {
            $rolePerms = array_merge(
                $rolePerms,
                $role->permissions->pluck('name')->toArray()
            );
        }
        $rolePerms = array_values(array_unique($rolePerms));

        $effective = array_values(array_unique(array_merge($direct, $rolePerms)));

        if ($user->hasRole('Super Admin')) {
            $allPerms = Permission::all()->pluck('name')->toArray();
            $effective = array_values(array_unique(array_merge($effective, $allPerms)));
        }

        return response()->json([
            'user_id' => $user->id,
            'username' => $user->username,
            'direct_permissions' => $direct,
            'inherited_permissions' => $rolePerms,
            'effective_permissions' => $effective,
            'all_permissions' => Permission::all()->pluck('name')->toArray(),
        ]);
    }

    /**
     * POST /api/people/users/{id}/permissions
     * Body JSON: { "give": [...], "revoke": [...] }
     * Asigna o revoca permisos directos sin tocar los roles.
     */
    public function updateUserPermissions(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $give = $request->input('give', []);
        $revoke = $request->input('revoke', []);

        foreach ($give as $permission) {
            if (is_string($permission) && $permission !== '') {
                $user->givePermissionTo($permission);
            }
        }

        foreach ($revoke as $permission) {
            if (is_string($permission) && $permission !== '') {
                $user->revokePermissionTo($permission);
            }
        }

        return response()->json([
            'status' => 'ok',
            'message' => 'Permisos actualizados',
        ]);
    }
}
