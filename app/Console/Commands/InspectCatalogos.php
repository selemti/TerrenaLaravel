<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class InspectCatalogos extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'terrena:inspect-catalogos';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Devuelve catálogos clave (sucursales, proveedores, almacenes, etc.) desde el esquema selemti';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $output = [
            'sucursales' => [],
            'proveedores' => [],
            'almacenes' => [],
        ];

        // Catálogo de Sucursales
        try {
            $sucursales = DB::connection('pgsql')
                ->table('selemti.cat_sucursales')
                ->select('id', 'nombre', 'clave', 'activo')
                ->limit(200)
                ->get();
            $output['sucursales'] = $sucursales->toArray();
        } catch (\Exception $e) {
            $this->warn("Tabla selemti.cat_sucursales no encontrada o error: " . $e->getMessage());
        }

        // Catálogo de Proveedores
        try {
            $proveedores = DB::connection('pgsql')
                ->table('selemti.cat_proveedores')
                ->select('id', 'razon_social', 'rfc', 'activo')
                ->limit(200)
                ->get();
            $output['proveedores'] = $proveedores->toArray();
        } catch (\Exception $e) {
            $this->warn("Tabla selemti.cat_proveedores no encontrada o error: " . $e->getMessage());
        }

        // Catálogo de Almacenes
        try {
            $almacenes = DB::connection('pgsql')
                ->table('selemti.cat_almacenes')
                ->select('id', 'descripcion', 'sucursal_id', 'activo')
                ->limit(200)
                ->get();
            $output['almacenes'] = $almacenes->toArray();
        } catch (\Exception $e) {
            $this->warn("Tabla selemti.cat_almacenes no encontrada o error: " . $e->getMessage());
        }

        $this->info(json_encode($output, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    }
}
