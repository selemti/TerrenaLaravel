# Plan de Delegación - Corrección Masiva de Modificadores
**Fecha:** 10 de Diciembre 2025
**Coordinación:** Multi-Agente

## **ESTRATEGIA MULTI-AGENTE**

### **Claude Code (Coordinador Principal)**
- **Rol:** Coordinación general y corrección de Service Layer
- **Archivos:** `app/Services/Reports/ItemModsReportService.php`
- **Responsabilidades:**
  - Corregir lógica de relación de modificadores
  - Implementar validaciones
  - Testing de reportes
  - Coordinar con otros agentes

### **Codex (Backend & Database)**
- **Rol:** Corrección de consultas SQL y lógica de negocio
- **Archivos:** Service Layer, Models, Migrations
- **Responsabilidades:**
  - Optimizar consultas SQL
  - Crear modelos de validación
  - Implementar correcciones en backend
  - Testing de integración

### **Gemini CLI (Base de Datos)**
- **Rol:** Análisis y corrección de datos
- **Base de datos:** PostgreSQL 9.5 (schemas: public, selemti)
- **Responsabilidades:**
  - Ejecutar consultas de diagnóstico
  - Corregir datos inconsistentes
  - Validar integridad referencial
  - Monitorear performance

---

## **FASES Y DELEGACIÓN**

### **FASE 1: DIAGNÓSTICO COMPLETO (Inmediato)**

#### **1.1 Validación de Consistencia [Gemini CLI]**
```sql
-- Consulta para ejecutar en PostgreSQL
-- Archivo: scripts/diagnostico_inconsistencias_modificadores.sql

-- 1. Verificar inconsistencias generales
SELECT
    COUNT(*) as total_inconsistencias,
    COUNT(DISTINCT ti.item_name) as items_afectados
FROM public.ticket_item_modifier tim
JOIN public.ticket_item ti ON ti.ticket_item_id = ti.id
JOIN public.menu_modifier mm ON mm.id = tim.item_id
JOIN public.ticket_item t ON ti.ticket_id = t.id
WHERE tim.group_id != mm.group_id
  AND t.closing_date >= '2025-01-01'
  AND t.paid = true
  AND t.voided = false;

-- 2. Listado detallado de inconsistencias
SELECT
    ti.item_name,
    tim.modifier_name,
    tim.group_id as group_ticket,
    mm.group_id as group_menu,
    COUNT(*) as veces,
    SUM(tim.item_count) as total_selecciones
FROM public.ticket_item_modifier tim
JOIN public.ticket_item ti ON ti.ticket_item_id = ti.id
JOIN public.menu_modifier mm ON mm.id = tim.item_id
JOIN public.ticket_item t ON ti.ticket_id = t.id
WHERE tim.group_id != mm.group_id
  AND t.closing_date >= '2025-12-02'
  AND t.closing_date <= '2025-12-08'
  AND t.paid = true
  AND t.voided = false
GROUP BY ti.item_name, tim.modifier_name, tim.group_id, mm.group_id
ORDER BY total_selecciones DESC;
```

#### **1.2 Análisis de Impacto [Gemini CLI]**
```sql
-- Impacto por mes
-- Archivo: scripts/analisis_impacto_mensual_modificadores.sql

SELECT
    DATE_TRUNC('month', t.closing_date) as mes,
    COUNT(*) as modificadores_totales,
    COUNT(CASE WHEN tim.group_id != mm.group_id THEN 1 END) as inconsistencias,
    ROUND(COUNT(CASE WHEN tim.group_id != mm.group_id THEN 1 END) * 100.0 / COUNT(*), 2) as porcentaje_inconsistente,
    SUM(tim.total_price) as monto_afectado
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
JOIN public.menu_modifier mm ON mm.id = tim.item_id
WHERE t.closing_date >= '2025-01-01'
  AND t.paid = true
  AND t.voided = false
GROUP BY DATE_TRUNC('month', t.closing_date)
ORDER BY mes;
```

#### **1.3 Validación de Misceláneos [Gemini CLI]**
```sql
-- Verificar misceláneos con item_id = 0
-- Archivo: scripts/analisis_miscelaneos_modificadores.sql

SELECT
    COUNT(*) as total_miscelaneos,
    SUM(COALESCE(ti.item_count, 0)) as total_unidades,
    SUM(ti.total_price) as monto_total,
    COUNT(DISTINCT tim.id) as total_modificadores_misc
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE t.closing_date >= '2025-12-02'
  AND t.closing_date <= '2025-12-08'
  AND t.paid = true
  AND t.voided = false
  AND ti.item_id = 0;
```

---

### **FASE 2: CORRECCIÓN DE SERVICE LAYER (Prioridad Alta)**

#### **2.1 Corrección Principal [Claude Code]**
```php
// Archivo: app/Services/Reports/ItemModsReportService.php

// EN MÉTODO fetchItemModifierCombos(), reemplazar:
❌ ->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', DB::raw('COALESCE(tim.group_id, mm.group_id)'))

// POR:
✅ ->leftJoin('public.menu_modifier mm', 'mm.id', '=', 'tim.item_id')
   ->leftJoin('public.menu_modifier_group mgr', 'mgr.id', '=', 'mm.group_id')

// SELECT modificado:
SELECT
    ti.category_name AS categoria,
    ti.group_name AS grupo_menu,
    ti.item_name AS menu_item,
    COALESCE(mg.name, 'Sin Grupo') AS grupo_modificador, -- Usar grupo correcto
    tim.modifier_name AS modificador,
    // ... resto de campos
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
LEFT JOIN public.menu_modifier mm ON mm.id = tim.item_id  -- ← AGREGAR
LEFT JOIN public.menu_modifier_group mg ON mg.id = COALESCE(mm.group_id, tim.group_id)  -- ← MODIFICAR
WHERE t.closing_date BETWEEN :start AND :end
  AND t.paid = true
  AND t.voided = false;
```

#### **2.2 Lógica Condicional [Claude Code]**
```php
// En el procesamiento de resultados:
$byTicketItem = $allRows->map(function ($row) {
    $groupName = 'Sin Grupo';

    // Para productos catalogados (item_id > 0): usar configuración correcta
    if ($row->item_id > 0 && !empty($row->grupo_modificador)) {
        $groupName = $row->grupo_modificador;
    }
    // Para misceláneos (item_id = 0): usar group_id del ticket o genérico
    else {
        $groupName = $row->tim_group_id ? $this->getGroupNameById($row->tim_group_id) : 'Misceláneo';
    }

    return (object) [
        'ticket_id' => $row->ticket_id,
        'ticket_item_id' => $row->ticket_item_id,
        'categoria' => $row->categoria,
        'grupo_menu' => $row->grupo_menu,
        'menu_item' => $row->menu_item,
        'grupo_modificador' => $groupName, // ← USAR GRUPO CORRECTO
        'modificador' => $row->modificador,
        // ... resto de campos
    ];
});
```

#### **2.3 Validación Adicional [Codex]**
```php
// Archivo: app/Services/Reports/ItemModsReportService.php

protected function validateModifierConsistency(Collection $data): array
{
    $inconsistencies = $data->filter(function ($row) {
        return $row->item_id > 0 && !empty($row->menu_modifier_group_id)
            && isset($row->ticket_group_id)
            && $row->menu_modifier_group_id != $row->ticket_group_id;
    });

    return [
        'total_items' => $data->count(),
        'inconsistencias' => $inconsistencies->count(),
        'items_afectados' => $inconsistencies->pluck('menu_item')->unique()->values(),
    ];
}

protected function getGroupNameById(int $groupId): ?string
{
    return DB::connection('pgsql')
        ->table('public.menu_modifier_group')
        ->where('id', $groupId)
        ->value('name');
}
```

---

### **FASE 3: EXTENSIÓN A OTROS MÓDULOS (Prioridad Media)**

#### **3.1 Módulo de Inventario [Codex]**
```php
// Archivo: app/Services/Inventory/InventoryMovementService.php

public function recordMovement(int $itemId, float $quantity, string $type, array $data)
{
    // Validar si es modificador y usar grupo correcto
    if ($this->isModifier($itemId)) {
        $correctGroup = $this->getModifierGroup($itemId);
        // Aplicar lógica de descuento con grupo correcto
    }

    return parent::recordMovement($itemId, $quantity, $type, $data);
}

protected function isModifier(int $itemId): bool
{
    return DB::connection('pgsql')
        ->table('public.menu_modifier')
        ->where('id', $itemId)
        ->exists();
}

protected function getModifierGroup(int $itemId): ?int
{
    return DB::connection('pgsql')
        ->table('public.menu_modifier')
        ->where('id', $itemId)
        ->value('group_id');
}
```

#### **3.2 Módulo de Recetas [Codex]**
```php
// Archivo: app/Services/Recetas/RecipeCostService.php

public function calculateRecipeCost(int $recipeId, array $modifierIds = []): float
{
    $totalCost = $this->getBaseRecipeCost($recipeId);

    foreach ($modifierIds as $modifierId) {
        // Usar grupo correcto para buscar costos de modificadores
        $modifier = $this->getModifierWithCorrectGroup($modifierId);
        $totalCost += $this->calculateModifierCost($modifier);
    }

    return $totalCost;
}

protected function getModifierWithCorrectGroup(int $modifierId)
{
    return DB::connection('pgsql')
        ->table('public.menu_modifier mm')
        ->join('public.menu_modifier_group mg', 'mg.id', '=', 'mm.group_id')
        ->where('mm.id', $modifierId)
        ->select('mm.*', 'mg.name as group_name')
        ->first();
}
```

---

### **FASE 4: CORRECCIÓN DE DATOS HISTÓRICOS (Prioridad Baja)**

#### **4.1 Evaluación de Corrección [Gemini CLI]**
```sql
-- Archivo: scripts/evaluar_correccion_datos_historicos.sql

-- Cuántos registros se corregirían
SELECT
    'REGISTROS A CORREGIR' as tipo,
    COUNT(*) as total,
    SUM(tim.total_price) as monto_afectado
FROM public.ticket_item_modifier tim
JOIN public.menu_modifier mm ON mm.id = tim.item_id
WHERE tim.group_id != mm.group_id;

-- Verificar impacto por periodo
SELECT
    DATE_TRUNC('month', t.closing_date) as mes,
    COUNT(*) as registros_a_corregir,
    SUM(tim.total_price) as monto_afectado
FROM public.ticket_item_modifier tim
JOIN public.menu_modifier mm ON mm.id = tim.item_id
JOIN public.ticket_item ti ON ti.ticket_item_id = ti.id
JOIN public.ticket t ON ti.ticket_id = t.id
WHERE tim.group_id != mm.group_id
  AND t.closing_date >= '2025-01-01'
GROUP BY DATE_TRUNC('month', t.closing_date)
ORDER BY mes;
```

#### **4.2 Script de Corrección (Opcional) [Gemini CLI]**
```sql
-- Archivo: scripts/corregir_inconsistencias_modificadores.sql
-- ⚠️ SOLO EJECUTAR DESPUÉS DE BACKUP COMPLETO Y VALIDACIÓN

-- Corrección segura (con validación)
BEGIN;

-- Crear tabla de respaldo
CREATE TABLE ticket_item_modifier_backup_20251210 AS
SELECT * FROM public.ticket_item_modifier;

-- Corrección de group_id basado en configuración correcta
UPDATE public.ticket_item_modifier tim
SET group_id = mm.group_id
FROM public.menu_modifier mm
WHERE tim.item_id = mm.id
  AND tim.group_id != mm.group_id;

-- Verificar corrección
SELECT
    'POST-CORRECCION' as estado,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN tim.group_id != mm.group_id THEN 1 END) como_inconsistencias_restantes
FROM public.ticket_item_modifier tim
JOIN public.menu_modifier mm ON mm.id = tim.item_id;

COMMIT;
```

---

### **FASE 5: PREVENCIÓN Y MONITOREO**

#### **5.1 Validaciones Proactivas [Claude Code]**
```php
// Archivo: app/Providers/AppServiceProvider.php

public function boot()
{
    // Validación de consistencia de modificadores
    Validator::extend('modifier_group_consistency', function ($attribute, $value, $parameters) {
        $modifierId = $value[0] ?? null;
        $groupId = $value[1] ?? null;

        if (!$modifierId || !$groupId) return true;

        $correctGroupId = DB::connection('pgsql')
            ->table('public.menu_modifier')
            ->where('id', $modifierId)
            ->value('group_id');

        return $correctGroupId == $groupId;
    });
}
```

#### **5.2 Job de Monitoreo [Claude Code]**
```php
// Archivo: app/Jobs/VerifyModifierConsistencyJob.php

class VerifyModifierConsistencyJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function handle()
    {
        $inconsistencias = DB::connection('pgsql')
            ->table('public.ticket_item_modifier tim')
            ->join('public.menu_modifier mm', 'mm.id', '=', 'tim.item_id')
            ->where('tim.group_id', '!=', 'mm.group_id')
            ->whereDate('tim.created_at', '>=', now()->subDays(7))
            ->count();

        if ($inconsistencias > 0) {
            Log::warning('Inconsistencias detectadas en modificadores', [
                'total_inconsistencias' => $inconsistencias,
                'fecha_verificacion' => now()->toDateTimeString()
            ]);

            // Notificar al equipo
            $this->notifyTeam($inconsistencias);
        }
    }
}
```

---

## **EJECUCIÓN COORDINADA**

### **Orden de Ejecución:**
1. **[Gemini CLI]** Ejecutar scripts de Fase 1
2. **[Claude Code]** Implementar correcciones Fase 2
3. **[Claude Code]** Testing y validación
4. **[Codex]** Extensión a otros módulos (Fase 3)
5. **[Gemini CLI]** Evaluación datos históricos (Fase 4)
6. **[Claude Code]** Implementar prevenciones (Fase 5)

### **Coordinación entre Agentes:**
- **Resultados de Gemini** → **Entrada para Claude/Codex**
- **Código de Claude/Codex** → **Testing y validación**
- **Todos los agentes** → **Documentación compartida en docs/**

### **Puntos de Control:**
- Después de Fase 1: Validar diagnóstico completo
- Después de Fase 2: Verificar corrección de Service Layer
- Después de Fase 3: Validar integración completa
- Antes de Fase 4: Evaluar necesidad de corrección histórica

---

## **MÉTRICAS DE SEGUIMIENTO**

### **Por Agente:**
- **Gemini CLI:** Consistencia de datos (%)
- **Claude Code:** Funcionalidad de reportes (✅/❌)
- **Codex:** Integración con módulos (✅/❌)

### **Globales:**
- **Precisión de inventario:** 100%
- **Costos correctos:** 100%
- **Performance:** Sin degradación

---

## **COMUNICACIÓN Y DOCUMENTACIÓN**

### **Documentos de Trabajo:**
- `docs/INVESTIGACION_CRITICA_MODIFICADORES_2025_12_10.md` - Hallazgo inicial
- `docs/PLAN_DELEGACION_MODIFICADORES_2025_12_10.md` - Este documento
- `scripts/` - Scripts SQL para Gemini CLI
- `app/Services/` - Código PHP para Claude/Codex

### **Canales de Comunicación:**
- **Resultados:** Actualizar documentos compartidos
- **Problemas:** Documentar en logs específicos por agente
- **Decisiones:** Registrar en documentos de seguimiento

---

**Este plan permite una ejecución coordinada, paralela y documentada del proceso de corrección masiva de modificadores.**

---

**Estado:** Listo para delegación y ejecución
**Coordinador:** Claude Code
**Agentes Involucrados:** Gemini CLI, Codex, Claude Code