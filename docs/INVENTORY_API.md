# Inventory API

## Item REST CRUD (API-only)
Los endpoints de ítems están disponibles para integraciones y automatizaciones. La UI final está en diseño; por ahora sólo existe consumo vía API.

- `GET /api/inventory/items` — Lista paginada de ítems (filtros `q`, `categoria_id`, `status`).  
  **Respuesta (200)**:
  ```json
  {
    "ok": true,
    "data": {
      "data": [
        {
          "id": "INS-0001",
          "nombre": "Harina de trigo",
          "categoria_id": "MATPRIMA",
          "activo": true,
          "uom": "KG"
        }
      ],
      "current_page": 1,
      "last_page": 5
    },
    "timestamp": "2025-10-28T12:34:56-06:00"
  }
  ```

- `POST /api/inventory/items` — Crea un ítem.  
  **Body (JSON o form-data)**:
  ```json
  {
    "id": "INS-0001",
    "nombre": "Harina de trigo",
    "descripcion": "Saco 25 kg",
    "categoria_id": "MATPRIMA",
    "tipo": "MATERIA_PRIMA",
    "unidad_base_id": 4,
    "unidad_compra_id": 4,
    "unidad_salida_id": 4,
    "factor_compra": 1,
    "factor_conversion": 1,
    "perishable": true
  }
  ```
  **Respuesta (201)**:
  ```json
  {
    "ok": true,
    "data": {
      "id": "INS-0001"
    },
    "message": "Ítem creado",
    "timestamp": "2025-10-28T12:34:56-06:00"
  }
  ```

- `GET /api/inventory/items/{id}` — Detalle del ítem (incluye proveedores, unidades y factores).  
  **Respuesta (200)**: igual estructura que listado pero para un solo registro (`data` = objeto).

- `PUT /api/inventory/items/{id}` — Actualiza datos principales. Campos opcionales; sólo se actualiza lo enviado.  
  **Respuesta (200)**:
  ```json
  {
    "ok": true,
    "message": "Ítem actualizado",
    "timestamp": "2025-10-28T12:34:56-06:00"
  }
  ```

- `DELETE /api/inventory/items/{id}` — Marca como inactivo (no se elimina físicamente).  
  **Respuesta (200)**:
  ```json
  {
    "ok": true,
    "message": "Ítem desactivado",
    "timestamp": "2025-10-28T12:34:56-06:00"
  }
  ```

**Estado actual**: UI por definir. El registro se gestiona desde paneles internos, pero el flujo visual aún está en planeación.

