<?php

namespace App\Helpers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CajaHelper
{
    public static function qp(Request $request, string $key, $default = null)
    {
        $query = $request->query($key);
        $body = $request->input($key);
        return $body ?? $query ?? $default;
    }

    public static function J(JsonResponse $response, array $data, int $code = 200): JsonResponse
    {
        return response()->json($data, $code);
    }

    public static function ver(float $d): string
    {
        return abs($d) < 0.005 ? 'CUADRA' : ($d > 0 ? 'A_FAVOR' : 'EN_CONTRA');
    }
}