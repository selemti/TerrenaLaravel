<div class="{{ $asModal ? '' : 'dashboard-grid py-3' }}">
  @if(!$asModal)
    <div class="d-flex justify-content-between align-items-center mb-3">
      <p class="text-muted mb-0">Registra la recepción de mercancía.</p>
      <a href="{{ route('inv.receptions') }}" class="btn btn-outline-secondary">
        <i class="fa-solid fa-arrow-left me-1"></i>Volver
      </a>
    </div>
  @endif

  @if (session()->has('ok'))
    <div class="alert alert-success alert-dismissible fade show" role="alert">
      <i class="fa-solid fa-circle-check me-2"></i>{{ session('ok') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
    </div>
  @endif

  <form wire:submit.prevent="save" class="card shadow-sm border-0">
    <div class="card-body">
      <div class="row g-3 mb-3">
        <div class="col-md-4">
          <label class="form-label">Proveedor</label>
          <select class="form-select" wire:model="supplier_id">
            <option value="">-- Seleccione --</option>
            @foreach($suppliers as $supplier)
              <option value="{{ $supplier->id }}">{{ $supplier->nombre }}</option>
            @endforeach
          </select>
          @error('supplier_id') <div class="text-danger small">{{ $message }}</div> @enderror
        </div>

        <div class="col-md-4">
          <label class="form-label">Sucursal</label>
          <select class="form-select" wire:model="branch_id">
            <option value="">-- Seleccione --</option>
            @foreach($branches as $branch)
              <option value="{{ $branch->id }}">{{ $branch->clave }} — {{ $branch->nombre }}</option>
            @endforeach
          </select>
          @error('branch_id') <div class="text-danger small">{{ $message }}</div> @enderror
        </div>

        <div class="col-md-4">
          <label class="form-label">Almacén</label>
          <select class="form-select" wire:model="warehouse_id">
            <option value="">-- Seleccione --</option>
            @foreach($warehouses as $warehouse)
              <option value="{{ $warehouse->id }}">
                {{ $warehouse->clave }} — {{ $warehouse->nombre }}
                @if($warehouse->sucursal_clave)
                  ({{ $warehouse->sucursal_clave }})
                @endif
              </option>
            @endforeach
          </select>
          @error('warehouse_id') <div class="text-danger small">{{ $message }}</div> @enderror
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
                  @foreach($items as $item)
                    <option value="{{ $item->id }}">{{ $item->nombre ?? $item->descripcion ?? $item->id }}</option>
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
                  @foreach($purchaseUoms as $purchaseUom)
                    <option value="{{ $purchaseUom }}">{{ $purchaseUom }}</option>
                  @endforeach
                </select>
              </td>
              <td>
                <input type="number" step="0.0001" class="form-control form-control-sm"
                       wire:model="lines.{{ $i }}.pack_size" placeholder="ej 12">
              </td>
              <td>
                <select class="form-select form-select-sm" wire:model="lines.{{ $i }}.uom_base">
                  @foreach($baseUoms as $baseUom)
                    <option value="{{ $baseUom }}">{{ $baseUom }}</option>
                  @endforeach
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
    </div>
    <div class="card-footer d-flex gap-2">
      <button type="button" class="btn btn-outline-primary" wire:click="addLine">+ Línea</button>
      <button type="submit" class="btn btn-success">Guardar recepción</button>
    </div>
  </form>
</div>
