<?php
namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;

class CajasController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $date = $request->query('date', now()->format('Y-m-d'));

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

            $terminals = collect($results)->map(function ($row) {
                return [
                    'id' => (int) $row->id,
                    'name' => $row->name,
                    'location' => $row->location,
                    'opening_float' => (float) ($row->opening_float ?? 0),
                    'assigned_user' => (int) ($row->assigned_user ?? 0),
                    'assigned_name' => $row->assigned_name ?? '—',
                    'sesion_id' => $row->sesion_id ? (int) $row->sesion_id : null,  // Preserva null en lugar de 0
                    'activa' => (bool) $row->activa,
                    'asignada' => (bool) $row->asignada,
                    'precorte_listo' => (bool) $row->precorte_listo,
                    'sin_postcorte' => (bool) $row->sin_postcorte,
                    'postcorte_pendiente' => (bool) $row->postcorte_pendiente,
                    'skipped_precorte' => (bool) $row->skipped_precorte,
                ];
            })->toArray();

            return response()->json(['ok' => true, 'date' => $date, 'terminals' => $terminals]);
        } catch (\Exception $e) {
            \Log::error("Error en cajas (fecha: {$date}): " . $e->getMessage());
            return response()->json(['ok' => false, 'error' => 'server_error'], 500);
        }
    }
}