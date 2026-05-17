<?php

namespace App\Services\Pos;

use App\Models\Pos\PosMenuItemRecipeMapping;
use App\Models\Pos\PosModifierInvMapping;
use Illuminate\Support\Facades\Cache;

class PosModifierService
{
    private const CACHE_TTL = 3600;

    private const MODIFIER_ID_CACHE_KEY = 'pos_modifier_mapping.by_id';

    private const MODIFIER_NAME_CACHE_KEY = 'pos_modifier_mapping.by_name';

    private const MENU_ITEM_CACHE_KEY = 'pos_menu_item_recipe_mapping.by_menu_item_id';

    public function findMapping(int $menuModifierId, string $modifierName): ?PosModifierInvMapping
    {
        $byId = $this->modifierMappingsById();
        if ($menuModifierId > 0 && isset($byId[$menuModifierId])) {
            return $byId[$menuModifierId];
        }

        $name = trim($modifierName);
        if ($name === '') {
            return null;
        }

        return $this->modifierMappingsByName()[$name] ?? null;
    }

    public function findMenuItemMapping(int $menuItemId): ?PosMenuItemRecipeMapping
    {
        return $this->menuItemMappings()[$menuItemId] ?? null;
    }

    public function warmCache(): void
    {
        $this->modifierMappingsById();
        $this->modifierMappingsByName();
        $this->menuItemMappings();
    }

    public function clearCache(): void
    {
        Cache::forget(self::MODIFIER_ID_CACHE_KEY);
        Cache::forget(self::MODIFIER_NAME_CACHE_KEY);
        Cache::forget(self::MENU_ITEM_CACHE_KEY);
    }

    /**
     * @return array<int, PosModifierInvMapping>
     */
    private function modifierMappingsById(): array
    {
        return Cache::remember(self::MODIFIER_ID_CACHE_KEY, self::CACHE_TTL, function (): array {
            return PosModifierInvMapping::query()
                ->where('activo', true)
                ->whereNotNull('menu_modifier_id')
                ->get()
                ->keyBy('menu_modifier_id')
                ->all();
        });
    }

    /**
     * @return array<string, PosModifierInvMapping>
     */
    private function modifierMappingsByName(): array
    {
        return Cache::remember(self::MODIFIER_NAME_CACHE_KEY, self::CACHE_TTL, function (): array {
            return PosModifierInvMapping::query()
                ->where('activo', true)
                ->whereNotNull('modifier_name_trim')
                ->get()
                ->keyBy(fn (PosModifierInvMapping $mapping): string => trim((string) $mapping->modifier_name_trim))
                ->all();
        });
    }

    /**
     * @return array<int, PosMenuItemRecipeMapping>
     */
    private function menuItemMappings(): array
    {
        return Cache::remember(self::MENU_ITEM_CACHE_KEY, self::CACHE_TTL, function (): array {
            return PosMenuItemRecipeMapping::query()
                ->where('activo', true)
                ->get()
                ->keyBy('menu_item_id')
                ->all();
        });
    }
}
