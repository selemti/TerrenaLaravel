<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RecipeCostController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth:sanctum', 'permission:can_view_recipe_dashboard']);
    }

    public function show(Request $request, $id): JsonResponse
    {
        $at = $request->query('at');

        try {
            $moment = $at ? Carbon::parse($at) : now();
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'El parámetro at debe ser una fecha válida.',
            ], 422);
        }

        $result = DB::connection('pgsql')->selectOne(
            'SELECT * FROM selemti.fn_recipe_cost_at(?, ?)',
            [$id, $moment->toDateTimeString()]
        );

        if (! $result) {
            return response()->json([
                'message' => 'No se encontró información de costo para la receta solicitada.',
            ], 404);
        }

        return response()->json([
            'data' => (array) $result,
            'requested_at' => $moment->toIso8601String(),
        ]);
    }
}
