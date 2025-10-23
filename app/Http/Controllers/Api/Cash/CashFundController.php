<?php

namespace App\Http\Controllers\Api\Cash;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Cash\CloseCashFundRequest;
use App\Http\Requests\Api\Cash\OpenCashFundRequest;
use App\Http\Requests\Api\Cash\RegisterCashFundMovementRequest;
use App\Services\Cash\CashFundService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CashFundController extends Controller
{
    public function __construct(private readonly CashFundService $service)
    {
        $this->middleware(['auth']);
        $this->middleware('can:cashfund.view')->only('index');
        $this->middleware('can:cashfund.manage')->except('index');
    }

    public function index(): JsonResponse
    {
        $connection = DB::connection('pgsql');

        $records = rescue(function () use ($connection) {
            if (! Schema::connection('pgsql')->hasTable('caja_fondo')) {
                return collect();
            }

            return $connection->table('caja_fondo')
                ->select(['id', 'sucursal_id', 'fecha', 'monto_inicial', 'moneda', 'estado', 'creado_en'])
                ->orderByDesc('fecha')
                ->limit(50)
                ->get();
        }, collect(), report: false);

        return response()->json([
            'data' => $records,
        ]);
    }

    public function store(OpenCashFundRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['creado_por'] = (int) $request->user()->getAuthIdentifier();

        $id = $this->service->open($data);

        return response()->json([
            'message' => 'Fondo de caja creado correctamente.',
            'data' => [
                'id' => $id,
            ],
        ], 201);
    }

    public function storeMovement(RegisterCashFundMovementRequest $request, int $fund): JsonResponse
    {
        $data = $request->validated();
        $data['creado_por'] = (int) $request->user()->getAuthIdentifier();

        $attachments = $data['attachments'] ?? [];
        unset($data['attachments']);

        $movementId = $this->service->registerMovement($fund, $data);

        if (! empty($attachments)) {
            $this->service->recordAttachments($movementId, $attachments);
        }

        return response()->json([
            'message' => 'Movimiento registrado.',
            'data' => [
                'id' => $movementId,
            ],
        ], 201);
    }

    public function approve(Request $request, int $movement): JsonResponse
    {
        if (! $request->user()?->can('cashfund.manage')) {
            abort(403);
        }

        $approver = (int) $request->user()->getAuthIdentifier();

        $this->service->approveMovement($movement, $approver);

        return response()->json([
            'message' => 'Movimiento aprobado.',
        ]);
    }

    public function close(CloseCashFundRequest $request, int $fund): JsonResponse
    {
        $data = $request->validated();
        $data['cerrado_por'] = (int) $request->user()->getAuthIdentifier();

        $this->service->closeFund($fund, $data);

        return response()->json([
            'message' => 'Fondo cerrado correctamente.',
        ]);
    }
}
