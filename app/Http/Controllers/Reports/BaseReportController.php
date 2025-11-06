<?php

namespace App\Http\Controllers\Reports;

use App\Http\Controllers\Controller;
use App\Traits\Reports\ConfiguresReportConnection;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Dompdf\Dompdf;
use Dompdf\Options;

/**
 * Controlador base para todos los reportes
 * Solo lectura, con caching inteligente
 */
abstract class BaseReportController extends Controller
{
    use ConfiguresReportConnection;

    /**
     * Timeout para queries de reportes (segundos)
     */
    protected int $queryTimeout = 30;

    /**
     * TTL del cache (minutos)
     */
    protected int $cacheTTL = 5;

    /**
     * Constructor
     */
    public function __construct()
    {
        $this->middleware('auth:sanctum');
        $this->configureReportConnection();
    }

    /**
     * Parsea fecha de request o usa hoy
     */
    protected function parseDate(Request $request, string $param = 'date'): Carbon
    {
        $dateStr = $request->input($param);
        
        if (!$dateStr) {
            return now()->timezone('America/Mexico_City');
        }

        try {
            return Carbon::parse($dateStr)->timezone('America/Mexico_City');
        } catch (\Exception $e) {
            return now()->timezone('America/Mexico_City');
        }
    }

    /**
     * Parsea rango de fechas
     */
    protected function parseDateRange(Request $request): array
    {
        $startInput = $request->input('start_date');
        $endInput = $request->input('end_date');

        if (!$startInput && !$endInput) {
            $single = $this->parseDate($request);
            $singleDay = $single->copy()->startOfDay();

            return [$singleDay, $singleDay];
        }

        $start = $startInput
            ? Carbon::parse($startInput, 'America/Mexico_City')
            : $this->parseDate($request)->copy();

        $end = $endInput
            ? Carbon::parse($endInput, 'America/Mexico_City')
            : $start->copy();

        if ($end->lt($start)) {
            [$start, $end] = [$end, $start];
        }

        return [$start->startOfDay(), $end->startOfDay()];
    }

    /**
     * Extrae una sucursal desde la request
     */
    protected function parseBranch(Request $request, string $param = 'branch'): ?string
    {
        $branch = trim((string) $request->input($param, ''));
        return $branch !== '' ? strtoupper($branch) : null;
    }

    /**
     * Extrae un filtro genérico en mayúsculas
     */
    protected function parseEnum(Request $request, string $param): ?string
    {
        $value = trim((string) $request->input($param, ''));
        return $value !== '' ? strtoupper($value) : null;
    }

    /**
     * Ejecuta query con timeout
     */
    protected function executeWithTimeout(string $sql, array $bindings = []): array
    {
        DB::connection('pgsql')->statement("SET statement_timeout = '{$this->queryTimeout}s'");
        
        try {
            return DB::connection('pgsql')->select($sql, $bindings);
        } finally {
            DB::connection('pgsql')->statement("SET statement_timeout = 0");
        }
    }

    /**
     * Obtiene datos con cache
     */
    protected function getCached(string $key, \Closure $callback, ?int $ttl = null): mixed
    {
        $ttl = $ttl ?? $this->cacheTTL;
        $tags = $this->getCacheTags();

        if (empty($tags)) {
            return Cache::remember($key, $ttl * 60, $callback);
        }

        return Cache::tags($tags)->remember($key, $ttl * 60, $callback);
    }

    /**
     * Invalida cache de reportes
     */
    protected function flushCache(?array $additionalTags = null): void
    {
        $tags = array_merge($this->getCacheTags(), $additionalTags ?? []);
        
        if (!empty($tags)) {
            Cache::tags($tags)->flush();
        }
    }

    /**
     * Tags de cache para este reporte
     * Override en clases hijas
     */
    protected function getCacheTags(): array
    {
        return ['reports'];
    }

    /**
     * Redondea a 2 decimales
     */
    protected function round(float $value): float
    {
        return round($value, 2);
    }

    /**
     * Formatea moneda
     */
    protected function formatMoney(float $value): string
    {
        return '$' . number_format($this->round($value), 2);
    }

    /**
     * Genera un PDF utilizando Dompdf a partir de una vista Blade
     */
    protected function renderPdf(string $view, array $data, string $filename, string $paper = 'letter', string $orientation = 'portrait', bool $inline = false): Response
    {
        $html = view($view, $data)->render();

        $options = new Options();
        $options->set('isHtml5ParserEnabled', true);
        $options->set('isRemoteEnabled', true);
        $options->setChroot(public_path());

        $dompdf = new Dompdf($options);
        $dompdf->loadHtml($html, 'UTF-8');
        $dompdf->setPaper($paper, $orientation);
        $dompdf->render();

        $disposition = $inline ? 'inline' : 'attachment';

        return response($dompdf->output(), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => sprintf('%s; filename="%s"', $disposition, $filename),
        ]);
    }

    protected function normalizeFilterList(mixed $value, bool $uppercase = true): array
    {
        if (is_array($value)) {
            $items = $value;
        } elseif (is_string($value) && trim($value) !== '') {
            $items = explode(',', $value);
        } else {
            return [];
        }

        return collect($items)
            ->map(fn ($item) => trim((string) $item))
            ->filter()
            ->map(fn ($item) => $uppercase ? strtoupper($item) : $item)
            ->unique()
            ->values()
            ->all();
    }

    protected function prepareBranchColors(array $branchKeys): array
    {
        $configured = collect(config('reports.branch_colors', []))
            ->mapWithKeys(fn ($color, $key) => [strtoupper((string) $key) => $color])
            ->toArray();

        $palette = config('reports.branch_palette', $configured ? [] : null);
        if (empty($palette)) {
            $palette = [
                '#2563eb', '#16a34a', '#f97316', '#0ea5e9', '#f43f5e',
                '#8b5cf6', '#f59e0b', '#22c55e', '#7c3aed', '#ef4444', '#0f172a',
            ];
        }

        $colors = $configured;
        $index = 0;

        foreach ($branchKeys as $key) {
            $upper = strtoupper((string) $key);
            if ($upper === '') {
                continue;
            }

            if (!isset($colors[$upper])) {
                $colors[$upper] = $palette[$index % count($palette)];
                $index++;
            }
        }

        return $colors;
    }

    protected function loadBranchOptions(array $branchColors, array $selected): Collection
    {
        try {
            $rows = DB::connection('pgsql')->select("
                SELECT
                    UPPER(COALESCE(clave, '')) AS key,
                    COALESCE(nombre, UPPER(clave)) AS label
                FROM selemti.cat_sucursales
                ORDER BY nombre
            ");
        } catch (\Throwable $e) {
            $rows = [];
        }

        $options = collect($rows)
            ->map(fn (object $row) => [
                'key' => strtoupper(trim((string) ($row->key ?? ''))),
                'label' => trim((string) ($row->label ?? ($row->key ?? ''))),
            ])
            ->filter(fn (array $opt) => $opt['key'] !== '')
            ->keyBy('key');

        $selectedKeys = collect($selected)
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->values()
            ->all();

        $allKeys = collect($branchColors)->keys()
            ->merge($options->keys())
            ->unique()
            ->values();

        return $allKeys
            ->map(function (string $key) use ($options, $branchColors, $selectedKeys) {
                $base = $options->get($key, [
                    'key' => $key,
                    'label' => $key,
                ]);

                $color = $branchColors[$key] ?? $branchColors[array_key_first($branchColors)] ?? '#2563eb';

                return array_merge($base, [
                    'value' => $key,
                    'color' => $color,
                    'indicator_color' => $color,
                    'selected' => in_array($key, $selectedKeys, true),
                    'badge' => null,
                    'highlight' => false,
                ]);
            })
            ->sortBy(fn (array $opt) => $opt['label'])
            ->values();
    }

    protected function loadTerminalOptions(
        array $branchColors,
        array $branchLabels,
        array $selectedTerminals,
        array $selectedBranches
    ): Collection {
        try {
            $rows = DB::connection('pgsql')->select("
                SELECT
                    CAST(t.id AS text) AS id,
                    COALESCE(NULLIF(t.name, ''), CONCAT('Terminal ', t.id::text)) AS name,
                    UPPER(COALESCE(s.clave, t.location, '')) AS branch_key,
                    COALESCE(s.nombre, t.location, CONCAT('Terminal ', t.id::text)) AS branch_label
                FROM public.terminal t
                LEFT JOIN selemti.cat_sucursales s ON s.pos_location = t.location
                ORDER BY branch_label, t.id
            ");
        } catch (\Throwable $e) {
            $rows = [];
        }

        $selected = collect($selectedTerminals)
            ->map(fn ($value) => trim((string) $value))
            ->filter()
            ->values()
            ->all();

        $selectedBranchSet = collect($selectedBranches)
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->values()
            ->all();

        return collect($rows)
            ->map(function (object $row) use ($branchColors, $branchLabels, $selected, $selectedBranchSet) {
                $branchKey = strtoupper((string) ($row->branch_key ?? ''));
                $label = trim((string) ($row->branch_label ?? ''));
                $color = $branchColors[$branchKey] ?? $branchColors[array_key_first($branchColors)] ?? '#2563eb';
                $badgeLabel = $branchLabels[$branchKey] ?? ($label ?: $branchKey);

                return [
                    'id' => (string) ($row->id ?? ''),
                    'value' => (string) ($row->id ?? ''),
                    'label' => trim(sprintf('%s · %s', (string) ($row->id ?? ''), (string) ($row->name ?? $row->id ?? ''))),
                    'branch_key' => $branchKey,
                    'branch_label' => $badgeLabel,
                    'color' => $color,
                    'indicator_color' => null,
                    'selected' => in_array((string) ($row->id ?? ''), $selected, true),
                    'highlight' => $branchKey && in_array($branchKey, $selectedBranchSet, true),
                    'badge' => [
                        'label' => $badgeLabel,
                        'color' => $color,
                        'text_color' => '#ffffff',
                    ],
                ];
            })
            ->filter(fn (array $opt) => $opt['id'] !== '')
            ->values();
    }

    protected function stringifyFilter(array $values): ?string
    {
        $normalized = collect($values)
            ->map(fn ($value) => trim((string) $value))
            ->filter()
            ->values();

        return $normalized->isEmpty() ? null : $normalized->implode(',');
    }

    protected function buildBranchContext(array $observedKeys, array $selected): array
    {
        $observed = collect($observedKeys)
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->unique()
            ->values();

        $selectedKeys = collect($selected)
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->unique()
            ->values();

        $allKeys = $observed
            ->merge($selectedKeys)
            ->unique()
            ->values()
            ->all();

        $branchColors = $this->prepareBranchColors($allKeys);
        $branchOptions = $this->loadBranchOptions($branchColors, $selectedKeys->all());
        $branchLabels = $branchOptions
            ->keyBy('key')
            ->map(fn (array $opt) => $opt['label'])
            ->toArray();

        return [$branchColors, $branchOptions, $branchLabels];
    }
}
