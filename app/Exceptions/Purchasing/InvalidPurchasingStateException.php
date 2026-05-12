<?php

namespace App\Exceptions\Purchasing;

class InvalidPurchasingStateException extends PurchasingException
{
    public function errorCode(): string
    {
        return 'invalid_purchasing_state';
    }
}
