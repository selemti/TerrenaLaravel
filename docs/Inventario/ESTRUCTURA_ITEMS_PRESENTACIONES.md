# 📦 ESTRUCTURA DE ITEMS Y PRESENTACIONES

**Fecha:** 2025-11-03  
**Versión:** 1.0

---

## 🎯 SEPARACIÓN DE RESPONSABILIDADES

### ❌ **INCORRECTO** (Antes)
```
items
├─ nombre: "Aceite de Soya Nutrioli"
└─ descripcion: "Aceite vegetal 3 pzas × 946 ml (2.838 L total)"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                ⚠️ INFORMACIÓN DE PRESENTACIÓN EN LUGAR EQUIVOCADO
```

### ✅ **CORRECTO** (Ahora)
```
items (Maestro del producto)
├─ id: ACEITE-NUT-01
├─ nombre: "Aceite de Soya Nutrioli"
├─ descripcion: "Aceite vegetal de soya 100% puro"
├─ unidad_medida: L
└─ unidad_medida_id: 2

item_vendor (Presentaciones por proveedor)
├─ item_id: ACEITE-NUT-01
├─ vendor_id: 4 (Costco)
├─ presentacion: "Caja 3 pzas × 946 ml"  ← AQUÍ VA
├─ unidad_presentacion_id: 15 (CAJA)
├─ factor_a_canonica: 2.838 (L)
└─ costo_ultimo: 150.00
```

---

## 📋 CAMPOS POR TABLA

### `selemti.items` (Información del PRODUCTO)

| Campo | Tipo | Propósito | Ejemplo |
|-------|------|-----------|---------|
| `id` | VARCHAR(20) | Código único | `MP-LAC-00001` |
| `nombre` | VARCHAR | **Nombre del producto** | `Leche Deslactosada Member's Mark` |
| `descripcion` | TEXT | **Características del producto** | `Leche deslactosada reducida en lactosa` |
| `categoria_id` | VARCHAR | Categoría | `CAT-LACT` |
| `unidad_medida` | VARCHAR | Unidad canónica | `L` |
| `unidad_medida_id` | INT | FK a cat_unidades | `2` |
| `tipo` | ENUM | Clasificación | `MATERIA_PRIMA` |
| `perishable` | BOOLEAN | ¿Caduca? | `true` |

**✅ Qué SÍ debe tener:**
- Nombre genérico del producto
- Descripción de características inherentes al producto (ej: "100% puro", "deslactosada", "grano entero")
- Propiedades físicas (perecedero, temperaturas)
- Categorización

**❌ Qué NO debe tener:**
- ❌ Información de presentación ("3 pzas de...")
- ❌ Cantidades de empaque
- ❌ Información específica del proveedor
- ❌ Precios

---

### `selemti.item_vendor` (Información de PRESENTACIÓN)

| Campo | Tipo | Propósito | Ejemplo |
|-------|------|-----------|---------|
| `item_id` | VARCHAR(20) | FK a items | `MP-LAC-00001` |
| `vendor_id` | BIGINT | FK a proveedores | `4` |
| `presentacion` | VARCHAR | **Presentación comercial** | `Caja 12 pzas × 1 L` |
| `unidad_presentacion_id` | INT | Unidad de empaque | `15` (CAJA) |
| `factor_a_canonica` | NUMERIC | Conversión a unidad base | `12.0` L |
| `costo_ultimo` | NUMERIC | Precio de compra | `220.00` |
| `codigo_proveedor` | VARCHAR | SKU del proveedor | `LAC-MM-12X1L` |
| `lead_time_dias` | INT | Días de entrega | `3` |
| `preferente` | BOOLEAN | ¿Proveedor principal? | `true` |

**✅ Qué SÍ debe tener:**
- Descripción completa del empaque comercial
- Cantidad de piezas y contenido por pieza
- Factor de conversión exacto
- Información específica del proveedor
- Costos

**❌ Qué NO debe tener:**
- ❌ Características del producto (van en items)
- ❌ Propiedades físicas (van en items)

---

## 🔄 EJEMPLOS COMPLETOS

### Ejemplo 1: Aceite Nutrioli

#### `items`
```sql
id: ACEITE-NUT-01
nombre: Aceite de Soya Nutrioli
descripcion: Aceite vegetal de soya 100% puro
categoria_id: CAT-ABARR
unidad_medida: L
unidad_medida_id: 2
tipo: MATERIA_PRIMA
perishable: false
activo: true
```

#### `item_vendor` (Costco)
```sql
item_id: ACEITE-NUT-01
vendor_id: 4
presentacion: Caja 3 botellas × 946 ml
unidad_presentacion_id: 15  -- CAJA
factor_a_canonica: 2.838    -- 3 × 0.946 = 2.838 L
costo_ultimo: 150.00
moneda: MXN
codigo_proveedor: NUT-SOY-3X946
preferente: true
```

#### `item_vendor` (Sam's Club - proveedor alternativo)
```sql
item_id: ACEITE-NUT-01
vendor_id: 3
presentacion: Paquete 2 botellas × 1.5 L
unidad_presentacion_id: 16  -- PAQUETE
factor_a_canonica: 3.0      -- 2 × 1.5 = 3.0 L
costo_ultimo: 165.00
moneda: MXN
codigo_proveedor: 550123
preferente: false
```

---

### Ejemplo 2: Leche Deslactosada

#### `items`
```sql
id: LECHE-MM-01
nombre: Leche Deslactosada Member's Mark
descripcion: Leche deslactosada reducida en lactosa, ultrapasteurizada
categoria_id: CAT-LACT
unidad_medida: L
unidad_medida_id: 2
tipo: MATERIA_PRIMA
perishable: true
temperatura_min: 2
temperatura_max: 8
activo: true
```

#### `item_vendor` (Sam's Club)
```sql
item_id: LECHE-MM-01
vendor_id: 3
presentacion: Caja 12 envases Tetra Pak × 1 L
unidad_presentacion_id: 15  -- CAJA
factor_a_canonica: 12.0     -- 12 × 1 = 12 L
costo_ultimo: 220.00
moneda: MXN
codigo_proveedor: MM-LAC-12X1L
lead_time_dias: 2
preferente: true
```

---

## 🎨 FLUJO DE CAPTURA

### Paso 1: Alta Rápida (InsumoCreate)
```
Usuario captura:
✓ Nombre: "Aceite de Soya Nutrioli"
✓ Categoría/Subcategoría
✓ Unidad base: L
✓ Perecible: No

Se guarda en items:
{
  nombre: "Aceite de Soya Nutrioli",
  descripcion: null,  ← VACÍO inicialmente
  unidad_medida: "L"
}
```

### Paso 2: Completar (ItemsManage Modal)
```
Usuario complementa:
✓ Descripcion: "Aceite vegetal de soya 100% puro"
✓ Unidades de compra/salida
✓ Temperaturas (si aplica)

✓ PROVEEDORES (tabla item_vendor):
  - Proveedor: Costco
  - Presentación: "Caja 3 botellas × 946 ml"  ← AQUÍ
  - Factor: 2.838 L
  - Costo: $150.00
```

---

## ⚠️ ERRORES COMUNES

### ❌ Error 1: Mezclar presentación con descripción
```sql
-- MAL
descripcion: "Aceite vegetal 3 pzas × 946 ml (2.838 L total)"

-- BIEN
descripcion: "Aceite vegetal de soya 100% puro"
+ item_vendor.presentacion: "Caja 3 botellas × 946 ml"
```

### ❌ Error 2: Nombre muy específico
```sql
-- MAL
nombre: "Aceite Nutrioli Botella 946ml Caja 3 Piezas"

-- BIEN
nombre: "Aceite de Soya Nutrioli"
```

### ❌ Error 3: No usar item_vendor
```sql
-- MAL: Todo en items, sin usar item_vendor
items.descripcion: "Caja 12 × 1L, proveedor Costco, $220"

-- BIEN: Separado correctamente
items.descripcion: "Leche deslactosada reducida en lactosa"
item_vendor.presentacion: "Caja 12 × 1 L"
item_vendor.costo_ultimo: 220.00
```

---

## 💡 BENEFICIOS DE LA SEPARACIÓN

### 1. Múltiples Proveedores para el Mismo Item
```
ACEITE-NUT-01 (un solo item)
├─ Costco: Caja 3 × 946ml = $150
├─ Sam's: Paquete 2 × 1.5L = $165
└─ Walmart: Botella individual 1L = $60
```

### 2. Comparación de Precios
```sql
SELECT 
  i.nombre,
  v.nombre as proveedor,
  iv.presentacion,
  iv.costo_ultimo,
  (iv.costo_ultimo / iv.factor_a_canonica) as costo_por_litro
FROM items i
JOIN item_vendor iv ON iv.item_id = i.id
JOIN cat_proveedores v ON v.id = iv.vendor_id
WHERE i.id = 'ACEITE-NUT-01'
ORDER BY costo_por_litro;
```

### 3. Cambio de Presentación sin Afectar Recetas
```
Si Costco cambia de "3 × 946ml" a "4 × 1L":
✓ Actualizar solo item_vendor
✓ Recetas siguen funcionando (usan unidad canónica L)
✓ Reportes muestran la presentación correcta
```

### 4. Historial de Costos por Presentación
```
Mismo producto, diferentes presentaciones en el tiempo:
2024-01: Caja 3 × 946ml = $150
2024-06: Caja 4 × 1L    = $180  (cambio de presentación)
2024-12: Caja 4 × 1L    = $195  (aumento de precio)
```

---

## 🔧 MIGRACIÓN APLICADA

```bash
php artisan migrate --path=database/migrations/2025_11_03_202400_clean_item_descriptions.php
```

**Limpia:**
- ❌ "Aceite vegetal 3 pzas × 946 ml" 
- ✅ "Aceite vegetal de soya 100% puro"

**Resultado:**
- Items con descripciones limpias
- Presentaciones pendientes de capturar en item_vendor

---

## ✅ CHECKLIST DE VALIDACIÓN

Al capturar un item, verificar:

- [ ] **Nombre**: ¿Es genérico y sin presentación?
- [ ] **Descripción**: ¿Describe el producto, no el empaque?
- [ ] **item_vendor**: ¿Existe al menos un registro con presentación?
- [ ] **Presentación**: ¿Incluye cantidad y unidad de empaque?
- [ ] **Factor**: ¿Convierte correctamente a unidad canónica?

---

**Fin del documento**
