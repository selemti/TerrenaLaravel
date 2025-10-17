@extends('layouts.terrena')
    @include('caja._wizard_modals')
    @include('caja._anulaciones')
@section('title', 'Administración de cajas')

@section('page-title')
    <div class="d-flex align-items-center justify-content-between mb-2">
        <div class="d-flex align-items-center gap-2">
            <h2 class="mb-0"><i class="fa-solid fa-cash-register me-2"></i> Administración de cajas</h2>
        </div>
    </div>
@endsection

@section('content')

    <div class="dashboard-grid">
		<div class="d-flex align-items-center justify-content-between mb-2">
					<div class="d-flex align-items-center gap-2">
						<h2 class="mb-0">Cajas</h2>
						<span class="badge bg-secondary" id="badgeFecha">{{ $date ?? now()->format('Y-m-d') }}</span>
					</div>
					<div class="d-flex align-items-center gap-2">
						<button id="btnRefrescar" class="btn btn-outline-secondary btn-sm">
							<i class="fa-solid fa-rotate"></i> Refrescar
						</button>
						<!-- Botón global para abrir Wizard (opcional; igual habrá botón por fila) -->
					</div>
				</div>

        {{-- Campo oculto para sincronizar fecha con JavaScript --}}
        <input type="hidden" id="filtroFecha" value="{{ $date ?? now()->format('Y-m-d') }}">

        {{-- KPIs --}}
        <div class="row g-3 mb-3">
            <div class="col-6 col-md-3">
                <div class="kpi">
                    <div class="kpi-label">Cajas abiertas</div>
                    <div class="kpi-value" id="kpiAbiertas">{{ $abiertas ?? 0 }}</div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="kpi">
                    <div class="kpi-label">Promedio diferencia</div>
                    <div class="kpi-value" id="kpiDifProm">${{ number_format($difProm ?? 0, 2) }}</div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="kpi">
                    <div class="kpi-label">Precortes hoy</div>
                    <div class="kpi-value" id="kpiPrecortes">{{ $precortes ?? 0 }}</div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="kpi">
                    <div class="kpi-label">Conciliadas hoy</div>
                    <div class="kpi-value" id="kpiConcil">{{ $conciliadas ?? 0 }}</div>
                </div>
            </div>
        </div>

        {{-- Tabla --}}
        <div class="table-responsive shadow-sm rounded bg-white">
            <table class="table table-sm align-middle mb-0" id="tablaCajas">
                <thead class="table-light">
                    <tr>
                        <th>Sucursal</th>
                        <th>Terminal</th>
                        <th>Cajero</th>
                        <th>Asignación</th>
                        <th>Estado</th>
                        <th class="text-end">Precorte</th>
                        <th class="text-end">Ventas POS</th>
                        <th class="text-end">Dif. Efectivo</th>
                        <th style="width:280px">Acciones</th>
                    </tr>
                </thead>
                <tbody id="tbodyCajas">
                    @forelse($cajas ?? [] as $caja)
                        <tr>
                            <td>{{ $caja->location ?? '—' }}</td>
                            <td>{{ $caja->name ?? $caja->id ?? '—' }}</td>
                            <td>{{ $caja->assigned_name ?? '—' }}</td>
                            <td>{{ $date ?? now()->format('Y-m-d') }}</td>
                            <td>
                                @if($caja->skipped_precorte)
                                    <span class="badge bg-danger">Regularizar</span>
                                @elseif($caja->asignada && $caja->activa)
                                    <span class="badge bg-success">Asignada</span>
                                @elseif($caja->asignada && !$caja->activa)
                                    <span class="badge bg-info">En Corte</span>
                                @elseif(!$caja->asignada && $caja->precorte_listo && $caja->sin_postcorte)
                                    <span class="badge bg-warning text-dark">Validación</span>
                                @else
                                    <span class="badge bg-secondary">Cerrada</span>
                                @endif
                            </td>
                            <td class="text-end">{{ number_format($caja->opening_float ?? 0, 2) }}</td>
                            <td class="text-end">0</td> {{-- Placeholder; carga via JS --}}
                            <td class="text-end">0</td>
                            <td class="text-end">
                                <div class="d-flex flex-wrap gap-2">
                                    @if($caja->sesion_id)
                                        <button class="btn btn-sm btn-primary" 
                                                data-caja-action="wizard"
                                                data-store="1"
                                                data-terminal="{{ $caja->id }}"
                                                data-user="{{ $caja->assigned_user }}"
                                                data-bdate="{{ $date ?? now()->format('Y-m-d') }}"
                                                data-opening="{{ $caja->opening_float }}"
                                                data-sesion="{{ $caja->sesion_id }}"
                                                title="Abrir Wizard">
                                            <i class="fa-solid fa-wand-magic-sparkles"></i>
                                        </button>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="9" class="text-center text-secondary py-4">Cargando... o sin datos para {{ $date ?? 'esta fecha' }}.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        {{-- Panel Detalle --}}
        <div class="mt-3" id="panelDetalle" hidden>
            <div class="card">
                <div class="card-body">
                    <div class="d-flex align-items-center justify-content-between">
                        <h5 class="mb-0">Detalle de Caja</h5>
                        <button class="btn btn-light btn-sm" id="btnOcultarDetalle">Ocultar</button>
                    </div>
                    <div id="detalleContenido" class="mt-3"><em>Selecciona una caja…</em></div>
                </div>
            </div>
        </div>
    </div>

    {{-- Partials --}}

@endsection

@push('scripts')



    <script type="module" src="{{ asset('assets/js/caja/main.js') }}"></script>
    {{-- Otros JS: helpers.js, state.js, etc., ya cargados en layout --}}
@endpush