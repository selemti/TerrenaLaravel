<?php

namespace App\Listeners\Inventory;

use App\Events\Inventory\TransferPosted;
use Illuminate\Support\Facades\Log;

class LogTransferPosted
{
    public function handle(TransferPosted $event): void
    {
        Log::info('Transfer posted', [
            'transfer_id' => $event->transferId,
            'from' => $event->fromAlmacenId,
            'to' => $event->toAlmacenId,
            'posted_at' => $event->postedAt->format('Y-m-d H:i:s'),
        ]);
    }
}
