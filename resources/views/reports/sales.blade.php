@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Reporte de Ventas',
    'pageTitle' => 'Reporte de Ventas',
])

@section('content')
<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1>Reporte de Ventas</h1>
        <a href="{{ route('reports.dashboard') }}" class="btn btn-outline-primary">
            <i class="fas fa-arrow-left me-1"></i> Volver al Dashboard
        </a>
    </div>

    <div class="card mb-4">
        <div class="card-body">
            <div class="row">
                <div class="col-md-6">
                    <h5 class="card-title">Filtros</h5>
                    <p><strong>Rango de fechas:</strong> {{ $fecha_desde }} - {{ $fecha_hasta }}</p>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title">Detalles de Ventas</h5>
                </div>
                <div class="card-body">
                    <p class="text-muted">Aquí se mostrarán los detalles del reporte de ventas para el rango seleccionado.</p>
                    <p class="text-muted">En una implementación completa, este reporte incluiría:</p>
                    <ul>
                        <li>Ventas detalladas por fecha</li>
                        <li>Productos más vendidos</li>
                        <li>Comparación con período anterior</li>
                        <li>Ventas por categoría de producto</li>
                        <li>Metas vs resultados</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection