<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Services\Audit\AuditLogService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class StockController extends Controller
{
    public function __construct(private AuditLogService $auditLogService)
    {
    }

    // GET /api/inventory/kpis
    public function kpis(Request $r)
    {
        $conn = DB::connection('pgsql');

        // Total items count
        $totalItems = $conn->table('selemti.items')
            ->where('activo', true)
            ->count();

        // Inventory value (using vw_stock_valorizado)
        $inventoryValue = $conn->table('selemti.vw_stock_valorizado')
            ->selectRaw('COALESCE(SUM(valor), 0) as total')
            ->first();

        // Low stock count (items below minimum stock policy)
        $lowStock = $conn->table('selemti.vw_stock_brechas')
            ->whereRaw('stock_actual < min_qty')
            ->count();

        // Expiring items (next 30 days)
        $expiringDate = Carbon::now()->addDays(30);
        $expiringItems = $conn->table('selemti.inventory_batch')
            ->where('estado', 'ACTIVO')
            ->whereNotNull('fecha_caducidad')
            ->where('fecha_caducidad', '<=', $expiringDate)
            ->where('cantidad_actual', '>', 0)
            ->count();

        return response()->json([
            'ok' => true,
            'data' => [
                'total_items' => $totalItems,
                'inventory_value' => round((float)($inventoryValue->total ?? 0), 2),
                'low_stock_count' => $lowStock,
                'expiring_items' => $expiringItems,
            ],
            'timestamp' => now()->toIso8601String()
        ]);
    }

    // GET /api/inventory/stock/list - Comprehensive stock list with filters
    public function stockList(Request $r)
    {
        $conn = DB::connection('pgsql');

        $query = $conn->table('selemti.items as i')
            ->leftJoin('selemti.vw_stock_valorizado as sv', function($join) use ($r) {
                $join->on('i.id', '=', 'sv.item_key');
                if ($r->filled('sucursal_id')) {
                    $join->where('sv.sucursal_id', $r->get('sucursal_id'));
                }
            })
            ->leftJoin('public.menu_category as cat', 'i.categoria_id', '=', DB::raw("'CAT-' || cat.id"))
            ->leftJoin('selemti.cat_unidades as u', 'i.unidad_medida_id', '=', 'u.id')
            ->select([
                'i.id as sku',
                'i.nombre',
                'i.descripcion',
                DB::raw('COALESCE(cat.name, i.categoria_id) as categoria'),
                'i.categoria_id',
                DB::raw('COALESCE(sv.stock, 0) as stock'),
                DB::raw('COALESCE(u.nombre, i.unidad_medida) as uom'),
                DB::raw('COALESCE(sv.costo_wac, i.costo_promedio, 0) as costo'),
                DB::raw('COALESCE(sv.valor, 0) as valor_total'),
                'i.activo',
                DB::raw("COALESCE(sv.sucursal_id, '0') as ubicacion_id")
            ]);

        // Search filter
        if ($term = $r->string('q')->toString()) {
            $query->where(function ($q) use ($term) {
                $q->where('i.id', 'ilike', "%{$term}%")
                  ->orWhere('i.nombre', 'ilike', "%{$term}%")
                  ->orWhere('i.descripcion', 'ilike', "%{$term}%");
            });
        }

        // Category filter
        if ($r->filled('categoria_id')) {
            $query->where('i.categoria_id', $r->get('categoria_id'));
        }

        // Status filter
        $status = $r->string('status')->toString();
        if ($status === 'active') {
            $query->where('i.activo', true);
        } elseif ($status === 'inactive') {
            $query->where('i.activo', false);
        } elseif ($status === 'low_stock') {
            // Items with stock below minimum
            $query->where('i.activo', true)
                  ->whereExists(function($q) {
                      $q->select(DB::raw(1))
                        ->from('selemti.vw_stock_brechas as sb')
                        ->whereColumn('sb.item_id', 'i.id')
                        ->whereRaw('sb.stock_actual < sb.min_qty');
                  });
        } elseif ($status === 'expiring') {
            // Items with batches expiring in next 30 days
            $expiringDate = Carbon::now()->addDays(30);
            $query->where('i.activo', true)
                  ->whereExists(function($q) use ($expiringDate) {
                      $q->select(DB::raw(1))
                        ->from('selemti.inventory_batch as b')
                        ->whereColumn('b.item_id', 'i.id')
                        ->where('b.estado', 'ACTIVO')
                        ->whereNotNull('b.fecha_caducidad')
                        ->where('b.fecha_caducidad', '<=', $expiringDate)
                        ->where('b.cantidad_actual', '>', 0);
                  });
        }

        // Ordering
        $orderBy = $r->string('order_by', 'nombre')->toString();
        $orderDir = $r->string('order_dir', 'asc')->toString();
        $query->orderBy($orderBy, $orderDir);

        $perPage = $r->integer('per_page', 25);
        $results = $query->paginate($perPage);

        return response()->json([
            'ok' => true,
            'data' => $results,
            'timestamp' => now()->toIso8601String()
        ]);
    }

    // GET /api/inventory/stock?item_id=...&ubicacion_id=...
    public function stockByItem(Request $r)
    {
        $q = DB::connection('pgsql')->table('selemti.inventory_batch')
            ->selectRaw('item_id, SUM(cantidad_actual) AS stock')
            ->groupBy('item_id');

        if ($r->filled('item_id'))      $q->where('item_id', $r->get('item_id'));
        if ($r->filled('ubicacion_id')) $q->where('ubicacion_id', $r->get('ubicacion_id'));

        return response()->json($q->get());
    }

    // GET /api/inventory/items/{id}/kardex
    public function kardex(Request $r, $itemId)
    {
        $q = DB::connection('pgsql')->table('selemti.mov_inv')
            ->where('item_id', $itemId)
            ->orderByDesc('ts');

        if ($r->filled('lote_id')) $q->where('lote_id', $r->get('lote_id'));
        if ($r->filled('from'))   $q->where('ts','>=',$r->date('from'));
        if ($r->filled('to'))     $q->where('ts','<=',$r->date('to'));

        $movements = $q->limit(100)->get();

        return response()->json([
            'ok' => true,
            'data' => $movements,
            'timestamp' => now()->toIso8601String()
        ]);
    }

    // GET /api/inventory/items/{id}/batches
    public function batches(Request $r, $itemId)
    {
        $q = DB::connection('pgsql')->table('selemti.inventory_batch')
            ->where('item_id', $itemId)
            ->orderByDesc('id');

        if ($r->filled('estado')) $q->where('estado', $r->get('estado'));

        return response()->json([
            'ok' => true,
            'data' => $q->paginate($r->integer('per_page',25)),
            'timestamp' => now()->toIso8601String()
        ]);
    }

    // POST /api/inventory/movements - Create quick stock movement
    public function createMovement(Request $r)
    {
        $data = $r->validate([
            'item_id' => 'required|string|max:20',
            'tipo' => 'required|string|in:ENTRADA,SALIDA,AJUSTE,MERMA',
            'cantidad' => 'required|numeric|min:0.001',
            'costo_unit' => 'nullable|numeric|min:0',
            'sucursal_id' => 'required|string',
            'razon' => 'nullable|string|max:255',
            'lote_id' => 'nullable|integer',
        ]);

        // Validar que el motivo sea obligatorio para operaciones críticas
        if (empty(trim($r->input('motivo', '')))) {
            return response()->json([
                'ok' => false,
                'error' => 'MOTIVO_REQUIRED',
                'message' => 'Motivo es obligatorio para crear movimiento de inventario.',
            ], 422);
        }

        // TODO: evidencia_url será obligatoria en producción. Si viene vacía aquí, estamos permitiendo temporalmente por QA.

        DB::connection('pgsql')->beginTransaction();

        try {
            // Create movement record
            $movementId = DB::connection('pgsql')->table('selemti.mov_inv')->insertGetId([
                'ts' => now(),
                'item_id' => $data['item_id'],
                'lote_id' => $data['lote_id'] ?? null,
                'cantidad' => $data['cantidad'],
                'qty_original' => $data['cantidad'],
                'costo_unit' => $data['costo_unit'] ?? 0,
                'tipo' => $data['tipo'],
                'ref_tipo' => 'AJUSTE_MANUAL',
                'ref_id' => $data['razon'] ?? 'Movimiento rápido',
                'sucursal_id' => $data['sucursal_id'],
                'usuario_id' => auth()->id() ?? 0,
                'created_at' => now(),
            ]);

            DB::connection('pgsql')->commit();

            $user = $r->user();
            $this->auditLogService->logAction(
                (int) $user->id,
                'INVENTORY_ADJUST',
                'manual_movement',
                (int) $movementId,
                (string) $r->input('motivo', ''),
                $r->input('evidencia_url'),
                $r->all()
            );

            return response()->json([
                'ok' => true,
                'data' => ['id' => $movementId],
                'message' => 'Movimiento creado exitosamente',
                'timestamp' => now()->toIso8601String()
            ], 201);
        } catch (\Exception $e) {
            DB::connection('pgsql')->rollBack();

            return response()->json([
                'ok' => false,
                'error' => 'movement_creation_failed',
                'message' => 'Error al crear movimiento: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String()
            ], 500);
        }
    }
}
