<div>
    <div class="container-fluid py-4">
        {{-- Header con Progreso --}}
        <div class="card shadow-sm mb-4 border-primary">
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col-md-6">
                        <h4 class="mb-1">
                            <i class="fa-solid fa-clipboard-check text-primary me-2"></i>
                            Captura de Conteo: <strong class="text-primary">{{ $count->folio }}</strong>
                        </h4>
                        <p class="text-muted mb-0">
                            {{ $count->sucursal_id ?? 'N/A' }} - {{ $count->almacen_id ?? 'N/A' }}
                        </p>
                    </div>
                    <div class="col-md-6">
                        <div class="mb-2">
                            <div class="d-flex justify-content-between mb-1">
                                <small>Progreso: {{ $contados }}/{{ $totalItems }} items</small>
                                <small>{{ number_format($porcentaje, 1) }}%</small>
                            </div>
                            <div class="progress" style="height: 25px;">
                                <div class="progress-bar bg-success"
                                     role="progressbar"
                                     style="width: {{ $porcentaje }}%"
                                     aria-valuenow="{{ $porcentaje }}"
                                     aria-valuemin="0"
                                     aria-valuemax="100">
                                    {{ number_format($porcentaje, 0) }}%
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Filtros --}}
        <div class="card shadow-sm mb-4">
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-md-6">
                        <input type="text"
                               class="form-control"
                               wire:model.live="search"
                               placeholder="Buscar item...">
                    </div>
                    <div class="col-md-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="soloSinContar" wire:model.live="soloSinContar">
                            <label class="form-check-label" for="soloSinContar">
                                Solo sin contar
                            </label>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Tabla de Captura --}}
        <div class="card shadow-sm mb-4">
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Código</th>
                                <th>Item</th>
                                <th>UOM</th>
                                <th class="text-end">Qty Teórica</th>
                                <th class="text-center" width="200">Qty Contada</th>
                                <th class="text-end">Variación</th>
                                <th>Estado</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($lines as $line)
                                <tr>
                                    <td><code>{{ $line->item->codigo }}</code></td>
                                    <td>{{ $line->item->nombre }}</td>
                                    <td><span class="badge bg-light text-dark">{{ $line->uom }}</span></td>
                                    <td class="text-end">
                                        <strong>{{ number_format($line->qty_teorica, 2) }}</strong>
                                    </td>
                                    <td>
                                        <input type="number"
                                               class="form-control form-control-sm text-center"
                                               step="0.01"
                                               value="{{ $contados[$line->id] ?? $line->qty_contada }}"
                                               wire:change="actualizarConteo({{ $line->id }}, $event.target.value)"
                                               wire:model.defer="contados.{{ $line->id }}">
                                    </td>
                                    <td class="text-end">
                                        @php
                                            $variacion = ($contados[$line->id] ?? $line->qty_contada) - $line->qty_teorica;
                                        @endphp
                                        @if(abs($variacion) < 0.001)
                                            <span class="text-success">0.00</span>
                                        @elseif($variacion > 0)
                                            <span class="text-info">+{{ number_format($variacion, 2) }}</span>
                                        @else
                                            <span class="text-warning">{{ number_format($variacion, 2) }}</span>
                                        @endif
                                    </td>
                                    <td>
                                        @if($line->qty_contada > 0)
                                            <i class="fa-solid fa-check-circle text-success"></i>
                                            <span class="text-success small">Contado</span>
                                        @else
                                            <i class="fa-regular fa-circle text-muted"></i>
                                            <span class="text-muted small">Pendiente</span>
                                        @endif
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        {{-- Botones de Acción --}}
        <div class="d-flex justify-content-between">
            <button type="button" class="btn btn-secondary" wire:click="cancelar">
                <i class="fa-solid fa-times me-1"></i>
                Cancelar
            </button>
            <div class="d-flex gap-2">
                <button type="button" class="btn btn-outline-primary" wire:click="guardarYContinuar">
                    <i class="fa-solid fa-save me-1"></i>
                    Guardar
                </button>
                <button type="button" class="btn btn-success" wire:click="finalizarCaptura">
                    <i class="fa-solid fa-arrow-right me-1"></i>
                    Continuar a Revisión
                </button>
            </div>
        </div>
    </div>
</div>
