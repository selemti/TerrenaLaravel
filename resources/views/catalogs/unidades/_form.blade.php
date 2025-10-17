@csrf
<div class="mb-3">
  <label class="form-label" for="codigo">Código</label>
  <input id="codigo" name="codigo" type="text" maxlength="10" class="form-control" value="{{ old('codigo', $unidad->codigo ?? '') }}" required>
  @error('codigo')<div class="text-danger small">{{ $message }}</div>@enderror
</div>
<div class="mb-3">
  <label class="form-label" for="nombre">Nombre</label>
  <input id="nombre" name="nombre" type="text" maxlength="50" class="form-control" value="{{ old('nombre', $unidad->nombre ?? '') }}" required>
  @error('nombre')<div class="text-danger small">{{ $message }}</div>@enderror
</div>
<div class="row g-3">
  <div class="col-md-4">
    <label for="tipo" class="form-label">Tipo</label>
    <select id="tipo" name="tipo" class="form-select" required>
      @php($tipoVal = old('tipo', $unidad->tipo ?? ''))
      @foreach(['PESO','VOLUMEN','UNIDAD','TIEMPO'] as $t)
        <option value="{{ $t }}" @selected($tipoVal===$t)>{{ $t }}</option>
      @endforeach
    </select>
    @error('tipo')<div class="text-danger small">{{ $message }}</div>@enderror
  </div>
  <div class="col-md-4">
    <label for="categoria" class="form-label">Categoría</label>
    <select id="categoria" name="categoria" class="form-select">
      @php($catVal = old('categoria', $unidad->categoria ?? ''))
      <option value="">(ninguna)</option>
      @foreach(['METRICO','IMPERIAL','CULINARIO'] as $c)
        <option value="{{ $c }}" @selected($catVal===$c)>{{ $c }}</option>
      @endforeach
    </select>
    @error('categoria')<div class="text-danger small">{{ $message }}</div>@enderror
  </div>
  <div class="col-md-4">
    <label for="decimales" class="form-label">Decimales</label>
    <input id="decimales" name="decimales" type="number" min="0" max="6" step="1" class="form-control" value="{{ old('decimales', $unidad->decimales ?? 0) }}">
    @error('decimales')<div class="text-danger small">{{ $message }}</div>@enderror
  </div>
</div>
<div class="row g-3 mt-2">
  <div class="col-md-4">
    <label for="factor_conversion_base" class="form-label">Factor conversión (a base)</label>
    <input id="factor_conversion_base" name="factor_conversion_base" type="number" step="0.000001" min="0" class="form-control" value="{{ old('factor_conversion_base', $unidad->factor_conversion_base ?? '') }}">
    @error('factor_conversion_base')<div class="text-danger small">{{ $message }}</div>@enderror
  </div>
  <div class="col-md-4 form-check mt-4">
    @php($base = old('es_base', $unidad->es_base ?? false))
    <input id="es_base" name="es_base" type="checkbox" value="1" class="form-check-input" @checked($base)>
    <label for="es_base" class="form-check-label">Es unidad base</label>
  </div>
</div>
<div class="mt-3 d-flex gap-2">
  <button class="btn btn-primary" type="submit">Guardar</button>
  <a href="{{ route('catalogos.unidades.index') }}" class="btn btn-secondary">Cancelar</a>
</div>
