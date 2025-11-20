<div class="container py-3">
  <div class="d-flex justify-content-between align-items-center mb-3">
    <div>
      <h1 class="h4 mb-1"><i class="fa-solid fa-code-compare me-2"></i>Comparador de versiones</h1>
      <p class="text-muted mb-0">Selecciona la receta y compara dos versiones lado a lado.</p>
    </div>
    <a href="{{ route('rec.index') }}" class="btn btn-outline-secondary btn-sm">
      <i class="fa-solid fa-arrow-left me-1"></i>Volver a recetas
    </a>
  </div>

  <div class="row g-3">
    <div class="col-lg-8">
      <form wire:submit.prevent="loadVersions" class="card shadow-sm border-0 mb-3">
        <div class="card-body">
          <div class="row g-3 align-items-end">
            <div class="col-md-6">
              <label class="form-label">Receta ID</label>
              <input type="text" class="form-control" placeholder="Ej. REC-00123" wire:model.defer="recipeId">
            </div>
            <div class="col-md-3">
              <button type="submit" class="btn btn-primary w-100">
                <i class="fa-solid fa-rotate me-1"></i>Cargar versiones
              </button>
            </div>
            <div class="col-md-3 text-md-end small text-muted">
              @if($loading)
                <span class="text-primary"><i class="fa-solid fa-spinner fa-spin me-1"></i>Cargando...</span>
              @elseif($versions)
                {{ count($versions) }} versión(es) encontradas
              @endif
            </div>
          </div>

          @if($errorMessage)
            <div class="alert alert-danger mt-3 mb-0 py-2">
              <i class="fa-solid fa-circle-exclamation me-2"></i>{{ $errorMessage }}
            </div>
          @endif
        </div>
      </form>

      <div class="card shadow-sm border-0 h-100">
        <div class="card-body">
          @if(empty($versions))
            <div class="text-center text-muted py-4">
              <i class="fa-regular fa-file-lines fa-2x mb-2"></i>
              <p class="mb-0">Ingresa una receta para ver su historial de versiones.</p>
            </div>
          @else
            <div class="row g-3 mb-3">
              <div class="col-md-6">
                <label class="form-label">Versión izquierda</label>
                <select class="form-select" wire:model.live="leftVersionId">
                  <option value="">-- Selecciona --</option>
                  @foreach($versions as $version)
                    <option value="{{ $version['id'] }}">
                      v{{ $version['version'] }} · {{ $version['descripcion_cambios'] ?? 'Sin descripción' }}
                      @if($version['publicada']) (publicada) @endif
                    </option>
                  @endforeach
                </select>
              </div>
              <div class="col-md-6">
                <label class="form-label">Versión derecha</label>
                <select class="form-select" wire:model.live="rightVersionId">
                  <option value="">-- Selecciona --</option>
                  @foreach($versions as $version)
                    <option value="{{ $version['id'] }}">
                      v{{ $version['version'] }} · {{ $version['descripcion_cambios'] ?? 'Sin descripción' }}
                      @if($version['publicada']) (publicada) @endif
                    </option>
                  @endforeach
                </select>
              </div>
            </div>

            @if($comparison)
              <div class="row g-3">
                <div class="col-md-6">
                  <div class="border rounded p-3 h-100">
                    <div class="d-flex align-items-center justify-content-between mb-2">
                      <div>
                        <div class="fw-semibold">Versión izquierda</div>
                        <div class="small text-muted">
                          v{{ $comparison['version1']['version'] ?? '—' }} |
                          {{ $comparison['version1']['descripcion_cambios'] ?? '' }}
                        </div>
                      </div>
                      @if(($comparison['version1']['publicada'] ?? false))
                        <span class="badge text-bg-success">Publicada</span>
                      @endif
                    </div>
                    <div class="small text-muted">
                      Ingredientes: {{ $comparison['version1']['total_ingredientes'] ?? 0 }} ·
                      Fecha: {{ $comparison['version1']['fecha_efectiva'] ?? '—' }}
                    </div>
                  </div>
                </div>
                <div class="col-md-6">
                  <div class="border rounded p-3 h-100">
                    <div class="d-flex align-items-center justify-content-between mb-2">
                      <div>
                        <div class="fw-semibold">Versión derecha</div>
                        <div class="small text-muted">
                          v{{ $comparison['version2']['version'] ?? '—' }} |
                          {{ $comparison['version2']['descripcion_cambios'] ?? '' }}
                        </div>
                      </div>
                      @if(($comparison['version2']['publicada'] ?? false))
                        <span class="badge text-bg-success">Publicada</span>
                      @endif
                    </div>
                    <div class="small text-muted">
                      Ingredientes: {{ $comparison['version2']['total_ingredientes'] ?? 0 }} ·
                      Fecha: {{ $comparison['version2']['fecha_efectiva'] ?? '—' }}
                    </div>
                  </div>
                </div>
              </div>

              <hr class="my-3">

              <div class="row g-3">
                <div class="col-md-4">
                  <h6 class="mb-2 text-success"><i class="fa-solid fa-plus me-1"></i>Agregados</h6>
                  @forelse($comparison['diff']['added'] ?? [] as $row)
                    <div class="border rounded p-2 mb-2">
                      <div class="fw-semibold">{{ $row['item_nombre'] ?? $row['item_id'] }}</div>
                      <div class="small text-muted">{{ $row['cantidad'] }} {{ $row['unidad_medida'] }}</div>
                    </div>
                  @empty
                    <p class="text-muted small mb-0">Sin nuevos ingredientes.</p>
                  @endforelse
                </div>
                <div class="col-md-4">
                  <h6 class="mb-2 text-danger"><i class="fa-solid fa-minus me-1"></i>Removidos</h6>
                  @forelse($comparison['diff']['removed'] ?? [] as $row)
                    <div class="border rounded p-2 mb-2">
                      <div class="fw-semibold">{{ $row['item_nombre'] ?? $row['item_id'] }}</div>
                      <div class="small text-muted">{{ $row['cantidad'] }} {{ $row['unidad_medida'] }}</div>
                    </div>
                  @empty
                    <p class="text-muted small mb-0">Sin elementos removidos.</p>
                  @endforelse
                </div>
                <div class="col-md-4">
                  <h6 class="mb-2 text-warning"><i class="fa-solid fa-pen-ruler me-1"></i>Cambios</h6>
                  @forelse($comparison['diff']['modified'] ?? [] as $row)
                    <div class="border rounded p-2 mb-2">
                      <div class="fw-semibold">{{ $row['item_nombre'] ?? $row['item_id'] }}</div>
                      <div class="small text-muted mb-1">
                        v{{ $comparison['version1']['version'] ?? '' }}:
                        {{ $row['v1']['cantidad'] ?? 0 }} {{ $row['v1']['unidad_medida'] ?? '—' }}
                        (merma {{ $row['v1']['merma'] ?? 0 }}%)
                      </div>
                      <div class="small text-muted">
                        v{{ $comparison['version2']['version'] ?? '' }}:
                        {{ $row['v2']['cantidad'] ?? 0 }} {{ $row['v2']['unidad_medida'] ?? '—' }}
                        (merma {{ $row['v2']['merma'] ?? 0 }}%)
                      </div>
                    </div>
                  @empty
                    <p class="text-muted small mb-0">Sin modificaciones detectadas.</p>
                  @endforelse
                </div>
              </div>
            @else
              <div class="text-muted small">Selecciona dos versiones para comparar.</div>
            @endif
          @endif
        </div>
      </div>
    </div>

    <div class="col-lg-4">
      @livewire('recipes.version-activator', ['recipeId' => $recipeId], key('version-activator-'.$recipeId))
    </div>
  </div>
</div>
