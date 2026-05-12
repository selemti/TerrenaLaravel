<?php

namespace App\Exceptions\Purchasing;

use App\Exceptions\Domain\DomainException;

abstract class PurchasingException extends DomainException
{
    public function errorCode(): string
    {
        return 'purchasing_error';
    }
}
