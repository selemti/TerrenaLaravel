<?php

namespace App\Http\Controllers\Caja;

use App\Http\Controllers\Controller;
use App\Services\Caja\AnalyticsService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CortesHistoricoController extends Controller
{
    protected $analyticsService;

    public function __construct(AnalyticsService $analyticsService)
    {
        $this->analyticsService = $analyticsService;
    }

    /**
     * Mostrar histórico de cortes (precortes y postcortes)
     */
    public function index(Request $request)
    {
        // Filtro de fecha rápido
        $dateFilter = $request->input('date_filter', 'last_30_days');
        $fechaInicio = $request->input('fecha_inicio');
        $fechaFin = $request->input('fecha_fin');

        // Calcular fechas según filtro rápido
        if (! $fechaInicio || ! $fechaFin || $dateFilter !== 'custom') {
            switch ($dateFilter) {
                case 'today':
                    $fechaInicio = now()->format('Y-m-d');
                    $fechaFin = now()->format('Y-m-d');
                    break;
                case 'yesterday':
                    $fechaInicio = now()->subDay()->format('Y-m-d');
                    $fechaFin = now()->subDay()->format('Y-m-d');
                    break;
                case 'last_week':
                    $fechaInicio = now()->subDays(7)->format('Y-m-d');
                    $fechaFin = now()->format('Y-m-d');
                    break;
                case 'current_month':
                    $fechaInicio = now()->startOfMonth()->format('Y-m-d');
                    $fechaFin = now()->format('Y-m-d');
                    break;
                case 'last_month':
                    $fechaInicio = now()->subMonth()->startOfMonth()->format('Y-m-d');
                    $fechaFin = now()->subMonth()->endOfMonth()->format('Y-m-d');
                    break;
                case 'last_30_days':
                default:
                    $fechaInicio = now()->subDays(30)->format('Y-m-d');
                    $fechaFin = now()->format('Y-m-d');
                    break;
            }
        }

        $terminalId = $request->input('terminal_id');
        $estatus = $request->input('estatus');
        $cajeroUsuarioId = $request->input('cajero_usuario_id');
        $perPage = $request->input('per_page', 20);
        $search = $request->input('search');
        $sortBy = $request->input('sort', 'apertura_ts');
        $sortOrder = $request->input('order', 'desc');
        $excludeSundays = $request->input('exclude_sundays', false);

        // Filtros avanzados
        $diferenciaMin = $request->input('diferencia_min');
        $diferenciaMax = $request->input('diferencia_max');
        $soloAlertas = $request->input('solo_alertas', false);
        $sinValidar = $request->input('sin_validar', false);
        $veredicto = $request->input('veredicto');

        // Parámetros para auto-abrir wizard y retorno
        $autoOpen = $request->input('auto_open');
        $returnPath = $request->input('return');
        $action = $request->input('action');
        $sesionIdForWizard = $request->input('sesion_id');

        // Validar perPage
        if (! in_array($perPage, [10, 20, 50, 100, 'all'])) {
            $perPage = 20;
        }

        // Validar ordenamiento
        $allowedSorts = [
            'sesion_id' => 's.id',
            'apertura_ts' => 's.apertura_ts',
            'terminal_id' => 's.terminal_id',
            'cajero_nombre' => 'cajero_nombre',
            'estatus' => 's.estatus',
            'cantidad_tickets' => 'cantidad_tickets',
            'total_ventas' => 'total_ventas',
            'sistema_efectivo' => 'sistema_efectivo',
            'declarado_efectivo' => 'declarado_efectivo',
            'diferencia_efectivo' => 'diferencia_efectivo',
        ];

        if (! isset($allowedSorts[$sortBy])) {
            $sortBy = 'apertura_ts';
        }

        $sortOrder = strtolower($sortOrder) === 'asc' ? 'asc' : 'desc';

        // Query para obtener sesiones con sus cortes y datos adicionales
        $query = DB::connection('pgsql')
            ->table('selemti.sesion_cajon as s')
            ->leftJoin('selemti.precorte as pre', 's.id', '=', 'pre.sesion_id')
            ->leftJoin('selemti.postcorte as post', 's.id', '=', 'post.sesion_id')
            ->leftJoin('public.users as u', 's.cajero_usuario_id', '=', 'u.auto_id')
            ->leftJoin('selemti.vw_sesion_dpr as dpr', 's.id', '=', 'dpr.sesion_id')
            ->select([
                's.id as sesion_id',
                's.sucursal',
                's.terminal_id',
                's.terminal_nombre',
                's.apertura_ts',
                's.cierre_ts',
                's.estatus',
                's.opening_float as fondo_inicial',
                's.closing_float as fondo_final',
                DB::raw("CONCAT(u.first_name, ' ', u.last_name) as cajero_nombre"),
                DB::raw('CAST(u.user_id as text) as cajero_user_id'),
                // Precorte
                'pre.id as precorte_id',
                'pre.creado_en as precorte_fecha',
                'pre.estatus as precorte_estatus',
                'pre.declarado_efectivo as precorte_declarado',
                // Postcorte
                'post.id as postcorte_id',
                'post.creado_en as postcorte_fecha',
                'post.validado',
                'post.validado_en',
                'post.sistema_efectivo_esperado',
                'post.declarado_efectivo',
                'post.diferencia_efectivo',
                'post.diferencia_tarjetas',
                'post.diferencia_transferencias',
                'post.veredicto_efectivo',
                // Datos de ventas
                'dpr.net_sales as total_ventas',
                'dpr.ticket_count as cantidad_tickets',
                'dpr.cash_receipt_amount as sistema_efectivo',
            ])
            ->whereDate('s.apertura_ts', '>=', $fechaInicio)
            ->whereDate('s.apertura_ts', '<=', $fechaFin);

        // Filtros opcionales
        if ($terminalId) {
            $query->where('s.terminal_id', $terminalId);
        }

        if ($estatus) {
            $query->where('s.estatus', $estatus);
        }

        if ($cajeroUsuarioId) {
            $query->where('s.cajero_usuario_id', $cajeroUsuarioId);
        }

        // Filtro específico por sesión (para auto-abrir wizard)
        if ($sesionIdForWizard) {
            $query->where('s.id', $sesionIdForWizard);
        }

        // Filtros avanzados (requieren postcorte)
        if ($diferenciaMin !== null || $diferenciaMax !== null || $soloAlertas || $sinValidar || $veredicto) {
            // Asegurar que hay un postcorte
            $query->whereExists(function ($subquery) {
                $subquery->select(DB::raw(1))
                    ->from('selemti.postcorte as p')
                    ->whereRaw('p.sesion_id = s.id');
            });

            // Filtro por rango de diferencias
            if ($diferenciaMin !== null) {
                $query->whereRaw('EXISTS (SELECT 1 FROM selemti.postcorte p WHERE p.sesion_id = s.id AND p.diferencia_efectivo >= ?)', [$diferenciaMin]);
            }
            if ($diferenciaMax !== null) {
                $query->whereRaw('EXISTS (SELECT 1 FROM selemti.postcorte p WHERE p.sesion_id = s.id AND p.diferencia_efectivo <= ?)', [$diferenciaMax]);
            }

            // Solo alertas críticas
            if ($soloAlertas) {
                $query->whereRaw('EXISTS (SELECT 1 FROM selemti.postcorte p WHERE p.sesion_id = s.id AND (p.requiere_aprobacion = true AND p.aprobado_por IS NULL AND p.rechazado = false OR ABS(p.diferencia_efectivo) > 500))');
            }

            // Sin validar
            if ($sinValidar) {
                $query->whereRaw('EXISTS (SELECT 1 FROM selemti.postcorte p WHERE p.sesion_id = s.id AND p.validado = false)');
            }

            // Por veredicto
            if ($veredicto) {
                $query->whereRaw('EXISTS (SELECT 1 FROM selemti.postcorte p WHERE p.sesion_id = s.id AND p.veredicto_efectivo = ?)', [$veredicto]);
            }
        }

        // Búsqueda global
        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('s.id', 'LIKE', "%{$search}%")
                    ->orWhere('s.terminal_id', 'LIKE', "%{$search}%")
                    ->orWhere('s.terminal_nombre', 'LIKE', "%{$search}%")
                    ->orWhere(DB::raw("CONCAT(u.first_name, ' ', u.last_name)"), 'LIKE', "%{$search}%")
                    ->orWhere('u.user_id', 'LIKE', "%{$search}%");
            });
        }

        // Excluir domingos sin ventas (para gráficos/reportes)
        if ($excludeSundays) {
            $query->where(function ($q) {
                // Incluir domingos solo si tienen ventas
                $q->whereRaw('EXTRACT(DOW FROM s.apertura_ts) != 0')
                    ->orWhereNotNull('dpr.net_sales');
            });
        }

        // Aplicar ordenamiento
        $query->orderBy($allowedSorts[$sortBy], $sortOrder);

        // Paginación o mostrar todos
        if ($perPage === 'all') {
            $cortes = $query->get();
            // Crear un objeto similar a LengthAwarePaginator para la vista
            $cortes = new \Illuminate\Pagination\LengthAwarePaginator(
                $cortes,
                $cortes->count(),
                $cortes->count(),
                1,
                ['path' => $request->url(), 'query' => $request->query()]
            );
        } else {
            $cortes = $query->paginate((int) $perPage)->appends($request->except('page'));
        }

        // Obtener terminales para el filtro
        $terminales = DB::connection('pgsql')
            ->table('selemti.sesion_cajon')
            ->select('terminal_id', 'terminal_nombre')
            ->distinct()
            ->orderBy('terminal_id')
            ->get();

        // Obtener cajeros para el filtro
        $cajeros = $this->analyticsService->getCajerosConSesiones();

        // Obtener métricas para dashboard KPIs
        $metrics = $this->analyticsService->getDashboardMetrics($fechaInicio, $fechaFin);

        return view('caja.historico-cortes', [
            'title' => 'Histórico de Cortes',
            'active' => 'caja',
            'cortes' => $cortes,
            'terminales' => $terminales,
            'cajeros' => $cajeros,
            'metrics' => $metrics,
            'filtros' => [
                'date_filter' => $dateFilter,
                'fecha_inicio' => $fechaInicio,
                'fecha_fin' => $fechaFin,
                'terminal_id' => $terminalId,
                'estatus' => $estatus,
                'cajero_usuario_id' => $cajeroUsuarioId,
                'per_page' => $perPage,
                'search' => $search,
                'sort' => $sortBy,
                'order' => $sortOrder,
                'exclude_sundays' => $excludeSundays,
                // Filtros avanzados
                'diferencia_min' => $diferenciaMin,
                'diferencia_max' => $diferenciaMax,
                'solo_alertas' => $soloAlertas,
                'sin_validar' => $sinValidar,
                'veredicto' => $veredicto,
            ],
            // Parámetros para wizard
            'autoOpen' => $autoOpen,
            'returnPath' => $returnPath,
            'action' => $action,
            'sesionIdForWizard' => $sesionIdForWizard,
        ]);
    }

    /**
     * Ver detalle de un corte específico
     */
    public function show($sesionId)
    {
        $sesion = DB::connection('pgsql')
            ->table('selemti.sesion_cajon as s')
            ->leftJoin('public.users as u', 's.cajero_usuario_id', '=', 'u.auto_id')
            ->where('s.id', $sesionId)
            ->select([
                's.*',
                DB::raw("CONCAT(u.first_name, ' ', u.last_name) as cajero_nombre"),
                DB::raw('CAST(u.user_id as text) as cajero_user_id'),
            ])
            ->first();

        if (! $sesion) {
            abort(404, 'Sesión no encontrada');
        }

        // Obtener precorte con datos calculados desde vw_sesion_dpr
        $precorteBase = DB::connection('pgsql')
            ->table('selemti.precorte')
            ->where('sesion_id', $sesionId)
            ->first();

        $precorte = null;
        if ($precorteBase) {
            // Obtener datos del sistema desde vw_sesion_dpr
            $dprData = DB::connection('pgsql')
                ->table('selemti.vw_sesion_dpr')
                ->where('sesion_id', $sesionId)
                ->first();

            $precorte = (object) [
                'id' => $precorteBase->id,
                'sesion_id' => $precorteBase->sesion_id,
                'sistema_efectivo' => $dprData->cash_receipt_amount ?? 0,
                'declarado_efectivo' => $precorteBase->declarado_efectivo,
                'diferencia_efectivo' => $precorteBase->declarado_efectivo - ($dprData->cash_receipt_amount ?? 0),
                'creado_en' => $precorteBase->creado_en,
                'estatus' => $precorteBase->estatus,
                'notas' => $precorteBase->notas,
            ];
        }

        $postcorte = DB::connection('pgsql')
            ->table('selemti.postcorte')
            ->where('sesion_id', $sesionId)
            ->first();

        // Obtener tickets de la sesión
        $tickets = DB::connection('pgsql')
            ->table('public.ticket as t')
            ->where('t.terminal_id', $sesion->terminal_id)
            ->whereDate('t.create_date', '>=', $sesion->apertura_ts)
            ->where(function ($query) use ($sesion) {
                $query->whereNull('t.closing_date')
                    ->orWhereDate('t.closing_date', '<=', $sesion->cierre_ts ?? now());
            })
            ->select([
                't.id',
                't.create_date',
                't.closing_date',
                't.total_price',
                't.paid',
                't.voided',
                't.status',
            ])
            ->orderBy('t.create_date')
            ->limit(100)
            ->get();

        return view('caja.detalle-corte', [
            'title' => "Detalle Corte - Sesión #{$sesionId}",
            'active' => 'caja',
            'sesion' => $sesion,
            'precorte' => $precorte,
            'postcorte' => $postcorte,
            'tickets' => $tickets,
        ]);
    }
}
