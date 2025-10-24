<div class="py-3">
    <div class="row justify-content-center">
        <div class="col-lg-8 col-xl-6">
            {{-- Card de apertura --}}
            <div class="card shadow-sm">
                <div class="card-header bg-white border-bottom">
                    <div class="d-flex align-items-center">
                        <i class="fa-solid fa-wallet text-success me-2 fs-4"></i>
                        <div>
                            <h5 class="mb-0">Apertura de Fondo de Caja Chica</h5>
                            <small class="text-muted">Registra el monto inicial para el día</small>
                        </div>
                    </div>
                </div>

                <div class="card-body">
                    <form wire:submit.prevent="save">
                        <div class="row g-3">
                            {{-- Sucursal --}}
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">
                                    Sucursal <span class="text-danger">*</span>
                                </label>
                                <select class="form-select @error('form.sucursal_id') is-invalid @enderror"
                                        wire:model.defer="form.sucursal_id"
                                        {{ $loading ? 'disabled' : '' }}>
                                    <option value="">-- Selecciona sucursal --</option>
                                    @foreach($sucursales as $suc)
                                        <option value="{{ $suc['id'] }}">{{ $suc['nombre'] }}</option>
                                    @endforeach
                                </select>
                                @error('form.sucursal_id')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>

                            {{-- Fecha --}}
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">
                                    Fecha <span class="text-danger">*</span>
                                </label>
                                <input type="date"
                                       class="form-control @error('form.fecha') is-invalid @enderror"
                                       wire:model.defer="form.fecha"
                                       max="{{ now()->format('Y-m-d') }}"
                                       {{ $loading ? 'disabled' : '' }}>
                                @error('form.fecha')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>

                            {{-- Responsable --}}
                            <div class="col-12">
                                <label class="form-label fw-semibold">
                                    Responsable del fondo <span class="text-danger">*</span>
                                </label>
                                <select class="form-select @error('form.responsable_user_id') is-invalid @enderror"
                                        wire:model.defer="form.responsable_user_id"
                                        {{ $loading ? 'disabled' : '' }}>
                                    <option value="">-- Selecciona responsable --</option>
                                    @foreach($usuarios as $user)
                                        <option value="{{ $user['id'] }}">{{ $user['nombre'] }}</option>
                                    @endforeach
                                </select>
                                @error('form.responsable_user_id')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                                <small class="text-muted">
                                    Usuario encargado de manejar y reportar el efectivo del fondo
                                </small>
                            </div>

                            {{-- Descripción (opcional) --}}
                            <div class="col-12">
                                <label class="form-label fw-semibold">
                                    Descripción <span class="text-muted small">(opcional)</span>
                                </label>
                                <input type="text"
                                       class="form-control @error('form.descripcion') is-invalid @enderror"
                                       wire:model.defer="form.descripcion"
                                       placeholder="Ej: Fondo para pagos proveedores semana 42"
                                       maxlength="255"
                                       {{ $loading ? 'disabled' : '' }}>
                                @error('form.descripcion')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                                <small class="text-muted">
                                    Nombre o descripción breve para identificar el fondo fácilmente
                                </small>
                            </div>

                            {{-- Monto inicial --}}
                            <div class="col-md-8">
                                <label class="form-label fw-semibold">
                                    Monto inicial <span class="text-danger">*</span>
                                </label>
                                <div class="input-group">
                                    <span class="input-group-text">
                                        <i class="fa-solid fa-dollar-sign"></i>
                                    </span>
                                    <input type="number"
                                           step="0.01"
                                           class="form-control @error('form.monto_inicial') is-invalid @enderror"
                                           wire:model.defer="form.monto_inicial"
                                           placeholder="0.00"
                                           {{ $loading ? 'disabled' : '' }}>
                                    @error('form.monto_inicial')
                                        <div class="invalid-feedback">{{ $message }}</div>
                                    @enderror
                                </div>
                                <small class="text-muted">
                                    Monto en efectivo con el que inicia el fondo del día
                                </small>
                            </div>

                            {{-- Moneda --}}
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">
                                    Moneda <span class="text-danger">*</span>
                                </label>
                                <select class="form-select @error('form.moneda') is-invalid @enderror"
                                        wire:model.defer="form.moneda"
                                        {{ $loading ? 'disabled' : '' }}>
                                    <option value="MXN">MXN (Pesos)</option>
                                    <option value="USD">USD (Dólares)</option>
                                </select>
                                @error('form.moneda')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>

                            {{-- Info adicional --}}
                            <div class="col-12">
                                <div class="alert alert-info d-flex align-items-start mb-0">
                                    <i class="fa-solid fa-circle-info mt-1 me-2"></i>
                                    <div>
                                        <strong>Importante:</strong> Una vez abierto el fondo, podrás registrar
                                        egresos y adjuntar comprobantes. Al final del día deberás realizar el
                                        arqueo y cierre del fondo.
                                    </div>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>

                <div class="card-footer bg-light d-flex justify-content-between align-items-center">
                    <a href="{{ url('/dashboard') }}" class="btn btn-outline-secondary">
                        <i class="fa-solid fa-arrow-left me-1"></i>
                        Cancelar
                    </a>
                    <button type="button"
                            class="btn btn-success"
                            wire:click="save"
                            {{ $loading ? 'disabled' : '' }}>
                        @if($loading)
                            <span class="spinner-border spinner-border-sm me-1"></span>
                            Abriendo...
                        @else
                            <i class="fa-solid fa-unlock me-1"></i>
                            Abrir fondo
                        @endif
                    </button>
                </div>
            </div>

            {{-- Info de ayuda --}}
            <div class="mt-3">
                <div class="card border-0 bg-light">
                    <div class="card-body">
                        <h6 class="fw-bold mb-2">
                            <i class="fa-solid fa-question-circle text-primary me-1"></i>
                            ¿Qué es el fondo de caja chica?
                        </h6>
                        <p class="small text-muted mb-0">
                            Es un monto asignado diariamente para cubrir gastos menores y pagos a proveedores.
                            El responsable debe registrar cada egreso, adjuntar comprobantes y realizar el
                            arqueo al cierre del día para conciliar el efectivo físico con el sistema.
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
