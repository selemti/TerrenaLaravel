# 04 - COMPONENTES LIVEWIRE

## 📦 Componentes del Sistema

El sistema cuenta con 6 componentes Livewire que manejan la lógica de negocio y la interactividad:

1. **Index** - Listado de fondos
2. **Open** - Apertura de fondos
3. **Movements** - Gestión de movimientos
4. **Arqueo** - Conciliación
5. **Approvals** - Aprobaciones
6. **Detail** - Vista de detalle

---

## 1. Index Component

**Archivo:** `app/Livewire/CashFund/Index.php`
**Vista:** `resources/views/livewire/cash-fund/index.blade.php`
**Ruta:** `/cashfund`

### Propósito
Lista todos los fondos de caja chica con filtros y búsqueda.

### Propiedades Públicas
```php
public string $search = '';        // Búsqueda por #fondo, sucursal, usuario
public string $estadoFilter = 'all'; // Filtro por estado
```

### Métodos Principales
- `render()`: Renderiza la lista con paginación
- `updatingSearch()`: Reset paginación al buscar
- `updatedEstadoFilter()`: Reset paginación al filtrar

### Características
- ✅ Paginación (20 por página)
- ✅ Búsqueda en tiempo real
- ✅ Filtro por estado
- ✅ Botón "Abrir fondo"
- ✅ Botón "Aprobaciones" (con permiso)
- ✅ Acciones condicionales según estado

---

## 2. Open Component

**Archivo:** `app/Livewire/CashFund/Open.php`
**Vista:** `resources/views/livewire/cash-fund/open.blade.php`
**Ruta:** `/cashfund/open`

### Propósito
Formulario para abrir un nuevo fondo de caja chica.

### Propiedades Públicas
```php
public array $form = [
    'sucursal_id' => null,
    'fecha' => '',
    'monto_inicial' => '',
    'moneda' => 'MXN',
    'descripcion' => '',
    'responsable_user_id' => null,
];
public array $sucursales = [];
public array $usuarios = [];
public bool $loading = false;
```

### Métodos Principales
- `mount()`: Inicializa formulario con valores por defecto
- `save()`: Crea el fondo y redirige a Movements
- `loadSucursales()`: Carga catálogo de sucursales
- `loadUsuarios()`: Carga lista de usuarios
- `rules()`: Reglas de validación
- `messages()`: Mensajes de error personalizados

### Validaciones
```php
'form.sucursal_id' => 'required|integer'
'form.fecha' => 'required|date|before_or_equal:today'
'form.monto_inicial' => 'required|numeric|min:0.01|max:999999.99'
'form.moneda' => 'required|in:MXN,USD'
'form.descripcion' => 'nullable|string|max:255'
'form.responsable_user_id' => 'required|exists:users,id'
```

---

## 3. Movements Component

**Archivo:** `app/Livewire/CashFund/Movements.php`
**Vista:** `resources/views/livewire/cash-fund/movements.blade.php`
**Ruta:** `/cashfund/{id}/movements`

### Propósito
Gestión completa de movimientos: crear, editar, eliminar, adjuntar comprobantes, ver auditoría.

### Propiedades Públicas
```php
public string $fondoId;
public ?CashFund $fondo = null;
public array $movimientoForm = [
    'tipo' => '',
    'concepto' => '',
    'proveedor_nombre' => '',
    'monto' => '',
    'metodo' => 'EFECTIVO',
];
public ?int $editingMovementId = null;
public ?int $attachmentMovementId = null;
public ?int $auditMovementId = null;
public bool $showEditModal = false;
public bool $showAttachmentModal = false;
public bool $showAuditModal = false;
public $archivo; // Para upload
```

### Métodos Principales

**Gestión de Movimientos:**
- `addMovimiento()`: Añadir nuevo movimiento
- `editMovimiento($id)`: Abrir modal de edición
- `updateMovimiento()`: Guardar cambios
- `deleteMovimiento($id)`: Eliminar movimiento

**Gestión de Comprobantes:**
- `openAttachmentModal($id)`: Abrir modal adjuntos
- `uploadAttachment()`: Subir nuevo archivo
- `removeAttachment()`: Eliminar archivo
- `downloadAttachment($id)`: Descargar archivo

**Auditoría:**
- `openAuditModal($id)`: Ver historial de cambios

**Navegación:**
- `realizarArqueo()`: Ir a página de arqueo

### Validaciones Dinámicas
```php
protected function rules(): array
{
    $rules = [
        'movimientoForm.tipo' => 'required|in:EGRESO,REINTEGRO,DEPOSITO',
        'movimientoForm.concepto' => 'required|string|min:3|max:500',
        'movimientoForm.monto' => 'required|numeric|min:0.01|max:999999.99',
        'movimientoForm.metodo' => 'required|in:EFECTIVO,TRANSFER',
    ];

    // Proveedor solo requerido para EGRESO
    if ($this->movimientoForm['tipo'] === 'EGRESO') {
        $rules['movimientoForm.proveedor_nombre'] = 'required|string|max:255';
    }

    // Archivo solo si hay upload
    if ($this->archivo) {
        $rules['archivo'] = 'file|mimes:pdf,jpg,jpeg,png|max:10240';
    }

    return $rules;
}
```

---

## 4. Arqueo Component

**Archivo:** `app/Livewire/CashFund/Arqueo.php`
**Vista:** `resources/views/livewire/cash-fund/arqueo.blade.php`
**Ruta:** `/cashfund/{id}/arqueo`

### Propósito
Realizar el arqueo (conciliación) del efectivo físico vs. saldo teórico.

### Propiedades Públicas
```php
public string $fondoId;
public ?CashFund $fondo = null;
public array $arqueoForm = [
    'efectivo_contado' => '',
    'observaciones' => '',
];
public bool $showConfirmModal = false;
public bool $loading = false;
```

### Métodos Principales
- `mount($id)`: Cargar fondo y validar estado
- `calcularDiferencia()`: Calcular diferencia en tiempo real
- `openConfirmModal()`: Abrir modal de confirmación
- `guardarArqueo()`: Guardar arqueo y cambiar estado

### Flujo
1. Mostrar saldo teórico calculado
2. Usuario ingresa efectivo contado
3. Calcular diferencia automáticamente
4. Validar y confirmar
5. Crear/actualizar registro de arqueo
6. Cambiar estado del fondo a EN_REVISION
7. Redirigir a Movements

---

## 5. Approvals Component

**Archivo:** `app/Livewire/CashFund/Approvals.php`
**Vista:** `resources/views/livewire/cash-fund/approvals.blade.php`
**Ruta:** `/cashfund/approvals`

### Propósito
Revisión y aprobación/rechazo de fondos en estado EN_REVISION.

### Propiedades Públicas
```php
public ?int $selectedFondoId = null;
public ?CashFund $selectedFondo = null;
public bool $showDetailModal = false;
public bool $showRejectModal = false;
public bool $showApproveModal = false;
public string $rejectReason = '';
```

### Métodos Principales
- `selectFondo($id)`: Seleccionar fondo para revisión
- `openRejectModal()`: Abrir modal de rechazo
- `rejectFund()`: Rechazar y reabrir fondo
- `openApproveModal()`: Abrir modal de aprobación
- `approveFund()`: Aprobar y cerrar definitivamente

### Validaciones de Negocio
```php
public function approveFund(): void
{
    // Validar permisos
    if (!Auth::user()->can('close-cash-funds')) {
        // Error
        return;
    }

    // Validar movimientos pendientes
    $movimientosPendientes = $this->selectedFondo->movements()
        ->where('tiene_comprobante', false)
        ->where('estatus', 'POR_APROBAR')
        ->count();

    if ($movimientosPendientes > 0) {
        // Error: hay movimientos sin comprobante
        return;
    }

    // Aprobar y cerrar
    DB::transaction(function () {
        $this->selectedFondo->update([
            'estado' => 'CERRADO',
            'closed_at' => now(),
        ]);

        // Aprobar todos los movimientos
        $this->selectedFondo->movements()->update([
            'estatus' => 'APROBADO'
        ]);
    });
}
```

---

## 6. Detail Component

**Archivo:** `app/Livewire/CashFund/Detail.php`
**Vista:** `resources/views/livewire/cash-fund/detail.blade.php`
**Ruta:** `/cashfund/{id}/detail`

### Propósito
Vista de solo lectura con información completa del fondo, ideal para fondos cerrados.

### Propiedades Públicas
```php
public string $fondoId;
public ?CashFund $fondo = null;
```

### Métodos Principales
- `mount($id)`: Cargar fondo con todas sus relaciones
- `downloadAttachment($id)`: Descargar comprobante
- `buildTimeline()`: Construir línea de tiempo de eventos
- `render()`: Pasar todos los datos calculados a la vista

### Datos Calculados
- Información general del fondo
- Resumen financiero (egresos, reintegros, saldo)
- Lista de movimientos con detalles
- Resúmenes por tipo y método
- Resultado del arqueo
- Timeline de eventos

### Timeline de Eventos
1. Apertura del fondo
2. Cada movimiento registrado
3. Arqueo realizado
4. Cierre definitivo

---

## 🎨 Características Comunes

### Toasts (Notificaciones)
```php
$this->dispatch('toast',
    type: 'success',  // success, error, warning, info
    body: 'Mensaje para el usuario'
);
```

### Confirmaciones
Todos los componentes usan modales Bootstrap para confirmaciones críticas:
- Eliminar movimiento
- Guardar arqueo
- Aprobar fondo
- Rechazar fondo

### Transacciones de BD
Operaciones críticas se envuelven en transacciones:
```php
DB::transaction(function () {
    // Operaciones atómicas
});
```

### Validación en Tiempo Real
Livewire `wire:model.live` para validación instantánea:
```blade
<input type="number" wire:model.live="arqueoForm.efectivo_contado">
```

### Loading States
```php
public bool $loading = false;

// En el método
$this->loading = true;
try {
    // Operación
} finally {
    $this->loading = false;
}
```

---

## 🔐 Seguridad en Componentes

### Validación de Permisos
```php
public function mount()
{
    if (!Auth::user()->can('approve-cash-funds')) {
        abort(403, 'No autorizado');
    }
}
```

### Validación de Estado
```php
if ($this->fondo->estado !== 'ABIERTO') {
    $this->dispatch('toast',
        type: 'error',
        body: 'El fondo ya no está abierto'
    );
    return;
}
```

### Validación de Propietario
```php
if ($this->fondo->responsable_user_id !== Auth::id() && !Auth::user()->hasRole('admin')) {
    abort(403, 'No eres el responsable de este fondo');
}
```
