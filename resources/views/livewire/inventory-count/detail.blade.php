<div>
    <div class="container-fluid py-4">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h2 class="mb-1">
                    <i class="fa-solid fa-clipboard-check text-success me-2"></i>
                    Detalle del Conteo: <strong>{{ $count->folio }}</strong>
                </h2>
                <p class="text-muted mb-0">{!! $count->estado_badge !!}</p>
            </div>
            <div>
                <button type="button" class="btn btn-outline-primary" wire:click="exportarPDF">
                    <i class="fa-solid fa-file-pdf me-1"></i>
                    PDF
                </button>
                <button type="button" class="btn btn-outline-success" wire:click="exportarExcel">
                    <i class="fa-solid fa-file-excel me-1"></i>
                    Excel
                </button>
                <button type="button" class="btn btn-secondary" wire:click="volver">
                    <i class="fa-solid fa-arrow-left me-1"></i>
                    Volver
                </button>
            </div>
        </div>

        {{-- Información General --}}
        <div class="card shadow-sm mb-4">
            <div class="card-header bg-primary text-white">
                <h5 class="mb-0">Información General</h5>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-3">
                        <p class="mb-1"><small class="text-muted">Folio</small></p>
                        <p class="fw-bold">{{ $count->folio }}</p>
                    </div>
                    <div class="col-md-3">
                        <p class="mb-1"><small class="text-muted">Sucursal</small></p>
                        <p>{{ $count->sucursal_id ?? 'N/A' }}</p>
                    </div>
                    <div class="col-md-3">
                        <p class="mb-1"><small class="text-muted">Almacén</small></p>
                        <p>{{ $count->almacen_id ?? 'N/A' }}</p>
                    </div>
                    <div class="col-md-3">
                        <p class="mb-1"><small class="text-muted">Iniciado</small></p>
                        <p>{{ $count->iniciado_en?->format('d/m/Y H:i') ?? 'N/A' }}</p>
                    </div>
                    <div class="col-md-3">
                        <p class="mb-1"><small class="text-muted">Cerrado</small></p>
                        <p>{{ $count->cerrado_en?->format('d/m/Y H:i') ?? 'N/A' }}</p>
                    </div>
                    <div class="col-md-3">
                        <p class="mb-1"><small class="text-muted">Creado Por</small></p>
                        <p>{{ $count->createdBy?->name ?? 'N/A' }}</p>
                    </div>
                    <div class="col-md-3">
                        <p class="mb-1"><small class="text-muted">Cerrado Por</small></p>
                        <p>{{ $count->closedBy?->name ?? 'N/A' }}</p>
                    </div>
                    <div class="col-md-3">
                        <p class="mb-1"><small class="text-muted">Exactitud</small></p>
                        <p class="fw-bold text-success">{{ number_format($count->porcentaje_exactitud, 1) }}%</p>
                    </div>
                </div>
                @if($count->notas)
                    <div class="mt-3 pt-3 border-top">
                        <p class="mb-1"><small class="text-muted">Notas</small></p>
                        <p>{{ $count->notas }}</p>
                    </div>
                @endif
            </div>
        </div>

        {{-- Estadísticas --}}
        <div class="row g-3 mb-4">
            <div class="col-md-3">
                <div class="card shadow-sm text-center">
                    <div class="card-body">
                        <h3 class="mb-0">{{ $totalLineas }}</h3>
                        <small class="text-muted">Total Items</small>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card shadow-sm text-center border-success">
                    <div class="card-body">
                        <h3 class="mb-0 text-success">{{ $exactos }}</h3>
                        <small class="text-muted">Exactos</small>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card shadow-sm text-center border-warning">
                    <div class="card-body">
                        <h3 class="mb-0 text-warning">{{ $conVariacion }}</h3>
                        <small class="text-muted">Con Variación</small>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card shadow-sm text-center border-info">
                    <div class="card-body">
                        <h4 class="mb-0 text-info">${{ number_format($valorVariacion, 2) }}</h4>
                        <small class="text-muted">Valor Variación</small>
                    </div>
                </div>
            </div>
        </div>

        {{-- Filtros --}}
        <div class="card shadow-sm mb-4">
            <div class="card-body">
                <div class="btn-group" role="group">
                    <input type="radio" class="btn-check" wire:model.live="filterVariacion" value="all" id="all">
                    <label class="btn btn-outline-secondary" for="all">Todos</label>
                    <input type="radio" class="btn-check" wire:model.live="filterVariacion" value="exactos" id="exactos">
                    <label class="btn btn-outline-success" for="exactos">Exactos</label>
                    <input type="radio" class="btn-check" wire:model.live="filterVariacion" value="variacion" id="variacion">
                    <label class="btn btn-outline-warning" for="variacion">Con Variación</label>
                    <input type="radio" class="btn-check" wire:model.live="filterVariacion" value="faltantes" id="faltantes">
                    <label class="btn btn-outline-danger" for="faltantes">Faltantes</label>
                    <input type="radio" class="btn-check" wire:model.live="filterVariacion" value="sobrantes" id="sobrantes">
                    <label class="btn btn-outline-info" for="sobrantes">Sobrantes</label>
                </div>
            </div>
        </div>

        {{-- Tabla de Líneas --}}
        <div class="card shadow-sm">
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Código</th>
                                <th>Item</th>
                                <th>UOM</th>
                                <th class="text-end">Teórica</th>
                                <th class="text-end">Contada</th>
                                <th class="text-end">Variación</th>
                                <th>%</th>
                                <th>Tipo</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($lines as $line)
                                <tr>
                                    <td><code>{{ $line->item->codigo }}</code></td>
                                    <td>{{ $line->item->nombre }}</td>
                                    <td><span class="badge bg-light text-dark">{{ $line->uom }}</span></td>
                                    <td class="text-end">{{ number_format($line->qty_teorica, 2) }}</td>
                                    <td class="text-end"><strong>{{ number_format($line->qty_contada, 2) }}</strong></td>
                                    <td class="text-end">
                                        @if(abs($line->qty_variacion) < 0.001)
                                            <span class="text-success">0.00</span>
                                        @elseif($line->qty_variacion > 0)
                                            <strong class="text-info">+{{ number_format($line->qty_variacion, 2) }}</strong>
                                        @else
                                            <strong class="text-warning">{{ number_format($line->qty_variacion, 2) }}</strong>
                                        @endif
                                    </td>
                                    <td>
                                        @if(abs($line->porcentaje_variacion) < 0.01)
                                            <span class="text-success">0%</span>
                                        @else
                                            <span class="{{ $line->porcentaje_variacion > 0 ? 'text-info' : 'text-warning' }}">
                                                {{ number_format($line->porcentaje_variacion, 1) }}%
                                            </span>
                                        @endif
                                    </td>
                                    <td>{!! $line->variacion_badge !!}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
