# 08 - API Y MÉTODOS PÚBLICOS

## 📡 API Interna (Métodos Públicos)

El sistema no expone un API REST público, pero los componentes Livewire ofrecen métodos que funcionan como API interna.

---

## 🔷 CashFund Model

### Accessors (Atributos Calculados)

```php
// Obtener total de egresos
$fondo->total_egresos; // float

// Obtener total de reintegros
$fondo->total_reintegros; // float

// Obtener saldo disponible
$fondo->saldo_disponible; // float
```

### Relaciones

```php
// Obtener responsable del fondo
$fondo->responsable; // User

// Obtener creador del fondo
$fondo->createdBy; // User

// Obtener movimientos
$fondo->movements; // Collection<CashFundMovement>

// Obtener arqueo
$fondo->arqueo; // CashFundArqueo|null
```

### Métodos de Query

```php
// Fondos abiertos
CashFund::where('estado', 'ABIERTO')->get();

// Fondos de una sucursal
CashFund::where('sucursal_id', 19)->get();

// Fondos de un usuario
CashFund::where('responsable_user_id', Auth::id())->get();

// Fondos con eager loading
CashFund::with(['responsable', 'movements', 'arqueo'])->find($id);
```

---

## 🔷 CashFundMovement Model

### Relaciones

```php
// Obtener fondo
$movimiento->cashFund; // CashFund

// Obtener creador
$movimiento->createdBy; // User

// Obtener auditoría
$movimiento->auditLogs; // Collection<CashFundMovementAuditLog>
```

### Queries Comunes

```php
// Movimientos de un fondo
CashFundMovement::where('cash_fund_id', $fondoId)->get();

// Solo egresos
CashFundMovement::where('tipo', 'EGRESO')->get();

// Sin comprobante
CashFundMovement::where('tiene_comprobante', false)->get();

// Con usuario
CashFundMovement::with('createdBy')->find($id);
```

---

## 🔷 CashFundArqueo Model

### Accessor

```php
// Estado del arqueo
$arqueo->estado; // 'CUADRA', 'A_FAVOR', 'FALTANTE'
```

### Relaciones

```php
// Obtener fondo
$arqueo->cashFund; // CashFund

// Obtener creador
$arqueo->createdBy; // User
```

---

## 🔷 CashFundMovementAuditLog Model

### Método Estático

```php
// Registrar cambio
CashFundMovementAuditLog::logChange(
    movementId: 123,
    action: 'UPDATED',
    fieldChanged: 'monto',
    oldValue: 100.00,
    newValue: 150.00,
    observaciones: 'Corrección de monto según factura'
);
```

### Acciones Válidas

```php
const ACTIONS = [
    'CREATED',
    'UPDATED',
    'DELETED',
    'ATTACHMENT_ADDED',
    'ATTACHMENT_REMOVED',
    'ATTACHMENT_REPLACED',
];
```

### Queries

```php
// Historial de un movimiento
CashFundMovementAuditLog::where('movement_id', $movId)
    ->with('changedBy')
    ->orderBy('created_at', 'desc')
    ->get();

// Cambios por usuario
CashFundMovementAuditLog::where('changed_by_user_id', Auth::id())
    ->orderBy('created_at', 'desc')
    ->get();
```

---

## 🔷 Index Component

### Propiedades Públicas

```php
public string $search = '';
public string $estadoFilter = 'all';
```

### Métodos de Livewire

```php
// Actualizar búsqueda (wire:model.live)
// Se ejecuta automáticamente al escribir

// Actualizar filtro (wire:model.live)
// Se ejecuta automáticamente al cambiar select
```

---

## 🔷 Open Component

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
```

### Métodos Invocables

```php
// Guardar fondo (wire:click="save")
save(): void
```

---

## 🔷 Movements Component

### Propiedades Públicas

```php
public array $movimientoForm = [
    'tipo' => '',
    'concepto' => '',
    'proveedor_nombre' => '',
    'monto' => '',
    'metodo' => 'EFECTIVO',
];
public $archivo; // UploadedFile
```

### Métodos Invocables

```php
// Añadir movimiento
addMovimiento(): void

// Editar movimiento
editMovimiento(int $id): void

// Actualizar movimiento
updateMovimiento(): void

// Eliminar movimiento
deleteMovimiento(int $id): void

// Gestión de comprobantes
openAttachmentModal(int $id): void
uploadAttachment(): void
removeAttachment(): void
downloadAttachment(int $id): Response

// Auditoría
openAuditModal(int $id): void

// Navegación
realizarArqueo(): void
```

---

## 🔷 Arqueo Component

### Propiedades Públicas

```php
public array $arqueoForm = [
    'efectivo_contado' => '',
    'observaciones' => '',
];
```

### Métodos Invocables

```php
// Abrir modal de confirmación
openConfirmModal(): void

// Guardar arqueo
guardarArqueo(): void
```

---

## 🔷 Approvals Component

### Métodos Invocables

```php
// Seleccionar fondo para revisión
selectFondo(int $id): void

// Rechazar fondo
openRejectModal(): void
rejectFund(): void

// Aprobar fondo
openApproveModal(): void
approveFund(): void
```

---

## 🔷 Detail Component

### Métodos Invocables

```php
// Descargar comprobante
downloadAttachment(int $movementId): Response
```

---

## 📊 Ejemplos de Uso

### Obtener Saldo Actual de un Fondo

```php
$fondo = CashFund::find($id);
$saldo = $fondo->saldo_disponible;

// Con desglose
$montoInicial = $fondo->monto_inicial;
$egresos = $fondo->total_egresos;
$reintegros = $fondo->total_reintegros;
$saldo = $montoInicial - $egresos + $reintegros;
```

---

### Obtener Historial Completo de un Movimiento

```php
$movimiento = CashFundMovement::with(['auditLogs.changedBy'])->find($id);

foreach ($movimiento->auditLogs as $log) {
    echo "{$log->created_at}: {$log->action} por {$log->changedBy->nombre_completo}\n";
    if ($log->field_changed) {
        echo "  {$log->field_changed}: {$log->old_value} → {$log->new_value}\n";
    }
}
```

---

### Validar si Fondo Puede Cerrarse

```php
$fondo = CashFund::with('movements')->find($id);

// Verificar estado
if ($fondo->estado !== 'EN_REVISION') {
    return 'El fondo debe estar en revisión';
}

// Verificar movimientos sin comprobante
$sinComprobante = $fondo->movements()
    ->where('tiene_comprobante', false)
    ->where('estatus', 'POR_APROBAR')
    ->count();

if ($sinComprobante > 0) {
    return "Hay {$sinComprobante} movimientos sin comprobante";
}

// Puede cerrarse
return true;
```

---

### Calcular Métricas de un Período

```php
// Fondos del mes actual
$fondos = CashFund::whereMonth('fecha', now()->month)
    ->whereYear('fecha', now()->year)
    ->get();

// Total movido en el mes
$totalEgresos = $fondos->sum('total_egresos');
$totalReintegros = $fondos->sum('total_reintegros');

// Promedio de egresos por fondo
$promedioEgresos = $fondos->avg('total_egresos');

// Fondos con diferencias
$conDiferencias = $fondos->filter(function($fondo) {
    return $fondo->arqueo && abs($fondo->arqueo->diferencia) > 0.01;
})->count();
```

---

### Generar Reporte de Proveedores

```php
$movimientos = CashFundMovement::where('tipo', 'EGRESO')
    ->whereNotNull('proveedor_nombre')
    ->whereHas('cashFund', function($q) {
        $q->whereMonth('fecha', now()->month);
    })
    ->get();

$porProveedor = $movimientos->groupBy('proveedor_nombre')
    ->map(function($grupo) {
        return [
            'total' => $grupo->sum('monto'),
            'cantidad' => $grupo->count(),
        ];
    })
    ->sortByDesc('total');
```

---

## 🔐 Seguridad en Métodos

### Validación de Permisos

Todos los métodos sensibles validan permisos:

```php
public function approveFund()
{
    if (!Auth::user()->can('close-cash-funds')) {
        abort(403, 'No autorizado');
    }

    // Proceder...
}
```

### Validación de Estado

```php
public function addMovimiento()
{
    if ($this->fondo->estado !== 'ABIERTO') {
        $this->dispatch('toast',
            type: 'error',
            body: 'El fondo no está abierto'
        );
        return;
    }

    // Proceder...
}
```

### Validación de Propietario

```php
public function editMovimiento($id)
{
    $movimiento = CashFundMovement::find($id);

    if ($movimiento->cashFund->responsable_user_id !== Auth::id()) {
        abort(403, 'No eres el responsable de este fondo');
    }

    // Proceder...
}
```

---

## 📝 Convenciones de Respuesta

### Toast Notifications

```php
// Éxito
$this->dispatch('toast',
    type: 'success',
    body: 'Operación exitosa'
);

// Error
$this->dispatch('toast',
    type: 'error',
    body: 'Ocurrió un error'
);

// Advertencia
$this->dispatch('toast',
    type: 'warning',
    body: 'Ten cuidado'
);

// Info
$this->dispatch('toast',
    type: 'info',
    body: 'Información relevante'
);
```

### Redirecciones

```php
// Con mensaje flash
return redirect()
    ->route('cashfund.movements', ['id' => $fondoId])
    ->with('success', 'Fondo abierto correctamente');

// Desde Livewire
return redirect()->route('cashfund.index');
```

---

## 🧪 Testing (Futuro)

### Ejemplo de Test de Método

```php
/** @test */
public function puede_calcular_saldo_disponible()
{
    $fondo = CashFund::factory()->create([
        'monto_inicial' => 5000.00
    ]);

    CashFundMovement::factory()->create([
        'cash_fund_id' => $fondo->id,
        'tipo' => 'EGRESO',
        'monto' => 250.00
    ]);

    CashFundMovement::factory()->create([
        'cash_fund_id' => $fondo->id,
        'tipo' => 'REINTEGRO',
        'monto' => 50.00
    ]);

    $this->assertEquals(4800.00, $fondo->fresh()->saldo_disponible);
}
```
