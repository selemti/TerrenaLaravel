# 🔧 PROMPT GEMINI - DATABASE PREP (VIERNES NOCHE)

**Agente**: Gemini CLI
**Fecha de Ejecución**: Viernes 31 de Octubre 2025 (23:55)
**Duración**: 1-2 horas
**Objetivo**: Verificar integridad BD y prepararla para deployment del fin de semana

---

## 🎯 CONTEXTO

Mañana sábado desplegaremos módulos de Catálogos y Recetas. Codex creará una nueva tabla `recipe_cost_snapshots` y agregará lógica compleja. Necesito que verifiques que la BD PostgreSQL está en buen estado y lista para recibir estas changes.

**Base de Datos**:
- Host: localhost
- Port: 5433
- Database: pos
- User: postgres
- Schema principal: `selemti` (working schema)
- Schema legacy: `public` (FloreantPOS, read-only)

---

## 📋 TAREAS

### TAREA 1: Verificar Estado Actual (15 min)

Conecta a la BD y verifica que las tablas principales existen y tienen datos:

```sql
-- Conectar
\c pos

-- Verificar schema selemti
\dn selemti

-- Listar todas las tablas en selemti
\dt selemti.*

-- Contar registros en tablas críticas
SELECT 'recipes' as tabla, COUNT(*) as registros FROM selemti.recipes
UNION ALL
SELECT 'items', COUNT(*) FROM selemti.items
UNION ALL
SELECT 'unidades_medida', COUNT(*) FROM selemti.unidades_medida
UNION ALL
SELECT 'cat_sucursales', COUNT(*) FROM selemti.cat_sucursales
UNION ALL
SELECT 'cat_almacenes', COUNT(*) FROM selemti.cat_almacenes
UNION ALL
SELECT 'cat_proveedores', COUNT(*) FROM selemti.cat_proveedores
UNION ALL
SELECT 'item_categories', COUNT(*) FROM selemti.item_categories;
```

**Documenta los resultados**.

---

### TAREA 2: Verificar Integridad Referencial (20 min)

Verifica que no hay datos huérfanos (foreign keys rotas):

```sql
-- 1. Recetas sin categoría válida
SELECT
    r.id,
    r.nombre,
    r.categoria_id
FROM selemti.recipes r
WHERE r.categoria_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM selemti.item_categories ic
      WHERE ic.id = r.categoria_id
  )
LIMIT 10;

-- 2. Items sin unidad de medida válida
SELECT
    i.id,
    i.nombre,
    i.unidad_medida_id
FROM selemti.items i
WHERE i.unidad_medida_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM selemti.unidades_medida u
      WHERE u.id = i.unidad_medida_id
  )
LIMIT 10;

-- 3. Almacenes sin sucursal válida
SELECT
    a.id,
    a.nombre,
    a.sucursal_id
FROM selemti.cat_almacenes a
WHERE a.sucursal_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM selemti.cat_sucursales s
      WHERE s.id = a.sucursal_id
  )
LIMIT 10;

-- 4. RecetaDetalles sin receta válida
SELECT
    rd.id,
    rd.receta_id
FROM selemti.recipe_detalles rd
WHERE NOT EXISTS (
    SELECT 1 FROM selemti.recipes r
    WHERE r.id = rd.receta_id
)
LIMIT 10;

-- 5. RecetaDetalles sin item válido (cuando item_id no es null)
SELECT
    rd.id,
    rd.receta_id,
    rd.item_id
FROM selemti.recipe_detalles rd
WHERE rd.item_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM selemti.items i
      WHERE i.id = rd.item_id
  )
LIMIT 10;
```

**Si encuentras datos huérfanos**:
- Documenta cuántos hay
- NO los borres sin confirmar con el usuario
- Marca como WARNING en tu reporte

---

### TAREA 3: Verificar que Tabla recipe_cost_snapshots NO Existe (5 min)

Codex creará esta tabla. Verifica que NO existe aún:

```sql
-- Verificar que tabla NO existe
SELECT to_regclass('selemti.recipe_cost_snapshots') as tabla_existe;
-- Debe retornar NULL

-- Si existe, describir su estructura
\d selemti.recipe_cost_snapshots
```

**Si la tabla YA existe**:
- Documenta su estructura actual
- Marca como WARNING (posible conflicto con migration de Codex)

---

### TAREA 4: Crear Índices Preventivos (20 min)

Crea índices para mejorar performance de queries que usaremos mañana:

```sql
-- IMPORTANTE: Usa CREATE INDEX IF NOT EXISTS para no fallar si ya existen

-- Índices para recipes
CREATE INDEX IF NOT EXISTS idx_recipes_activo
    ON selemti.recipes(activo);

CREATE INDEX IF NOT EXISTS idx_recipes_categoria
    ON selemti.recipes(categoria_id);

CREATE INDEX IF NOT EXISTS idx_recipes_nombre
    ON selemti.recipes(nombre);

-- Índices para items
CREATE INDEX IF NOT EXISTS idx_items_activo
    ON selemti.items(activo);

CREATE INDEX IF NOT EXISTS idx_items_categoria
    ON selemti.items(categoria_id);

CREATE INDEX IF NOT EXISTS idx_items_nombre
    ON selemti.items(nombre);

-- Índices para recipe_detalles (para BOM implosion)
CREATE INDEX IF NOT EXISTS idx_recipe_detalles_receta
    ON selemti.recipe_detalles(receta_id);

CREATE INDEX IF NOT EXISTS idx_recipe_detalles_item
    ON selemti.recipe_detalles(item_id);

-- Si hay columna receta_id_ingrediente (sub-recetas)
CREATE INDEX IF NOT EXISTS idx_recipe_detalles_subreceta
    ON selemti.recipe_detalles(receta_id)
    WHERE item_id IS NULL;

-- Índices para almacenes
CREATE INDEX IF NOT EXISTS idx_almacenes_sucursal
    ON selemti.cat_almacenes(sucursal_id);

CREATE INDEX IF NOT EXISTS idx_almacenes_activo
    ON selemti.cat_almacenes(activo);

-- Índices para items (unidad de medida)
CREATE INDEX IF NOT EXISTS idx_items_uom
    ON selemti.items(unidad_medida_id);
```

**Documenta cuántos índices se crearon**.

---

### TAREA 5: Verificar Estructura de Tablas Críticas (15 min)

Verifica que las tablas tienen las columnas que esperamos:

```sql
-- Estructura de recipes
\d selemti.recipes

-- Debe tener al menos:
-- - id (varchar o similar)
-- - nombre
-- - categoria_id
-- - activo (boolean)
-- - porciones
-- - created_at, updated_at

-- Estructura de recipe_detalles
\d selemti.recipe_detalles

-- Debe tener al menos:
-- - id
-- - receta_id (FK a recipes)
-- - item_id (FK a items, nullable si es sub-receta)
-- - cantidad
-- - unidad_id

-- Estructura de items
\d selemti.items

-- Debe tener al menos:
-- - id
-- - nombre
-- - categoria_id
-- - unidad_medida_id
-- - activo

-- Estructura de unidades_medida
\d selemti.unidades_medida

-- Debe tener al menos:
-- - id
-- - codigo (KG, L, PZ, etc)
-- - nombre
-- - tipo (BASE, COMPRA, SALIDA)
-- - categoria (MASA, VOLUMEN, UNIDAD)
```

**Si faltan columnas críticas**: Marca como ERROR en reporte.

---

### TAREA 6: Análisis de Datos (10 min)

Genera estadísticas útiles:

```sql
-- Distribución de recetas por categoría
SELECT
    ic.nombre as categoria,
    COUNT(r.id) as cantidad_recetas
FROM selemti.item_categories ic
LEFT JOIN selemti.recipes r ON r.categoria_id = ic.id
GROUP BY ic.id, ic.nombre
ORDER BY cantidad_recetas DESC;

-- Distribución de items por categoría
SELECT
    ic.nombre as categoria,
    COUNT(i.id) as cantidad_items
FROM selemti.item_categories ic
LEFT JOIN selemti.items i ON i.categoria_id = ic.id
GROUP BY ic.id, ic.nombre
ORDER BY cantidad_items DESC;

-- Recetas más complejas (más ingredientes)
SELECT
    r.id,
    r.nombre,
    COUNT(rd.id) as num_ingredientes
FROM selemti.recipes r
LEFT JOIN selemti.recipe_detalles rd ON rd.receta_id = r.id
GROUP BY r.id, r.nombre
ORDER BY num_ingredientes DESC
LIMIT 10;

-- Unidades de medida más usadas
SELECT
    u.codigo,
    u.nombre,
    COUNT(i.id) as items_usando_esta_uom
FROM selemti.unidades_medida u
LEFT JOIN selemti.items i ON i.unidad_medida_id = u.id
GROUP BY u.id, u.codigo, u.nombre
ORDER BY items_usando_esta_uom DESC
LIMIT 10;

-- Sucursales y almacenes
SELECT
    s.nombre as sucursal,
    COUNT(a.id) as num_almacenes
FROM selemti.cat_sucursales s
LEFT JOIN selemti.cat_almacenes a ON a.sucursal_id = s.id
GROUP BY s.id, s.nombre
ORDER BY num_almacenes DESC;
```

---

### TAREA 7: Generar Reporte Final (10 min)

Crea un archivo Markdown con todos los resultados:

**Ubicación**: `C:/xampp3/htdocs/TerrenaLaravel/docs/GEMINI_DB_PREP_REPORT.md`

**Template del Reporte**:

```markdown
# 🔧 REPORTE GEMINI - PREPARATIVOS BD

**Fecha**: 31 de Octubre 2025
**Hora**: [HORA_ACTUAL]
**Ejecutado por**: Gemini CLI
**Base de Datos**: PostgreSQL 9.5 - Database `pos`, Schema `selemti`

---

## ✅ RESUMEN EJECUTIVO

- **Status General**: [OK / WARNING / ERROR]
- **Tablas Verificadas**: [NÚMERO]
- **Índices Creados**: [NÚMERO]
- **Issues Encontrados**: [NÚMERO]
- **Tiempo de Ejecución**: [MINUTOS]

---

## 📊 VERIFICACIÓN DE TABLAS

### Tablas Existentes y Registros

| Tabla | Registros | Status |
|-------|-----------|--------|
| recipes | [CANTIDAD] | ✅ OK |
| items | [CANTIDAD] | ✅ OK |
| unidades_medida | [CANTIDAD] | ✅ OK |
| cat_sucursales | [CANTIDAD] | ✅ OK |
| cat_almacenes | [CANTIDAD] | ✅ OK |
| cat_proveedores | [CANTIDAD] | ✅ OK |
| item_categories | [CANTIDAD] | ✅ OK |

---

## 🔗 INTEGRIDAD REFERENCIAL

### Recetas sin Categoría Válida
- **Encontrados**: [CANTIDAD]
- **Status**: [✅ OK (0) / ⚠️ WARNING (>0)]
- **Acción**: [Ninguna / Requiere limpieza]

### Items sin Unidad de Medida Válida
- **Encontrados**: [CANTIDAD]
- **Status**: [✅ OK (0) / ⚠️ WARNING (>0)]
- **Acción**: [Ninguna / Requiere limpieza]

### Almacenes sin Sucursal Válida
- **Encontrados**: [CANTIDAD]
- **Status**: [✅ OK (0) / ⚠️ WARNING (>0)]
- **Acción**: [Ninguna / Requiere limpieza]

### RecetaDetalles Huérfanos
- **Encontrados**: [CANTIDAD]
- **Status**: [✅ OK (0) / ⚠️ WARNING (>0)]
- **Acción**: [Ninguna / Requiere limpieza]

---

## 🏗️ PREPARATIVOS PARA MIGRATIONS

### Tabla recipe_cost_snapshots
- **Existe**: [SÍ / NO]
- **Status**: [✅ OK (NO existe) / ⚠️ WARNING (ya existe)]
- **Acción**: [Ready for creation / Verificar estructura]

---

## 📈 ÍNDICES CREADOS

Total de índices preventivos creados: **[NÚMERO]**

### Detalle
- ✅ idx_recipes_activo
- ✅ idx_recipes_categoria
- ✅ idx_recipes_nombre
- ✅ idx_items_activo
- ✅ idx_items_categoria
- ✅ idx_items_nombre
- ✅ idx_recipe_detalles_receta
- ✅ idx_recipe_detalles_item
- ✅ idx_recipe_detalles_subreceta
- ✅ idx_almacenes_sucursal
- ✅ idx_almacenes_activo
- ✅ idx_items_uom

**Índices que ya existían**: [LISTA]

---

## 📊 ESTADÍSTICAS DE DATOS

### Distribución de Recetas por Categoría
[TABLA CON RESULTADOS]

### Distribución de Items por Categoría
[TABLA CON RESULTADOS]

### Top 10 Recetas Más Complejas
[TABLA CON RESULTADOS]

### Unidades de Medida Más Usadas
[TABLA CON RESULTADOS]

### Sucursales y Almacenes
[TABLA CON RESULTADOS]

---

## 🔍 VERIFICACIÓN DE ESTRUCTURA

### Tabla recipes
- ✅ Columna `id` existe
- ✅ Columna `nombre` existe
- ✅ Columna `categoria_id` existe
- ✅ Columna `activo` existe
- ✅ Columna `porciones` existe

### Tabla recipe_detalles
- ✅ Columna `receta_id` existe
- ✅ Columna `item_id` existe
- ✅ Columna `cantidad` existe
- ✅ Columna `unidad_id` existe

### Tabla items
- ✅ Columna `nombre` existe
- ✅ Columna `categoria_id` existe
- ✅ Columna `unidad_medida_id` existe
- ✅ Columna `activo` existe

---

## ⚠️ WARNINGS Y RECOMENDACIONES

[LISTA DE WARNINGS SI HAY]

**Ejemplo**:
- ⚠️ Se encontraron 5 items sin unidad de medida válida
- ⚠️ Tabla recipe_cost_snapshots ya existe (conflicto potencial)

---

## ✅ CONCLUSIONES

1. [Conclusión 1]
2. [Conclusión 2]
3. [Conclusión 3]

**Status Final**: [✅ LISTO PARA DEPLOYMENT / ⚠️ REQUIERE ATENCIÓN / ❌ BLOQUEANTE]

---

## 🎯 PRÓXIMOS PASOS

1. [Paso 1]
2. [Paso 2]

---

**Generado por**: Gemini CLI
**Documento**: GEMINI_DB_PREP_REPORT.md
```

---

## ✅ CHECKLIST FINAL

Antes de terminar, verifica que completaste:

- [ ] Tarea 1: Verificación de estado (tablas existen)
- [ ] Tarea 2: Integridad referencial (sin huérfanos o documentados)
- [ ] Tarea 3: Verificación recipe_cost_snapshots NO existe
- [ ] Tarea 4: Índices preventivos creados (12 índices)
- [ ] Tarea 5: Estructura de tablas verificada
- [ ] Tarea 6: Estadísticas generadas
- [ ] Tarea 7: Reporte `GEMINI_DB_PREP_REPORT.md` creado

---

## 🚨 SI ENCUENTRAS PROBLEMAS

### Problema: No puedo conectar a BD

```bash
# Verificar que PostgreSQL está corriendo
# En Windows:
net start postgresql-x64-9.5

# Verificar puerto
netstat -an | findstr 5433
```

### Problema: Tabla recipe_cost_snapshots ya existe

**Acción**:
1. Describir su estructura: `\d selemti.recipe_cost_snapshots`
2. Documentar en reporte como WARNING
3. Notificar que puede haber conflicto con migration de Codex

### Problema: Muchos datos huérfanos

**Acción**:
1. Documentar cantidad exacta
2. NO borrar sin autorización
3. Marcar como WARNING en reporte
4. Sugerir limpieza manual

---

## 🎯 RESULTADO ESPERADO

Al terminar:
- ✅ BD verificada e íntegra
- ✅ 12 índices preventivos creados
- ✅ Reporte completo generado
- ✅ BD lista para migrations de mañana
- ✅ Performance mejorada con índices

**Tiempo estimado**: 1-2 horas

---

🔧 **¡ADELANTE CON LA VERIFICACIÓN!** 🔧

---

**Creado**: 31 de Octubre 2025, 23:59
**Para**: Gemini CLI
**Ejecución**: Viernes noche (AHORA)
