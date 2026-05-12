<?php

namespace App\Exceptions\Inventory;

class ItemNotFoundException extends InventoryException
{
    public function errorCode(): string
    {
        return 'item_not_found';
    }

    public static function forId(int|string $itemId): static
    {
        $e = new static("Item '{$itemId}' not found.");
        $e->context = ['item_id' => $itemId];

        return $e;
    }

    public static function reception(int|string $receptionId): static
    {
        $e = new static("Reception '{$receptionId}' not found.");
        $e->context = ['reception_id' => $receptionId];

        return $e;
    }
}
