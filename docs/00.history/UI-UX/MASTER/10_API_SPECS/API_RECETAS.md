# 📡 API SPECIFICATIONS - RECETAS

**Fecha**: 31 de octubre de 2025
**Versión**: 1.0
**Base URL**: `/api/recipes`

---

## 🎯 RESUMEN

Este documento especifica los endpoints de la API de Recetas que gestionan fórmulas de producción, costeo automático, ingredientes y versionado de recetas.

**Endpoints Documentados**: 7
**Autenticación**: Laravel Sanctum (Bearer Token)
**Permisos Requeridos**: `can_view_recipe_dashboard`, `can_manage_recipes`

---

## 🔐 AUTENTICACIÓN Y PERMISOS

Todos los endpoints requieren:
1. **Autenticación**: Bearer Token válido
2. **Permisos**: Según operación (ver, editar, eliminar)

```http
Authorization: Bearer {token}
```

**Permisos Disponibles**:
- `can_view_recipe_dashboard` - Ver recetas y costos
- `can_manage_recipes` - Crear/editar/eliminar recetas
- `can_approve_recipes` - Aprobar versiones de recetas

---

## 📋 ENDPOINTS

### 1. GET /api/recipes/{id}/cost

Obtiene el costo de una receta a una fecha específica (función histórica).

#### Request

```http
GET /api/recipes/{id}/cost?at=2025-10-15T10:30:00Z
Authorization: Bearer {token}
```

#### Path Parameters

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `id` | string | Sí | ID de la receta (ej: `REC-001`) |

#### Query Parameters

| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `at` | datetime ISO8601 | No | now() | Fecha para calcular costo histórico |

#### Response 200 OK

```json
{
  "data": {
    "recipe_id": "REC-001",
    "recipe_name": "Hamburguesa Clásica",
    "cost_total": 45.50,
    "cost_per_portion": 22.75,
    "yield_qty": 2.0,
    "yield_uom": "PZ",
    "ingredients_cost": 42.00,
    "overhead_cost": 3.50,
    "last_cost_update": "2025-10-15T08:00:00.000000Z",
    "cost_breakdown": [
      {
        "item_id": "ITEM-PAN-001",
        "item_name": "Pan para hamburguesa",
        "quantity": 2.0,
        "uom": "PZ",
        "unit_cost": 4.50,
        "total_cost": 9.00
      },
      {
        "item_id": "ITEM-CARNE-001",
        "item_name": "Carne molida de res",
        "quantity": 0.300,
        "uom": "KG",
        "unit_cost": 80.00,
        "total_cost": 24.00
      },
      {
        "item_id": "ITEM-QUESO-001",
        "item_name": "Queso amarillo en rebanadas",
        "quantity": 0.100,
        "uom": "KG",
        "unit_cost": 90.00,
        "total_cost": 9.00
      }
    ]
  },
  "requested_at": "2025-10-15T10:30:00.000000Z"
}
```

#### Response 404 Not Found

```json
{
  "message": "No se encontró información de costo para la receta solicitada."
}
```

#### Response 422 Validation Error

```json
{
  "message": "El parámetro at debe ser una fecha válida."
}
```

#### Ejemplo cURL

```bash
curl -X GET "https://app.terrena.com/api/recipes/REC-001/cost?at=2025-10-15T10:30:00Z" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

---

### 2. GET /api/recipes/{id}/bom/implode

**✅ IMPLEMENTADO** - Implosiona el BOM (Bill of Materials) de una receta recursivamente, resolviendo sub-recetas y agregando ingredientes duplicados.

#### Descripción

Este endpoint toma una receta (que puede contener sub-recetas como ingredientes) y la "implota" recursivamente hasta obtener SOLO ingredientes base (items de inventario). Si hay ingredientes duplicados, se agregan las cantidades.

**Casos de uso**:
- Calcular materiales exactos necesarios para producción
- Obtener lista de compras consolidada
- Análisis de dependencias de recetas
- Validar disponibilidad de inventario

#### Request

```http
GET /api/recipes/{recipe_id}/bom/implode
Authorization: Bearer {token}
```

#### Path Parameters

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `id` | string | Sí | ID de la receta (ej: `REC-HAMBUR-001`) |

#### Response 200 OK

```json
{
  "ok": true,
  "recipe_id": "REC-HAMBUR-001",
  "recipe_name": "Hamburguesa Clásica",
  "version_id": 5,
  "version_number": 1,
  "base_ingredients": [
    {
      "item_id": "ITEM-PAN-001",
      "item_name": "Pan para hamburguesa",
      "total_qty": 2.0,
      "uom": "PZ",
      "is_base": true
    },
    {
      "item_id": "ITEM-CARNE-001",
      "item_name": "Carne molida de res",
      "total_qty": 200.0,
      "uom": "GR",
      "is_base": true
    },
    {
      "item_id": "ITEM-TOMATE",
      "item_name": "Tomate",
      "total_qty": 150.0,
      "uom": "GR",
      "is_base": true
    },
    {
      "item_id": "ITEM-CEBOLLA",
      "item_name": "Cebolla",
      "total_qty": 50.0,
      "uom": "GR",
      "is_base": true
    }
  ],
  "total_ingredients": 4,
  "aggregated": true,
  "timestamp": "2025-11-01T06:20:00.000000Z"
}
```

**Campos de respuesta**:
- `ok`: Boolean - Estado de la operación
- `recipe_id`: ID de la receta procesada
- `recipe_name`: Nombre de la receta
- `version_id`: ID de la versión usada (publicada o última)
- `version_number`: Número de versión
- `base_ingredients`: Array de ingredientes base consolidados
  - `item_id`: ID del item de inventario
  - `item_name`: Nombre del item
  - `total_qty`: Cantidad total agregada (si había duplicados)
  - `uom`: Unidad de medida
  - `is_base`: true (siempre, indica que es ingrediente base)
- `total_ingredients`: Cantidad de ingredientes únicos
- `aggregated`: true (indica que duplicados fueron agregados)

#### Response 404 Not Found

```json
{
  "ok": false,
  "message": "Receta no encontrada.",
  "recipe_id": "REC-INVALID"
}
```

```json
{
  "ok": false,
  "message": "La receta no tiene versiones disponibles.",
  "recipe_id": "REC-HAMBUR-001"
}
```

#### Response 400 Bad Request

```json
{
  "ok": false,
  "message": "Profundidad máxima de recursión excedida (loop detectado en receta). Max: 10 niveles.",
  "recipe_id": "REC-LOOP-001"
}
```

#### Response 500 Internal Server Error

```json
{
  "ok": false,
  "message": "Error al procesar BOM: Database connection failed",
  "recipe_id": "REC-HAMBUR-001"
}
```

#### Ejemplo Receta Simple

**Receta**: Ensalada Simple  
**Ingredientes directos**: Lechuga (100gr) + Tomate (50gr)

```bash
curl -X GET "https://app.terrena.com/api/recipes/REC-ENSALADA-001/bom/implode" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

**Response**:
```json
{
  "ok": true,
  "recipe_id": "REC-ENSALADA-001",
  "recipe_name": "Ensalada Simple",
  "base_ingredients": [
    {"item_id": "ITEM-LECHUGA", "total_qty": 100.0, "uom": "GR"},
    {"item_id": "ITEM-TOMATE", "total_qty": 50.0, "uom": "GR"}
  ],
  "total_ingredients": 2
}
```

#### Ejemplo Receta Compuesta

**Receta**: Pasta con Salsa  
**Ingredientes**:
- Pasta (100gr) - item base
- Salsa Roja (1 porción) - **SUB-RECETA**

**Sub-receta "Salsa Roja"**:
- Tomate (200gr)
- Cebolla (50gr)

```bash
curl -X GET "https://app.terrena.com/api/recipes/REC-PASTA-SALSA/bom/implode" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

**Response** (nota que la sub-receta fue implosionada):
```json
{
  "ok": true,
  "recipe_id": "REC-PASTA-SALSA",
  "recipe_name": "Pasta con Salsa",
  "base_ingredients": [
    {"item_id": "ITEM-PASTA", "total_qty": 100.0, "uom": "GR"},
    {"item_id": "ITEM-TOMATE", "total_qty": 200.0, "uom": "GR"},
    {"item_id": "ITEM-CEBOLLA", "total_qty": 50.0, "uom": "GR"}
  ],
  "total_ingredients": 3,
  "aggregated": true
}
```

#### Ejemplo Ingredientes Duplicados

**Receta**: Combo de Salsas  
**Ingredientes**:
- Salsa Roja (1 porción) - contiene: Tomate 100gr
- Salsa Verde (1 porción) - contiene: Tomate 50gr

```bash
curl -X GET "https://app.terrena.com/api/recipes/REC-COMBO-SALSAS/bom/implode" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

**Response** (nota que tomate fue agregado):
```json
{
  "ok": true,
  "recipe_id": "REC-COMBO-SALSAS",
  "recipe_name": "Combo de Salsas",
  "base_ingredients": [
    {"item_id": "ITEM-TOMATE", "total_qty": 150.0, "uom": "GR"}
  ],
  "total_ingredients": 1,
  "aggregated": true
}
```

#### Notas Técnicas

**Lógica de Implosión**:
1. Se obtiene la versión publicada de la receta (o la última versión si no hay publicada)
2. Se itera sobre cada ingrediente de la receta
3. Si el `item_id` comienza con `REC-`, se trata como sub-receta y se resuelve recursivamente
4. Si es un item normal, se agrega directamente al resultado
5. Ingredientes duplicados se consolidan sumando cantidades
6. Protección contra loops infinitos (max 10 niveles de profundidad)

**Identificación de Sub-recetas**:
- Sub-recetas se identifican por `item_id` que comienza con `REC-`
- Ejemplo: `REC-SALSA-001` es una sub-receta, `ITEM-PAN-001` es un ingrediente base

**Protección contra Loops**:
- Si la receta A contiene receta B, y receta B contiene receta A (loop), el algoritmo detecta y previene recursión infinita
- Max profundidad: 10 niveles
- Si se excede, retorna error 400

**Performance**:
- Eager loading de relaciones para evitar N+1 queries
- Complejidad: O(n * d) donde n = ingredientes y d = profundidad máxima

---

### 3. GET /api/recipes

Obtiene el listado de recetas con filtros y paginación.

#### Request

```http
GET /api/recipes?search=hamburguesa&category=PLATOS&page=1&per_page=20
Authorization: Bearer {token}
```

#### Query Parameters

| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `search` | string | No | - | Busca en nombre y código de receta |
| `category` | string | No | - | Filtra por categoría (ENTRADAS, PLATOS, etc.) |
| `page` | integer | No | 1 | Número de página |
| `per_page` | integer | No | 20 | Registros por página (máx 100) |

#### Response 200 OK

```json
{
  "ok": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": "REC-001",
        "nombre_plato": "Hamburguesa Clásica",
        "codigo_plato_pos": "HAM-CLA",
        "categoria_plato": "PLATOS",
        "yield_qty": 2.0,
        "yield_uom": "PZ",
        "merma_porcentaje": 5.0,
        "activo": true,
        "published_version": {
          "version_number": 3,
          "cost_total": 45.50,
          "cost_per_portion": 22.75,
          "published_at": "2025-10-01T00:00:00.000000Z",
          "published_by_user_id": 1
        },
        "latest_version": {
          "version_number": 4,
          "cost_total": 46.20,
          "cost_per_portion": 23.10,
          "is_draft": true,
          "updated_at": "2025-10-30T14:00:00.000000Z"
        },
        "created_at": "2025-01-15T10:00:00.000000Z",
        "updated_at": "2025-10-30T14:00:00.000000Z"
      },
      {
        "id": "REC-002",
        "nombre_plato": "Hamburguesa con Queso",
        "codigo_plato_pos": "HAM-QUE",
        "categoria_plato": "PLATOS",
        "yield_qty": 2.0,
        "yield_uom": "PZ",
        "merma_porcentaje": 5.0,
        "activo": true,
        "published_version": {
          "version_number": 2,
          "cost_total": 48.00,
          "cost_per_portion": 24.00,
          "published_at": "2025-09-15T00:00:00.000000Z",
          "published_by_user_id": 1
        },
        "latest_version": null,
        "created_at": "2025-01-20T11:00:00.000000Z",
        "updated_at": "2025-09-15T12:00:00.000000Z"
      }
    ],
    "first_page_url": "https://app.terrena.com/api/recipes?page=1",
    "from": 1,
    "last_page": 5,
    "last_page_url": "https://app.terrena.com/api/recipes?page=5",
    "next_page_url": "https://app.terrena.com/api/recipes?page=2",
    "path": "https://app.terrena.com/api/recipes",
    "per_page": 20,
    "prev_page_url": null,
    "to": 20,
    "total": 95
  },
  "timestamp": "2025-10-31T19:00:00.000000Z"
}
```

#### Ejemplo cURL

```bash
curl -X GET "https://app.terrena.com/api/recipes?search=hamburguesa&per_page=10" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

---

### 4. GET /api/recipes/{id}

Obtiene el detalle completo de una receta incluyendo ingredientes.

#### Request

```http
GET /api/recipes/{id}
Authorization: Bearer {token}
```

#### Path Parameters

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `id` | string | Sí | ID de la receta |

#### Response 200 OK

```json
{
  "ok": true,
  "data": {
    "id": "REC-001",
    "nombre_plato": "Hamburguesa Clásica",
    "codigo_plato_pos": "HAM-CLA",
    "categoria_plato": "PLATOS",
    "yield_qty": 2.0,
    "yield_uom": "PZ",
    "merma_porcentaje": 5.0,
    "instrucciones": "1. Formar las hamburguesas con la carne\n2. Cocinar a término medio\n3. Calentar el pan\n4. Armar la hamburguesa",
    "notas": "Usar carne fresca, no congelada",
    "activo": true,
    "ingredientes": [
      {
        "id": 1,
        "receta_id": "REC-001",
        "item_id": "ITEM-PAN-001",
        "item_nombre": "Pan para hamburguesa",
        "cantidad": 2.0,
        "uom": "PZ",
        "costo_unitario": 4.50,
        "costo_total": 9.00,
        "sort_order": 1
      },
      {
        "id": 2,
        "receta_id": "REC-001",
        "item_id": "ITEM-CARNE-001",
        "item_nombre": "Carne molida de res",
        "cantidad": 0.300,
        "uom": "KG",
        "costo_unitario": 80.00,
        "costo_total": 24.00,
        "sort_order": 2
      },
      {
        "id": 3,
        "receta_id": "REC-001",
        "item_id": "ITEM-QUESO-001",
        "item_nombre": "Queso amarillo en rebanadas",
        "cantidad": 0.100,
        "uom": "KG",
        "costo_unitario": 90.00,
        "costo_total": 9.00,
        "sort_order": 3
      }
    ],
    "versiones": [
      {
        "version_number": 4,
        "cost_total": 46.20,
        "cost_per_portion": 23.10,
        "is_draft": true,
        "is_published": false,
        "published_at": null,
        "updated_at": "2025-10-30T14:00:00.000000Z"
      },
      {
        "version_number": 3,
        "cost_total": 45.50,
        "cost_per_portion": 22.75,
        "is_draft": false,
        "is_published": true,
        "published_at": "2025-10-01T00:00:00.000000Z",
        "updated_at": "2025-10-01T00:00:00.000000Z"
      }
    ],
    "created_at": "2025-01-15T10:00:00.000000Z",
    "updated_at": "2025-10-30T14:00:00.000000Z"
  },
  "timestamp": "2025-10-31T19:05:00.000000Z"
}
```

#### Response 404 Not Found

```json
{
  "message": "Receta no encontrada."
}
```

#### Ejemplo cURL

```bash
curl -X GET "https://app.terrena.com/api/recipes/REC-001" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

---

### 5. POST /api/recipes

Crea una nueva receta con sus ingredientes.

#### Request

```http
POST /api/recipes
Authorization: Bearer {token}
Content-Type: application/json
```

#### Request Body

```json
{
  "nombre_plato": "Pizza Margarita",
  "codigo_plato_pos": "PIZZA-MAR",
  "categoria_plato": "PLATOS",
  "yield_qty": 1.0,
  "yield_uom": "PZ",
  "merma_porcentaje": 3.0,
  "instrucciones": "1. Preparar la masa\n2. Agregar salsa y mozzarella\n3. Hornear 12 minutos a 250°C",
  "notas": "Usar horno de leña preferentemente",
  "ingredientes": [
    {
      "item_id": "ITEM-MASA-001",
      "cantidad": 0.250,
      "uom": "KG"
    },
    {
      "item_id": "ITEM-SALSA-001",
      "cantidad": 0.100,
      "uom": "LT"
    },
    {
      "item_id": "ITEM-QUESO-MOZ-001",
      "cantidad": 0.150,
      "uom": "KG"
    }
  ]
}
```

#### Request Body Schema

| Campo | Tipo | Requerido | Validación | Descripción |
|-------|------|-----------|------------|-------------|
| `nombre_plato` | string | Sí | max:150, unique | Nombre de la receta |
| `codigo_plato_pos` | string | No | max:50, unique | Código en POS |
| `categoria_plato` | string | No | - | Categoría |
| `yield_qty` | number | Sí | min:0.001 | Cantidad que produce |
| `yield_uom` | string | Sí | exists:unidades_medida,codigo | UOM de producción |
| `merma_porcentaje` | number | No | min:0, max:100 | % de merma esperada |
| `instrucciones` | text | No | - | Pasos de preparación |
| `notas` | text | No | - | Notas adicionales |
| `ingredientes` | array | Sí | min:1 | Lista de ingredientes |
| `ingredientes.*.item_id` | string | Sí | exists:items,id | ID del ítem |
| `ingredientes.*.cantidad` | number | Sí | min:0.001 | Cantidad requerida |
| `ingredientes.*.uom` | string | Sí | exists:unidades_medida,codigo | Unidad de medida |

#### Response 201 Created

```json
{
  "ok": true,
  "data": {
    "id": "REC-105",
    "nombre_plato": "Pizza Margarita",
    "codigo_plato_pos": "PIZZA-MAR",
    "categoria_plato": "PLATOS",
    "yield_qty": 1.0,
    "yield_uom": "PZ",
    "merma_porcentaje": 3.0,
    "cost_total": 28.50,
    "cost_per_portion": 28.50,
    "activo": true,
    "ingredientes_count": 3,
    "created_at": "2025-10-31T19:10:00.000000Z",
    "updated_at": "2025-10-31T19:10:00.000000Z"
  },
  "message": "Receta creada exitosamente.",
  "timestamp": "2025-10-31T19:10:00.000000Z"
}
```

#### Response 422 Validation Error

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "nombre_plato": [
      "El campo nombre_plato es obligatorio."
    ],
    "yield_qty": [
      "El campo yield_qty debe ser mayor a 0."
    ],
    "ingredientes": [
      "Debe agregar al menos un ingrediente."
    ],
    "ingredientes.0.item_id": [
      "El ítem seleccionado no existe."
    ]
  }
}
```

#### Ejemplo cURL

```bash
curl -X POST "https://app.terrena.com/api/recipes" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_plato": "Pizza Margarita",
    "codigo_plato_pos": "PIZZA-MAR",
    "yield_qty": 1.0,
    "yield_uom": "PZ",
    "ingredientes": [
      {"item_id": "ITEM-MASA-001", "cantidad": 0.250, "uom": "KG"}
    ]
  }'
```

---

### 6. PUT /api/recipes/{id}

Actualiza una receta existente (crea nueva versión si hay cambios significativos).

#### Request

```http
PUT /api/recipes/{id}
Authorization: Bearer {token}
Content-Type: application/json
```

#### Request Body

```json
{
  "nombre_plato": "Pizza Margarita Premium",
  "merma_porcentaje": 2.5,
  "ingredientes": [
    {
      "item_id": "ITEM-MASA-001",
      "cantidad": 0.300,
      "uom": "KG"
    },
    {
      "item_id": "ITEM-SALSA-001",
      "cantidad": 0.120,
      "uom": "LT"
    },
    {
      "item_id": "ITEM-QUESO-MOZ-PREMIUM-001",
      "cantidad": 0.200,
      "uom": "KG"
    }
  ]
}
```

#### Response 200 OK

```json
{
  "ok": true,
  "data": {
    "id": "REC-105",
    "nombre_plato": "Pizza Margarita Premium",
    "version_created": true,
    "current_version": 2,
    "cost_total_old": 28.50,
    "cost_total_new": 32.80,
    "cost_change_pct": 15.09,
    "updated_at": "2025-10-31T19:15:00.000000Z"
  },
  "message": "Receta actualizada. Se creó nueva versión debido a cambio de costo >2%.",
  "timestamp": "2025-10-31T19:15:00.000000Z"
}
```

#### Response 404 Not Found

```json
{
  "message": "Receta no encontrada."
}
```

#### Ejemplo cURL

```bash
curl -X PUT "https://app.terrena.com/api/recipes/REC-105" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Content-Type: application/json" \
  -d '{
    "merma_porcentaje": 2.5,
    "ingredientes": [...]
  }'
```

---

### 7. DELETE /api/recipes/{id}

Elimina (soft delete) una receta.

#### Request

```http
DELETE /api/recipes/{id}
Authorization: Bearer {token}
```

#### Response 200 OK

```json
{
  "ok": true,
  "message": "Receta eliminada exitosamente.",
  "timestamp": "2025-10-31T19:20:00.000000Z"
}
```

#### Response 404 Not Found

```json
{
  "message": "Receta no encontrada."
}
```

#### Ejemplo cURL

```bash
curl -X DELETE "https://app.terrena.com/api/recipes/REC-105" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

---

## 🔧 FUNCIONALIDADES ESPECIALES

### Versionado Automático

El sistema crea automáticamente una nueva versión de la receta cuando:

1. **Cambio de costo >2%**: Si al actualizar ingredientes el costo cambia más del 2%
2. **Publicación manual**: Usuario marca una versión como "publicada"
3. **Cambio en yield**: Modificación del rendimiento (yield_qty o yield_uom)

```json
{
  "version_number": 4,
  "cost_total": 46.20,
  "is_draft": true,
  "is_published": false,
  "created_at": "2025-10-30T14:00:00.000000Z"
}
```

### Costeo Histórico

La función `fn_recipe_cost_at(recipe_id, timestamp)` permite consultar el costo de una receta en cualquier punto del tiempo:

```sql
SELECT * FROM selemti.fn_recipe_cost_at('REC-001', '2025-09-15 10:00:00');
```

Esto es útil para:
- Análisis de variación de costos
- Auditorías
- Reportes históricos de rentabilidad
- Justificación de cambios de precio

### Implosión de Recetas

(Pendiente de implementar)

La implosión permite descomponer una receta en sus ingredientes básicos, útil para:
- Recetas que usan otras recetas como ingredientes
- Cálculo de costo real hasta materias primas
- Análisis de rentabilidad preciso

---

## 🚨 CÓDIGOS DE ERROR

| Código | Mensaje | Causa | Solución |
|--------|---------|-------|----------|
| 401 | Unauthenticated | Token inválido | Renovar token |
| 403 | Forbidden | Sin permisos | Verificar rol del usuario |
| 404 | Not Found | Receta no existe | Verificar ID |
| 422 | Validation Error | Datos inválidos | Corregir request |
| 500 | Internal Server Error | Error de servidor | Contactar soporte |

---

## 📊 REGLAS DE NEGOCIO

### Validación de Ingredientes

1. **No duplicados**: No se puede agregar el mismo `item_id` dos veces
2. **Cantidad mínima**: `cantidad` debe ser > 0.001
3. **UOM válida**: Debe existir en catálogo de unidades
4. **Item activo**: El item debe estar activo

### Versionado

1. **Versión inicial**: Al crear receta se crea versión 1 automáticamente
2. **Publicación**: Solo puede haber 1 versión publicada por receta
3. **Eliminación**: No se pueden eliminar versiones, solo la receta completa

### Costeo

1. **Recalculo automático**: Al guardar/actualizar se recalcula costo
2. **Snapshot diario**: Se guarda snapshot de costos a las 00:00 hrs
3. **Alertas**: Si costo cambia >5% se genera alerta automática

---

## 🔗 REFERENCIAS

- [API Catalogos Documentation](./API_CATALOGOS.md)
- [API Inventory Documentation](./API_INVENTORY.md)
- [Error Codes Complete List](../09_VALIDACIONES/ERROR_CODES.md)
- [Recipe Cost Calculation Logic](../05_SPECS_TECNICAS/SERVICIOS_BACKEND.md#recipecostingservice)

---

**Última actualización**: 31 de octubre de 2025
**Mantenido por**: Equipo TerrenaLaravel
