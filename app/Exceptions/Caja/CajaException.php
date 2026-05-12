<?php

namespace App\Exceptions\Caja;

use App\Exceptions\Domain\DomainException;

class CajaException extends DomainException
{
    public function errorCode(): string
    {
        return 'caja_error';
    }
}
