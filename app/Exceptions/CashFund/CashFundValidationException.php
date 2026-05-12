<?php

namespace App\Exceptions\CashFund;

class CashFundValidationException extends CashFundException
{
    public function errorCode(): string
    {
        return 'cash_fund_validation_error';
    }
}
