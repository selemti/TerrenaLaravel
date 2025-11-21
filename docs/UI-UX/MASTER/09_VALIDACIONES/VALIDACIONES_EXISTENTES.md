# ✅ MATRIZ DE VALIDACIONES EXISTENTES - TerrenaLaravel ERP

**Fecha**: 31 de octubre de 2025
**Versión**: 1.0
**Fuente**: Código actual extraído de Livewire Components

---

## 📋 ÍNDICE

1. [Catálogos](#catálogos)
2. [Recetas](#recetas)
3. [Inventario](#inventario)
4. [Compras](#compras)
5. [Reglas de Negocio](#reglas-de-negocio)

---

## 🏢 CATÁLOGOS

### Sucursales

| Campo | Tipo | Requerido | Min | Max | Regex | Default | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|-------|---------|------------|---------------|
| `clave` | string | ✅ | - | 16 | - | - | required, unique(cat_sucursales) | La clave es obligatoria y debe ser única |
| `nombre` | string | ✅ | - | 120 | - | - | required | El nombre es obligatorio |
| `ubicacion` | string | ❌ | - | 160 | - | null | nullable | - |
| `activo` | boolean | ❌ | - | - | - | true | boolean | - |

**Reglas Especiales**:
- La `clave` se convierte automáticamente a mayúsculas: `strtoupper(trim($this->clave))`
- Los campos de texto se limpian con `trim()` antes de guardar

---

### Proveedores

| Campo | Tipo | Requerido | Min | Max | Regex | Default | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|-------|---------|------------|---------------|
| `rfc` | string | ✅ | - | 20 | - | - | required, unique(cat_proveedores) | El RFC es obligatorio y debe ser único |
| `nombre` | string | ✅ | - | 120 | - | - | required | El nombre es obligatorio |
| `telefono` | string | ❌ | - | 30 | - | null | nullable | - |
| `email` | string | ❌ | - | 120 | - | null | nullable, email | El email debe ser válido |
| `activo` | boolean | ❌ | - | - | - | true | boolean | - |

**Reglas Especiales**:
- El `rfc` se convierte a mayúsculas: `strtoupper(trim($this->rfc))`
- Valida que la tabla `cat_proveedores` exista antes de procesar

**Código de Validación**:
```php
protected function rules(): array
{
    $rfcRules = ['required','string','max:20'];

    if ($this->tableReady) {
        $rfcRules[] = Rule::unique('cat_proveedores', 'rfc')->ignore($this->editId);
    }

    return [
        'rfc'      => $rfcRules,
        'nombre'   => ['required','string','max:120'],
        'telefono' => ['nullable','string','max:30'],
        'email'    => ['nullable','email','max:120'],
        'activo'   => ['boolean'],
    ];
}
```

---

### Almacenes

| Campo | Tipo | Requerido | Min | Max | Regex | Default | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|-------|---------|------------|---------------|
| `nombre` | string | ✅ | - | 120 | - | - | required | El nombre es obligatorio |
| `sucursal_id` | integer | ✅ | - | - | - | - | required, exists(cat_sucursales,id) | La sucursal es obligatoria y debe existir |
| `tipo` | string | ❌ | - | 50 | - | 'GENERAL' | nullable, in(GENERAL,FRIO,SECO) | Tipo inválido |
| `activo` | boolean | ❌ | - | - | - | true | boolean | - |

**Tipos Permitidos**:
- `GENERAL` - Almacén general
- `FRIO` - Almacén refrigerado/congelado
- `SECO` - Almacén de secos

---

### Unidades de Medida

| Campo | Tipo | Requerido | Min | Max | Regex | Default | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|-------|---------|------------|---------------|
| `codigo` | string | ✅ | - | 10 | - | - | required, unique(unidades_medida) | El código es obligatorio y debe ser único |
| `nombre` | string | ✅ | - | 100 | - | - | required | El nombre es obligatorio |
| `tipo` | string | ✅ | - | - | - | - | required, in(BASE,COMPRA,SALIDA) | Tipo inválido |
| `categoria` | string | ✅ | - | - | - | - | required, in(MASA,VOLUMEN,UNIDAD) | Categoría inválida |
| `es_base` | boolean | ❌ | - | - | - | false | boolean | - |
| `factor_conversion_base` | decimal | ❌ | 0 | - | - | 1.0 | nullable, numeric, min:0 | Debe ser un número positivo |
| `decimales` | integer | ❌ | 0 | 6 | - | 2 | nullable, integer, min:0, max:6 | - |

**Tipos Permitidos**:
- `BASE` - Unidad base del sistema
- `COMPRA` - Unidad de compra (ej: caja de 24 unidades)
- `SALIDA` - Unidad de salida/venta

**Categorías Permitidas**:
- `MASA` - Kilogramos, gramos, toneladas
- `VOLUMEN` - Litros, mililitros, galones
- `UNIDAD` - Piezas, cajas, paquetes

---

### Políticas de Stock

| Campo | Tipo | Requerido | Min | Max | Regex | Default | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|-------|---------|------------|---------------|
| `item_id` | string | ✅ | - | - | - | - | required, exists(items,id) | El ítem es obligatorio y debe existir |
| `almacen_id` | integer | ✅ | - | - | - | - | required, exists(cat_almacenes,id) | El almacén es obligatorio y debe existir |
| `stock_min` | decimal | ✅ | 0 | - | - | 0 | required, numeric, min:0 | Debe ser mayor o igual a 0 |
| `stock_max` | decimal | ✅ | 0 | - | - | 0 | required, numeric, min:0, gte:stock_min | Debe ser mayor o igual al mínimo |
| `stock_seguridad` | decimal | ❌ | 0 | - | - | 0 | nullable, numeric, min:0 | - |
| `lead_time_dias` | integer | ❌ | 0 | - | - | 7 | nullable, integer, min:0 | - |
| `metodo_reposicion` | string | ❌ | - | - | - | 'MIN_MAX' | nullable, in(MIN_MAX,SMA,CONSUMO_POS) | Método inválido |

**Métodos de Reposición**:
- `MIN_MAX` - Reabastecer cuando stock < mínimo hasta nivel máximo
- `SMA` - Media móvil simple de consumo
- `CONSUMO_POS` - Basado en consumo real de ventas POS

**Regla de Negocio**:
```
stock_max >= stock_min
stock_seguridad <= stock_min (recomendado)
lead_time_dias típico: 1-30 días
```

---

## 🍽️ RECETAS

### Receta (Header)

| Campo | Tipo | Requerido | Min | Max | Regex | Default | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|-------|---------|------------|---------------|
| `nombre_plato` | string | ✅ | - | 150 | - | - | required, unique(recetas) | El nombre es obligatorio y debe ser único |
| `codigo_plato_pos` | string | ❌ | - | 50 | - | null | nullable, unique(recetas) | El código debe ser único si se proporciona |
| `categoria_plato` | string | ❌ | - | 50 | - | null | nullable | - |
| `yield_qty` | decimal | ✅ | 0.001 | - | - | - | required, numeric, min:0.001 | La cantidad debe ser mayor a 0 |
| `yield_uom` | string | ✅ | - | 20 | - | - | required, exists(unidades_medida,codigo) | La unidad es obligatoria y debe existir |
| `merma_porcentaje` | decimal | ❌ | 0 | 100 | - | 0 | nullable, numeric, min:0, max:100 | Debe estar entre 0 y 100 |
| `instrucciones` | text | ❌ | - | - | - | null | nullable | - |
| `notas` | text | ❌ | - | - | - | null | nullable | - |
| `activo` | boolean | ❌ | - | - | - | true | boolean | - |

**Reglas de Negocio**:
- El `nombre_plato` no puede contener el prefijo `REC-MOD-` (reservado para modificadores)
- El `codigo_plato_pos` no puede empezar con `MOD-` (reservado para modificadores)
- El `yield_qty` debe ser consistente con la UOM (ej: 2.5 KG, 1 PZ)

---

### Ingredientes de Receta

| Campo | Tipo | Requerido | Min | Max | Regex | Default | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|-------|---------|------------|---------------|
| `receta_id` | string | ✅ | - | - | - | - | required, exists(recetas,id) | La receta es obligatoria y debe existir |
| `item_id` | string | ✅ | - | - | - | - | required, exists(items,id) | El ítem es obligatorio y debe existir |
| `cantidad` | decimal | ✅ | 0.001 | - | - | - | required, numeric, min:0.001 | La cantidad debe ser mayor a 0 |
| `uom` | string | ✅ | - | 20 | - | - | required, exists(unidades_medida,codigo) | La unidad es obligatoria y debe existir |
| `sort_order` | integer | ❌ | 0 | - | - | 0 | nullable, integer, min:0 | - |
| `notas` | text | ❌ | - | - | - | null | nullable | - |

**Reglas de Negocio**:
- No puede haber ingredientes duplicados en una misma receta: `unique:receta_id,item_id`
- La cantidad debe ser consistente con la UOM del ítem
- El `sort_order` determina el orden de aparición en la receta

---

## 📦 INVENTARIO

### Items / Insumos

| Campo | Tipo | Requerido | Min | Max | Regex | Default | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|-------|---------|------------|---------------|
| `codigo` | string | ✅ | - | 64 | `^[A-Z]{3}-[A-Z]{3}-\d{5}$` | auto | required, unique(items), regex | Formato: CAT-SUB-##### |
| `nombre` | string | ✅ | - | 150 | - | - | required | El nombre es obligatorio |
| `categoria_id` | integer | ✅ | - | - | - | - | required, exists(item_categories,id) | La categoría es obligatoria |
| `unidad_medida_id` | integer | ✅ | - | - | - | - | required, exists(unidades_medida,id) | La UOM es obligatoria |
| `perecible` | boolean | ❌ | - | - | - | false | boolean | - |
| `requiere_lote` | boolean | ❌ | - | - | - | auto | boolean | Se calcula automáticamente si perecible=true |
| `costo_promedio` | decimal | ❌ | 0 | - | - | 0 | nullable, numeric, min:0 | - |
| `activo` | boolean | ❌ | - | - | - | true | boolean | - |

**Reglas Especiales**:
- El `codigo` se genera automáticamente basado en categoría y subcategoría
- Si `perecible=true`, entonces `requiere_lote=true` automáticamente
- El `costo_promedio` se calcula automáticamente basado en recepciones

**Formato de Código**:
```
CAT-SUB-#####
│   │   └─────── Consecutivo de 5 dígitos (00001-99999)
│   └─────────── Prefijo de subcategoría (3 letras mayúsculas)
└─────────────── Prefijo de categoría (3 letras mayúsculas)

Ejemplo: ALI-CAR-00125 (Alimentos → Carnes → consecutivo 125)
```

---

### Recepciones

| Campo | Tipo | Requerido | Min | Max | Regex | Default | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|-------|---------|------------|---------------|
| `proveedor_id` | integer | ✅ | - | - | - | - | required, exists(cat_proveedores,id) | El proveedor es obligatorio |
| `almacen_id` | integer | ✅ | - | - | - | - | required, exists(cat_almacenes,id) | El almacén es obligatorio |
| `fecha_recepcion` | date | ✅ | - | - | - | today | required, date, lte:today | No puede ser fecha futura |
| `documento` | string | ❌ | - | 50 | - | null | nullable | - |
| `lines` | array | ✅ | 1 | - | - | - | required, array, min:1 | Debe agregar al menos una línea |

**Líneas de Recepción**:

| Campo | Tipo | Requerido | Min | Max | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|------------|---------------|
| `lines.*.item_id` | string | ✅ | - | - | required, exists(items,id) | El ítem es obligatorio |
| `lines.*.cantidad` | decimal | ✅ | 0.001 | - | required, numeric, min:0.001 | La cantidad debe ser mayor a 0 |
| `lines.*.uom_compra` | string | ✅ | - | 20 | required, exists(unidades_medida,codigo) | La UOM es obligatoria |
| `lines.*.lote` | string | condicional | - | 50 | required_if(item.perecible,true) | El lote es obligatorio para ítems perecibles |
| `lines.*.caducidad` | date | condicional | - | - | required_if(item.perecible,true), date, gt:today+7 | La caducidad debe ser al menos 7 días en el futuro |
| `lines.*.costo_unitario` | decimal | ✅ | 0 | - | required, numeric, min:0 | El costo es obligatorio |
| `lines.*.temperatura` | decimal | ❌ | -50 | 100 | nullable, numeric, min:-50, max:100 | Temperatura entre -50°C y 100°C |

**Reglas de Negocio**:
- Items perecibles **REQUIEREN** lote y caducidad
- La caducidad debe ser al menos 7 días posterior a la fecha actual
- La cantidad se convierte automáticamente a UOM base usando `factor_conversion`
- Se genera automáticamente un snapshot de costo al postear la recepción

---

### Transferencias

| Campo | Tipo | Requerido | Min | Max | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|------------|---------------|
| `warehouse_from_id` | integer | ✅ | - | - | required, exists(cat_almacenes,id), different:warehouse_to_id | El almacén origen es obligatorio y debe ser diferente al destino |
| `warehouse_to_id` | integer | ✅ | - | - | required, exists(cat_almacenes,id), different:warehouse_from_id | El almacén destino es obligatorio y debe ser diferente al origen |
| `fecha` | date | ✅ | - | - | required, date, lte:today | No puede ser fecha futura |
| `notas` | text | ❌ | - | - | nullable | - |
| `lines` | array | ✅ | 1 | - | required, array, min:1 | Debe agregar al menos un ítem |

**Líneas de Transferencia**:

| Campo | Tipo | Requerido | Min | Max | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|------------|---------------|
| `lines.*.item_id` | string | ✅ | - | - | required, exists(items,id) | El ítem es obligatorio |
| `lines.*.cantidad` | decimal | ✅ | 0.001 | - | required, numeric, min:0.001, lte:stock_disponible | La cantidad debe ser mayor a 0 y no exceder el stock disponible |
| `lines.*.lote_id` | integer | condicional | - | - | required_if(item.requiere_lote,true), exists(lotes,id) | El lote es obligatorio si el ítem lo requiere |

**Reglas de Negocio**:
- La cantidad transferida no puede exceder el stock disponible en el almacén origen
- Para items con lotes, se debe especificar el lote exacto a transferir (FEFO)
- Se aplica tolerancia de ±5% en la recepción (configurable en políticas)

---

### Conteos Físicos

| Campo | Tipo | Requerido | Min | Max | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|------------|---------------|
| `almacen_id` | integer | ✅ | - | - | required, exists(cat_almacenes,id) | El almacén es obligatorio |
| `fecha` | date | ✅ | - | - | required, date, lte:today | No puede ser fecha futura |
| `tipo` | string | ✅ | - | - | required, in(TOTAL,PARCIAL,CICLICO) | Tipo inválido |
| `lines` | array | ✅ | 1 | - | required, array, min:1 | Debe contar al menos un ítem |

**Líneas de Conteo**:

| Campo | Tipo | Requerido | Min | Max | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|------------|---------------|
| `lines.*.item_id` | string | ✅ | - | - | required, exists(items,id) | El ítem es obligatorio |
| `lines.*.cantidad_contada` | decimal | ✅ | 0 | - | required, numeric, min:0 | La cantidad debe ser mayor o igual a 0 |
| `lines.*.lote_id` | integer | condicional | - | - | required_if(item.requiere_lote,true) | El lote es obligatorio si el ítem lo requiere |

**Tipos de Conteo**:
- `TOTAL` - Conteo completo de todo el almacén
- `PARCIAL` - Conteo de categorías específicas
- `CICLICO` - Conteo rotativo programado

**Estados del Flujo**:
```
BORRADOR → EN_PROCESO → AJUSTADO
```

---

## 🛒 COMPRAS

### Solicitudes de Compra

| Campo | Tipo | Requerido | Min | Max | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|------------|---------------|
| `sucursal_id` | integer | ✅ | - | - | required, exists(cat_sucursales,id) | La sucursal es obligatoria |
| `almacen_id` | integer | ✅ | - | - | required, exists(cat_almacenes,id) | El almacén es obligatorio |
| `fecha_requerida` | date | ✅ | - | - | required, date, gte:today | La fecha requerida debe ser hoy o posterior |
| `prioridad` | string | ❌ | - | - | nullable, in(URGENTE,ALTA,NORMAL,BAJA) | Prioridad inválida |
| `lines` | array | ✅ | 1 | - | required, array, min:1 | Debe agregar al menos un ítem |

**Líneas de Solicitud**:

| Campo | Tipo | Requerido | Min | Max | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|------------|---------------|
| `lines.*.item_id` | string | ✅ | - | - | required, exists(items,id) | El ítem es obligatorio |
| `lines.*.cantidad_solicitada` | decimal | ✅ | 0.001 | - | required, numeric, min:0.001 | La cantidad debe ser mayor a 0 |
| `lines.*.proveedor_preferente_id` | integer | ❌ | - | - | nullable, exists(cat_proveedores,id) | El proveedor debe existir |

---

### Órdenes de Compra

| Campo | Tipo | Requerido | Min | Max | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|------------|---------------|
| `proveedor_id` | integer | ✅ | - | - | required, exists(cat_proveedores,id) | El proveedor es obligatorio |
| `sucursal_id` | integer | ✅ | - | - | required, exists(cat_sucursales,id) | La sucursal es obligatoria |
| `almacen_id` | integer | ✅ | - | - | required, exists(cat_almacenes,id) | El almacén es obligatorio |
| `fecha_entrega_estimada` | date | ✅ | - | - | required, date, gte:today | La fecha de entrega debe ser hoy o posterior |
| `monto_total` | decimal | ❌ | 0 | - | nullable, numeric, min:0 | - |
| `lines` | array | ✅ | 1 | - | required, array, min:1 | Debe agregar al menos un ítem |

**Líneas de Orden**:

| Campo | Tipo | Requerido | Min | Max | Validación | Mensaje Error |
|-------|------|-----------|-----|-----|------------|---------------|
| `lines.*.item_id` | string | ✅ | - | - | required, exists(items,id) | El ítem es obligatorio |
| `lines.*.cantidad` | decimal | ✅ | 0.001 | - | required, numeric, min:0.001 | La cantidad debe ser mayor a 0 |
| `lines.*.precio_unitario` | decimal | ✅ | 0 | - | required, numeric, min:0 | El precio es obligatorio |
| `lines.*.uom_compra` | string | ✅ | - | 20 | required, exists(unidades_medida,codigo) | La UOM es obligatoria |

**Estados del Flujo**:
```
BORRADOR → APROBADA → ENVIADA → RECIBIDA → CERRADA
```

**Reglas de Aprobación**:
- Órdenes < $5,000: Aprobación automática
- Órdenes >= $5,000: Requiere aprobación manual de Gerente
- Órdenes >= $20,000: Requiere aprobación de Director

---

## 📏 REGLAS DE NEGOCIO

### Conversión de Unidades

**Regla**: Al registrar cantidades, siempre convertir a UOM base para kardex

**Ejemplo**:
```
Recibo: 5 CAJAS de Coca-Cola (1 CAJA = 24 PZ)
Conversión: 5 * 24 = 120 PZ (UOM base)
Registrar en kardex: 120 PZ
```

**Validación**:
- El sistema debe tener definido el `factor_conversion` entre UOM compra y UOM base
- Si no existe conversión, mostrar error: "No se encontró factor de conversión entre CAJA y PZ para este ítem"

---

### Control FEFO (First Expire First Out)

**Regla**: Al despachar items perecibles, siempre usar el lote más próximo a caducar

**Validación**:
- Al crear transferencia o salida, el sistema debe sugerir automáticamente el lote con caducidad más cercana
- Usuario puede override manual, pero debe justificar con nota
- Alerta si se intenta despachar lote con caducidad > 30 días cuando hay lotes con caducidad < 30 días

---

### Tolerancia en Recepciones

**Regla**: Permitir discrepancias de ±5% entre cantidad ordenada vs recibida

**Ejemplo**:
```
Ordenado: 100 KG
Tolerancia: ±5 KG
Rango aceptable: 95 - 105 KG

Recibido: 97 KG → ✅ OK (dentro de tolerancia)
Recibido: 92 KG → ❌ Requiere override con permiso especial
Recibido: 108 KG → ❌ Requiere override con permiso especial
```

**Validación**:
- Calcular desviación: `abs(qty_recibida - qty_ordenada) / qty_ordenada * 100`
- Si desviación <= 5%: Procesar automáticamente
- Si desviación > 5%: Bloquear posteo, requerir permiso `inventory.receptions.override_tolerance`

---

### Stock Negativo

**Regla**: NO permitir stock negativo (excepto con permiso especial)

**Validación**:
```php
if ($stock_actual - $cantidad_salida < 0) {
    if (!$user->hasPermissionTo('inventory.allow_negative')) {
        throw new ValidationException('Stock insuficiente. Stock actual: ' . $stock_actual);
    }
}
```

**Permiso Requerido**: `inventory.allow_negative` (solo Gerentes y Admins)

---

### Versionado de Recetas

**Regla**: Crear nueva versión automáticamente si el cambio de costo es >2%

**Ejemplo**:
```
Versión 3: Costo = $45.50
Actualización: Costo nuevo = $46.80
Cambio: (46.80 - 45.50) / 45.50 * 100 = 2.86%

Como 2.86% > 2% → Crear versión 4 automáticamente
```

**Validación**:
- Calcular `cost_change_pct` al guardar cambios
- Si `cost_change_pct > 2`: Crear nueva versión, notificar usuario
- Si `cost_change_pct <= 2`: Actualizar versión actual (borrador)

---

### Caducidad Mínima

**Regla**: No aceptar recepciones con caducidad < 7 días

**Validación**:
```php
if ($caducidad < now()->addDays(7)) {
    throw new ValidationException('La caducidad debe ser al menos 7 días en el futuro');
}
```

**Excepción**: Con permiso `inventory.accept_short_expiry` se puede override

---

## 🔗 REFERENCIAS

- [API Catalogos Documentation](../10_API_SPECS/API_CATALOGOS.md)
- [API Recetas Documentation](../10_API_SPECS/API_RECETAS.md)
- [Error Codes](./ERROR_CODES.md)
- [Permissions Matrix](../../v6/PERMISSIONS_MATRIX_V6.md)

---

**Última actualización**: 31 de octubre de 2025
**Mantenido por**: Equipo TerrenaLaravel
