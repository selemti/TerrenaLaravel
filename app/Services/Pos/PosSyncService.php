<?php

namespace App\Services\Pos;

use App\Services\Inventory\PosConsumptionService;
use Carbon\CarbonImmutable;
use Illuminate\Support\Arr;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class PosSyncService
{
    public function __construct(
        protected PosConsumptionService $consumptionService
    ) {
    }

    /**
     * @param  array<int, array<string, mixed>>  $tickets
     */
    public function ingestTickets(array $tickets, string $sourceSystem = 'pos'): int
    {
        if ($tickets === []) {
            return 0;
        }

        return DB::connection('pgsql')->transaction(function () use ($tickets, $sourceSystem): int {
            $batchId = DB::table('selemti.pos_sync_batches')->insertGetId([
                'source_system' => $sourceSystem,
                'status' => 'processing',
                'started_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $processed = 0;
            $successful = 0;
            $failed = 0;

            foreach ($tickets as $ticket) {
                $processed++;
                $externalId = Arr::get($ticket, 'global_id') ?? Arr::get($ticket, 'id');

                try {
                    $this->upsertTicket($ticket);
                    $successful++;

                    DB::table('selemti.pos_sync_logs')->insert([
                        'batch_id' => $batchId,
                        'external_id' => $externalId,
                        'action' => 'ticket_ingest',
                        'status' => 'success',
                        'payload' => json_encode($ticket, JSON_THROW_ON_ERROR),
                        'message' => null,
                    ]);
                } catch (\Throwable $exception) {
                    $failed++;
                    Log::warning('POS ingest failed', [
                        'external_id' => $externalId,
                        'message' => $exception->getMessage(),
                    ]);

                    DB::table('selemti.pos_sync_logs')->insert([
                        'batch_id' => $batchId,
                        'external_id' => $externalId,
                        'action' => 'ticket_ingest',
                        'status' => 'failed',
                        'payload' => json_encode($ticket, JSON_THROW_ON_ERROR),
                        'message' => $exception->getMessage(),
                    ]);
                }
            }

            DB::table('selemti.pos_sync_batches')
                ->where('id', $batchId)
                ->update([
                    'status' => $failed > 0 ? 'completed_with_errors' : 'completed',
                    'finished_at' => now(),
                    'rows_processed' => $processed,
                    'rows_successful' => $successful,
                    'rows_failed' => $failed,
                    'updated_at' => now(),
                ]);

            return $successful;
        });
    }

    /**
     * @param  array<string, mixed>  $ticket
     */
    protected function upsertTicket(array $ticket): void
    {
        if (! config('app.allow_pos_writes', false)) {
            throw new RuntimeException('Direct writes to public.* están prohibidas por la política A de seguridad operativa. Implementar integración mediante APIs del POS.');
        }

        $ticketId = Arr::get($ticket, 'id');
        $paid = (bool) Arr::get($ticket, 'paid');
        $voided = (bool) Arr::get($ticket, 'voided');
        $paidAt = $this->parseDate(Arr::get($ticket, 'paid_at'));

        DB::table('public.ticket')->updateOrInsert(
            ['id' => $ticketId],
            [
                'global_id' => Arr::get($ticket, 'global_id'),
                'paid' => $paid,
                'voided' => $voided,
                'total' => Arr::get($ticket, 'total', 0),
                'sub_total' => Arr::get($ticket, 'sub_total', 0),
                'tax_total' => Arr::get($ticket, 'tax_total', 0),
                'customer_id' => Arr::get($ticket, 'customer_id'),
                'terminal_id' => Arr::get($ticket, 'terminal_id'),
                'paid_time' => $paidAt?->toDateTimeString(),
                'closed' => $paid,
            ]
        );

        $items = collect(Arr::get($ticket, 'items', []));
        $this->syncTicketItems($ticketId, $items);

        if ($paid && ! $voided) {
            $this->consumptionService->confirmConsumption((int) $ticketId);
        }

        if ($voided) {
            $this->consumptionService->reverseConsumption((int) $ticketId);
        }
    }

    /**
     * @param  Collection<int, array<string, mixed>>  $items
     */
    protected function syncTicketItems(int|string $ticketId, Collection $items): void
    {
        DB::table('public.ticket_item')->where('ticket_id', $ticketId)->delete();

        foreach ($items as $item) {
            DB::table('public.ticket_item')->insert([
                'ticket_id' => $ticketId,
                'item_id' => Arr::get($item, 'item_id'),
                'item_quantity' => Arr::get($item, 'quantity', 1),
                'item_price' => Arr::get($item, 'price', 0),
                'item_subtotal' => Arr::get($item, 'subtotal', 0),
                'item_name' => Arr::get($item, 'name'),
                'category_name' => Arr::get($item, 'category'),
            ]);
        }
    }

    protected function parseDate(mixed $value): ?CarbonImmutable
    {
        if ($value === null) {
            return null;
        }

        if ($value instanceof CarbonImmutable) {
            return $value;
        }

        try {
            return CarbonImmutable::parse($value);
        } catch (\Throwable) {
            throw new RuntimeException('Fecha de pago inválida proporcionada por POS');
        }
    }
}
