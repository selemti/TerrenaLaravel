<div class="card shadow-sm border-0 h-100">
  <div class="card-body">
    <h5 class="card-title mb-3"><i class="fa-solid fa-bolt me-2"></i>Activar versión</h5>

    <div class="mb-3">
      <label class="form-label">Receta ID</label>
      <input type="text" class="form-control form-control-sm" placeholder="REC-00123" wire:model.defer="recipeId">
    </div>

    <div class="mb-3">
      <label class="form-label">Versión a publicar</label>
      <select class="form-select form-select-sm" wire:model.live="selectedVersion" @disabled(empty($versions))>
        <option value="">-- Selecciona --</option>
        @foreach($versions as $version)
          <option value="{{ $version['id'] }}">
            v{{ $version['version'] }} · {{ $version['descripcion_cambios'] ?? 'Sin descripción' }}
            @if($version['publicada']) (publicada) @endif
          </option>
        @endforeach
      </select>
      <div class="form-text">Publica para que POS y costeo usen la versión activa.</div>
    </div>

    <div class="d-grid gap-2">
      <button type="button" class="btn btn-success" wire:click="publish" @disabled(!$selectedVersion || $loading)">
        @if($loading)
          <i class="fa-solid fa-spinner fa-spin me-1"></i>Publicando...
        @else
          <i class="fa-solid fa-check me-1"></i>Publicar versión
        @endif
      </button>
    </div>

    @if($statusMessage)
      <div class="alert alert-success mt-3 py-2">
        <i class="fa-solid fa-circle-check me-2"></i>{{ $statusMessage }}
      </div>
    @endif

    @if($errorMessage)
      <div class="alert alert-danger mt-3 py-2">
        <i class="fa-solid fa-circle-exclamation me-2"></i>{{ $errorMessage }}
      </div>
    @endif

    @if(empty($versions) && $recipeId)
      <p class="small text-muted mt-3 mb-0">No hay versiones registradas para esta receta.</p>
    @endif
  </div>
</div>
