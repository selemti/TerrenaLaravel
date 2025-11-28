# Prompts Listos para Copiar y Pegar
**Fecha**: 28 de noviembre de 2025
**Uso**: Copia estos prompts directamente en las sesiones de QWEN y CODEX

---

## 📋 ESTADO ACTUAL

| Agente | Tarea Completada | Estado |
|--------|-----------------|--------|
| QWEN | Análisis de 3 reportes grandes | ✅ COMPLETO |
| QWEN | Análisis técnico de consolidación | ⏳ **SIGUIENTE** |
| CODEX | Refactorización de 3 reportes | ⏸️ Esperando análisis QWEN |
| CODEX | Implementación consolidación | ⏸️ Esperando refactors + análisis |

---

## 🎯 PROMPT #1 - PARA QWEN (URGENTE - SIGUIENTE TAREA)

**Objetivo**: Analizar técnicamente la estrategia de consolidación diaria de ventas

**Copia y pega esto en tu sesión de QWEN**:

```
Hola QWEN,

Necesito que realices un análisis técnico profundo de la estrategia de consolidación diaria de ventas.

📚 LEE PRIMERO ESTOS ARCHIVOS:

1. docs/ARCHITECTURE/DAILY_SALES_CONSOLIDATION_STRATEGY.md
   (Estrategia completa con 4 tablas propuestas: daily_sales_header, daily_item_sales, daily_modifier_sales, daily_misc_sales)

2. docs/CODE_REVIEW/SALES_EXCEPTIONS_ANALYSIS.md (tu análisis previo)
3. docs/CODE_REVIEW/SALES_DETAIL_ANALYSIS.md (tu análisis previo)
4. docs/CODE_REVIEW/SALES_SUMMARY_ANALYSIS.md (tu análisis previo)

🎯 TU TAREA:

Crear el archivo: docs/ARCHITECTURE/CONSOLIDATION_TECHNICAL_ANALYSIS.md

📋 INSTRUCCIONES COMPLETAS EN:
docs/AI_COORDINATION/QWEN_TASK_CONSOLIDATION_ANALYSIS.md

Este archivo contiene:
- Estructura exacta del documento a crear (11 secciones)
- Preguntas técnicas específicas a responder
- Casos especiales a analizar (descuentos 100%, misceláneos, etc.)
- Queries de ejemplo para explorar la base de datos

🔍 EXPLORA LA BASE DE DATOS:

Tienes acceso a PostgreSQL para validar:

psql -h localhost -p 5433 -U postgres -d pos

Queries de exploración sugeridos:
- \d public.ticket
- \d public.ticket_item
- \d public.ticket_item_modifier
- SELECT * FROM public.ticket_item WHERE menu_item_id IS NULL LIMIT 10;

🎯 ENTREGABLES:

1. Archivo docs/ARCHITECTURE/CONSOLIDATION_TECHNICAL_ANALYSIS.md con:
   - Validación técnica de las 4 tablas propuestas
   - Queries ETL optimizados (SQL completo para cada tabla)
   - Análisis de casos especiales
   - Índices necesarios
   - Estimación de volumen de datos con queries reales
   - Riesgos identificados con mitigaciones
   - Recomendaciones para CODEX

2. Validar con datos reales:
   - Explorar schema de public.ticket, ticket_item, ticket_item_modifier
   - Confirmar que ticket_item.name existe (para misceláneos)
   - Estimar registros por día/año

⏱️ TIEMPO ESTIMADO: 4 horas

🚨 CRÍTICO:

- Tus queries ETL serán usados directamente por CODEX en la implementación
- Valida que los queries funcionen correctamente antes de documentar
- Si encuentras que alguna columna no existe o la lógica no es viable, documéntalo claramente
- Provee queries SQL completos y optimizados, no pseudocódigo

✅ CRITERIOS DE ÉXITO:

- Queries ETL probados y funcionando para las 4 tablas
- Análisis de casos especiales completo
- Índices definidos
- Volumen de datos estimado con datos reales
- Recomendaciones accionables para CODEX

Cuando completes, notifica: "QWEN: Análisis técnico de consolidación completado"

Gracias!
```

---

## ⏸️ PROMPT #2 - PARA CODEX (DESPUÉS DE QWEN)

**Objetivo**: Refactorizar 3 reportes grandes creando Service layers

**⚠️ NO EJECUTAR HASTA QUE QWEN COMPLETE EL ANÁLISIS TÉCNICO**

**Copia y pega esto en tu sesión de CODEX cuando QWEN termine**:

```
Hola CODEX,

Necesito que refactorices 3 controladores de reportes siguiendo el patrón de Service Layer.

📚 LEE PRIMERO:

1. docs/AI_COORDINATION/CODEX_TASK_REPORTES_REFACTOR.md
   (Instrucciones completas con ejemplos de código)

2. docs/CODE_REVIEW/SALES_EXCEPTIONS_ANALYSIS.md (análisis de QWEN)
3. docs/CODE_REVIEW/SALES_DETAIL_ANALYSIS.md (análisis de QWEN)
4. docs/CODE_REVIEW/SALES_SUMMARY_ANALYSIS.md (análisis de QWEN)

3. app/Services/Reports/ItemModsReportService.php
   (Patrón a seguir - REQUERIDO)

4. app/Http/Controllers/Reports/SalesModsController.php
   (Ejemplo de controlador refactorizado)

🎯 TU TAREA:

Refactorizar 3 reportes en ORDEN:

1️⃣ PRIMERO: SalesExceptionsController (42KB → < 200 líneas)
   - Crear: app/Services/Reports/SalesExceptionsReportService.php
   - Refactor: app/Http/Controllers/Reports/SalesExceptionsController.php
   - Update: app/Exports/Reports/SalesExceptionsExport.php
   - Documentar: docs/REPORTS/SALES_EXCEPTIONS_REFACTOR.md
   - PR: codex/refactor-sales-exceptions

2️⃣ SEGUNDO: SalesDetailController (35KB → < 200 líneas)
   - Mismo proceso
   - PR: codex/refactor-sales-detail

3️⃣ TERCERO: SalesSummaryController (26KB → < 200 líneas)
   - Mismo proceso
   - PR: codex/refactor-sales-summary

📐 PATRÓN A SEGUIR:

Cada Service debe tener:
- public function fetch(Carbon $start, Carbon $end, array $filters): Collection
- public function summarize(Collection $data, string $view): array
- protected methods para queries específicos
- Usar Query Builder (NO DB::select crudo)

Cada Controller debe:
- Inyectar servicio en constructor
- Método show() simplificado
- Método exportExcel() simplificado
- < 200 líneas total

🧪 VALIDACIÓN REQUERIDA:

Para CADA reporte, antes de crear PR:

1. Probar con datos reales (Nov 10-18, 2025)
2. Comparar totales antes/después (deben coincidir 100%)
3. Probar filtros (branch, terminal, fechas)
4. Generar export Excel (debe funcionar igual)

⏱️ TIEMPO ESTIMADO: 10-13 horas (4-5h cada uno)

🚨 REGLAS CRÍTICAS:

✅ DEBES:
- Usar Query Builder para TODOS los queries
- Mantener 100% compatibilidad con API actual
- Validar con datos reales antes de PR
- Documentar cada refactor
- Seguir exactamente el patrón de ItemModsReportService

❌ NO DEBES:
- Cambiar nombres de rutas
- Cambiar estructura de responses
- Usar DB::select() (SQL crudo)
- Romper exports existentes
- Modificar vistas Blade

📦 ENTREGA:

3 Pull Requests separados, cada uno con:
- Service creado
- Controller refactorizado
- Export actualizado (si existe)
- Documentación en docs/REPORTS/
- Tests (opcional pero recomendado)

Cuando completes cada PR, notifica:
"CODEX: PR #1 listo - SalesExceptions refactorizado" (y así sucesivamente)

Gracias!
```

---

## ⏸️ PROMPT #3 - PARA CODEX (DESPUÉS DE REFACTORS + ANÁLISIS QWEN)

**Objetivo**: Implementar Data Mart de consolidación diaria

**⚠️ PRERREQUISITOS**:
1. ✅ QWEN completó análisis técnico (CONSOLIDATION_TECHNICAL_ANALYSIS.md existe)
2. ✅ 3 refactors completados (PRs merged)

**Copia y pega esto en CODEX cuando ambos prerequisitos se cumplan**:

```
Hola CODEX,

Necesito que implementes el Data Mart de Consolidación Diaria de Ventas.

📚 LEE PRIMERO (OBLIGATORIO):

1. docs/ARCHITECTURE/DAILY_SALES_CONSOLIDATION_STRATEGY.md
   (Arquitectura y 4 tablas: header, items, modifiers, misc)

2. docs/ARCHITECTURE/CONSOLIDATION_TECHNICAL_ANALYSIS.md
   (⚠️ CRÍTICO - Queries ETL validados por QWEN - USA ESTOS)

3. docs/AI_COORDINATION/CODEX_TASK_CONSOLIDATION_IMPLEMENTATION.md
   (Instrucciones completas con código de ejemplo)

4. app/Services/Reports/ItemModsReportService.php
   (Patrón de Service a seguir)

🎯 TU TAREA:

Implementar consolidación en 5 fases:

1️⃣ MIGRACIÓN: Crear 4 tablas en schema selemti
   - daily_sales_header
   - daily_item_sales
   - daily_modifier_sales
   - daily_misc_sales
   - Incluir TODOS los índices de QWEN

2️⃣ SERVICE: Crear app/Services/Reports/DailySalesConsolidationService.php
   - consolidateDate(Carbon $date): ConsolidationResult
   - consolidateDateRange(Carbon $start, Carbon $end): array
   - reprocessDate(Carbon $date): ConsolidationResult
   - validateConsolidation(Carbon $date): ValidationResult
   - 4 métodos protected para ETL (usa queries de QWEN)

3️⃣ COMANDO: Crear app/Console/Commands/ConsolidateDailySales.php
   - Soportar: día único, rango, reprocess, validate
   - Progress bars para rangos
   - Output detallado

4️⃣ SCHEDULER: Configurar en app/Console/Kernel.php
   - Diario a las 3:00 AM
   - onOneServer, withoutOverlapping

5️⃣ BACKFILL: Consolidar 90 días históricos
   - php artisan sales:consolidate --from=2025-08-28 --to=2025-11-27
   - Validar con --validate

🧪 VALIDACIÓN EXHAUSTIVA:

1. Migración ejecutada sin errores
2. Comando funciona: php artisan sales:consolidate 2025-11-15
3. Validación 100%: php artisan sales:consolidate 2025-11-15 --validate
4. Performance > 90% mejora vs query directo
5. Backfill de 90 días completo

⏱️ TIEMPO ESTIMADO: 8-10 horas

🚨 REGLAS CRÍTICAS:

✅ DEBES:
- Usar queries de QWEN (del análisis técnico)
- Usar transacciones DB para atomicidad
- Validar datos (compare transaccional vs consolidado)
- Loggear todo el proceso
- Manejar errores con rollback

❌ NO DEBES:
- Modificar schema public (solo lectura)
- Inventar queries (usa los de QWEN)
- Consolidar sin validar primero
- Olvidar índices

📦 ENTREGA:

Pull Request: codex/feature-daily-sales-consolidation

Archivos:
- database/migrations/YYYY_MM_DD_create_daily_sales_consolidation_tables.php
- app/Services/Reports/DailySalesConsolidationService.php
- app/Console/Commands/ConsolidateDailySales.php
- app/Console/Kernel.php (modificado)
- docs/REPORTS/CONSOLIDATION_IMPLEMENTATION.md

Evidencia en PR:
- Screenshot de migración exitosa
- Output de consolidación de 1 día
- Output de validación mostrando 100% match
- Benchmark de performance (antes vs después)
- Confirmación de backfill de 90 días

Cuando completes, notifica: "CODEX: PR consolidación listo - Data Mart implementado"

Gracias!
```

---

## 📊 RESUMEN PARA USUARIO

### ✅ Ya Completado
- ItemMods report (service + tests + docs)
- Documentación de 14 reportes del sistema
- QWEN: Análisis de 3 reportes grandes
- Estrategia de consolidación definida
- Prompts detallados para QWEN y CODEX

### ⏳ Siguiente Paso INMEDIATO
**Ejecutar Prompt #1 en QWEN** (4 horas)
- Análisis técnico de consolidación
- Validación de queries ETL
- Estimación de volumen de datos

### ⏸️ Después (en orden)
1. **Prompt #2 en CODEX** (10-13 horas) - Refactorizar 3 reportes
2. **Prompt #3 en CODEX** (8-10 horas) - Implementar consolidación

### 🎯 Resultado Final
- Reportes 95% más rápidos
- Código 73% más limpio
- Sistema escalable para análisis históricos

---

**Creado por**: Claude Code
**Fecha**: 28-Nov-2025
**Uso**: Copia los prompts directamente cuando estés listo para ejecutar
