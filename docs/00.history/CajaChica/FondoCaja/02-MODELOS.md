# 02 - MODELOS ELOQUENT

## 📚 Modelos del Sistema

El sistema utiliza 4 modelos principales que representan las entidades del negocio:

1. **CashFund** - Fondo de caja chica
2. **CashFundMovement** - Movimientos del fondo
3. **CashFundArqueo** - Arqueo/conciliación
4. **CashFundMovementAuditLog** - Auditoría de cambios

---

## 1. CashFund

**Archivo:** `app/Models/CashFund.php`
**Tabla:** `selemti.cash_funds`

### Propósito
Representa un fondo de caja chica diario asignado a una sucursal y responsable específico.

### Propiedades

```php
protected $connection = 'pgsql';
protected $table = 'selemti.cash_funds';

protected $fillable = [
    'sucursal_id',
    'fecha',
    'monto_inicial',
    'moneda',
    'descripcion',
    'estado',
    'responsable_user_id',
    'created_by_user_id',
    'closed_at',
];

protected $casts = [
    'fecha' => 'date',
    'monto_inicial' => 'decimal:2',
    'closed_at' => 'datetime',
];
```

### Campos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | bigserial | ID autoincremental |
| `sucursal_id` | integer | FK a `selemti.cat_sucursales` |
| `fecha` | date | Fecha del fondo |
| `monto_inicial` | decimal(12,2) | Monto en efectivo inicial |
| `moneda` | varchar(3) | MXN o USD |
| `descripcion` | varchar(255) | Nombre/descripción opcional |
| `estado` | varchar(20) | ABIERTO, EN_REVISION, CERRADO |
| `responsable_user_id` | integer | FK a `users.id` |
| `created_by_user_id` | integer | FK a `users.id` |
| `closed_at` | timestamp | Fecha de cierre definitivo |
| `created_at` | timestamp | Fecha de creación |
| `updated_at` | timestamp | Última modificación |

### Relaciones

```php
// Usuario responsable del fondo
public function responsable(): BelongsTo
{
    return $this->belongsTo(User::class, 'responsable_user_id');
}

// Usuario que creó el fondo
public function createdBy(): BelongsTo
{
    return $this->belongsTo(User::class, 'created_by_user_id');
}

// Movimientos del fondo
public function movements(): HasMany
{
    return $this->hasMany(CashFundMovement::class, 'cash_fund_id');
}

// Arqueo del fondo
public function arqueo(): HasOne
{
    return $this->hasOne(CashFundArqueo::class, 'cash_fund_id');
}
```

### Atributos Calculados (Accessors)

```php
// Total de egresos
public function getTotalEgresosAttribute(): float
{
    return $this->movements()
        ->where('tipo', 'EGRESO')
        ->sum('monto');
}

// Total de reintegros y depósitos
public function getTotalReintegrosAttribute(): float
{
    return $this->movements()
        ->whereIn('tipo', ['REINTEGRO', 'DEPOSITO'])
        ->sum('monto');
}

// Saldo disponible (calculado)
public function getSaldoDisponibleAttribute(): float
{
    return $this->monto_inicial
        - $this->total_egresos
        + $this->total_reintegros;
}
```

### Uso

```php
// Crear un fondo
$fondo = CashFund::create([
    'sucursal_id' => 19,
    'fecha' => '2025-10-23',
    'monto_inicial' => 5000.00,
    'moneda' => 'MXN',
    'descripcion' => 'Fondo semana 42',
    'estado' => 'ABIERTO',
    'responsable_user_id' => 2,
    'created_by_user_id' => Auth::id(),
]);

// Obtener saldo disponible
$saldo = $fondo->saldo_disponible; // Atributo calculado

// Cargar relaciones
$fondo = CashFund::with(['responsable', 'movements'])->find(1);

// Filtrar por estado
$abiertos = CashFund::where('estado', 'ABIERTO')->get();
```

---

## 2. CashFundMovement

**Archivo:** `app/Models/CashFundMovement.php`
**Tabla:** `selemti.cash_fund_movements`

### Propósito
Representa un movimiento (egreso, reintegro o depósito) dentro de un fondo de caja chica.

### Propiedades

```php
protected $connection = 'pgsql';
protected $table = 'selemti.cash_fund_movements';

protected $fillable = [
    'cash_fund_id',
    'tipo',
    'concepto',
    'proveedor_nombre',
    'monto',
    'metodo',
    'tiene_comprobante',
    'adjunto_path',
    'estatus',
    'created_by_user_id',
];

protected $casts = [
    'monto' => 'decimal:2',
    'tiene_comprobante' => 'boolean',
];
```

### Campos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | bigserial | ID autoincremental |
| `cash_fund_id` | bigint | FK a `cash_funds.id` |
| `tipo` | varchar(20) | EGRESO, REINTEGRO, DEPOSITO |
| `concepto` | text | Descripción del movimiento |
| `proveedor_nombre` | varchar(255) | Nombre del proveedor (opcional) |
| `monto` | decimal(12,2) | Monto del movimiento |
| `metodo` | varchar(20) | EFECTIVO o TRANSFER |
| `tiene_comprobante` | boolean | Indica si tiene adjunto |
| `adjunto_path` | varchar(500) | Ruta del archivo adjunto |
| `estatus` | varchar(20) | POR_APROBAR, APROBADO, RECHAZADO |
| `created_by_user_id` | integer | FK a `users.id` |
| `created_at` | timestamp | Fecha de creación |
| `updated_at` | timestamp | Última modificación |

### Relaciones

```php
// Fondo al que pertenece
public function cashFund(): BelongsTo
{
    return $this->belongsTo(CashFund::class, 'cash_fund_id');
}

// Usuario que creó el movimiento
public function createdBy(): BelongsTo
{
    return $this->belongsTo(User::class, 'created_by_user_id');
}

// Auditoría de cambios
public function auditLogs(): HasMany
{
    return $this->hasMany(CashFundMovementAuditLog::class, 'movement_id');
}
```

### Uso

```php
// Crear un movimiento
$movimiento = CashFundMovement::create([
    'cash_fund_id' => $fondoId,
    'tipo' => 'EGRESO',
    'concepto' => 'Compra de verduras',
    'proveedor_nombre' => 'Verdulería El Huerto',
    'monto' => 250.50,
    'metodo' => 'EFECTIVO',
    'tiene_comprobante' => true,
    'adjunto_path' => 'cash_fund_attachments/1/2/1729721234_factura.pdf',
    'estatus' => 'POR_APROBAR',
    'created_by_user_id' => Auth::id(),
]);

// Obtener movimientos de un fondo
$movimientos = CashFundMovement::where('cash_fund_id', $fondoId)
    ->orderBy('created_at', 'desc')
    ->get();

// Con relaciones
$movimiento = CashFundMovement::with(['createdBy', 'auditLogs'])->find(1);
```

---

## 3. CashFundArqueo

**Archivo:** `app/Models/CashFundArqueo.php`
**Tabla:** `selemti.cash_fund_arqueos`

### Propósito
Representa el arqueo (conciliación) de efectivo físico vs. saldo teórico al cierre del día.

### Propiedades

```php
protected $connection = 'pgsql';
protected $table = 'selemti.cash_fund_arqueos';

protected $fillable = [
    'cash_fund_id',
    'monto_esperado',
    'monto_contado',
    'diferencia',
    'observaciones',
    'created_by_user_id',
];

protected $casts = [
    'monto_esperado' => 'decimal:2',
    'monto_contado' => 'decimal:2',
    'diferencia' => 'decimal:2',
];
```

### Campos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | bigserial | ID autoincremental |
| `cash_fund_id` | bigint | FK a `cash_funds.id` (UNIQUE) |
| `monto_esperado` | decimal(12,2) | Saldo teórico calculado |
| `monto_contado` | decimal(12,2) | Efectivo físico contado |
| `diferencia` | decimal(12,2) | monto_contado - monto_esperado |
| `observaciones` | text | Notas sobre la diferencia |
| `created_by_user_id` | integer | FK a `users.id` |
| `created_at` | timestamp | Fecha del arqueo |
| `updated_at` | timestamp | Última modificación |

### Relaciones

```php
// Fondo al que pertenece
public function cashFund(): BelongsTo
{
    return $this->belongsTo(CashFund::class, 'cash_fund_id');
}

// Usuario que realizó el arqueo
public function createdBy(): BelongsTo
{
    return $this->belongsTo(User::class, 'created_by_user_id');
}
```

### Atributos Calculados

```php
// Estado del arqueo
public function getEstadoAttribute(): string
{
    if (abs($this->diferencia) < 0.01) {
        return 'CUADRA';
    }
    return $this->diferencia > 0 ? 'A_FAVOR' : 'FALTANTE';
}
```

### Uso

```php
// Crear/actualizar arqueo
$arqueo = CashFundArqueo::updateOrCreate(
    ['cash_fund_id' => $fondoId],
    [
        'monto_esperado' => 4750.50,
        'monto_contado' => 4750.00,
        'diferencia' => -0.50,
        'observaciones' => 'Faltante menor, moneda de 50 centavos',
        'created_by_user_id' => Auth::id(),
    ]
);

// Verificar si cuadra
if ($arqueo->estado === 'CUADRA') {
    // Perfecto
}

// Obtener arqueo de un fondo
$arqueo = CashFundArqueo::where('cash_fund_id', $fondoId)->first();
```

---

## 4. CashFundMovementAuditLog

**Archivo:** `app/Models/CashFundMovementAuditLog.php`
**Tabla:** `selemti.cash_fund_movement_audit_log`

### Propósito
Registra todos los cambios realizados en los movimientos para trazabilidad completa.

### Propiedades

```php
protected $connection = 'pgsql';
protected $table = 'selemti.cash_fund_movement_audit_log';

protected $fillable = [
    'movement_id',
    'action',
    'field_changed',
    'old_value',
    'new_value',
    'observaciones',
    'changed_by_user_id',
];

public $timestamps = false; // Solo created_at
```

### Campos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | bigserial | ID autoincremental |
| `movement_id` | bigint | FK a `cash_fund_movements.id` |
| `action` | varchar(50) | CREATED, UPDATED, DELETED, ATTACHMENT_* |
| `field_changed` | varchar(100) | Campo modificado |
| `old_value` | text | Valor anterior |
| `new_value` | text | Valor nuevo |
| `observaciones` | text | Notas adicionales |
| `changed_by_user_id` | integer | FK a `users.id` |
| `created_at` | timestamp | Momento del cambio |

### Relaciones

```php
// Movimiento auditado
public function movement(): BelongsTo
{
    return $this->belongsTo(CashFundMovement::class, 'movement_id');
}

// Usuario que hizo el cambio
public function changedBy(): BelongsTo
{
    return $this->belongsTo(User::class, 'changed_by_user_id');
}
```

### Método Estático

```php
/**
 * Registrar un cambio en el log de auditoría
 */
public static function logChange(
    int $movementId,
    string $action,
    ?string $fieldChanged = null,
    $oldValue = null,
    $newValue = null,
    ?string $observaciones = null
): void {
    self::create([
        'movement_id' => $movementId,
        'action' => $action,
        'field_changed' => $fieldChanged,
        'old_value' => $oldValue !== null ? (string) $oldValue : null,
        'new_value' => $newValue !== null ? (string) $newValue : null,
        'observaciones' => $observaciones,
        'changed_by_user_id' => Auth::id(),
    ]);
}
```

### Acciones Soportadas

| Acción | Descripción |
|--------|-------------|
| `CREATED` | Movimiento creado |
| `UPDATED` | Campo modificado |
| `DELETED` | Movimiento eliminado |
| `ATTACHMENT_ADDED` | Comprobante añadido |
| `ATTACHMENT_REMOVED` | Comprobante eliminado |
| `ATTACHMENT_REPLACED` | Comprobante reemplazado |

### Uso

```php
// Registrar creación
CashFundMovementAuditLog::logChange(
    movementId: $movimiento->id,
    action: 'CREATED',
    observaciones: 'Movimiento creado exitosamente'
);

// Registrar cambio de monto
CashFundMovementAuditLog::logChange(
    movementId: $movimiento->id,
    action: 'UPDATED',
    fieldChanged: 'monto',
    oldValue: 100.00,
    newValue: 150.00,
    observaciones: 'Corrección de monto'
);

// Obtener historial de un movimiento
$historial = CashFundMovementAuditLog::where('movement_id', $movimientoId)
    ->with('changedBy')
    ->orderBy('created_at', 'desc')
    ->get();
```

---

## 🔗 Diagrama de Relaciones

```
┌─────────────────┐
│   CashFund      │
├─────────────────┤
│ id (PK)         │◄──────┐
│ sucursal_id     │       │
│ responsable_id  │───┐   │
│ created_by_id   │───┤   │
│ estado          │   │   │
└─────────────────┘   │   │
         │            │   │
         │ 1:N        │   │
         ▼            │   │
┌─────────────────┐   │   │
│ CashFundMovement│   │   │
├─────────────────┤   │   │
│ id (PK)         │   │   │
│ cash_fund_id(FK)│───┘   │
│ created_by_id   │───┤   │
│ tipo            │   │   │
│ monto           │   │   │
└─────────────────┘   │   │
         │            │   │
         │ 1:N        │   │
         ▼            │   │
┌──────────────────┐  │   │
│ AuditLog         │  │   │
├──────────────────┤  │   │
│ id (PK)          │  │   │
│ movement_id (FK) │──┘   │
│ changed_by_id    │──────┤
│ action           │      │
│ old_value        │      │
│ new_value        │      │
└──────────────────┘      │
                          │
┌─────────────────┐       │
│ CashFundArqueo  │       │
├─────────────────┤       │
│ id (PK)         │       │
│ cash_fund_id(FK)│───────┘
│ created_by_id   │───┐
│ monto_esperado  │   │
│ monto_contado   │   │
│ diferencia      │   │
└─────────────────┘   │
                      │
                      ▼
              ┌───────────┐
              │   User    │
              ├───────────┤
              │ id (PK)   │
              │ name      │
              │ email     │
              └───────────┘
```

---

## 📝 Convenciones de Nomenclatura

### Estados
- **ABIERTO:** Fondo activo, se pueden registrar movimientos
- **EN_REVISION:** Arqueo realizado, pendiente de aprobación
- **CERRADO:** Fondo cerrado definitivamente, solo lectura

### Tipos de Movimiento
- **EGRESO:** Salida de dinero del fondo
- **REINTEGRO:** Devolución de dinero al fondo
- **DEPOSITO:** Adición de dinero al fondo

### Métodos de Pago
- **EFECTIVO:** Pago en efectivo
- **TRANSFER:** Transferencia bancaria

### Estatus de Movimiento
- **POR_APROBAR:** Pendiente de revisión
- **APROBADO:** Aprobado por gerente/autorizado
- **RECHAZADO:** Rechazado, requiere corrección
