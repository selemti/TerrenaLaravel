# ISSUE_INV-001-DATASET-MP-ID-FIX

**Issue ID**: ISSUE-001
**Épica**: INV-001 (Motor de Replenishment)
**Prioridad**: ALTA (BLOQUEADOR)
**Descubierto por**: Claude Code (Auditoría BD)
**Fecha**: 2025-11-19
**Estado**: OPEN
**Asignado a**: Qwen (especialista BD/SQL)

---

## Descripción del Problema

El dataset `REPLENISHMENT_DATASET_MIGRACION.sql` (línea 210) utiliza una extracción de mp_id basada en regex que **NO es compatible** con el formato de IDs de items en la BD real.

### Código Problemático

**Archivo**: `docs/V4.0/BaseDatos/REPLENISHMENT_DATASET_MIGRACION.sql`
**Línea**: 210

```sql
CAST(SUBSTRING(t.id FROM '[0-9]+') AS INTEGER)  -- mp_id (extraer número del item_id)
```

### Asunción Incorrecta

El código asume que `selemti.items.id` contiene un número extraíble (ejemplo: `ITEM-001` → `001` → `1`).

### Realidad en BD

Items reales tienen formato:
```
LECHE-MEMBERS-01
LECHE-MEM-01
LECHE-NUTRI-01
ACEITE-NUTRIOLI-01
ACEITE-NUT-01
LECHE-NUT-01
```

**Todos terminan en `-01`**, por lo que la extracción genera:
- `LECHE-MEMBERS-01` → mp_id = 1
- `LECHE-MEM-01` → mp_id = 1
- `LECHE-NUTRI-01` → mp_id = 1
- `ACEITE-NUTRIOLI-01` → mp_id = 1
- `ACEITE-NUT-01` → mp_id = 1
- `LECHE-NUT-01` → mp_id = 1

**RESULTADO**: 6 filas diferentes con el mismo mp_id → **COLISIÓN DE DATOS**.

---

## Impacto

### Bloqueador para:
- Ejecución del dataset de migración
- Pruebas de motor de Replenishment con datos reales
- Algoritmo POS_CONSUMPTION (depende de `inv_consumo_pos_det.mp_id`)

### No bloquea:
- Desarrollo de ReplenishmentService (ya funcional con BD vacía)
- Algoritmos MIN_MAX y SMA (no dependen de consumos POS)
- Tests unitarios con mocks

---

## Solución Propuesta

### Opción A: Mapeo Secuencial Temporal (RECOMENDADA)

Modificar dataset líneas 204-223 para usar mapeo explícito:

```sql
-- ANTES (línea 205-223 actual)
INSERT INTO selemti.inv_consumo_pos_det
    (consumo_id, mp_id, uom_id, cantidad, factor, origen,
     requiere_reproceso, procesado, fecha_proceso, revertido)
SELECT
    c.id,
    CAST(SUBSTRING(t.id FROM '[0-9]+') AS INTEGER),  -- PROBLEMÁTICO
    1,
    2.500000,
    1.000000,
    'RECETA',
    false,
    true,
    c.fecha_proceso,
    false
FROM selemti.inv_consumo_pos c
CROSS JOIN temp_items_replenishment t
WHERE c.ticket_id BETWEEN 90001 AND 90007;

-- DESPUÉS (propuesta)
-- 1. Crear mapeo items → mp_id
CREATE TEMP TABLE temp_mp_mapping AS
SELECT
    id as item_id,
    ROW_NUMBER() OVER (ORDER BY id) as mp_id
FROM temp_items_replenishment;

-- 2. Usar mapeo en INSERT
INSERT INTO selemti.inv_consumo_pos_det
    (consumo_id, mp_id, uom_id, cantidad, factor, origen,
     requiere_reproceso, procesado, fecha_proceso, revertido)
SELECT
    c.id,
    m.mp_id,  -- Usar mp_id del mapeo
    1,
    2.500000,
    1.000000,
    'RECETA',
    false,
    true,
    c.fecha_proceso,
    false
FROM selemti.inv_consumo_pos c
CROSS JOIN temp_mp_mapping m
WHERE c.ticket_id BETWEEN 90001 AND 90007
  AND c.procesado = true
LIMIT 14;

-- 3. Limpiar mapeo temporal al final
DROP TABLE IF EXISTS temp_mp_mapping;  -- Agregar en sección 7
```

**Ventajas**:
- ✅ Funciona con cualquier formato de item_id
- ✅ Garantiza mp_id únicos secuenciales (1, 2, 3)
- ✅ No requiere cambios en estructura de BD

---

### Opción B: Crear Tabla materia_prima Permanente

Crear tabla de mapeo permanente items ↔ mp_id:

```sql
-- Nueva migración
CREATE TABLE selemti.materia_prima (
    id SERIAL PRIMARY KEY,
    item_id VARCHAR(64) NOT NULL UNIQUE REFERENCES selemti.items(id),
    nombre VARCHAR(255),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Poblar desde items existentes
INSERT INTO selemti.materia_prima (item_id, nombre, activo)
SELECT id, nombre, activo
FROM selemti.items
WHERE tipo = 'MATERIA_PRIMA';

-- Modificar inv_consumo_pos_det para usar FK
ALTER TABLE selemti.inv_consumo_pos_det
ADD CONSTRAINT fk_mp_id FOREIGN KEY (mp_id) REFERENCES selemti.materia_prima(id);
```

**Ventajas**:
- ✅ Solución estructural robusta
- ✅ FK constraint asegura integridad
- ✅ Permite extender funcionalidad de materias primas

**Desventajas**:
- ❌ Requiere migración nueva
- ❌ Más complejo para dataset mínimo
- ❌ Rompe compatibilidad con código existente (si lo hay)

---

## Recomendación

**Usar Opción A** (mapeo temporal) para el dataset de migración.

**Considerar Opción B** como mejora futura en Sprint 2+ si se detecta que mp_id es usado ampliamente en lógica de negocio.

---

## Checklist de Resolución

- [ ] Qwen modifica `REPLENISHMENT_DATASET_MIGRACION.sql` líneas 204-223
- [ ] Agregar temp_mp_mapping antes de inv_consumo_pos_det INSERT
- [ ] Probar dataset en ambiente de desarrollo (BEGIN...ROLLBACK)
- [ ] Verificar que mp_id generados son 1, 2, 3 (no colisiones)
- [ ] Documentar cambios en DEVLOG propio de Qwen
- [ ] Ejecutar dataset y validar con queries de validación (líneas 305-312)
- [ ] Marcar BD-VERIFICAR-DATASETS como DONE en MASTER_SPRINT1_STATUS_V2.md

---

## Archivos Afectados

- `docs/V4.0/BaseDatos/REPLENISHMENT_DATASET_MIGRACION.sql` (líneas 204-223)
- `docs/V4.1/00_Orquestador/MASTER_SPRINT1_STATUS_V2.md` (BD-VERIFICAR-DATASETS)
- `docs/V4.1/Code/DEVLOG_SPRINT1_INV-001-CLAUDE-BD-DATASET.md` (auditoría completa)

---

## Referencias

- **Auditoría completa**: `DEVLOG_SPRINT1_INV-001-CLAUDE-BD-DATASET.md`
- **Items reales BD**: Query ejecutada 2025-11-19
- **Estructura inv_consumo_pos_det**: `\d selemti.inv_consumo_pos_det`

---

**Creado por**: Claude Code
**Para revisión de**: Qwen (BD specialist)
**Fecha**: 2025-11-19
