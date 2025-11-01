@php
    use Illuminate\Support\Str;
@endphp

<div>
    <div class="container-fluid py-4">
        <nav aria-label="breadcrumb" class="mb-3">
            <ol class="breadcrumb">
                @foreach($breadcrumbs as $crumb)
                    <li class="breadcrumb-item {{ $loop->last ? 'active' : '' }}" @if($loop->last) aria-current="page" @endif>
                        @if(! $loop->last && $crumb['route'])
                            <a href="{{ $crumb['route'] }}">{{ $crumb['label'] }}</a>
                        @else
                            {{ $crumb['label'] }}
                        @endif
                    </li>
                @endforeach
            </ol>
        </nav>

        <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center mb-4 gap-3">
            <div>
                <h2 class="h4 mb-0">Detalle: {{ Str::headline($type) }}</h2>
                <p class="text-muted mb-0">Vista granular para investigar anomalías o tendencias.</p>
            </div>
            <div class="d-flex gap-2">
                <select class="form-select form-select-sm" style="width: 200px" wire:model.live="filters.dateRange">
                    <option value="today">Hoy</option>
                    <option value="yesterday">Ayer</option>
                    <option value="last_7_days">Últimos 7 días</option>
                    <option value="last_30_days">Últimos 30 días</option>
                    <option value="this_month">Este mes</option>
                    <option value="last_month">Mes anterior</option>
                </select>
                <button class="btn btn-outline-warning btn-sm" wire:click="markFavorite">
                    <i class="fas fa-star me-1"></i> Guardar favorito
                </button>
            </div>
        </div>

        <div class="card shadow-sm">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Concepto</th>
                                <th class="text-end">Valores</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($rows as $row)
                                <tr>
                                    <td>
                                        <strong>{{ $row['label'] ?? '-' }}</strong>
                                        @if(isset($row['estado']))
                                            <span class="badge bg-primary ms-2">{{ $row['estado'] }}</span>
                                        @endif
                                    </td>
                                    <td class="text-end">
                                        @foreach(collect($row)->except('label', 'estado') as $key => $value)
                                            <div class="text-muted small">{{ Str::headline($key) }}: <strong>{{ is_numeric($value) ? number_format($value, 2) : $value }}</strong></div>
                                        @endforeach
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="2" class="text-center py-4 text-muted">No se encontraron datos para el rango seleccionado.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
