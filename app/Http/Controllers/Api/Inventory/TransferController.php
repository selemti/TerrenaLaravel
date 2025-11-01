<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Models\Inventory\TransferHeader;
use App\Services\Inventory\TransferService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class TransferController extends Controller
{
    public function __construct(private readonly TransferService $transferService)
    {
        $this->middleware(['auth:sanctum', 'permission:can_manage_transfers']);
    }

    public function index(Request $request): JsonResponse
    {
        try {
            $query = TransferHeader::with(['origenAlmacen', 'destinoAlmacen', 'creadaPor']);

            if ($request->filled('estado')) {
                $query->where('estado', $request->string('estado'));
            }

            if ($request->filled('almacen_origen_id')) {
                $query->where('origen_almacen_id', $request->integer('almacen_origen_id'));
            }

            if ($request->filled('almacen_destino_id')) {
                $query->where('destino_almacen_id', $request->integer('almacen_destino_id'));
            }

            if ($request->filled('desde')) {
                $query->whereDate('fecha_solicitada', '>=', $request->date('desde'));
            }

            if ($request->filled('hasta')) {
                $query->whereDate('fecha_solicitada', '<=', $request->date('hasta'));
            }

            $transfers = $query->orderByDesc('fecha_solicitada')->paginate(20);

            return response()->json([
                'ok' => true,
                'data' => $transfers,
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            Log::error('Error listando transferencias', ['error' => $e->getMessage()]);

            return response()->json([
                'ok' => false,
                'error' => 'TRANSFERS_LIST_ERROR',
                'message' => 'Error al listar transferencias',
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'origen_almacen_id' => ['required', 'integer', 'exists:selemti.cat_almacenes,id'],
            'destino_almacen_id' => ['required', 'integer', 'different:origen_almacen_id', 'exists:selemti.cat_almacenes,id'],
            'lineas' => ['required', 'array', 'min:1'],
            'lineas.*.item_id' => ['required', 'string', 'exists:selemti.items,id'],
            'lineas.*.cantidad' => ['required', 'numeric', 'min:0.001'],
            'lineas.*.uom_id' => ['required', 'integer', 'exists:selemti.cat_unidades,id'],
            'lineas.*.costo_unitario' => ['nullable', 'numeric', 'min:0'],
        ]);

        try {
            $result = $this->transferService->createTransfer(
                fromAlmacenId: $validated['origen_almacen_id'],
                toAlmacenId: $validated['destino_almacen_id'],
                lines: $validated['lineas'],
                userId: (int) $request->user()->id
            );

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Transferencia creada exitosamente',
                'timestamp' => now()->toIso8601String(),
            ], 201);
        } catch (Throwable $e) {
            Log::error('Error creando transferencia', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'TRANSFER_CREATE_ERROR',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $transfer = TransferHeader::with([
                'origenAlmacen',
                'destinoAlmacen',
                'lineas.item.uom',
                'creadaPor',
                'aprobadaPor',
                'despachadaPor',
                'recibidaPor',
                'posteadaPor',
            ])->findOrFail($id);

            return response()->json([
                'ok' => true,
                'data' => $transfer,
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'ok' => false,
                'error' => 'TRANSFER_NOT_FOUND',
                'message' => 'Transferencia no encontrada',
                'timestamp' => now()->toIso8601String(),
            ], 404);
        }
    }

    public function approve(int $id, Request $request): JsonResponse
    {
        try {
            $result = $this->transferService->approveTransfer(
                transferId: $id,
                userId: (int) $request->user()->id
            );

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Transferencia aprobada',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            Log::error('Error aprobando transferencia', [
                'transfer_id' => $id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'APPROVAL_ERROR',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }
    }

    public function ship(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'guia' => ['nullable', 'string', 'max:64'],
        ]);

        try {
            $result = $this->transferService->markInTransit(
                transferId: $id,
                userId: (int) $request->user()->id,
                guia: $validated['guia'] ?? null
            );

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Transferencia despachada',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'ok' => false,
                'error' => 'SHIP_ERROR',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }
    }

    public function receive(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'lineas' => ['required', 'array', 'min:1'],
            'lineas.*.line_id' => ['required', 'integer'],
            'lineas.*.cantidad_recibida' => ['required', 'numeric', 'min:0'],
            'lineas.*.observaciones' => ['nullable', 'string', 'max:500'],
        ]);

        try {
            $result = $this->transferService->receiveTransfer(
                transferId: $id,
                receivedLines: $validated['lineas'],
                userId: (int) $request->user()->id
            );

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Transferencia recibida',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'ok' => false,
                'error' => 'RECEIVE_ERROR',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }
    }

    public function post(int $id, Request $request): JsonResponse
    {
        try {
            $result = $this->transferService->postTransferToInventory(
                transferId: $id,
                userId: (int) $request->user()->id
            );

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Transferencia posteada a inventario',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            Log::error('Error posteando transferencia', [
                'transfer_id' => $id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'POST_ERROR',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }
    }
}
