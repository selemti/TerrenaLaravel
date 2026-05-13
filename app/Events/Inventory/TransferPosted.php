<?php

namespace App\Events\Inventory;

use Illuminate\Foundation\Events\Dispatchable;

class TransferPosted
{
    use Dispatchable;

    public function __construct(
        public readonly string $transferId,
        public readonly string $fromAlmacenId,
        public readonly string $toAlmacenId,
        public readonly \DateTimeImmutable $postedAt,
    ) {}
}
