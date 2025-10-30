<?php

namespace App\Http\Controllers\Reports;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

/**
 * Controlador para KPIs operativos de compras e inventario.
 */
class ReportsController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth:sanctum', 'permission:can_view_recipe_dashboard']);
    }

    /**
     * Lista las órdenes de compra que aún no tienen recepción posteada.
     *
     * @route GET /api/reports/purchasing/late-po
     * @return JsonResponse
     * @todo Agregar filtros por proveedor y rango de fechas.
     */
    public function purchasingLatePO(): JsonResponse
    {
        // TODO auth: requiere permiso reports.view.purchasing
        $rows = DB::table('purchase_orders as po')
            ->select([
                'po.id',
                'po.numero as po_number',
                'po.proveedor_id',
                'po.fecha_aprobacion',
                'po.fecha_estimada_recepcion',
                'recepciones.fecha_posteo as recepcion_posteada_at',
            ])
            ->leftJoin('recepcion_cab as recepciones', 'recepciones.purchase_order_id', '=', 'po.id')
            ->whereNull('recepciones.fecha_posteo')
            ->orderByDesc('po.fecha_aprobacion')
            ->limit(20)
            ->get();

        // TODO: caching/report snapshots
        return response()->json([
            'ok' => true,
            'data' => $rows,
        ]);
    }

    /**
     * Muestra recepciones fuera de tolerancia pendientes de aprobaciones.
     *
     * @route GET /api/reports/inventory/over-tolerance
     * @return JsonResponse
     * @todo Añadir joins a proveedores y exportación CSV.
     */
    public function inventoryOverTolerance(): JsonResponse
    {
        // TODO auth: requiere permiso reports.view.inventory
        $rows = DB::table('recepcion_det as rd')
            ->select([
                'rd.item_id',
                'rd.recepcion_id',
                'rd.qty_ordenada',
                'rd.qty_recibida',
                DB::raw('ABS(rd.qty_recibida - rd.qty_ordenada) / NULLIF(rd.qty_ordenada,0) * 100 as diferencia_pct'),
            ])
            ->join('recepcion_cab as rc', 'rc.id', '=', 'rd.recepcion_id')
            ->where('rc.requiere_aprobacion', true)
            ->orderByDesc('diferencia_pct')
            ->limit(50)
            ->get();

        // TODO: caching/report snapshots
        return response()->json([
            'ok' => true,
            'data' => $rows,
        ]);
    }

    /**
     * Devuelve el top de insumos con prioridad URGENTE para compra.
     *
     * @route GET /api/reports/inventory/top-urgent
     * @return JsonResponse
     * @todo Incorporar métricas de rotación y stock restante.
     */
    public function inventoryTopUrgent(): JsonResponse
    {
        // TODO auth: requiere permiso reports.view.inventory
        $rows = DB::table('purchase_suggestions as ps')
            ->select([
                'ps.id',
                'ps.item_id',
                'ps.prioridad',
                'ps.qty_sugerida',
                'ps.sucursal_id',
            ])
            ->where('ps.prioridad', 'URGENTE')
            ->orderByDesc('ps.updated_at')
            ->limit(10)
            ->get();

        // TODO: caching/report snapshots
        return response()->json([
            'ok' => true,
            'data' => $rows,
        ]);
    }
}
