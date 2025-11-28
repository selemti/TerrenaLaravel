


<div x-data>
    {{-- Filtros --}}
    <x-card variant="bordered" class="mb-3">
        <div class="row g-2 align-items-end">
            <div class="col-md-4">
                <label class="form-label">Buscar producto / SKU</label>
                <input type="text" class="form-control" placeholder="Ej. 'Leche 1.5L' o 'SKU-0001'" wire:model.live.debounce.400ms="q">
            </div>
            <div class="col-md-2">
                <label class="form-label">Sucursal</label>
                <select class="form-select" wire:model.live="sucursal">
                    <option>Todas</option>
                    <option>PRINCIPAL</option>
                    <option>NORTE</option>
                    <option>SUR</option>
                </select>
            </div>
            <div class="col-md-2">
                <label class="form-label">Categoría</label>
                <select class="form-select" wire:model.live="categoria">
                    <option>Todas</option>
                    <option>Materia Prima</option>
                    <option>Bebidas</option>
                    <option>Panificados</option>
                </select>
            </div>
            <div class="col-md-2">
                <label class="form-label">Caducidad</label>
                <select class="form-select" wire:model.live="estadoCad">
                    <option value="">Todas</option>
                    <option value="<15d">Con caducidad &lt; 15 días</option>
                </select>
            </div>
            <div class="col-md-2 text-end">
                <x-button variant="outline" size="sm" icon="fa-rotate-right" wire:click="$refresh">
                    Filtrar
                </x-button>
            </div>
        </div>
    </x-card>

    {{-- KPIs --}}
    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <x-kpi-card
                icon="fa-boxes-stacked"
                label="Ítems distintos"
                :value="$itemsDistintos"
                helper="Catálogo"
                variant="primary"
            />
        </div>
        <div class="col-md-3">
            <x-kpi-card
                icon="fa-dollar-sign"
                label="Valor inventario"
                :value="'$' . number_format($valorInventario,2)"
                helper="Total valorizado"
                variant="success"
            />
        </div>
        <div class="col-md-3">
            <x-kpi-card
                icon="fa-triangle-exclamation"
                label="Bajo stock"
                :value="$bajoStock"
                helper="Reponer pronto"
                variant="warning"
            />
        </div>
        <div class="col-md-3">
            <x-kpi-card
                icon="fa-hourglass-half"
                label="Caducan &lt; 15 días"
                :value="$porVencer"
                helper="Vigilar lotes"
                variant="danger"
            />
        </div>
    </div>

    {{-- Tabla --}}
    <x-card padding="none">
        <x-slot name="header">
            <div class="d-flex justify-content-between align-items-center">
                <h6 class="mb-0">Catálogo de Items</h6>
                <x-button variant="primary" size="sm" icon="fa-plus" as="a" href="{{ route('inventory.items.new') }}">
                    Nuevo Item
                </x-button>
            </div>
        </x-slot>
        <div class="table-responsive p-3">
            <table class="table table-hover align-middle">
                <thead class="table-light">
                <tr>
                    <th>SKU / Código</th>
                    <th>Categoría</th>
                    <th>Unidad base</th>
                    <th>Tipo</th>
                    <th class="text-end">Precio vigente</th>
                    <th>Proveedor</th>
                    <th>Estado</th>
                    <th class="text-end">Acciones</th>
                </tr>
                </thead>
                <tbody>
                @forelse($rows as $r)
                    <tr>
                        <td>
                            <div class="fw-semibold">{{ $r->sku ?: $r->item_id }}</div>
                            <small class="text-muted d-block">{{ $r->producto }}</small>
                            @if($r->descripcion)
                                <small class="text-muted fst-italic d-block">{{ Str::limit($r->descripcion, 60) }}</small>
                            @endif
                            @if($r->perishable)
                                <x-badge type="warning" pill icon="fa-lemon">Perecedero</x-badge>
                            @endif
                            @if($r->activo)
                                <x-badge type="success" pill>Activo</x-badge>
                            @else
                                <x-badge type="neutral" pill>Inactivo</x-badge>
                            @endif
                        </td>
                        <td>
                            @if($r->categoria_nombre)
                                <x-badge type="info">{{ $r->categoria_nombre }}</x-badge>
                            @else
                                <span class="text-muted">{{ $r->categoria_id ?: '—' }}</span>
                            @endif
                        </td>
                        <td>
                            @if($r->udm_base)
                                <x-badge type="primary">{{ $r->udm_base }}</x-badge>
                                @if($r->udm_base_nombre)
                                    <small class="text-muted d-block">{{ $r->udm_base_nombre }}</small>
                                @endif
                            @else
                                <span class="text-muted">—</span>
                            @endif
                        </td>
                        <td>
                            @if($r->tipo)
                                @php
                                    $tipoColor = $r->tipo === 'MATERIA_PRIMA' ? 'secondary' : ($r->tipo === 'ELABORADO' ? 'info' : 'success');
                                @endphp
                                <x-badge :type="$tipoColor" pill>{{ $r->tipo }}</x-badge>
                            @else
                                <span class="text-muted">—</span>
                            @endif
                        </td>
                        <td class="text-end">
                            @if($r->costo_promedio)
                                <span class="fw-semibold">${{ number_format($r->costo_promedio, 2) }}</span>
                            @else
                                <span class="text-muted">—</span>
                            @endif
                        </td>
                        <td>
                            <span class="text-muted">—</span>
                            {{-- TODO: JOIN con item_vendor para mostrar proveedor principal --}}
                        </td>
                        <td>
                            @if($r->activo)
                                <x-badge type="success" pill icon="fa-circle-check">Activo</x-badge>
                            @else
                                <x-badge type="neutral" pill>Inactivo</x-badge>
                            @endif
                        </td>
                        <td class="text-end">
                            <div class="btn-group btn-group-sm">
                                <button class="btn btn-outline-secondary"
                                        wire:click="openKardex('{{ $r->item_id }}','{{ addslashes($r->producto) }}')"
                                        title="Ver Kardex">
                                    <i class="fa-solid fa-list"></i>
                                </button>
                                <a class="btn btn-outline-primary"
                                   href="{{ route('inventory.items.edit', $r->item_id) }}"
                                   title="Editar">
                                    <i class="fa-regular fa-pen-to-square"></i>
                                </a>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="text-center text-muted py-4">
                            <i class="fa-regular fa-folder-open fa-3x mb-2 d-block"></i>
                            No se encontraron items.
                        </td>
                    </tr>
                @endforelse
                </tbody>
            </table>
            <div class="d-flex justify-content-between align-items-center mt-3">
                <div class="text-muted">
                    Mostrando {{ $rows->count() }} de {{ $rows->total() }} items
                </div>
                <div>
                    {{ $rows->links() }}
                </div>
            </div>
        </div>
    </x-card>

    {{-- Modal Kardex --}}
    <div class="modal fade @if($showKardex) show d-block @endif" tabindex="-1" style="@if(!$showKardex)display:none;@endif" x-data @keydown.escape.window="$wire.showKardex=false">
        <div class="modal-dialog modal-xl">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Kardex – {{ $kardexItemNombre }}</h5>
                    <button type="button" class="btn-close" wire:click="$set('showKardex',false)"></button>
                </div>
                <div class="modal-body table-responsive">
                    <table class="table table-sm">
                        <thead>
                        <tr>
                            <th>Fecha/Hora</th><th>Tipo</th><th>Ref</th>
                            <th class="text-end">Entrada</th>
                            <th class="text-end">Salida</th>
                            <th class="text-end">Saldo</th>
                            <th class="text-end">Costo</th>
                            <th>Notas</th>
                        </tr>
                        </thead>
                        <tbody>
                        @forelse($kardexRows as $k)
                            <tr>
                                <td>{{ $k['ts'] ?? '' }}</td>
                                <td>{{ $k['tipo'] ?? '' }}</td>
                                <td>{{ $k['ref'] ?? '' }}</td>
                                <td class="text-end">{{ number_format($k['entrada'] ?? 0, 2) }}</td>
                                <td class="text-end">{{ number_format($k['salida'] ?? 0, 2) }}</td>
                                <td class="text-end">{{ number_format($k['saldo'] ?? 0, 2) }}</td>
                                <td class="text-end">${{ number_format($k['costo'] ?? 0, 4) }}</td>
                                <td>{{ $k['notas'] ?? '' }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="8" class="text-center text-muted">Sin movimientos</td></tr>
                        @endforelse
                        </tbody>
                    </table>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-secondary" wire:click="$set('showKardex',false)">Cerrar</button>
                </div>
            </div>
        </div>
    </div>

    {{-- Modal Movimiento rápido --}}
    <div class="modal fade @if($showMove) show d-block @endif" tabindex="-1" style="@if(!$showMove)display:none;@endif" x-data @keydown.escape.window="$wire.showMove=false">
        <div class="modal-dialog">
            <form wire:submit.prevent="saveMove" class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Movimiento rápido — {{ $moveItemNombre }}</h5>
                    <button type="button" class="btn-close" wire:click="$set('showMove',false)"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-2">
                        <label class="form-label">Tipo</label>
                        <select class="form-select" wire:model="moveTipo">
                            <option>ENTRADA</option>
                            <option>SALIDA</option>
                            <option>TRANSFERENCIA</option>
                            <option>MERMA</option>
                        </select>
                    </div>
                    <div class="row g-2">
                        <div class="col-7">
                            <label class="form-label">Cantidad</label>
                            <input type="number" step="0.0001" class="form-control" wire:model="moveCantidad">
                        </div>
                        <div class="col-5">
                            <label class="form-label">UDM</label>
                            <input type="text" class="form-control" wire:model="moveUdm">
                        </div>
                    </div>
                    <div class="row g-2 mt-1">
                        <div class="col">
                            <label class="form-label">Sucursal origen</label>
                            <input class="form-control" wire:model="sucOrigen">
                        </div>
                        <div class="col" x-show="$wire.moveTipo==='TRANSFERENCIA'">
                            <label class="form-label">Sucursal destino</label>
                            <input class="form-control" wire:model="sucDestino">
                        </div>
                    </div>
                    <div class="row g-2 mt-1">
                        <div class="col">
                            <label class="form-label">Lote</label>
                            <input class="form-control" wire:model="moveLote" placeholder="Opcional">
                        </div>
                        <div class="col">
                            <label class="form-label">Caducidad</label>
                            <input type="date" class="form-control" wire:model="moveCaducidad">
                        </div>
                    </div>
                    <div class="row g-2 mt-1">
                        <div class="col">
                            <label class="form-label">Costo (opcional)</label>
                            <input type="number" step="0.0001" class="form-control" wire:model="moveCosto">
                        </div>
                    </div>
                    <div class="mt-2">
                        <label class="form-label">Notas</label>
                        <textarea class="form-control" rows="2" wire:model="moveNotas" placeholder="Detalle del movimiento..."></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-secondary" type="button" wire:click="$set('showMove',false)">Cancelar</button>
                    <button class="btn btn-primary" type="submit">Guardar movimiento</button>
                </div>
            </form>
        </div>
    </div>
</div>
