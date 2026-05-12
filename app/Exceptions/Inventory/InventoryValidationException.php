<?php

namespace App\Exceptions\Inventory;

class InventoryValidationException extends InventoryException
{
    public function errorCode(): string
    {
        return 'inventory_validation_error';
    }
}
