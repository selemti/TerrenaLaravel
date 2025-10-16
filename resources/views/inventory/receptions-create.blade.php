<x-layouts.app>
<div class="d-flex justify-content-between align-items-center mb-3">
  <h1 class="h4">Nueva recepción</h1>
  <a href="{{ route('inv.receptions') }}" class="btn btn-outline-secondary">Volver</a>
</div>

@if (session('ok'))
  <div class="alert alert-success">{{ session('ok') }}</div>
@endif

<form wire:submit.prevent="save">
  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">Proveedor</label>
      <select class="form-select" wire:model="supplier_id">
        <option value="">-- Seleccione --</option>
        @foreach($suppliers as $s)
          <option value="{{ $s['id'] }}">{{ $s['nombre'] }}</option>
        @endforeach
      </select>
      @error('supplier_id') <div class="text-danger small">{{ $message }}</div> @enderror
    </div>

    <div class="col-md-4">
      <label class="form-label">Sucursal</label>
      <input type="text" class="form-control" wire:model="branch_id" placeholder="Opcional">
    </div>

    <div class="col-md-4">
      <label class="form-label">Almacén</label>
      <input type="text" class="form-control" wire:model="warehouse_id" placeholder="Opcional">
    </div>
  </div>

  <div class="table-responsive">
    <table class="table table-sm align-middle">
      <thead class="table-light">
        <tr>
          <th style="width:22%">Producto</th>
          <th>Qty Presentación</th>
          <th>UOM Compra</th>
          <th>Pack Size</th>
          <th>UOM Base</th>
          <th>Lote</th>
          <th>Caducidad</th>
          <th>Temp</th>
          <th>Evidencia</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
      @foreach($lines as $i => $l)
        <tr>
          <td>
            <select class="form-select form-select-sm" wire:model="lines.{{ $i }}.item_id">
              <option value="">--</option>
              @foreach($items as $it)
                <option value="{{ $it['id'] }}">{{ $it['nombre'] }}</option>
              @endforeach
            </select>
            @error("lines.$i.item_id") <div class="text-danger small">{{ $message }}</div> @enderror
          </td>
          <td>
            <input type="number" step="0.0001" class="form-control form-control-sm"
              wire:model="lines.{{ $i }}.qty_pack">
          </td>
          <td>
            <select class="form-select form-select-sm" wire:model="lines.{{ $i }}.uom_purchase">
              <option value="PZ">PZ</option>
              <option value="CAJA">CAJA</option>
              <option value="LT">LT</option>
            </select>
          </td>
          <td>
            <input type="number" step="0.0001" class="form-control form-control-sm"
               wire:model="lines.{{ $i }}.pack_size" placeholder="ej 12">
          </td>
          <td>
            <select class="form-select form-select-sm" wire:model="lines.{{ $i }}.uom_base">
              <option value="GR">GR</option>
              <option value="ML">ML</option>
              <option value="PZ">PZ</option>
            </select>
          </td>
          <td><input type="text" class="form-control form-control-sm"
              wire:model="lines.{{ $i }}.lot" placeholder="Auto si vacío"></td>
          <td><input type="date" class="form-control form-control-sm"
              wire:model="lines.{{ $i }}.exp_date"></td>
          <td><input type="number" step="0.1" class="form-control form-control-sm"
              wire:model="lines.{{ $i }}.temp"></td>
          <td><input type="file" class="form-control form-control-sm"
              wire:model="lines.{{ $i }}.evidence"></td>
          <td>
            <button type="button" class="btn btn-sm btn-outline-danger"
              wire:click="removeLine({{ $i }})">✕</button>
          </td>
        </tr>
      @endforeach
      </tbody>
    </table>
  </div>

  <div class="d-flex gap-2">
    <button type="button" class="btn btn-outline-primary" wire:click="addLine">+ Línea</button>
    <button type="submit" class="btn btn-success">Guardar recepción</button>
  </div>
</form>
</x-layouts.app>
