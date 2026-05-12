<?php

namespace App\Exceptions\Inventory;

class InsufficientStockException extends InventoryException
{
    public function errorCode(): string
    {
        return 'insufficient_stock';
    }

    public static function forItem(int|string $itemId, float $requested, float $available): static
    {
        $e = new static(
            "Insufficient stock for item '{$itemId}': requested {$requested}, available {$available}."
        );
        $e->context = [
            'item_id' => $itemId,
            'requested' => $requested,
            'available' => $available,
        ];
        return $e;
    }
}
