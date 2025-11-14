<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Controlador para Gestión de Tickets Problemáticos
 *
 * Permite administrar tickets con problemas:
 * - Cerrados sin pago
 * - Abiertos con deuda antigua
 * - Abiertos vacíos
 * - Pagados sin cierre
 */
class TicketManagementController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth', 'permission:admin.access']);
    }

    /**
     * Obtiene la sesión de caja a la que pertenece un ticket
     */
    private function getTicketSession($ticketId)
    {
        $ticket = DB::connection('pgsql')
            ->table('ticket')
            ->where('id', $ticketId)
            ->select('terminal_id', 'create_date')
            ->first();

        if (! $ticket) {
            return null;
        }

        // Buscar sesión por terminal y rango de fechas
        return DB::connection('pgsql')->selectOne('
            SELECT s.id, s.estatus,
                   (SELECT COUNT(*) FROM selemti.postcorte p
                    WHERE p.sesion_id = s.id
                      AND p.aprobado_en IS NOT NULL) as tiene_postcorte_aprobado
            FROM selemti.sesion_cajon s
            WHERE s.terminal_id = ?
              AND s.apertura_ts <= ?
              AND (s.cierre_ts IS NULL OR s.cierre_ts >= ?)
            ORDER BY s.apertura_ts DESC
            LIMIT 1
        ', [$ticket->terminal_id, $ticket->create_date, $ticket->create_date]);
    }

    /**
     * Valida si se puede modificar un ticket
     */
    private function canModifyTicket($ticketId): array
    {
        $session = $this->getTicketSession($ticketId);

        // Si no hay sesión, es un ticket legacy (anterior al sistema de sesiones)
        // Permitir la operación
        if (! $session) {
            return ['ok' => true, 'session' => null, 'legacy' => true];
        }

        // Si hay sesión y tiene postcorte aprobado, bloquear
        if ($session->tiene_postcorte_aprobado > 0) {
            return ['ok' => false, 'reason' => 'La sesión ya tiene postcorte aprobado. No se puede modificar.'];
        }

        return ['ok' => true, 'session' => $session, 'legacy' => false];
    }

    /**
     * Verifica si un ticket tiene descuento del 100%
     */
    private function hasFullDiscount($ticketId): bool
    {
        // Primero verificamos si el ticket tiene monto total 0
        $ticket = DB::connection('pgsql')
            ->table('ticket')
            ->where('id', $ticketId)
            ->select('total_price', 'total_discount', 'sub_total')
            ->first();

        if (! $ticket) {
            return false;
        }

        // Si el total_price es 0 y el total_discount es igual al sub_total (o al total original), es un descuento del 100%
        if ($ticket->total_price == 0 && $ticket->sub_total > 0 && $ticket->total_discount >= $ticket->sub_total) {
            return true;
        }

        // Verificar también si la suma de los descuentos en items iguala o supera el subtotal
        $itemDiscountTotal = DB::connection('pgsql')
            ->table('ticket_item as ti')
            ->join('ticket_item_discount as tid', 'ti.id', '=', 'tid.ticket_itemid')
            ->where('ti.ticket_id', $ticketId)
            ->sum('tid.amount');

        if ($itemDiscountTotal >= $ticket->sub_total) {
            return true;
        }

        return false;
    }

    /**
     * Obtiene el nombre del descuento aplicado a un ticket
     */
    private function getDiscountName($ticketId): string
    {
        // Intentar obtener el nombre del descuento desde la tabla ticket_discount
        $discount = DB::connection('pgsql')
            ->table('ticket_discount')
            ->where('ticket_id', $ticketId)
            ->select('name', 'description')
            ->first();

        if ($discount) {
            return $discount->name ?? $discount->description ?? 'Descuento 100%';
        }

        // Si no hay descuento en ticket_discount, intentar con descuentos a nivel de item
        $itemDiscount = DB::connection('pgsql')
            ->table('ticket_item as ti')
            ->join('ticket_item_discount as tid', 'ti.id', '=', 'tid.ticket_itemid')
            ->where('ti.ticket_id', $ticketId)
            ->select('tid.name', 'tid.description')
            ->first();

        if ($itemDiscount) {
            return $itemDiscount->name ?? $itemDiscount->description ?? 'Descuento Item 100%';
        }

        // Si no hay información específica, devolver un valor por defecto
        return 'Descuento por Promoción';
    }

    /**
     * Identifica y cierra tickets con descuento del 100% automáticamente
     */
    public function closeFullDiscountTickets()
    {
        // Buscar tickets que están pagados pero sin fecha de cierre y tienen descuento del 100%
        $sql = '
            SELECT t.id, t.total_price, t.total_discount, t.sub_total
            FROM public.ticket t
            WHERE t.paid = true 
              AND t.closing_date IS NULL
              AND t.total_price = 0
              AND t.total_discount > 0
              AND t.voided = false
        ';

        $tickets = DB::connection('pgsql')->select($sql);

        $processed = [];
        $errors = [];

        foreach ($tickets as $ticket) {
            try {
                DB::connection('pgsql')->transaction(function () use ($ticket, &$processed) {
                    // Verificar si tiene descuento del 100%
                    if ($this->hasFullDiscount($ticket->id)) {
                        // Obtener el nombre del descuento aplicado
                        $discountName = $this->getDiscountName($ticket->id);

                        // Cerrar el ticket y establecer la fecha de cierre
                        DB::connection('pgsql')
                            ->table('ticket')
                            ->where('id', $ticket->id)
                            ->update([
                                'paid' => true,
                                'paid_amount' => 0,
                                'due_amount' => 0,
                                'closing_date' => now(), // Fecha actual como fecha de cierre
                                'status' => 'CLOSED',
                                'close_reason' => $discountName, // Registrar la razón del cierre
                            ]);

                        $processed[] = [
                            'ticket_id' => $ticket->id,
                            'message' => "Ticket con descuento 100% ({$discountName}) cerrado automáticamente",
                        ];

                        Log::info('Ticket con descuento 100% cerrado automáticamente', [
                            'ticket_id' => $ticket->id,
                            'user_id' => 1,
                            'user_name' => 'Sistema - Auto-cierre Descuento 100%',
                            'discount_name' => $discountName,
                        ]);
                    }
                });
            } catch (\Exception $e) {
                $errors[] = [
                    'ticket_id' => $ticket->id,
                    'error' => $e->getMessage(),
                ];
            }
        }

        return response()->json([
            'ok' => true,
            'processed' => count($processed),
            'errors' => count($errors),
            'details' => [
                'processed' => $processed,
                'errors' => $errors,
            ],
        ]);
    }

    /**
     * Dashboard principal de gestión de tickets
     */
    public function index(Request $request)
    {
        $stats = $this->getTicketStats();
        $tickets = $this->getProblematicTickets($request->input('type', 'all'));

        // Cargar razones de anulación desde la BD (tabla Floreant POS)
        $voidReasons = DB::connection('pgsql')
            ->table('public.void_reasons')
            ->orderBy('id')
            ->pluck('reason_text', 'id');

        return view('admin.tickets.management', [
            'title' => 'Gestión de Tickets Problemáticos',
            'active' => 'admin',
            'stats' => $stats,
            'tickets' => $tickets,
            'filterType' => $request->input('type', 'all'),
            'voidReasons' => $voidReasons,
        ]);
    }

    /**
     * Obtiene estadísticas de tickets problemáticos
     */
    private function getTicketStats(): array
    {
        $sql = "
            WITH ticket_problems AS (
                SELECT
                    CASE
                        WHEN paid = true AND closing_date IS NULL THEN 'pagado_sin_cierre'
                        WHEN paid = false AND closing_date IS NOT NULL AND total_price = 0 AND total_discount > 0 THEN 'cerrado_con_descuento_100'
                        WHEN paid = false AND closing_date IS NOT NULL THEN 'cerrado_sin_pago'
                        WHEN paid = false AND closing_date IS NULL AND due_amount > 0 THEN 'abierto_con_deuda'
                        WHEN paid = false AND closing_date IS NULL AND total_price = 0 AND total_discount = 0 THEN 'abierto_vacio'
                    END as problema,
                    COUNT(*) as cantidad,
                    SUM(total_price) as monto_total,
                    SUM(due_amount) as deuda_total
                FROM public.ticket
                WHERE voided = false
                    AND (
                        (paid = true AND closing_date IS NULL)
                        OR (paid = false AND closing_date IS NOT NULL AND total_price > 0)
                        OR (paid = false AND closing_date IS NOT NULL AND total_price = 0 AND total_discount > 0)
                        OR (paid = false AND closing_date IS NULL AND due_amount > 0)
                        OR (paid = false AND closing_date IS NULL AND total_price = 0 AND total_discount = 0)
                    )
                GROUP BY problema
            )
            SELECT * FROM ticket_problems ORDER BY cantidad DESC
        ";

        $results = DB::connection('pgsql')->select($sql);

        return [
            'cerrado_sin_pago' => collect($results)->firstWhere('problema', 'cerrado_sin_pago'),
            'cerrado_con_descuento_100' => collect($results)->firstWhere('problema', 'cerrado_con_descuento_100'),
            'abierto_con_deuda' => collect($results)->firstWhere('problema', 'abierto_con_deuda'),
            'abierto_vacio' => collect($results)->firstWhere('problema', 'abierto_vacio'),
            'pagado_sin_cierre' => collect($results)->firstWhere('problema', 'pagado_sin_cierre'),
            'total' => collect($results)->sum('cantidad'),
            'monto_total' => collect($results)->sum('monto_total'),
        ];
    }

    /**
     * Obtiene lista de tickets problemáticos
     */
    private function getProblematicTickets(string $type = 'all'): array
    {
        $whereClauses = [
            'cerrado_sin_pago' => 'paid = false AND closing_date IS NOT NULL AND total_price > 0',
            'cerrado_con_descuento_100' => 'paid = false AND closing_date IS NOT NULL AND total_price = 0 AND total_discount > 0',
            'abierto_con_deuda' => 'paid = false AND closing_date IS NULL AND due_amount > 0',
            'abierto_vacio' => 'paid = false AND closing_date IS NULL AND total_price = 0 AND total_discount = 0',
            'pagado_sin_cierre' => 'paid = true AND closing_date IS NULL',
        ];

        $where = $type === 'all'
            ? '(paid = false AND closing_date IS NOT NULL AND total_price > 0) OR 
               (paid = false AND closing_date IS NOT NULL AND total_price = 0 AND total_discount > 0) OR 
               (paid = false AND closing_date IS NULL AND due_amount > 0) OR 
               (paid = false AND closing_date IS NULL AND total_price = 0 AND total_discount = 0) OR 
               (paid = true AND closing_date IS NULL)'
            : $whereClauses[$type] ?? '1=0';

        $sql = "
            SELECT
                t.id,
                t.create_date,
                t.closing_date,
                t.paid,
                t.voided,
                t.total_price,
                t.total_discount,
                t.due_amount,
                t.terminal_id,
                t.branch_key,
                t.ticket_type,
                CURRENT_DATE - t.create_date::date AS dias_desde_creacion,
                (SELECT COUNT(*) FROM transactions tx WHERE tx.ticket_id = t.id AND tx.voided = false) as num_transacciones,
                (SELECT SUM(tx.amount) FROM transactions tx WHERE tx.ticket_id = t.id AND tx.voided = false) as monto_pagado,
                (SELECT COUNT(*) FROM ticket_item ti WHERE ti.ticket_id = t.id) as num_items,
                CASE
                    WHEN t.paid = true AND t.closing_date IS NULL THEN 'pagado_sin_cierre'
                    WHEN t.paid = false AND t.closing_date IS NOT NULL AND t.total_price = 0 AND t.total_discount > 0 THEN 'cerrado_con_descuento_100'
                    WHEN t.paid = false AND t.closing_date IS NOT NULL THEN 'cerrado_sin_pago'
                    WHEN t.paid = false AND t.closing_date IS NULL AND t.due_amount > 0 THEN 'abierto_con_deuda'
                    WHEN t.paid = false AND t.closing_date IS NULL AND t.total_price = 0 AND t.total_discount = 0 THEN 'abierto_vacio'
                END as tipo_problema
            FROM public.ticket t
            WHERE t.voided = false AND ({$where})
            ORDER BY t.create_date DESC
            LIMIT 100
        ";

        return DB::connection('pgsql')->select($sql);
    }

    /**
     * Anula un ticket (marca como voided)
     */
    public function void(Request $request)
    {
        $request->validate([
            'ticket_id' => 'required|integer',
            'reason' => 'required|string|max:255',
        ]);

        try {
            // Validar si se puede modificar el ticket
            $validation = $this->canModifyTicket($request->ticket_id);
            if (! $validation['ok']) {
                return response()->json([
                    'ok' => false,
                    'message' => 'No se puede anular el ticket: '.$validation['reason'],
                ], 400);
            }

            DB::connection('pgsql')->transaction(function () use ($request) {
                $ticket = DB::connection('pgsql')
                    ->table('ticket')
                    ->where('id', $request->ticket_id)
                    ->first();

                if (! $ticket) {
                    throw new \Exception('Ticket no encontrado');
                }

                if ($ticket->voided) {
                    throw new \Exception('El ticket ya está anulado');
                }

                // Anular ticket (igual que Floreant POS)
                // IMPORTANTE: Al anular, también se cierra el ticket automáticamente
                // NOTA: void_by_user apunta a public.users(auto_id), usar admin = 1
                DB::connection('pgsql')
                    ->table('ticket')
                    ->where('id', $request->ticket_id)
                    ->update([
                        'voided' => true,
                        'void_reason' => $request->reason,
                        'void_by_user' => 1, // Admin System en public.users
                        'closing_date' => now(), // ✅ Cerrar automáticamente al anular (como Floreant)
                        'due_amount' => 0, // ✅ Limpiar deuda
                        'status' => 'CLOSED', // ✅ Marcar como cerrado
                    ]);

                // Registrar en auditoría
                $userId = auth()->id() ?? 3; // Usar usuario autenticado o ID 3 por defecto
                DB::connection('pgsql')->insert('
                    INSERT INTO selemti.audit_log
                        (user_id, accion, entidad, entidad_id, motivo, payload_json)
                    VALUES (?, ?, ?, ?, ?, ?::jsonb)
                ', [
                    $userId,
                    'ticket_void', // accion
                    'ticket', // entidad
                    $request->ticket_id, // entidad_id
                    $request->reason, // motivo
                    json_encode([
                        'ticket_id' => $request->ticket_id,
                        'user_id' => $userId,
                        'user_name' => auth()->user()->name ?? 'Sistema',
                        'ip' => $request->ip(),
                        'ticket_antes' => $ticket,
                        'razon' => $request->reason,
                    ]),
                ]);

                // Log de auditoría adicional en Laravel
                Log::info('Ticket anulado', [
                    'ticket_id' => $request->ticket_id,
                    'reason' => $request->reason,
                    'user_id' => 1,
                    'user_name' => 'Administrador del Sistema',
                    'ticket_data' => $ticket,
                ]);
            });

            return response()->json([
                'ok' => true,
                'message' => 'Ticket anulado correctamente',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al anular ticket: '.$e->getMessage(),
            ], 400);
        }
    }

    /**
     * Cierra un ticket pagado sin fecha de cierre
     */
    public function close(Request $request)
    {
        $request->validate([
            'ticket_id' => 'required|integer',
        ]);

        try {
            DB::connection('pgsql')->transaction(function () use ($request) {
                $ticket = DB::connection('pgsql')
                    ->table('ticket')
                    ->where('id', $request->ticket_id)
                    ->first();

                if (! $ticket) {
                    throw new \Exception('Ticket no encontrado');
                }

                if ($ticket->closing_date) {
                    throw new \Exception('El ticket ya tiene fecha de cierre');
                }

                // Verificar si tiene descuento 100%
                $hasFullDiscount = $this->hasFullDiscount($request->ticket_id);

                // Si tiene descuento 100%, marcarlo como pagado automáticamente
                if ($hasFullDiscount) {
                    // Obtener el nombre del descuento para la razón
                    $discountName = $this->getDiscountName($request->ticket_id);
                    $reason = $request->input('reason', $discountName);

                    // Marcar como pagado y cerrar en una sola operación
                    DB::connection('pgsql')
                        ->table('ticket')
                        ->where('id', $request->ticket_id)
                        ->update([
                            'paid' => true,
                            'paid_amount' => 0,
                            'due_amount' => 0,
                            'closing_date' => $ticket->create_date ?: now(),
                            'status' => 'CLOSED',
                        ]);

                    Log::info('Ticket con descuento 100% cerrado', [
                        'ticket_id' => $request->ticket_id,
                        'user_id' => auth()->id(),
                        'discount_name' => $reason,
                    ]);
                } else {
                    // Validación normal: debe estar pagado
                    if (! $ticket->paid) {
                        throw new \Exception('El ticket no está pagado, no se puede cerrar');
                    }

                    // Cerrar ticket con la fecha de creación o ahora
                    $closingDate = $ticket->create_date ?: now();

                    DB::connection('pgsql')
                        ->table('ticket')
                        ->where('id', $request->ticket_id)
                        ->update([
                            'closing_date' => $closingDate,
                            'status' => 'CLOSED',
                        ]);
                }

                // Registrar en auditoría
                $userId = auth()->id() ?? 3; // Usar usuario autenticado o ID 3 por defecto
                DB::connection('pgsql')->insert('
                    INSERT INTO selemti.audit_log
                        (user_id, accion, entidad, entidad_id, motivo, payload_json)
                    VALUES (?, ?, ?, ?, ?, ?::jsonb)
                ', [
                    $userId,
                    'ticket_close', // accion
                    'ticket', // entidad
                    $request->ticket_id, // entidad_id
                    $request->input('reason', 'Cierre manual desde gestión'), // motivo
                    json_encode([
                        'ticket_id' => $request->ticket_id,
                        'user_id' => $userId,
                        'user_name' => auth()->user()->name ?? 'Sistema',
                        'ip' => $request->ip(),
                        'ticket_antes' => $ticket,
                        'closing_date' => $closingDate,
                    ]),
                ]);

                // Log de auditoría adicional en Laravel
                Log::info('Ticket cerrado manualmente', [
                    'ticket_id' => $request->ticket_id,
                    'closing_date' => $closingDate,
                    'user_id' => 1,
                    'user_name' => 'Administrador del Sistema',
                    'ticket_data' => $ticket,
                ]);
            });

            return response()->json([
                'ok' => true,
                'message' => 'Ticket cerrado correctamente',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al cerrar ticket: '.$e->getMessage(),
            ], 400);
        }
    }

    /**
     * Reabre un ticket cerrado incorrectamente
     */
    public function reopen(Request $request)
    {
        $request->validate([
            'ticket_id' => 'required|integer',
            'reason' => 'required|string|max:255',
        ]);

        try {
            // Validar si se puede modificar el ticket
            $validation = $this->canModifyTicket($request->ticket_id);
            if (! $validation['ok']) {
                return response()->json([
                    'ok' => false,
                    'message' => 'No se puede reabrir el ticket: '.$validation['reason'],
                ], 400);
            }

            DB::connection('pgsql')->transaction(function () use ($request) {
                $ticket = DB::connection('pgsql')
                    ->table('ticket')
                    ->where('id', $request->ticket_id)
                    ->first();

                if (! $ticket) {
                    throw new \Exception('Ticket no encontrado');
                }

                if (! $ticket->closing_date) {
                    throw new \Exception('El ticket no está cerrado');
                }

                // Reabrir ticket
                DB::connection('pgsql')
                    ->table('ticket')
                    ->where('id', $request->ticket_id)
                    ->update([
                        'closing_date' => null,
                        'paid' => false,
                        'status' => null,
                    ]);

                // Registrar en auditoría
                $userId = auth()->id() ?? 3; // Usar usuario autenticado o ID 3 por defecto
                DB::connection('pgsql')->insert('
                    INSERT INTO selemti.audit_log
                        (user_id, accion, entidad, entidad_id, motivo, payload_json)
                    VALUES (?, ?, ?, ?, ?, ?::jsonb)
                ', [
                    $userId,
                    'ticket_reopen', // accion
                    'ticket', // entidad
                    $request->ticket_id, // entidad_id
                    $request->reason, // motivo
                    json_encode([
                        'ticket_id' => $request->ticket_id,
                        'user_id' => $userId,
                        'user_name' => auth()->user()->name ?? 'Sistema',
                        'ip' => $request->ip(),
                        'ticket_antes' => $ticket,
                        'razon' => $request->reason,
                    ]),
                ]);

                // Log de auditoría adicional en Laravel
                Log::info('Ticket reabierto manualmente', [
                    'ticket_id' => $request->ticket_id,
                    'reason' => $request->reason,
                    'user_id' => 1,
                    'user_name' => 'Administrador del Sistema',
                    'ticket_data' => $ticket,
                ]);
            });

            return response()->json([
                'ok' => true,
                'message' => 'Ticket reabierto correctamente',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al reabrir ticket: '.$e->getMessage(),
            ], 400);
        }
    }

    /**
     * Obtiene el rango de días disponible para cierre masivo
     */
    public function getMassiveCloseRange()
    {
        try {
            $range = DB::connection('pgsql')->selectOne('
                SELECT
                    MIN(CURRENT_DATE - create_date::date) as dias_minimo,
                    MAX(CURRENT_DATE - create_date::date) as dias_maximo,
                    COUNT(*) as total_tickets
                FROM public.ticket
                WHERE voided = false
                    AND (
                        (paid = true AND closing_date IS NULL)
                        OR
                        (paid = false AND total_price = 0 AND total_discount > 0)
                    )
            ');

            return response()->json([
                'ok' => true,
                'range' => $range,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al obtener rango: '.$e->getMessage(),
            ], 400);
        }
    }

    /**
     * Vista previa de cierre masivo
     * Muestra cuántos tickets se cerrarían y el impacto
     * Incluye: 1) Tickets pagados sin closing_date 2) Tickets con descuento 100% sin marcar como pagados
     */
    public function previewMassiveClose(Request $request)
    {
        $minDaysOld = $request->input('min_days', 30);

        try {
            // Contar tickets candidatos (ambos tipos)
            $stats = DB::connection('pgsql')->selectOne("
                SELECT
                    COUNT(*) as cantidad,
                    SUM(total_price) as monto_total,
                    MIN(create_date::date) as fecha_mas_antigua,
                    MAX(create_date::date) as fecha_mas_reciente
                FROM public.ticket
                WHERE voided = false
                    AND create_date < CURRENT_DATE - INTERVAL '{$minDaysOld} days'
                    AND (
                        -- Tipo 1: Pagados sin fecha de cierre
                        (paid = true AND closing_date IS NULL)
                        OR
                        -- Tipo 2: Descuento 100% sin marcar como pagado
                        (paid = false AND total_price = 0 AND total_discount > 0)
                    )
            ");

            // Obtener TODOS los tickets (sin límite)
            $tickets = DB::connection('pgsql')->select("
                SELECT
                    id,
                    create_date,
                    total_price,
                    total_discount,
                    paid,
                    closing_date,
                    terminal_id,
                    branch_key,
                    CURRENT_DATE - create_date::date as dias,
                    CASE
                        WHEN paid = true AND closing_date IS NULL THEN 'Pagado sin cierre'
                        WHEN paid = false AND total_price = 0 AND total_discount > 0 THEN 'Descuento 100%'
                    END as tipo
                FROM public.ticket
                WHERE voided = false
                    AND create_date < CURRENT_DATE - INTERVAL '{$minDaysOld} days'
                    AND (
                        (paid = true AND closing_date IS NULL)
                        OR
                        (paid = false AND total_price = 0 AND total_discount > 0)
                    )
                ORDER BY create_date ASC
            ");

            return response()->json([
                'ok' => true,
                'stats' => $stats,
                'tickets' => $tickets,
                'min_days' => $minDaysOld,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al obtener vista previa: '.$e->getMessage(),
            ], 400);
        }
    }

    /**
     * Ejecuta cierre masivo de tickets
     * Incluye: 1) Tickets pagados sin closing_date 2) Tickets con descuento 100% sin marcar como pagados
     */
    public function executeMassiveClose(Request $request)
    {
        $request->validate([
            'min_days' => 'required|integer|min:7',
            'confirmation' => 'required|string',
        ]);

        // Verificar confirmación
        if ($request->confirmation !== 'CERRAR MASIVO') {
            return response()->json([
                'ok' => false,
                'message' => 'Confirmación incorrecta. Debe escribir "CERRAR MASIVO"',
            ], 400);
        }

        $minDaysOld = $request->input('min_days', 30);

        try {
            $affectedTotal = 0;

            DB::connection('pgsql')->transaction(function () use ($minDaysOld, &$affectedTotal) {
                // Crear backup antes de modificar (ambos tipos)
                $userId = auth()->id() ?? 1;
                $userName = str_replace("'", "''", auth()->user()->name ?? 'Sistema'); // Escapar comillas simples
                $tableName = 'backup_tickets_cierre_masivo_'.date('Ymd_His');

                DB::connection('pgsql')->statement("
                    CREATE TABLE IF NOT EXISTS {$tableName} AS
                    SELECT
                        t.*,
                        CURRENT_TIMESTAMP as backup_timestamp,
                        CAST({$userId} AS INTEGER) as backup_user_id,
                        CAST('{$userName}' AS VARCHAR(255)) as backup_user_name
                    FROM public.ticket t
                    WHERE t.voided = false
                        AND t.create_date < CURRENT_DATE - INTERVAL '{$minDaysOld} days'
                        AND (
                            (t.paid = true AND t.closing_date IS NULL)
                            OR
                            (t.paid = false AND t.total_price = 0 AND t.total_discount > 0)
                        )
                ");

                // UPDATE 1: Tickets pagados sin fecha de cierre
                $affected1 = DB::connection('pgsql')->update("
                    UPDATE public.ticket
                    SET
                        closing_date = create_date,
                        status = 'CLOSED'
                    WHERE voided = false
                        AND paid = true
                        AND closing_date IS NULL
                        AND create_date < CURRENT_DATE - INTERVAL '{$minDaysOld} days'
                ");

                // UPDATE 2: Tickets con descuento 100% - marcar como pagados y cerrar
                $affected2 = DB::connection('pgsql')->update("
                    UPDATE public.ticket
                    SET
                        paid = true,
                        paid_amount = 0,
                        due_amount = 0,
                        closing_date = COALESCE(closing_date, create_date),
                        status = 'CLOSED'
                    WHERE voided = false
                        AND paid = false
                        AND total_price = 0
                        AND total_discount > 0
                        AND create_date < CURRENT_DATE - INTERVAL '{$minDaysOld} days'
                ");

                $affectedTotal = $affected1 + $affected2;

                // Log de auditoría
                Log::info('Cierre masivo de tickets ejecutado', [
                    'tickets_pagados_cerrados' => $affected1,
                    'tickets_descuento_100_cerrados' => $affected2,
                    'total_afectados' => $affectedTotal,
                    'min_days' => $minDaysOld,
                    'user_id' => auth()->id(),
                    'user_name' => auth()->user()->name,
                    'timestamp' => now(),
                ]);
            });

            return response()->json([
                'ok' => true,
                'message' => "Se cerraron {$affectedTotal} tickets correctamente",
                'affected' => $affectedTotal,
            ]);
        } catch (\Exception $e) {
            Log::error('Error en cierre masivo', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id(),
            ]);

            return response()->json([
                'ok' => false,
                'message' => 'Error al ejecutar cierre masivo: '.$e->getMessage(),
            ], 400);
        }
    }
}
