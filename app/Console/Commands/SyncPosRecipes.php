<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class SyncPosRecipes extends Command
{
    protected $signature = 'recipes:sync-pos {--modifiers : DEPRECADO. Solo actualiza metadatos de modificadores existentes} {--dry-run : Muestra acciones sin aplicar cambios}';

    protected $description = 'Sincroniza metadatos básicos de Floreant POS contra recetas PREVIAMENTE vinculadas. Ya no crea recetas nuevas de forma automática.';

    public function handle(): int
    {
        $dry = $this->option('dry-run');
        $withModifiers = $this->option('modifiers');

        $conn = $this->resolvePosConnection();

        $this->info(($dry ? '[DRY RUN] ' : '').'Sincronizando metadatos ERP <-> POS (Modo Estructural Asistido)...');

        $items = $conn->table('public.menu_item as mi')
            ->leftJoin('public.menu_group as mg', 'mi.group_id', '=', 'mg.id')
            ->select('mi.id', 'mi.name', 'mi.price', 'mg.name as group_name', 'mi.visible')
            ->orderBy('mi.id')
            ->get();

        $updatedRecipes = 0;
        $unlinkedPosItems = 0;

        foreach ($items as $item) {
            $posIdStr = (string) $item->id;
            $attributes = [
                // 'nombre_plato' => $item->name, // DESACTIVADO: Respetar soberanía del chef sobre el nombre
                'categoria_plato' => $item->group_name ?? null,
                'precio_venta_sugerido' => $item->price ?? 0,
            ];

            // Validar si EXISTE un vínculo manual asistido ya creado
            $exists = DB::table('selemti.receta_cab')->where('codigo_plato_pos', $posIdStr)->first();

            if ($exists) {
                $updatedRecipes++;
                if (! $dry) {
                    DB::table('selemti.receta_cab')->where('id', $exists->id)->update($attributes + ['updated_at' => now()]);
                }
            } else {
                // El item de POS no tiene receta en ERP. No se crea cascarón automático.
                $unlinkedPosItems++;
            }
        }

        $this->warn('Aviso: El comando ya no crea cascarones ciegos. Use la interfaz POS Link para vincular.');
        $this->info("Recetas vinculadas actualizadas: {$updatedRecipes}");
        $this->comment("Platillos POS sin receta vinculada (Bandeja Pendientes): {$unlinkedPosItems}");

        if ($withModifiers) {
            $this->syncModifiers($dry, $conn);
        }

        return Command::SUCCESS;
    }

    protected function syncModifiers(bool $dry, $conn): void
    {
        $this->info(($dry ? '[DRY RUN] ' : '').'Actualizando metadatos de modificadores vinculados...');

        $modifiers = $conn->table('public.menu_modifier as mm')
            ->leftJoin('public.menu_modifier_group as mg', 'mm.group_id', '=', 'mg.id')
            ->select('mm.id', 'mm.name', 'mm.price', 'mg.name as group_name')
            ->orderBy('mm.id')
            ->get();

        $updatedMods = 0;
        $unlinkedMods = 0;

        foreach ($modifiers as $mod) {
            $modCode = sprintf('MOD-%05d', $mod->id);

            // Solo actualiza modificadores POS explícitamente guardados
            $exists = DB::table('selemti.modificadores_pos')->where('codigo_pos', $modCode)->first();

            if ($exists) {
                $updatedMods++;
                if (! $dry) {
                    DB::table('selemti.modificadores_pos')
                        ->where('codigo_pos', $modCode)
                        ->update([
                            'nombre' => $mod->name,
                            'precio_extra' => $mod->price ?? 0,
                        ]);
                }
            } else {
                $unlinkedMods++;
            }
        }

        $this->info("Modificadores vinculados actualizados: {$updatedMods}");
        $this->comment("Modificadores POS ignorados/sin vínculo: {$unlinkedMods}");
    }

    protected function resolvePosConnection()
    {
        $base = config('database.connections.pgsql');

        $host = env('POS_DB_HOST', env('DB_HOST', '127.0.0.1'));
        if ($host === '127.0.0.1') {
            $host = '172.24.240.1';
        }

        $base['host'] = $host;
        $base['port'] = env('POS_DB_PORT', env('DB_PORT', '5432'));
        $base['database'] = env('POS_DB_DATABASE', env('DB_DATABASE', 'pos'));
        $base['username'] = env('POS_DB_USERNAME', env('DB_USERNAME', 'postgres'));
        $base['password'] = env('POS_DB_PASSWORD', env('DB_PASSWORD', ''));

        config(['database.connections.pgsql' => $base]);
        config(['database.connections.pos_pg' => $base]);

        return DB::connection('pos_pg');
    }
}
