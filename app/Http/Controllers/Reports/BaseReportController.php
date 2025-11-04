<?php

namespace App\Http\Controllers\Reports;

use App\Http\Controllers\Controller;
use App\Traits\Reports\ConfiguresReportConnection;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

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
        $start = $this->parseDate($request, 'start_date');
        $end = $this->parseDate($request, 'end_date');

        // Si end es anterior a start, invertir
        if ($end->lt($start)) {
            [$start, $end] = [$end, $start];
        }

        return [$start, $end];
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
}
