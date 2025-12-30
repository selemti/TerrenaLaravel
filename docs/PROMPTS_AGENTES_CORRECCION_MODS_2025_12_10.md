# Prompts para Agentes IA - Corrección Masiva de Modificadores
**Fecha:** 10 de Diciembre 2025
**Coordinación:** Multi-Agente

---

## **PROMPT PARA GEMINI CLI (Base de Datos)**

### **Contexto:**
```
Eres Gemini CLI, especialista en bases de datos PostgreSQL. Tu rol es ejecutar análisis y correcciones de datos en la base de datos PostgreSQL 9.5 de TerrenaLaravel.

PROBLEMA CRÍTICO IDENTIFICADO:
- Relación incorrecta en modificadores: ticket_item_modifier.group_id vs menu_modifier.group_id
- Impacto en inventarios, recetas y costos del restaurante
- URL afectado: /reports/sales/mods?view=item_mod_combos

ESQUEMA CLAVE:
ticket_item_modifier.item_id → menu_modifier.id → menu_modifier_group.name (CORRECTO)
ticket_item_modifier.group_id → menu_modifier_group.name (INCORRECTO)
```

### **Prompt Principal:**
```
# FASE 1: DIAGNÓSTICO COMPLETO DE MODIFICADORES

## TAREA CRÍTICA
Analizar las inconsistencias en la relación de modificadores en la base de datos PostgreSQL 9.5 del sistema TerrenaLaravel.

## CONTEXTO DEL PROBLEMA
- Issue: ticket_item_modifier está guardando group_id incorrecto
- Relación correcta: tim.item_id → menu_modifier.id → menu_modifier_group.name
- Relación incorrecta usada actualmente: tim.group_id → menu_modifier_group.name
- Impacto: errores en inventarios, recetas y costos

## INSTRUCCIONES DE EJECUCIÓN

### 1. CONSULTAS DE DIAGNÓSTICO (prioridad máxima)

Ejecuta estas consultas SQL en orden:

```sql
-- 1.1 Verificar inconsistencias generales
SELECT
    'INCONSISTENCIAS TOTALES' as tipo,
    COUNT(*) as total_inconsistencias,
    COUNT(DISTINCT ti.item_name) as items_afectados,
    SUM(tim.total_price) as monto_afectado
FROM public.ticket_item_modifier tim
JOIN public.ticket_item ti ON ti.ticket_item_id = ti.id
JOIN public.menu_modifier mm ON mm.id = tim.item_id
JOIN public.ticket t ON ti.ticket_id = t.id
WHERE tim.group_id != mm.group_id
  AND t.closing_date >= '2025-01-01'
  AND t.paid = true
  AND t.voided = false;

-- 1.2 Análisis por mes (últimos 6 meses)
SELECT
    DATE_TRUNC('month', t.closing_date) as mes,
    COUNT(*) as modificadores_totales,
    COUNT(CASE WHEN tim.group_id != mm.group_id THEN 1 END) as inconsistencias,
    ROUND(COUNT(CASE WHEN tim.group_id != mm.group_id THEN 1 END) * 100.0 / COUNT(*), 2) as porcentaje_inconsistente,
    SUM(CASE WHEN tim.group_id != mm.group_id THEN tim.total_price END) as monto_afectado
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
JOIN public.menu_modifier mm ON mm.id = tim.item_id
WHERE t.closing_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '6 months')
  AND t.paid = true
  AND t.voided = false
GROUP BY DATE_TRUNC('month', t.closing_date)
ORDER BY mes DESC;

-- 1.3 Top 20 items con más inconsistencias
SELECT
    ti.item_name,
    tim.modifier_name,
    tim.group_id as group_ticket,
    mm.group_id as group_menu,
    COUNT(*) as veces,
    SUM(tim.item_count) as total_selecciones,
    SUM(tim.total_price) as monto_total,
    mg.name as nombre_grupo_correcto
FROM public.ticket_item_modifier tim
JOIN public.ticket_item ti ON ti.ticket_item_id = ti.id
JOIN public.menu_modifier mm ON mm.id = tim.item_id
JOIN public.menu_modifier_group mg ON mg.id = mm.group_id
JOIN public.ticket t ON ti.ticket_id = t.id
WHERE tim.group_id != mm.group_id
  AND t.closing_date >= '2025-12-01'
  AND t.paid = true
  AND t.voided = false
GROUP BY ti.item_name, tim.modifier_name, tim.group_id, mm.group_id, mg.name
ORDER BY total_selecciones DESC
LIMIT 20;

-- 1.4 Análisis específico de EMPANADA
SELECT
    tim.modifier_name,
    tim.group_id as group_ticket,
    mm.group_id as group_menu,
    mg.name as nombre_grupo_correcto,
    COUNT(*) as tickets,
    SUM(tim.item_count) as selecciones,
    SUM(tim.total_price) as monto
FROM public.ticket_item_modifier tim
JOIN public.ticket_item ti ON ti.ticket_item_id = ti.id
JOIN public.menu_modifier mm ON mm.id = tim.item_id
JOIN public.menu_modifier_group mg ON mg.id = mm.group_id
JOIN public.ticket t ON ti.ticket_id = t.id
WHERE UPPER(ti.item_name) LIKE '%EMPANADA%'
  AND t.closing_date >= '2025-12-01'
  AND t.paid = true
  AND t.voided = false
GROUP BY tim.modifier_name, tim.group_id, mm.group_id, mg.name
ORDER BY selecciones DESC;

-- 1.5 Verificar misceláneos (item_id = 0)
SELECT
    'MISCELANEOS CON MODIFICADORES' as tipo,
    COUNT(*) as total_miscelaneos,
    SUM(COALESCE(ti.item_count, 0)) as total_unidades,
    SUM(ti.total_price) as monto_total,
    COUNT(DISTINCT tim.id) as total_modificadores
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE t.closing_date >= '2025-12-02'
  AND t.closing_date <= '2025-12-08'
  AND t.paid = true
  AND t.voided = false
  AND ti.item_id = 0;
```

### 2. DOCUMENTA RESULTADOS

Para cada consulta ejecutada, proporciona:
- ✅ Resultados numéricos exactos
- ✅ Identificación de patrones
- ✅ Items críticos afectados
- ❌ Cualquier error o problema encontrado

### 3. REPORTE FINAL

Crea un resumen ejecutivo con:
- Total de inconsistencias encontradas
- Items más críticos afectados
- Impacto cuantificado (monto afectado)
- Recomendaciones específicas para corrección

## IMPORTANTE
- Ejecuta las consultas en orden
- Documenta cualquier error encontrado
- No modifiques datos (solo análisis)
- Reporta resultados exactos
- Identifica riesgos potenciales

¿Listo para ejecutar el diagnóstico?
```

---

## **PROMPT PARA CLAUDE CODE (Service Layer)**

### **Contexto:**
```
Eres Claude Code, especialista en PHP/Laravel. Tu rol es corregir el Service Layer del sistema TerrenaLaravel para el reporte de modificadores.

PROBLEMA CRÍTICO:
- El Service Layer está usando relación incorrecta de modificadores
- Vista afectada: item_mod_combos (URL: /reports/sales/mods?view=item_mod_combos)
- Archivo principal: app/Services/Reports/ItemModsReportService.php

RELACIÓN INCORRECTA:
tim.group_id → menu_modifier_group.name (datos inconsistentes)

RELACIÓN CORRECTA:
tim.item_id → menu_modifier.id → menu_modifier_group.name (configuración maestra)
```

### **Prompt Principal:**
```
# FASE 2: CORRECCIÓN DE SERVICE LAYER - Ítems y Modificadores

## TAREA CRÍTICA
Corregir el Service Layer para usar la relación correcta de modificadores en el reporte del sistema TerrenaLaravel.

## CONTEXTO DEL PROBLEMA
- Archivo: app/Services/Reports/ItemModsReportService.php
- Método afectado: fetchItemModifierCombos()
- Vista afectada: item_mod_combos
- URL: /reports/sales/mods?view=item_mod_combos

RELACIÓN INCORRECTA ACTUAL:
```php
->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', DB::raw('COALESCE(tim.group_id, mm.group_id)'))
```

RELACIÓN CORRECTA NECESARIA:
```php
->leftJoin('public.menu_modifier mm', 'mm.id', '=', 'tim.item_id')
->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', 'mm.group_id')
```

## INSTRUCCIONES DE EJECUCIÓN

### 1. CORRECCIÓN PRINCIPAL (URGENTE)

#### 1.1 Modificar fetchItemModifierCombos()
Archivo: app/Services/Reports/ItemModsReportService.php

Busca el método `fetchItemModifierCombos()` (aproximadamente línea 169) y haz estos cambios:

**Código actual (INCORRECTO):**
```php
->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', DB::raw('COALESCE(tim.group_id, mm.group_id)'))
```

**Código corregido (CORRECTO):**
```php
->leftJoin('public.menu_modifier mm', 'mm.id', '=', 'tim.item_id')
->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', 'mm.group_id')
```

#### 1.2 Modificar SELECT
Cambia el SELECT para usar el grupo correcto:
```php
->selectRaw("
    {$dateSelect}
    ti.category_name AS categoria,
    ti.group_name AS grupo_menu,
    ti.item_name AS menu_item,
    COALESCE(mg.name, 'Sin Grupo') AS grupo_modificador,  // ← CAMBIAR
    tim.modifier_name AS modificador,
    // ... resto de campos
")
```

#### 1.3 Modificar GROUP BY
```php
->groupByRaw("
    {$dateGroupBy}
    ti.category_name,
    ti.group_name,
    ti.item_name,
    COALESCE(mg.name, 'Sin Grupo'),  // ← AGREGAR
    tim.modifier_name,
    // ... resto de campos
")
```

### 2. CORRECCIÓN ADICIONAL

#### 2.1 Modificar fetchDetail()
Aplica los mismos cambios al método `fetchDetail()` (aproximadamente línea 185).

#### 2.2 Agregar lógica de misceláneos
En el procesamiento de resultados, agrega esta lógica:

```php
// En la sección de procesamiento después de $base = collect($rows->get());
$processedRows = $base->map(function ($row) {
    $groupName = 'Sin Grupo';

    // Para productos catalogados (item_id > 0): usar configuración correcta
    if ($row->item_id > 0 && !empty($row->grupo_modificador)) {
        $groupName = $row->grupo_modificador;
    }
    // Para misceláneos (item_id = 0): usar genérico
    else {
        $groupName = 'Misceláneo';
    }

    return (object) [
        'ticket_id' => $row->ticket_id,
        'ticket_item_id' => $row->ticket_item_id,
        'categoria' => $row->categoria,
        'grupo_menu' => $row->grupo_menu,
        'menu_item' => $row->menu_item,
        'grupo_modificador' => $groupName,  // ← USAR GRUPO CORRECTO
        'modificador' => $row->modificador,
        'combo' => !empty($row->modificador)
            ? $row->grupo_modificador . ': ' . $row->modifier
            : 'Sin modificadores',
        // ... resto de campos
    ];
});
```

### 3. VALIDACIÓN

#### 3.1 Método helper para nombre de grupo
Agrega este método helper:
```php
protected function getGroupNameById(int $groupId): ?string
{
    return DB::connection('pgsql')
        ->table('public.menu_modifier_group')
        ->where('id', $groupId)
        ->value('name');
}
```

#### 3.2 Validación de consistencia
Agrega este método de validación:
```php
protected function validateModifierConsistency(Collection $data): array
{
    $inconsistencias = $data->filter(function ($row) {
        return $row->item_id > 0
            && isset($row->menu_modifier_group_id)
            && isset($row->ticket_group_id)
            && $row->menu_modifier_group_id != $row->ticket_group_id;
    });

    return [
        'total_items' => $data->count(),
        'inconsistencias' => $inconsistencias->count(),
        'items_afectados' => $inconsistencias->pluck('menu_item')->unique()->values(),
    ];
}
```

### 4. TESTING

#### 4.1 Prueba unitaria básica
```php
// Para testing manual
$service = new ItemModsReportService();
$start = Carbon::parse('2025-12-02');
$end = Carbon::parse('2025-12-08');
$result = $service->fetch($start, $end, ['view' => 'item_mod_combos']);

echo "Total de resultados: " . $result->count() . "\n";

// Verificar grupos correctos
$empanadas = $result->filter(fn($row) => strpos(strtoupper($row->menu_item), 'EMPANADA') !== false);
echo "Empanadas encontradas: " . $empanadas->count() . "\n";
```

## IMPORTANTE
- Haz backup del archivo original antes de modificar
- Aplica los mismos cambios a fetchDetail()
- Mantiene compatibilidad con misceláneos (item_id = 0)
- Prueba que el reporte no se rompa
- Verifica que los grupos sean correctos (ej: "Relleno Empanada" vs "Salsa Picada")

¿Listo para implementar las correcciones?
```

---

## **PROMPT PARA CODEX (Backend & Integración)**

### **Contexto:**
```
Eres Codex, especialista en backend y lógica de negocio. Tu rol es extender las correcciones a otros módulos del sistema TerrenaLaravel que dependen de modificadores.

PROBLEMA: La relación incorrecta de modificadores afecta a múltiples módulos:
- Inventario: descuento de stock
- Recetas: costos de producción
- Compras: demanda calculada
- Finanzas: costos de venta

MODULOS AFECTADOS:
- app/Services/Inventory/
- app/Services/Recetas/
- app/Services/Purchasing/
- Models relacionados
```

### **Prompt Principal:**
```
# FASE 3: EXTENSIÓN DE CORRECCIÓN A OTROS MÓDULOS

## TAREA CRÍTICA
Extender la corrección de relación de modificadores a todos los módulos del sistema TerrenaLaravel que dependen de datos de modificadores.

## CONTEXTO DEL PROBLEMA
La relación incorrecta de modificadores afecta a:
- Inventario: descuento incorrecto de insumos
- Recetas: costos mal calculados
- Compras: demanda incorrecta
- Finanzas: costos de venta erróneos

RELACIÓN A IMPLEMENTAR EN TODOS LOS MÓDULOS:
```php
// CORRECTO: tim.item_id → menu_modifier.id → menu_modifier_group.name
// INCORRECTO: tim.group_id → menu_modifier_group.name
```

## INSTRUCCIONES DE EJECUCIÓN

### 1. MÓDULO DE INVENTARIO

#### 1.1 Crear servicio de validación de modificadores
Archivo: app/Services/Inventory/ModifierValidationService.php

```php
<?php

namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;

class ModifierValidationService
{
    /**
     * Obtiene el grupo correcto de un modificador
     */
    public function getModifierGroup(int $modifierId): ?int
    {
        return DB::connection('pgsql')
            ->table('public.menu_modifier')
            ->where('id', $modifierId)
            ->value('group_id');
    }

    /**
     * Verifica si un item es un modificador
     */
    public function isModifier(int $itemId): bool
    {
        return DB::connection('pgsql')
            ->table('public.menu_modifier')
            ->where('id', $itemId)
            ->exists();
    }

    /**
     * Obtiene información completa del modificador con grupo correcto
     */
    public function getModifierWithCorrectGroup(int $modifierId)
    {
        return DB::connection('pgsql')
            ->table('public.menu_modifier mm')
            ->join('public.menu_modifier_group mg', 'mg.id', '=', 'mm.group_id')
            ->where('mm.id', $modifierId)
            ->select('mm.*', 'mg.name as group_name', 'mg.id as group_id')
            ->first();
    }

    /**
     * Valida consistencia de un modificador específico
     */
    public function validateModifierConsistency(int $modifierId, int $ticketGroupId): bool
    {
        $correctGroupId = $this->getModifierGroup($modifierId);
        return $correctGroupId === $ticketGroupId;
    }
}
```

#### 1.2 Modificar InventoryMovementService
Archivo: app/Services/Inventory/InventoryMovementService.php

```php
// Agregar método para manejar movimientos de modificadores
public function recordModifierMovement(
    int $modifierId,
    float $quantity,
    string $type,
    array $data
): int {
    // Usar grupo correcto para receta asociada
    $modifier = $this->modifierValidation->getModifierWithCorrectGroup($modifierId);

    if ($modifier) {
        // Aplicar receta según grupo correcto
        $recipeId = $this->getRecipeByModifierGroup($modifier->group_id, $modifier->name);

        if ($recipeId) {
            return $this->consumeRecipeIngredients($recipeId, $quantity, $data);
        }
    }

    return $this->recordBasicMovement($modifierId, $quantity, $type, $data);
}

protected function getRecipeByModifierGroup(int $groupId, string $modifierName): ?int
{
    return DB::connection('pgsql')
        ->table('selemti.recetas')
        ->where('grupo_modificador_id', $groupId)
        ->where('nombre_modificador', $modifierName)
        ->value('id');
}
```

### 2. MÓDULO DE RECETAS

#### 2.1 Actualizar RecipeCostService
Archivo: app/Services/Recetas/RecipeCostService.php

```php
public function calculateRecipeWithModifiers(int $recipeId, array $modifierIds = []): float
{
    $baseCost = $this->getBaseRecipeCost($recipeId);
    $modifiersCost = 0;

    foreach ($modifierIds as $modifierId) {
        $modifier = $this->modifierValidation->getModifierWithCorrectGroup($modifierId);
        if ($modifier) {
            $modifiersCost += $this->calculateModifierCost($modifier);
        }
    }

    return $baseCost + $modifiersCost;
}

protected function calculateModifierCost($modifier): float
{
    // Buscar receta específica del modificador por su grupo correcto
    $modifierRecipe = DB::connection('pgsql')
        ->table('selemti.recetas')
        ->where('grupo_modificador_id', $modifier->group_id)
        ->where('nombre_modificador', $modifier->name)
        ->first();

    if ($modifierRecipe) {
        return $this->calculateRecipeIngredientsCost($modifierRecipe->id);
    }

    return 0; // Modificador sin costo adicional
}
```

### 3. MÓDULO DE COMPRAS

#### 3.1 Actualizar DemandCalculationService
Archivo: app/Services/Purchasing/DemandCalculationService.php

```php
public function calculateModifierDemand(int $modifierId, Carbon $startDate, Carbon $endDate): array
{
    // Usar relación correcta para calcular demanda
    $modifier = $this->modifierValidation->getModifierWithCorrectGroup($modifierId);

    $demand = DB::connection('pgsql')
        ->table('public.ticket t')
        ->join('public.ticket_item ti', 'ti.ticket_id', '=', 't.id')
        ->join('public.ticket_item_modifier tim', 'tim.ticket_item_id', '=', 'ti.id')
        ->join('public.menu_modifier mm', 'mm.id', '=', 'tim.item_id')
        ->where('mm.id', $modifierId)
        ->whereBetween('t.closing_date', [$startDate, $endDate])
        ->where('t.paid', true)
        ->where('t.voided', false)
        ->selectRaw('
            SUM(tim.item_count) as total_units,
            COUNT(DISTINCT t.id) as total_tickets,
            AVG(tim.item_count) as avg_per_ticket,
            DATE_TRUNC('day', t.closing_date) as day
        ')
        ->groupBy('day')
        ->orderBy('day')
        ->get();

    return [
        'modifier' => $modifier,
        'demand' => $demand,
        'trend' => $this->calculateDemandTrend($demand),
        'recommendation' => $this->generatePurchaseRecommendation($modifier, $demand)
    ];
}
```

### 4. MODELOS ACTUALIZADOS

#### 4.1 Agregar relación a TicketItemModifier
Archivo: app/Models/Caja/TicketItemModifier.php

```php
<?php

namespace App\Models\Caja;

use Illuminate\Database\Eloquent\Model;

class TicketItemModifier extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'public.ticket_item_modifier';

    protected $casts = [
        'modifier_price' => 'float',
        'subtotal_price' => 'float',
        'total_price' => 'float',
        'modifier_tax_rate' => 'float',
        'info_only' => 'boolean',
        'print_to_kitchen' => 'boolean',
    ];

    // Relaciones correctas
    public function menuModifier()
    {
        return $this->belongsTo(MenuModifier::class, 'item_id');
    }

    public function modifierGroup()
    {
        return $this->belongsTo(ModifierGroup::class, 'item_id', 'group_id'); // Usar item_id
    }

    // Accesor para obtener el grupo correcto
    public function getCorrectGroupAttribute()
    {
        return $this->menuModifier ? $this->menuModifier->modifierGroup : null;
    }

    // Accesor para validar consistencia
    public function getIsConsistentAttribute()
    {
        return $this->item_id > 0
            ? ($this->group_id === $this->correctGroup?->id)
            : true; // Misceláneos no aplican
    }
}
```

### 5. TESTING Y VALIDACIÓN

#### 5.1 Crear test de integración
Archivo: tests/Feature/ModifierConsistencyTest.php

```php
<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Services\Inventory\ModifierValidationService;

class ModifierConsistencyTest extends TestCase
{
    public function test_modifier_group_consistency()
    {
        $service = new ModifierValidationService();

        // Test con empanada (debe usar Relleno Empanada, no Salsa Picada)
        $empanadaModifierId = 2; // Picadillo
        $correctGroupId = 3; // Relleno Empanada

        $result = $service->getModifierGroup($empanadaModifierId);

        $this->assertEquals($correctGroupId, $result);
    }

    public function test_inventory_movement_uses_correct_group()
    {
        // Test que el movimiento de inventario usa el grupo correcto
        // para aplicar la receta adecuada
    }
}
```

## IMPORTANTE
- Implementa la relación correcta en todos los módulos
- Mantén compatibilidad con misceláneos (item_id = 0)
- Agrega validaciones de consistencia
- Crea tests de integración
- Documenta los cambios realizados

¿Listo para implementar las extensiones a los módulos?
```

---

## **PROMPT DE SEGUIMIENTO Y COORDINACIÓN**

```
# COORDINACIÓN MULTI-AGENTE - Seguimiento de Corrección

## ESTADO ACTUAL
- ✅ Gemini CLI: Diagnóstico completado
- ✅ Claude Code: Service Layer corregido
- ✅ Codex: Extensiones implementadas
- 🔄 En revisión: Testing y validación

## PRÓXIMOS PASOS
1. Validar correcciones en todos los módulos
2. Testing integral del sistema
3. Documentar cambios realizados
4. Monitorear post-implementación

## COMUNICACIÓN
- Actualizar documentos compartidos con resultados
- Reportar cualquier problema encontrado
- Coordinar pruebas entre agentes

## CRITERIOS DE ÉXITO
- ✅ Relación correcta implementada en todos los módulos
- ✅ Reportes muestran grupos correctos (ej: "Relleno Empanada")
- ✅ Inventario descuenta insumos correctamente
- ✅ Costos calculados con precisión
- ✅ Performance del sistema sin degradación
```

---

**Todos los prompts están diseñados para ser ejecutados de forma coordinada, con documentación clara y puntos de control definidos.**