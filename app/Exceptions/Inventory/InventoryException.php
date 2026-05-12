<?php

namespace App\Exceptions\Inventory;

use App\Exceptions\Domain\DomainException;

class InventoryException extends DomainException
{
    public function errorCode(): string
    {
        return 'inventory_error';
    }
}
