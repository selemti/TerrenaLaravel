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

        if (!$ticket) {
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
        $sql = "
            SELECT t.id, t.total_price, t.total_discount, t.sub_total
            FROM public.ticket t
            WHERE t.paid = true 
              AND t.closing_date IS NULL
              AND t.total_price = 0
              AND t.total_discount > 0
              AND t.voided = false
        ";

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
                            'message' => "Ticket con descuento 100% ({$discountName}) cerrado automáticamente"
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
                    'error' => $e->getMessage()
                ];
            }
        }

        return response()->json([
            'ok' => true,
            'processed' => count($processed),
            'errors' => count($errors),
            'details' => [
                'processed' => $processed,
                'errors' => $errors
            ]
        ]);
    }

    /**
     * Dashboard principal de gestión de tickets
     */
    public function index(Request $request)
    {
        $stats = $this->getTicketStats();
        $tickets = $this->getProblematicTickets($request->input('type', 'all'));

        return view('admin.tickets.management', [
            'title' => 'Gestión de Tickets Problemáticos',
            'active' => 'admin',
            'stats' => $stats,
            'tickets' => $tickets,
            'filterType' => $request->input('type', 'all'),
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

                // Anular ticket - Usar el usuario administrador con auto_id = 1
                DB::connection('pgsql')
                    ->table('ticket')
                    ->where('id', $request->ticket_id)
                    ->update([
                        'voided' => true,
                        'void_reason' => $request->reason,
                        'void_by_user' => 1, // Usar auto_id = 1 para el admin
                    ]);

                // Log de auditoría
                Log::info('Ticket anulado', [
                    'ticket_id' => $request->ticket_id,
                    'reason' => $request->reason,
                    'user_id' => 1, // Registrar como admin
                    'user_name' => 'Administrador del Sistema', // Usar nombre genérico
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

                if (! $ticket->paid) {
                    throw new \Exception('El ticket no está pagado, no se puede cerrar');
                }

                if ($ticket->closing_date) {
                    throw new \Exception('El ticket ya tiene fecha de cierre');
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

                // Log de auditoría
                Log::info('Ticket cerrado manualmente', [
                    'ticket_id' => $request->ticket_id,
                    'closing_date' => $closingDate,
                    'user_id' => 1, // Registrar como admin
                    'user_name' => 'Administrador del Sistema', // Usar nombre genérico
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
     * Marca un ticket como pagado y cerrado
     * (Para tickets cerrados sin pago que sí fueron pagados)
     */
    public function markAsPaid(Request $request)
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

                if ($ticket->paid) {
                    throw new \Exception('El ticket ya está marcado como pagado');
                }

                // Calcular monto pagado de transacciones
                $montoPagado = DB::connection('pgsql')
                    ->table('transactions')
                    ->where('ticket_id', $request->ticket_id)
                    ->where('voided', false)
                    ->sum('amount');

                if ($montoPagado < $ticket->total_price - 0.50) {
                    throw new \Exception('Las transacciones no cubren el total del ticket');
                }

                // Marcar como pagado
                DB::connection('pgsql')
                    ->table('ticket')
                    ->where('id', $request->ticket_id)
                    ->update([
                        'paid' => true,
                        'paid_amount' => $montoPagado,
                        'due_amount' => 0,
                    ]);

                // Log de auditoría
                Log::info('Ticket marcado como pagado manualmente', [
                    'ticket_id' => $request->ticket_id,
                    'paid_amount' => $montoPagado,
                    'user_id' => 1, // Registrar como admin
                    'user_name' => 'Administrador del Sistema', // Usar nombre genérico
                    'ticket_data' => $ticket,
                ]);
            });

            return response()->json([
                'ok' => true,
                'message' => 'Ticket marcado como pagado correctamente',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al marcar ticket como pagado: '.$e->getMessage(),
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

                // Log de auditoría
                Log::info('Ticket reabierto manualmente', [
                    'ticket_id' => $request->ticket_id,
                    'reason' => $request->reason,
                    'user_id' => 1, // Registrar como admin
                    'user_name' => 'Administrador del Sistema', // Usar nombre genérico
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
     * Vista previa de cierre masivo
     * Muestra cuántos tickets se cerrarían y el impacto
     */
    public function previewMassiveClose(Request $request)
    {
        $minDaysOld = $request->input('min_days', 30);

        try {
            // Contar tickets candidatos
            $stats = DB::connection('pgsql')->selectOne("
                SELECT
                    COUNT(*) as cantidad,
                    SUM(total_price) as monto_total,
                    MIN(create_date::date) as fecha_mas_antigua,
                    MAX(create_date::date) as fecha_mas_reciente
                FROM public.ticket
                WHERE total_price > 0
                    AND COALESCE(due_amount, 0) = 0
                    AND closing_date IS NULL
                    AND voided = false
                    AND paid = false
                    AND create_date < CURRENT_DATE - INTERVAL '{$minDaysOld} days'
            ");

            // Obtener muestra de tickets
            $sample = DB::connection('pgsql')->select("
                SELECT
                    id,
                    create_date,
                    total_price,
                    terminal_id,
                    branch_key,
                    CURRENT_DATE - create_date::date as dias
                FROM public.ticket
                WHERE total_price > 0
                    AND COALESCE(due_amount, 0) = 0
                    AND closing_date IS NULL
                    AND voided = false
                    AND paid = false
                    AND create_date < CURRENT_DATE - INTERVAL '{$minDaysOld} days'
                ORDER BY create_date DESC
                LIMIT 10
            ");

            return response()->json([
                'ok' => true,
                'stats' => $stats,
                'sample' => $sample,
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
     * Ejecuta cierre masivo de tickets pagados sin fecha de cierre
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
            DB::connection('pgsql')->transaction(function () use ($minDaysOld, $request) {
                // Crear backup antes de modificar
                DB::connection('pgsql')->statement("
                    CREATE TABLE IF NOT EXISTS backup_tickets_cierre_masivo_".date('Ymd_His')." AS
                    SELECT
                        t.*,
                        CURRENT_TIMESTAMP as backup_timestamp,
                        ? as backup_user_id,
                        ? as backup_user_name
                    FROM public.ticket t
                    WHERE t.total_price > 0
                        AND COALESCE(t.due_amount, 0) = 0
                        AND t.closing_date IS NULL
                        AND t.voided = false
                        AND t.paid = false
                        AND t.create_date < CURRENT_DATE - INTERVAL '{$minDaysOld} days'
                ", [auth()->id(), auth()->user()->name]);

                // Ejecutar cierre masivo
                $affected = DB::connection('pgsql')->update("
                    UPDATE public.ticket
                    SET
                        closing_date = create_date,
                        paid = true,
                        paid_amount = COALESCE(total_price, 0),
                        due_amount = 0,
                        status = 'CLOSED'
                    WHERE total_price > 0
                        AND COALESCE(due_amount, 0) = 0
                        AND closing_date IS NULL
                        AND voided = false
                        AND paid = false
                        AND create_date < CURRENT_DATE - INTERVAL '{$minDaysOld} days'
                ");

                // Log de auditoría
                Log::info('Cierre masivo de tickets ejecutado', [
                    'tickets_afectados' => $affected,
                    'min_days' => $minDaysOld,
                    'user_id' => auth()->id(),
                    'user_name' => auth()->user()->name,
                    'timestamp' => now(),
                ]);

                // Guardar en variable de sesión
                session(['massive_close_count' => $affected]);
            });

            $affected = session('massive_close_count', 0);

            return response()->json([
                'ok' => true,
                'message' => "Se cerraron {$affected} tickets correctamente",
                'affected' => $affected,
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
