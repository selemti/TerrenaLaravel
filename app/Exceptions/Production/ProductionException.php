<?php

namespace App\Exceptions\Production;

use App\Exceptions\Domain\DomainException;

class ProductionException extends DomainException
{
    public function errorCode(): string
    {
        return 'production_error';
    }
}
