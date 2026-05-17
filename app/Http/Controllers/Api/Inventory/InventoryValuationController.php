<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Services\Inventory\InventoryValuationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InventoryValuationController extends Controller
{
    public function __construct(private InventoryValuationService $service) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'almacen_id' => 'nullable|string|max:36',
            'sucursal_id' => 'nullable|string|max:36',
            'categoria' => 'nullable|string|max:100',
            'only_with_stock' => 'nullable|boolean',
            'per_page' => 'nullable|integer|min:1|max:200',
            'page' => 'nullable|integer|min:1',
        ]);

        if ($request->has('only_with_stock')) {
            $filters['only_with_stock'] = $request->boolean('only_with_stock');
        }

        return response()->json([
            'ok' => true,
            'data' => $this->service->getValuation($filters),
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
