# 01 - ARQUITECTURA DEL SISTEMA

## 📐 Visión General

El Sistema de Fondo de Caja Chica está construido siguiendo una arquitectura **MVC (Model-View-Controller)** con **Livewire** como capa reactiva, eliminando la necesidad de escribir JavaScript para la interactividad.

---

## 🎯 Principios de Diseño

### 1. **Separación de Responsabilidades**
- **Modelos:** Lógica de negocio y acceso a datos
- **Componentes Livewire:** Controladores reactivos
- **Vistas Blade:** Presentación e interfaz de usuario

### 2. **Single Responsibility**
Cada componente tiene una responsabilidad única:
- `Index`: Solo listar fondos
- `Open`: Solo crear fondos
- `Movements`: Solo gestionar movimientos
- `Arqueo`: Solo realizar conciliación
- `Approvals`: Solo aprobar/rechazar
- `Detail`: Solo mostrar información completa

### 3. **Inmutabilidad de Estados**
Estados del fondo siguen un flujo unidireccional:
```
ABIERTO → EN_REVISION → CERRADO
```
Solo se permite retroceder de EN_REVISION a ABIERTO mediante rechazo explícito.

### 4. **Auditoría Completa**
Cada cambio en movimientos se registra automáticamente en `cash_fund_movement_audit_log`.

---

## 🗂️ Estructura de Archivos

```
app/
├── Models/
│   ├── CashFund.php                        # Modelo principal del fondo
│   ├── CashFundMovement.php                # Modelo de movimientos
│   ├── CashFundArqueo.php                  # Modelo de arqueo
│   └── CashFundMovementAuditLog.php        # Modelo de auditoría
│
├── Livewire/CashFund/
│   ├── Index.php                           # Listado de fondos
│   ├── Open.php                            # Apertura de fondo
│   ├── Movements.php                       # Gestión de movimientos
│   ├── Arqueo.php                          # Arqueo y conciliación
│   ├── Approvals.php                       # Aprobaciones
│   └── Detail.php                          # Vista detalle completa
│
database/migrations/
├── 2025_01_23_100000_create_cash_funds_table.php
├── 2025_01_23_101000_create_cash_fund_movements_table.php
├── 2025_01_23_102000_create_cash_fund_arqueos_table.php
├── 2025_01_23_110000_create_cash_fund_movement_audit_log_table.php
└── 2025_10_23_154901_add_descripcion_to_cash_funds_table.php
│
resources/views/livewire/cash-fund/
├── index.blade.php                         # Vista listado
├── open.blade.php                          # Vista apertura
├── movements.blade.php                     # Vista movimientos
├── arqueo.blade.php                        # Vista arqueo
├── approvals.blade.php                     # Vista aprobaciones
└── detail.blade.php                        # Vista detalle
│
routes/
└── web.php                                 # Rutas del módulo
│
storage/app/public/
└── cash_fund_attachments/                  # Archivos adjuntos
    └── {cash_fund_id}/
        └── {movement_id}/
            └── {timestamp}_{filename}
│
public/storage/                             # Symlink → storage/app/public
```

---

## 🔄 Flujo de Datos

### Apertura de Fondo

```
Usuario → Open Component
           ↓
       Validación
           ↓
    CashFund::create()
           ↓
     Base de Datos
           ↓
    Redirect a Movements
```

### Registro de Movimiento

```
Usuario → Movements Component
           ↓
       Validación
           ↓
    DB::transaction {
        CashFundMovement::create()
        ↓
        Store attachment (si hay)
        ↓
        CashFundMovementAuditLog::create()
    }
           ↓
    Actualización reactiva de UI
```

### Edición de Movimiento

```
Usuario → Click Editar
           ↓
    Cargar datos en modal
           ↓
    Usuario modifica campos
           ↓
       Validación
           ↓
    DB::transaction {
        Por cada campo modificado:
            ↓
        CashFundMovementAuditLog::logChange()
            ↓
        CashFundMovement::update()
    }
           ↓
    Actualización reactiva
```

### Arqueo

```
Usuario → Arqueo Component
           ↓
    Calcular saldo teórico
           ↓
    Usuario ingresa efectivo contado
           ↓
    Calcular diferencia
           ↓
       Validación
           ↓
    DB::transaction {
        CashFundArqueo::updateOrCreate()
        ↓
        CashFund::update(['estado' => 'EN_REVISION'])
    }
           ↓
    Redirect a Movements
```

### Aprobación

```
Usuario con permiso → Approvals Component
                         ↓
                  Seleccionar fondo
                         ↓
                  Ver detalle completo
                         ↓
             [Rechazar]     [Aprobar]
                 ↓               ↓
    CashFund::update()   Validar movimientos
    estado = ABIERTO          ↓
                          CashFund::update()
                          estado = CERRADO
                          closed_at = now()
```

---

## 🔗 Relaciones Entre Modelos

```
CashFund (1)
    │
    ├─→ responsable (BelongsTo User)
    ├─→ createdBy (BelongsTo User)
    │
    ├─→ movements (HasMany CashFundMovement)
    │      │
    │      └─→ createdBy (BelongsTo User)
    │      └─→ auditLogs (HasMany CashFundMovementAuditLog)
    │             │
    │             └─→ changedBy (BelongsTo User)
    │
    └─→ arqueo (HasOne CashFundArqueo)
           │
           └─→ createdBy (BelongsTo User)
```

---

## 📊 Atributos Calculados

### CashFund Model

```php
// Atributos calculados automáticamente
public function getTotalEgresosAttribute(): float
public function getTotalReintegrosAttribute(): float
public function getSaldoDisponibleAttribute(): float
```

Estos atributos se calculan dinámicamente consultando la suma de movimientos:
- `total_egresos`: Suma de movimientos tipo EGRESO
- `total_reintegros`: Suma de movimientos tipo REINTEGRO + DEPOSITO
- `saldo_disponible`: monto_inicial - total_egresos + total_reintegros

---

## 🛡️ Seguridad y Validación

### Niveles de Seguridad

1. **Nivel de Ruta (Middleware)**
```php
Route::middleware('auth')->group(function () {
    Route::get('/cashfund/approvals', Approvals::class)
        ->middleware('can:approve-cash-funds');
});
```

2. **Nivel de Componente (mount)**
```php
public function mount()
{
    if (!Auth::user()->can('approve-cash-funds')) {
        abort(403);
    }
}
```

3. **Nivel de Método**
```php
public function approveFund()
{
    if (!Auth::user()->can('close-cash-funds')) {
        // Error
        return;
    }
    // ...
}
```

### Validación de Datos

Todos los componentes implementan:
- `rules()`: Reglas de validación Laravel
- `messages()`: Mensajes personalizados
- Validación en tiempo real con Livewire

---

## 🎨 Capa de Presentación

### Diseño Responsive

- **Desktop:** Layout de 2 columnas (principal + sidebar)
- **Tablet:** Layout adaptativo con colapso de sidebar
- **Mobile:** Layout de 1 columna con menú hamburguesa

### Componentes UI Reutilizables

- **Modales Bootstrap 5:** Para edición y confirmaciones
- **Toasts Livewire:** Para notificaciones
- **Badges de estado:** Para visualizar estados del fondo
- **Cards Bootstrap:** Para agrupar información

### Iconografía

**FontAwesome 6** para iconos consistentes:
- 💰 `fa-wallet`: Caja chica
- 📤 `fa-arrow-down`: Egresos
- 📥 `fa-arrow-up`: Reintegros
- 🔒 `fa-lock`: Cerrado
- 🔓 `fa-unlock`: Abierto
- 👁️ `fa-eye`: En revisión
- ✅ `fa-check-double`: Aprobaciones

---

## 📦 Dependencias Externas

### Backend
- `laravel/framework`: ^12.0
- `livewire/livewire`: ^3.7
- `spatie/laravel-permission`: Para gestión de permisos

### Frontend
- Bootstrap 5.3
- FontAwesome 6.7
- Alpine.js (incluido con Livewire)
- Cleave.js (formateo de montos)

### Base de Datos
- PostgreSQL 9.5+
- Schema: `selemti`
- Conexión: `pgsql` (definida en config/database.php)

---

## 🔧 Configuración

### Variables de Entorno

```env
DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5433
DB_DATABASE=pos
DB_USERNAME=postgres
DB_PASSWORD=your_password

# Importante para archivos adjuntos
FILESYSTEM_DISK=public
```

### Config Database

```php
// config/database.php
'pgsql' => [
    'driver' => 'pgsql',
    'host' => env('DB_HOST', '127.0.0.1'),
    'port' => env('DB_PORT', '5432'),
    'database' => env('DB_DATABASE', 'forge'),
    'username' => env('DB_USERNAME', 'forge'),
    'password' => env('DB_PASSWORD', ''),
    'charset' => 'utf8',
    'prefix' => '',
    'search_path' => 'selemti,public',
    'sslmode' => 'prefer',
],
```

---

## 🚦 Performance

### Optimizaciones Implementadas

1. **Eager Loading**
```php
CashFund::with(['responsable', 'createdBy', 'movements.createdBy'])
```

2. **Paginación**
```php
$fondos = $query->paginate(20);
```

3. **Índices de BD**
- Primary keys en todas las tablas
- Foreign keys indexadas
- Índices en campos de búsqueda frecuente

4. **Cache de Consultas**
- Nombres de sucursales cacheados en memoria durante request
- Relaciones lazy loaded solo cuando se necesitan

---

## 📈 Escalabilidad

### Preparado para Crecer

- **Multi-sucursal:** Soporta N sucursales sin cambios
- **Multi-moneda:** MXN/USD configurables
- **Archivos:** Estructura de carpetas por fondo/movimiento
- **Auditoría:** Log ilimitado de cambios

### Límites Actuales

- Paginación: 20 fondos por página
- Archivos adjuntos: Máximo 10MB por archivo
- Movimientos: Sin límite por fondo
- Auditoría: Sin límite de registros

---

## 🔮 Extensiones Futuras

Arquitectura preparada para:
- ✨ Exportación a Excel/PDF
- ✨ API REST para integraciones
- ✨ Notificaciones por email
- ✨ Dashboard con métricas
- ✨ App móvil (PWA o nativa)
- ✨ Múltiples monedas simultáneas
- ✨ Integración con contabilidad
