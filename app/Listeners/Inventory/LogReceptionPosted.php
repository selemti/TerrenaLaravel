<?php

namespace App\Listeners\Inventory;

use App\Events\Inventory\ReceptionPosted;
use Illuminate\Support\Facades\Log;

class LogReceptionPosted
{
    public function handle(ReceptionPosted $event): void
    {
        Log::info('Reception posted', [
            'reception_id' => $event->receptionId,
            'almacen_id' => $event->almacenId,
            'posted_at' => $event->postedAt->format('Y-m-d H:i:s'),
        ]);
    }
}
