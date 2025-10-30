<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use App\Services\Purchasing\PurchasingService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class PurchaseSuggestionController extends Controller
{
    protected PurchasingService $purchasingService;

    public function __construct(PurchasingService $purchasingService)
    {
        $this->purchasingService = $purchasingService;
    }

    /**
     * GET /api/purchasing/suggestions
     */
    public function index(Request $request): JsonResponse
    {
        // TODO: autorización basada en permisos dinámicos
        $filters = $request->only(['estado', 'prioridad', 'sucursal_id']);
        $suggestions = $this->purchasingService->listSuggestions($filters);

        return response()->json([
            'ok' => true,
            'data' => $suggestions,
        ]);
    }

    /**
     * POST /api/purchasing/suggestions/{id}/approve
     */
    public function approve(int $id, Request $request): JsonResponse
    {
        // TODO: autorización basada en permisos dinámicos
        $userId = $request->user()->id ?? 1;

        $suggestion = $this->purchasingService->approveSuggestion($id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $suggestion,
            'message' => 'Sugerencia aprobada exitosamente',
        ]);
    }

    /**
     * POST /api/purchasing/suggestions/{id}/convert
     */
    public function convert(int $id, Request $request): JsonResponse
    {
        // TODO: autorización basada en permisos dinámicos
        $userId = $request->user()->id ?? 1;

        $result = $this->purchasingService->convertSuggestionToRequest($id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $result,
            'message' => 'Sugerencia convertida a solicitud de compra exitosamente',
        ]);
    }
}
