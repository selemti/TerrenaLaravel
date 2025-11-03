<div>
    {{-- Alertas --}}
    @if (session('ok'))
      <div class="alert alert-success alert-dismissible fade show position-fixed top-0 end-0 m-3" role="alert" style="z-index:1055;">
        <i class="fa-solid fa-circle-check me-2"></i>{{ session('ok') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif

    {{-- SECCIÓN 1: CALCULADORA INTERACTIVA --}}
    <div class="card shadow-sm border-0 mb-3" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
      <div class="card-body text-white">
        <h5 class="mb-3">
          <i class="fa-solid fa-calculator me-2"></i>
          Calculadora de Conversiones
        </h5>
        <div class="row g-3 align-items-center">
          <div class="col-md-3">
            <input type="number"
                   class="form-control form-control-lg text-center"
                   wire:model.live="calcCantidad"
                   placeholder="0"
                   step="0.01"
                   style="font-size: 2rem; font-weight: bold;">
          </div>
          <div class="col-md-3">
            <select class="form-select form-select-lg" wire:model.live="calcOrigen">
              <option value="">-- Selecciona --</option>
              @foreach($unitOptions as $opt)
                <option value="{{ $opt->id }}">{{ $opt->clave }} ({{ $opt->nombre }})</option>
              @endforeach
            </select>
          </div>
          <div class="col-md-1 text-center">
            <i class="fa-solid fa-arrow-right fa-2x"></i>
          </div>
          <div class="col-md-2">
            @if($this->calcResultado !== null)
              <div class="bg-white bg-opacity-25 rounded p-3 text-center">
                <div style="font-size: 2rem; font-weight: bold;">{{ number_format($this->calcResultado, 3) }}</div>
              </div>
            @else
              <div class="text-center text-white-50">
                <i class="fa-regular fa-circle-question fa-3x"></i>
              </div>
            @endif
          </div>
          <div class="col-md-3">
            <select class="form-select form-select-lg" wire:model.live="calcDestino">
              <option value="">-- Selecciona --</option>
              @foreach($unitOptions as $opt)
                <option value="{{ $opt->id }}">{{ $opt->clave }} ({{ $opt->nombre }})</option>
              @endforeach
            </select>
          </div>
        </div>
        @if($this->calcResultado !== null && $calcOrigen && $calcDestino)
          <div class="mt-3 text-center">
            <div class="badge bg-white text-dark px-3 py-2" style="font-size: 1rem;">
              <i class="fa-solid fa-check-circle text-success me-1"></i>
              {{ $calcCantidad }} {{ $this->calcOrigenNombre }} = {{ number_format($this->calcResultado, 3) }} {{ $this->calcDestinoNombre }}
            </div>
          </div>
        @elseif($calcOrigen && $calcDestino && $this->calcResultado === null)
          <div class="mt-3 text-center">
            <div class="badge bg-warning text-dark px-3 py-2">
              <i class="fa-solid fa-triangle-exclamation me-1"></i>
              No existe conversión entre estas unidades.
              <button class="btn btn-sm btn-light ms-2" wire:click="createFromCalc">
                <i class="fa-solid fa-plus"></i> Crear conversión
              </button>
            </div>
          </div>
        @endif
      </div>
    </div>

    {{-- SECCIÓN 2: CONVERSIONES AGRUPADAS --}}
    <div class="row g-3 mb-3">
      <div class="col-md-6">
        {{-- Peso --}}
        <div class="card shadow-sm border-0 h-100">
          <div class="card-header bg-primary bg-opacity-10">
            <h6 class="mb-0">
              <i class="fa-solid fa-weight-hanging me-2 text-primary"></i>
              Conversiones de Peso → KG
            </h6>
          </div>
          <div class="list-group list-group-flush">
            @forelse($this->conversionesPeso as $conv)
              <div class="list-group-item d-flex justify-content-between align-items-center">
                <div class="flex-grow-1">
                  <div class="d-flex align-items-center">
                    <span class="badge bg-info me-2">{{ $conv->origenClave }}</span>
                    <i class="fa-solid fa-arrow-right mx-2 text-muted"></i>
                    <span class="badge bg-primary me-2">{{ $conv->destinoClave }}</span>
                  </div>
                  <small class="text-muted d-block mt-1">
                    <strong>Ejemplo:</strong> 1 {{ $conv->origenNombre }} = {{ number_format($conv->factor, 6) }} {{ $conv->destinoNombre }}
                  </small>
                </div>
                <div class="btn-group btn-group-sm">
                  @if($conv->is_exact)
                    <span class="badge bg-success me-2">Exacta</span>
                  @else
                    <span class="badge bg-warning text-dark me-2">~Aprox</span>
                  @endif
                  <button class="btn btn-sm btn-outline-primary" wire:click="edit({{ $conv->id }})" title="Editar">
                    <i class="fa-regular fa-pen-to-square"></i>
                  </button>
                  <button class="btn btn-sm btn-outline-danger"
                          wire:click="delete({{ $conv->id }})"
                          onclick="return confirm('¿Eliminar conversión?')"
                          title="Eliminar">
                    <i class="fa-regular fa-trash-can"></i>
                  </button>
                </div>
              </div>
            @empty
              <div class="list-group-item text-center text-muted py-4">
                <i class="fa-regular fa-face-frown fa-2x mb-2"></i>
                <div>No hay conversiones de peso</div>
                <button class="btn btn-sm btn-primary mt-2" wire:click="create">
                  <i class="fa-solid fa-plus me-1"></i> Agregar primera
                </button>
              </div>
            @endforelse
          </div>
        </div>
      </div>

      <div class="col-md-6">
        {{-- Volumen --}}
        <div class="card shadow-sm border-0 h-100">
          <div class="card-header bg-info bg-opacity-10">
            <h6 class="mb-0">
              <i class="fa-solid fa-flask me-2 text-info"></i>
              Conversiones de Volumen → L
            </h6>
          </div>
          <div class="list-group list-group-flush">
            @forelse($this->conversionesVolumen as $conv)
              <div class="list-group-item d-flex justify-content-between align-items-center">
                <div class="flex-grow-1">
                  <div class="d-flex align-items-center">
                    <span class="badge bg-info me-2">{{ $conv->origenClave }}</span>
                    <i class="fa-solid fa-arrow-right mx-2 text-muted"></i>
                    <span class="badge bg-primary me-2">{{ $conv->destinoClave }}</span>
                  </div>
                  <small class="text-muted d-block mt-1">
                    <strong>Ejemplo:</strong> 1 {{ $conv->origenNombre }} = {{ number_format($conv->factor, 6) }} {{ $conv->destinoNombre }}
                  </small>
                </div>
                <div class="btn-group btn-group-sm">
                  @if($conv->is_exact)
                    <span class="badge bg-success me-2">Exacta</span>
                  @else
                    <span class="badge bg-warning text-dark me-2">~Aprox</span>
                  @endif
                  <button class="btn btn-sm btn-outline-primary" wire:click="edit({{ $conv->id }})" title="Editar">
                    <i class="fa-regular fa-pen-to-square"></i>
                  </button>
                  <button class="btn btn-sm btn-outline-danger"
                          wire:click="delete({{ $conv->id }})"
                          onclick="return confirm('¿Eliminar conversión?')"
                          title="Eliminar">
                    <i class="fa-regular fa-trash-can"></i>
                  </button>
                </div>
              </div>
            @empty
              <div class="list-group-item text-center text-muted py-4">
                <i class="fa-regular fa-face-frown fa-2x mb-2"></i>
                <div>No hay conversiones de volumen</div>
                <button class="btn btn-sm btn-info mt-2" wire:click="create">
                  <i class="fa-solid fa-plus me-1"></i> Agregar primera
                </button>
              </div>
            @endforelse
          </div>
        </div>
      </div>
    </div>

    {{-- SECCIÓN 3: CONVERSIONES BIDIRECCIONALES --}}
    @if($this->conversionesBidireccionales->isNotEmpty())
    <div class="card shadow-sm border-0 mb-3">
      <div class="card-header bg-success bg-opacity-10">
        <h6 class="mb-0">
          <i class="fa-solid fa-arrows-rotate me-2 text-success"></i>
          Conversiones Bidireccionales (↔)
        </h6>
      </div>
      <div class="card-body">
        <div class="row g-3">
          @foreach($this->conversionesBidireccionales as $par)
            <div class="col-md-4">
              <div class="border rounded p-3 bg-light">
                <div class="d-flex align-items-center justify-content-between mb-2">
                  <span class="badge bg-success">{{ $par['unidad1'] }}</span>
                  <i class="fa-solid fa-arrows-left-right text-success"></i>
                  <span class="badge bg-success">{{ $par['unidad2'] }}</span>
                </div>
                <div class="text-center">
                  <small class="text-muted">
                    1 {{ $par['unidad1'] }} = {{ number_format($par['factor1'], 3) }} {{ $par['unidad2'] }}<br>
                    1 {{ $par['unidad2'] }} = {{ number_format($par['factor2'], 3) }} {{ $par['unidad1'] }}
                  </small>
                </div>
              </div>
            </div>
          @endforeach
        </div>
      </div>
    </div>
    @endif

    {{-- SECCIÓN 4: SUGERENCIAS INTELIGENTES --}}
    @if($this->sugerencias->isNotEmpty())
    <div class="alert alert-warning shadow-sm mb-3">
      <h6 class="alert-heading">
        <i class="fa-solid fa-lightbulb me-2"></i>
        Conversiones Sugeridas
      </h6>
      <p class="mb-2 small">El sistema detectó que podrías necesitar estas conversiones comunes:</p>
      <div class="d-flex flex-wrap gap-2">
        @foreach($this->sugerencias as $sug)
          <button class="btn btn-sm btn-outline-warning"
                  wire:click="createFromSuggestion({{ $sug['origenId'] }}, {{ $sug['destinoId'] }}, {{ $sug['factor'] }})">
            <i class="fa-solid fa-plus-circle me-1"></i>
            {{ $sug['origen'] }} → {{ $sug['destino'] }} ({{ $sug['factor'] }})
          </button>
        @endforeach
      </div>
    </div>
    @endif

    {{-- SECCIÓN 5: TABLA COMPLETA (Plegable) --}}
    <div class="card shadow-sm border-0">
      <div class="card-header bg-light">
        <div class="d-flex justify-content-between align-items-center">
          <h6 class="mb-0">
            <i class="fa-solid fa-list me-2"></i>
            Todas las Conversiones ({{ $this->totalConversiones }})
          </h6>
          <div class="d-flex gap-2">
            <button class="btn btn-sm btn-outline-secondary"
                    data-bs-toggle="collapse"
                    data-bs-target="#tablaCompleta">
              <i class="fa-solid fa-chevron-down"></i> Mostrar/Ocultar
            </button>
            <button class="btn btn-sm btn-primary" wire:click="create">
              <i class="fa-solid fa-plus me-1"></i> Nueva conversión
            </button>
          </div>
        </div>
      </div>
      <div class="collapse" id="tablaCompleta">
        <div class="card-body p-0">
          <div class="input-group p-3 bg-light">
            <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
            <input type="search"
                   class="form-control"
                   placeholder="Buscar conversión..."
                   wire:model.live.debounce.400ms="search">
          </div>
          <div class="table-responsive">
            <table class="table table-hover table-sm align-middle mb-0">
              <thead class="table-light">
                <tr>
                  <th>Origen</th>
                  <th>Destino</th>
                  <th class="text-end">Factor</th>
                  <th class="text-center">Tipo</th>
                  <th class="text-center">Scope</th>
                  <th>Ejemplo</th>
                  <th class="text-end">Acciones</th>
                </tr>
              </thead>
              <tbody>
                @forelse($rows as $row)
                  <tr>
                    <td>
                      <span class="badge bg-secondary">{{ $row->origenClave ?? 'N/A' }}</span>
                      <small class="text-muted d-block">{{ $row->origenNombre }}</small>
                    </td>
                    <td>
                      <span class="badge bg-primary">{{ $row->destinoClave ?? 'N/A' }}</span>
                      <small class="text-muted d-block">{{ $row->destinoNombre }}</small>
                    </td>
                    <td class="text-end">
                      <code>{{ number_format($row->factor, 6) }}</code>
                    </td>
                    <td class="text-center">
                      @if($row->is_exact)
                        <span class="badge bg-success">Exacta</span>
                      @else
                        <span class="badge bg-warning text-dark">Aprox</span>
                      @endif
                    </td>
                    <td class="text-center">
                      <span class="badge bg-info">{{ $row->scope }}</span>
                    </td>
                    <td>
                      <small class="text-muted">
                        1 {{ $row->origenClave }} = {{ number_format($row->factor, 3) }} {{ $row->destinoClave }}
                      </small>
                    </td>
                    <td class="text-end">
                      <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-primary" wire:click="edit({{ $row->id }})" title="Editar">
                          <i class="fa-regular fa-pen-to-square"></i>
                        </button>
                        <button class="btn btn-outline-danger"
                                wire:click="delete({{ $row->id }})"
                                onclick="return confirm('¿Eliminar?')"
                                title="Eliminar">
                          <i class="fa-regular fa-trash-can"></i>
                        </button>
                      </div>
                    </td>
                  </tr>
                @empty
                  <tr>
                    <td colspan="7" class="text-center text-muted py-4">
                      <i class="fa-regular fa-folder-open fa-3x mb-2 d-block"></i>
                      No hay conversiones registradas.
                    </td>
                  </tr>
                @endforelse
              </tbody>
            </table>
          </div>
        </div>
        <div class="card-footer bg-white">
          {{ $rows->links() }}
        </div>
      </div>
    </div>

    {{-- MODAL DE EDICIÓN --}}
    <div class="modal fade" id="modalUom" tabindex="-1" aria-labelledby="modalUomLabel" aria-hidden="true" wire:ignore.self>
      <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content border-0 shadow-lg">
          <form wire:submit.prevent="save">
            <div class="modal-header" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
              <h5 class="modal-title text-white" id="modalUomLabel">
                <i class="fa-solid fa-arrows-rotate me-2"></i>
                {{ $editId ? 'Editar Conversión' : 'Nueva Conversión' }}
              </h5>
              <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Cerrar" wire:click="closeModal"></button>
            </div>
            <div class="modal-body">
              <div class="row g-3">
                <div class="col-md-5">
                  <label class="form-label">Unidad Origen <span class="text-danger">*</span></label>
                  <select class="form-select @error('origen_id') is-invalid @enderror" wire:model.live="origen_id">
                    <option value="">-- Selecciona --</option>
                    @foreach ($unitOptions as $option)
                      <option value="{{ $option->id }}">
                        {{ $option->clave }} - {{ $option->nombre }}
                        @if($option->categoria)
                          ({{ $option->categoria }})
                        @endif
                      </option>
                    @endforeach
                  </select>
                  @error('origen_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
                <div class="col-md-2 text-center">
                  <label class="form-label d-block">&nbsp;</label>
                  <i class="fa-solid fa-arrow-right fa-2x text-primary"></i>
                </div>
                <div class="col-md-5">
                  <label class="form-label">Unidad Destino <span class="text-danger">*</span></label>
                  <select class="form-select @error('destino_id') is-invalid @enderror" wire:model.live="destino_id">
                    <option value="">-- Selecciona --</option>
                    @foreach ($unitOptions as $option)
                      <option value="{{ $option->id }}">
                        {{ $option->clave }} - {{ $option->nombre }}
                        @if($option->categoria)
                          ({{ $option->categoria }})
                        @endif
                      </option>
                    @endforeach
                  </select>
                  @error('destino_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
              </div>

              <div class="row g-3 mt-2">
                <div class="col-md-6">
                  <label class="form-label">Factor de Conversión <span class="text-danger">*</span></label>
                  <input type="number"
                         step="0.000001"
                         min="0.000001"
                         class="form-control form-control-lg @error('factor') is-invalid @enderror"
                         wire:model.live="factor"
                         placeholder="0.000000">
                  @error('factor')<div class="invalid-feedback">{{ $message }}</div>@enderror
                  <small class="form-text text-muted">
                    <i class="fa-solid fa-circle-info me-1"></i>
                    ¿Cuántas unidades destino hay en 1 unidad origen?
                  </small>
                </div>
                <div class="col-md-6">
                  <label class="form-label">Tipo de Conversión</label>
                  <div class="form-check">
                    <input class="form-check-input" type="checkbox" id="isExact" wire:model.defer="is_exact">
                    <label class="form-check-label" for="isExact">
                      Conversión exacta
                    </label>
                  </div>
                  <small class="form-text text-muted d-block mt-2">
                    ✓ Exacta: Gramo → KG (0.001)<br>
                    ~ Aproximada: Pizca → KG (0.0005)
                  </small>
                </div>
              </div>

              @if($origen_id && $destino_id && $factor)
                <div class="alert alert-info mt-3">
                  <h6 class="alert-heading">
                    <i class="fa-solid fa-calculator me-2"></i>
                    Vista Previa
                  </h6>
                  <p class="mb-0">
                    <strong>1 {{ $this->origenPreview }}</strong> =
                    <strong>{{ number_format($factor, 6) }} {{ $this->destinoPreview }}</strong>
                  </p>
                </div>
              @endif

              <div class="mt-3">
                <label class="form-label">Notas (Opcional)</label>
                <textarea class="form-control"
                          wire:model.defer="notes"
                          rows="2"
                          placeholder="Ej: Conversión estándar según norma NOM-XXX"></textarea>
              </div>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal" wire:click="closeModal">
                Cancelar
              </button>
              <button type="submit" class="btn btn-primary">
                <i class="fa-regular fa-floppy-disk me-1"></i> Guardar Conversión
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
</div>

@push('scripts')
<script>
  document.addEventListener('DOMContentLoaded', () => {
    if (!window.bootstrap) return;
    const modalEl = document.getElementById('modalUom');
    const modal = new bootstrap.Modal(modalEl);

    document.querySelectorAll('.alert-dismissible').forEach(alert => {
      setTimeout(() => {
        const instance = bootstrap.Alert.getOrCreateInstance(alert);
        instance.close();
      }, 3500);
    });

    Livewire.on('toggle-uom-modal', (payload) => {
      const open = typeof payload === 'object' && payload !== null && 'open' in payload ? payload.open : !!payload;
      open ? modal.show() : modal.hide();
    });

    modalEl.addEventListener('hidden.bs.modal', () => {
      Livewire.dispatch('uom-modal-closed');
    });
  });
</script>
@endpush
