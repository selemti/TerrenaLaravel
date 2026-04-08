<?php
// Script para agregar método showV2 al controlador
require_once 'vendor/autoload.php';

$file = 'app/Http/Controllers/Reports/SalesModsController.php';
$content = file_get_contents($file);

// Buscar el final de la clase para agregar el método
$pattern = '/^}$/m';
$methodCode = '

    /**
     * Vista mejorada v2.0 para reporte de ítems + modificadores
     */
    public function showV2(Request $request): View
    {
        [$start, $end, $filters] = $this->resolveFilters($request);

        // Forzar vista v2.0
        $filters[\'view\'] = \'item_mod_combos\';
        $view = \'item_mod_combos\';
        $groupByDay = $filters[\'group_by_day\'] ?? false;
        $branches = $filters[\'branch_ids\'] ?? [];
        $terminals = $filters[\'terminal_ids\'] ?? [];
        $includeEmpty = $filters[\'include_empty\'] ?? true;

        // Obtener datos usando el servicio existente
        $dataset = $this->service->fetch($start, $end, $filters);
        $summary = $this->service->summarize($dataset, $view);
        $branchCandidates = $this->extractBranchesFromNewData($dataset);

        $observedBranches = $branchCandidates
            ->pluck(\'key\')
            ->merge($dataset->map(function ($row) {
                if (is_object($row)) {
                    return $row->branch_key ?? $row->branch ?? $row->sucursal ?? null;
                } elseif (is_array($row)) {
                    return $row[\'branch_key\'] ?? $row[\'branch\'] ?? $row[\'sucursal\'] ?? null;
                }
                return null;
            })->filter())
            ->filter()
            ->unique()
            ->sort()
            ->values();

        $branchColors = [];
        $branchLabels = [];

        foreach ($observedBranches as $key => $branchId) {
            if ($branchId !== null) {
                $candidate = $branchCandidates->firstWhere(\'key\', $branchId);
                $branchColors[$branchId] = $candidate ? $candidate[\'color\'] : "#{$branchId}";
                $branchLabels[$branchId] = $candidate ? $candidate[\'label\'] : "Sucursal {$branchId}";
            }
        }

        // Generar colores para cualquier branch que no tenga color asignado
        foreach ($observedBranches as $branchId) {
            if ($branchId !== null && !isset($branchColors[$branchId])) {
                $branchColors[$branchId] = \'#\' . substr(md5($branchId), 0, 6);
                $branchLabels[$branchId] = "Sucursal {$branchId}";
            }
        }

        $branchFilter = $branches;
        $terminalFilter = $terminals;
        $generatedAt = now(\'America/Mexico_City\');

        return view(\'reports.sales.mods_v2\', compact(
            \'startDate\',
            \'endDate\',
            \'view\',
            \'groupByDay\',
            \'includeEmpty\',
            \'rows\',
            \'summary\',
            \'branchFilter\',
            \'branchOptions\',
            \'terminalFilter\',
            \'terminalOptions\',
            \'branchColors\',
            \'branchLabels\',
            \'generatedAt\'
        ));
    }
';

$content = preg_replace($pattern, $methodCode, $content);

// Escribir el archivo modificado
file_put_contents($file, $content);

echo "✅ Método showV2 agregado correctamente\n";
echo "📁 Archivo modificado: {$file}\n";
echo "🔧 Método ready para usar";