# 📡 API SPECIFICATIONS - CATÁLOGOS

**Fecha**: 31 de octubre de 2025
**Versión**: 1.0
**Base URL**: `/api/catalogs`

---

## 🎯 RESUMEN

Este documento especifica los endpoints de la API de Catálogos que gestionan las entidades maestras del sistema: sucursales, almacenes, unidades de medida, categorías y tipos de movimiento.

**Endpoints Documentados**: 5
**Autenticación**: Laravel Sanctum (Bearer Token)
**Rate Limiting**: 60 req/min por usuario

---

## 🔐 AUTENTICACIÓN

Todos los endpoints requieren autenticación vía Bearer Token:

```http
Authorization: Bearer {token}
```

**Obtener Token**:
```bash
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}
```

**Response**:
```json
{
  "ok": true,
  "token": "1|abc123...",
  "user": { ... }
}
```

---

## 📋 ENDPOINTS

### 1. GET /api/catalogs/sucursales

Obtiene el listado de sucursales (branches).

#### Request

```http
GET /api/catalogs/sucursales?show_all=false
Authorization: Bearer {token}
```

#### Query Parameters

| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `show_all` | boolean | No | false | Si es `true`, muestra sucursales inactivas también |

#### Response 200 OK

```json
{
  "ok": true,
  "data": [
    {
      "id": 1,
      "clave": "SUC01",
      "nombre": "Sucursal Centro",
      "rfc": "ABC123456789",
      "direccion": "Calle Principal 123",
      "telefono": "5551234567",
      "email": "centro@terrena.com",
      "activo": true,
      "created_at": "2025-01-15T10:00:00.000000Z",
      "updated_at": "2025-01-15T10:00:00.000000Z"
    },
    {
      "id": 2,
      "clave": "SUC02",
      "nombre": "Sucursal Norte",
      "rfc": "DEF987654321",
      "direccion": "Av. Norte 456",
      "telefono": "5559876543",
      "email": "norte@terrena.com",
      "activo": true,
      "created_at": "2025-01-20T14:30:00.000000Z",
      "updated_at": "2025-01-20T14:30:00.000000Z"
    }
  ],
  "timestamp": "2025-10-31T18:45:30.000000Z"
}
```

#### Response 401 Unauthorized

```json
{
  "message": "Unauthenticated."
}
```

#### Ejemplo cURL

```bash
curl -X GET "https://app.terrena.com/api/catalogs/sucursales?show_all=false" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

---

### 2. GET /api/catalogs/almacenes

Obtiene el listado de almacenes (warehouses).

#### Request

```http
GET /api/catalogs/almacenes?show_all=false&sucursal_id=1
Authorization: Bearer {token}
```

#### Query Parameters

| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `show_all` | boolean | No | false | Muestra almacenes inactivos si es `true` |
| `sucursal_id` | integer | No | - | Filtra por sucursal específica |

#### Response 200 OK

```json
{
  "ok": true,
  "data": [
    {
      "id": 1,
      "sucursal_id": 1,
      "nombre": "Almacén Principal Centro",
      "tipo": "GENERAL",
      "activo": true,
      "created_at": "2025-01-15T10:30:00.000000Z",
      "updated_at": "2025-01-15T10:30:00.000000Z",
      "sucursal": {
        "id": 1,
        "nombre": "Sucursal Centro",
        "clave": "SUC01"
      }
    },
    {
      "id": 2,
      "sucursal_id": 1,
      "nombre": "Almacén Refrigerados Centro",
      "tipo": "FRIO",
      "activo": true,
      "created_at": "2025-01-15T11:00:00.000000Z",
      "updated_at": "2025-01-15T11:00:00.000000Z",
      "sucursal": {
        "id": 1,
        "nombre": "Sucursal Centro",
        "clave": "SUC01"
      }
    }
  ],
  "timestamp": "2025-10-31T18:46:00.000000Z"
}
```

#### Ejemplo cURL

```bash
curl -X GET "https://app.terrena.com/api/catalogs/almacenes?sucursal_id=1" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

---

### 3. GET /api/catalogs/unidades

Obtiene el catálogo de unidades de medida.

#### Request

```http
GET /api/catalogs/unidades?tipo=BASE&limit=100
Authorization: Bearer {token}
```

#### Query Parameters

| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `tipo` | string | No | - | Filtra por tipo: `BASE`, `COMPRA`, `SALIDA` |
| `categoria` | string | No | - | Filtra por categoría: `MASA`, `VOLUMEN`, `UNIDAD` |
| `only_count` | boolean | No | false | Solo retorna el conteo, no los datos |
| `limit` | integer | No | 250 | Límite de resultados (máx 500) |

#### Response 200 OK

```json
{
  "ok": true,
  "count": 45,
  "data": [
    {
      "id": 1,
      "codigo": "KG",
      "nombre": "Kilogramo",
      "tipo": "BASE",
      "categoria": "MASA",
      "es_base": true,
      "factor_conversion_base": 1.0,
      "decimales": 3
    },
    {
      "id": 2,
      "codigo": "GR",
      "nombre": "Gramo",
      "tipo": "BASE",
      "categoria": "MASA",
      "es_base": false,
      "factor_conversion_base": 0.001,
      "decimales": 2
    },
    {
      "id": 3,
      "codigo": "LT",
      "nombre": "Litro",
      "tipo": "BASE",
      "categoria": "VOLUMEN",
      "es_base": true,
      "factor_conversion_base": 1.0,
      "decimales": 3
    },
    {
      "id": 4,
      "codigo": "ML",
      "nombre": "Mililitro",
      "tipo": "BASE",
      "categoria": "VOLUMEN",
      "es_base": false,
      "factor_conversion_base": 0.001,
      "decimales": 2
    },
    {
      "id": 5,
      "codigo": "PZ",
      "nombre": "Pieza",
      "tipo": "BASE",
      "categoria": "UNIDAD",
      "es_base": true,
      "factor_conversion_base": 1.0,
      "decimales": 0
    }
  ],
  "timestamp": "2025-10-31T18:47:00.000000Z"
}
```

#### Response 200 OK (only_count=true)

```json
{
  "ok": true,
  "count": 45,
  "data": [],
  "timestamp": "2025-10-31T18:47:10.000000Z"
}
```

#### Ejemplo cURL

```bash
curl -X GET "https://app.terrena.com/api/catalogs/unidades?tipo=BASE&limit=50" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

---

### 4. GET /api/catalogs/categories

Obtiene las categorías de menú del POS (FloreantPOS).

#### Request

```http
GET /api/catalogs/categories?show_all=false
Authorization: Bearer {token}
```

#### Query Parameters

| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `show_all` | boolean | No | false | Muestra categorías ocultas si es `true` |

#### Response 200 OK

```json
{
  "ok": true,
  "data": [
    {
      "id": "CAT-1",
      "name": "ENTRADAS",
      "translated_name": "Entradas",
      "visible": true,
      "beverage": false,
      "sort_order": 1
    },
    {
      "id": "CAT-2",
      "name": "PLATOS FUERTES",
      "translated_name": "Platos Fuertes",
      "visible": true,
      "beverage": false,
      "sort_order": 2
    },
    {
      "id": "CAT-3",
      "name": "BEBIDAS",
      "translated_name": "Bebidas",
      "visible": true,
      "beverage": true,
      "sort_order": 3
    },
    {
      "id": "CAT-4",
      "name": "POSTRES",
      "translated_name": "Postres",
      "visible": true,
      "beverage": false,
      "sort_order": 4
    }
  ],
  "timestamp": "2025-10-31T18:48:00.000000Z"
}
```

#### Ejemplo cURL

```bash
curl -X GET "https://app.terrena.com/api/catalogs/categories" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

---

### 5. GET /api/catalogs/movement-types

Obtiene los tipos de movimiento de inventario disponibles.

#### Request

```http
GET /api/catalogs/movement-types
Authorization: Bearer {token}
```

#### Query Parameters

Ninguno.

#### Response 200 OK

```json
{
  "ok": true,
  "data": [
    {
      "value": "ENTRADA",
      "label": "Entrada",
      "description": "Entrada de inventario",
      "affects_stock": true,
      "sign": "+"
    },
    {
      "value": "SALIDA",
      "label": "Salida",
      "description": "Salida de inventario",
      "affects_stock": true,
      "sign": "-"
    },
    {
      "value": "AJUSTE",
      "label": "Ajuste",
      "description": "Ajuste de inventario",
      "affects_stock": true,
      "sign": "±"
    },
    {
      "value": "MERMA",
      "label": "Merma",
      "description": "Merma o desperdicio",
      "affects_stock": true,
      "sign": "-"
    },
    {
      "value": "RECEPCION",
      "label": "Recepción",
      "description": "Recepción de compra",
      "affects_stock": true,
      "sign": "+"
    },
    {
      "value": "TRASPASO_IN",
      "label": "Traspaso Entrada",
      "description": "Traspaso entre almacenes (entrada)",
      "affects_stock": true,
      "sign": "+"
    },
    {
      "value": "TRASPASO_OUT",
      "label": "Traspaso Salida",
      "description": "Traspaso entre almacenes (salida)",
      "affects_stock": true,
      "sign": "-"
    }
  ],
  "timestamp": "2025-10-31T18:49:00.000000Z"
}
```

#### Ejemplo cURL

```bash
curl -X GET "https://app.terrena.com/api/catalogs/movement-types" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

---

## 🚨 CÓDIGOS DE ERROR

### Error 401 - Unauthorized

```json
{
  "message": "Unauthenticated."
}
```

**Causa**: Token inválido o expirado
**Solución**: Renovar token con `/api/auth/login`

### Error 403 - Forbidden

```json
{
  "message": "Esta acción no está autorizada."
}
```

**Causa**: Usuario no tiene permisos para el recurso
**Solución**: Verificar permisos del usuario

### Error 422 - Validation Error

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "sucursal_id": [
      "El campo sucursal_id debe ser un número entero."
    ]
  }
}
```

**Causa**: Parámetros inválidos
**Solución**: Corregir parámetros según especificación

### Error 500 - Internal Server Error

```json
{
  "message": "Server Error",
  "error": "Database connection failed"
}
```

**Causa**: Error interno del servidor
**Solución**: Contactar soporte técnico

---

##  RESPONSE FORMAT STANDARD

Todas las respuestas exitosas siguen este formato:

```json
{
  "ok": true,           // boolean: indica éxito
  "data": [...],        // array/object: datos solicitados
  "timestamp": "..."    // string ISO8601: fecha/hora del servidor
}
```

Respuestas con conteo incluyen:

```json
{
  "ok": true,
  "count": 45,          // integer: total de registros
  "data": [...],
  "timestamp": "..."
}
```

---

## 🔄 VERSIONADO API

**Versión Actual**: v1 (implícita)
**Header**: `X-API-Version: 1.0`

Cuando se lance v2, se usará:
- `/api/v2/catalogs/...`
- Header: `X-API-Version: 2.0`

---

## 📊 RATE LIMITING

| Nivel | Requests | Ventana | Header |
|-------|----------|---------|--------|
| Usuario Autenticado | 60 | 1 minuto | `X-RateLimit-Limit: 60` |
| Usuario Anónimo | 10 | 1 minuto | `X-RateLimit-Limit: 10` |

**Headers en Response**:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1698780000
```

Si se excede el límite:

```json
{
  "message": "Too Many Requests",
  "retry_after": 60
}
```

Status: `429 Too Many Requests`

---

## 🧪 TESTING

### Postman Collection

Descarga la colección Postman: [TerrenaLaravel_Catalogos.postman_collection.json](../postman/TerrenaLaravel_Catalogos.postman_collection.json)

### Environments

**Local**:
```json
{
  "base_url": "http://localhost/TerrenaLaravel",
  "token": "{{login_token}}"
}
```

**Staging**:
```json
{
  "base_url": "https://staging.terrena.com",
  "token": "{{login_token}}"
}
```

**Production**:
```json
{
  "base_url": "https://app.terrena.com",
  "token": "{{login_token}}"
}
```

---

## 📝 NOTAS ADICIONALES

1. **Filtros por Defecto**: La mayoría de endpoints filtran solo registros activos por defecto. Usa `show_all=true` para ver todos.

2. **Eager Loading**: Los endpoints incluyen relaciones precargadas (ej: `almacenes.sucursal`) para reducir queries N+1.

3. **Ordenamiento**: Los resultados están ordenados alfabéticamente por defecto (`nombre` o `codigo`).

4. **Paginación**: Actualmente no hay paginación en catálogos (son tablas pequeñas). Se agregará cuando superen 1000 registros.

5. **Cache**: Las respuestas de catálogos se cachean por 1 hora en Redis. Para forzar refresh: agregar header `X-Force-Refresh: true`.

---

## 🔗 REFERENCIAS

- [API Auth Documentation](./API_AUTH.md)
- [API Inventory Documentation](./API_INVENTORY.md)
- [API Recipes Documentation](./API_RECIPES.md)
- [Error Codes Complete List](../09_VALIDACIONES/ERROR_CODES.md)

---

**Última actualización**: 31 de octubre de 2025
**Mantenido por**: Equipo TerrenaLaravel
