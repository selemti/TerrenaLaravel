# 05 - VISTAS BLADE

## 🎨 Vistas del Sistema

Todas las vistas están en `resources/views/livewire/cash-fund/`

---

## 1. index.blade.php

**Ruta:** `/cashfund`
**Componente:** `App\Livewire\CashFund\Index`

### Estructura

```blade
<div class="py-3">
    {{-- Header con búsqueda --}}
    <div class="d-flex">
        <input wire:model.live.debounce.400ms="search">
        <a href="{{ route('cashfund.open') }}">Abrir fondo</a>
        @can('approve-cash-funds')
            <a href="{{ route('cashfund.approvals') }}">Aprobaciones</a>
        @endcan
    </div>

    {{-- Filtros --}}
    <select wire:model.live="estadoFilter">
        <option value="all">Todos</option>
        <option value="abierto">Abiertos</option>
        <option value="en_revision">En revisión</option>
        <option value="cerrado">Cerrados</option>
    </select>

    {{-- Tabla de fondos --}}
    <table>
        <thead>
            <tr>
                <th>#Fondo</th>
                <th>Sucursal</th>
                <th>Fecha</th>
                <th>Responsable</th>
                <th>Monto Inicial</th>
                <th>Egresos</th>
                <th>Disponible</th>
                <th>Estado</th>
                <th>Acciones</th>
            </tr>
        </thead>
        <tbody>
            @forelse($fondos as $fondo)
                <tr>
                    {{-- Contenido --}}
                    <td>
                        @if($fondo['estado'] === 'ABIERTO')
                            <a href="movements">Gestionar</a>
                        @elseif($fondo['estado'] === 'EN_REVISION')
                            <a href="movements">Ver</a>
                        @else
                            <a href="detail">Detalle</a>
                        @endif
                    </td>
                </tr>
            @empty
                <tr><td colspan="9">No hay fondos</td></tr>
            @endforelse
        </tbody>
    </table>
</div>
```

### Elementos Clave

**Búsqueda en Tiempo Real:**
```blade
<input type="text"
       wire:model.live.debounce.400ms="search"
       placeholder="Buscar por sucursal, #fondo o usuario">
```

**Badges de Estado:**
```blade
@if($fondo['estado'] === 'ABIERTO')
    <span class="badge text-bg-success">
        <i class="fa-solid fa-unlock"></i>ABIERTO
    </span>
@elseif($fondo['estado'] === 'EN_REVISION')
    <span class="badge text-bg-warning">
        <i class="fa-solid fa-eye"></i>EN REVISIÓN
    </span>
@else
    <span class="badge text-bg-secondary">
        <i class="fa-solid fa-lock"></i>CERRADO
    </span>
@endif
```

**Acciones Condicionales:**
```blade
@if($fondo['estado'] === 'ABIERTO')
    <a href="{{ route('cashfund.movements', $fondo['id']) }}"
       class="btn btn-outline-primary">
        Gestionar
    </a>
@endif
```

---

## 2. open.blade.php

**Ruta:** `/cashfund/open`
**Componente:** `App\Livewire\CashFund\Open`

### Formulario de Apertura

```blade
<form wire:submit.prevent="save">
    {{-- Sucursal --}}
    <select wire:model.defer="form.sucursal_id">
        @foreach($sucursales as $suc)
            <option value="{{ $suc['id'] }}">{{ $suc['nombre'] }}</option>
        @endforeach
    </select>

    {{-- Fecha --}}
    <input type="date"
           wire:model.defer="form.fecha"
           max="{{ now()->format('Y-m-d') }}">

    {{-- Responsable --}}
    <select wire:model.defer="form.responsable_user_id">
        @foreach($usuarios as $user)
            <option value="{{ $user['id'] }}">{{ $user['nombre'] }}</option>
        @endforeach
    </select>

    {{-- Descripción (opcional) --}}
    <input type="text"
           wire:model.defer="form.descripcion"
           placeholder="Ej: Fondo para pagos proveedores semana 42"
           maxlength="255">

    {{-- Monto Inicial --}}
    <input type="number"
           step="0.01"
           wire:model.defer="form.monto_inicial"
           placeholder="0.00">

    {{-- Moneda --}}
    <select wire:model.defer="form.moneda">
        <option value="MXN">MXN (Pesos)</option>
        <option value="USD">USD (Dólares)</option>
    </select>

    {{-- Botones --}}
    <button type="button" wire:click="save" {{ $loading ? 'disabled' : '' }}>
        @if($loading)
            <span class="spinner-border spinner-border-sm"></span>
            Abriendo...
        @else
            <i class="fa-solid fa-unlock"></i>
            Abrir fondo
        @endif
    </button>
</form>
```

### Validación en Vivo

```blade
<input type="number"
       class="form-control @error('form.monto_inicial') is-invalid @enderror"
       wire:model.defer="form.monto_inicial">
@error('form.monto_inicial')
    <div class="invalid-feedback">{{ $message }}</div>
@enderror
```

---

## 3. movements.blade.php

**Ruta:** `/cashfund/{id}/movements`
**Componente:** `App\Livewire\CashFund\Movements`

### Estructura Principal

```blade
<div>
    {{-- Header con info del fondo --}}
    <div class="card">
        <h3>Fondo #{{ $fondo->id }}</h3>
        <p>Saldo disponible: ${{ number_format($saldoDisponible, 2) }}</p>
        <span class="badge">{{ $fondo->estado }}</span>
    </div>

    {{-- Formulario de nuevo movimiento --}}
    @if($fondo->estado === 'ABIERTO')
        <form wire:submit.prevent="addMovimiento">
            {{-- Campos del formulario --}}
        </form>
    @endif

    {{-- Tabla de movimientos --}}
    <table>
        @foreach($movimientos as $mov)
            <tr>
                <td>{{ $mov['concepto'] }}</td>
                <td>${{ number_format($mov['monto'], 2) }}</td>
                <td>
                    {{-- Iconos de acción --}}
                    @if($fondo->estado === 'ABIERTO')
                        <button wire:click="editMovimiento({{ $mov['id'] }})">
                            <i class="fa-solid fa-edit"></i>
                        </button>
                        <button wire:click="deleteMovimiento({{ $mov['id'] }})">
                            <i class="fa-solid fa-trash"></i>
                        </button>
                    @endif
                    <button wire:click="openAuditModal({{ $mov['id'] }})">
                        <i class="fa-solid fa-history"></i>
                    </button>
                </td>
            </tr>
        @endforeach
    </table>

    {{-- Modal de edición --}}
    @if($showEditModal)
        <div class="modal show d-block">
            <form wire:submit.prevent="updateMovimiento">
                {{-- Campos --}}
            </form>
        </div>
    @endif

    {{-- Modal de adjuntos --}}
    @if($showAttachmentModal)
        <div class="modal show d-block">
            <input type="file" wire:model="archivo">
            <button wire:click="uploadAttachment">Subir</button>
        </div>
    @endif

    {{-- Modal de auditoría --}}
    @if($showAuditModal)
        <div class="modal show d-block">
            @foreach($auditHistory as $log)
                <div class="timeline-item">
                    <strong>{{ $log['action'] }}</strong>
                    <span>{{ $log['fecha'] }}</span>
                    <p>{{ $log['usuario'] }}</p>
                    @if($log['field_changed'])
                        <div>
                            {{ $log['field_changed'] }}:
                            <del>{{ $log['old_value'] }}</del>
                            → {{ $log['new_value'] }}
                        </div>
                    @endif
                </div>
            @endforeach
        </div>
    @endif
</div>
```

### Formulario Dinámico

```blade
<select wire:model.live="movimientoForm.tipo">
    <option value="EGRESO">Egreso</option>
    <option value="REINTEGRO">Reintegro</option>
    <option value="DEPOSITO">Depósito</option>
</select>

{{-- Campo proveedor solo visible para EGRESO --}}
@if($movimientoForm['tipo'] === 'EGRESO')
    <input type="text"
           wire:model.defer="movimientoForm.proveedor_nombre"
           placeholder="Nombre del proveedor">
@endif
```

### Upload de Archivos

```blade
<input type="file"
       wire:model="archivo"
       accept=".pdf,.jpg,.jpeg,.png">

<div wire:loading wire:target="archivo">
    Subiendo archivo...
</div>

@if($archivo)
    <p>Archivo seleccionado: {{ $archivo->getClientOriginalName() }}</p>
@endif
```

---

## 4. arqueo.blade.php

**Ruta:** `/cashfund/{id}/arqueo`
**Componente:** `App\Livewire\CashFund\Arqueo`

### Vista de Arqueo

```blade
<div class="row">
    {{-- Columna izquierda: Resumen --}}
    <div class="col-lg-8">
        <h4>Saldo Teórico: ${{ number_format($saldoTeorico, 2) }}</h4>

        <table>
            <tr>
                <td>Monto Inicial:</td>
                <td>${{ number_format($fondo->monto_inicial, 2) }}</td>
            </tr>
            <tr class="text-danger">
                <td>Total Egresos:</td>
                <td>-${{ number_format($totalEgresos, 2) }}</td>
            </tr>
            <tr class="text-success">
                <td>Total Reintegros:</td>
                <td>+${{ number_format($totalReintegros, 2) }}</td>
            </tr>
        </table>

        {{-- Tabla de movimientos --}}
        <table>
            @foreach($movimientos as $mov)
                <tr>
                    <td>{{ $mov['concepto'] }}</td>
                    <td>{{ $mov['tipo'] }}</td>
                    <td>${{ number_format($mov['monto'], 2) }}</td>
                    <td>
                        @if($mov['tiene_comprobante'])
                            <i class="fa-solid fa-check text-success"></i>
                        @else
                            <i class="fa-solid fa-times text-danger"></i>
                        @endif
                    </td>
                </tr>
            @endforeach
        </table>
    </div>

    {{-- Columna derecha: Formulario de arqueo --}}
    <div class="col-lg-4">
        <div class="card">
            <h5>Conteo de Efectivo</h5>

            <label>Efectivo Contado</label>
            <input type="number"
                   step="0.01"
                   wire:model.live="arqueoForm.efectivo_contado"
                   placeholder="0.00"
                   class="form-control">

            <div class="alert alert-{{ abs($diferencia) < 0.01 ? 'success' : 'warning' }}">
                <strong>Diferencia:</strong>
                ${{ number_format($diferencia, 2) }}

                @if(abs($diferencia) < 0.01)
                    <p>✅ CUADRA PERFECTAMENTE</p>
                @elseif($diferencia > 0)
                    <p>⚠️ SOBRANTE</p>
                @else
                    <p>⚠️ FALTANTE</p>
                @endif
            </div>

            <label>Observaciones</label>
            <textarea wire:model.defer="arqueoForm.observaciones"></textarea>

            <button wire:click="openConfirmModal">
                Confirmar y cerrar
            </button>
        </div>
    </div>
</div>

{{-- Modal de confirmación --}}
@if($showConfirmModal)
    <div class="modal show d-block">
        <h5>¿Confirmar Arqueo?</h5>
        <p>Saldo teórico: ${{ number_format($saldoTeorico, 2) }}</p>
        <p>Efectivo contado: ${{ number_format($efectivoContado, 2) }}</p>
        <p class="fw-bold">Diferencia: ${{ number_format($diferencia, 2) }}</p>

        <button wire:click="guardarArqueo">Confirmar</button>
        <button wire:click="$set('showConfirmModal', false)">Cancelar</button>
    </div>
@endif
```

---

## 5. approvals.blade.php

**Ruta:** `/cashfund/approvals`
**Componente:** `App\Livewire\CashFund\Approvals`

### Vista de Aprobaciones

```blade
<div class="row">
    {{-- Lista de fondos pendientes --}}
    <div class="col-lg-4">
        <h5>Fondos en Revisión ({{ count($fondosPendientes) }})</h5>

        @foreach($fondosPendientes as $fondo)
            <div class="card mb-2 {{ $selectedFondoId === $fondo['id'] ? 'border-primary' : '' }}"
                 wire:click="selectFondo({{ $fondo['id'] }})">
                <h6>Fondo #{{ $fondo['id'] }}</h6>
                <p>{{ $fondo['sucursal_nombre'] }}</p>
                <p>{{ $fondo['fecha'] }}</p>
                <span class="badge">
                    ${{ number_format($fondo['saldo_disponible'], 2) }}
                </span>
            </div>
        @endforeach
    </div>

    {{-- Detalle del fondo seleccionado --}}
    <div class="col-lg-8">
        @if($selectedFondo)
            <div class="card">
                <h4>Fondo #{{ $selectedFondo->id }}</h4>

                {{-- Resumen --}}
                <table>
                    <tr>
                        <td>Monto Inicial:</td>
                        <td>${{ number_format($selectedFondo->monto_inicial, 2) }}</td>
                    </tr>
                    <tr>
                        <td>Total Egresos:</td>
                        <td>-${{ number_format($totalEgresos, 2) }}</td>
                    </tr>
                    <tr>
                        <td>Saldo Final:</td>
                        <td>${{ number_format($saldoFinal, 2) }}</td>
                    </tr>
                </table>

                {{-- Resultado de arqueo --}}
                @if($arqueo)
                    <div class="alert alert-{{ abs($arqueo['diferencia']) < 0.01 ? 'success' : 'warning' }}">
                        <h5>Resultado del Arqueo</h5>
                        <p>Esperado: ${{ number_format($arqueo['monto_esperado'], 2) }}</p>
                        <p>Contado: ${{ number_format($arqueo['monto_contado'], 2) }}</p>
                        <p>Diferencia: ${{ number_format($arqueo['diferencia'], 2) }}</p>
                    </div>
                @endif

                {{-- Movimientos --}}
                <table>
                    @foreach($movimientos as $mov)
                        <tr class="{{ !$mov['tiene_comprobante'] ? 'table-warning' : '' }}">
                            <td>{{ $mov['concepto'] }}</td>
                            <td>${{ number_format($mov['monto'], 2) }}</td>
                            <td>
                                @if($mov['tiene_comprobante'])
                                    <a href="{{ asset('storage/'.$mov['adjunto_path']) }}" target="_blank">
                                        Ver comprobante
                                    </a>
                                @else
                                    <span class="text-danger">Sin comprobante</span>
                                @endif
                            </td>
                        </tr>
                    @endforeach
                </table>

                {{-- Botones de acción --}}
                <div class="d-flex gap-2">
                    @can('approve-cash-funds')
                        <button wire:click="openRejectModal" class="btn btn-warning">
                            Rechazar y reabrir
                        </button>
                    @endcan

                    @can('close-cash-funds')
                        <button wire:click="openApproveModal" class="btn btn-success">
                            Aprobar y cerrar definitivamente
                        </button>
                    @endcan
                </div>
            </div>
        @else
            <p class="text-muted">Selecciona un fondo para ver detalles</p>
        @endif
    </div>
</div>

{{-- Modales de confirmación --}}
```

---

## 6. detail.blade.php

**Ruta:** `/cashfund/{id}/detail`
**Componente:** `App\Livewire\CashFund\Detail`

### Vista de Detalle (Solo Lectura)

```blade
<div class="py-3">
    {{-- Header para impresión --}}
    <div class="d-none d-print-block print-header">
        <h1>ESTADO DE CUENTA - FONDO DE CAJA CHICA</h1>
        <h2>Fondo #{{ $fondo['id'] }}</h2>
    </div>

    {{-- Contenido de 2 columnas --}}
    <div class="row">
        <div class="col-lg-8">
            {{-- Información general --}}
            {{-- Resumen financiero --}}
            {{-- Tabla de movimientos --}}
        </div>

        <div class="col-lg-4">
            {{-- Resultado del arqueo --}}
            {{-- Timeline de eventos --}}
        </div>
    </div>

    {{-- Botón de impresión --}}
    <button onclick="window.print()">
        <i class="fa-solid fa-print"></i> Imprimir
    </button>
</div>

{{-- Estilos para impresión --}}
@push('styles')
<style>
@media print {
    .btn, .sidebar, .top-bar, .timeline {
        display: none !important;
    }

    @page {
        margin: 1cm;
        size: letter;
    }

    .table {
        font-size: 8pt;
    }

    .table thead {
        background: #333 !important;
        color: white !important;
        -webkit-print-color-adjust: exact;
    }
}
</style>
@endpush
```

---

## 🎨 Componentes UI Reutilizables

### Toast Notifications

```blade
{{-- En el layout principal --}}
<script>
    Livewire.on('toast', (event) => {
        // Mostrar notificación Bootstrap Toast
        const toast = new bootstrap.Toast(document.getElementById('liveToast'));
        document.getElementById('toastBody').textContent = event.body;
        toast.show();
    });
</script>
```

### Loading States

```blade
<div wire:loading wire:target="save">
    <div class="spinner-border spinner-border-sm"></div>
    Guardando...
</div>
```

### Iconos de Estado

```blade
{{-- Comprobante --}}
@if($tiene_comprobante)
    <i class="fa-solid fa-circle-check text-success" title="Con comprobante"></i>
@else
    <i class="fa-solid fa-circle-xmark text-danger" title="Sin comprobante"></i>
@endif

{{-- Estado del movimiento --}}
@if($estatus === 'APROBADO')
    <span class="badge text-bg-success">Aprobado</span>
@elseif($estatus === 'POR_APROBAR')
    <span class="badge text-bg-warning">Por aprobar</span>
@else
    <span class="badge text-bg-danger">Rechazado</span>
@endif
```

---

## 📱 Responsive Design

### Breakpoints Bootstrap 5

- **xs:** < 576px (Mobile)
- **sm:** ≥ 576px (Mobile landscape)
- **md:** ≥ 768px (Tablet)
- **lg:** ≥ 992px (Desktop)
- **xl:** ≥ 1200px (Large desktop)

### Clases Útiles

```blade
{{-- Ocultar en móvil, mostrar en desktop --}}
<div class="d-none d-lg-block">Solo desktop</div>

{{-- Mostrar en móvil, ocultar en desktop --}}
<div class="d-lg-none">Solo móvil</div>

{{-- Columnas responsive --}}
<div class="col-12 col-md-6 col-lg-4">
    {{-- 100% móvil, 50% tablet, 33% desktop --}}
</div>
```
