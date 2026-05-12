<?php

namespace App\Adapters\FloreantPos\Dtos;

final readonly class PosMenuModifierDto
{
    public function __construct(
        public int $id,
        public string $name,
        public ?int $groupId,
        public ?string $groupName,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            id: (int) $row->id,
            name: $row->name ?? '',
            groupId: isset($row->group_id) ? (int) $row->group_id : null,
            groupName: $row->group_name ?? null,
        );
    }
}
