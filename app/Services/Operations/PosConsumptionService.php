<?php

namespace App\Services\Operations;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;
use Throwable;

class PosConsumptionService
{
    protected string $connection = 'pgsql';

    public function processTicket(int $ticketId): array
    {
        return DB::connection($this->connection)->transaction(function () use ($ticketId) {
            // 1. Idempotency Check
            $existing = DB::connection($this->connection)->table('selemti.inv_consumo_pos')
                ->where('ticket_id', $ticketId)->first();
            if ($existing) {
                return ['status' => 'already_processed', 'consumo_id' => $existing->id];
            }

            // 2. Fetch ticket data
            $ticket = DB::connection($this->connection)->table('public.tickets as t')
                ->join('public.ticket_items as ti', 't.id', '=', 'ti.ticket_id')
                ->where('t.id', $ticketId)
                ->select('t.id', 't.branch_id', 't.created_at', 't.total', 'ti.id as ticket_item_id', 'ti.menu_item_id', 'ti.quantity')
                ->get();

            if ($ticket->isEmpty()) {
                return ['status' => 'ticket_not_found'];
            }

            $header = $ticket->first();
            $consumoId = Str::uuid();
            $requiresReprocess = false;
            $consumoDetails = [];
            $movInvRecords = [];

            // 3. Map items and modifiers
            foreach ($ticket as $item) {
                $recipeMap = DB::connection($this->connection)->table('selemti.pos_map')
                    ->where('pos_item_id', $item->menu_item_id)
                    ->where('type', 'MENU_ITEM')
                    ->first();

                if (!$recipeMap) {
                    $requiresReprocess = true;
                } else {
                    // 4. Calculate consumption
                    $recipeDetails = DB::connection($this->connection)->table('selemti.recipe_details')
                        ->where('recipe_id', $recipeMap->terrena_item_id)->get();

                    foreach ($recipeDetails as $ingredient) {
                        $consumoDetails[] = [
                            'consumo_id' => $consumoId,
                            'item_id' => $ingredient->item_id,
                            'cantidad_teorica' => $ingredient->quantity * $item->quantity,
                            // costo se podría obtener aquí, pero lo dejamos para un paso posterior o trigger
                            'ref_type' => 'MENU_ITEM',
                            'ref_id' => $item->menu_item_id,
                        ];
                    }
                }
            }
            
            // 5. Insert data
            DB::connection($this->connection)->table('selemti.inv_consumo_pos')->insert([
                'id' => $consumoId,
                'ticket_id' => $ticketId,
                'branch_id' => $header->branch_id,
                'fecha_operacion' => Carbon::parse($header->created_at)->toDateString(),
                'total_venta' => $header->total,
                'status' => 'PROCESADO',
                'requiere_reproceso' => $requiresReprocess,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            if (!empty($consumoDetails)) {
                DB::connection($this->connection)->table('selemti.inv_consumo_pos_det')->insert($consumoDetails);

                // 6. Generate inventory movements
                foreach ($consumoDetails as $detail) {
                     $movInvRecords[] = [
                        'id' => Str::uuid(),
                        'branch_id' => $header->branch_id,
                        'item_id' => $detail['item_id'],
                        'tipo_movimiento' => 'SALIDA_VENTA',
                        'cantidad' => -$detail['cantidad_teorica'],
                        'ref_tipo' => 'CONSUMO_POS',
                        'ref_id' => (string)$consumoId,
                        'created_at' => now(),
                        'updated_at' => now(),
                     ];
                }
                DB::connection($this->connection)->table('selemti.mov_inv')->insert($movInvRecords);
            }

            return [
                'status' => 'success',
                'consumo_id' => $consumoId,
                'requiere_reproceso' => $requiresReprocess
            ];
        });
    }
}
