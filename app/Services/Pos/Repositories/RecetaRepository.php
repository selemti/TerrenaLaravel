<?php

namespace App\Services\Pos\Repositories;

use Illuminate\Support\Facades\DB;

class RecetaRepository
{
    /**
     * Obtiene el recipe_version_id mapeado para un pos_code
     *
     * @param string $posCode
     * @return int|null
     */
    public function getRecipeVersionForPosCode(string $posCode): ?int
    {
        $result = DB::connection('pgsql')
            ->table('selemti.pos_map')
            ->where('pos_code', $posCode)
            ->where('is_active', true)
            ->value('recipe_version_id');

        return $result ? (int) $result : null;
    }

    /**
     * Obtiene los items de una versión de receta
     *
     * @param int $recipeVersionId
     * @return array
     */
    public function getRecipeItemsByRecipeVersion(int $recipeVersionId): array
    {
        $results = DB::connection('pgsql')
            ->table('selemti.recipe_version_items as rvi')
            ->leftJoin('selemti.items as i', 'i.id', '=', 'rvi.item_id')
            ->where('rvi.recipe_version_id', $recipeVersionId)
            ->select([
                'rvi.item_id',
                'rvi.qty',
                'rvi.uom',
                'i.descripcion as item_descripcion',
                'i.clave as item_clave',
                'i.es_producible',
                'i.es_consumible_operativo',
                'i.es_empaque_to_go',
            ])
            ->get();

        return $results->map(fn ($item) => (array) $item)->toArray();
    }

    /**
     * Obtiene información de una receta
     *
     * @param int $recipeId
     * @return array|null
     */
    public function getRecipeInfo(int $recipeId): ?array
    {
        $result = DB::connection('pgsql')
            ->table('selemti.recipe_versions')
            ->where('id', $recipeId)
            ->first();

        return $result ? (array) $result : null;
    }

    /**
     * Verifica si un pos_code tiene mapeo activo
     *
     * @param string $posCode
     * @return bool
     */
    public function hasActiveMapping(string $posCode): bool
    {
        return DB::connection('pgsql')
            ->table('selemti.pos_map')
            ->where('pos_code', $posCode)
            ->where('is_active', true)
            ->exists();
    }

    /**
     * Obtiene todos los mapeos activos
     *
     * @return array
     */
    public function getAllActiveMappings(): array
    {
        $results = DB::connection('pgsql')
            ->table('selemti.pos_map')
            ->where('is_active', true)
            ->get();

        return $results->map(fn ($map) => (array) $map)->toArray();
    }

    /**
     * Obtiene mapeos por patrón de pos_code
     *
     * @param string $pattern
     * @return array
     */
    public function getMappingsByPattern(string $pattern): array
    {
        $results = DB::connection('pgsql')
            ->table('selemti.pos_map')
            ->where('pos_code', 'LIKE', $pattern)
            ->where('is_active', true)
            ->get();

        return $results->map(fn ($map) => (array) $map)->toArray();
    }
}
