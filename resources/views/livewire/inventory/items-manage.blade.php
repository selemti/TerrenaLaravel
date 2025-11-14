<div class="py-3">
  <div class="d-flex flex-column flex-lg-row align-items-lg-center justify-content-between gap-2 mb-3">
    <div class="d-flex gap-2 w-100 w-lg-50">
      <div class="flex-grow-1">
        <input type="text" class="form-control" placeholder="Buscar por SKU, nombre o descripción"
               wire:model.live.debounce.400ms="q">
      </div>
      <a href="{{ route('inventory.items.new') }}" class="btn btn-primary">
        <i class="fa-solid fa-plus me-1"></i>Nuevo insumo (CAT-SUB-#####)
      </a>
      @can('inventory.prices.manage')
        <button class="btn btn-outline-secondary" wire:click="openPriceModal()">
          <i class="fa-solid fa-tag me-1"></i>Cargar precio
        </button>
      @endcan
    </div>
    <div class="text-muted small d-flex align-items-center gap-2">
      <i class="fa-regular fa-circle-info"></i>
      <span>Recientes: {{ $items->total() }}</span>
       </div>
      </div>

  <div class="card shadow-sm mb-3">
    <div class="card-body">
      <div class="alert alert-info d-flex align-items-start gap-2 mb-4">
        <i class="fa-solid fa-circle-info mt-1"></i>
        <div>
          El alta de insumos sigue el flujo documentado (código interno CAT‑SUB‑##### generado automáticamente).
          Usa el botón <strong>“Nuevo insumo”</strong> para crear registros en <code>selemti.items</code>.
        </div>
      </div>

      <div class="row g-3 align-items-end">
        <div class="col-md-4">
          <label class="form-label">Categoría</label>
          <select class="form-select" wire:model.live="categoryFilter">
            <option value="">Todas</option>
            @foreach($categoryOptions as $category)
              <option value="{{ $category['id'] }}">
                {{ $category['id'] }} · {{ $category['nombre'] }}
              </option>
            @endforeach
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">Estado</label>
          <select class="form-select" wire:model.live="statusFilter">
            <option value="all">Todos</option>
            <option value="active">Solo activos</option>
            <option value="inactive">Solo inactivos</option>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">Proveedor preferente</label>
          <select class="form-select" wire:model.live="preferredFilter">
            <option value="all">Todos</option>
            <option value="with">Con proveedor</option>
            <option value="without">Sin proveedor</option>
          </select>
        </div>
        <div class="col-md-2">
          <label class="form-label">Ordenar por</label>
          <select class="form-select" wire:model.live="sortField">
            <option value="name">Nombre</option>
            <option value="effective_from">Vigencia precio</option>
          </select>
        </div>
        <div class="col-md-2">
          <label class="form-label">Dirección</label>
          <select class="form-select" wire:model.live="sortDirection">
            <option value="asc">Ascendente</option>
            <option value="desc">Descendente</option>
          </select>
        </div>
      </div>
    </div>
  </div>

  <div class="card shadow-sm">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th>SKU / Código</th>
            <th>
              <button type="button" class="btn btn-link p-0 text-decoration-none" wire:click="sortBy('name')">
                Nombre
                @if($sortField === 'name')
                  <i class="fa-solid fa-arrow-{{ $sortDirection === 'asc' ? 'up' : 'down' }}-a-z ms-1"></i>
                @endif
              </button>
            </th>
            <th>Categoría</th>
            <th>Unidad base</th>
            <th>Tipo</th>
            <th class="text-end">Precio vigente</th>
            <th>Proveedor</th>
            <th>
              <button type="button" class="btn btn-link p-0 text-decoration-none" wire:click="sortBy('effective_from')">
                Vigencia
                @if($sortField === 'effective_from')
                  <i class="fa-solid fa-arrow-{{ $sortDirection === 'asc' ? 'up' : 'down' }} ms-1"></i>
                @endif
              </button>
            </th>
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
              @php
                $needsCompletion = !$row->unidad_compra_id || !$row->preferente_vendor;
              @endphp
              @if($needsCompletion)
                <span class="badge bg-warning text-dark mt-1">
                  <i class="fa-solid fa-triangle-exclamation"></i> Pendiente completar
                </span>
              @endif
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
                <div class="fw-semibold">{{ $row->preferente_vendor_name ?? ('Proveedor #' . $row->preferente_vendor) }}</div>
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
              @php
                $needsCompletion = !$row->unidad_compra_id || !$row->preferente_vendor;
              @endphp
              
              @if($needsCompletion)
                <button class="btn btn-sm btn-warning" wire:click="openEdit('{{ $row->id }}')">
                  <i class="fa-solid fa-circle-exclamation"></i> Completar
                </button>
              @else
                <button class="btn btn-sm btn-outline-primary" wire:click="openEdit('{{ $row->id }}')">
                  <i class="fa-solid fa-pen-to-square"></i> Editar
                </button>
              @endif
              
              @can('inventory.prices.manage')
                <button class="btn btn-sm btn-outline-secondary mt-1" wire:click="openPriceModal('{{ $row->id }}')">
                  <i class="fa-solid fa-tag"></i>
                </button>
              @endcan
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
              {{ $isEditing ? 'Completar ítem' : 'Nuevo ítem' }}
            </h5>
            <button type="button" class="btn-close" wire:click="closeForm" aria-label="Cerrar"></button>
          </div>
          <div class="modal-body">
            @if($isEditing && session()->has('success'))
              <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="fa-solid fa-circle-check me-2"></i>
                <strong>Alta rápida completada.</strong> Ahora agrega la información complementaria:
                <ul class="mb-0 mt-2">
                  <li><strong>Unidades de compra/salida</strong> para conversiones precisas</li>
                  <li><strong>Proveedores y costos</strong> para órdenes de compra</li>
                  <li><strong>Temperaturas</strong> si es perecedero</li>
                </ul>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
              </div>
            @endif
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
                <label class="form-label">
                  Unidad compra
                  @if(!$form['unidad_compra_id'])
                    <span class="badge bg-warning text-dark ms-1">Requerido</span>
                  @endif
                </label>
                <select class="form-select" wire:model.defer="form.unidad_compra_id">
                  <option value="">-- Selecciona --</option>
                  @foreach($units as $unit)
                    <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }} · {{ $unit['nombre'] }}</option>
                  @endforeach
                </select>
                @error('form.unidad_compra_id') <div class="text-danger small">{{ $message }}</div> @enderror
                <small class="text-muted">Unidad en la que compras al proveedor</small>
              </div>
              <div class="col-md-4">
                <label class="form-label">
                  Unidad salida
                  <span class="badge bg-info text-dark ms-1">Opcional</span>
                </label>
                <select class="form-select" wire:model.defer="form.unidad_salida_id">
                  <option value="">-- Selecciona --</option>
                  @foreach($units as $unit)
                    <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }} · {{ $unit['nombre'] }}</option>
                  @endforeach
                </select>
                @error('form.unidad_salida_id') <div class="text-danger small">{{ $message }}</div> @enderror
                <small class="text-muted">Unidad para usar en recetas de cocina</small>
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
                <hr class="my-4">
                <div class="d-flex justify-content-between align-items-center mb-3">
                  <h6 class="fw-bold mb-0">
                    <i class="fa-solid fa-truck me-2"></i>Proveedores y Presentaciones
                  </h6>
                  <button type="button" class="btn btn-sm btn-primary" wire:click="addProviderLine">
                    <i class="fa-solid fa-plus me-1"></i> Agregar proveedor
                  </button>
                </div>

                @if(empty($providers))
                  <div class="alert alert-info">
                    <i class="fa-solid fa-info-circle me-2"></i>
                    No hay proveedores configurados. Agrega al menos uno para completar el item.
                  </div>
                @else
                  <div class="accordion" id="accordionProviders">
                    @foreach($providers as $index => $provider)
                      @php
                        $providerName = collect($providerOptions)->firstWhere('id', $provider['vendor_id'])['nombre'] ?? 'Proveedor sin seleccionar';
                        $isPreferred = $provider['preferente'] ?? false;
                        $hasErrors = $errors->has("providers.$index.*");
                      @endphp
                      
                      <div class="accordion-item {{ $hasErrors ? 'border-danger' : '' }}">
                        <h2 class="accordion-header" id="heading{{ $index }}">
                          <button class="accordion-button {{ $index > 0 ? 'collapsed' : '' }}" type="button" 
                                  data-bs-toggle="collapse" 
                                  data-bs-target="#collapse{{ $index }}" 
                                  aria-expanded="{{ $index === 0 ? 'true' : 'false' }}" 
                                  aria-controls="collapse{{ $index }}">
                            <div class="d-flex align-items-center gap-3 w-100">
                              @if($isPreferred)
                                <span class="badge bg-success">
                                  <i class="fa-solid fa-star"></i> Preferente
                                </span>
                              @else
                                <span class="badge bg-secondary">Alternativo</span>
                              @endif
                              <span class="fw-semibold">{{ $providerName }}</span>
                              @if($provider['presentacion'])
                                <span class="text-muted small">· {{ $provider['presentacion'] }}</span>
                              @endif
                              @if($provider['costo_ultimo'])
                                <span class="ms-auto text-success fw-bold me-5">
                                  ${{ number_format($provider['costo_ultimo'], 2) }} {{ $provider['moneda'] ?? 'MXN' }}
                                </span>
                              @endif
                            </div>
                          </button>
                        </h2>
                        <div id="collapse{{ $index }}" 
                             class="accordion-collapse collapse {{ $index === 0 ? 'show' : '' }}" 
                             aria-labelledby="heading{{ $index }}" 
                             data-bs-parent="#accordionProviders">
                          <div class="accordion-body">
                            <div class="row g-3">
                              <!-- Proveedor -->
                              <div class="col-md-6">
                                <label class="form-label fw-semibold">
                                  <i class="fa-solid fa-building me-1"></i>Proveedor
                                  <span class="text-danger">*</span>
                                </label>
                                <select class="form-select" wire:model.live="providers.{{ $index }}.vendor_id">
                                  <option value="">-- Selecciona un proveedor --</option>
                                  @foreach($providerOptions as $option)
                                    <option value="{{ $option['id'] }}">{{ $option['nombre'] }}</option>
                                  @endforeach
                                </select>
                                @error("providers.$index.vendor_id") 
                                  <div class="text-danger small mt-1">{{ $message }}</div> 
                                @enderror
                              </div>

                              <!-- Preferente -->
                              <div class="col-md-6">
                                <label class="form-label fw-semibold">
                                  <i class="fa-solid fa-star me-1"></i>Proveedor principal
                                </label>
                                <div class="form-check form-switch mt-2">
                                  <input class="form-check-input" type="checkbox" role="switch"
                                         id="preferente{{ $index }}"
                                         {{ $isPreferred ? 'checked' : '' }}
                                         wire:click="setPreferred({{ $index }})">
                                  <label class="form-check-label" for="preferente{{ $index }}">
                                    Marcar como proveedor preferente
                                  </label>
                                </div>
                                <small class="text-muted">Solo puede haber un proveedor preferente</small>
                              </div>

                              <!-- Presentación -->
                              <div class="col-md-8">
                                <label class="form-label fw-semibold">
                                  <i class="fa-solid fa-box me-1"></i>Presentación comercial
                                  <span class="text-danger">*</span>
                                </label>
                                <input type="text" class="form-control"
                                       wire:model.defer="providers.{{ $index }}.presentacion"
                                       placeholder="Ej: Caja 12 pzas × 1 L">
                                @error("providers.$index.presentacion") 
                                  <div class="text-danger small mt-1">{{ $message }}</div> 
                                @enderror
                                <small class="text-muted">Describe cómo vende este proveedor el producto</small>
                              </div>

                              <!-- Unidad de presentación -->
                              <div class="col-md-4">
                                <label class="form-label fw-semibold">
                                  Unidad empaque <span class="text-danger">*</span>
                                </label>
                                <select class="form-select" wire:model.defer="providers.{{ $index }}.unidad_presentacion_id">
                                  <option value="">-- Selecciona --</option>
                                  @foreach($units as $unit)
                                    <option value="{{ $unit['id'] }}">
                                      {{ $unit['codigo'] }} - {{ $unit['nombre'] }}
                                    </option>
                                  @endforeach
                                </select>
                                @error("providers.$index.unidad_presentacion_id") 
                                  <div class="text-danger small mt-1">{{ $message }}</div> 
                                @enderror
                              </div>

                              <!-- Factor de conversión -->
                              <div class="col-md-4">
                                <label class="form-label fw-semibold">
                                  <i class="fa-solid fa-calculator me-1"></i>Factor a base
                                  <span class="text-danger">*</span>
                                </label>
                                <input type="number" step="0.0001" class="form-control"
                                       wire:model.defer="providers.{{ $index }}.factor_a_canonica"
                                       placeholder="12.0">
                                @error("providers.$index.factor_a_canonica") 
                                  <div class="text-danger small mt-1">{{ $message }}</div> 
                                @enderror
                                <small class="text-muted">Cuántas unidades base contiene</small>
                              </div>

                              <!-- Costo -->
                              <div class="col-md-4">
                                <label class="form-label fw-semibold">
                                  <i class="fa-solid fa-dollar-sign me-1"></i>Costo
                                  <span class="text-danger">*</span>
                                </label>
                                <div class="input-group">
                                  <span class="input-group-text">$</span>
                                  <input type="number" step="0.01" class="form-control"
                                         wire:model.defer="providers.{{ $index }}.costo_ultimo"
                                         placeholder="150.00">
                                </div>
                                @error("providers.$index.costo_ultimo") 
                                  <div class="text-danger small mt-1">{{ $message }}</div> 
                                @enderror
                              </div>

                              <!-- Moneda -->
                              <div class="col-md-4">
                                <label class="form-label fw-semibold">Moneda</label>
                                <select class="form-select" wire:model.defer="providers.{{ $index }}.moneda">
                                  <option value="MXN">MXN - Peso Mexicano</option>
                                  <option value="USD">USD - Dólar</option>
                                </select>
                              </div>

                              <!-- Lead time -->
                              <div class="col-md-4">
                                <label class="form-label fw-semibold">
                                  <i class="fa-solid fa-clock me-1"></i>Lead time (días)
                                </label>
                                <input type="number" class="form-control"
                                       wire:model.defer="providers.{{ $index }}.lead_time_dias"
                                       placeholder="3">
                                <small class="text-muted">Tiempo de entrega del proveedor</small>
                              </div>

                              <!-- SKU proveedor -->
                              <div class="col-md-8">
                                <label class="form-label fw-semibold">
                                  <i class="fa-solid fa-barcode me-1"></i>SKU del proveedor
                                </label>
                                <input type="text" class="form-control"
                                       wire:model.defer="providers.{{ $index }}.codigo_proveedor"
                                       placeholder="Código/SKU que usa el proveedor">
                              </div>

                              <!-- Botón eliminar -->
                              <div class="col-12">
                                <hr>
                                <button type="button" class="btn btn-sm btn-outline-danger" 
                                        wire:click="removeProviderLine({{ $index }})">
                                  <i class="fa-solid fa-trash me-1"></i>
                                  Eliminar este proveedor
                                </button>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    @endforeach
                  </div>
                @endif
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

  @can('inventory.prices.manage')
    <livewire:inventory.item-price-create />
  @endcan
</div>
