@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Reportes de ventas',
    'pageTitle' => 'Reportes de ventas',
])

@section('content')
<section class="report-shell">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-chart-line text-primary me-2"></i>
                Centro de reportes de ventas
            </h1>
            <p class="text-muted mb-0">Selecciona el reporte operativo con filtros por rango de fechas, sucursal y severidad.</p>
        </div>
        <a href="{{ route('reports.dashboard') }}" class="btn btn-outline-primary">
            <i class="fa-solid fa-arrow-left me-1"></i> Volver al dashboard
        </a>
    </div>

    <div class="row g-3">
        <div class="col-lg-3 col-md-6">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body d-flex flex-column">
                    <div class="d-flex align-items-center mb-3">
                        <span class="rounded-circle bg-primary bg-opacity-10 p-3 me-3">
                            <i class="fa-solid fa-chart-pie text-primary fa-lg"></i>
                        </span>
                        <h5 class="fw-semibold mb-0">Mix de ventas</h5>
                    </div>
                    <p class="text-muted flex-grow-1">
                        Distribución de ventas por forma de pago con totales por sucursal y acceso directo a modificadores.
                    </p>
                    <a href="{{ route('reports.sales.mix') }}" class="btn btn-primary w-100 mt-2">
                        Abrir reporte
                    </a>
                </div>
            </div>
        </div>

        <div class="col-lg-3 col-md-6">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body d-flex flex-column">
                    <div class="d-flex align-items-center mb-3">
                        <span class="rounded-circle bg-success bg-opacity-10 p-3 me-3">
                            <i class="fa-solid fa-cash-register text-success fa-lg"></i>
                        </span>
                        <h5 class="fw-semibold mb-0">Cajón vs efectivo</h5>
                    </div>
                    <p class="text-muted flex-grow-1">
                        Cruce entre el efectivo esperado por POS y lo registrado en caja con severidades CRITICAL/WARN/INFO.
                    </p>
                    <a href="{{ route('reports.sales.drawer') }}" class="btn btn-primary w-100 mt-2">
                        Abrir reporte
                    </a>
                </div>
            </div>
        </div>

        <div class="col-lg-3 col-md-6">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body d-flex flex-column">
                    <div class="d-flex align-items-center mb-3">
                        <span class="rounded-circle bg-warning bg-opacity-10 p-3 me-3">
                            <i class="fa-solid fa-stethoscope text-warning fa-lg"></i>
                        </span>
                        <h5 class="fw-semibold mb-0">Diagnósticos diarios</h5>
                    </div>
                    <p class="text-muted flex-grow-1">
                        Resumen de vistas operativas con filtros por severidad para identificar anomalías en segundos.
                    </p>
                    <a href="{{ route('reports.sales.diagnostics') }}" class="btn btn-primary w-100 mt-2">
                        Abrir reporte
                    </a>
                </div>
            </div>
        </div>

        <div class="col-lg-3 col-md-6">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body d-flex flex-column">
                    <div class="d-flex align-items-center mb-3">
                        <span class="rounded-circle bg-info bg-opacity-10 p-3 me-3">
                            <i class="fa-solid fa-bowl-food text-info fa-lg"></i>
                        </span>
                        <h5 class="fw-semibold mb-0">Ítems + modificadores</h5>
                    </div>
                    <p class="text-muted flex-grow-1">
                        Ranking de combinaciones artículos/mods con montos adicionales y top extras más vendidos.
                    </p>
                    <a href="{{ route('reports.sales.mods') }}" class="btn btn-primary w-100 mt-2">
                        Abrir reporte
                    </a>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection
