# TAREA PARA QWEN - Análisis de Estrategia de Consolidación Diaria
**Fecha**: 28 de noviembre de 2025
**Prioridad**: 🟡 MEDIA (después de análisis de reportes)
**Tiempo estimado**: 2-3 horas
**Tipo**: ANÁLISIS - Validación técnica y complemento de documentación

---

## 🎯 OBJETIVO

Analizar la estrategia de **Consolidación Diaria de Ventas** propuesta en `docs/ARCHITECTURE/DAILY_SALES_CONSOLIDATION_STRATEGY.md` y complementar la documentación con análisis técnico profundo.

**Meta**:
- ✅ Validar viabilidad técnica de las 4 tablas consolidadas
- ✅ Analizar queries ETL necesarios
- ✅ Identificar riesgos y dependencias
- ✅ Proponer optimizaciones
- ✅ Documentar casos especiales (misceláneos, modificadores, descuentos)

---

## 📚 DOCUMENTOS A LEER PRIMERO

### 1. Estrategia Principal (OBLIGATORIO)
**Archivo**: `docs/ARCHITECTURE/DAILY_SALES_CONSOLIDATION_STRATEGY.md`

**Qué contiene**:
- 4 tablas consolidadas: `daily_sales_header`, `daily_item_sales`, `daily_modifier_sales`, `daily_misc_sales`
- Arquitectura de Data Mart
- Plan de implementación en 6 fases
- Service layer propuesto: `DailySalesConsolidationService`

### 2. Análisis de Reportes (Para contexto)
**Archivos**:
- `docs/CODE_REVIEW/SALES_EXCEPTIONS_ANALYSIS.md` (tu análisis previo)
- `docs/CODE_REVIEW/SALES_DETAIL_ANALYSIS.md` (tu análisis previo)
- `docs/CODE_REVIEW/SALES_SUMMARY_ANALYSIS.md` (tu análisis previo)

**Por qué leerlos**: Estos reportes serán los principales consumidores de las tablas consolidadas.

### 3. Esquema de Base de Datos
**Tablas principales** (schema `public` - solo lectura):
- `public.ticket` - Tickets del POS
- `public.ticket_item` - Ítems en tickets (productos del menú)
- `public.ticket_item_modifier` - Modificadores aplicados
- `public.ticket_discount` - Descuentos a nivel ticket
- `public.ticket_item_discount` - Descuentos a nivel ítem
- `public.menu_item` - Catálogo de productos del menú
- `public.transactions` - Pagos y transacciones

**Usar**: `psql` para explorar la estructura real:
```bash
psql -h localhost -p 5433 -U postgres -d pos -c "\d public.ticket"
psql -h localhost -p 5433 -U postgres -d pos -c "\d public.ticket_item"
```

---

## 📋 ANÁLISIS REQUERIDO

### Sección 1: Validación de Esquemas de Tablas

Para cada una de las 4 tablas propuestas:

1. **daily_sales_header**
   - ✅ Validar que los campos propuestos son suficientes
   - ⚠️ Identificar campos faltantes (ej: ¿delivery vs dine-in?, ¿tipo de servicio?)
   - 🔍 Analizar índices necesarios (business_date, branch_key, terminal_id)
   - 📊 Estimar tamaño de tabla (registros por año)

2. **daily_item_sales**
   - ✅ Validar relación con `public.menu_item`
   - ⚠️ ¿Cómo manejar items que cambiaron de precio durante el día?
   - 🔍 ¿Necesitamos guardar precio promedio o precio(s) específico(s)?
   - 📊 Estimar volumen (items únicos × días × sucursales)

3. **daily_modifier_sales**
   - ✅ Validar relación con `public.menu_modifier`
   - ⚠️ ¿Cómo agrupar modificadores que se repiten?
   - 🔍 ¿Guardar precio de modificador o solo cantidad?
   - 📊 Casos especiales: modificadores sin cargo, promociones

4. **daily_misc_sales**
   - ✅ **MUY IMPORTANTE**: Validar lógica de "misceláneos"
   - ⚠️ ¿Cómo identificar items sin `menu_item_id`?
   - 🔍 ¿Normalización de nombres? (ej: "Coca Cola" vs "coca cola" vs "COCA COLA")
   - 📊 Query para extraer misceláneos de `public.ticket_item`

---

### Sección 2: Queries ETL (Extracción, Transformación, Carga)

**Tarea crítica**: Diseñar los queries que poblarán cada tabla.

#### Query 1: Consolidar `daily_sales_header`

**Origen**: `public.ticket`, `public.transactions`

**Desafío**: Calcular métricas agregadas por día/sucursal/terminal

**Tu análisis debe incluir**:
```sql
-- Pseudocódigo esperado (no código final, solo lógica)
SELECT
    DATE(closing_date) as business_date,
    branch_key,
    terminal_id,
    COUNT(*) FILTER (WHERE voided = false) as total_tickets,
    COUNT(*) FILTER (WHERE voided = true) as total_voided_tickets,
    SUM(subtotal_amount) as total_gross_sales,
    SUM(discount_amount) as total_discounts,
    -- ... más métricas
FROM public.ticket
WHERE closing_date = ?
GROUP BY DATE(closing_date), branch_key, terminal_id;
```

**Preguntas a responder**:
- ¿Filtrar solo tickets `paid = true`?
- ¿Incluir tickets anulados en totales?
- ¿Cómo manejar tickets con `closing_date` NULL?
- ¿Timezone considerations? (ej: cierre a las 3am → ¿día anterior o actual?)

---

#### Query 2: Consolidar `daily_item_sales`

**Origen**: `public.ticket_item`, `public.ticket`, `public.menu_item`

**Desafío**: Agrupar ítems vendidos con sus totales

**Tu análisis debe incluir**:
- ¿JOIN con `menu_item` para obtener nombre?
- ¿Cómo sumar cantidades si el mismo ítem tiene diferentes precios?
- ¿Filtrar items de tickets anulados?
- ¿Manejar descuentos a nivel ítem (`ticket_item_discount`)?

**Query ejemplo**:
```sql
SELECT
    DATE(t.closing_date) as business_date,
    t.branch_key,
    t.terminal_id,
    ti.menu_item_id,
    mi.name as item_name,
    SUM(ti.quantity) as quantity_sold,
    COUNT(DISTINCT t.id) as ticket_count,
    SUM(ti.unit_price * ti.quantity) as total_amount,
    -- ... más campos
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
LEFT JOIN public.menu_item mi ON mi.id = ti.menu_item_id
WHERE DATE(t.closing_date) = ?
  AND t.paid = true
  AND t.voided = false
GROUP BY DATE(t.closing_date), t.branch_key, t.terminal_id, ti.menu_item_id, mi.name;
```

**Preguntas**:
- ¿Qué hacer si `menu_item_id` es NULL? → ¿Va a `daily_misc_sales`?
- ¿Precio unitario cambia durante el día? → ¿Guardamos AVG, MIN, MAX?

---

#### Query 3: Consolidar `daily_modifier_sales`

**Origen**: `public.ticket_item_modifier`, `public.ticket_item`, `public.ticket`

**Desafío**: Relacionar modificadores con sus ítems padre

**Tu análisis debe incluir**:
- ¿JOIN completo hasta `ticket` para filtrar fechas?
- ¿Cómo agrupar modificadores repetidos?
- ¿Guardar relación con `menu_item_id` del ítem padre?

---

#### Query 4: Consolidar `daily_misc_sales` (CRÍTICO)

**Origen**: `public.ticket_item` WHERE `menu_item_id IS NULL`

**Desafío**: Identificar y normalizar productos de captura libre

**Tu análisis debe incluir**:
```sql
SELECT
    DATE(t.closing_date) as business_date,
    t.branch_key,
    t.terminal_id,
    ti.name as misc_item_name,  -- Nombre capturado manualmente
    LOWER(TRIM(ti.name)) as misc_item_name_normalized,  -- Normalización
    SUM(ti.quantity) as quantity_sold,
    COUNT(DISTINCT t.id) as ticket_count,
    SUM(ti.unit_price * ti.quantity) as total_amount
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE DATE(t.closing_date) = ?
  AND ti.menu_item_id IS NULL  -- ← CLAVE: sin ID de menú
  AND t.paid = true
  AND t.voided = false
GROUP BY DATE(t.closing_date), t.branch_key, t.terminal_id, ti.name, LOWER(TRIM(ti.name));
```

**Preguntas críticas**:
- ¿Existe la columna `ticket_item.name` o se llama diferente?
- ¿Hay casos donde `menu_item_id IS NULL` pero sí existe un producto?
- ¿Normalización: lowercase, trim, eliminar acentos?
- ¿Agrupar variantes? (ej: "Coca Cola 600ml" vs "Coca Cola 355ml" → ¿separar o unir?)

---

### Sección 3: Casos Especiales

Analiza cómo manejar estos escenarios:

#### Caso 1: Tickets Parcialmente Anulados
- Ticket tiene 5 ítems, se anulan 2
- ¿Cómo contabilizar en consolidado?
- ¿Restar de totales o marcar en columna separada?

#### Caso 2: Descuentos 100%
- Item con descuento 100% (gratis)
- ¿Cuenta en `quantity_sold`? → SÍ
- ¿Cuenta en `total_amount`? → $0.00
- ¿Necesitamos columna `quantity_discounted_100pct`?

#### Caso 3: Items sin Precio
- Modificadores sin cargo (ej: "sin cebolla")
- ¿Se registran en `daily_modifier_sales`?
- ¿Columna separada `no_charge_quantity`?

#### Caso 4: Cambios de Menú
- Un `menu_item_id = 123` cambia de nombre durante el mes
- Consolidación del día 1: "Hamburguesa Clásica"
- Consolidación del día 15: "Hamburguesa Premium" (mismo ID)
- ¿Cómo reportar en trends?

#### Caso 5: Tickets Multi-Día
- Ticket abierto a las 23:50 del día A
- Cerrado a las 00:10 del día B
- ¿A qué `business_date` pertenece?
- ¿Usar `opening_date` o `closing_date`?

---

### Sección 4: Performance y Optimización

Analiza el impacto de la consolidación:

#### Índices Necesarios

Para cada tabla, proponer índices:

**`daily_sales_header`**:
```sql
CREATE INDEX idx_dsh_date_branch ON selemti.daily_sales_header(business_date, branch_key);
CREATE INDEX idx_dsh_date ON selemti.daily_sales_header(business_date);
```

**`daily_item_sales`**:
```sql
CREATE INDEX idx_dis_date_branch_item ON selemti.daily_item_sales(business_date, branch_key, menu_item_id);
-- ... más índices
```

**Pregunta**: ¿Índices compuestos vs simples? ¿Cuándo usar cada uno?

---

#### Volumen de Datos

Estimar registros por tabla:

| Tabla | Registros/día | Registros/año | Tamaño estimado (MB) |
|-------|---------------|---------------|---------------------|
| daily_sales_header | ? sucursales × ? terminales | ? | ? |
| daily_item_sales | ? items × ? sucursales | ? | ? |
| daily_modifier_sales | ? modifiers × ? sucursales | ? | ? |
| daily_misc_sales | ? misc × ? sucursales | ? | ? |

**Usar datos reales**:
```sql
-- Contar sucursales únicas
SELECT COUNT(DISTINCT branch_key) FROM public.ticket WHERE closing_date >= CURRENT_DATE - INTERVAL '30 days';

-- Contar items promedio por día
SELECT COUNT(DISTINCT menu_item_id) FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE DATE(t.closing_date) = CURRENT_DATE - 1;
```

---

#### Tiempo de ETL

Estimar cuánto tardará el proceso diario:

- Query 1 (header): ? segundos
- Query 2 (items): ? segundos
- Query 3 (modifiers): ? segundos
- Query 4 (misc): ? segundos
- **Total**: ? segundos (objetivo: < 60 seg)

**Pregunta**: ¿Es viable a las 3:00 AM? ¿Qué pasa si tarda más de 1 hora?

---

### Sección 5: Riesgos y Mitigación

Identifica riesgos técnicos:

#### Riesgo 1: Datos Inconsistentes
- **Escenario**: Consolidación falla a mitad de ejecución
- **Impacto**: Datos parciales en tablas consolidadas
- **Mitigación propuesta**: ?

#### Riesgo 2: Re-proceso
- **Escenario**: Se descubre error en consolidación del día X (hace 30 días)
- **Impacto**: Necesidad de re-procesar
- **Mitigación propuesta**: ¿Comando para re-consolidar día específico?

#### Riesgo 3: Cambios en Schema de POS
- **Escenario**: Actualización de Floreant POS cambia estructura de `ticket_item`
- **Impacto**: Queries ETL fallan
- **Mitigación propuesta**: ?

#### Riesgo 4: Timezone Issues
- **Escenario**: Sucursal en zona horaria diferente
- **Impacto**: `business_date` incorrecto
- **Mitigación propuesta**: ?

---

## 📝 ENTREGABLE ESPERADO

Crear archivo: **`docs/ARCHITECTURE/CONSOLIDATION_TECHNICAL_ANALYSIS.md`**

### Estructura del documento:

```markdown
# Análisis Técnico: Consolidación Diaria de Ventas
**Autor**: QWEN
**Fecha**: 28-Nov-2025
**Basado en**: DAILY_SALES_CONSOLIDATION_STRATEGY.md

---

## 1. RESUMEN EJECUTIVO
- Viabilidad técnica: SÍ / NO / CONDICIONAL
- Riesgos principales: [lista]
- Tiempo estimado de ETL: X minutos
- Recomendaciones clave: [3-5 puntos]

---

## 2. VALIDACIÓN DE ESQUEMAS

### 2.1 daily_sales_header
- ✅ Campos validados
- ⚠️ Campos a agregar: [lista]
- 🔧 Modificaciones sugeridas: [lista]

[Repetir para las 4 tablas]

---

## 3. QUERIES ETL

### 3.1 Query: Consolidar daily_sales_header
```sql
-- Query completo y optimizado
```
**Explicación**: ...
**Performance esperado**: X segundos para 1 día

[Repetir para las 4 queries]

---

## 4. CASOS ESPECIALES

### 4.1 Tickets Parcialmente Anulados
**Solución propuesta**: ...

[Analizar los 5 casos especiales]

---

## 5. PERFORMANCE

### 5.1 Índices Propuestos
```sql
-- Lista completa de índices
```

### 5.2 Estimación de Volumen
[Tabla con datos reales]

### 5.3 Tiempo de ETL
- Header: X seg
- Items: Y seg
- Modifiers: Z seg
- Misc: W seg
- **Total**: T seg ✅ / ❌

---

## 6. RIESGOS Y MITIGACIÓN

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Datos inconsistentes | Media | Alto | Usar transacciones |
| ... | ... | ... | ... |

---

## 7. VALIDACIÓN CON DATOS REALES

### 7.1 Exploración de Schema
```sql
-- Queries usados para explorar
```

### 7.2 Hallazgos
- `ticket_item.name` existe: SÍ / NO
- Items sin `menu_item_id`: X registros encontrados
- Timezone en `closing_date`: ...

---

## 8. RECOMENDACIONES FINALES

### Para CODEX (Implementación):
1. [Recomendación técnica 1]
2. [Recomendación técnica 2]
...

### Para Claude Code (Coordinación):
1. [Consideración arquitectónica 1]
2. [Consideración arquitectónica 2]
...

### Cambios Sugeridos a Estrategia Original:
- ✏️ Modificar campo X en tabla Y por [razón]
- ➕ Agregar tabla Z para [caso especial]
- 🔧 Cambiar enfoque de ETL para [optimización]
```

---

## ⏱️ TIEMPO ESTIMADO

| Fase | Descripción | Tiempo |
|------|-------------|--------|
| 1 | Leer documentación y estrategia | 30 min |
| 2 | Explorar base de datos con psql | 45 min |
| 3 | Diseñar queries ETL | 1 hora |
| 4 | Analizar casos especiales | 30 min |
| 5 | Validar con datos reales | 30 min |
| 6 | Escribir documento de análisis | 45 min |
| **TOTAL** | | **~4 horas** |

---

## 🎯 CRITERIOS DE ÉXITO

Tu análisis será exitoso si:

✅ Validas técnicamente las 4 tablas propuestas
✅ Diseñas los 4 queries ETL necesarios
✅ Identificas al menos 3 riesgos con mitigaciones
✅ Propones optimizaciones de índices
✅ Analizas los 5 casos especiales
✅ Estimas volumen y performance con datos reales
✅ Provees recomendaciones accionables para CODEX
✅ Documento completo en `docs/ARCHITECTURE/CONSOLIDATION_TECHNICAL_ANALYSIS.md`

---

## 🚨 IMPORTANTE

### Exploración de Base de Datos

**Tienes acceso completo a psql** para explorar:

```bash
# Conectar a base de datos
psql -h localhost -p 5433 -U postgres -d pos

# Ver estructura de tabla
\d public.ticket
\d public.ticket_item

# Queries de exploración
SELECT * FROM public.ticket_item WHERE menu_item_id IS NULL LIMIT 10;
SELECT COUNT(*) FROM public.ticket WHERE closing_date >= CURRENT_DATE - 1;
```

**Usa queries reales** para validar tus hipótesis. No asumas, verifica.

---

## 📞 COMUNICACIÓN

Cuando completes el análisis:

1. **Commit el archivo** `CONSOLIDATION_TECHNICAL_ANALYSIS.md`
2. **Notifica completado** en PR o issue
3. **Marca hallazgos críticos** con 🚨 en el documento
4. **Si encuentras blockers**: Documenta y escala a Claude Code

---

**Creado por**: Claude Code
**Para**: QWEN (agente de análisis)
**Depende de**: DAILY_SALES_CONSOLIDATION_STRATEGY.md (ya existe)
**Siguiente paso**: CODEX implementará basándose en tu análisis
**Última actualización**: 28-Nov-2025
