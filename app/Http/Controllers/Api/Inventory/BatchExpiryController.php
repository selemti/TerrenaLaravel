<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Services\Inventory\BatchExpiryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BatchExpiryController extends Controller
{
    public function __construct(private BatchExpiryService $service) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'days' => 'nullable|integer|min:1|max:365',
            'almacen_id' => 'nullable|string|max:36',
            'include_expired' => 'nullable|boolean',
            'only_with_qty' => 'nullable|boolean',
            'per_page' => 'nullable|integer|min:1|max:200',
            'page' => 'nullable|integer|min:1',
        ]);

        foreach (['include_expired', 'only_with_qty'] as $booleanFilter) {
            if ($request->has($booleanFilter)) {
                $filters[$booleanFilter] = $request->boolean($booleanFilter);
            }
        }

        return response()->json([
            'ok' => true,
            'data' => $this->service->getExpiringBatches($filters),
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
