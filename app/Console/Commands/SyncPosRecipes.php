<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SyncPosRecipes extends Command
{
    protected $signature = 'recipes:sync-pos {--modifiers : Sincroniza también los modificadores del POS como sub-recetas placeholder} {--dry-run : Muestra acciones sin aplicar cambios}';

    protected $description = 'Sincroniza productos de Floreant POS con el catálogo de recetas (receta_cab, receta_version y placeholders para modificadores).';

    public function handle(): int
    {
        $dry = $this->option('dry-run');
        $withModifiers = $this->option('modifiers');

        $this->info(($dry ? '[DRY RUN] ' : '') . 'Sincronizando productos del POS...');

        $items = DB::connection()->table('public.menu_item as mi')
            ->leftJoin('public.menu_group as mg', 'mi.group_id', '=', 'mg.id')
            ->select('mi.id', 'mi.name', 'mi.price', 'mg.name as group_name', 'mi.visible')
            ->orderBy('mi.id')
            ->get();

        $createdRecipes = 0;
        $createdVersions = 0;
        $updatedRecipes = 0;

        foreach ($items as $item) {
            $recipeId = sprintf('REC-%05d', $item->id);
            $attributes = [
                'nombre_plato' => $item->name,
                'codigo_plato_pos' => (string) $item->id,
                'categoria_plato' => $item->group_name ?? null,
                'precio_venta_sugerido' => $item->price ?? 0,
            ];

            $exists = DB::table('selemti.receta_cab')->where('id', $recipeId)->first();
            if ($exists) {
                $updatedRecipes++;
                if (!$dry) {
                    DB::table('selemti.receta_cab')->where('id', $recipeId)->update($attributes + ['updated_at' => now()]);
                }
            } else {
                $createdRecipes++;
                if (!$dry) {
                    DB::table('selemti.receta_cab')->insert($attributes + [
                        'id' => $recipeId,
                        'porciones_standard' => 1,
                        'costo_standard_porcion' => 0,
                        'activo' => true,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }

            $versionExists = DB::table('selemti.receta_version')
                ->where('receta_id', $recipeId)
                ->where('version', 1)
                ->exists();

            if (!$versionExists) {
                $createdVersions++;
                if (!$dry) {
                    DB::table('selemti.receta_version')->insert([
                        'receta_id' => $recipeId,
                        'version' => 1,
                        'descripcion_cambios' => 'Versión generada automáticamente desde Floreant POS',
                        'fecha_efectiva' => now()->toDateString(),
                        'version_publicada' => false,
                        'created_at' => now(),
                    ]);
                }
            }
        }

        $this->info("Recetas nuevas: {$createdRecipes}");
        $this->info("Recetas actualizadas: {$updatedRecipes}");
        $this->info("Versiones iniciales creadas: {$createdVersions}");

        if ($withModifiers) {
            $this->syncModifiers($dry);
        }

        return Command::SUCCESS;
    }

    protected function syncModifiers(bool $dry): void
    {
        $this->info(($dry ? '[DRY RUN] ' : '') . 'Sincronizando modificadores del POS...');

        $modifiers = DB::connection()->table('public.menu_modifier as mm')
            ->leftJoin('public.menu_modifier_group as mg', 'mm.group_id', '=', 'mg.id')
            ->select('mm.id', 'mm.name', 'mm.price', 'mg.name as group_name')
            ->orderBy('mm.id')
            ->get();

        $createdMods = 0;
        $createdModRecipes = 0;

        foreach ($modifiers as $mod) {
            $modCode = sprintf('MOD-%05d', $mod->id);
            $recipeId = sprintf('REC-MOD-%05d', $mod->id);

            $exists = DB::table('selemti.modificadores_pos')->where('codigo_pos', $modCode)->first();
            if (!$exists) {
                $createdMods++;
                if (!$dry) {
                    DB::table('selemti.modificadores_pos')->insert([
                        'codigo_pos' => $modCode,
                        'nombre' => $mod->name,
                        'tipo' => $mod->group_name ?? null,
                        'precio_extra' => $mod->price ?? 0,
                        'receta_modificador_id' => $recipeId,
                        'activo' => true,
                    ]);
                }
            }

            $recipeExists = DB::table('selemti.receta_cab')->where('id', $recipeId)->exists();
            if (!$recipeExists) {
                $createdModRecipes++;
                if (!$dry) {
                    DB::table('selemti.receta_cab')->insert([
                        'id' => $recipeId,
                        'nombre_plato' => $mod->group_name ? $mod->group_name . ' · ' . $mod->name : $mod->name,
                        'codigo_plato_pos' => $modCode,
                        'categoria_plato' => $mod->group_name,
                        'porciones_standard' => 1,
                        'costo_standard_porcion' => 0,
                        'precio_venta_sugerido' => $mod->price ?? 0,
                        'activo' => true,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    DB::table('selemti.receta_version')->insert([
                        'receta_id' => $recipeId,
                        'version' => 1,
                        'descripcion_cambios' => 'Placeholder auto-generado para modificador POS',
                        'fecha_efectiva' => now()->toDateString(),
                        'version_publicada' => false,
                        'created_at' => now(),
                    ]);
                }
            }
        }

        $this->info("Modificadores registrados: {$createdMods}");
        $this->info("Recetas placeholder para modificadores: {$createdModRecipes}");

        $this->info('Sincronización de modificadores completada (placeholders creados; pendientes vínculos de ingredientes reales).');
    }
}
