<?php

namespace App\Http\Controllers\Reports;

use App\Http\Controllers\Controller;
use App\Traits\Reports\ConfiguresReportConnection;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
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
}
