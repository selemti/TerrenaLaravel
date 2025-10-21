<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Schema;

class VerifyCatalogTables extends Command
{
    protected $signature = 'catalogs:verify-tables {--details : Muestra también las columnas básicas esperadas.}';

    protected $description = 'Valida que existan las tablas requeridas por los catálogos de Terrena.';

    /**
     * Lista de tablas a validar y, opcionalmente, columnas clave.
     *
     * @var array<string, array<string>>
     */
    protected array $catalogTables = [
        'cat_unidades'        => ['clave', 'nombre'],
        'cat_uom_conversion'  => ['origen_id', 'destino_id', 'factor'],
        'cat_proveedores'     => ['rfc', 'nombre'],
        'cat_sucursales'      => ['clave', 'nombre'],
        'cat_almacenes'       => ['clave', 'nombre'],
        'inv_stock_policy'    => ['item_id', 'sucursal_id'],
        'items'               => ['id', 'nombre'],
        'selemti.unidades_medida' => ['codigo', 'nombre'],
    ];

    public function handle(): int
    {
        $this->info('Validando tablas de catálogos...');
        $this->newLine();

        $rows = [];
        try {
            foreach ($this->catalogTables as $table => $columns) {
                $exists = Schema::hasTable($table);
                $missingColumns = [];

                if ($exists && $this->option('details')) {
                    $actualColumns = collect(Schema::getColumnListing($table));
                    $missingColumns = collect($columns)
                        ->reject(fn ($col) => $actualColumns->contains($col))
                        ->values()
                        ->all();
                }

                $rows[] = [
                    'Tabla'    => $table,
                    'Estado'   => $exists ? 'OK' : 'FALTA',
                    'Detalles' => $exists
                        ? ($this->option('details') && ! empty($missingColumns)
                            ? 'Faltan columnas: ' . implode(', ', $missingColumns)
                            : '')
                        : 'Ejecuta las migraciones correspondientes',
                ];
            }
        } catch (\Throwable $e) {
            $this->error('No se pudo conectar a la base de datos: ' . $e->getMessage());
            $this->newLine();
            $this->warn('Verifica tus credenciales en el archivo .env o que el servidor de base de datos esté escuchando.');
            return self::FAILURE;
        }

        $this->table(['Tabla', 'Estado', 'Detalles'], $rows);

        $missing = collect($rows)->where('Estado', 'FALTA')->pluck('Tabla')->all();
        if (! empty($missing)) {
            $this->newLine();
            $this->error('Algunas tablas faltan. Ejecuta "php artisan migrate" y vuelve a correr la verificación.');
            return self::FAILURE;
        }

        $this->newLine();
        $this->info('Todas las tablas requeridas están presentes.');
        return self::SUCCESS;
    }
}
