<?php

namespace App\Adapters\FloreantPos\Dtos;

final readonly class PosTicketDto
{
    public function __construct(
        public int $id,
        public ?string $creationDate,
        public ?string $paidTime,
        public ?string $closingDate,
        public bool $paid,
        public bool $voided,
        public ?int $terminalId,
        public float $totalDiscount,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            id: (int) $row->id,
            creationDate: $row->creation_date ?? null,
            paidTime: $row->paid_time ?? null,
            closingDate: $row->closing_date ?? null,
            paid: (bool) ($row->paid ?? false),
            voided: (bool) ($row->voided ?? false),
            terminalId: isset($row->terminal_id) ? (int) $row->terminal_id : null,
            totalDiscount: (float) ($row->total_discount ?? 0),
        );
    }
}
