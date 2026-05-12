<?php

namespace App\Exceptions\CashFund;

use App\Exceptions\Domain\DomainException;

class CashFundException extends DomainException
{
    public function errorCode(): string
    {
        return 'cash_fund_error';
    }
}
