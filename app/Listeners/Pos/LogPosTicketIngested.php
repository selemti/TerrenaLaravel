<?php

namespace App\Listeners\Pos;

use App\Events\Pos\PosTicketIngested;
use Illuminate\Support\Facades\Log;

class LogPosTicketIngested
{
    public function handle(PosTicketIngested $event): void
    {
        Log::channel('daily')->info('PosTicketIngested', [
            'ticket_id' => $event->ticketId,
            'terminal_id' => $event->terminalId,
            'date' => $event->date,
        ]);
    }
}
