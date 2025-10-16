


<div x-data>
    {{-- Filtros --}}
    <div class="card mb-3">
        <div class="card-body row g-2 align-items-end">
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
                <button class="btn btn-outline-secondary" wire:click="$refresh">Filtrar</button>
            </div>
        </div>
    </div>

    {{-- KPIs --}}
    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="p-3 border rounded">Ítems distintos<br><span class="fs-4 fw-bold">{{ $itemsDistintos }}</span></div>
        </div>
        <div class="col-md-3">
            <div class="p-3 border rounded">Valor inventario<br>
                <span class="fs-4 fw-bold">${{ number_format($valorInventario,2) }}</span></div>
        </div>
        <div class="col-md-3">
            <div class="p-3 border rounded">Bajo stock<br><span class="fs-4 fw-bold">{{ $bajoStock }}</span></div>
        </div>
        <div class="col-md-3">
            <div class="p-3 border rounded">Con caducidad &lt; 15 días<br><span class="fs-4 fw-bold">{{ $porVencer }}</span></div>
        </div>
    </div>

    {{-- Tabla --}}
    <div class="card">
        <div class="card-body table-responsive">
            <table class="table align-middle">
                <thead>
                <tr>
                    <th>SKU</th>
                    <th>Producto</th>
                    <th>UDM base</th>
                    <th class="text-end">Existencia</th>
                    <th class="text-end">Mín</th>
                    <th class="text-end">Máx</th>
                    <th class="text-end">Costo (base)</th>
                    <th>Sucursal</th>
                    <th class="text-end">Acciones</th>
                </tr>
                </thead>
                <tbody>
                @foreach($rows as $r)
                    @php
                        $low = ($r->existencia ?? 0) < ($r->minimo ?? 0);
                    @endphp
                    <tr>
                        <td>{{ $r->sku }}</td>
                        <td>{{ $r->producto }}</td>
                        <td>{{ $r->udm_base }}</td>
                        <td class="text-end {{ $low ? 'text-danger fw-semibold' : '' }}">{{ number_format($r->existencia ?? 0, 2) }}</td>
                        <td class="text-end">{{ number_format($r->minimo ?? 0, 0) }}</td>
                        <td class="text-end">{{ number_format($r->maximo ?? 0, 0) }}</td>
                        <td class="text-end">${{ number_format($r->costo_base ?? 0, 4) }}</td>
                        <td><span class="badge text-bg-secondary">{{ $r->sucursal }}</span></td>
                        <td class="text-end">
                            <div class="btn-group">
                                <button class="btn btn-sm btn-outline-primary"
                                        wire:click="openMove('{{ $r->item_id }}','{{ addslashes($r->producto) }}','{{ $r->udm_base }}')">Mover</button>
                                <button class="btn btn-sm btn-outline-secondary"
                                        wire:click="openKardex('{{ $r->item_id }}','{{ addslashes($r->producto) }}')">Kardex</button>
                                <a class="btn btn-sm btn-outline-dark" href="#">Editar</a>
                            </div>
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
            {{ $rows->links() }}
        </div>
    </div>

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
