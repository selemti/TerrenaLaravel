<div>
    <div class="container-fluid py-4">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h2 class="mb-1">
                    <i class="fa-solid fa-clipboard-list text-warning me-2"></i>
                    Revisión de Conteo: <strong class="text-primary">{{ $count->folio }}</strong>
                </h2>
                <p class="text-muted mb-0">Revise las variaciones antes de generar ajustes</p>
            </div>
        </div>

        {{-- Estadísticas --}}
        <div class="row g-3 mb-4">
            <div class="col-md-2">
                <div class="card shadow-sm text-center">
                    <div class="card-body">
                        <h3 class="mb-0">{{ $totalLineas }}</h3>
                        <small class="text-muted">Total Items</small>
                    </div>
                </div>
            </div>
            <div class="col-md-2">
                <div class="card shadow-sm text-center border-success">
                    <div class="card-body">
                        <h3 class="mb-0 text-success">{{ $exactos }}</h3>
                        <small class="text-muted">Exactos</small>
                    </div>
                </div>
            </div>
            <div class="col-md-2">
                <div class="card shadow-sm text-center border-warning">
                    <div class="card-body">
                        <h3 class="mb-0 text-warning">{{ $conVariacion }}</h3>
                        <small class="text-muted">Con Variación</small>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card shadow-sm text-center border-danger">
                    <div class="card-body">
                        <h3 class="mb-0 text-danger">{{ $faltantes }}</h3>
                        <small class="text-muted">Faltantes</small>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card shadow-sm text-center border-info">
                    <div class="card-body">
                        <h3 class="mb-0 text-info">{{ $sobrantes }}</h3>
                        <small class="text-muted">Sobrantes</small>
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

        {{-- Tabla de Revisión --}}
        <div class="card shadow-sm mb-4">
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
                                    <td>{!! $line->variacion_badge !!}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        {{-- Notas y Confirmación --}}
        <div class="card shadow-sm mb-4">
            <div class="card-header bg-warning text-dark">
                <h5 class="mb-0">Notas del Ajuste</h5>
            </div>
            <div class="card-body">
                <textarea class="form-control" rows="3" wire:model="notas" placeholder="Observaciones sobre el conteo y ajustes..."></textarea>
            </div>
        </div>

        {{-- Botones --}}
        <div class="d-flex justify-content-between">
            <button type="button" class="btn btn-secondary" wire:click="volver">
                <i class="fa-solid fa-arrow-left me-1"></i>
                Volver a Captura
            </button>
            <button type="button" class="btn btn-success btn-lg" wire:click="openConfirmModal">
                <i class="fa-solid fa-check-circle me-1"></i>
                Finalizar y Generar Ajustes
            </button>
        </div>

        {{-- Modal de Confirmación --}}
        @if($showConfirmModal)
            <div class="modal fade show" style="display: block; background: rgba(0,0,0,0.5);" tabindex="-1">
                <div class="modal-dialog modal-dialog-centered">
                    <div class="modal-content">
                        <div class="modal-header bg-warning text-dark">
                            <h5 class="modal-title">Confirmar Finalización</h5>
                            <button type="button" class="btn-close" wire:click="closeConfirmModal"></button>
                        </div>
                        <div class="modal-body">
                            <div class="alert alert-warning">
                                <i class="fa-solid fa-exclamation-triangle me-2"></i>
                                <strong>¿Está seguro?</strong>
                            </div>
                            <p>Esta acción generará <strong>{{ $conVariacion }}</strong> ajustes de inventario y no podrá deshacerse.</p>
                            <ul>
                                <li>{{ $faltantes }} faltantes</li>
                                <li>{{ $sobrantes }} sobrantes</li>
                            </ul>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" wire:click="closeConfirmModal">Cancelar</button>
                            <button type="button" class="btn btn-success" wire:click="finalizarConteo">
                                <i class="fa-solid fa-check me-1"></i>
                                Sí, Finalizar
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        @endif
    </div>
</div>
