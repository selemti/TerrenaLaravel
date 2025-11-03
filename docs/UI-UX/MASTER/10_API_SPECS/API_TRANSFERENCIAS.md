# API TRANSFERENCIAS - DOCUMENTACIÓN COMPLETA

**Módulo**: Transferencias entre Almacenes  
**Base URL**: `/api/inventory/transfers`  
**Autenticación**: Bearer Token (Sanctum)  
**Versión**: 1.0  
**Última actualización**: 2025-11-01

---

## 📋 ÍNDICE

1. [Overview](#overview)
2. [Estados de Transferencia](#estados)
3. [Endpoints](#endpoints)
4. [Flujo Completo](#flujo)
5. [Ejemplos de Uso](#ejemplos)
6. [Errores Comunes](#errores)

---

## 🎯 OVERVIEW

El módulo de Transferencias gestiona el movimiento de inventario entre almacenes de la organización.

### Características
- ✅ Flujo de estados validado (SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA)
- ✅ Validación de stock antes de aprobar
- ✅ Cálculo automático de varianzas en recepción
- ✅ Posteo automático a kardex (mov_inv)
- ✅ Trazabilidad completa (quién, cuándo)
- ✅ Número de guía de transporte

---

## 🔄 ESTADOS DE TRANSFERENCIA

| Estado | Descripción | Puede transicionar a |
|--------|-------------|---------------------|
| **SOLICITADA** | Transferencia creada, pendiente aprobación | APROBADA, CANCELADA |
| **APROBADA** | Transferencia aprobada, lista para despacho | EN_TRANSITO, CANCELADA |
| **EN_TRANSITO** | Mercancía despachada, en tránsito | RECIBIDA |
| **RECIBIDA** | Mercancía recibida en destino | POSTEADA |
| **POSTEADA** | Movimientos registrados en kardex | - |
| **CANCELADA** | Transferencia cancelada | - |

---

## 📡 ENDPOINTS

### 1. Listar Transferencias

```http
GET /api/inventory/transfers
```

**Headers**:
```
Authorization: Bearer {token}
```

**Query Parameters**:
| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `estado` | string | No | Filtrar por estado |
| `origen_almacen_id` | integer | No | Filtrar por almacén origen |
| `destino_almacen_id` | integer | No | Filtrar por almacén destino |
| `fecha_desde` | date | No | Filtrar desde fecha (Y-m-d) |
| `fecha_hasta` | date | No | Filtrar hasta fecha (Y-m-d) |
| `pendientes` | boolean | No | Solo pendientes (true) |
| `completadas` | boolean | No | Solo completadas (true) |
| `per_page` | integer | No | Resultados por página (default: 15) |

**Response 200 OK**:
```json
{
  "ok": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "origen_almacen_id": 1,
        "destino_almacen_id": 2,
        "estado": "SOLICITADA",
        "creada_por": 1,
        "fecha_solicitada": "2025-11-01T07:00:00.000000Z",
        "observaciones": "Transferencia urgente",
        "origen_almacen": {
          "id": 1,
          "nombre": "Almacén Central",
          "clave": "CENTRAL"
        },
        "destino_almacen": {
          "id": 2,
          "nombre": "Almacén Sucursal",
          "clave": "SUCURSAL"
        },
        "lineas": [
          {
            "id": 1,
            "item_id": 100,
            "cantidad_solicitada": "10.0000",
            "unidad_medida": "PZ",
            "item": {
              "id": 100,
              "clave": "PROD-001",
              "nombre": "Producto Test"
            }
          }
        ]
      }
    ],
    "total": 1
  },
  "timestamp": "2025-11-01T07:00:00.000000Z"
}
```

---

### 2. Crear Transferencia

```http
POST /api/inventory/transfers
```

**Request Body**:
```json
{
  "origen_almacen_id": 1,
  "destino_almacen_id": 2,
  "lines": [
    {
      "item_id": 100,
      "cantidad": 10,
      "unidad_medida": "PZ",
      "observaciones": "Producto A"
    },
    {
      "item_id": 101,
      "cantidad": 5,
      "unidad_medida": "KG"
    }
  ],
  "observaciones": "Transferencia urgente para sucursal"
}
```

**Validaciones**:
- `origen_almacen_id`: required, integer, exists en selemti.almacenes
- `destino_almacen_id`: required, integer, exists en selemti.almacenes, diferente de origen
- `lines`: required, array, mínimo 1 elemento
- `lines.*.item_id`: required, integer, exists en selemti.items
- `lines.*.cantidad`: required, numeric, >= 0.0001
- `lines.*.unidad_medida`: required, string, max 10 caracteres
- `observaciones`: optional, string, max 1000 caracteres

**Response 201 Created**:
```json
{
  "ok": true,
  "message": "Transferencia creada exitosamente",
  "data": {
    "id": 1,
    "origen_almacen_id": 1,
    "destino_almacen_id": 2,
    "estado": "SOLICITADA",
    "created_at": "2025-11-01T07:00:00.000000Z",
    "lineas": [...]
  },
  "timestamp": "2025-11-01T07:00:00.000000Z"
}
```

**Response 422 Validation Error**:
```json
{
  "ok": false,
  "message": "Validation failed",
  "errors": {
    "origen_almacen_id": ["The origen almacen id field is required."],
    "lines": ["The lines field must have at least 1 items."]
  },
  "timestamp": "2025-11-01T07:00:00.000000Z"
}
```

---

### 3. Obtener Detalle

```http
GET /api/inventory/transfers/{id}
```

**Response 200 OK**:
```json
{
  "ok": true,
  "data": {
    "id": 1,
    "origen_almacen_id": 1,
    "destino_almacen_id": 2,
    "estado": "APROBADA",
    "creada_por": 1,
    "aprobada_por": 2,
    "fecha_solicitada": "2025-11-01T07:00:00.000000Z",
    "fecha_aprobada": "2025-11-01T07:10:00.000000Z",
    "observaciones": "Transferencia urgente",
    "creada_por_user": {
      "id": 1,
      "name": "Juan Pérez"
    },
    "aprobada_por_user": {
      "id": 2,
      "name": "María González"
    },
    "lineas": [
      {
        "id": 1,
        "item_id": 100,
        "cantidad_solicitada": "10.0000",
        "cantidad_despachada": null,
        "cantidad_recibida": null,
        "unidad_medida": "PZ",
        "item": {
          "id": 100,
          "clave": "PROD-001",
          "nombre": "Producto Test"
        }
      }
    ]
  },
  "timestamp": "2025-11-01T07:00:00.000000Z"
}
```

**Response 404 Not Found**:
```json
{
  "ok": false,
  "message": "Transferencia #999 no encontrada",
  "timestamp": "2025-11-01T07:00:00.000000Z"
}
```

---

### 4. Aprobar Transferencia

```http
POST /api/inventory/transfers/{id}/approve
```

**Precondiciones**:
- Estado debe ser `SOLICITADA`
- Debe haber stock suficiente en almacén origen para todos los items

**Response 200 OK**:
```json
{
  "ok": true,
  "message": "Transferencia aprobada exitosamente",
  "data": {
    "id": 1,
    "estado": "APROBADA",
    "aprobada_por": 2,
    "fecha_aprobada": "2025-11-01T07:10:00.000000Z"
  },
  "timestamp": "2025-11-01T07:10:00.000000Z"
}
```

**Response 400 Bad Request** (estado incorrecto):
```json
{
  "ok": false,
  "message": "Transfer must be in SOLICITADA status to be approved. Current: APROBADA",
  "timestamp": "2025-11-01T07:10:00.000000Z"
}
```

**Response 400 Bad Request** (stock insuficiente):
```json
{
  "ok": false,
  "message": "Stock insuficiente para item Producto Test. Disponible: 5, Requerido: 10",
  "timestamp": "2025-11-01T07:10:00.000000Z"
}
```

---

### 5. Despachar Transferencia

```http
POST /api/inventory/transfers/{id}/ship
```

**Request Body**:
```json
{
  "numero_guia": "GUIA-12345" // opcional
}
```

**Precondiciones**:
- Estado debe ser `APROBADA`

**Response 200 OK**:
```json
{
  "ok": true,
  "message": "Transferencia despachada exitosamente",
  "data": {
    "id": 1,
    "estado": "EN_TRANSITO",
    "despachada_por": 3,
    "fecha_despachada": "2025-11-01T08:00:00.000000Z",
    "numero_guia": "GUIA-12345",
    "lineas": [
      {
        "id": 1,
        "cantidad_solicitada": "10.0000",
        "cantidad_despachada": "10.0000" // auto-filled
      }
    ]
  },
  "timestamp": "2025-11-01T08:00:00.000000Z"
}
```

---

### 6. Recibir Transferencia

```http
POST /api/inventory/transfers/{id}/receive
```

**Request Body**:
```json
{
  "lines": [
    {
      "line_id": 1,
      "cantidad_recibida": 10,
      "observaciones": "Recibido en buen estado"
    },
    {
      "line_id": 2,
      "cantidad_recibida": 4.5, // Varianza: se solicitaron 5
      "observaciones": "Faltante por rotura"
    }
  ],
  "observaciones_generales": "Recepción con varianza"
}
```

**Validaciones**:
- `lines`: required, array, min 1
- `lines.*.line_id`: required, integer
- `lines.*.cantidad_recibida`: required, numeric, >= 0
- `lines.*.observaciones`: optional, string, max 500 caracteres

**Precondiciones**:
- Estado debe ser `EN_TRANSITO`

**Response 200 OK**:
```json
{
  "ok": true,
  "message": "Transferencia recibida exitosamente",
  "data": {
    "id": 1,
    "estado": "RECIBIDA",
    "recibida_por": 4,
    "fecha_recibida": "2025-11-01T10:00:00.000000Z"
  },
  "varianzas": [
    {
      "line_id": 2,
      "item_id": 101,
      "varianza": -0.5,
      "varianza_porcentaje": -10.0
    }
  ],
  "timestamp": "2025-11-01T10:00:00.000000Z"
}
```

---

### 7. Postear a Inventario

```http
POST /api/inventory/transfers/{id}/post
```

**Precondiciones**:
- Estado debe ser `RECIBIDA`

**Response 200 OK**:
```json
{
  "ok": true,
  "message": "Transferencia posteada exitosamente",
  "data": {
    "id": 1,
    "estado": "POSTEADA",
    "posteada_por": 5,
    "fecha_posteada": "2025-11-01T11:00:00.000000Z"
  },
  "movimientos_generados": 4,
  "timestamp": "2025-11-01T11:00:00.000000Z"
}
```

**Nota**: Se crean automáticamente:
- Movimientos `TRASPASO_OUT` (negativos) en almacén origen
- Movimientos `TRASPASO_IN` (positivos) en almacén destino

---

## 🔄 FLUJO COMPLETO

### Ejemplo: Transferencia de 10 productos de Central a Sucursal

#### 1. **Crear Transferencia**
```bash
POST /api/inventory/transfers
{
  "origen_almacen_id": 1,
  "destino_almacen_id": 2,
  "lines": [
    { "item_id": 100, "cantidad": 10, "unidad_medida": "PZ" }
  ]
}
→ Estado: SOLICITADA
```

#### 2. **Aprobar Transferencia**
```bash
POST /api/inventory/transfers/1/approve
→ Estado: APROBADA
→ Valida que hay stock >= 10 en almacén origen
```

#### 3. **Despachar**
```bash
POST /api/inventory/transfers/1/ship
{ "numero_guia": "GUIA-001" }
→ Estado: EN_TRANSITO
→ cantidad_despachada = 10 (auto)
```

#### 4. **Recibir**
```bash
POST /api/inventory/transfers/1/receive
{
  "lines": [
    { "line_id": 1, "cantidad_recibida": 10 }
  ]
}
→ Estado: RECIBIDA
→ Varianza: 0 (todo OK)
```

#### 5. **Postear**
```bash
POST /api/inventory/transfers/1/post
→ Estado: POSTEADA
→ Crea mov_inv:
  - TRASPASO_OUT en almacén 1 (-10)
  - TRASPASO_IN en almacén 2 (+10)
```

---

## ❌ ERRORES COMUNES

### 400 Bad Request - Estado Inválido
```json
{
  "ok": false,
  "message": "Transfer must be in SOLICITADA status to be approved. Current: APROBADA"
}
```
**Solución**: Verificar estado actual antes de llamar endpoint.

### 400 Bad Request - Stock Insuficiente
```json
{
  "ok": false,
  "message": "Stock insuficiente para item Producto Test. Disponible: 5, Requerido: 10"
}
```
**Solución**: Reducir cantidad solicitada o reabastecer almacén origen.

### 422 Validation Error - Almacenes Iguales
```json
{
  "ok": false,
  "message": "Validation failed",
  "errors": {
    "destino_almacen_id": ["The destino almacen id and origen almacen id must be different."]
  }
}
```
**Solución**: Seleccionar almacenes diferentes.

### 404 Not Found
```json
{
  "ok": false,
  "message": "Transferencia #999 no encontrada"
}
```
**Solución**: Verificar ID de transferencia.

---

## 📊 MODELOS DE DATOS

### TransferHeader
```
- id: integer
- origen_almacen_id: integer
- destino_almacen_id: integer
- estado: enum (SOLICITADA, APROBADA, EN_TRANSITO, RECIBIDA, POSTEADA, CANCELADA)
- creada_por: integer (user_id)
- aprobada_por: integer (user_id) nullable
- despachada_por: integer (user_id) nullable
- recibida_por: integer (user_id) nullable
- posteada_por: integer (user_id) nullable
- numero_guia: string nullable
- fecha_solicitada: datetime
- fecha_aprobada: datetime nullable
- fecha_despachada: datetime nullable
- fecha_recibida: datetime nullable
- fecha_posteada: datetime nullable
- observaciones: text nullable
- observaciones_recepcion: text nullable
- created_at: datetime
- updated_at: datetime
```

### TransferLine
```
- id: integer
- transfer_id: integer
- item_id: integer
- cantidad_solicitada: decimal(10,4)
- cantidad_despachada: decimal(10,4) nullable
- cantidad_recibida: decimal(10,4) nullable
- unidad_medida: string(10)
- observaciones: text nullable
- observaciones_recepcion: text nullable
- created_at: datetime
```

---

## 🔐 PERMISOS REQUERIDOS

| Endpoint | Permiso Mínimo |
|----------|---------------|
| GET /transfers | `inventory.transfers.view` |
| POST /transfers | `inventory.transfers.create` |
| POST /approve | `inventory.transfers.approve` |
| POST /ship | `inventory.transfers.ship` |
| POST /receive | `inventory.transfers.receive` |
| POST /post | `inventory.transfers.post` |

---

## 📝 NOTAS ADICIONALES

1. **Transacciones**: Todos los endpoints usan transacciones de BD para garantizar atomicidad
2. **Auditoría**: Se registra quién realizó cada acción (creada_por, aprobada_por, etc.)
3. **Varianzas**: Se calculan automáticamente como `cantidad_recibida - cantidad_despachada`
4. **Kardex**: El posteo crea movimientos automáticos en `selemti.mov_inv`
5. **Cancelación**: No implementada aún (próxima versión)

---

**Documentación generada**: 2025-11-01  
**Versión**: 1.0  
**Contacto**: Equipo Terrena ERP
