# Módulo: Transferencias (Transfers)

Sistema de gestión de movimientos de inventario entre almacenes con flujo de despacho y recepción.

## Componentes Livewire

### ✅ Transfers/Create
**Estado:** Implementado ✅
**Ruta:** `/transfers/create`
**Archivo:** `app/Livewire/Transfers/Create.php`

**Funcionalidad:**
- Selección de almacén de origen y destino (con validación de diferencia)
- Fecha solicitada para la transferencia
- Líneas de ítems con cantidad y UOM
- Agregar/eliminar líneas dinámicamente
- Validaciones inline en español
- Mock local (sin conexión a API todavía)

**Contrato API esperado:**
```
POST /api/transferencias
Request: {
  almacen_origen_id: int,
  almacen_destino_id: int,
  fecha_solicitada: date,
  observaciones: string|null,
  lineas: [{ item_id: string, cantidad: decimal, uom_id: int }]
}
Response: {
  ok: bool,
  data: { id: int, numero: string, estado: string },
  message: string
}
```

**TODO Backend:**
- [ ] Implementar endpoint `POST /api/transferencias`
- [ ] Validar existencia de stock en almacén origen
- [ ] Registrar en tablas `transferencia_cab` y `transferencia_det`
- [ ] Estado inicial: BORRADOR

---

### 🚧 Transfers/Dispatch (Pendiente)
**Funcionalidad planeada:**
- Ver detalle de transferencia en estado BORRADOR
- Validar stock disponible en almacén origen
- Confirmar despacho
- Generar movimiento TRANSFER_OUT en kardex
- Cambiar estado a DESPACHADA
- Imprimir guía de remisión

**Endpoint:**
- `POST /api/transferencias/{id}/despachar`

---

### 🚧 Transfers/Receive (Pendiente)
**Funcionalidad planeada:**
- Ver detalle de transferencia DESPACHADA
- Capturar cantidades recibidas (permitir parciales)
- Observaciones por línea (faltantes, daños)
- Generar movimiento TRANSFER_IN en kardex
- Cambiar estado a RECIBIDA o PARCIAL
- Actualizar stock en almacén destino

**Endpoint:**
- `POST /api/transferencias/{id}/recibir`

---

### 🚧 Transfers/Index (Pendiente)
**Funcionalidad planeada:**
- Listado de transferencias con filtros
- Estados: BORRADOR, DESPACHADA, PARCIAL, RECIBIDA, CANCELADA
- Búsqueda por número, almacenes, fechas
- Acciones: ver detalle, despachar, recibir, cancelar

---

## Modelo de datos (referencia)

### Tablas usadas:
- `transferencia_cab` - Cabecera de transferencia
- `transferencia_det` - Líneas de ítems
- `selemti.mov_inv` - Kardex (movimientos TRANSFER_OUT/TRANSFER_IN)

### Estados de transferencia:
- `BORRADOR` - Creada, sin despachar
- `DESPACHADA` - Enviada desde origen, pendiente de recibir
- `PARCIAL` - Recibida parcialmente en destino
- `RECIBIDA` - Recibida completamente
- `CANCELADA` - Cancelada antes de despachar

---

## Flujo operativo

1. **Crear** (Almacén Origen) → Seleccionar ítems y cantidades → Estado: BORRADOR
2. **Despachar** (Almacén Origen) → Validar stock → Generar TRANSFER_OUT → Estado: DESPACHADA
3. **Recibir** (Almacén Destino) → Capturar cantidades recibidas → Generar TRANSFER_IN → Estado: RECIBIDA/PARCIAL

---

## Dependencias

**Base de datos:**
- Tabla `selemti.cat_almacenes` (debe existir con registros)
- Tabla `selemti.items` (catálogo de ítems activo)
- Tabla `selemti.unidades_medida` (UOMs)
- Migraciones v1.4 aplicadas

**Permisos (sugeridos):**
- `transfers.create` - Crear transferencias
- `transfers.dispatch` - Despachar desde origen
- `transfers.receive` - Recibir en destino
- `transfers.cancel` - Cancelar transferencias

**Vistas/Layout:**
- `layouts.terrena` (layout principal autenticado)

---

## Progreso actual

### ✅ Completados
- [x] Transfers/Create - Crear transferencia con líneas de ítems

### 🚧 Pendientes
- [ ] Transfers/Index - Listado y búsqueda
- [ ] Transfers/Dispatch - Despachar transferencia
- [ ] Transfers/Receive - Recibir transferencia (parcial)
- [ ] Conectar con endpoints reales (actualmente usando mocks)
- [ ] Validación de stock disponible en origen
- [ ] Generación de kardex (TRANSFER_OUT/IN)
- [ ] Tests de componentes

---

## Actualizado
2025-01-23 - Implementado Transfers/Create con mock local
