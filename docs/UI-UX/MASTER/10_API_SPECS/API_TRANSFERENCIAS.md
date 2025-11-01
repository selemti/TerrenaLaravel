# API Transferencias entre Almacenes

> **Versión:** 2025-11-01 — alineado al esquema normalizado `selemti`.
> **Autenticación:** Bearer Token (Laravel Sanctum)
> **Permiso requerido:** `can_manage_transfers`

## Estados soportados

| Estado        | Descripción                           |
|---------------|----------------------------------------|
| SOLICITADA    | Creada por usuario, pendiente de aprobación |
| APROBADA      | Validada con stock suficiente          |
| EN_TRANSITO   | Despachada desde almacén origen        |
| RECIBIDA      | Cantidades recibidas registradas       |
| POSTEADA      | Movimientos generados en `mov_inv`     |
| CANCELADA     | Cancelada (pendiente de implementación UI) |

---

## 1. Listar transferencias

`GET /api/inventory/transfers`

### Parámetros opcionales
- `estado` — filtra por estado exacto
- `almacen_origen_id` — filtra por almacén origen
- `almacen_destino_id` — filtra por almacén destino
- `desde` / `hasta` — fechas `YYYY-MM-DD` para `fecha_solicitada`

### Respuesta 200
```json
{
  "ok": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 12,
        "estado": "APROBADA",
        "origen_almacen_id": 1,
        "destino_almacen_id": 2,
        "fecha_solicitada": "2025-11-01T09:32:00Z",
        "origen_almacen": {"nombre": "General"},
        "destino_almacen": {"nombre": "Refrigerados"}
      }
    ]
  },
  "timestamp": "2025-11-01T10:00:00Z"
}
```

---

## 2. Crear transferencia

`POST /api/inventory/transfers`

```json
{
  "origen_almacen_id": 1,
  "destino_almacen_id": 2,
  "lineas": [
    {"item_id": "ITEM-001", "cantidad": 5, "uom_id": 1},
    {"item_id": "ITEM-002", "cantidad": 3, "uom_id": 1}
  ]
}
```

### Respuesta 201
```json
{
  "ok": true,
  "data": {
    "transfer_id": 34,
    "status": "SOLICITADA"
  },
  "message": "Transferencia creada exitosamente",
  "timestamp": "2025-11-01T10:05:00Z"
}
```

Errores comunes:
- `422` si falta alguna línea o `item_id` no existe.
- `400` si origen = destino.

---

## 3. Obtener detalle

`GET /api/inventory/transfers/{id}`

Incluye relaciones:
- `lineas.item.uom`
- `origenAlmacen` y `destinoAlmacen`
- Usuarios: `creadaPor`, `aprobadaPor`, `despachadaPor`, `recibidaPor`, `posteadaPor`

---

## 4. Aprobar transferencia

`POST /api/inventory/transfers/{id}/approve`

- Valida stock en `mov_inv` para el almacén origen.
- Respuesta `400` si ya fue aprobada o no hay stock suficiente.

---

## 5. Despachar transferencia

`POST /api/inventory/transfers/{id}/ship`

Payload opcional:
```json
{
  "guia": "GUIA-1234"
}
```

- Mueve el estado a `EN_TRANSITO` y conserva `cantidad_despachada`.

---

## 6. Recibir transferencia

`POST /api/inventory/transfers/{id}/receive`

```json
{
  "lineas": [
    {"line_id": 55, "cantidad_recibida": 4.5, "observaciones": "Faltó 0.5"}
  ]
}
```

- Todas las líneas deben pertenecer a la transferencia.
- Estado final: `RECIBIDA`.

---

## 7. Postear transferencia a inventario

`POST /api/inventory/transfers/{id}/post`

- Requiere que la transferencia esté en estado `RECIBIDA`.
- Genera dos movimientos en `selemti.mov_inv`:
  - Salida (`cantidad` negativa) para almacén origen.
  - Entrada (`cantidad` positiva) para almacén destino.

Respuesta 200:
```json
{
  "ok": true,
  "data": {"transfer_id": 34, "status": "POSTEADA"},
  "message": "Transferencia posteada a inventario",
  "timestamp": "2025-11-01T11:12:00Z"
}
```

---

## Notas técnicas
- Todos los movimientos usan `tipo = TRASPASO` y referencia `ref_tipo = TRANSFER`.
- El stock disponible se calcula sumando `cantidad` en `mov_inv` filtrado por `item_id` y `sucursal_id` del almacén.
- Los campos adicionales (`observaciones`, `observaciones_recepcion`, `lote`) quedan disponibles para futuras iteraciones UI.
