@extends('layouts.terrena', ['active' => 'audit'])

@section('title', 'Auditoría Operacional')

@section('content')
<div class="container-fluid">
    <div class="mb-3">
        <h2 class="h4 fw-semibold mb-1">
            <i class="fa-solid fa-clipboard-list me-2"></i>
            <span class="label">Auditoría Operacional</span>
        </h2>
        <p class="text-muted small mb-0">
            Registro de todas las acciones sensibles del sistema para trazabilidad completa.
        </p>
    </div>

    <div class="card shadow-sm">
        <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h5 class="card-title mb-0">
                    <i class="fa-solid fa-table-list me-1"></i>
                    Últimos 100 registros de auditoría
                </h5>
                <div class="small text-muted">
                    {{ now()->format('d/m/Y H:i') }}
                </div>
            </div>

            <div class="table-responsive">
                <table class="table table-sm table-striped table-hover mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Fecha/Hora</th>
                            <th>Usuario</th>
                            <th>Acción</th>
                            <th>Entidad</th>
                            <th>ID Entidad</th>
                            <th>Motivo</th>
                            <th>Evidencia</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($logs as $row)
                            @php
                                // Calcular clase de fila según criterios
                                $trClass = '';
                                if (in_array($row->accion, ['USER_DISABLE', 'USER_ENABLE'])) {
                                    $trClass = 'table-info';
                                } elseif (isset($row->payload_json_decoded['tolerancia_fuera']) && $row->payload_json_decoded['tolerancia_fuera'] === true) {
                                    $trClass = 'table-danger';
                                } elseif (isset($row->payload_json_decoded['requires_investigation']) && $row->payload_json_decoded['requires_investigation'] === true) {
                                    $trClass = 'table-warning';
                                }
                            @endphp
                            <tr class="{{ $trClass }}">
                                <td class="small">{{ $row->timestamp->format('d/m/Y H:i:s') }}</td>
                                <td>
                                    <div class="fw-semibold">{{ $row->user?->username ?? '—' }}</div>
                                    <div class="small text-muted">{{ $row->user?->nombre_completo ?? '—' }}</div>
                                </td>
                                <td>
                                    <span class="badge bg-primary">{{ $row->accion }}</span>
                                </td>
                                <td>{{ $row->entidad ?? '—' }}</td>
                                <td>{{ $row->entidad_id ?? '—' }}</td>
                                <td class="small">{{ $row->motivo ?? '—' }}</td>
                                <td class="text-center">
                                    @if($row->evidencia_url)
                                        <a href="{{ $row->evidencia_url }}" target="_blank" class="btn btn-sm btn-outline-primary">
                                            <i class="fa-solid fa-paperclip"></i>
                                        </a>
                                    @else
                                        <span class="text-muted">—</span>
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="7" class="text-center text-muted py-4">
                                    <i class="fa-regular fa-circle-question me-1"></i>No se encontraron registros de auditoría.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection