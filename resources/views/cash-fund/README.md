# Módulo: Caja Chica (Cash Fund)

Sistema de gestión de fondos de caja chica con control de egresos, comprobantes y conciliación diaria.

## Componentes Livewire

### ✅ CashFund/Open
**Estado:** Implementado ✅
**Ruta:** `/cashfund/open`
**Archivo:** `app/Livewire/CashFund/Open.php`

**Funcionalidad:**
- Apertura de fondo diario de caja chica
- Validaciones inline en español
- Pre-selección de sucursal única
- Redirección a Movements al guardar
- Mock local (sin conexión a API todavía)

**Contrato API esperado:**
```
POST /api/caja-fondo
Request: {
  sucursal_id: int,
  fecha: date (Y-m-d),
  monto_inicial: decimal,
  moneda: string (MXN|USD),
  creado_por: int
}
Response: {
  ok: bool,
  data: { id: int, estado: string, ... },
  message: string
}
```

**TODO Backend:**
- [ ] Implementar endpoint `POST /api/caja-fondo`
- [ ] Validar que no exista fondo abierto para la misma sucursal/fecha
- [ ] Registrar en tabla `selemti.caja_fondo`

---

### ✅ CashFund/Movements
**Estado:** Implementado ✅
**Ruta:** `/cashfund/{id}/movements`
**Archivo:** `app/Livewire/CashFund/Movements.php`

**Funcionalidad:**
- Resumen visual del fondo (header con datos clave)
- Barra de progreso de uso del fondo
- Registro de movimientos (EGRESO/REINTEGRO/DEPOSITO)
- Adjuntar comprobantes (file upload con validación)
- Semáforo de comprobación (alertas de movs sin comprobante)
- Tabla de movimientos con estados
- Cálculo de saldo disponible en tiempo real
- Botón para ir a arqueo

**Endpoints esperados:**
- `GET /api/caja-fondo/{id}` - Obtener fondo y movimientos
- `POST /api/caja-fondo/{id}/mov` - Crear movimiento
- `POST /api/caja-fondo/mov/{movId}/adjuntos` - Upload comprobante

**TODO Backend:**
- [ ] Implementar endpoints de movimientos
- [ ] Upload y storage de adjuntos (PDF/JPG/PNG)
- [ ] Validar estado del fondo antes de permitir movimientos
- [ ] Calcular saldos actualizados

---

### ✅ CashFund/Arqueo
**Estado:** Implementado ✅
**Ruta:** `/cashfund/{id}/arqueo`
**Archivo:** `app/Livewire/CashFund/Arqueo.php`

**Funcionalidad:**
- Resumen visual del fondo (cards con KPIs)
- Captura de efectivo contado físicamente
- Cálculo automático de diferencia (teórico vs contado)
- Indicador visual de estado (cuadra/a favor/faltante)
- Observaciones opcionales
- Modal de confirmación antes de guardar
- Cambio de estado a EN_REVISION
- Validación de que el fondo esté ABIERTO

**Endpoints esperados:**
- `POST /api/caja-fondo/{id}/arqueo`

**TODO Backend:**
- [ ] Implementar endpoint de arqueo
- [ ] Cambiar estado del fondo a EN_REVISION
- [ ] Registrar en tabla `selemti.caja_fondo_arqueo`
- [ ] Validar permisos del usuario

---

### 🚧 CashFund/Approvals (Pendiente)
**Funcionalidad planeada:**
- Panel para gerencia
- Aprobar/rechazar egresos sin comprobante
- Aprobar/rechazar arqueos con diferencias
- Cerrar fondos

**Endpoints:**
- `POST /api/caja-fondo/mov/{id}/aprobar`
- `POST /api/caja-fondo/{id}/cerrar`

---

## Modelo de datos (referencia)

### Tablas usadas:
- `selemti.caja_fondo` - Cabecera del fondo
- `selemti.caja_fondo_usuario` - Usuarios asignados
- `selemti.caja_fondo_mov` - Movimientos (egresos)
- `selemti.caja_fondo_adj` - Adjuntos/comprobantes
- `selemti.caja_fondo_arqueo` - Arqueos de cierre

### Estados del fondo:
- `ABIERTO` - Puede registrar movimientos
- `EN_REVISION` - Arqueo capturado, pendiente de aprobación
- `CERRADO` - Conciliado y cerrado

---

## Dependencias

**Base de datos:**
- Tabla `selemti.cat_sucursales` (debe existir y tener registros)
- Migraciones v1.4 aplicadas (`2025_10_23_000001_caja_fondo.sql`)

**Permisos (sugeridos):**
- `cashfund.open` - Abrir fondos
- `cashfund.manage` - Registrar movimientos
- `cashfund.approve` - Aprobar egresos sin comprobante
- `cashfund.close` - Cerrar fondos

**Vistas/Layout:**
- `layouts.terrena` (layout principal autenticado)

---

## Flujo operativo

1. **Apertura** (Titular/Admin) → Crea fondo con monto inicial → Estado: ABIERTO
2. **Egresos** (Titular) → Registra pagos con/sin comprobante
3. **Aprobación** (Admin/Gerencia) → Aprueba egresos sin comprobante
4. **Arqueo** (Titular) → Cuenta efectivo físico → Estado: EN_REVISION
5. **Cierre** (Gerencia) → Aprueba arqueo → Estado: CERRADO

---

## Testing

**Tests sugeridos (pendientes):**
- `tests/Feature/CashFund/OpenTest.php` - Validaciones y flujo de apertura
- `tests/Feature/CashFund/MovementsTest.php` - Egresos y adjuntos
- `tests/Feature/CashFund/ArqueoTest.php` - Cálculo de diferencias
- `tests/Feature/CashFund/ApprovalsTest.php` - Aprobaciones y cierres

---

## Progreso actual

### ✅ Completados
- [x] CashFund/Open - Apertura de fondos
- [x] CashFund/Movements - Registro de egresos y movimientos
- [x] CashFund/Arqueo - Conteo físico y cierre

### 🚧 Pendientes
- [ ] CashFund/Approvals - Panel de aprobaciones para gerencia
- [ ] Conectar todos los componentes con endpoints reales (actualmente usando mocks)
- [ ] Implementar upload real de adjuntos
- [ ] Tests de componentes

## Actualizado
2025-01-23 - Implementados Open, Movements y Arqueo con mocks locales
