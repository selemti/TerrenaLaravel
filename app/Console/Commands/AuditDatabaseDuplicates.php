<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class AuditDatabaseDuplicates extends Command
{
    protected $signature = 'db:audit-duplicates';

    protected $description = 'Auditoría exhaustiva de tablas duplicadas y legacy en PostgreSQL';

    public function handle()
    {
        $this->info('=== AUDITORÍA DE BASE DE DATOS PostgreSQL ===');
        $this->info('Fecha: '.now()->format('Y-m-d H:i:s'));
        $this->newLine();

        // Get all tables from both schemas
        $selemti_tables = $this->getTables('selemti');
        $public_tables = $this->getTables('public');

        $this->info('=== RESUMEN ===');
        $this->info('Tablas en selemti: '.count($selemti_tables));
        $this->info('Tablas en public: '.count($public_tables));
        $this->info('TOTAL: '.(count($selemti_tables) + count($public_tables)));
        $this->newLine();

        // Analyze all selemti tables
        $selemti_analysis = [];
        $this->info('=== ANALIZANDO TABLAS SELEMTI ===');
        $progressBar = $this->output->createProgressBar(count($selemti_tables));
        $progressBar->start();

        foreach ($selemti_tables as $table) {
            $selemti_analysis[$table] = $this->analyzeTable('selemti', $table);
            $progressBar->advance();
        }
        $progressBar->finish();
        $this->newLine(2);

        // Analyze public tables (lighter analysis)
        $public_analysis = [];
        $this->info('=== ANALIZANDO TABLAS PUBLIC (Floreant POS) ===');
        $progressBar = $this->output->createProgressBar(count($public_tables));
        $progressBar->start();

        foreach ($public_tables as $table) {
            $public_analysis[$table] = $this->analyzeTable('public', $table, false);
            $progressBar->advance();
        }
        $progressBar->finish();
        $this->newLine(2);

        // Generate report
        $this->generateReport($selemti_analysis, $public_analysis, $selemti_tables, $public_tables);

        $this->info("\n=== AUDITORÍA COMPLETADA ===");
        $this->info('Reporte generado en: docs/BD/REPORTE_AUDITORIA_DUPLICADOS.md');

        return 0;
    }

    private function getTables(string $schema): array
    {
        $tables = DB::select('
            SELECT tablename
            FROM pg_tables
            WHERE schemaname = ?
            ORDER BY tablename
        ', [$schema]);

        return array_map(fn ($t) => $t->tablename, $tables);
    }

    private function analyzeTable(string $schema, string $table, bool $detailed = true): array
    {
        // Count records
        try {
            $count = DB::select("SELECT COUNT(*) as total FROM {$schema}.\"$table\"")[0]->total;
        } catch (\Exception $e) {
            $count = 'ERROR';
        }

        // Get columns
        $columns = DB::select('
            SELECT column_name, data_type, character_maximum_length, is_nullable
            FROM information_schema.columns
            WHERE table_schema = ? AND table_name = ?
            ORDER BY ordinal_position
        ', [$schema, $table]);

        $analysis = [
            'schema' => $schema,
            'count' => $count,
            'columns' => $columns,
        ];

        if ($detailed) {
            // Get foreign keys
            $fks = DB::select("
                SELECT
                    tc.constraint_name,
                    kcu.column_name,
                    ccu.table_schema AS foreign_table_schema,
                    ccu.table_name AS foreign_table_name,
                    ccu.column_name AS foreign_column_name
                FROM information_schema.table_constraints AS tc
                JOIN information_schema.key_column_usage AS kcu
                    ON tc.constraint_name = kcu.constraint_name
                    AND tc.table_schema = kcu.table_schema
                JOIN information_schema.constraint_column_usage AS ccu
                    ON ccu.constraint_name = tc.constraint_name
                    AND ccu.table_schema = tc.table_schema
                WHERE tc.constraint_type = 'FOREIGN KEY'
                    AND tc.table_schema = ?
                    AND tc.table_name = ?
            ", [$schema, $table]);

            $analysis['fks'] = $fks;
        }

        return $analysis;
    }

    private function generateReport(array $selemti_analysis, array $public_analysis, array $selemti_tables, array $public_tables)
    {
        // Identify duplicate groups
        $duplicate_groups = $this->identifyDuplicateGroups($selemti_analysis, $public_analysis, $selemti_tables, $public_tables);

        // Identify legacy tables
        $legacy_tables = array_filter($selemti_tables, fn ($t) => str_contains($t, '_legacy'));

        // Generate markdown report
        $report = $this->buildMarkdownReport($duplicate_groups, $legacy_tables, $selemti_analysis, $public_analysis);

        // Save report
        $dir = base_path('docs/BD');
        if (! is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        file_put_contents($dir.'/REPORTE_AUDITORIA_DUPLICADOS.md', $report);
    }

    private function identifyDuplicateGroups(array $selemti_analysis, array $public_analysis, array $selemti_tables, array $public_tables): array
    {
        $groups = [];

        // Define known duplicate patterns
        $patterns = [
            'Usuarios' => [
                'public.users' => in_array('users', $public_tables),
                'selemti.users' => in_array('users', $selemti_tables),
                'selemti.usuario' => in_array('usuario', $selemti_tables),
            ],
            'Roles' => [
                'selemti.rol' => in_array('rol', $selemti_tables),
                'selemti.roles' => in_array('roles', $selemti_tables),
            ],
            'Sucursales' => [
                'selemti.sucursal' => in_array('sucursal', $selemti_tables),
                'selemti.cat_sucursales' => in_array('cat_sucursales', $selemti_tables),
            ],
            'Almacenes' => [
                'selemti.almacen' => in_array('almacen', $selemti_tables),
                'selemti.cat_almacenes' => in_array('cat_almacenes', $selemti_tables),
            ],
            'Proveedores' => [
                'selemti.proveedor' => in_array('proveedor', $selemti_tables),
                'selemti.cat_proveedores' => in_array('cat_proveedores', $selemti_tables),
            ],
            'Unidades de Medida' => [
                'selemti.unidad_medida_legacy' => in_array('unidad_medida_legacy', $selemti_tables),
                'selemti.unidades_medida_legacy' => in_array('unidades_medida_legacy', $selemti_tables),
                'selemti.cat_unidades' => in_array('cat_unidades', $selemti_tables),
                'selemti.uom' => in_array('uom', $selemti_tables),
                'selemti.unit_of_measure' => in_array('unit_of_measure', $selemti_tables),
            ],
            'Conversiones de Unidad' => [
                'selemti.conversion_unidad' => in_array('conversion_unidad', $selemti_tables),
                'selemti.conversiones_unidad_legacy' => in_array('conversiones_unidad_legacy', $selemti_tables),
                'selemti.uom_conversion_legacy' => in_array('uom_conversion_legacy', $selemti_tables),
                'selemti.uom_conversions' => in_array('uom_conversions', $selemti_tables),
            ],
            'Recetas' => [
                'selemti.receta' => in_array('receta', $selemti_tables),
                'selemti.receta_cab' => in_array('receta_cab', $selemti_tables),
                'selemti.recipes' => in_array('recipes', $selemti_tables),
            ],
            'Detalle de Recetas' => [
                'selemti.receta_det' => in_array('receta_det', $selemti_tables),
                'selemti.recipe_lines' => in_array('recipe_lines', $selemti_tables),
            ],
            'Órdenes de Producción' => [
                'selemti.orden_produccion' => in_array('orden_produccion', $selemti_tables),
                'selemti.ordenes_produccion' => in_array('ordenes_produccion', $selemti_tables),
                'selemti.production_orders' => in_array('production_orders', $selemti_tables),
            ],
            'Caja Chica / Cash Fund' => [
                'selemti.caja_fondo' => in_array('caja_fondo', $selemti_tables),
                'selemti.cash_funds' => in_array('cash_funds', $selemti_tables),
                'selemti.caja_chica' => in_array('caja_chica', $selemti_tables),
            ],
            'Movimientos de Caja Chica' => [
                'selemti.caja_fondo_movimiento' => in_array('caja_fondo_movimiento', $selemti_tables),
                'selemti.cash_fund_movements' => in_array('cash_fund_movements', $selemti_tables),
            ],
            'Liquidaciones de Caja Chica' => [
                'selemti.caja_fondo_liquidacion' => in_array('caja_fondo_liquidacion', $selemti_tables),
                'selemti.cash_fund_settlements' => in_array('cash_fund_settlements', $selemti_tables),
            ],
            'Transferencias' => [
                'selemti.transferencia' => in_array('transferencia', $selemti_tables),
                'selemti.transferencias' => in_array('transferencias', $selemti_tables),
                'selemti.transfers' => in_array('transfers', $selemti_tables),
            ],
            'Items / Productos' => [
                'selemti.item' => in_array('item', $selemti_tables),
                'selemti.items' => in_array('items', $selemti_tables),
                'selemti.producto' => in_array('producto', $selemti_tables),
            ],
            'Lotes / Batches' => [
                'selemti.lote' => in_array('lote', $selemti_tables),
                'selemti.lotes' => in_array('lotes', $selemti_tables),
                'selemti.batches' => in_array('batches', $selemti_tables),
            ],
        ];

        // Process each group
        foreach ($patterns as $group_name => $tables) {
            $found_tables = [];
            foreach ($tables as $table_full => $exists) {
                if ($exists) {
                    [$schema, $table] = explode('.', $table_full);
                    $analysis = $schema === 'public' ? $public_analysis[$table] : $selemti_analysis[$table];
                    $found_tables[$table_full] = $analysis;
                }
            }

            if (count($found_tables) > 1) {
                $groups[$group_name] = $found_tables;
            }
        }

        return $groups;
    }

    private function buildMarkdownReport(array $duplicate_groups, array $legacy_tables, array $selemti_analysis, array $public_analysis): string
    {
        $report = "# AUDITORÍA DE TABLAS DUPLICADAS Y LEGACY\n\n";
        $report .= '**Fecha**: '.now()->format('d F Y H:i:s')."\n";
        $report .= '**Total Tablas**: '.(count($selemti_analysis) + count($public_analysis))."\n";
        $report .= '  - Selemti: '.count($selemti_analysis)."\n";
        $report .= '  - Public: '.count($public_analysis)."\n\n";

        $report .= "---\n\n";

        // Executive summary
        $report .= "## RESUMEN EJECUTIVO\n\n";
        $report .= '- **Grupos de tablas duplicadas encontrados**: '.count($duplicate_groups)."\n";
        $report .= '- **Tablas legacy (con sufijo _legacy)**: '.count($legacy_tables)."\n";

        // Count legacy tables with data
        $legacy_with_data = 0;
        foreach ($legacy_tables as $table) {
            if ($selemti_analysis[$table]['count'] > 0) {
                $legacy_with_data++;
            }
        }
        $report .= "- **Tablas legacy con datos**: $legacy_with_data\n";
        $report .= '- **Impacto**: '.($legacy_with_data > 0 ? 'ALTO' : 'MEDIO')." - Requiere revisión y limpieza\n\n";

        $report .= "---\n\n";

        // Duplicate groups analysis
        $group_num = 1;
        foreach ($duplicate_groups as $group_name => $tables) {
            $report .= "## $group_num. TABLAS DUPLICADAS - $group_name\n\n";

            $report .= "| Tabla | Registros | Columnas | Tipo | Acción Recomendada |\n";
            $report .= "|-------|-----------|----------|------|--------------------||\n";

            foreach ($tables as $table_full => $analysis) {
                [$schema, $table] = explode('.', $table_full);

                $count = $analysis['count'];
                $col_count = count($analysis['columns']);

                // Determine type and recommendation
                if ($schema === 'public') {
                    $type = 'POS Floreant (Producción)';
                    $recommendation = '✅ MANTENER - NO TOCAR';
                } elseif (str_contains($table, '_legacy')) {
                    $type = 'Legacy';
                    $recommendation = $count > 0 ? '⚠️ MIGRAR DATOS → ELIMINAR' : '❌ ELIMINAR (vacía)';
                } elseif (str_contains($table, 'cat_') || str_contains($table, 's_')) {
                    $type = 'Normalizada (Actual)';
                    $recommendation = '✅ MANTENER - Usar en app';
                } else {
                    $type = 'Legacy/Antigua';
                    $recommendation = $count > 0 ? '⚠️ REVISAR - Tiene datos' : '❌ ELIMINAR (vacía)';
                }

                $report .= "| $table_full | $count | $col_count | $type | $recommendation |\n";
            }

            $report .= "\n**Análisis**:\n\n";

            foreach ($tables as $table_full => $analysis) {
                [$schema, $table] = explode('.', $table_full);
                $count = $analysis['count'];

                $report .= "- **$table_full**: ";

                // Add description
                if ($schema === 'public') {
                    $report .= "Sistema POS Floreant en producción, READ-ONLY, no modificar sin coordinación.\n";
                } elseif (str_contains($table, '_legacy')) {
                    if ($count > 0) {
                        $report .= "Tabla legacy con **$count registros**, requiere migración antes de eliminar.\n";
                    } else {
                        $report .= "Tabla legacy vacía, **SAFE TO DROP**.\n";
                    }
                } elseif (str_contains($table, 'cat_')) {
                    $report .= "Tabla normalizada del catálogo, usar esta versión en la aplicación.\n";
                } else {
                    if ($count > 0) {
                        $report .= "Tabla antigua con **$count registros**, revisar si se está usando.\n";
                    } else {
                        $report .= "Tabla sin datos, candidata para eliminación.\n";
                    }
                }
            }

            // Show dependencies
            $report .= "\n**Dependencias (Foreign Keys)**:\n\n";
            $has_fks = false;

            foreach ($tables as $table_full => $analysis) {
                if (isset($analysis['fks']) && count($analysis['fks']) > 0) {
                    $has_fks = true;
                    [$schema, $table] = explode('.', $table_full);
                    $report .= "- **$table_full**:\n";
                    foreach ($analysis['fks'] as $fk) {
                        $report .= "  - `{$fk->column_name}` → `{$fk->foreign_table_schema}.{$fk->foreign_table_name}({$fk->foreign_column_name})`\n";
                    }
                }
            }

            if (! $has_fks) {
                $report .= "- Sin foreign keys detectadas.\n";
            }

            $report .= "\n**Estructura de columnas**:\n\n";

            foreach ($tables as $table_full => $analysis) {
                [$schema, $table] = explode('.', $table_full);
                $report .= "- **$table_full** (".count($analysis['columns'])." columnas):\n";
                $report .= "  ```\n";
                foreach (array_slice($analysis['columns'], 0, 10) as $col) {
                    $type = $col->data_type;
                    if ($col->character_maximum_length) {
                        $type .= "({$col->character_maximum_length})";
                    }
                    $nullable = $col->is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
                    $report .= "  {$col->column_name} ({$type}) {$nullable}\n";
                }
                if (count($analysis['columns']) > 10) {
                    $report .= '  ... y '.(count($analysis['columns']) - 10)." columnas más\n";
                }
                $report .= "  ```\n";
            }

            $report .= "\n---\n\n";
            $group_num++;
        }

        // Legacy tables section
        $report .= '## '.$group_num.". TABLAS CON SUFIJO _legacy\n\n";
        $report .= "Lista completa de tablas con sufijo `_legacy`:\n\n";
        $report .= "| Tabla | Registros | Acción |\n";
        $report .= "|-------|-----------|--------|\n";

        foreach ($legacy_tables as $table) {
            $count = $selemti_analysis[$table]['count'];
            $action = $count > 0 ? '⚠️ MIGRAR DATOS → ELIMINAR' : '❌ ELIMINAR (vacía)';
            $report .= "| selemti.$table | $count | $action |\n";
        }

        $report .= "\n---\n\n";
        $group_num++;

        // Cleanup plan
        $report .= '## '.$group_num.". PLAN DE LIMPIEZA\n\n";

        $report .= "### FASE 1: Eliminar tablas legacy VACÍAS (Sin datos)\n\n";
        $report .= "**Criterio**: Tablas con sufijo `_legacy` o duplicadas que tienen 0 registros.\n\n";
        $report .= "```sql\n";

        foreach ($legacy_tables as $table) {
            if ($selemti_analysis[$table]['count'] == 0) {
                $report .= "DROP TABLE IF EXISTS selemti.\"$table\" CASCADE;\n";
            }
        }

        // Add empty duplicate tables
        foreach ($duplicate_groups as $group_name => $tables) {
            foreach ($tables as $table_full => $analysis) {
                [$schema, $table] = explode('.', $table_full);
                if ($schema === 'selemti' && $analysis['count'] == 0 && ! str_contains($table, 'cat_') && $schema !== 'public') {
                    $report .= "DROP TABLE IF EXISTS selemti.\"$table\" CASCADE;\n";
                }
            }
        }

        $report .= "```\n\n";

        $report .= "### FASE 2: Migrar datos de tablas legacy CON DATOS\n\n";
        $report .= "**Criterio**: Tablas legacy que tienen registros, migrar a tablas normalizadas.\n\n";
        $report .= "```sql\n";
        $report .= "-- EJEMPLO: Migrar sucursal → cat_sucursales\n";
        $report .= "-- INSERT INTO selemti.cat_sucursales (id, nombre, activo, created_at)\n";
        $report .= "-- SELECT id, nombre, activo, NOW() FROM selemti.sucursal;\n";
        $report .= "-- DROP TABLE selemti.sucursal CASCADE;\n\n";

        foreach ($legacy_tables as $table) {
            if ($selemti_analysis[$table]['count'] > 0) {
                $report .= "-- TODO: Migrar datos de selemti.$table ({$selemti_analysis[$table]['count']} registros)\n";
            }
        }

        $report .= "```\n\n";

        $report .= "### FASE 3: Verificar código antes de eliminar\n\n";
        $report .= "Antes de ejecutar drops, buscar referencias en código:\n\n";
        $report .= "```bash\n";
        $report .= "# Buscar referencias a tablas legacy en código PHP\n";
        foreach (array_slice($legacy_tables, 0, 5) as $table) {
            $report .= "grep -r \"$table\" app/\n";
        }
        $report .= "# ... repetir para todas las tablas a eliminar\n";
        $report .= "```\n\n";

        $report .= "---\n\n";
        $group_num++;

        // Risks
        $report .= '## '.$group_num.". RIESGOS Y VALIDACIONES\n\n";
        $report .= "### Riesgos:\n\n";
        $report .= "1. **Código legacy**: Modelos o queries pueden referenciar tablas antiguas.\n";
        $report .= "2. **Foreign Keys**: CASCADE drops pueden eliminar datos relacionados.\n";
        $report .= "3. **Datos importantes**: Tablas legacy pueden contener datos no migrados.\n";
        $report .= "4. **Coordinación multi-agente**: Gemini, Codex y Claude deben estar alineados.\n\n";

        $report .= "### Validaciones requeridas antes de DROP:\n\n";
        $report .= "1. ✅ Verificar 0 registros en tabla (`SELECT COUNT(*)`)\n";
        $report .= "2. ✅ Buscar referencias en código (`grep -r \"tabla\" app/`)\n";
        $report .= "3. ✅ Verificar foreign keys (`\\d+ tabla` en psql)\n";
        $report .= "4. ✅ Backup completo de base de datos (`pg_dump`)\n";
        $report .= "5. ✅ Coordinar con otros agentes (Gemini, Codex)\n";
        $report .= "6. ✅ Ejecutar en ambiente de desarrollo primero\n\n";

        $report .= "---\n\n";
        $group_num++;

        // Tables to keep
        $report .= '## '.$group_num.". TABLAS A MANTENER (Post-Limpieza)\n\n";
        $report .= "Lista de tablas correctas que deben permanecer:\n\n";

        $report .= "### Catálogos (cat_*):\n";
        foreach (array_keys($selemti_analysis) as $table) {
            if (str_starts_with($table, 'cat_')) {
                $report .= "- ✅ selemti.$table ({$selemti_analysis[$table]['count']} registros)\n";
            }
        }

        $report .= "\n### Operaciones actuales:\n";
        $current_tables = ['items', 'batches', 'mov_inv', 'recepciones', 'recipes', 'recipe_lines',
            'production_orders', 'cash_funds', 'cash_fund_movements', 'purchase_orders'];
        foreach ($current_tables as $table) {
            if (isset($selemti_analysis[$table])) {
                $report .= "- ✅ selemti.$table ({$selemti_analysis[$table]['count']} registros)\n";
            }
        }

        $report .= "\n### Sistema POS (READ-ONLY):\n";
        $report .= "- ✅ public.* (todas las tablas de Floreant POS)\n";

        $report .= "\n---\n\n";

        // Summary statistics
        $report .= "## ESTADÍSTICAS FINALES\n\n";
        $report .= '- **Total tablas selemti**: '.count($selemti_analysis)."\n";
        $report .= '- **Total tablas public**: '.count($public_analysis)."\n";
        $report .= '- **Grupos duplicados**: '.count($duplicate_groups)."\n";
        $report .= '- **Tablas legacy**: '.count($legacy_tables)."\n";

        $empty_legacy = count(array_filter($legacy_tables, fn ($t) => $selemti_analysis[$t]['count'] == 0));
        $report .= "- **Tablas legacy vacías**: $empty_legacy\n";
        $report .= "- **Tablas legacy con datos**: $legacy_with_data\n\n";

        $report .= "---\n\n";
        $report .= "_Reporte generado automáticamente por Laravel Artisan command `db:audit-duplicates`_\n";

        return $report;
    }
}
