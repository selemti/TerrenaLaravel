<?php

namespace App\Exceptions\Transfer;

class InvalidTransferStateException extends TransferException
{
    public function errorCode(): string
    {
        return 'invalid_transfer_state';
    }

    public static function transition(int|string $transferId, string $current, string $expected): static
    {
        $e = new static(
            "Transfer {$transferId} must be in '{$expected}' status to proceed. Current: '{$current}'."
        );
        $e->context = [
            'transfer_id' => $transferId,
            'current_state' => $current,
            'expected_state' => $expected,
        ];

        return $e;
    }
}
