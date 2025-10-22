<div class="py-3">
  <div class="d-flex flex-column flex-lg-row align-items-lg-center justify-content-between gap-2 mb-3">
    <div class="d-flex gap-2 w-100 w-lg-50">
      <div class="flex-grow-1">
        <input type="text" class="form-control" placeholder="Buscar por SKU, nombre o descripción"
               wire:model.debounce.400ms="q">
      </div>
      <button class="btn btn-primary" wire:click="openCreate">
        <i class="fa-solid fa-plus me-1"></i>Nuevo ítem
      </button>
    </div>
    <div class="text-muted small d-flex align-items-center gap-2">
      <i class="fa-regular fa-circle-info"></i>
      <span>Recientes: {{ $items->total() }}</span>
    </div>
  </div>

  <div class="card shadow-sm">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th>SKU / Código</th>
            <th>Nombre</th>
            <th>Categoría</th>
            <th>Unidad base</th>
            <th>Tipo</th>
            <th class="text-end">Precio vigente</th>
            <th>Proveedor</th>
            <th>Vigencia</th>
            <th>Estado</th>
            <th class="text-end">Acciones</th>
          </tr>
        </thead>
        <tbody>
        @forelse($items as $row)
          @php
            $unit = $unitsIndex->get($row->unidad_medida_id);
          @endphp
          <tr>
            <td class="font-monospace fw-semibold text-uppercase">
              {{ $row->id }}
              <div class="small text-muted">{{ $row->item_code ?? '—' }}</div>
            </td>
            <td>
              <div class="fw-semibold">{{ $row->nombre }}</div>
              <div class="small text-muted">
                {{ $row->perishable ? 'Perecedero · ' : '' }}{{ $row->activo ? 'Activo' : 'Inactivo' }}
              </div>
            </td>
            <td>{{ $row->categoria_id ?? '—' }}</td>
            <td>{{ $unit['codigo'] ?? '—' }}</td>
            <td>
              <span class="badge text-bg-light">{{ $row->tipo ?? '—' }}</span>
            </td>
            <td class="text-end">
              @if(!is_null($row->preferente_price))
                <div>
                  $ {{ number_format($row->preferente_price, 2) }}
                </div>
                <div class="small text-muted">
                  @if(!is_null($row->preferente_pack_qty) && $row->preferente_pack_uom)
                    {{ rtrim(rtrim(number_format($row->preferente_pack_qty, 2), '0'), '.') }} {{ $row->preferente_pack_uom }}
                  @else
                    Presentación preferente
                  @endif
                </div>
              @else
                —
              @endif
            </td>
            <td>
              @if($row->preferente_vendor)
                <span class="badge text-bg-secondary">Proveedor #{{ $row->preferente_vendor }}</span>
                <div class="small text-muted">{{ $row->preferente_presentacion ?? '' }}</div>
              @else
                <span class="text-muted">—</span>
              @endif
            </td>
            <td>
              @if($row->preferente_effective_from)
                <span class="badge text-bg-light">{{ \Carbon\Carbon::parse($row->preferente_effective_from)->format('Y-m-d') }}</span>
              @else
                <span class="text-muted">—</span>
              @endif
            </td>
            <td>
              <span class="badge {{ $row->activo ? 'text-bg-success' : 'text-bg-secondary' }}">
                {{ $row->activo ? 'Activo' : 'Inactivo' }}
              </span>
            </td>
            <td class="text-end">
              <button class="btn btn-sm btn-outline-primary" wire:click="openEdit('{{ $row->id }}')">
                <i class="fa-solid fa-pen-to-square"></i> Editar
              </button>
            </td>
          </tr>
        @empty
          <tr>
            <td colspan="9" class="text-center text-muted py-4">
              No hay ítems todavía. Usa el botón "Nuevo ítem".
            </td>
          </tr>
        @endforelse
        </tbody>
      </table>
    </div>
    <div class="card-footer">
      {{ $items->links() }}
    </div>
  </div>

  @if($showForm)
    <div class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true">
      <div class="modal-dialog modal-xl modal-dialog-scrollable">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              <i class="fa-solid fa-box-open me-2"></i>
              {{ $isEditing ? 'Editar ítem' : 'Nuevo ítem' }}
            </h5>
            <button type="button" class="btn-close" wire:click="closeForm" aria-label="Cerrar"></button>
          </div>
          <div class="modal-body">
            <div class="row g-3">
              <div class="col-md-4">
                <label class="form-label">SKU / Clave</label>
                <input type="text" class="form-control text-uppercase" wire:model.defer="form.id"
                       placeholder="Ej. INS-0001" {{ $isEditing ? 'disabled' : '' }}>
                @error('form.id') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="col-md-8">
                <label class="form-label">Nombre</label>
                <input type="text" class="form-control" wire:model.defer="form.nombre">
                @error('form.nombre') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="col-md-12">
                <label class="form-label">Descripción</label>
                <textarea class="form-control" rows="2" wire:model.defer="form.descripcion"
                          placeholder="Notas adicionales, especificaciones, etc."></textarea>
                @error('form.descripcion') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>

              <div class="col-md-4">
                <label class="form-label">Categoría</label>
                <input type="text" class="form-control text-uppercase" wire:model.defer="form.categoria_id"
                       placeholder="CAT-GRAL">
                @error('form.categoria_id') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="col-md-4">
                <label class="form-label">Tipo</label>
                <select class="form-select" wire:model.defer="form.tipo">
                  @foreach($tipoOptions as $option)
                    <option value="{{ $option }}">{{ $option }}</option>
                  @endforeach
                </select>
                @error('form.tipo') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="col-md-4">
                <label class="form-label">Estado</label>
                <select class="form-select" wire:model.defer="form.activo">
                  <option value="1">Activo</option>
                  <option value="0">Inactivo</option>
                </select>
              </div>

              <div class="col-md-4">
                <label class="form-label">Unidad base</label>
                <select class="form-select" wire:model.defer="form.unidad_base_id">
                  <option value="">-- Selecciona --</option>
                  @foreach($units as $unit)
                    <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }} · {{ $unit['nombre'] }}</option>
                  @endforeach
                </select>
                @error('form.unidad_base_id') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="col-md-4">
                <label class="form-label">Unidad compra</label>
                <select class="form-select" wire:model.defer="form.unidad_compra_id">
                  <option value="">-- Selecciona --</option>
                  @foreach($units as $unit)
                    <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }} · {{ $unit['nombre'] }}</option>
                  @endforeach
                </select>
                @error('form.unidad_compra_id') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="col-md-4">
                <label class="form-label">Unidad salida</label>
                <select class="form-select" wire:model.defer="form.unidad_salida_id">
                  <option value="">-- Selecciona --</option>
                  @foreach($units as $unit)
                    <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }} · {{ $unit['nombre'] }}</option>
                  @endforeach
                </select>
                @error('form.unidad_salida_id') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>

              <div class="col-md-3">
                <label class="form-label">Factor compra → base</label>
                <input type="number" step="0.0001" class="form-control" wire:model.defer="form.factor_compra">
                @error('form.factor_compra') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="col-md-3">
                <label class="form-label">Factor conversión</label>
                <input type="number" step="0.0001" class="form-control" wire:model.defer="form.factor_conversion">
                @error('form.factor_conversion') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="col-md-3">
                <label class="form-label">Temperatura mínima</label>
                <input type="number" class="form-control" wire:model.defer="form.temperatura_min">
                @error('form.temperatura_min') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="col-md-3">
                <label class="form-label">Temperatura máxima</label>
                <input type="number" class="form-control" wire:model.defer="form.temperatura_max">
                @error('form.temperatura_max') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>

              <div class="col-12">
                <div class="form-check form-switch">
                  <input class="form-check-input" type="checkbox" role="switch" id="perishableSwitch"
                         wire:model.defer="form.perishable">
                  <label class="form-check-label" for="perishableSwitch">Ítem perecedero</label>
                </div>
              </div>

              <div class="col-12">
                <hr>
                <h6 class="fw-bold mb-2">Proveedores y costos</h6>
                <div class="table-responsive">
                  <table class="table table-sm align-middle">
                    <thead class="table-light">
                      <tr>
                        <th>Proveedor</th>
                        <th>Presentación</th>
                        <th>Unidad</th>
                        <th>Factor</th>
                        <th>Costo</th>
                        <th>Moneda</th>
                        <th>Lead time (días)</th>
                        <th>SKU proveedor</th>
                        <th>Preferente</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      @foreach($providers as $index => $provider)
                        <tr>
                          <td style="width: 200px;">
                            <select class="form-select form-select-sm"
                                    wire:model.defer="providers.{{ $index }}.vendor_id">
                              <option value="">-- Selecciona --</option>
                              @foreach($providerOptions as $option)
                                <option value="{{ $option['id'] }}">{{ $option['nombre'] }}</option>
                              @endforeach
                            </select>
                            @error("providers.$index.vendor_id") <div class="text-danger small">{{ $message }}</div> @enderror
                          </td>
                          <td>
                            <input type="text" class="form-control form-control-sm"
                                   wire:model.defer="providers.{{ $index }}.presentacion"
                                   placeholder="Caja 12 x 1L">
                            @error("providers.$index.presentacion") <div class="text-danger small">{{ $message }}</div> @enderror
                          </td>
                          <td style="width: 160px;">
                            <select class="form-select form-select-sm"
                                    wire:model.defer="providers.{{ $index }}.unidad_presentacion_id">
                              <option value="">--</option>
                              @foreach($units as $unit)
                                <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }}</option>
                              @endforeach
                            </select>
                            @error("providers.$index.unidad_presentacion_id") <div class="text-danger small">{{ $message }}</div> @enderror
                          </td>
                          <td style="width: 110px;">
                            <input type="number" step="0.0001" class="form-control form-control-sm text-end"
                                   wire:model.defer="providers.{{ $index }}.factor_a_canonica">
                            @error("providers.$index.factor_a_canonica") <div class="text-danger small">{{ $message }}</div> @enderror
                          </td>
                          <td style="width: 130px;">
                            <div class="input-group input-group-sm">
                              <span class="input-group-text">$</span>
                              <input type="number" step="0.01" class="form-control text-end"
                                     wire:model.defer="providers.{{ $index }}.costo_ultimo">
                            </div>
                            @error("providers.$index.costo_ultimo") <div class="text-danger small">{{ $message }}</div> @enderror
                          </td>
                          <td style="width: 90px;">
                            <select class="form-select form-select-sm"
                                    wire:model.defer="providers.{{ $index }}.moneda">
                              <option value="MXN">MXN</option>
                              <option value="USD">USD</option>
                            </select>
                          </td>
                          <td style="width: 120px;">
                            <input type="number" class="form-control form-control-sm text-end"
                                   wire:model.defer="providers.{{ $index }}.lead_time_dias">
                          </td>
                          <td>
                            <input type="text" class="form-control form-control-sm"
                                   wire:model.defer="providers.{{ $index }}.codigo_proveedor">
                          </td>
                          <td class="text-center">
                            <input class="form-check-input" type="radio" name="preferredVendor"
                                   @checked($provider['preferente'])
                                   wire:click="setPreferred({{ $index }})">
                          </td>
                          <td class="text-end">
                            <button type="button" class="btn btn-sm btn-outline-danger"
                                    wire:click="removeProviderLine({{ $index }})">
                              <i class="fa-solid fa-xmark"></i>
                            </button>
                          </td>
                        </tr>
                      @endforeach
                    </tbody>
                  </table>
                </div>
                <button type="button" class="btn btn-sm btn-outline-primary" wire:click="addProviderLine">
                  <i class="fa-solid fa-plus"></i> Agregar proveedor
                </button>
              </div>

              @if($priceHistory)
                <div class="col-12">
                  <hr>
                  <h6 class="fw-bold mb-2">Historial de costos</h6>
                  <div class="table-responsive">
                    <table class="table table-sm align-middle">
                      <thead class="table-light">
                        <tr>
                          <th>Fecha</th>
                          <th class="text-end">Costo nuevo</th>
                          <th class="text-end">Costo anterior</th>
                          <th>Fuente</th>
                          <th>Versión</th>
                          <th>Usuario</th>
                        </tr>
                      </thead>
                      <tbody>
                        @foreach($priceHistory as $history)
                          <tr>
                            <td>{{ $history['fecha_efectiva'] }}</td>
                            <td class="text-end">$ {{ number_format($history['costo_nuevo'], 2) }}</td>
                            <td class="text-end">
                              {{ $history['costo_anterior'] ? '$ '.number_format($history['costo_anterior'], 2) : '—' }}
                            </td>
                            <td>{{ $history['fuente_datos'] }}</td>
                            <td>{{ $history['version_datos'] }}</td>
                            <td>{{ $history['usuario_id'] ?? '—' }}</td>
                          </tr>
                        @endforeach
                      </tbody>
                    </table>
                  </div>
                </div>
              @endif
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline-secondary" wire:click="closeForm">Cancelar</button>
            <button class="btn btn-success" wire:click="save">
              <i class="fa-solid fa-floppy-disk me-1"></i>Guardar ítem
            </button>
          </div>
        </div>
      </div>
    </div>
    <div class="modal-backdrop fade show"></div>
  @endif
</div>
