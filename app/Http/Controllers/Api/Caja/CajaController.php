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

        // Query para cajas - SOLO muestra terminales con sesiones del día
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
              us.apertura_ts, us.cierre_ts, us.estatus AS sesion_estatus,
              (us.estatus = 'ACTIVA') AS activa, (us.cajero_usuario_id IS NOT NULL) AS asignada,
              EXISTS (SELECT 1 FROM selemti.precorte pr WHERE pr.sesion_id = us.id AND pr.estatus IN ('ENVIADO','APROBADO')) AS precorte_listo,
              NOT EXISTS (SELECT 1 FROM selemti.postcorte pc WHERE pc.sesion_id = us.id) AS sin_postcorte,
              (EXISTS (SELECT 1 FROM selemti.postcorte pc WHERE pc.sesion_id = us.id) AND us.cierre_ts IS NULL) AS postcorte_pendiente,
              COALESCE(us.skipped_precorte, FALSE) AS skipped_precorte,
              (SELECT estatus FROM selemti.postcorte WHERE sesion_id = us.id LIMIT 1) AS postcorte_estatus
            FROM public.terminal t
            INNER JOIN ultimas_sesiones us ON us.terminal_id = t.id
            LEFT JOIN public.users u ON u.auto_id = us.cajero_usuario_id
            ORDER BY
                CASE WHEN us.estatus = 'ACTIVA' THEN 1
                     WHEN us.estatus = 'CERRADA' AND NOT EXISTS (SELECT 1 FROM selemti.precorte WHERE sesion_id = us.id AND estatus IN ('ENVIADO','APROBADO')) THEN 2
                     WHEN EXISTS (SELECT 1 FROM selemti.precorte WHERE sesion_id = us.id AND estatus IN ('ENVIADO','APROBADO'))
                          AND NOT EXISTS (SELECT 1 FROM selemti.postcorte WHERE sesion_id = us.id) THEN 3
                     ELSE 4
                END,
                t.id
        ";

        try {
            $results = DB::connection('pgsql')->select($sql, ['day' => $date]);

            $cajas = collect($results)->map(function ($row) {
                $activa = (bool) $row->activa;
                $asignada = (bool) $row->asignada;
                $precorteListo = (bool) $row->precorte_listo;
                $sinPostcorte = (bool) $row->sin_postcorte;
                $postcortePendiente = (bool) $row->postcorte_pendiente;
                $skipped = (bool) $row->skipped_precorte;

                // Calcular estado mejorado
                $estado = $this->calcularEstado($activa, $asignada, $precorteListo, $sinPostcorte, $postcortePendiente, $skipped);

                return (object) [
                    'id' => (int) $row->id,
                    'name' => $row->name,
                    'location' => $row->location,
                    'opening_float' => (float) ($row->opening_float ?? 0),
                    'assigned_user' => (int) ($row->assigned_user ?? 0),
                    'assigned_name' => $row->assigned_name ?? '—',
                    'sesion_id' => $row->sesion_id ? (int) $row->sesion_id : null,
                    'apertura_ts' => $row->apertura_ts,
                    'cierre_ts' => $row->cierre_ts,
                    'activa' => $activa,
                    'asignada' => $asignada,
                    'precorte_listo' => $precorteListo,
                    'sin_postcorte' => $sinPostcorte,
                    'postcorte_pendiente' => $postcortePendiente,
                    'skipped_precorte' => $skipped,
                    'estado' => $estado,  // Estado calculado
                ];
            });

            // KPIs calculados DESPUÉS de mapear $cajas
            $abiertas = $cajas->where('estado', 'ABIERTA')->count();
            $pendientes = $cajas->whereIn('estado', ['PRECORTE_PENDIENTE', 'VALIDACION'])->count();
            $precortes = $cajas->where('precorte_listo', true)->count();
            $conciliadas = $cajas->where('estado', 'CONCILIADA')->count();
            $difProm = 0; // Placeholder; calcula promedio de diffs si tienes datos en BD (e.g., avg de precorte.diferencia)

            // Obtener excepciones del día desde PostgreSQL (con manejo de errores)
            try {
                $anulaciones = $this->obtenerAnulaciones($date);
            } catch (\Exception $e) {
                \Log::error("Error obteniendo excepciones en index: " . $e->getMessage());
                $anulaciones = []; // Continuar con array vacío si falla
            }

            // Variable para active en el layout (para highlighting del menú)
            $active = 'cortes';  // Identificador para el menú de "Cortes de Caja"

            // PASA TODAS LAS VARS A LA VISTA CON COMPACT (AHORA COMPLETO, INCLUYENDO $active)
            return view('caja.cortes', compact(
                'cajas',      // Colección de terminales/cajas
                'date',       // Fecha actual (e.g., '2025-10-14')
                'abiertas',   // Número de cajas abiertas
                'pendientes', // Cajas que requieren acción
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
                'pendientes' => 0,
                'precortes' => 0,
                'conciliadas' => 0,
                'difProm' => 0,
                'anulaciones' => [],
                'active' => 'cortes',  // Fallback para active
            ]);
        }
    }

    /**
     * Calcular estado de la sesión basado en el ciclo de vida
     */
    private function calcularEstado(bool $activa, bool $asignada, bool $precorteListo, bool $sinPostcorte, bool $postcortePendiente, bool $skipped): string
    {
        // 1. Requiere regularización urgente
        if ($skipped) {
            return 'REGULARIZAR';
        }

        // 2. Caja abierta y operando
        if ($activa && $asignada) {
            return 'ABIERTA';
        }

        // 3. Cerrada en POS pero falta precorte
        if (!$activa && $asignada && !$precorteListo) {
            return 'PRECORTE_PENDIENTE';
        }

        // 4. Precorte enviado, esperando validación (postcorte)
        if ($precorteListo && $sinPostcorte) {
            return 'VALIDACION';
        }

        // 5. Postcorte creado pero no validado
        if ($precorteListo && !$sinPostcorte && $postcortePendiente) {
            return 'EN_REVISION';
        }

        // 6. Todo completo
        if ($precorteListo && !$sinPostcorte && !$postcortePendiente) {
            return 'CONCILIADA';
        }

        // 7. Default - sesión sin actividad
        return 'DISPONIBLE';
    }

    /**
     * Obtener TODAS las excepciones del día (anulaciones, devoluciones, descuentos, etc.)
     */
    private function obtenerAnulaciones(string $date): array
    {
        try {
            // Query comprehensiva para todas las excepciones que afectan ventas
            $sql = "
                WITH excepciones AS (
                    -- 1. Tickets anulados
                    SELECT
                        t.id AS ticket_internal_id,
                        t.daily_folio AS ticket_id,
                        'Anulación' AS tipo,
                        t.total_price AS monto,
                        t.create_date AS fecha,
                        t.terminal_id,
                        COALESCE(term.name, t.terminal_id::text) AS terminal,
                        COALESCE(u.first_name || ' ' || u.last_name, 'Sistema') AS usuario,
                        COALESCE(t.void_reason, '–') AS razon,
                        1 AS prioridad
                    FROM public.ticket t
                    LEFT JOIN public.users u ON u.auto_id = t.void_by_user
                    LEFT JOIN public.terminal term ON term.id = t.terminal_id
                    WHERE DATE(t.create_date) = ?::date
                      AND t.voided = true

                    UNION ALL

                    -- 2. Tickets con devolución
                    SELECT
                        t.id AS ticket_internal_id,
                        t.daily_folio AS ticket_id,
                        'Devolución' AS tipo,
                        t.total_price AS monto,
                        t.create_date AS fecha,
                        t.terminal_id,
                        COALESCE(term.name, t.terminal_id::text) AS terminal,
                        COALESCE(u.first_name || ' ' || u.last_name, 'Sistema') AS usuario,
                        'Reembolso completo' AS razon,
                        2 AS prioridad
                    FROM public.ticket t
                    LEFT JOIN public.users u ON u.auto_id = t.owner_id
                    LEFT JOIN public.terminal term ON term.id = t.terminal_id
                    WHERE DATE(t.create_date) = ?::date
                      AND t.refunded = true
                      AND t.voided = false

                    UNION ALL

                    -- 3. Tickets desperdiciados
                    SELECT
                        t.id AS ticket_internal_id,
                        t.daily_folio AS ticket_id,
                        'Desperdicio' AS tipo,
                        t.total_price AS monto,
                        t.create_date AS fecha,
                        t.terminal_id,
                        COALESCE(term.name, t.terminal_id::text) AS terminal,
                        COALESCE(u.first_name || ' ' || u.last_name, 'Sistema') AS usuario,
                        'Producto desperdiciado' AS razon,
                        3 AS prioridad
                    FROM public.ticket t
                    LEFT JOIN public.users u ON u.auto_id = t.owner_id
                    LEFT JOIN public.terminal term ON term.id = t.terminal_id
                    WHERE DATE(t.create_date) = ?::date
                      AND t.wasted = true
                      AND t.voided = false

                    UNION ALL

                    -- 4. Tickets con descuentos aplicados (mejorado)
                    SELECT
                        t.id AS ticket_internal_id,
                        t.daily_folio AS ticket_id,
                        'Descuento' AS tipo,
                        t.total_discount AS monto,
                        t.create_date AS fecha,
                        t.terminal_id,
                        COALESCE(term.name, t.terminal_id::text) AS terminal,
                        COALESCE(u.first_name || ' ' || u.last_name, 'Sistema') AS usuario,
                        COALESCE(
                            -- Primero intenta descuentos a nivel de ticket
                            (SELECT STRING_AGG(DISTINCT td.name, ', ')
                             FROM ticket_discount td
                             WHERE td.ticket_id = t.id AND td.name IS NOT NULL AND td.name != ''),
                            -- Luego intenta descuentos a nivel de item
                            (SELECT STRING_AGG(DISTINCT tid.name, ', ')
                             FROM ticket_item ti
                             INNER JOIN ticket_item_discount tid ON tid.ticket_itemid = ti.id
                             WHERE ti.ticket_id = t.id AND tid.name IS NOT NULL AND tid.name != ''),
                            -- Si no hay nombre, calcula el porcentaje promedio
                            'Desc. ' || ROUND((t.total_discount / NULLIF(t.sub_total + t.total_discount, 0) * 100)::numeric, 0)::text || '%'
                        ) AS razon,
                        4 AS prioridad
                    FROM public.ticket t
                    LEFT JOIN public.users u ON u.auto_id = t.owner_id
                    LEFT JOIN public.terminal term ON term.id = t.terminal_id
                    WHERE DATE(t.create_date) = ?::date
                      AND t.total_discount > 0
                      AND t.voided = false
                      AND t.wasted = false

                    UNION ALL

                    -- 5. Ajustes de precio (overrides)
                    SELECT
                        t.id AS ticket_internal_id,
                        t.daily_folio AS ticket_id,
                        'Ajuste' AS tipo,
                        ABS(t.adjustment_amount) AS monto,
                        t.create_date AS fecha,
                        t.terminal_id,
                        COALESCE(term.name, t.terminal_id::text) AS terminal,
                        COALESCE(u.first_name || ' ' || u.last_name, 'Sistema') AS usuario,
                        CASE
                            WHEN t.adjustment_amount > 0 THEN 'Ajuste positivo'
                            WHEN t.adjustment_amount < 0 THEN 'Ajuste negativo'
                            ELSE '–'
                        END AS razon,
                        5 AS prioridad
                    FROM public.ticket t
                    LEFT JOIN public.users u ON u.auto_id = t.owner_id
                    LEFT JOIN public.terminal term ON term.id = t.terminal_id
                    WHERE DATE(t.create_date) = ?::date
                      AND t.adjustment_amount IS NOT NULL
                      AND t.adjustment_amount != 0
                      AND t.voided = false
                )
                SELECT * FROM excepciones
                ORDER BY prioridad, fecha DESC
                LIMIT 50
            ";

            // Ejecutar con fecha repetida para cada subquery
            $results = DB::connection('pgsql')->select($sql, [$date, $date, $date, $date, $date]);

            return collect($results)->map(function ($row) {
                return [
                    'ticket_internal_id' => $row->ticket_internal_id,
                    'ticket_id' => $row->ticket_id ?? $row->ticket_internal_id,
                    'tipo' => $row->tipo,
                    'monto' => (float) ($row->monto ?? 0),
                    'hora' => $row->fecha ? \Carbon\Carbon::parse($row->fecha)->format('h:i A') : '–',
                    'terminal_id' => $row->terminal_id,
                    'terminal' => $row->terminal,
                    'usuario' => $row->usuario,
                    'razon' => $row->razon,
                    'prioridad' => $row->prioridad,
                ];
            })->toArray();
        } catch (\Exception $e) {
            \Log::error("Error obteniendo excepciones (fecha: {$date}): " . $e->getMessage());
            return [];
        }
    }

    /**
     * Obtener detalle completo de un ticket
     */
    public function getTicketDetail($ticketId)
    {
        try {
            // Obtener info del ticket
            $sqlTicket = "
                SELECT
                    t.id,
                    t.daily_folio,
                    t.create_date,
                    t.sub_total,
                    t.total_discount,
                    t.total_tax,
                    t.total_price,
                    t.voided,
                    t.void_reason,
                    t.terminal_id,
                    COALESCE(term.name, t.terminal_id::text) AS terminal,
                    COALESCE(u.first_name || ' ' || u.last_name, 'Sistema') AS usuario
                FROM public.ticket t
                LEFT JOIN public.terminal term ON term.id = t.terminal_id
                LEFT JOIN public.users u ON u.auto_id = t.owner_id
                WHERE t.id = ?
            ";

            $ticket = DB::connection('pgsql')->selectOne($sqlTicket, [$ticketId]);

            if (!$ticket) {
                return response()->json(['ok' => false, 'error' => 'Ticket no encontrado'], 404);
            }

            // Obtener items del ticket
            $sqlItems = "
                SELECT
                    ti.id,
                    ti.item_name,
                    ti.item_quantity,
                    ti.item_price,
                    ti.discount,
                    ti.total_price,
                    ti.sub_total
                FROM ticket_item ti
                WHERE ti.ticket_id = ?
                ORDER BY ti.id
            ";

            $items = DB::connection('pgsql')->select($sqlItems, [$ticketId]);

            return response()->json([
                'ok' => true,
                'ticket' => [
                    'id' => $ticket->id,
                    'daily_folio' => $ticket->daily_folio,
                    'create_date' => $ticket->create_date,
                    'sub_total' => (float) ($ticket->sub_total ?? 0),
                    'total_discount' => (float) ($ticket->total_discount ?? 0),
                    'total_tax' => (float) ($ticket->total_tax ?? 0),
                    'total_price' => (float) ($ticket->total_price ?? 0),
                    'voided' => (bool) $ticket->voided,
                    'void_reason' => $ticket->void_reason,
                    'terminal' => $ticket->terminal,
                    'usuario' => $ticket->usuario,
                    'items' => collect($items)->map(function ($item) {
                        return [
                            'id' => $item->id,
                            'item_name' => $item->item_name,
                            'item_quantity' => (float) ($item->item_quantity ?? 1),
                            'item_price' => (float) ($item->item_price ?? 0),
                            'discount' => (float) ($item->discount ?? 0),
                            'total_price' => (float) ($item->total_price ?? 0),
                            'sub_total' => (float) ($item->sub_total ?? 0),
                        ];
                    })->toArray(),
                ],
            ]);
        } catch (\Exception $e) {
            \Log::error("Error obteniendo detalle de ticket {$ticketId}: " . $e->getMessage());
            return response()->json(['ok' => false, 'error' => 'Error del servidor'], 500);
        }
    }
}