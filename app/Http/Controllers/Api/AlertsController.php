<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AlertsController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $handledParam = $request->query('handled');

        $query = DB::connection('pgsql')
            ->table('selemti.alert_events')
            ->orderByDesc('created_at');

        if ($handledParam !== null) {
            $handled = filter_var($handledParam, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);

            if ($handled === null && ! in_array($handledParam, ['0', '1', 0, 1], true)) {
                return response()->json([
                    'message' => 'El parámetro handled debe ser 0 o 1.',
                ], 422);
            }

            $handled = $handled ?? ($handledParam == 1);
            $query->where('handled', $handled);
        }

        $alerts = $query->get([
            'id',
            'recipe_id',
            'snapshot_at',
            'old_portion_cost',
            'new_portion_cost',
            'delta_pct',
            'created_at',
            'handled',
        ]);

        return response()->json(['data' => $alerts]);
    }

    public function acknowledge(int $id): JsonResponse
    {
        $updated = DB::connection('pgsql')
            ->table('selemti.alert_events')
            ->where('id', $id)
            ->update(['handled' => true]);

        if (! $updated) {
            return response()->json([
                'message' => 'No se encontró la alerta solicitada.',
            ], 404);
        }

        return response()->json([
            'message' => 'Alerta marcada como atendida.',
        ]);
    }
}
