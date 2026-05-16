<?php

namespace App\Http\Controllers\Production;

use App\Http\Controllers\Controller;
use App\Services\Production\ProductionOrderReadService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductionOrderController extends Controller
{
    public function __construct(private ProductionOrderReadService $service) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'estado' => 'nullable|string|in:BORRADOR,EN_PROCESO,COMPLETADO,POSTEADO,CANCELADO',
            'sucursal_id' => 'nullable|string|max:36',
            'from' => 'nullable|date_format:Y-m-d',
            'to' => 'nullable|date_format:Y-m-d|after_or_equal:from',
            'recipe_id' => 'nullable|integer',
            'per_page' => 'nullable|integer|min:1|max:100',
            'page' => 'nullable|integer|min:1',
        ]);

        return response()->json([
            'ok' => true,
            'data' => $this->service->list($filters),
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $data = $this->service->detail($id);
        } catch (ModelNotFoundException) {
            return response()->json([
                'ok' => false,
                'error' => 'order_not_found',
                'timestamp' => now()->toIso8601String(),
            ], 404);
        }

        return response()->json([
            'ok' => true,
            'data' => $data,
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
