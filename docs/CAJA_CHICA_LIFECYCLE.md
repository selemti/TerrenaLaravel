# Ciclo de Vida del Sistema de Caja Chica

## Resumen

El sistema de Caja Chica (Petty Cash) permite gestionar fondos diarios para gastos menores. Este documento explica el flujo completo desde la apertura hasta el cierre del fondo, con **persistencia real en base de datos**.

## Base de Datos

### Tablas Creadas

1. **`cash_funds`** - Fondos de caja chica
   - `id` - ID del fondo
   - `sucursal_id` - Sucursal (FK a selemti.cat_sucursales en PostgreSQL)
   - `fecha` - Fecha del fondo
   - `monto_inicial` - Monto con el que inicia el fondo
   - `moneda` - MXN o USD
   - `estado` - ABIERTO / EN_REVISION / CERRADO
   - `responsable_user_id` - Usuario responsable del fondo
   - `created_by_user_id` - Usuario que creó el fondo
   - `closed_at` - Fecha/hora de cierre
   - `created_at`, `updated_at`

2. **`cash_fund_movements`** - Movimientos del fondo
   - `id` - ID del movimiento
   - `cash_fund_id` - FK al fondo
   - `tipo` - EGRESO / REINTEGRO / DEPOSITO
   - `concepto` - Descripción del movimiento
   - `proveedor_id` - Proveedor asociado (opcional, FK a selemti.cat_proveedores)
   - `monto` - Cantidad del movimiento
   - `metodo` - EFECTIVO / TRANSFER
   - `estatus` - APROBADO / POR_APROBAR / RECHAZADO
   - `requiere_comprobante` - Boolean
   - `tiene_comprobante` - Boolean
   - `adjunto_path` - Ruta del archivo adjunto
   - `created_by_user_id` - Usuario que creó el movimiento
   - `approved_by_user_id` - Usuario que aprobó (si aplica)
   - `approved_at` - Fecha de aprobación
   - `created_at`, `updated_at`

3. **`cash_fund_arqueos`** - Arqueos (conteo físico)
   - `id` - ID del arqueo
   - `cash_fund_id` - FK al fondo (UNIQUE - un fondo solo tiene un arqueo)
   - `monto_esperado` - Saldo teórico calculado
   - `monto_contado` - Efectivo físico contado
   - `diferencia` - Diferencia (contado - esperado)
   - `observaciones` - Notas sobre el arqueo
   - `created_by_user_id` - Usuario que realizó el arqueo
   - `created_at`, `updated_at`

## Flujo Completo

### 1. Apertura de Fondo (Estado: ABIERTO)

**Componente:** `app/Livewire/CashFund/Open.php`
**Ruta:** `/cashfund/open`
**Vista:** `resources/views/livewire/cash-fund/open.blade.php`

**Proceso:**
1. Usuario selecciona:
   - Sucursal
   - Fecha (no puede ser futura)
   - Monto inicial
   - Moneda (MXN/USD)
   - Responsable del fondo
2. Sistema guarda en `cash_funds` con estado `ABIERTO`
3. Redirige a pantalla de Movimientos

**Validaciones:**
- Sucursal obligatoria
- Fecha no puede ser futura
- Monto inicial > 0
- Responsable obligatorio (debe existir en `users`)

### 2. Registro de Movimientos (Estado: ABIERTO)

**Componente:** `app/Livewire/CashFund/Movements.php`
**Ruta:** `/cashfund/{id}/movements`
**Vista:** `resources/views/livewire/cash-fund/movements.blade.php`

**Proceso:**
1. Solo disponible si fondo está `ABIERTO`
2. Usuario puede registrar movimientos:
   - **EGRESO**: Salida de efectivo (gasto)
   - **REINTEGRO**: Devolución de efectivo no utilizado
   - **DEPOSITO**: Aporte adicional al fondo
3. Cada movimiento requiere:
   - Tipo
   - Concepto (mínimo 5 caracteres)
   - Monto
   - Método (Efectivo / Transferencia)
   - Proveedor (opcional)
   - Comprobante (opcional - archivo PDF/JPG/PNG máx 5MB)
   - Switch "Requiere aprobación" para egresos sin comprobante
4. Sistema guarda en `cash_fund_movements`
5. Si no hay comprobante y se marcó "Requiere aprobación": estatus = `POR_APROBAR`
6. Si hay comprobante o no se requiere aprobación: estatus = `APROBADO`

**Validaciones en Tiempo Real:**
- Botón "Nuevo movimiento" deshabilitado si estado != ABIERTO
- No se pueden agregar movimientos si fondo está EN_REVISION o CERRADO
- Al intentar guardar, verifica nuevamente que fondo esté ABIERTO

**Cálculos Dinámicos:**
```php
Saldo Disponible = Monto Inicial - Total Egresos + Total Reintegros
Porcentaje Egresado = (Total Egresos / Monto Inicial) × 100
```

### 3. Arqueo y Cierre (Estado: ABIERTO → EN_REVISION)

**Componente:** `app/Livewire/CashFund/Arqueo.php`
**Ruta:** `/cashfund/{id}/arqueo`
**Vista:** `resources/views/livewire/cash-fund/arqueo.blade.php`

**Proceso:**
1. Solo disponible si fondo está `ABIERTO`
2. Usuario cuenta efectivo físico y registra:
   - Monto contado
   - Observaciones (opcional)
3. Sistema calcula:
   - Saldo teórico = Monto Inicial - Egresos + Reintegros
   - Diferencia = Efectivo Contado - Saldo Teórico
4. Sistema guarda en `cash_fund_arqueos`
5. **Cambia estado del fondo a `EN_REVISION`**
6. Redirige a Movimientos (ahora en modo solo lectura)

**Estados de Diferencia:**
- **CUADRA**: |diferencia| < 0.01 (prácticamente cero)
- **A_FAVOR**: diferencia > 0 (sobra dinero)
- **EN_CONTRA**: diferencia < 0 (falta dinero)

**Validaciones:**
- Solo se puede hacer arqueo una vez por fondo (constraint UNIQUE en BD)
- Efectivo contado >= 0
- Observaciones máximo 500 caracteres

### 4. Cierre Final (Estado: EN_REVISION → CERRADO)

**Pendiente de implementar en futuro componente `Approvals`**

El fondo en estado `EN_REVISION` requeriría aprobación de gerencia para:
- Revisar diferencias (si las hay)
- Aprobar/rechazar movimientos sin comprobante
- Cerrar definitivamente el fondo (estado `CERRADO`)

Por ahora, fondos quedan en `EN_REVISION` hasta implementar módulo de aprobaciones.

## Estados del Fondo

| Estado | Descripción | Acciones Permitidas |
|--------|-------------|---------------------|
| **ABIERTO** | Fondo activo para el día | ✅ Agregar movimientos<br>✅ Realizar arqueo |
| **EN_REVISION** | Arqueo realizado, pendiente de aprobación | ❌ No se pueden agregar movimientos<br>❌ No se puede realizar arqueo<br>👁️ Solo lectura |
| **CERRADO** | Fondo cerrado definitivamente | 🔒 Solo lectura, no se puede modificar |

## Validaciones de Estado en UI

### Componente: Index
- Muestra todos los fondos con su estado
- Badge de color según estado (Verde=ABIERTO, Amarillo=EN_REVISION, Gris=CERRADO)

### Componente: Movements
- Botón "Nuevo movimiento": `{{ $fondo['estado'] !== 'ABIERTO' ? 'disabled' : '' }}`
- Botón "Ir a arqueo": `{{ $fondo['estado'] !== 'ABIERTO' ? 'disabled' : '' }}`
- Método `canAddMovements()`: verifica `estado === 'ABIERTO'`
- Método `canDoArqueo()`: verifica `estado === 'ABIERTO'`

### Componente: Arqueo
- Redirige automáticamente si fondo no está ABIERTO
- Validación en `mount()` y antes de guardar

## Modelos Eloquent

### CashFund (app/Models/CashFund.php)

**Relaciones:**
```php
$fondo->responsable        // User - Responsable del fondo
$fondo->createdBy         // User - Quien creó el fondo
$fondo->movements         // Collection<CashFundMovement>
$fondo->arqueo            // CashFundArqueo (nullable)
```

**Atributos Calculados:**
```php
$fondo->total_egresos      // float - Suma de egresos
$fondo->total_reintegros   // float - Suma de reintegros/depósitos
$fondo->saldo_disponible   // float - Saldo actual
```

**Métodos de Validación:**
```php
$fondo->canAddMovements()  // bool - ¿Se pueden agregar movimientos?
$fondo->canDoArqueo()      // bool - ¿Se puede realizar arqueo?
$fondo->isClosed()         // bool - ¿Está cerrado?
```

**Scopes:**
```php
CashFund::abierto()->get()      // Solo fondos abiertos
CashFund::enRevision()->get()   // Solo en revisión
CashFund::cerrado()->get()      // Solo cerrados
```

### CashFundMovement (app/Models/CashFundMovement.php)

**Relaciones:**
```php
$movement->cashFund       // CashFund
$movement->createdBy      // User
$movement->approvedBy     // User (nullable)
```

**Atributos Calculados:**
```php
$movement->proveedor_nombre  // string - Nombre del proveedor desde PostgreSQL
```

**Scopes:**
```php
CashFundMovement::aprobado()->get()    // Solo aprobados
CashFundMovement::porAprobar()->get()  // Pendientes de aprobación
CashFundMovement::egresos()->get()     // Solo egresos
CashFundMovement::ingresos()->get()    // Reintegros y depósitos
```

### CashFundArqueo (app/Models/CashFundArqueo.php)

**Relaciones:**
```php
$arqueo->cashFund         // CashFund
$arqueo->createdBy        // User
```

**Atributos Calculados:**
```php
$arqueo->estado           // string - 'CUADRA' | 'A_FAVOR' | 'EN_CONTRA'
```

**Métodos:**
```php
$arqueo->cuadra()         // bool - ¿El arqueo cuadra?
```

## Ejemplo de Uso Completo

```php
// 1. Crear fondo
$fondo = CashFund::create([
    'sucursal_id' => 1,
    'fecha' => today(),
    'monto_inicial' => 5000.00,
    'moneda' => 'MXN',
    'estado' => 'ABIERTO',
    'responsable_user_id' => 2,
    'created_by_user_id' => 1,
]);

// 2. Agregar movimientos
$fondo->movements()->create([
    'tipo' => 'EGRESO',
    'concepto' => 'Compra de insumos',
    'monto' => 350.00,
    'metodo' => 'EFECTIVO',
    'estatus' => 'APROBADO',
    'tiene_comprobante' => true,
    'created_by_user_id' => 1,
]);

// 3. Verificar saldo
$saldo = $fondo->saldo_disponible; // 4650.00

// 4. Realizar arqueo
$arqueo = $fondo->arqueo()->create([
    'monto_esperado' => $fondo->saldo_disponible,
    'monto_contado' => 4650.00,
    'diferencia' => 0.00,
    'created_by_user_id' => 1,
]);

// 5. Cambiar estado
$fondo->update(['estado' => 'EN_REVISION']);

// 6. Verificar que no se pueden agregar más movimientos
$fondo->canAddMovements(); // false
```

## Navegación

```
Sidebar → Caja → Caja Chica
  ↓
Index (lista de fondos)
  ↓
  [Abrir fondo] → Open (crear nuevo fondo)
                   ↓
                   Movements (registrar gastos)
                   ↓
                   [Ir a arqueo] → Arqueo (contar efectivo)
                                    ↓
                                    Movements (solo lectura, estado: EN_REVISION)
```

## Archivos Clave

**Migraciones:**
- `database/migrations/2025_01_23_100000_create_cash_funds_table.php`
- `database/migrations/2025_01_23_100001_create_cash_fund_movements_table.php`
- `database/migrations/2025_01_23_100002_create_cash_fund_arqueos_table.php`

**Modelos:**
- `app/Models/CashFund.php`
- `app/Models/CashFundMovement.php`
- `app/Models/CashFundArqueo.php`

**Componentes Livewire:**
- `app/Livewire/CashFund/Index.php`
- `app/Livewire/CashFund/Open.php`
- `app/Livewire/CashFund/Movements.php`
- `app/Livewire/CashFund/Arqueo.php`

**Vistas:**
- `resources/views/livewire/cash-fund/index.blade.php`
- `resources/views/livewire/cash-fund/open.blade.php`
- `resources/views/livewire/cash-fund/movements.blade.php`
- `resources/views/livewire/cash-fund/arqueo.blade.php`

**Rutas (routes/web.php):**
```php
Route::prefix('cashfund')->group(function () {
    Route::get('/', CashFundIndex::class)->name('cashfund.index');
    Route::get('/open', CashFundOpen::class)->name('cashfund.open');
    Route::get('/{id}/movements', CashFundMovements::class)->name('cashfund.movements');
    Route::get('/{id}/arqueo', CashFundArqueo::class)->name('cashfund.arqueo');
});
```

## Garantías de Funcionalidad

✅ **100% Funcional con Persistencia Real**

- [x] Apertura de fondos se guarda en `cash_funds`
- [x] Movimientos se guardan en `cash_fund_movements`
- [x] Arqueos se guardan en `cash_fund_arqueos`
- [x] Transiciones de estado (ABIERTO → EN_REVISION)
- [x] Validaciones de estado en UI (botones deshabilitados)
- [x] Validaciones de estado en backend
- [x] Cálculos dinámicos en tiempo real
- [x] Subida real de archivos adjuntos
- [x] Asignación de responsable
- [x] Auditoría (created_by_user_id en todas las tablas)
- [x] Relaciones entre tablas vía FK
- [x] Transacciones DB para operaciones críticas

## Pendientes (Futuras Mejoras)

- [ ] Componente `Approvals` para aprobar fondos en revisión
- [ ] Cerrar definitivamente fondos (estado CERRADO)
- [ ] Aprobar/rechazar movimientos sin comprobante
- [ ] Visualizar arqueos en modo solo lectura
- [ ] Reportes de fondos por período
- [ ] Notificaciones por diferencias grandes
- [ ] Integración con módulo de Contabilidad
