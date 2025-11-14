@extends('layouts.terrena')

@section('title', 'Histórico de Cortes')

@section('page-title')
    <div class="d-flex align-items-center justify-content-between mb-2">
        <div class="d-flex align-items-center gap-2">
            <h2 class="mb-0"><i class="fa-solid fa-clock-rotate-left me-2"></i> Histórico de Cortes</h2>
        </div>
    </div>
@endsection

@push('styles')
<style>
    /* Estilos para headers ordenables */
    .table thead th a {
        cursor: pointer;
        user-select: none;
        transition: background-color 0.15s ease-in-out;
        padding: 0.5rem;
        margin: -0.5rem;
        display: flex;
        width: 100%;
    }
    .table thead th a:hover {
        background-color: rgba(0, 0, 0, 0.05);
        border-radius: 0.25rem;
    }
    .table thead th {
        white-space: nowrap;
        position: relative;
    }
</style>
@endpush

@section('content')

<div class="dashboard-grid">
    <div class="mb-3">
        <p class="text-muted mb-0">Consulta el histórico completo de precortes y postcortes</p>
    </div>

    {{-- Banner de retorno cuando viene desde detalle --}}
    @if(isset($returnPath) && $returnPath)
        <div class="alert alert-info alert-dismissible fade show mb-4" role="alert">
            <div class="d-flex align-items-center justify-content-between">
                <div>
                    <i class="fa-solid fa-info-circle me-2"></i>
                    @if(isset($sesionIdForWizard))
                        <strong>Vista filtrada:</strong> Mostrando únicamente la Sesión #{{ $sesionIdForWizard }}
                    @else
                        <strong>Vista desde detalle de sesión</strong>
                    @endif
                </div>
                <div class="d-flex gap-2">
                    <a href="{{ route('caja.' . $returnPath) }}" class="btn btn-sm btn-primary">
                        <i class="fa-solid fa-arrow-left me-1"></i> Volver al Detalle
                    </a>
                    <a href="{{ route('caja.historico') }}" class="btn btn-sm btn-outline-secondary">
                        <i class="fa-solid fa-list me-1"></i> Ver Todos los Cortes
                    </a>
                </div>
            </div>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    @endif

    {{-- Dashboard KPIs --}}
    @if(isset($metrics))
    <div class="row g-3 mb-4">
        {{-- Ventas Totales --}}
        <div class="col-md-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">💰 Ventas Totales</p>
                            <h3 class="mb-0 fw-bold">${{ number_format($metrics['periodo_actual']['total_ventas'], 2) }}</h3>
                        </div>
                        <div class="text-end">
                            @php
                                $ventasChange = $metrics['variacion']['ventas_pct'];
                                $changeClass = $ventasChange > 0 ? 'text-success' : ($ventasChange < 0 ? 'text-danger' : 'text-muted');
                                $changeIcon = $ventasChange > 0 ? '↑' : ($ventasChange < 0 ? '↓' : '=');
                            @endphp
                            <span class="badge {{ $changeClass }} bg-opacity-10">
                                {{ $changeIcon }} {{ abs($ventasChange) }}%
                            </span>
                        </div>
                    </div>
                    <small class="text-muted">vs período anterior</small>
                </div>
            </div>
        </div>

        {{-- Diferencia Total --}}
        <div class="col-md-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">💵 Diferencia Total</p>
                            @php
                                $difTotal = $metrics['periodo_actual']['total_diferencias'];
                                $difClass = abs($difTotal) < 100 ? 'text-success' : ($difTotal < 0 ? 'text-danger' : 'text-warning');
                            @endphp
                            <h3 class="mb-0 fw-bold {{ $difClass }}">${{ number_format(abs($difTotal), 2) }}</h3>
                        </div>
                        <div class="text-end">
                            @php
                                $difChange = $metrics['variacion']['diferencias_pct'];
                                $difChangeClass = $difChange > 0 ? 'text-danger' : 'text-success';
                                $difChangeIcon = $difChange > 0 ? '↑' : '↓';
                            @endphp
                            <span class="badge {{ $difChangeClass }} bg-opacity-10">
                                {{ $difChangeIcon }} {{ abs($difChange) }}%
                            </span>
                        </div>
                    </div>
                    <small class="text-muted">{{ $difTotal < 0 ? 'En contra' : 'A favor' }}</small>
                </div>
            </div>
        </div>

        {{-- Total Cortes --}}
        <div class="col-md-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">📋 Total Cortes</p>
                            <h3 class="mb-0 fw-bold">{{ number_format($metrics['periodo_actual']['total_cortes']) }}</h3>
                        </div>
                        <div>
                            <i class="fa-solid fa-file-invoice fa-2x text-primary opacity-25"></i>
                        </div>
                    </div>
                    <small class="text-muted">
                        @php
                            $estatusCounts = $metrics['periodo_actual']['cortes_por_estatus'];
                            $pendientes = ($estatusCounts['ACTIVA'] ?? 0) + ($estatusCounts['LISTO_PARA_CORTE'] ?? 0) + ($estatusCounts['EN_CORTE'] ?? 0);
                            $cerradas = $estatusCounts['CERRADA'] ?? 0;
                        @endphp
                        {{ $pendientes }} pendientes, {{ $cerradas }} cerradas
                    </small>
                </div>
            </div>
        </div>

        {{-- Alertas Críticas --}}
        <div class="col-md-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">🔴 Alertas Críticas</p>
                            @php
                                $alertas = $metrics['periodo_actual']['alertas_criticas'];
                                $alertClass = $alertas > 0 ? 'text-danger' : 'text-success';
                            @endphp
                            <h3 class="mb-0 fw-bold {{ $alertClass }}">{{ number_format($alertas) }}</h3>
                        </div>
                        <div>
                            <i class="fa-solid fa-triangle-exclamation fa-2x text-danger opacity-25"></i>
                        </div>
                    </div>
                    <small class="text-muted">Requieren aprobación o >$500</small>
                </div>
            </div>
        </div>
    </div>
    @endif

    {{-- Filtros --}}
    <div class="card mb-4">
        <div class="card-header py-2 d-flex justify-content-between align-items-center">
            <strong><i class="fa-solid fa-filter me-2"></i>Filtros de Búsqueda</strong>
            <div class="d-flex align-items-center gap-2">
                <label for="per_page" class="form-label mb-0 small">Mostrar:</label>
                <select class="form-select form-select-sm" id="per_page" name="per_page" style="width: auto;"
                        onchange="this.form.submit()">
                    <option value="10" {{ $filtros['per_page'] == 10 ? 'selected' : '' }}>10</option>
                    <option value="20" {{ $filtros['per_page'] == 20 ? 'selected' : '' }}>20</option>
                    <option value="50" {{ $filtros['per_page'] == 50 ? 'selected' : '' }}>50</option>
                    <option value="100" {{ $filtros['per_page'] == 100 ? 'selected' : '' }}>100</option>
                    <option value="all" {{ $filtros['per_page'] == 'all' ? 'selected' : '' }}>Todos</option>
                </select>
            </div>
        </div>
        <div class="card-body">
            <form method="GET" action="{{ route('caja.historico') }}" id="filterForm" class="row g-3">
                <input type="hidden" name="per_page" value="{{ $filtros['per_page'] }}">
                <input type="hidden" name="sort" value="{{ $filtros['sort'] }}">
                <input type="hidden" name="order" value="{{ $filtros['order'] }}">
                <input type="hidden" name="date_filter" id="date_filter" value="{{ $filtros['date_filter'] }}">

                {{-- Campo de búsqueda global --}}
                <div class="col-md-12 mb-2">
                    <div class="input-group">
                        <span class="input-group-text">
                            <i class="fa-solid fa-search"></i>
                        </span>
                        <input type="text" class="form-control" name="search"
                               placeholder="Buscar por sesión, terminal, cajero..."
                               value="{{ $filtros['search'] ?? '' }}">
                        @if($filtros['search'] ?? false)
                            <a href="{{ route('caja.historico') }}?{{ http_build_query(array_merge($filtros, ['search' => null])) }}"
                               class="btn btn-outline-secondary"
                               title="Limpiar búsqueda">
                                <i class="fa-solid fa-times"></i>
                            </a>
                        @endif
                    </div>
                </div>

                {{-- Filtros rápidos de fecha --}}
                <div class="col-md-12">
                    <label class="form-label">Período:</label>
                    <div class="btn-group w-100" role="group">
                        <input type="radio" class="btn-check" name="date_filter_radio" id="filter_today" value="today"
                               {{ $filtros['date_filter'] == 'today' ? 'checked' : '' }}>
                        <label class="btn btn-outline-primary" for="filter_today">
                            <i class="fa-solid fa-calendar-day"></i> Hoy
                        </label>

                        <input type="radio" class="btn-check" name="date_filter_radio" id="filter_yesterday" value="yesterday"
                               {{ $filtros['date_filter'] == 'yesterday' ? 'checked' : '' }}>
                        <label class="btn btn-outline-primary" for="filter_yesterday">
                            <i class="fa-solid fa-calendar-minus"></i> Ayer
                        </label>

                        <input type="radio" class="btn-check" name="date_filter_radio" id="filter_last_week" value="last_week"
                               {{ $filtros['date_filter'] == 'last_week' ? 'checked' : '' }}>
                        <label class="btn btn-outline-primary" for="filter_last_week">
                            <i class="fa-solid fa-calendar-week"></i> Última Semana
                        </label>

                        <input type="radio" class="btn-check" name="date_filter_radio" id="filter_current_month" value="current_month"
                               {{ $filtros['date_filter'] == 'current_month' ? 'checked' : '' }}>
                        <label class="btn btn-outline-primary" for="filter_current_month">
                            <i class="fa-solid fa-calendar"></i> Mes Actual
                        </label>

                        <input type="radio" class="btn-check" name="date_filter_radio" id="filter_last_month" value="last_month"
                               {{ $filtros['date_filter'] == 'last_month' ? 'checked' : '' }}>
                        <label class="btn btn-outline-primary" for="filter_last_month">
                            <i class="fa-solid fa-calendar-minus"></i> Mes Anterior
                        </label>

                        <input type="radio" class="btn-check" name="date_filter_radio" id="filter_custom" value="custom"
                               {{ $filtros['date_filter'] == 'custom' ? 'checked' : '' }}>
                        <label class="btn btn-outline-primary" for="filter_custom">
                            <i class="fa-solid fa-calendar-range"></i> Personalizado
                        </label>
                    </div>
                </div>

                {{-- Fechas personalizadas (solo visible cuando se selecciona Personalizado) --}}
                <div class="col-md-3" id="custom_dates_container" style="display: {{ $filtros['date_filter'] == 'custom' ? 'block' : 'none' }}">
                    <label for="fecha_inicio" class="form-label">Fecha Inicio</label>
                    <input type="date" class="form-control" id="fecha_inicio" name="fecha_inicio"
                           value="{{ $filtros['fecha_inicio'] }}">
                </div>
                <div class="col-md-3" id="custom_dates_container2" style="display: {{ $filtros['date_filter'] == 'custom' ? 'block' : 'none' }}">
                    <label for="fecha_fin" class="form-label">Fecha Fin</label>
                    <input type="date" class="form-control" id="fecha_fin" name="fecha_fin"
                           value="{{ $filtros['fecha_fin'] }}">
                </div>
                <div class="col-md-2" id="terminal_filter_container">
                    <label for="terminal_id" class="form-label">Terminal</label>
                    <select class="form-select" id="terminal_id" name="terminal_id">
                        <option value="">Todas</option>
                        @foreach($terminales as $terminal)
                            <option value="{{ $terminal->terminal_id }}"
                                    {{ $filtros['terminal_id'] == $terminal->terminal_id ? 'selected' : '' }}>
                                {{ $terminal->terminal_id }} - {{ $terminal->terminal_nombre }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-2" id="estatus_filter_container">
                    <label for="estatus" class="form-label">Estatus</label>
                    <select class="form-select" id="estatus" name="estatus">
                        <option value="">Todos</option>
                        <option value="ACTIVA" {{ $filtros['estatus'] == 'ACTIVA' ? 'selected' : '' }}>Activa</option>
                        <option value="LISTO_PARA_CORTE" {{ $filtros['estatus'] == 'LISTO_PARA_CORTE' ? 'selected' : '' }}>Listo para Corte</option>
                        <option value="EN_CORTE" {{ $filtros['estatus'] == 'EN_CORTE' ? 'selected' : '' }}>En Corte</option>
                        <option value="CERRADA" {{ $filtros['estatus'] == 'CERRADA' ? 'selected' : '' }}>Cerrada</option>
                    </select>
                </div>
                <div class="col-md-2" id="cajero_filter_container">
                    <label for="cajero_usuario_id" class="form-label">Cajero</label>
                    <select class="form-select" id="cajero_usuario_id" name="cajero_usuario_id">
                        <option value="">Todos</option>
                        @foreach($cajeros as $cajero)
                            <option value="{{ $cajero->usuario_id }}"
                                    {{ ($filtros['cajero_usuario_id'] ?? '') == $cajero->usuario_id ? 'selected' : '' }}>
                                {{ $cajero->nombre_completo }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-2 d-flex align-items-end" id="exclude_sundays_container">
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" id="exclude_sundays" name="exclude_sundays"
                               value="1" {{ $filtros['exclude_sundays'] ? 'checked' : '' }}>
                        <label class="form-check-label" for="exclude_sundays">
                            <small>Excluir domingos sin ventas</small>
                        </label>
                    </div>
                </div>
                <div class="col-md-2 d-flex align-items-end">
                    <button type="submit" class="btn btn-primary w-100">
                        <i class="fa-solid fa-search me-1"></i> Aplicar Filtros
                    </button>
                </div>

                {{-- Panel Más Filtros Avanzados --}}
                <div class="col-md-12 mt-3">
                    <button class="btn btn-outline-secondary btn-sm" type="button" data-bs-toggle="collapse" data-bs-target="#filtrosAvanzados" aria-expanded="false" aria-controls="filtrosAvanzados">
                        <i class="fa-solid fa-sliders me-2"></i> Más Filtros
                    </button>
                </div>

                <div class="collapse mt-3" id="filtrosAvanzados">
                    <div class="card card-body bg-light">
                        <div class="row g-3">
                            {{-- Rango de Diferencias --}}
                            <div class="col-md-3">
                                <label for="diferencia_min" class="form-label">Diferencia Mínima ($)</label>
                                <input type="number" step="0.01" class="form-control" id="diferencia_min" name="diferencia_min"
                                       value="{{ $filtros['diferencia_min'] ?? '' }}" placeholder="Ej: -500">
                            </div>
                            <div class="col-md-3">
                                <label for="diferencia_max" class="form-label">Diferencia Máxima ($)</label>
                                <input type="number" step="0.01" class="form-control" id="diferencia_max" name="diferencia_max"
                                       value="{{ $filtros['diferencia_max'] ?? '' }}" placeholder="Ej: 500">
                            </div>

                            {{-- Solo Alertas --}}
                            <div class="col-md-2 d-flex align-items-end">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="solo_alertas" name="solo_alertas"
                                           value="1" {{ ($filtros['solo_alertas'] ?? false) ? 'checked' : '' }}>
                                    <label class="form-check-label" for="solo_alertas">
                                        <small>Solo Alertas Críticas</small>
                                    </label>
                                </div>
                            </div>

                            {{-- Sin Validar --}}
                            <div class="col-md-2 d-flex align-items-end">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="sin_validar" name="sin_validar"
                                           value="1" {{ ($filtros['sin_validar'] ?? false) ? 'checked' : '' }}>
                                    <label class="form-check-label" for="sin_validar">
                                        <small>Sin Validar</small>
                                    </label>
                                </div>
                            </div>

                            {{-- Veredicto Efectivo --}}
                            <div class="col-md-2">
                                <label for="veredicto" class="form-label">Veredicto</label>
                                <select class="form-select" id="veredicto" name="veredicto">
                                    <option value="">Todos</option>
                                    <option value="CUADRA" {{ ($filtros['veredicto'] ?? '') == 'CUADRA' ? 'selected' : '' }}>Cuadra</option>
                                    <option value="A_FAVOR" {{ ($filtros['veredicto'] ?? '') == 'A_FAVOR' ? 'selected' : '' }}>A Favor</option>
                                    <option value="EN_CONTRA" {{ ($filtros['veredicto'] ?? '') == 'EN_CONTRA' ? 'selected' : '' }}>En Contra</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>

            </form>
        </div>
    </div>

    @php
        // Helper function para crear links de ordenamiento
        function sortableLink($column, $label, $currentSort, $currentOrder, $filters) {
            $newOrder = ($currentSort === $column && $currentOrder === 'asc') ? 'desc' : 'asc';
            $icon = '';

            if ($currentSort === $column) {
                $icon = $currentOrder === 'asc'
                    ? '<i class="fa-solid fa-sort-up ms-1"></i>'
                    : '<i class="fa-solid fa-sort-down ms-1"></i>';
            } else {
                $icon = '<i class="fa-solid fa-sort ms-1 text-muted opacity-50"></i>';
            }

            $params = array_merge($filters, ['sort' => $column, 'order' => $newOrder]);
            $url = route('caja.historico') . '?' . http_build_query($params);

            return "<a href='{$url}' class='text-decoration-none text-dark d-flex align-items-center justify-content-between'>{$label} {$icon}</a>";
        }
    @endphp

    <script>
        // Vincular el selector per_page con el formulario
        document.getElementById('per_page').form = document.getElementById('filterForm');

        // Manejar cambios en filtros rápidos de fecha
        document.querySelectorAll('input[name="date_filter_radio"]').forEach(radio => {
            radio.addEventListener('change', function() {
                const dateFilter = this.value;
                document.getElementById('date_filter').value = dateFilter;

                // Mostrar/ocultar campos personalizados
                const customDatesContainer = document.getElementById('custom_dates_container');
                const customDatesContainer2 = document.getElementById('custom_dates_container2');

                if (dateFilter === 'custom') {
                    customDatesContainer.style.display = 'block';
                    customDatesContainer2.style.display = 'block';

                    // Reorganizar columnas para modo personalizado
                    document.getElementById('terminal_filter_container').classList.remove('col-md-2');
                    document.getElementById('terminal_filter_container').classList.add('col-md-3');
                    document.getElementById('estatus_filter_container').classList.remove('col-md-2');
                    document.getElementById('estatus_filter_container').classList.add('col-md-3');
                } else {
                    customDatesContainer.style.display = 'none';
                    customDatesContainer2.style.display = 'none';

                    // Restaurar columnas
                    document.getElementById('terminal_filter_container').classList.remove('col-md-3');
                    document.getElementById('terminal_filter_container').classList.add('col-md-2');
                    document.getElementById('estatus_filter_container').classList.remove('col-md-3');
                    document.getElementById('estatus_filter_container').classList.add('col-md-2');

                    // Auto-enviar formulario cuando se selecciona filtro rápido
                    document.getElementById('filterForm').submit();
                }
            });
        });
    </script>

    {{-- Resultados --}}
    <div class="card">
        <div class="card-header py-2 d-flex justify-content-between align-items-center">
            <strong><i class="fa-solid fa-list me-2"></i>Cortes Registrados</strong>
            <span class="badge bg-primary">Total: {{ $cortes->total() }}</span>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 table-sm">
                    <thead class="table-light">
                        <tr>
                            <th>{!! sortableLink('sesion_id', 'Sesión', $filtros['sort'], $filtros['order'], $filtros) !!}</th>
                            <th>{!! sortableLink('apertura_ts', 'Fecha/Hora', $filtros['sort'], $filtros['order'], $filtros) !!}</th>
                            <th>{!! sortableLink('terminal_id', 'Terminal', $filtros['sort'], $filtros['order'], $filtros) !!}</th>
                            <th>{!! sortableLink('cajero_nombre', 'Cajero', $filtros['sort'], $filtros['order'], $filtros) !!}</th>
                            <th class="text-center">{!! sortableLink('estatus', 'Estatus', $filtros['sort'], $filtros['order'], $filtros) !!}</th>
                            <th class="text-end">{!! sortableLink('cantidad_tickets', 'Tickets', $filtros['sort'], $filtros['order'], $filtros) !!}</th>
                            <th class="text-end">{!! sortableLink('total_ventas', 'Total Ventas', $filtros['sort'], $filtros['order'], $filtros) !!}</th>
                            <th class="text-end">{!! sortableLink('sistema_efectivo', 'Sistema', $filtros['sort'], $filtros['order'], $filtros) !!}</th>
                            <th class="text-end">{!! sortableLink('declarado_efectivo', 'Declarado', $filtros['sort'], $filtros['order'], $filtros) !!}</th>
                            <th class="text-end">{!! sortableLink('diferencia_efectivo', 'Diferencia', $filtros['sort'], $filtros['order'], $filtros) !!}</th>
                            <th class="text-center">Validación</th>
                            <th class="text-center">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($cortes as $corte)
                            <tr>
                                <td><strong>#{{ $corte->sesion_id }}</strong></td>
                                <td>
                                    <div>{{ \Carbon\Carbon::parse($corte->apertura_ts)->format('d/m/Y') }}</div>
                                    <small class="text-muted">
                                        {{ \Carbon\Carbon::parse($corte->apertura_ts)->format('H:i') }}
                                        @if($corte->cierre_ts)
                                            - {{ \Carbon\Carbon::parse($corte->cierre_ts)->format('H:i') }}
                                        @endif
                                    </small>
                                </td>
                                <td>
                                    <div><strong>{{ $corte->terminal_id }}</strong></div>
                                    <small class="text-muted">{{ $corte->terminal_nombre }}</small>
                                </td>
                                <td>
                                    <div>{{ $corte->cajero_nombre ?? 'N/A' }}</div>
                                    <small class="text-muted">ID: {{ $corte->cajero_user_id ?? '-' }}</small>
                                </td>
                                <td class="text-center">
                                    @php
                                        $statusClass = match($corte->estatus) {
                                            'ACTIVA' => 'success',
                                            'LISTO_PARA_CORTE' => 'warning',
                                            'EN_CORTE' => 'info',
                                            'CERRADA' => 'secondary',
                                            default => 'light'
                                        };
                                    @endphp
                                    <span class="badge bg-{{ $statusClass }}">{{ $corte->estatus }}</span>
                                </td>
                                {{-- Cantidad de Tickets --}}
                                <td class="text-end">
                                    @if($corte->cantidad_tickets)
                                        <span class="badge bg-info">{{ number_format($corte->cantidad_tickets) }}</span>
                                    @else
                                        <span class="text-muted">-</span>
                                    @endif
                                </td>
                                {{-- Total Ventas --}}
                                <td class="text-end">
                                    @if($corte->total_ventas)
                                        <strong>${{ number_format($corte->total_ventas, 2) }}</strong>
                                    @else
                                        <span class="text-muted">-</span>
                                    @endif
                                </td>
                                {{-- Sistema (Efectivo) --}}
                                <td class="text-end">
                                    @if($corte->sistema_efectivo_esperado)
                                        ${{ number_format($corte->sistema_efectivo_esperado, 2) }}
                                    @elseif($corte->sistema_efectivo)
                                        ${{ number_format($corte->sistema_efectivo, 2) }}
                                    @else
                                        <span class="text-muted">-</span>
                                    @endif
                                </td>
                                {{-- Declarado (Efectivo) --}}
                                <td class="text-end">
                                    @if($corte->declarado_efectivo)
                                        ${{ number_format($corte->declarado_efectivo, 2) }}
                                    @elseif($corte->precorte_declarado)
                                        ${{ number_format($corte->precorte_declarado, 2) }}
                                    @else
                                        <span class="text-muted">-</span>
                                    @endif
                                </td>
                                {{-- Diferencia (Efectivo) --}}
                                <td class="text-end">
                                    @if($corte->diferencia_efectivo !== null)
                                        @php
                                            $difClass = $corte->diferencia_efectivo == 0 ? 'success' :
                                                       ($corte->diferencia_efectivo > 0 ? 'primary' : 'danger');
                                        @endphp
                                        <span class="badge bg-{{ $difClass }}">
                                            ${{ number_format($corte->diferencia_efectivo, 2) }}
                                        </span>
                                        @if($corte->veredicto_efectivo)
                                            <div><small class="text-muted">{{ $corte->veredicto_efectivo }}</small></div>
                                        @endif
                                    @else
                                        <span class="text-muted">-</span>
                                    @endif
                                </td>
                                {{-- Estado de Validación --}}
                                <td class="text-center">
                                    @if($corte->postcorte_id)
                                        @if($corte->validado)
                                            <span class="badge bg-success"
                                                  data-bs-toggle="tooltip"
                                                  title="Validado el {{ \Carbon\Carbon::parse($corte->validado_en)->format('d/m/Y H:i') }}">
                                                <i class="fa-solid fa-check-double"></i> Validado
                                            </span>
                                        @else
                                            <span class="badge bg-warning"
                                                  data-bs-toggle="tooltip"
                                                  title="Pendiente validación">
                                                <i class="fa-solid fa-clock"></i> Pendiente
                                            </span>
                                        @endif
                                    @else
                                        <span class="badge bg-secondary">Sin postcorte</span>
                                    @endif
                                </td>
                                {{-- Acciones --}}
                                <td class="text-center">
                                    <a href="{{ route('caja.historico.detalle', $corte->sesion_id) }}"
                                       class="btn btn-sm btn-outline-primary"
                                       data-bs-toggle="tooltip"
                                       title="Ver Detalle Completo">
                                        <i class="fa-solid fa-eye"></i>
                                    </a>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="12" class="text-center py-4 text-muted">
                                    <i class="fa-solid fa-inbox fa-3x mb-3 d-block"></i>
                                    No se encontraron cortes con los filtros seleccionados
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
        @if($cortes->hasPages())
            <div class="card-footer d-flex justify-content-between align-items-center">
                <div class="text-muted small">
                    Mostrando {{ $cortes->firstItem() }} a {{ $cortes->lastItem() }} de {{ $cortes->total() }} resultados
                </div>
                <div>
                    {{ $cortes->links('pagination::bootstrap-5') }}
                </div>
            </div>
        @endif
    </div>
</div>

@endsection

@push('scripts')
<script>
    // Auto-abrir wizard cuando viene el parámetro auto_open
    document.addEventListener('DOMContentLoaded', function() {
        @if(isset($autoOpen) && $autoOpen === 'wizard' && isset($sesionIdForWizard))
            // Esperar un momento para que la tabla cargue
            setTimeout(function() {
                // Buscar el botón del wizard para esta sesión
                const wizardBtn = document.querySelector('[data-caja-action="wizard"][data-sesion-id="{{ $sesionIdForWizard }}"]');

                if (wizardBtn) {
                    console.log('Auto-abriendo wizard para sesión #{{ $sesionIdForWizard }}');
                    wizardBtn.click();
                } else {
                    console.warn('No se encontró botón de wizard para sesión #{{ $sesionIdForWizard }}');
                }
            }, 500);
        @endif
    });
</script>
@endpush
