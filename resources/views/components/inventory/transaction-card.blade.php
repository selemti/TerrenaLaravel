@props([
    'transaction' => null,
    'showHeader' => true,
    'showFooter' => true,
    'headerActions' => null,
    'footerActions' => null,
    'status' => null,
    'type' => null,
])

@php
    $statusConfig = [
        'DRAFT' => ['class' => 'bg-secondary', 'label' => 'Borrador'],
        'PENDING' => ['class' => 'bg-warning', 'label' => 'Pendiente'],
        'APPROVED' => ['class' => 'bg-info', 'label' => 'Aprobado'],
        'COMPLETED' => ['class' => 'bg-success', 'label' => 'Completado'],
        'CANCELLED' => ['class' => 'bg-danger', 'label' => 'Cancelado'],
    ];
    
    $typeConfig = [
        'IN' => ['class' => 'text-success', 'icon' => 'fa fa-arrow-down', 'label' => 'Entrada'],
        'OUT' => ['class' => 'text-danger', 'icon' => 'fa fa-arrow-up', 'label' => 'Salida'],
        'TRANSFER' => ['class' => 'text-primary', 'icon' => 'fa fa-exchange-alt', 'label' => 'Transferencia'],
        'ADJUSTMENT' => ['class' => 'text-warning', 'icon' => 'fa fa-balance-scale', 'label' => 'Ajuste'],
    ];
    
    $statusInfo = $statusConfig[$status ?? $transaction['estado'] ?? 'PENDING'] ?? $statusConfig['PENDING'];
    $typeInfo = $typeConfig[$type ?? $transaction['tipo'] ?? 'IN'] ?? $typeConfig['IN'];
@endphp

<div class="card shadow-sm">
    @if($showHeader)
        <div class="card-header d-flex justify-content-between align-items-center">
            <div>
                <h5 class="card-title mb-0">
                    <i class="{{ $typeInfo['icon'] }} {{ $typeInfo['class'] }} me-2 }}"></i>
                    {{ $transaction['titulo'] ?? $transaction['nombre'] ?? 'Transacción' }}
                    <small class="text-muted d-block mt-1">
                        ID: {{ $transaction['id'] ?? 'N/A' }} | 
                        Fecha: {{ $transaction['fecha'] ?? now()->format('d/m/Y') }}
                    </small>
                </h5>
            </div>
            <div class="d-flex align-items-center gap-2">
                @if($headerActions)
                    <div>{{ $headerActions }}</div>
                @endif
                <span class="badge {{ $statusInfo['class'] }}">{{ $statusInfo['label'] }}</span>
            </div>
        </div>
    @endif
    
    <div class="card-body">
        <div class="row">
            <div class="col-md-6">
                <div class="mb-3">
                    <label class="form-label text-muted">Almacén Origen</label>
                    <p class="mb-0">{{ $transaction['almacen_origen'] ?? 'N/A' }}</p>
                </div>
            </div>
            <div class="col-md-6">
                <div class="mb-3">
                    <label class="form-label text-muted">Almacén Destino</label>
                    <p class="mb-0">{{ $transaction['almacen_destino'] ?? 'N/A' }}</p>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-12">
                <label class="form-label text-muted">Observaciones</label>
                <p class="mb-0">{{ $transaction['observaciones'] ?? 'Sin observaciones' }}</p>
            </div>
        </div>
        
        <hr class="my-4">
        
        <h6 class="mb-3">Líneas de Transacción</h6>
        
        <div class="table-responsive">
            <table class="table table-sm">
                <thead class="table-light">
                    <tr>
                        <th>Ítem</th>
                        <th>Cantidad</th>
                        <th>UOM</th>
                        <th class="text-end">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @if(isset($transaction['lineas']) && count($transaction['lineas']) > 0)
                        @foreach($transaction['lineas'] as $line)
                            <tr>
                                <td>{{ $line['item_nombre'] ?? $line['nombre'] ?? 'N/A' }}</td>
                                <td>{{ $line['cantidad'] ?? '0.00' }}</td>
                                <td>{{ $line['unidad_medida'] ?? 'N/A' }}</td>
                                <td class="text-end">
                                    <button class="btn btn-sm btn-outline-secondary">Acción</button>
                                </td>
                            </tr>
                        @endforeach
                    @else
                        <tr>
                            <td colspan="4" class="text-center text-muted py-3">No hay líneas registradas</td>
                        </tr>
                    @endif
                </tbody>
            </table>
        </div>
    </div>
    
    @if($showFooter)
        <div class="card-footer d-flex justify-content-between">
            @if($footerActions)
                <div>{{ $footerActions }}</div>
            @else
                <div></div>
            @endif
            <div class="text-end">
                <span class="text-muted small">
                    Creado: {{ $transaction['fecha_creacion'] ?? now()->format('d/m/Y H:i') }}
                    @if(!empty($transaction['usuario_creacion']))
                        por {{ $transaction['usuario_creacion'] }}
                    @endif
                </span>
            </div>
        </div>
    @endif
</div>