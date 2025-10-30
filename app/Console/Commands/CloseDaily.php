<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\Operations\DailyCloseService;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class CloseDaily extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'close:daily {--date=} {--branch=*}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Executes the daily closing process for one or all branches.';

    /**
     * Execute the console command.
     */
    public function handle(DailyCloseService $dailyCloseService)
    {
        $date = $this->option('date') ? Carbon::parse($this->option('date')) : $this->getDefaultDate();
        $branches = $this->option('branch') ?: $this->getAllActiveBranches();

        $this->info("Starting Daily Close for date: {$date->toDateString()}");

        foreach ($branches as $branchId) {
            $this->line("Processing Branch: {$branchId}...");
            try {
                $result = $dailyCloseService->run($branchId, $date->toDateString());
                $status = $result['closed'] ?? false ? 'SUCCESS' : 'INCOMPLETE';
                $this->line("Branch {$branchId} finished with status: {$status}");
                $this->line(json_encode($result['semaphore'] ?? [], JSON_PRETTY_PRINT));
            } catch (\Exception $e) {
                $this->error("Failed to process branch {$branchId}: {$e->getMessage()}");
                Log::error("DailyClose failed for branch {$branchId} on {$date->toDateString()}", [
                    'exception' => $e
                ]);
            }
        }

        $this->info('Daily Close process finished.');
        return Command::SUCCESS;
    }

    protected function getDefaultDate(): Carbon
    {
        $now = Carbon::now('America/Mexico_City');
        // If run before 10 PM, it's for the previous day. After 10 PM, it's for today.
        return $now->hour >= 22 ? $now : $now->subDay();
    }

    protected function getAllActiveBranches(): array
    {
        // TODO: Replace with actual logic to get all branch IDs
        // For now, returning a placeholder. In a real scenario, this would be:
        // return \App\Models\Catalogs\Sucursal::where('activo', true)->pluck('id')->toArray();
        return ['1'];
    }
}