<?php

namespace App\Events\Pos;

use Illuminate\Foundation\Events\Dispatchable;

class PosTicketIngested
{
    use Dispatchable;

    public function __construct(
        public readonly int $ticketId,
        public readonly string $date,
        public readonly ?int $terminalId = null,
    ) {}
}
