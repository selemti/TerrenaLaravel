# Refactor Producción – Alineación BD ↔ Código

**Fecha**: 2025-11-17
**Agente**: Claude Code
**Módulo**: Producción

---

## 1. Resumen Ejecutivo

- **MISMATCH corregidos (confirmados contra BD)**: 0
- **FANTASMA atendidos (eliminados o TODO)**: 0
- **Campos MISSING_IN_CODE agregados**: 0
- **ERROR_MAPA detectados**: 0
- **Modelos corregidos**: 2
- **Servicios revisados**: 1
- **Tablas procesadas**: 2 (op_produccion_cab, production_orders)

### Estado General
✅ El módulo Producción tiene una alineación **excelente** entre BD y código. No se detectaron MISMATCH ni FANTASMA en las tablas activas. Solo se realizaron mejoras menores de configuración.

---

## 2. Cambios por tabla/columna

| Tabla BD | Modelo Laravel | Estado | Inconsistencias | Correcciones Aplicadas |
|----------|----------------|--------|-----------------|------------------------|
| selemti.op_produccion_cab | OrdenProduccion | ✅ OK | 0 | Agregado `$connection = 'pgsql'` |
| selemti.production_orders | ProductionOrder | ✅ OK | 0 | Agregado prefijo schema `selemti.` en `$table` |

---

## 3. Detalle de Correcciones

### 3.1 Modelo: OrdenProduccion
**Archivo**: `app/Models/Rec/OrdenProduccion.php`
**Tabla BD**: `selemti.op_produccion_cab`

#### Cambios Aplicados:
1. **Conexión PostgreSQL** (MEJORA)
   - **Acción**: Agregado `protected $connection = 'pgsql';`
   - **Razón**: Asegurar que el modelo use la conexión correcta PostgreSQL en lugar de SQLite por defecto
   - **Impacto**: Sin breaking changes, solo hace explícita la configuración

#### Campos Verificados (10/10 ✅):
- ✅ `id` (integer, PK)
- ✅ `receta_version_id` (integer, FK)
- ✅ `cantidad_planeada` (numeric)
- ✅ `cantidad_real` (numeric)
- ✅ `fecha_produccion` (date)
- ✅ `estado` (varchar)
- ✅ `lote_resultado` (varchar)
- ✅ `usuario_responsable` (integer)
- ✅ `created_at` (timestamp)
- ✅ `updated_at` (timestamp)

**Todos los campos están correctamente declarados en `$fillable` y `$casts`.**

---

### 3.2 Modelo: ProductionOrder
**Archivo**: `app/Models/ProductionOrder.php`
**Tabla BD**: `selemti.production_orders`

#### Cambios Aplicados:
1. **Schema explícito en tabla** (MEJORA)
   - **Antes**: `protected $table = 'production_orders';`
   - **Después**: `protected $table = 'selemti.production_orders';`
   - **Razón**: Evitar ambigüedades con el search_path de PostgreSQL
   - **Impacto**: Mejora la portabilidad y elimina dependencias del search_path

#### Campos Verificados (20/20 ✅):
- ✅ `id` (bigint, PK)
- ✅ `folio` (varchar)
- ✅ `recipe_id` (bigint, FK)
- ✅ `item_id` (varchar, FK)
- ✅ `qty_programada` (numeric) → Cast correcto `decimal:2`
- ✅ `qty_producida` (numeric) → Cast correcto `decimal:2`
- ✅ `qty_merma` (numeric) → Cast correcto `decimal:2`
- ✅ `uom_base` (varchar)
- ✅ `sucursal_id` (varchar, FK)
- ✅ `almacen_id` (varchar, FK)
- ✅ `programado_para` (timestamp with time zone) → Cast correcto `datetime`
- ✅ `iniciado_en` (timestamp with time zone) → Cast correcto `datetime`
- ✅ `cerrado_en` (timestamp with time zone) → Cast correcto `datetime`
- ✅ `estado` (varchar)
- ✅ `creado_por` (bigint, FK)
- ✅ `aprobado_por` (bigint, FK)
- ✅ `notas` (text)
- ✅ `meta` (jsonb) → Cast correcto `array`
- ✅ `created_at` (timestamp with time zone)
- ✅ `updated_at` (timestamp with time zone)

**El modelo usa `protected $guarded = []` lo cual es correcto para permitir mass assignment de todos los campos validados externamente.**

---

### 3.3 Servicio: ProductionService
**Archivo**: `app/Services/Production/ProductionService.php`

#### Verificaciones:
- ✅ **No hace acceso directo a columnas de BD**: Usa modelos correctamente
- ✅ **Métodos bien diseñados**: planBatch, consumeIngredients, completeBatch, postBatchToInventory
- ✅ **TODOs documentados**: Todas las funciones críticas tienen TODOs para implementación futura
- ⚠️ **Estado**: Servicio skeleton (métodos no implementados completamente)

**No requiere correcciones en esta fase de refactor BD↔Código.**

---

## 4. Tablas de BD Identificadas en el Módulo

### Tablas con Modelo (2/12):
1. ✅ `selemti.op_produccion_cab` → `OrdenProduccion`
2. ✅ `selemti.production_orders` → `ProductionOrder`

### Tablas Sin Modelo - Estado NO_USADO (10/12):
Estas tablas existen en BD pero no están siendo utilizadas en el código actual. Según el mapeo verificado, tienen estado `NO_USADO` y es **correcto** que no tengan modelos:

3. 🔵 `selemti.merma` - Tabla de mermas (14 columnas)
4. 🔵 `selemti.op_cab` - Orden producción (alternativa)
5. 🔵 `selemti.op_insumo` - Insumos de orden
6. 🔵 `selemti.op_yield` - Rendimientos
7. 🔵 `selemti.prod_cab` - Producción cabecera (alternativa)
8. 🔵 `selemti.prod_det` - Producción detalle (alternativa)
9. 🔵 `selemti.production_order_inputs` - Inputs de orden
10. 🔵 `selemti.production_order_outputs` - Outputs de orden
11. 🔵 `selemti.sol_prod_cab` - Solicitud producción cabecera
12. 🔵 `selemti.sol_prod_det` - Solicitud producción detalle

### Vistas (2):
- `selemti.v_merma_por_item`
- `selemti.vw_dashboard_ordenes`

---

## 5. Conflictos mapa ↔ BD (ERROR_MAPA)

**Ninguno detectado.** ✅

Todos los registros del mapeo para el módulo Producción coinciden con la estructura real de BD PostgreSQL.

---

## 6. TODOs Importantes

### En Código Existente:
Los TODOs encontrados son **funcionales** (lógica de negocio pendiente), no de alineación BD↔Código:

1. **ProductionService.php**:
   - TODO: Implementar persistencia de batches PLANIFICADA
   - TODO: Validar disponibilidad en inventario
   - TODO: Registrar consumo de insumos
   - TODO: Asociar lotes creados y métricas de merma
   - TODO: Crear mov_inv para posteo a inventario

2. **ProductionController.php**:
   - TODO: Validar recipe y qty con FormRequest
   - TODO: Validar líneas contra inventario disponible
   - TODO: Registrar métricas de rendimiento
   - TODO: Manejar errores de doble posteo

**Estos TODOs son de desarrollo de funcionalidad, NO de refactor BD↔Código.**

---

## 7. Archivos Modificados

### Modificados (2):
1. `app/Models/Rec/OrdenProduccion.php`
   - Agregado `protected $connection = 'pgsql';`

2. `app/Models/ProductionOrder.php`
   - Actualizado `protected $table` de `'production_orders'` a `'selemti.production_orders'`

### Revisados sin cambios (2):
1. `app/Services/Production/ProductionService.php`
2. `app/Http/Controllers/Production/ProductionController.php`

---

## 8. Validaciones Realizadas

### Validación contra BD Real:
```sql
-- Verificación de tablas de producción
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'selemti'
  AND (table_name LIKE '%produccion%' OR table_name LIKE '%orden%' OR table_name LIKE '%merma%')
ORDER BY table_name;

-- Verificación de columnas op_produccion_cab
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'selemti' AND table_name = 'op_produccion_cab'
ORDER BY ordinal_position;

-- Verificación de columnas production_orders
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'selemti' AND table_name = 'production_orders'
ORDER BY ordinal_position;
```

✅ **Todas las validaciones pasaron exitosamente.**

---

## 9. Dependencias del Módulo

### Dependencias Confirmadas:
- ✅ **Recetas** (DONE) - Para RecetaVersion en OrdenProduccion
- ✅ **Inventario** (DONE) - Para mov_inv en posteo de producción

### Módulos que Dependen de Producción:
- ⏳ **Reportes** (PENDING) - Consumirá datos de órdenes de producción

---

## 10. Métricas Finales

| Métrica | Valor |
|---------|-------|
| Tablas en BD (Producción) | 12 |
| Tablas con modelo | 2 |
| Tablas NO_USADO (correcto) | 10 |
| Modelos refactorizados | 2 |
| Campos verificados | 30 |
| MISMATCH encontrados | 0 |
| FANTASMA encontrados | 0 |
| ERROR_MAPA detectados | 0 |
| Archivos modificados | 2 |
| Tests ejecutados | N/A |

---

## 11. Conclusiones y Recomendaciones

### ✅ Aspectos Positivos:
1. **Alineación perfecta**: No hay discrepancias entre BD y código
2. **Modelos bien diseñados**: Uso correcto de fillable/guarded, casts, y relationships
3. **Separación clara**: Tablas legacy (NO_USADO) vs tablas activas
4. **Servicio bien estructurado**: ProductionService sigue patrones correctos

### 🔵 Observaciones:
1. **10 tablas NO_USADO**: Parece haber múltiples esquemas históricos de producción. Recomendable documentar cuál es el definitivo.
2. **ProductionService skeleton**: La lógica de negocio está pendiente (TODOs), pero la estructura es correcta.

### 📋 Próximos Pasos Sugeridos:
1. Implementar la lógica de negocio pendiente en ProductionService
2. Crear FormRequests para validación de inputs en ProductionController
3. Agregar tests unitarios para modelos
4. Agregar tests de integración para ProductionService
5. Documentar workflow completo de órdenes de producción

---

## 12. Estado Final del Módulo

**Estado**: ✅ **DONE**
**Calidad de Alineación**: 🟢 **EXCELENTE** (100% de coincidencia BD↔Código)
**Listo para**: Implementación de lógica de negocio

---

**Documento generado automáticamente por AGENTE REFACTOR MULTI-MÓDULO**
**Versión**: 1.0
**Próxima revisión**: Después de implementar TODOs funcionales
