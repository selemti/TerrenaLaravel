<?php
namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Collection;
use Carbon\Carbon;

class CajaController extends Controller
{
    public function index(Request $request)
    {
        $date = $request->query('date', Carbon::today()->format('Y-m-d'));  // Fecha por default

        // Query para cajas (raw SQL como en API)
        $sql = "
            WITH d AS (SELECT :day::date AS day),
            ultimas_sesiones AS (
                SELECT DISTINCT ON (terminal_id)
                    id, terminal_id, cajero_usuario_id, apertura_ts, cierre_ts,
                    estatus, opening_float, closing_float, skipped_precorte
                FROM selemti.sesion_cajon
                WHERE DATE(apertura_ts) = (SELECT day FROM d)
                ORDER BY terminal_id, apertura_ts DESC
            )
            SELECT
              t.id, COALESCE(t.name, t.id::text) AS name, COALESCE(t.location, '') AS location,
              us.opening_float, us.closing_float, us.cajero_usuario_id AS assigned_user,
              u.first_name || ' ' || u.last_name AS assigned_name, us.id AS sesion_id,
              (us.estatus = 'ACTIVA') AS activa, (us.cajero_usuario_id IS NOT NULL) AS asignada,
              EXISTS (SELECT 1 FROM selemti.precorte pr WHERE pr.sesion_id = us.id AND pr.estatus IN ('ENVIADO','APROBADO')) AS precorte_listo,
              NOT EXISTS (SELECT 1 FROM selemti.postcorte pc WHERE pc.sesion_id = us.id) AS sin_postcorte,
              (EXISTS (SELECT 1 FROM selemti.postcorte pc WHERE pc.sesion_id = us.id) AND us.cierre_ts IS NULL) AS postcorte_pendiente,
              COALESCE(us.skipped_precorte, FALSE) AS skipped_precorte
            FROM public.terminal t
            LEFT JOIN ultimas_sesiones us ON us.terminal_id = t.id
            LEFT JOIN public.users u ON u.auto_id = us.cajero_usuario_id
            ORDER BY t.id
        ";

        try {
            $results = DB::select($sql, ['day' => $date]);

            $cajas = collect($results)->map(function ($row) {
                return (object) [
                    'id' => (int) $row->id,
                    'name' => $row->name,
                    'location' => $row->location,
                    'opening_float' => (float) ($row->opening_float ?? 0),
                    'assigned_user' => (int) ($row->assigned_user ?? 0),
                    'assigned_name' => $row->assigned_name ?? '—',
                    'sesion_id' => (int) ($row->sesion_id ?? 0),
                    'activa' => (bool) $row->activa,
                    'asignada' => (bool) $row->asignada,
                    'precorte_listo' => (bool) $row->precorte_listo,
                    'sin_postcorte' => (bool) $row->sin_postcorte,
                    'postcorte_pendiente' => (bool) $row->postcorte_pendiente,
                    'skipped_precorte' => (bool) $row->skipped_precorte,
                ];
            });

            // KPIs calculados DESPUÉS de mapear $cajas
            $abiertas = $cajas->where('activa', true)->count();
            $precortes = $cajas->where('precorte_listo', true)->count();
            $conciliadas = $cajas->where('precorte_listo', true)->where('postcorte_pendiente', false)->count();
            $difProm = 0; // Placeholder; calcula promedio de diffs si tienes datos en BD (e.g., avg de precorte.diferencia)

            // Anulaciones para partial (query simple de Floreant; ajusta tabla/tipos si es necesario)
            $anulaciones = DB::table('transaction')  // Asumiendo 'transaction' en Floreant para anulaciones
                ->whereIn('type', ['VOID', 'CANCEL', 'REFUND'])  // Tipos comunes de anulaciones/devoluciones
                ->orderBy('created_date', 'desc')
                ->limit(5)
                ->get(['id as ticket_id', 'type as transaction_type', 'created_date as transaction_time', 'total as amount'])
                ->toArray();

            // Variable para active en el layout (para highlighting del menú)
            $active = 'cortes';  // Identificador para el menú de "Cortes de Caja"

            // PASA TODAS LAS VARS A LA VISTA CON COMPACT (AHORA COMPLETO, INCLUYENDO $active)
            return view('caja.cortes', compact(
                'cajas',      // Colección de terminales/cajas
                'date',       // Fecha actual (e.g., '2025-10-14')
                'abiertas',   // Número de cajas abiertas
                'precortes',  // Número de precortes
                'conciliadas', // Número de conciliadas
                'difProm',    // Diferencia promedio (0 por ahora)
                'anulaciones', // Array para partial _anulaciones
                'active'      // Para el layout terrena.blade.php (menú active)
            ));
        } catch (\Exception $e) {
            \Log::error("Error en CajaController@index (fecha: {$date}): " . $e->getMessage());
            // Fallback: vista con datos vacíos para no crashar
            return view('caja.cortes', [
                'cajas' => collect(),
                'date' => $date,
                'abiertas' => 0,
                'precortes' => 0,
                'conciliadas' => 0,
                'difProm' => 0,
                'anulaciones' => [],
                'active' => 'cortes',  // Fallback para active
            ]);
        }
    }
}