<div class="py-3">
    {{-- Header con búsqueda --}}
    <div class="d-flex flex-column flex-lg-row align-items-lg-center justify-content-between gap-2 mb-3">
        <div class="d-flex gap-2 w-100 w-lg-50">
            <div class="flex-grow-1">
                <input type="text" class="form-control" placeholder="Buscar por sucursal, #fondo o usuario"
                       wire:model.live.debounce.400ms="search">
            </div>
            <a href="{{ route('cashfund.open') }}" class="btn btn-success">
                <i class="fa-solid fa-plus me-1"></i>Abrir fondo
            </a>
            @can('approve-cash-funds')
                <a href="{{ route('cashfund.approvals') }}" class="btn btn-warning">
                    <i class="fa-solid fa-check-double me-1"></i>Aprobaciones
                </a>
            @endcan
        </div>
        <div class="text-muted small d-flex align-items-center gap-2">
            <i class="fa-regular fa-circle-info"></i>
            <span>{{ count($fondos) }} fondo(s)</span>
        </div>
    </div>

    {{-- Filtros --}}
    <div class="card shadow-sm mb-3">
        <div class="card-body">
            <div class="row g-3 align-items-end">
                <div class="col-md-4">
                    <label class="form-label">Estado</label>
                    <select class="form-select" wire:model.live="estadoFilter">
                        <option value="all">Todos</option>
                        <option value="abierto">Abiertos</option>
                        <option value="en_revision">En revisión</option>
                        <option value="cerrado">Cerrados</option>
                    </select>
                </div>
            </div>
        </div>
    </div>

    {{-- Tabla de fondos --}}
    <div class="card shadow-sm">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>#Fondo</th>
                        <th>Sucursal</th>
                        <th>Fecha</th>
                        <th>Responsable</th>
                        <th class="text-end">Monto Inicial</th>
                        <th class="text-end">Egresos</th>
                        <th class="text-end">Disponible</th>
                        <th>Estado</th>
                        <th class="text-end">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($fondos as $fondo)
                        <tr>
                            <td class="font-monospace fw-semibold">
                                #{{ $fondo['id'] }}
                                @if($fondo['descripcion'])
                                    <div class="small text-muted fw-normal">{{ $fondo['descripcion'] }}</div>
                                @endif
                            </td>
                            <td>{{ $fondo['sucursal_nombre'] }}</td>
                            <td>{{ \Carbon\Carbon::parse($fondo['fecha'])->format('d/m/Y') }}</td>
                            <td class="small">
                                <i class="fa-solid fa-user me-1 text-muted"></i>{{ $fondo['responsable'] }}
                            </td>
                            <td class="text-end">${{ number_format($fondo['monto_inicial'], 2) }}</td>
                            <td class="text-end text-danger">${{ number_format($fondo['total_egresos'], 2) }}</td>
                            <td class="text-end fw-bold {{ $fondo['saldo_disponible'] < 0 ? 'text-danger' : 'text-success' }}">
                                ${{ number_format($fondo['saldo_disponible'], 2) }}
                            </td>
                            <td>
                                @if($fondo['estado'] === 'ABIERTO')
                                    <span class="badge text-bg-success"><i class="fa-solid fa-unlock me-1"></i>ABIERTO</span>
                                @elseif($fondo['estado'] === 'EN_REVISION')
                                    <span class="badge text-bg-warning"><i class="fa-solid fa-eye me-1"></i>EN REVISIÓN</span>
                                @else
                                    <span class="badge text-bg-secondary"><i class="fa-solid fa-lock me-1"></i>CERRADO</span>
                                @endif
                            </td>
                            <td class="text-end">
                                @if($fondo['estado'] === 'ABIERTO')
                                    <a href="{{ route('cashfund.movements', ['id' => $fondo['id']]) }}"
                                       class="btn btn-sm btn-outline-primary"
                                       title="Gestionar movimientos">
                                        <i class="fa-solid fa-edit"></i> Gestionar
                                    </a>
                                @elseif($fondo['estado'] === 'EN_REVISION')
                                    <a href="{{ route('cashfund.movements', ['id' => $fondo['id']]) }}"
                                       class="btn btn-sm btn-outline-warning"
                                       title="Ver movimientos (solo lectura)">
                                        <i class="fa-solid fa-eye"></i> Ver
                                    </a>
                                @else
                                    {{-- CERRADO --}}
                                    <a href="{{ route('cashfund.detail', ['id' => $fondo['id']]) }}"
                                       class="btn btn-sm btn-outline-secondary"
                                       title="Ver detalle completo">
                                        <i class="fa-solid fa-file-lines"></i> Detalle
                                    </a>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="9" class="text-center text-muted py-4">
                                No hay fondos registrados. Usa el botón "Abrir fondo".
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    {{-- Info de ayuda --}}
    <div class="alert alert-info mt-3 d-flex align-items-start">
        <i class="fa-solid fa-circle-info mt-1 me-2"></i>
        <div class="small">
            <strong>Caja Chica:</strong> Es el fondo diario asignado para cubrir gastos menores y pagos a proveedores.
            Es <strong>independiente</strong> del efectivo de ventas (cortes de caja POS).
            Al final del día se debe realizar el arqueo y cierre del fondo.
        </div>
    </div>
</div>
