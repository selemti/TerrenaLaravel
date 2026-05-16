<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Services\Inventory\StockAlertService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StockAlertController extends Controller
{
    public function __construct(private StockAlertService $service) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'sucursal_id' => 'nullable|string|max:36',
            'almacen_id' => 'nullable|string|max:36',
            'severity' => 'nullable|string|in:critical,low',
            'per_page' => 'nullable|integer|min:1|max:200',
            'page' => 'nullable|integer|min:1',
        ]);

        return response()->json([
            'ok' => true,
            'data' => $this->service->getAlerts($filters),
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
