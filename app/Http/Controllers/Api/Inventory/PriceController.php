<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Actions\Inventory\StoreVendorPrice;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Inventory\StoreVendorPriceRequest;
use Illuminate\Http\JsonResponse;

class PriceController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth', 'can:inventory.prices.manage']);
    }

    public function store(StoreVendorPriceRequest $request, StoreVendorPrice $action): JsonResponse
    {
        $payload = $request->validated();

        $latest = $action->execute($payload);

        $responseData = [
            'message' => 'Precio registrado correctamente.',
            'data' => $latest,
        ];

        return response()->json($responseData, 201);
    }
}
