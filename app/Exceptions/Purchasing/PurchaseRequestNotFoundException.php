<?php

namespace App\Exceptions\Purchasing;

class PurchaseRequestNotFoundException extends PurchasingException
{
    public function errorCode(): string
    {
        return 'purchase_request_not_found';
    }
}
