<?php

namespace App\Services\Inventory;

use App\Adapters\FloreantPos\FloreantPosAdapter;

/**
 * Utilidades para validar y resolver modificadores del POS.
 * Delegadas al FloreantPosAdapter — no query public.* directamente.
 */
class ModifierValidationService
{
    public function __construct(protected FloreantPosAdapter $posAdapter) {}

    public function getModifierGroup(int $modifierId): ?int
    {
        return $this->posAdapter->getModifierGroupId($modifierId);
    }

    public function isModifier(int $itemId): bool
    {
        return $this->posAdapter->isModifier($itemId);
    }

    public function getModifierWithCorrectGroup(int $modifierId): ?object
    {
        $dto = $this->posAdapter->getModifierWithGroup($modifierId);

        if ($dto === null) {
            return null;
        }

        return (object) [
            'id' => $dto->id,
            'name' => $dto->name,
            'group_id' => $dto->groupId,
            'group_name' => $dto->groupName,
        ];
    }

    public function validateModifierConsistency(int $modifierId, int $ticketGroupId): bool
    {
        return $this->posAdapter->getModifierGroupId($modifierId) === $ticketGroupId;
    }
}
