<?php

namespace App\Exceptions\Purchasing;

class PurchaseOrderNotFoundException extends PurchasingException
{
    public function errorCode(): string
    {
        return 'purchase_order_not_found';
    }
}
