<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected $commands = [
        \App\Console\Commands\InspectCatalogos::class,
        \App\Console\Commands\CheckLegacyLinks::class,
    ];

    protected function schedule(Schedule $schedule):
    {
        // Puedes dejarlo vacío por ahora.
    }

    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');
        // require base_path('routes/console.php');
    }
}
