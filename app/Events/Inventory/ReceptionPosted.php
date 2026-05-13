<?php

namespace App\Events\Inventory;

use Illuminate\Foundation\Events\Dispatchable;

class ReceptionPosted
{
    use Dispatchable;

    public function __construct(
        public readonly string $receptionId,
        public readonly string $almacenId,
        public readonly \DateTimeImmutable $postedAt,
    ) {}
}
