<?php

namespace App\Exceptions\Replenishment;

use App\Exceptions\Domain\DomainException;

class ReplenishmentException extends DomainException
{
    public function errorCode(): string
    {
        return 'replenishment_error';
    }
}
