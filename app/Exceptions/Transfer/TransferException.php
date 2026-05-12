<?php

namespace App\Exceptions\Transfer;

use App\Exceptions\Domain\DomainException;

class TransferException extends DomainException
{
    public function errorCode(): string
    {
        return 'transfer_error';
    }
}
