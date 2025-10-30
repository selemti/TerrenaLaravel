<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected $commands = [
        \App\Console\Commands\InspectCatalogos::class,
        \App\Console\Commands\CheckLegacyLinks::class,
        \App\Console\Commands\RecalcularCostosRecetasCommand::class,
    ];

    protected function schedule(Schedule $schedule): void
    {
        $schedule->command('close:daily')->dailyAt('22:00')->timezone('America/Mexico_City');
        $schedule->command('recetas:recalcular-costos')->dailyAt('01:10')->timezone('America/Mexico_City');
    }

    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');
        // require base_path('routes/console.php');
    }
}
