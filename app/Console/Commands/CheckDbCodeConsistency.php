<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

/**
 * Comando para verificar consistencia entre BD y código
 * Detecta MISMATCH y columnas FANTASMA
 *
 * Uso: php artisan check:db-code-consistency
 */
class CheckDbCodeConsistency extends Command
{
    protected $signature = 'check:db-code-consistency 
                            {--verbose : Mostrar todas las verificaciones}
                            {--only-errors : Mostrar solo errores}';

    protected $description = 'Verifica consistencia entre BD real y mapeo documentado de campos';

    private $errors = [];

    private $warnings = [];

    private $checked = 0;

    private $mapFilePath = 'docs/V4.0/Code/BD_CODIGO_MAPA_CAMPOS_ALL_VERIFICADO.md';

    public function handle()
    {
        $this->info('═══════════════════════════════════════════════════════');
        $this->info('  CHECK AUTOMÁTICO: BD ↔ CÓDIGO');
        $this->info('═══════════════════════════════════════════════════════');
        $this->newLine();

        // Verificar que existe el archivo de mapeo
        $fullPath = base_path($this->mapFilePath);
        if (! File::exists($fullPath)) {
            $this->error("❌ No se encontró el archivo de mapeo: {$this->mapFilePath}");

            return 1;
        }

        $this->info("📄 Leyendo mapeo desde: {$this->mapFilePath}");
        $this->newLine();

        // Leer y parsear el archivo
        $content = File::get($fullPath);
        $rows = $this->parseMarkdownTable($content);

        if (empty($rows)) {
            $this->error('❌ No se pudieron parsear filas del archivo de mapeo');

            return 1;
        }

        $this->info('📊 Total de filas a verificar: '.count($rows));
        $this->newLine();

        // Obtener todas las tablas y columnas de la BD
        $dbSchema = $this->getDatabaseSchema();

        $this->info('🔍 Iniciando verificación...');
        $this->newLine();

        // Verificar cada fila
        foreach ($rows as $row) {
            $this->checkRow($row, $dbSchema);
        }

        // Mostrar reporte
        $this->showReport();

        return empty($this->errors) ? 0 : 1;
    }

    private function parseMarkdownTable($content)
    {
        $lines = explode("\n", $content);
        $rows = [];
        $inTable = false;
        $headers = [];

        foreach ($lines as $line) {
            $line = trim($line);

            if (empty($line) || strpos($line, '#') === 0) {
                continue;
            }

            if (strpos($line, '|') === false) {
                continue;
            }

            // Es una línea de tabla
            $cells = array_map('trim', explode('|', $line));
            $cells = array_filter($cells, fn ($c) => $c !== '');
            $cells = array_values($cells);

            // Detectar headers
            if (empty($headers)) {
                $headers = $cells;
                $inTable = true;

                continue;
            }

            // Saltar línea separadora (contiene guiones)
            if (isset($cells[0]) && preg_match('/^-+$/', $cells[0])) {
                continue;
            }

            // Es una fila de datos
            if ($inTable && count($cells) >= 4) {
                $row = [];
                foreach ($headers as $i => $header) {
                    $row[$header] = $cells[$i] ?? '';
                }
                $rows[] = $row;
            }
        }

        return $rows;
    }

    private function getDatabaseSchema()
    {
        $schema = [];

        // Obtener todas las tablas y columnas de ambos esquemas
        $tables = DB::select("
            SELECT 
                table_schema,
                table_name,
                column_name,
                data_type
            FROM information_schema.columns
            WHERE table_schema IN ('public', 'selemti')
            ORDER BY table_schema, table_name, ordinal_position
        ");

        foreach ($tables as $table) {
            $schemaName = $table->table_schema;
            $tableName = $table->table_name;
            $columnName = $table->column_name;

            if (! isset($schema[$schemaName])) {
                $schema[$schemaName] = [];
            }
            if (! isset($schema[$schemaName][$tableName])) {
                $schema[$schemaName][$tableName] = [];
            }
            $schema[$schemaName][$tableName][] = $columnName;
        }

        return $schema;
    }

    private function checkRow($row, $dbSchema)
    {
        $this->checked++;

        $schema = $row['esquema'] ?? '';
        $table = $row['tabla_bd'] ?? '';
        $column = $row['columna_bd'] ?? '';
        $existeEnBd = strtoupper(trim($row['existe_en_bd'] ?? ''));
        $decisionFinal = strtoupper(trim($row['decision_final'] ?? ''));
        $estadoBd = strtoupper(trim($row['estado_bd'] ?? ''));

        // Validar que tenemos los datos mínimos
        if (empty($schema) || empty($table) || empty($column)) {
            return;
        }

        // Verificar existencia real en BD
        $existsInDb = isset($dbSchema[$schema][$table])
                      && in_array($column, $dbSchema[$schema][$table]);

        // Casos de error:

        // 1. El mapeo dice que existe en BD pero no está
        if ($existeEnBd === 'SI' && ! $existsInDb) {
            $this->errors[] = [
                'tipo' => 'BD_FALTANTE',
                'esquema' => $schema,
                'tabla' => $table,
                'columna' => $column,
                'mensaje' => 'Mapeo indica que existe en BD pero NO se encontró en BD real',
                'estado_bd' => $estadoBd,
                'decision' => $decisionFinal,
            ];
        }

        // 2. El mapeo dice que NO existe pero sí está en BD
        if ($existeEnBd === 'NO' && $existsInDb) {
            $this->warnings[] = [
                'tipo' => 'BD_NUEVA',
                'esquema' => $schema,
                'tabla' => $table,
                'columna' => $column,
                'mensaje' => 'Mapeo indica NO_EXISTE pero la columna SÍ está en BD real',
                'estado_bd' => $estadoBd,
                'decision' => $decisionFinal,
            ];
        }

        // 3. Marcado como CONFIABLE pero el estado_bd indica problemas
        if ($decisionFinal === 'CONFIABLE') {
            if ($estadoBd === 'NO_EXISTE' && $existsInDb) {
                $this->warnings[] = [
                    'tipo' => 'INCONSISTENCIA_ESTADO',
                    'esquema' => $schema,
                    'tabla' => $table,
                    'columna' => $column,
                    'mensaje' => 'Marcado CONFIABLE con estado NO_EXISTE pero la columna existe en BD',
                    'estado_bd' => $estadoBd,
                    'decision' => $decisionFinal,
                ];
            }
        }

        // Mostrar verbose si se solicita
        if ($this->option('verbose') && ! $this->option('only-errors')) {
            $status = $existsInDb ? '✓' : '✗';
            $this->line("  {$status} {$schema}.{$table}.{$column}");
        }
    }

    private function showReport()
    {
        $this->newLine();
        $this->info('═══════════════════════════════════════════════════════');
        $this->info('  REPORTE DE VERIFICACIÓN');
        $this->info('═══════════════════════════════════════════════════════');
        $this->newLine();

        $this->info("✓ Filas verificadas: {$this->checked}");
        $this->info('✗ Errores encontrados: '.count($this->errors));
        $this->info('⚠ Advertencias: '.count($this->warnings));
        $this->newLine();

        if (empty($this->errors) && empty($this->warnings)) {
            $this->info('🎉 ¡TODO OK! No se encontraron inconsistencias.');

            return;
        }

        // Mostrar errores
        if (! empty($this->errors)) {
            $this->error('═══════════════════════════════════════════════════════');
            $this->error('  ❌ ERRORES CRÍTICOS');
            $this->error('═══════════════════════════════════════════════════════');
            $this->newLine();

            foreach ($this->errors as $error) {
                $this->error("  {$error['tipo']}: {$error['esquema']}.{$error['tabla']}.{$error['columna']}");
                $this->line("    → {$error['mensaje']}");
                $this->line("    → Estado BD: {$error['estado_bd']} | Decisión: {$error['decision']}");
                $this->newLine();
            }
        }

        // Mostrar advertencias
        if (! empty($this->warnings) && ! $this->option('only-errors')) {
            $this->warn('═══════════════════════════════════════════════════════');
            $this->warn('  ⚠ ADVERTENCIAS');
            $this->warn('═══════════════════════════════════════════════════════');
            $this->newLine();

            foreach ($this->warnings as $warning) {
                $this->warn("  {$warning['tipo']}: {$warning['esquema']}.{$warning['tabla']}.{$warning['columna']}");
                $this->line("    → {$warning['mensaje']}");
                $this->line("    → Estado BD: {$warning['estado_bd']} | Decisión: {$warning['decision']}");
                $this->newLine();
            }
        }

        $this->newLine();
        $this->info('═══════════════════════════════════════════════════════');
        $this->info('  RESUMEN');
        $this->info('═══════════════════════════════════════════════════════');

        if (! empty($this->errors)) {
            $this->error('⚠ Se encontraron inconsistencias que requieren atención.');
            $this->error('  Actualiza el archivo de mapeo o corrige la BD.');
        } else {
            $this->info('✓ No se encontraron errores críticos.');
        }
    }
}
