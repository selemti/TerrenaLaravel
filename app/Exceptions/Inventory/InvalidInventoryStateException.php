<?php

namespace App\Exceptions\Inventory;

class InvalidInventoryStateException extends InventoryException
{
    public function errorCode(): string
    {
        return 'invalid_inventory_state';
    }

    public static function transition(int|string $entityId, string $current, string $expected): static
    {
        $e = new static(
            "Cannot transition entity {$entityId} from '{$current}' to '{$expected}'."
        );
        $e->context = [
            'entity_id' => $entityId,
            'current_state' => $current,
            'expected_state' => $expected,
        ];
        return $e;
    }
}
