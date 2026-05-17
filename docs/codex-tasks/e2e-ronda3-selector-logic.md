# Codex Task — E2E Ronda 3: Lógica SELECTOR híbrida en PosConsumptionService

## Contexto de negocio — LEER ANTES DE TOCAR CÓDIGO

### Campo canónico: `selemti.items.tipo_venta_pos VARCHAR(20)`

El comportamiento POS de cada ítem queda definido **en el ítem mismo**, no en el mapping
ni en la receta. La migración `2026_05_16_210000_add_tipo_venta_pos_to_items.php` ya
aplicó la columna con el siguiente CHECK:

```sql
CHECK (tipo_venta_pos IN ('PLATILLO','SELECTOR_DEFINE','PRODUCCION','DIRECTO'))
```

| Valor | Significado |
|-------|-------------|
| `PLATILLO` | Tiene receta de venta. ADICIONAL suma; SELECTOR reemplaza slot. |
| `SELECTOR_DEFINE` | Sin receta base. El modifier SELECTOR define qué SKU se descuenta. Aplica a Malanga (sabores), Suerox (sabores), chicles, cualquier producto con variante. |
| `PRODUCCION` | Se produce internamente. No se vende directo en POS. |
| `DIRECTO` | Se vende tal cual sin receta ni selector. |
| `NULL` | Insumo puro. No aparece en POS. |

Los ítems del seeder E2E tienen este campo poblado:
- INS-001..025 → `NULL`
- PROD-001..010 → `PRODUCCION`

Los platillos reales de producción (Picada, Chilaquiles, Enchiladas) tendrán `PLATILLO`.
Malanga, Suerox, chicles → `SELECTOR_DEFINE` cuando se registren en el catálogo.

### Los 3 tipos en flujo POS

**Tipo PLATILLO** — Chilaquiles, Enchiladas, Picada:
- Tienen una receta con ingredientes base definidos
- `ADICIONAL` suma consumo (Extra queso, Extra proteína)
- `SELECTOR` reemplaza un slot de la receta base (qué salsa, qué proteína base)

**Tipo PRODUCCION** — Salsa Roja Base, Pollo Deshebrado:
- No se venden directamente en POS
- Se producen con `ProductionService` y generan stock de ítems PROD-*
- Los platillos PLATILLO los consumen como ingredientes

**Tipo SELECTOR_DEFINE** — Malanga (sabores), Suerox (sabores), chicles:
- El menu item de POS es genérico ("Malanga", "Suerox")
- **NO existe receta base** — `pos_menu_item_recipe_mapping.recipe_id = NULL`
- El SELECTOR define QUÉ ítem exacto se descuenta de inventario
- Mismo precio para todos los sabores (o puede variar — no afecta inventario)

---

## Cómo leer el tipo en PosConsumptionService

```php
// Al resolver un menu item, cargar también el item del catálogo para leer tipo_venta_pos
$menuMapping = $this->modifierService->findMenuItemMapping($menuItemId);

// Si no hay mapping: item POS no configurado → warning, no procesar
if (! $menuMapping) {
    $summary['warnings'][] = "menu_item {$menuItemId} sin configuración POS";
    continue;
}

// El tipo_consumo viene del ítem asociado al menu_item_id
// (Para SELECTOR_DEFINE: menuMapping->recipe_id es null, no hay receta que descontar)
$tipoConsumo = $this->resolveItemTipoVentaPos($menuMapping->menu_item_id);

match ($tipoConsumo) {
    'PLATILLO'        => $this->procesarPlatillo($menuMapping, $selectorUoms, ...),
    'SELECTOR_DEFINE' => $this->procesarSelectorDefine(...),   // solo descuenta modifiers SELECTOR
    default           => $summary['warnings'][] = "tipo_venta_pos desconocido o NULL para menu_item {$menuItemId}",
};
```

Nota: `resolveItemTipoVentaPos(int $menuItemId)` necesita un mapeo de `menu_item_id`
(ID del POS) al `item_code` del catálogo de inventario. Hoy ese mapeo **no existe
explícitamente** — se puede agregar un campo `item_id` a `pos_menu_item_recipe_mapping`
o hacer el lookup por nombre como fallback. **Usar el campo `recipe_id` como proxy**:
si `recipe_id IS NOT NULL` → PLATILLO; si `recipe_id IS NULL` → SELECTOR_DEFINE.
Esto es suficiente para la corrida E2E.

---

## Problema actual en PosConsumptionService

`confirmTicket()` procesa todos los modifiers con la misma lógica sin distinguir tipo:

```php
// Actual — INCORRECTO para SELECTOR
foreach ($modifiers as $modifier) {
    $qty = $this->resolveModifierQty($mapping, $modifier->item_count);
    $this->deductInventoryItem($mapping->item_id, $qty, ...);
}
```

Para un SELECTOR en un PLATILLO, esto **suma** el ítem del selector sobre la receta base,
cuando debería **reemplazar** el slot.

---

## Diseño de la solución híbrida

### Regla de negocio

| Situación | Comportamiento |
|-----------|---------------|
| Item `PLATILLO` + modifier `ADICIONAL` | Siempre **suma** al descuento base de la receta |
| Item `PLATILLO` + modifier `SELECTOR` | **Reemplaza** el slot de la receta con mismo `uom_receta`. Fallback: suma si no hay match de uom. |
| Item `SELECTOR_DEFINE` + modifier `SELECTOR` | **Define** el único descuento. No hay receta base que procesar. |

### Cómo identificar el slot a reemplazar

`tipo_efecto = 'SELECTOR'` → el ítem del selector reemplaza al ingrediente de la receta
que tenga el **mismo `uom_receta`** que el `uom` del mapping del selector.
Si no hay match de uom → fallback seguro: suma como ADICIONAL.

---

## Cambios requeridos

### 1. `PosConsumptionService::confirmTicket()` — separar SELECTOR de ADICIONAL

```php
// En el loop de modifiers dentro de confirmTicket()
$selectorItemIds = []; // item_ids que ya fueron cubiertos por un SELECTOR

foreach ($modifiers as $modifier) {
    $mapping = $this->modifierService->findMapping(
        $modifier->item_id,
        $modifier->modifier_name ?? ''
    );
    if (! $mapping || ! $mapping->item_id) {
        continue;
    }

    if ($mapping->tipo_efecto === 'SELECTOR') {
        // Resolver uom del selector para identificar qué slot reemplaza
        $qty = $this->resolveModifierQty($mapping, $modifier->item_count);
        $this->deductInventoryItem($mapping->item_id, $qty, ...);
        // Registrar que este uom fue cubierto por selector
        $selectorItemIds[$mapping->uom] = $mapping->item_id;
        $summary['modifier_movements']++;
    } else {
        // ADICIONAL — procesar después de SELECTOR
        $pendingAdicionales[] = [$modifier, $mapping];
    }
}

// Procesar ADICIONAL
foreach ($pendingAdicionales as [$modifier, $mapping]) {
    $qty = $this->resolveModifierQty($mapping, $modifier->item_count);
    $this->deductInventoryItem($mapping->item_id, $qty, ...);
    $summary['modifier_movements']++;
}
```

### 2. `PosConsumptionService::deductRecipeIngredients()` — respetar slots SELECTOR

Cuando se descontan los ingredientes de la receta base, **saltarse** los ítems cuyo
`uom_receta` ya fue cubierto por un SELECTOR:

```php
private function deductRecipeIngredients(
    int $recipeId,
    int $quantity,
    int $ticketId,
    ?int $userId,
    ?string $almacenId,
    array $selectorUoms = []    // ← nuevo parámetro
): int {
    // ...
    foreach ($ingredients as $ingredient) {
        // Si este slot fue cubierto por un SELECTOR, saltarlo
        if (isset($selectorUoms[$ingredient->uom_receta])) {
            continue;
        }
        $this->deductInventoryItem($ingredient->item_id, $qty, ...);
    }
}
```

### 3. Coordinar el flujo en `confirmTicket()`

```php
// 1. Procesar todos los modifiers, separando SELECTOR de ADICIONAL
// 2. Construir $selectorUoms (uom → item_id) de los SELECTORs aplicados
// 3. Llamar deductRecipeIngredients(..., selectorUoms: $selectorUoms)
// 4. Procesar ADICIONAL
```

### 4. Caso Tipo C (sin receta base, solo SELECTOR define el descuento)

Si `pos_menu_item_recipe_mapping` no tiene entrada para el `menu_item_id` (Malanga no
tiene receta de venta), la lógica actual ya maneja esto correctamente: si no hay
`recipeMapping`, se salta `deductRecipeIngredients()` y solo procesa los modifiers.

**No se necesita cambio adicional para Tipo C** — funciona si el menu item no tiene
mapping de receta. Solo hay que asegurarse de NO crear un mapping de receta vacío para
los ítems Tipo C.

---

## Tests nuevos requeridos (en PosConsumptionServiceTest o archivo separado)

### Test A — SELECTOR reemplaza slot de receta base

```
Dado: Receta "Picada" con ingrediente Salsa Genérica (0.2 KG, uom_receta=KG)
Dado: Modifier SELECTOR "Salsa Roja" mapeado a PROD-001 (qty=0.2 KG, uom=KG)
Cuando: confirmTicket con 1 Picada + SELECTOR Salsa Roja
Entonces: PROD-001 descontado 0.2 KG; Salsa Genérica NO descontada
```

### Test B — ADICIONAL suma sobre la receta base

```
Dado: Receta "Picada" con ingrediente Pollo (0.1 KG)
Dado: Modifier ADICIONAL "Extra Pollo" mapeado a PROD-006 (qty=0.05 KG)
Cuando: confirmTicket con 1 Picada + ADICIONAL Extra Pollo
Entonces: PROD-006 descontado 0.15 KG total (0.1 base + 0.05 extra)
```

### Test C — Tipo C (Malanga con sabor como SELECTOR, sin receta base)

```
Dado: menu_item_id=55 "Malanga" sin entrada en pos_menu_item_recipe_mapping
Dado: Modifier SELECTOR "Malanga Chocolate" mapeado a item INS-025 (qty=1 PZ)
Cuando: confirmTicket con 1 Malanga + SELECTOR Malanga Chocolate
Entonces: INS-025 descontado 1 PZ; ningún otro ítem descontado
```

### Test D — SELECTOR sin receta con uom diferente (fallback a ADICIONAL)

```
Dado: Receta base con ingrediente en KG
Dado: Modifier SELECTOR con uom=PZ (no hay slot KG en la receta que reemplazar)
Cuando: confirmTicket
Entonces: ambos descontados (fallback seguro — suma, no reemplaza)
```

---

## Verificación

```bash
php artisan test tests/Feature/Services/Pos/PosConsumptionServiceTest.php
php artisan test  # sin regresiones
```

**Criterio de éxito:**
- Los 4 tests existentes siguen pasando
- Tests A, B, C, D nuevos pasan
- No hay descuento doble cuando hay SELECTOR + ingrediente base del mismo uom
