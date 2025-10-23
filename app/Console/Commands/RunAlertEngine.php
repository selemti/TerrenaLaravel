<?php

namespace App\Console\Commands;

use App\Services\Alerts\AlertEngine;
use Illuminate\Console\Command;

class RunAlertEngine extends Command
{
    protected $signature = 'alerts:run';

    protected $description = 'Evalúa reglas de alerta y genera eventos pendientes';

    public function handle(AlertEngine $engine): int
    {
        $engine->run();

        $this->info('Alertas evaluadas correctamente.');

        return self::SUCCESS;
    }
}
