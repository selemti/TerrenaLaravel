# Corrección de Vistas - Reporte de Mods
**URL Base:** `http://localhost/TerrenaLaravel/reports/sales/mods`
**Fecha:** 10 de Diciembre 2025

## **VISTAS DEL SELECT (5 totales)**

### **1. `legacy` - Función Original**
- **Descripción:** Mantener comportamiento antiguo
- **Método:** `fetchData()` y `summarize()` del controller
- **Estado:** Funciona con lógica original (potencialmente con mismo problema)
- **Acción:** ✅ No necesita corrección (usa método diferente)

### **2. `summary_item_mods` - Resumen Ítems + Mods**
- **Descripción:** Vista principal de ítems con modificadores
- **Método:** `fetchSummaryItemMods()` en Service Layer
- **Estado:** ✅ YA CORREGIDO (usa relación correcta)
- **Acción:** Mantener corrección existente

### **3. `summary_items` - Resumen por Ítem**
- **Descripción:** Resumen por Categoría → Grupo → Item (sin modificadores)
- **Método:** `fetchSummaryItems()` en Service Layer
- **Estado:** ✅ NO AFECTADO (no usa modificadores)
- **Acción:** No requiere cambios

### **4. `item_mod_combos` - Combinaciones Ítem + Modificadores** ⭐
- **Descripción:** **URL ESPECÍFICA MENCIONADA**
- **Método:** `fetchItemModifierCombos()` en Service Layer
- **Estado:** ❌ **REQUIERE CORRECCIÓN URGENTE**
- **Acción:** **PRIORIDAD MÁXIMA**

### **5. `detail` - Detalle por Ticket**
- **Descripción:** Detalle a nivel de ticket individual
- **Método:** `fetchDetail()` en Service Layer
- **Estado:** ❌ **REQUIERE CORRECCIÓN URGENTE**
- **Acción:** **PRIORIDAD ALTA**

---

## **ANÁLISIS POR VISTA**

### **Vistas que USAN modificadores (requieren corrección):**

#### **4. `item_mod_combos` (URGENTE)**
```php
// Archivo: app/Services/Reports/ItemModsReportService.php:169+
protected function fetchItemModifierCombos(
    Carbon $start,
    Carbon $end,
    ?array $branchIds,
    ?array $terminalIds
): Collection {
    // ❌ CÓDIGO INCORRECTO ACTUAL:
    ->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', DB::raw('COALESCE(tim.group_id, mm.group_id)'))

    // ✅ CORRECCIÓN NECESARIA:
    ->leftJoin('public.menu_modifier mm', 'mm.id', '=', 'tim.item_id')
    ->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', 'mm.group_id')
}
```

#### **5. `detail` (ALTA)**
```php
// Archivo: app/Services/Reports/ItemModsReportService.php:185+
protected function fetchDetail(...): Collection {
    // MISMA CORRECCIÓN NECESARIA que fetchItemModifierCombos
}
```

### **Vistas que NO usan modificadores (no requieren corrección):**

#### **3. `summary_items`**
```php
// Solo usa ticket_item (no ticket_item_modifier)
protected function fetchSummaryItems(...): Collection {
    ->join('public.ticket_item ti', 'ti.ticket_id', '=', 't.id')
    // ❌ NO USA ticket_item_modifier
    // ✅ NO REQUIERE CORRECCIÓN
}
```

#### **2. `summary_item_mods`**
```php
// ✅ YA CORREGIDO anteriormente
protected function fetchSummaryItemMods(...): Collection {
    ->leftJoin('public.menu_modifier mm', 'mm.id', '=', 'tim.item_id')
    ->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', 'mm.group_id')
    // ✅ YA USA RELACIÓN CORRECTA
}
```

---

## **PLAN DE CORRECCIÓN POR VISTA**

### **Prioridad 1 (Inmediato):**
```php
// Archivo: app/Services/Reports/ItemModsReportService.php

// 1. CORREGIR fetchItemModifierCombos() - Línea ~169
protected function fetchItemModifierCombos(
    Carbon $start,
    Carbon $end,
    ?array $branchIds,
    ?array $terminalIds
): Collection {
    $query = DB::connection('pgsql')
        ->table('public.ticket as t')
        ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
        ->join('public.ticket_item_modifier as tim', 'tim.ticket_item_id', '=', 'ti.id')
        ->leftJoin('public.menu_modifier mm', 'mm.id', '=', 'tim.item_id')  // ← AGREGAR
        ->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', 'mm.group_id')  // ← MODIFICAR
        // ... resto de consulta
}

// 2. CORREGIR fetchDetail() - Línea ~185
protected function fetchDetail(
    Carbon $start,
    Carbon $end,
    ?array $branchIds,
    ?array $terminalIds
): Collection {
    // MISMA CORRECCIÓN que fetchItemModifierCombos
    ->leftJoin('public.menu_modifier mm', 'mm.id', '=', 'tim.item_id')
    ->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', 'mm.group_id')
}
```

### **Prioridad 2 (Verificación):**
- ✅ `summary_item_mods` - Verificar que ya esté corregido
- ✅ `summary_items` - Confirmar que no usa modificadores
- ✅ `legacy` - Mantener como está (no usa Service Layer)

---

## **URL ESPECÍFICA MENCIONADA**

```
http://localhost/TerrenaLaravel/reports/sales/mods?start_date=2025-12-08&end_date=2025-12-10&view=item_mod_combos&include_empty=1
```

- **Vista:** `item_mod_combos` (La que necesita corrección URGENTE)
- **Fechas:** 8-10 Diciembre 2025
- **Include Empty:** Sí (para mostrar items sin modificadores)

---

## **ESTADO ACTUAL POR VISTA**

| Vista | Usa Modificadores | Estado | Prioridad | Acción |
|-------|------------------|---------|-----------|--------|
| `legacy` | ❌ | ✅ Funciona | Baja | Mantener |
| `summary_item_mods` | ✅ | ✅ Corregido | Media | Verificar |
| `summary_items` | ❌ | ✅ OK | Baja | No cambiar |
| `item_mod_combos` | ✅ | ❌ **PROBLEMA** | **URGENTE** | **CORREGIR** |
| `detail` | ✅ | ❌ **PROBLEMA** | **ALTA** | **CORREGIR** |

---

## **ACCIONES INMEDIATAS**

1. **[URGENTE]** Corregir `fetchItemModifierCombos()` para la vista `item_mod_combos`
2. **[ALTA]** Corregir `fetchDetail()` para la vista `detail`
3. **[MEDIA]** Verificar que `fetchSummaryItemMods()` ya esté corregido
4. **[BAJA]** Confirmar que `summary_items` y `legacy` no necesitan cambios

**La URL específica que mencionas (`view=item_mod_combos`) es la de máxima prioridad y requiere corrección inmediata.**

---

**Actualizado:** 10 de Diciembre 2025
**Impacto:** 2 de 5 vistas requieren corrección urgente