# TAREA PARA QWEN - Análisis de Reportes de Ventas
**Fecha**: 28 de noviembre de 2025
**Prioridad**: 🔴 ALTA
**Tiempo estimado**: 4-6 horas
**Tipo**: SOLO ANÁLISIS Y DOCUMENTACIÓN (NO MODIFICAR CÓDIGO)

---

## 🎯 OBJETIVO

Analizar los **3 reportes más complejos** del sistema para identificar:
1. Lógica de negocio
2. Problemas de código
3. Oportunidades de refactorización
4. Queries a la base de datos
5. Dependencias y acoplamiento

---

## 📋 REPORTES A ANALIZAR (en orden de prioridad)

### 1. SalesExceptionsController.php (42KB) 🔴 URGENTE
**Ubicación**: `app/Http/Controllers/Reports/SalesExceptionsController.php`

**Por qué es prioritario**:
- Es el archivo MÁS GRANDE de todos los reportes (42KB)
- Probablemente tiene lógica duplicada
- Maneja casos especiales/anómalos
- Alto acoplamiento esperado

### 2. SalesDetailController.php (35KB) 🔴 URGENTE
**Ubicación**: `app/Http/Controllers/Reports/SalesDetailController.php`

**Por qué es prioritario**:
- Segundo archivo más grande (35KB)
- Probablemente tiene muchas responsabilidades
- Candidato principal para Service layer

### 3. SalesSummaryController.php (26KB) 🟡 MEDIA
**Ubicación**: `app/Http/Controllers/Reports/SalesSummaryController.php`

**Por qué es prioritario**:
- Tercer archivo más grande (26KB)
- Resumen de ventas es crítico para negocio
- Debe coincidir con otros reportes

---

## 📝 ENTREGABLES

Para **CADA UNO** de los 3 reportes, crea un archivo markdown siguiendo esta estructura:

### Archivo: `docs/CODE_REVIEW/{NOMBRE}_ANALYSIS.md`

Ejemplo: `docs/CODE_REVIEW/SALES_EXCEPTIONS_ANALYSIS.md`

---

## 🔍 ESTRUCTURA DEL ANÁLISIS (para cada reporte)

```markdown
# Análisis de {Nombre del Reporte}
**Archivo**: app/Http/Controllers/Reports/{Nombre}Controller.php
**Tamaño**: {tamaño}KB
**Fecha de análisis**: 28-Nov-2025
**Analista**: QWEN

---

## 1. RESUMEN EJECUTIVO

**Propósito del reporte**: [Explicar en 2-3 párrafos qué hace este reporte]

**Complejidad**: ⚠️ Alta / Media / Baja

**Problemas principales identificados**:
1. [Problema 1]
2. [Problema 2]
3. [Problema 3]

**Recomendación**: Refactorizar / Optimizar / Mantener

---

## 2. MÉTODOS PÚBLICOS (endpoints)

Listar todos los métodos públicos del controlador:

| Método | Ruta | Propósito | Líneas | Complejidad |
|--------|------|-----------|--------|-------------|
| show() | GET /reports/sales/xxx | Mostrar reporte | 50-100 | Alta |
| exportPdf() | GET /xxx/export/pdf | Exportar PDF | 20-30 | Media |
| ... | ... | ... | ... | ... |

---

## 3. QUERIES A LA BASE DE DATOS

### 3.1 Tablas consultadas

Listar todas las tablas de PostgreSQL que se consultan:

- `public.ticket`
- `public.ticket_item`
- `public.ticket_item_modifier`
- ... (todas las que encuentres)

### 3.2 Queries identificados

Para cada query importante, documentar:

**Query 1: [Nombre descriptivo]**
```sql
-- SQL aproximado del query (si usas DB::select)
-- o descripción del Query Builder
```

**Propósito**: [Qué busca este query]
**Complejidad**: ⚠️ Alta / Media / Baja
**Posibles problemas**: [N+1, falta de índices, etc.]

---

## 4. LÓGICA DE NEGOCIO

### 4.1 Flujo principal

Describir el flujo de ejecución del método principal:

```
1. Recibir parámetros (fecha_inicio, fecha_fin, sucursal)
2. Validar parámetros
3. Consultar tabla X
4. Procesar datos (agrupar, filtrar, calcular)
5. Aplicar lógica especial para casos Y
6. Retornar vista con datos
```

### 4.2 Casos especiales

Documentar cualquier lógica condicional compleja:

- ¿Hay manejo de excepciones específico?
- ¿Hay validaciones de negocio?
- ¿Hay cálculos complejos?

---

## 5. PROBLEMAS IDENTIFICADOS

### 5.1 Código duplicado

| Líneas | Descripción | Solución propuesta |
|--------|-------------|-------------------|
| 45-60 | Lógica de filtrado repetida | Extraer a método privado |
| ... | ... | ... |

### 5.2 Violaciones de principios SOLID

- **Single Responsibility**: [¿El controlador hace demasiado?]
- **Open/Closed**: [¿Es difícil extender?]
- **Dependency Inversion**: [¿Depende de implementaciones concretas?]

### 5.3 Performance

- ¿Hay queries lentos potenciales?
- ¿Hay N+1 queries?
- ¿Falta paginación?
- ¿Falta caché?

### 5.4 Seguridad

- ¿Hay SQL injection potencial?
- ¿Hay validación de entrada?
- ¿Hay autorización adecuada?

---

## 6. DEPENDENCIAS

### 6.1 Modelos usados

Listar todos los modelos Eloquent usados:
- `Ticket`
- `TicketItem`
- ... (todos)

### 6.2 Servicios/Helpers

- ¿Usa otros servicios?
- ¿Usa helpers globales?
- ¿Tiene acoplamiento con otros controladores?

---

## 7. RECOMENDACIONES DE REFACTORIZACIÓN

### 7.1 Service Layer

**¿Debe tener Service?** Sí / No

**Si sí, qué lógica mover**:
1. [Lógica 1 a mover al servicio]
2. [Lógica 2 a mover al servicio]
3. ...

**Nombre propuesto**: `app/Services/Reports/{Nombre}ReportService.php`

### 7.2 Métodos a extraer

| Líneas actuales | Método a crear | Propósito |
|-----------------|----------------|-----------|
| 50-80 | buildQuery() | Construir query base |
| 100-150 | calculateTotals() | Calcular KPIs |
| ... | ... | ... |

### 7.3 Queries a optimizar

1. Query en línea X: [Problema y solución]
2. Query en línea Y: [Problema y solución]

### 7.4 Validaciones a agregar

- [Validación faltante 1]
- [Validación faltante 2]

---

## 8. COMPARACIÓN CON ItemModsReportService

### 8.1 Similitudes

- [Similitud 1]
- [Similitud 2]

### 8.2 Diferencias

- [Diferencia 1]
- [Diferencia 2]

### 8.3 Patrón a replicar

**Qué aplicar del patrón ItemModsReportService**:
1. [Aspecto 1 a replicar]
2. [Aspecto 2 a replicar]

---

## 9. PLAN DE REFACTORIZACIÓN (para CODEX)

### Fase 1: Preparación
- [ ] Crear archivo de servicio
- [ ] Mover constantes
- [ ] Definir interface del servicio

### Fase 2: Migración de lógica
- [ ] Mover query principal al servicio
- [ ] Mover cálculos de KPIs
- [ ] Mover procesamiento de datos

### Fase 3: Limpieza del controlador
- [ ] Reducir controlador a < 200 líneas
- [ ] Inyectar servicio
- [ ] Eliminar código duplicado

### Fase 4: Tests
- [ ] Crear tests del servicio
- [ ] Crear tests del controlador
- [ ] Validar con datos reales

**Tiempo estimado**: [X horas/días]

---

## 10. MÉTRICAS DE CÓDIGO

| Métrica | Valor Actual | Valor Objetivo | Estado |
|---------|--------------|----------------|--------|
| Líneas de código | {actual} | < 200 | ⚠️ |
| Métodos públicos | {actual} | < 5 | ⚠️ |
| Complejidad ciclomática | {estimado} | < 10 | ⚠️ |
| Nivel de acoplamiento | Alto/Medio/Bajo | Bajo | ⚠️ |

---

## 11. RIESGOS DE REFACTORIZACIÓN

### 11.1 Riesgos técnicos

- [Riesgo 1 y mitigación]
- [Riesgo 2 y mitigación]

### 11.2 Riesgos de negocio

- ¿Hay lógica crítica que no se puede romper?
- ¿Hay dependencias externas?

---

**FIN DEL ANÁLISIS**
```

---

## ⚠️ INSTRUCCIONES IMPORTANTES

### ✅ PUEDES:
- ✅ Leer todos los archivos PHP del proyecto
- ✅ Analizar código sin ejecutarlo
- ✅ Consultar documentación existente
- ✅ Buscar patrones y antipatrones
- ✅ Crear archivos markdown de documentación

### ❌ NO PUEDES:
- ❌ Modificar archivos de código PHP
- ❌ Ejecutar queries en la base de datos
- ❌ Crear o modificar tests
- ❌ Ejecutar comandos de Laravel (artisan)
- ❌ Hacer commits a git

---

## 📚 ARCHIVOS DE REFERENCIA

**Para entender el patrón correcto**:
- `app/Services/Reports/ItemModsReportService.php` ⭐ EJEMPLO A SEGUIR
- `app/Http/Controllers/Reports/SalesModsController.php` ⭐ CONTROLADOR REFACTORIZADO
- `docs/REPORTS/ITEMS_MODS_STRATEGY.md` ⭐ ESTRATEGIA DOCUMENTADA
- `docs/REPORTS/README.md` - Estado general de reportes

**Documentación del proyecto**:
- `CLAUDE.md` - Arquitectura general
- `docs/CODE_REVIEW/SECURITY_PERFORMANCE_REVIEW.md` - Ejemplo de análisis

---

## 🎯 CRITERIOS DE ÉXITO

Tu trabajo será exitoso si:

✅ Los 3 análisis están completos y detallados
✅ Identificas al menos 5 problemas por reporte
✅ Propones un plan de refactorización claro
✅ Comparas con el patrón ItemModsReportService
✅ Las recomendaciones son específicas y accionables
✅ El análisis es técnicamente preciso

---

## 📦 ENTREGA

**Archivos a crear** (3 archivos):
1. `docs/CODE_REVIEW/SALES_EXCEPTIONS_ANALYSIS.md`
2. `docs/CODE_REVIEW/SALES_DETAIL_ANALYSIS.md`
3. `docs/CODE_REVIEW/SALES_SUMMARY_ANALYSIS.md`

**Formato**: Markdown, siguiendo la estructura proporcionada
**Tiempo límite**: 6 horas de trabajo
**Próxima fase**: CODEX usará estos análisis para refactorizar

---

## 🚀 COMIENZA AQUÍ

1. Lee `app/Http/Controllers/Reports/SalesExceptionsController.php`
2. Analiza siguiendo la estructura
3. Documenta en `docs/CODE_REVIEW/SALES_EXCEPTIONS_ANALYSIS.md`
4. Repite para los otros 2 reportes
5. Notifica cuando termines

---

**IMPORTANTE**: Este es SOLO análisis. NO modifiques código. CODEX hará la refactorización basándose en tu análisis.

---

**Última actualización**: 28-Nov-2025
**Creado por**: Claude Code
**Para**: QWEN (agente de análisis)
