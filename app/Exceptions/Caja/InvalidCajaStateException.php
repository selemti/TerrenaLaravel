<?php

namespace App\Exceptions\Caja;

class InvalidCajaStateException extends CajaException
{
    public function errorCode(): string
    {
        return 'invalid_caja_state';
    }

    public static function transition(int|string $entityId, string $current, string $expected): static
    {
        $e = new static(
            "Caja entity {$entityId} must be in '{$expected}' to proceed. Current: '{$current}'."
        );
        $e->context = [
            'entity_id' => $entityId,
            'current_state' => $current,
            'expected_state' => $expected,
        ];
        return $e;
    }
}
