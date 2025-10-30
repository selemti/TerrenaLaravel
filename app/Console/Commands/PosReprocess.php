<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\Operations\PosConsumptionService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;
use Throwable;

class PosReprocess extends Command
{
    protected $signature = 'pos:reprocess {--date=} {--branch=*} {--force}';
    protected $description = 'Finds and reprocesses POS consumption records that required reprocessing.';

    protected PosConsumptionService $posConsumptionService;
    protected string $connection = 'pgsql';

    public function __construct(PosConsumptionService $posConsumptionService)
    {
        parent::__construct();
        $this->posConsumptionService = $posConsumptionService;
    }

    public function handle()
    {
        if (app()->environment('production') && !$this->option('force')) {
            $this->error('Running in production requires the --force flag.');
            return Command::FAILURE;
        }

        $date = $this->option('date') ? Carbon::parse($this->option('date'))->toDateString() : null;
        $branches = $this->option('branch') ?: [];

        $this->info("Starting POS Reprocessing...");
        $this->line("Date filter: " . ($date ?? 'None'));
        $this->line("Branch filter: " . (!empty($branches) ? implode(', ', $branches) : 'All'));

        $query = DB::connection($this->connection)->table('selemti.inv_consumo_pos')
            ->where('requiere_reproceso', true);

        if ($date) {
            $query->where('fecha_operacion', $date);
        }
        if (!empty($branches)) {
            $query->whereIn('branch_id', $branches);
        }

        $recordsToReprocess = $query->get();

        if ($recordsToReprocess->isEmpty()) {
            $this->info("No records found requiring reprocessing.");
            return Command::SUCCESS;
        }

        $this->info("Found {$recordsToReprocess->count()} records to reprocess.");
        $bar = $this->output->createProgressBar($recordsToReprocess->count());
        $bar->start();

        $stillRequiresReprocess = [];

        foreach ($recordsToReprocess as $record) {
            DB::connection($this->connection)->transaction(function () use ($record, &$stillRequiresReprocess) {
                // 1. Revert previous inventory movements
                $movements = DB::connection($this->connection)->table('selemti.mov_inv')
                    ->where('ref_tipo', 'CONSUMO_POS')
                    ->where('ref_id', $record->id)
                    ->get();

                $reversalMovements = [];
                foreach ($movements as $mov) {
                    $reversalMovements[] = [
                        'id' => Str::uuid(),
                        'branch_id' => $mov->branch_id,
                        'item_id' => $mov->item_id,
                        'tipo_movimiento' => 'REPROCESO_POS_ANULACION',
                        'cantidad' => -$mov->cantidad, // Reverse the amount
                        'ref_tipo' => 'REPROCESO_POS',
                        'ref_id' => $record->id,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ];
                }
                if (!empty($reversalMovements)) {
                    DB::connection($this->connection)->table('selemti.mov_inv')->insert($reversalMovements);
                }

                // 2. Delete old consumption records
                DB::connection($this->connection)->table('selemti.inv_consumo_pos_det')->where('consumo_id', $record->id)->delete();
                DB::connection($this->connection)->table('selemti.inv_consumo_pos')->where('id', $record->id)->delete();

                // 3. Re-invoke consumption service
                $result = $this->posConsumptionService->processTicket($record->ticket_id);

                if ($result['status'] === 'success' && $result['requiere_reproceso']) {
                    $stillRequiresReprocess[] = $record->ticket_id;
                }
            });
            $bar->advance();
        }

        $bar->finish();
        $this->newLine(2);
        $this->info("Reprocessing complete.");

        if (!empty($stillRequiresReprocess)) {
            $this->warn("The following tickets still require reprocessing after this run:");
            foreach ($stillRequiresReprocess as $ticketId) {
                $this->line("- Ticket ID: {$ticketId}");
            }
        }

        return Command::SUCCESS;
    }
}