<?php

namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;

/**
 * Utilidades para validar y resolver modificadores usando la relación correcta:
 * ticket_item_modifier.item_id -> menu_modifier.id -> menu_modifier.group_id.
 */
class ModifierValidationService
{
    /**
     * Obtiene el group_id correcto de un modificador del maestro POS.
     */
    public function getModifierGroup(int $modifierId): ?int
    {
        return DB::connection('pgsql')
            ->table('public.menu_modifier')
            ->where('id', $modifierId)
            ->value('group_id');
    }

    /**
     * Verifica si el item corresponde a un modificador registrado.
     */
    public function isModifier(int $itemId): bool
    {
        return DB::connection('pgsql')
            ->table('public.menu_modifier')
            ->where('id', $itemId)
            ->exists();
    }

    /**
     * Devuelve el modificador con su grupo correcto ya resuelto.
     */
    public function getModifierWithCorrectGroup(int $modifierId)
    {
        return DB::connection('pgsql')
            ->table('public.menu_modifier as mm')
            ->join('public.menu_modifier_group as mg', 'mg.id', '=', 'mm.group_id')
            ->where('mm.id', $modifierId)
            ->select('mm.*', 'mg.name as group_name', 'mg.id as group_id')
            ->first();
    }

    /**
     * Valida que el modificador pertenezca al group_id indicado por el ticket.
     */
    public function validateModifierConsistency(int $modifierId, int $ticketGroupId): bool
    {
        $correctGroupId = $this->getModifierGroup($modifierId);

        return $correctGroupId === $ticketGroupId;
    }
}
