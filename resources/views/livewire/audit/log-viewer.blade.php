<div>
    <!-- Filtros -->
    <div class="card shadow-sm mb-3">
        <div class="card-body">
            <h5 class="card-title mb-3">
                <i class="fa-solid fa-filter me-1"></i>
                Filtros de búsqueda
            </h5>
            
            <form wire:submit.prevent="load">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label">Fecha desde</label>
                        <input type="date" class="form-control" wire:model.blur="desde">
                    </div>
                    
                    <div class="col-md-3">
                        <label class="form-label">Fecha hasta</label>
                        <input type="date" class="form-control" wire:model.blur="hasta">
                    </div>
                    
                    <div class="col-md-3">
                        <label class="form-label">Usuario</label>
                        <select class="form-select" wire:model.blur="userId">
                            <option value="">Todos los usuarios</option>
                            @foreach($usersList as $user)
                                <option value="{{ $user['id'] }}">
                                    {{ $user['full_name'] }} ({{ $user['username'] }})
                                </option>
                            @endforeach
                        </select>
                    </div>
                    
                    <div class="col-md-3">
                        <label class="form-label">Módulo</label>
                        <select class="form-select" wire:model.blur="module">
                            <option value="">Todos los módulos</option>
                            @foreach($modulesList as $mod)
                                <option value="{{ $mod }}">{{ ucfirst(str_replace('_', ' ', $mod)) }}</option>
                            @endforeach
                        </select>
                    </div>
                    
                    <div class="col-md-9">
                        <label class="form-label">Texto de búsqueda</label>
                        <input type="text" class="form-control" placeholder="Buscar en acción, entidad, motivo..." wire:model.live.debounce.500ms="search">
                    </div>
                    
                    <div class="col-md-3 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary w-100" wire:loading.attr="disabled">
                            <span wire:loading.remove>
                                <i class="fa-solid fa-magnifying-glass me-1"></i>
                                Filtrar
                            </span>
                            <span wire:loading>
                                <i class="fa-solid fa-spinner fa-spin me-1"></i>
                                Buscando...
                            </span>
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Resultados -->
    <div class="card shadow-sm">
        <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h5 class="card-title mb-0">
                    <i class="fa-solid fa-table-list me-1"></i>
                    Registros de auditoría
                </h5>
                <div class="small text-muted">
                    {{ count($rows) }} registros encontrados
                </div>
            </div>

            <div class="table-responsive">
                <table class="table table-sm table-striped table-hover mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Fecha/Hora</th>
                            <th>Usuario</th>
                            <th>Módulo</th>
                            <th>Acción</th>
                            <th>Entidad</th>
                            <th>Motivo</th>
                            <th>Evidencia</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($rows as $row)
                            <tr>
                                <td class="small">{{ $row['timestamp'] }}</td>
                                <td>
                                    <div class="fw-semibold">{{ $row['username'] }}</div>
                                    <div class="small text-muted">{{ $row['user_full_name'] }}</div>
                                </td>
                                <td>{{ $row['module'] }}</td>
                                <td>
                                    <span class="badge bg-primary">{{ $row['action'] }}</span>
                                </td>
                                <td>{{ $row['entity'] }}</td>
                                <td class="small">{{ $row['reason'] ?? '—' }}</td>
                                <td class="text-center">
                                    @if($row['evidence_url'])
                                        <a href="{{ $row['evidence_url'] }}" target="_blank" class="text-decoration-none">
                                            <i class="fa-solid fa-paperclip"></i>
                                        </a>
                                    @else
                                        <span class="text-muted">—</span>
                                    @endif
                                </td>
                                <td class="text-end">
                                    <button class="btn btn-sm btn-outline-primary" wire:click="selectLog({{ $row['id'] }})">
                                        <i class="fa-solid fa-eye"></i>
                                    </button>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="8" class="text-center text-muted py-4">
                                    <i class="fa-regular fa-circle-question me-1"></i>No se encontraron registros de auditoría con los filtros aplicados.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Offcanvas de detalle -->
    @if($selectedLog)
        <div class="offcanvas offcanvas-end" tabindex="-1" id="logDetailOffcanvas" aria-labelledby="logDetailLabel">
            <div class="offcanvas-header">
                <h5 class="offcanvas-title" id="logDetailLabel">
                    <i class="fa-solid fa-circle-info me-1"></i>
                    Detalle de auditoría
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Cerrar"></button>
            </div>
            <div class="offcanvas-body">
                @if($selectedLog)
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label class="small text-muted mb-1">Fecha/Hora</label>
                            <div class="fw-semibold">{{ $selectedLog['timestamp'] }}</div>
                        </div>
                        <div class="col-md-6">
                            <label class="small text-muted mb-1">Usuario</label>
                            <div class="fw-semibold">
                                {{ $selectedLog['user']['full_name'] ?? '—' }}
                                <span class="small text-muted">({{ $selectedLog['user']['username'] ?? '—' }})</span>
                            </div>
                        </div>
                    </div>

                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label class="small text-muted mb-1">Módulo</label>
                            <div class="fw-semibold">{{ $selectedLog['module'] }}</div>
                        </div>
                        <div class="col-md-6">
                            <label class="small text-muted mb-1">Acción</label>
                            <div>
                                <span class="badge bg-primary">{{ $selectedLog['action'] }}</span>
                            </div>
                        </div>
                    </div>

                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label class="small text-muted mb-1">Entidad afectada</label>
                            <div class="fw-semibold">{{ $selectedLog['entity'] }}</div>
                        </div>
                        <div class="col-md-6">
                            <label class="small text-muted mb-1">ID Entidad</label>
                            <div class="fw-semibold">#{{ $selectedLog['entity_id'] }}</div>
                        </div>
                    </div>

                    <div class="row mb-3">
                        <div class="col-12">
                            <label class="small text-muted mb-1">Motivo</label>
                            <div class="bg-light p-2 rounded">
                                {{ $selectedLog['reason'] ?? '—' }}
                            </div>
                        </div>
                    </div>

                    @if($selectedLog['evidence_url'])
                        <div class="row mb-3">
                            <div class="col-12">
                                <label class="small text-muted mb-1">Evidencia</label>
                                <div>
                                    <a href="{{ $selectedLog['evidence_url'] }}" target="_blank" class="btn btn-sm btn-outline-primary">
                                        <i class="fa-solid fa-paperclip me-1"></i>
                                        Ver evidencia adjunta
                                    </a>
                                </div>
                            </div>
                        </div>
                    @endif

                    @if($selectedLog['payload'] && !empty($selectedLog['payload']))
                        <div class="row">
                            <div class="col-12">
                                <label class="small text-muted mb-1">Datos adicionales (payload)</label>
                                <pre class="small bg-light p-2 rounded overflow-auto" style="max-height: 200px;">{{ json_encode($selectedLog['payload'], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) }}</pre>
                            </div>
                        </div>
                    @endif
                @endif
            </div>
        </div>

        <script>
            document.addEventListener('livewire:init', function () {
                Livewire.on('show-log-detail', function () {
                    var offcanvasElement = document.getElementById('logDetailOffcanvas');
                    var offcanvas = new bootstrap.Offcanvas(offcanvasElement);
                    offcanvas.show();
                });
            });
        </script>
    @endif
</div>