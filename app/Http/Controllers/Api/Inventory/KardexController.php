<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Services\Inventory\KardexService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KardexController extends Controller
{
    public function __construct(private KardexService $service) {}

    public function show(Request $request, string $itemId): JsonResponse
    {
        $filters = $request->validate([
            'from' => 'nullable|date_format:Y-m-d',
            'to' => 'nullable|date_format:Y-m-d|after_or_equal:from',
            'almacen_id' => 'nullable|string|max:36',
            'tipo' => 'nullable|string|in:ENTRADA,SALIDA,AJUSTE,MERMA,PRODUCCION,CONSUMO,TRASPASO_SALIDA,TRASPASO_ENTRADA',
            'per_page' => 'nullable|integer|min:1|max:200',
            'page' => 'nullable|integer|min:1',
        ]);

        try {
            $data = $this->service->getKardex($itemId, $filters);
        } catch (ModelNotFoundException) {
            return response()->json([
                'ok' => false,
                'error' => 'item_not_found',
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
