<?php

namespace App\Exceptions\Transfer;

class TransferNotFoundException extends TransferException
{
    public function errorCode(): string
    {
        return 'transfer_not_found';
    }

    public static function forId(int|string $transferId): static
    {
        $e = new static("Transfer '{$transferId}' not found.");
        $e->context = ['transfer_id' => $transferId];
        return $e;
    }
}
