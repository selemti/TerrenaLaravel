<?php

namespace App\Services\Caja;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Service for analytics and metrics in the Caja system
 *
 * Provides dashboard KPIs, trends analysis, and insights
 * for cash register operations
 */
class AnalyticsService
{
    /**
     * Get dashboard metrics for a given period
     *
     * Returns:
     * - Total sales (net_sales from vw_sesion_dpr)
     * - Total variance (sum of all differences)
     * - Count of cortes by status
     * - Critical alerts count
     * - Comparison with previous period (% change)
     *
     * @param  string  $fechaInicio  YYYY-MM-DD
     * @param  string  $fechaFin  YYYY-MM-DD
     */
    public function getDashboardMetrics(string $fechaInicio, string $fechaFin): array
    {
        // Calculate previous period dates (same duration)
        $inicio = Carbon::parse($fechaInicio);
        $fin = Carbon::parse($fechaFin);
        $dias = $inicio->diffInDays($fin) + 1; // +1 to include both dates

        $prevInicio = $inicio->copy()->subDays($dias)->format('Y-m-d');
        $prevFin = $inicio->copy()->subDay()->format('Y-m-d');

        // Get current period metrics
        $current = $this->getPeriodMetrics($fechaInicio, $fechaFin);

        // Get previous period metrics for comparison
        $previous = $this->getPeriodMetrics($prevInicio, $prevFin);

        // Calculate percentage changes
        $ventasChange = $this->calculatePercentageChange(
            $previous['total_ventas'],
            $current['total_ventas']
        );

        $diferenciasChange = $this->calculatePercentageChange(
            abs($previous['total_diferencias']),
            abs($current['total_diferencias'])
        );

        return [
            'periodo_actual' => [
                'fecha_inicio' => $fechaInicio,
                'fecha_fin' => $fechaFin,
                'total_ventas' => $current['total_ventas'],
                'total_diferencias' => $current['total_diferencias'],
                'total_cortes' => $current['total_cortes'],
                'cortes_por_estatus' => $current['cortes_por_estatus'],
                'alertas_criticas' => $current['alertas_criticas'],
            ],
            'periodo_anterior' => [
                'fecha_inicio' => $prevInicio,
                'fecha_fin' => $prevFin,
                'total_ventas' => $previous['total_ventas'],
                'total_diferencias' => $previous['total_diferencias'],
            ],
            'variacion' => [
                'ventas_pct' => $ventasChange,
                'diferencias_pct' => $diferenciasChange,
            ],
        ];
    }

    /**
     * Get metrics for a specific period
     */
    protected function getPeriodMetrics(string $fechaInicio, string $fechaFin): array
    {
        // Total sales and cortes count
        $ventasData = DB::connection('pgsql')
            ->table('selemti.sesion_cajon as s')
            ->leftJoin('selemti.vw_sesion_dpr as dpr', 's.id', '=', 'dpr.sesion_id')
            ->whereDate('s.apertura_ts', '>=', $fechaInicio)
            ->whereDate('s.apertura_ts', '<=', $fechaFin)
            ->selectRaw('
                COALESCE(SUM(dpr.net_sales), 0) as total_ventas,
                COUNT(DISTINCT s.id) as total_cortes
            ')
            ->first();

        // Total differences (efectivo + tarjetas + transferencias)
        $diferenciasData = DB::connection('pgsql')
            ->table('selemti.sesion_cajon as s')
            ->join('selemti.postcorte as p', 's.id', '=', 'p.sesion_id')
            ->whereDate('s.apertura_ts', '>=', $fechaInicio)
            ->whereDate('s.apertura_ts', '<=', $fechaFin)
            ->selectRaw('
                COALESCE(SUM(
                    p.diferencia_efectivo +
                    p.diferencia_tarjetas +
                    p.diferencia_transferencias
                ), 0) as total_diferencias
            ')
            ->first();

        // Cortes by status
        $cortesPorEstatus = DB::connection('pgsql')
            ->table('selemti.sesion_cajon as s')
            ->whereDate('s.apertura_ts', '>=', $fechaInicio)
            ->whereDate('s.apertura_ts', '<=', $fechaFin)
            ->select('s.estatus', DB::raw('COUNT(*) as cantidad'))
            ->groupBy('s.estatus')
            ->get()
            ->pluck('cantidad', 'estatus')
            ->toArray();

        // Critical alerts (not approved and abs(diferencia_efectivo) > 500)
        $alertasCriticas = DB::connection('pgsql')
            ->table('selemti.postcorte as p')
            ->join('selemti.sesion_cajon as s', 'p.sesion_id', '=', 's.id')
            ->whereDate('s.apertura_ts', '>=', $fechaInicio)
            ->whereDate('s.apertura_ts', '<=', $fechaFin)
            ->where(function ($query) {
                $query->where('p.requiere_aprobacion', true)
                    ->whereNull('p.aprobado_por')
                    ->where('p.rechazado', false);
            })
            ->orWhereRaw('ABS(p.diferencia_efectivo) > 500')
            ->count();

        return [
            'total_ventas' => (float) ($ventasData->total_ventas ?? 0),
            'total_cortes' => (int) ($ventasData->total_cortes ?? 0),
            'total_diferencias' => (float) ($diferenciasData->total_diferencias ?? 0),
            'cortes_por_estatus' => $cortesPorEstatus,
            'alertas_criticas' => (int) $alertasCriticas,
        ];
    }

    /**
     * Calculate percentage change between two values
     */
    protected function calculatePercentageChange(float $oldValue, float $newValue): float
    {
        if ($oldValue == 0) {
            return $newValue > 0 ? 100.0 : 0.0;
        }

        return round((($newValue - $oldValue) / $oldValue) * 100, 1);
    }

    /**
     * Get list of cajeros (cashiers) who have sessions
     *
     * Used for filter dropdown
     */
    public function getCajerosConSesiones(): array
    {
        $cajeros = DB::connection('pgsql')
            ->table('selemti.sesion_cajon as s')
            ->join('public.users as u', 's.cajero_usuario_id', '=', 'u.auto_id')
            ->select([
                'u.auto_id as usuario_id',
                DB::raw("CONCAT(u.first_name, ' ', u.last_name) as nombre_completo"),
                'u.user_id as codigo_empleado',
                DB::raw('COUNT(DISTINCT s.id) as total_sesiones'),
            ])
            ->groupBy('u.auto_id', 'u.first_name', 'u.last_name', 'u.user_id')
            ->orderBy('nombre_completo')
            ->get()
            ->toArray();

        return $cajeros;
    }

    /**
     * Get insights for a period (trends, anomalies, alerts)
     *
     * Returns:
     * - Peak variance time (day/hour with most differences)
     * - Worst performing terminal
     * - Critical alerts pending
     */
    public function getInsights(string $fechaInicio, string $fechaFin): array
    {
        // Peak variance time (día/hora con mayores diferencias)
        $peakTime = DB::connection('pgsql')
            ->table('selemti.sesion_cajon as s')
            ->join('selemti.postcorte as p', 's.id', '=', 'p.sesion_id')
            ->whereDate('s.apertura_ts', '>=', $fechaInicio)
            ->whereDate('s.apertura_ts', '<=', $fechaFin)
            ->selectRaw('
                EXTRACT(DOW FROM s.apertura_ts) as dia_semana,
                EXTRACT(HOUR FROM s.apertura_ts) as hora,
                AVG(ABS(p.diferencia_efectivo)) as dif_promedio,
                COUNT(*) as num_cortes
            ')
            ->groupBy(DB::raw('EXTRACT(DOW FROM s.apertura_ts)'), DB::raw('EXTRACT(HOUR FROM s.apertura_ts)'))
            ->orderBy('dif_promedio', 'desc')
            ->first();

        // Worst performing terminal (mayor % de error)
        $worstTerminal = DB::connection('pgsql')
            ->table('selemti.sesion_cajon as s')
            ->join('selemti.postcorte as p', 's.id', '=', 'p.sesion_id')
            ->whereDate('s.apertura_ts', '>=', $fechaInicio)
            ->whereDate('s.apertura_ts', '<=', $fechaFin)
            ->where('p.sistema_efectivo_esperado', '>', 0)
            ->selectRaw('
                s.terminal_id,
                s.terminal_nombre,
                AVG(ABS(p.diferencia_efectivo / NULLIF(p.sistema_efectivo_esperado, 0))) * 100 as pct_error,
                COUNT(*) as num_cortes,
                SUM(ABS(p.diferencia_efectivo)) as total_diferencias
            ')
            ->groupBy('s.terminal_id', 's.terminal_nombre')
            ->orderBy('pct_error', 'desc')
            ->first();

        // Critical alerts pending
        $criticalAlerts = DB::connection('pgsql')
            ->table('selemti.postcorte as p')
            ->join('selemti.sesion_cajon as s', 'p.sesion_id', '=', 's.id')
            ->whereDate('s.apertura_ts', '>=', $fechaInicio)
            ->whereDate('s.apertura_ts', '<=', $fechaFin)
            ->where('p.requiere_aprobacion', true)
            ->whereNull('p.aprobado_por')
            ->where('p.rechazado', false)
            ->select([
                'p.id as postcorte_id',
                's.id as sesion_id',
                's.terminal_id',
                'p.diferencia_efectivo',
                'p.motivo_irregular',
                'p.creado_en',
            ])
            ->orderBy('p.creado_en', 'desc')
            ->limit(5)
            ->get()
            ->toArray();

        // Days of week mapping (0 = Domingo, 1 = Lunes, etc.)
        $diasSemana = [
            0 => 'Domingo',
            1 => 'Lunes',
            2 => 'Martes',
            3 => 'Miércoles',
            4 => 'Jueves',
            5 => 'Viernes',
            6 => 'Sábado',
        ];

        return [
            'pico_varianza' => $peakTime ? [
                'dia' => $diasSemana[(int) $peakTime->dia_semana] ?? 'N/A',
                'hora' => (int) $peakTime->hora.':00',
                'diferencia_promedio' => (float) $peakTime->dif_promedio,
                'num_cortes' => (int) $peakTime->num_cortes,
            ] : null,
            'terminal_problematica' => $worstTerminal ? [
                'terminal_id' => (int) $worstTerminal->terminal_id,
                'terminal_nombre' => $worstTerminal->terminal_nombre,
                'porcentaje_error' => (float) $worstTerminal->pct_error,
                'num_cortes' => (int) $worstTerminal->num_cortes,
                'total_diferencias' => (float) $worstTerminal->total_diferencias,
            ] : null,
            'alertas_criticas' => $criticalAlerts,
        ];
    }
}
