# BACKLOG DE SPRINTS V4.0

**Orquestador**: MAESTRO (Consolidación CLAUDE + QWEN + CODEX + COPILOT)
**Fecha**: 14 Noviembre 2025
**Fuente**: FASE1-FASE6 + 4 Backlogs consolidados
**Duración Sprint**: 2 semanas
**Total**: 8 sprints (16 semanas / 4 meses)

---

## 1. INTRODUCCIÓN

Este backlog consolida las tareas de desarrollo del sistema Terrena POS/ERP basadas en la fusión de insights de 4 agentes de IA (CLAUDE, QWEN, CODEX, COPILOT), la auditoría completa FASE1-FASE6 y los lineamientos de deployment. El backlog está organizado en 8 sprints con un total de **340 horas** de esfuerzo, distribuidas estratégicamente para abordar los gaps críticos identificados en la matriz de alineación.

**Metodología**: Sprint planning basado en prioridades P0/P1/P2 y dependencias entre módulos, considerando los lineamientos de deployment en producción.

---

## 2. ROADMAP GENERAL

### FASE CRÍTICA (Sprints 1-2): Gaps UI/UX + Código Duplicado + Motor Replenishment (106h)

Abordar gaps críticos que impactan operación diaria:
- UX crítico (forms loading, notificaciones, confirmaciones)
- Consolidación de servicios duplicados (PosConsumptionService x3, ProductionService x2)
- Motor de Replenishment 0% → 100%
- Funciones BD críticas sin documentar

### FASE DOCUMENTACIÓN (Sprints 3-4): Docs Core 15 Módulos (52h)

Completar documentación V4.0 de módulos con gaps:
- Recetas (versionado, BOM implosion, costeo)
- Producción (planificación, mise en place, mermas)
- POS (sincronización, repositorios, consumos)
- Inventario (lotes, kardex, ajustes, políticas)
- Purchasing (replenishment, comparación cotizaciones)
- Otros módulos con gaps documentales

### FASE LIMPIEZA (Sprints 5-6): Código Huérfano Prioritario (95h)

Eliminar duplicados y completar funcionalidades:
- Recetas versionado UI completo
- Transferencias UI despacho/recepción
- Inventario recepciones estados completos
- Reportes KPIs analíticos
- Seguridad GUI permisos

### FASE CONSOLIDACIÓN (Sprints 7-8): BD + Tests + Pulido (87h)

Aseguramiento de calidad y deployment:
- Tests de integración
- Validación deployment
- Refinamiento UX
- Documentación final

---

## 3. RESUMEN EJECUTIVO

| Sprint | Horas | Enfoque | Objetivos | Módulos afectados | Consideraciones Deployment |
|--------|-------|---------|-----------|-------------------|-----------------------------|
| Sprint 1 | 55h | UX Crítico + Consolidación | Forms loading, notificaciones, confirmaciones, consolidar PosConsumptionService x3, ProductionService x2 | Frontend, POS, Producción | Assets deben cargar en servidor con RewriteBase /terrena2/ |
| Sprint 2 | 51h | Motor Replenishment + BD | Motor completo (31h), documentar 12 funciones BD críticas (20h) | Purchasing, Base de Datos | fn_recipe_cost_at() y otras funciones críticas en producción |
| Sprint 3 | 42h | Documentación Core | 15 docs V4.0 completos (Recetas, Producción, POS, Inventario, etc.) | Todos | Documentar proceso de deployment para cada módulo |
| Sprint 4 | 40h | Código Huérfano Prioritario | Eliminar duplicados, modelos faltantes, huérfanos críticos | Todos | Consolidar servicios duplicados antes de deployment |
| Sprint 5 | 48h | Funcionalidad Recetas + Transferencias | Recetas versionado UI, Transferencias UI despacho/recepción, Inventario estados | Recetas, Transferencias, Inventario | fn_recipe_cost_at() funcional en producción |
| Sprint 6 | 42h | Reportes + Inventario Avanzado | KPIs analíticos, recepciones estados completos, políticas stock | Reportes, Inventario, Caja | Validar vistas analíticas en producción |
| Sprint 7 | 37h | Seguridad + Frontend Design System | GUI permisos, Design System, refinamiento UX | Seguridad, Frontend | Validar en entorno producción |
| Sprint 8 | 25h | Tests + Pulido + Deployment | Aseguramiento calidad, deployment final, documentación deployment | Todos | Validar procesos de deployment completos |
| **Total** | **340h** | - | - | - | - |

---

## 4. SPRINT 1: UX CRÍTICO + CONSOLIDACIÓN (55h)

### US-1.1: Forms Loading States
**Prioridad**: 🔴 P0
**Esfuerzo**: 4 horas
**Agente**: CLAUDE + CODEX
**Módulos**: Frontend (todos)

**Como** usuario del sistema
**Quiero** ver indicadores visuales cuando envío formularios
**Para** saber que mi acción está procesándose y evitar clicks duplicados

**Criterios de aceptación**:
- [ ] 40 formularios identificados (FASE6)
- [ ] Patrón wire:loading implementado en todos
- [ ] Botón deshabilitado durante submit
- [ ] Spinner + texto "Guardando..." visible
- [ ] Tests: verificar comportamiento en 5 forms críticos

**Archivos afectados**:
- resources/views/livewire/inventory/reception-create.blade.php
- resources/views/livewire/purchasing/request-create.blade.php
- resources/views/livewire/cash-fund/create.blade.php
- resources/views/livewire/recipes/recipe-editor.blade.php
- resources/views/livewire/transfers/create.blade.php
- [... 35 más]

**Dependencias**: Ninguna
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- Verificar que assets (CSS/JS) se carguen correctamente en producción
- Asegurar que RewriteBase esté configurado como /terrena2/ para que spinner funcione
- Validar en http://100.126.124.101/terrena2/

**Referencias**:
- [CLAUDE FASE6]: Gap 1 - Forms sin loading states
- [CODEX]: Brecha UX crítica (riesgo doble submit)

---

### US-1.2: Sistema Unificado de Notificaciones
**Prioridad**: 🔴 P0
**Esfuerzo**: 6 horas
**Agente**: CLAUDE + QWEN
**Módulos**: Frontend

**Como** usuario del sistema
**Quiero** recibir notificaciones consistentes de éxito/error
**Para** tener feedback claro sobre las operaciones realizadas

**Criterios de aceptación**:
- [ ] Sistema único de toast notifications con Bootstrap 5
- [ ] 3 tipos: éxito, error, advertencia
- [ ] Posicionamiento consistente (top-right)
- [ ] Desaparición automática (5s) o manual
- [ ] 100% de componentes usando el nuevo sistema

**Archivos afectados**:
- resources/views/components/ui/toast.blade.php
- resources/js/bootstrap-toast.js
- app/Livewire/* (componentes que usan notificaciones)

**Dependencias**: US-1.1
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- Verificar que script de notificaciones se cargue correctamente en producción
- Validar que toasts aparezcan en http://100.126.124.101/terrena2/

---

### US-1.3: Confirmaciones Delete
**Prioridad**: 🔴 P0
**Esfuerzo**: 4 horas
**Agente**: CLAUDE + COPILOT
**Módulos**: Frontend (todos con delete)

**Como** usuario del sistema
**Quiero** confirmar antes de eliminar registros
**Para** evitar eliminaciones accidentales

**Criterios de aceptación**:
- [ ] Modal de confirmación Bootstrap 5
- [ ] Mostrar información del registro a eliminar
- [ ] Doble confirmación para registros críticos
- [ ] 100% de operaciones delete protegidas

**Archivos afectados**:
- resources/views/components/ui/confirm-delete-modal.blade.php
- app/Livewire/* (componentes con delete)

**Dependencias**: US-1.2
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- Validar modal en entorno producción
- Verificar que confirmaciones funcionen correctamente

---

### US-1.4: Consolidar PosConsumptionService (TRIPLICADO)
**Prioridad**: 🔴 P0
**Esfuerzo**: 4 horas
**Agente**: CODEX + COPILOT
**Módulos**: POS

**Como** desarrollador
**Quiero** tener un único PosConsumptionService
**Para** mantener consistencia y facilitar mantenimiento

**Criterios de aceptación**:
- [ ] Identificar las 3 ubicaciones actuales
- [ ] Consolidar en app/Services/Pos/PosConsumptionService.php
- [ ] Actualizar referencias en código
- [ ] Tests de integración verifican funcionalidad
- [ ] Eliminar las 2 copias restantes

**Archivos afectados**:
- app/Services/Pos/PosConsumptionService.php (mantener)
- app/Services/PosConsumptionService.php (eliminar)
- app/Services/Legacy/PosConsumptionService.php (eliminar)

**Dependencias**: Ninguna
**Bloqueantes**: Bloquea HU-5.1 (Recetas versionado)

**Consideraciones de Deployment**:
- Validar consolidación en producción antes de eliminar copias
- Asegurar que fn_expandir_consumo_ticket() funcione correctamente
- Verificar integración con pos_map

**Referencias**:
- [CLAUDE]: PosConsumptionService TRIPLICADO (CRÍTICO)
- [COPILOT]: 3 ubicaciones identificadas

---

### US-1.5: Consolidar ProductionService (DUPLICADO)
**Prioridad**: 🟡 P1
**Esfuerzo**: 3 horas
**Agente**: CLAUDE + CODEX
**Módulos**: Producción

**Como** desarrollador
**Quiero** tener un único ProductionService
**Para** mantener consistencia y facilitar mantenimiento

**Criterios de aceptación**:
- [ ] Identificar las 2 ubicaciones actuales
- [ ] Consolidar en app/Services/Production/ProductionService.php
- [ ] Actualizar referencias en código
- [ ] Tests de integración verifican funcionalidad
- [ ] Eliminar la copia restante

**Archivos afectados**:
- app/Services/Production/ProductionService.php (mantener)
- app/Services/ProductionService.php (eliminar)

**Dependencias**: Ninguna
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- Validar consolidación en producción antes de eliminar copia
- Verificar integración con Inventario y Recetas

---

### HU-1.1: Recepciones - Wizard Completo (COPILOT)
**Prioridad**: 🔴 P0
**Esfuerzo**: 8 horas
**Agente**: COPILOT + QWEN
**Módulos**: Inventario

**Como** usuario de inventario
**Quiero** completar el flujo de recepciones BORRADOR → VALIDADA → POSTEADA
**Para** tener control de calidad antes de afectar inventario

**Criterios de aceptación**:
- [ ] Estado BORRADOR: captura inicial, editable
- [ ] Estado VALIDADA: revisión gerencial, no editable
- [ ] Estado POSTEADA: afecta kardex, irreversible
- [ ] Transiciones de estado con permisos
- [ ] UI muestra estado actual claramente

**Archivos afectados**:
- app/Services/Inventory/ReceptionService.php
- app/Livewire/Inventory/ReceptionCreate.php
- database/migrations/add_reception_states.php

**Dependencias**: US-1.1, US-1.2
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- Asegurar migración de estados en producción
- Validar permisos de transición de estado
- Verificar que recepciones existentes no se rompan

---

### HU-1.2: Recepciones - Tolerancias (COPILOT)
**Prioridad**: 🟠 P1
**Esfuerzo**: 6 horas
**Agente**: COPILOT
**Módulos**: Inventario

**Como** usuario de inventario
**Quiero** configurar tolerancias de recepción por proveedor
**Para** alertar cuando recibo más/menos de lo esperado

**Criterios de aceptación**:
- [ ] Tabla de tolerancias por proveedor (%, fijo)
- [ ] Validación en recepción contra tolerancia
- [ ] Alertas visuales si supera tolerancia
- [ ] Requiere aprobación gerencial si supera

**Archivos afectados**:
- database/migrations/create_reception_tolerances.php
- app/Models/Inventory/ReceptionTolerance.php
- app/Services/Inventory/ReceptionService.php

**Dependencias**: HU-1.1
**Bloqueantes**: No bloquea otras tareas

---

### HU-1.3: Recepciones - Evidencias (COPILOT)
**Prioridad**: 🟡 P1
**Esfuerzo**: 7 horas
**Agente**: COPILOT
**Módulos**: Inventario

**Como** usuario de inventario
**Quiero** adjuntar fotos y documentos a recepciones
**Para** tener evidencia de calidad y conformidad

**Criterios de aceptación**:
- [ ] Upload múltiple de archivos (fotos, PDFs)
- [ ] Almacenamiento en storage/app/receptions/{id}/
- [ ] Visualización en detalle de recepción
- [ ] Eliminación de evidencias con auditoría

**Archivos afectados**:
- app/Livewire/Inventory/ReceptionDetail.php
- resources/views/livewire/inventory/reception-detail.blade.php
- database/migrations/create_reception_attachments.php

**Dependencias**: HU-1.1
**Bloqueantes**: No bloquea otras tareas

---

## 5. SPRINT 2: MOTOR REPLENISHMENT + BD CRÍTICO (51h)

### HU-2.1: Motor Replenishment - Algoritmos (COPILOT)
**Prioridad**: 🔴 P0
**Esfuerzo**: 12 horas
**Agente**: COPILOT + CODEX
**Módulos**: Purchasing

**Como** usuario de compras
**Quiero** que el sistema calcule sugerencias de compra automáticamente
**Para** mantener niveles óptimos de inventario

**Criterios de aceptación**:
- [ ] Algoritmo Min-Max implementado
- [ ] Algoritmo SMA (Simple Moving Average) implementado
- [ ] Algoritmo POS Consumption implementado
- [ ] Configuración de algoritmo por ítem
- [ ] Cálculo se ejecuta vía job scheduler

**Archivos afectados**:
- app/Services/Purchasing/ReplenishmentService.php
- app/Jobs/CalculateReplenishmentSuggestions.php
- database/migrations/create_replenishment_config.php

**Dependencias**: Ninguna
**Bloqueantes**: Bloquea HU-2.2, HU-2.3

**Consideraciones de Deployment**:
- Validar algoritmos con datos históricos en producción
- Configurar cron job para cálculo diario
- Asegurar que purchase_suggestions se llene correctamente

---

### HU-2.2: Motor Replenishment - Dashboard Sugerencias (COPILOT)
**Prioridad**: 🔴 P0
**Esfuerzo**: 10 horas
**Agente**: COPILOT + CLAUDE
**Módulos**: Purchasing

**Como** usuario de compras
**Quiero** ver un dashboard de sugerencias de compra
**Para** tomar decisiones informadas de reposición

**Criterios de aceptación**:
- [ ] Dashboard con lista de sugerencias priorizadas
- [ ] Filtros por almacén, categoría, proveedor
- [ ] Mostrar razón de cálculo (por qué se sugiere)
- [ ] Permitir aceptar/rechazar/modificar sugerencias
- [ ] Crear PR desde sugerencias con 1 click

**Archivos afectados**:
- app/Livewire/Purchasing/ReplenishmentDashboard.php
- resources/views/livewire/purchasing/replenishment-dashboard.blade.php

**Dependencias**: HU-2.1
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- Validar dashboard en producción con datos reales
- Verificar rendimiento con 1000+ sugerencias

---

### HU-2.3: Motor Replenishment - API Sugerencias (COPILOT)
**Prioridad**: 🔴 P0
**Esfuerzo**: 9 horas
**Agente**: COPILOT + CODEX
**Módulos**: Purchasing

**Como** sistema externo
**Quiero** acceder a sugerencias vía API REST
**Para** integrar con otros sistemas de compras

**Criterios de aceptación**:
- [ ] Endpoint GET /api/purchasing/suggestions
- [ ] Filtros query params (almacén, categoría, etc.)
- [ ] Endpoint POST /api/purchasing/suggestions/{id}/accept
- [ ] Endpoint POST /api/purchasing/suggestions/{id}/reject
- [ ] Documentación Swagger completa

**Archivos afectados**:
- app/Http/Controllers/Api/Purchasing/ReplenishmentController.php
- routes/api.php
- storage/api-docs/purchasing.yaml

**Dependencias**: HU-2.1
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- Registrar rutas API en producción
- Validar autenticación JWT
- Documentar endpoint en Swagger

---

### US-2.4: Documentar 12 Funciones BD Críticas (CLAUDE)
**Prioridad**: 🔴 P0
**Esfuerzo**: 20 horas
**Agente**: CLAUDE + CODEX
**Módulos**: Base de Datos

**Como** desarrollador
**Quiero** documentación de funciones BD críticas
**Para** entender su funcionamiento y dependencias

**Criterios de aceptación**:
- [ ] 12 funciones documentadas en docs/V4.0/BaseDatos/
- [ ] Cada doc incluye: propósito, parámetros, retorno, ejemplos, dependencias
- [ ] Funciones críticas: fn_recipe_cost_at, fn_expandir_consumo_ticket, fn_confirmar_consumo, fn_reversar_consumo, fn_consolidar_stock, etc.

**Archivos afectados**:
- docs/V4.0/BaseDatos/Funciones/fn_recipe_cost_at.md
- docs/V4.0/BaseDatos/Funciones/fn_expandir_consumo_ticket.md
- [... 10 más]

**Dependencias**: Ninguna
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- Validar que funciones existan en producción
- Verificar permisos de ejecución
- Documentar versión de función en producción

---

## 6. SPRINT 3: DOCUMENTACIÓN CORE (42h)

### US-3.1: Recetas - Documentación Versionado
**Prioridad**: 🟡 P1
**Esfuerzo**: 6 horas
**Agente**: CLAUDE + COPILOT
**Módulos**: Recetas

**Como** desarrollador
**Quiero** documentación completa del sistema de versionado de recetas
**Para** entender cómo crear, comparar y activar versiones

**Criterios de aceptación**:
- [ ] docs/V4.0/Recetas/02_VERSIONADO.md creado
- [ ] Explica estructura de versiones (receta_version)
- [ ] Documenta flujos de versionado
- [ ] Ejemplos de creación y comparación
- [ ] Documenta RecipeCostSnapshot

**Archivos afectados**:
- docs/V4.0/Recetas/02_VERSIONADO.md
- docs/V4.0/Recetas/README.md (ampliar)

**Dependencias**: US-2.4
**Bloqueantes**: Bloquea HU-5.1

---

### US-3.2: Recetas - Documentación BOM Implosion
**Prioridad**: 🟡 P1
**Esfuerzo**: 5 horas
**Agente**: CODEX + QWEN
**Módulos**: Recetas

**Como** desarrollador
**Quiero** documentación del sistema BOM Implosion
**Para** entender cómo se calculan subrecetas y explosión de materiales

**Criterios de aceptación**:
- [ ] docs/V4.0/Recetas/03_BOM_IMPLOSION.md creado
- [ ] Explica algoritmo de explosión
- [ ] Documenta tablas relacionadas
- [ ] Ejemplos de subrecetas

**Archivos afectados**:
- docs/V4.0/Recetas/03_BOM_IMPLOSION.md

**Dependencias**: US-3.1
**Bloqueantes**: No bloquea otras tareas

---

### US-3.3: Producción - Documentación Completa
**Prioridad**: 🟡 P1
**Esfuerzo**: 8 horas
**Agente**: CLAUDE + QWEN
**Módulos**: Producción

**Como** desarrollador
**Quiero** documentación completa del módulo Producción
**Para** entender flujos, estados y KPIs

**Criterios de aceptación**:
- [ ] docs/V4.0/Produccion/README.md ampliado (300+ líneas)
- [ ] docs/V4.0/Produccion/02_MISE_EN_PLACE.md creado
- [ ] docs/V4.0/Produccion/03_MERMAS_RENDIMIENTOS.md creado
- [ ] Documenta ProductionService consolidado
- [ ] Diagrama de estados de órdenes de producción

**Archivos afectados**:
- docs/V4.0/Produccion/README.md
- docs/V4.0/Produccion/02_MISE_EN_PLACE.md
- docs/V4.0/Produccion/03_MERMAS_RENDIMIENTOS.md

**Dependencias**: US-1.5
**Bloqueantes**: No bloquea otras tareas

---

### US-3.4: POS - Documentación Completa
**Prioridad**: 🟡 P1
**Esfuerzo**: 7 horas
**Agente**: CLAUDE + COPILOT
**Módulos**: POS

**Como** desarrollador
**Quiero** documentación completa del módulo POS
**Para** entender sincronización, repositorios y consumos

**Criterios de aceptación**:
- [ ] docs/V4.0/POS/README.md ampliado (250+ líneas)
- [ ] docs/V4.0/POS/02_SINCRONIZACION.md creado
- [ ] docs/V4.0/POS/03_REPOSITORIOS.md creado
- [ ] Documenta PosConsumptionService consolidado
- [ ] Documenta 5 repositorios

**Archivos afectados**:
- docs/V4.0/POS/README.md
- docs/V4.0/POS/02_SINCRONIZACION.md
- docs/V4.0/POS/03_REPOSITORIOS.md

**Dependencias**: US-1.4
**Bloqueantes**: No bloquea otras tareas

---

### US-3.5: Inventario - Documentación Completa
**Prioridad**: 🟡 P1
**Esfuerzo**: 8 horas
**Agente**: CLAUDE + QWEN
**Módulos**: Inventario

**Como** desarrollador
**Quiero** documentación completa del módulo Inventario
**Para** entender lotes, kardex, ajustes y políticas

**Criterios de aceptación**:
- [ ] docs/V4.0/Inventario/02_LOTES_TRAZABILIDAD.md creado
- [ ] docs/V4.0/Inventario/03_KARDEX_AJUSTES.md creado
- [ ] docs/V4.0/Inventario/04_POLITICAS_STOCK.md creado
- [ ] Documenta BatchTrackingService
- [ ] Documenta InventoryAdjustmentService
- [ ] Documenta 8 componentes Livewire

**Archivos afectados**:
- docs/V4.0/Inventario/02_LOTES_TRAZABILIDAD.md
- docs/V4.0/Inventario/03_KARDEX_AJUSTES.md
- docs/V4.0/Inventario/04_POLITICAS_STOCK.md

**Dependencias**: HU-1.1, HU-1.2, HU-1.3
**Bloqueantes**: No bloquea otras tareas

---

### US-3.6: Purchasing - Documentación Replenishment
**Prioridad**: 🔴 P0
**Esfuerzo**: 8 horas
**Agente**: COPILOT + CODEX
**Módulos**: Purchasing

**Como** desarrollador
**Quiero** documentación completa del motor Replenishment
**Para** entender algoritmos, configuración y API

**Criterios de aceptación**:
- [ ] docs/V4.0/Purchasing/03_REPLENISHMENT.md creado
- [ ] Documenta 3 algoritmos (Min-Max, SMA, POS Consumption)
- [ ] Documenta configuración por ítem
- [ ] Documenta API de sugerencias
- [ ] Ejemplos de uso completos

**Archivos afectados**:
- docs/V4.0/Purchasing/03_REPLENISHMENT.md

**Dependencias**: HU-2.1, HU-2.2, HU-2.3
**Bloqueantes**: No bloquea otras tareas

---

## 7. SPRINT 4: CÓDIGO HUÉRFANO PRIORITARIO (40h)

### US-4.1: Eliminar Modelos Huérfanos Críticos
**Prioridad**: 🟡 P1
**Esfuerzo**: 12 horas
**Agente**: CODEX + CLAUDE
**Módulos**: Todos

**Como** desarrollador
**Quiero** eliminar modelos huérfanos identificados
**Para** reducir código no utilizado

**Criterios de aceptación**:
- [ ] 30 modelos huérfanos identificados
- [ ] Verificar que no estén referenciados
- [ ] Eliminar modelos no utilizados
- [ ] Documentar modelos mantenidos

**Archivos afectados**:
- app/Models/PosMap.php (verificar uso, documentar)
- app/Models/RecipeCostSnapshot.php (verificar uso, documentar)
- [... 28 más]

**Dependencias**: Ninguna
**Bloqueantes**: No bloquea otras tareas

---

### US-4.2: Crear Modelos Eloquent para 82 Tablas
**Prioridad**: 🟡 P1
**Esfuerzo**: 16 horas
**Agente**: CODEX + COPILOT
**Módulos**: Base de Datos

**Como** desarrollador
**Quiero** modelos Eloquent para tablas sin modelo
**Para** acceder a datos de forma ORM

**Criterios de aceptación**:
- [ ] 82 tablas sin modelo identificadas
- [ ] Priorizar 20 tablas más utilizadas
- [ ] Crear modelos con relaciones básicas
- [ ] Documentar en docs/V4.0/BaseDatos/

**Archivos afectados**:
- app/Models/Inventory/InventoryLog.php
- app/Models/Pos/PosSync Log.php
- [... 18 más]

**Dependencias**: Ninguna
**Bloqueantes**: No bloquea otras tareas

---

### US-4.3: Documentar 10 Vistas BD Analíticas
**Prioridad**: 🟡 P1
**Esfuerzo**: 12 horas
**Agente**: CLAUDE + CODEX
**Módulos**: Reportes, Base de Datos

**Como** desarrollador
**Quiero** documentación de vistas BD analíticas
**Para** entender datos y consultas disponibles

**Criterios de aceptación**:
- [ ] 10 vistas sin doc identificadas
- [ ] Documentar propósito, columnas, joins
- [ ] Ejemplos de consultas
- [ ] Rendimiento esperado

**Archivos afectados**:
- docs/V4.0/BaseDatos/Vistas/vw_dashboard_ventas.md
- docs/V4.0/BaseDatos/Vistas/vw_sesion_dpr.md
- [... 8 más]

**Dependencias**: US-2.4
**Bloqueantes**: No bloquea otras tareas

---

## 8. SPRINT 5: FUNCIONALIDAD RECETAS + TRANSFERENCIAS (48h)

### HU-5.1: Recetas Versionado - UI Completa
**Prioridad**: 🟡 P1
**Esfuerzo**: 14 horas
**Agente**: CLAUDE + COPILOT
**Módulos**: Recetas

**Como** usuario de recetas
**Quiero** gestionar versiones de recetas desde la UI
**Para** mantener historial de cambios y comparar versiones

**Criterios de aceptación**:
- [ ] UI lista versiones de receta
- [ ] UI crea nueva versión (copia de actual)
- [ ] UI compara 2 versiones lado a lado
- [ ] UI activa/desactiva versiones
- [ ] UI muestra versión activa actual

**Archivos afectados**:
- app/Livewire/Recipes/RecipeVersions.php
- resources/views/livewire/recipes/recipe-versions.blade.php
- app/Services/Recipes/RecipeVersionService.php

**Dependencias**: US-3.1, US-1.4
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- fn_recipe_cost_at() debe estar funcional en producción
- Validar versionado con recetas existentes

---

### HU-5.2: Transferencias - UI Despacho
**Prioridad**: 🟡 P1
**Esfuerzo**: 10 horas
**Agente**: CLAUDE + QWEN
**Módulos**: Transferencias

**Como** usuario de almacén origen
**Quiero** despachar transferencias desde la UI
**Para** confirmar salida de inventario

**Criterios de aceptación**:
- [ ] UI lista transferencias SOLICITADAS
- [ ] UI permite marcar como DESPACHADA
- [ ] Captura fecha/hora despacho
- [ ] Afecta kardex origen
- [ ] Notifica a almacén destino

**Archivos afectados**:
- app/Livewire/Transfers/Dispatch.php
- resources/views/livewire/transfers/dispatch.blade.php
- app/Services/Inventory/TransferService.php

**Dependencias**: US-3.5
**Bloqueantes**: Bloquea HU-5.3

---

### HU-5.3: Transferencias - UI Recepción
**Prioridad**: 🟡 P1
**Esfuerzo**: 12 horas
**Agente**: CLAUDE + QWEN
**Módulos**: Transferencias

**Como** usuario de almacén destino
**Quiero** recibir transferencias desde la UI
**Para** confirmar ingreso de inventario

**Criterios de aceptación**:
- [ ] UI lista transferencias DESPACHADAS
- [ ] UI permite marcar como RECIBIDA
- [ ] Captura cantidad recibida (puede diferir)
- [ ] Afecta kardex destino
- [ ] Si difiere cantidad, alerta gerencial

**Archivos afectados**:
- app/Livewire/Transfers/Receive.php
- resources/views/livewire/transfers/receive.blade.php
- app/Services/Inventory/TransferService.php

**Dependencias**: HU-5.2
**Bloqueantes**: No bloquea otras tareas

---

### HU-5.4: Inventario Recepciones - Vinculación PO
**Prioridad**: 🟡 P1
**Esfuerzo**: 12 horas
**Agente**: QWEN + COPILOT
**Módulos**: Inventario, Purchasing

**Como** usuario de inventario
**Quiero** vincular recepciones a órdenes de compra
**Para** rastrear cumplimiento de proveedores

**Criterios de aceptación**:
- [ ] UI selecciona PO al crear recepción
- [ ] Pre-llena ítems desde PO
- [ ] Compara cantidad recibida vs ordenada
- [ ] Actualiza estado PO (parcial/completo)
- [ ] Permite recepciones parciales

**Archivos afectados**:
- app/Livewire/Inventory/ReceptionCreate.php
- app/Services/Inventory/ReceptionService.php
- database/migrations/add_reception_po_link.php

**Dependencias**: HU-1.1
**Bloqueantes**: No bloquea otras tareas

---

## 9. SPRINT 6: REPORTES + INVENTARIO AVANZADO (42h)

### HU-6.1: Reportes - KPIs Analíticos Avanzados
**Prioridad**: 🟡 P1
**Esfuerzo**: 14 horas
**Agente**: CLAUDE + COPILOT
**Módulos**: Reportes

**Como** gerente
**Quiero** KPIs analíticos avanzados
**Para** tomar decisiones estratégicas

**Criterios de aceptación**:
- [ ] Dashboard con 5 KPIs nuevos
- [ ] Tendencias históricas (gráficos)
- [ ] Comparación entre sucursales
- [ ] Drill-down a detalle
- [ ] Exportación PDF/XLSX

**Archivos afectados**:
- app/Livewire/Reports/AnalyticsDashboard.php
- resources/views/livewire/reports/analytics-dashboard.blade.php

**Dependencias**: US-4.3
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- Validar vistas analíticas en producción
- Verificar rendimiento con datos históricos

---

### HU-6.2: Inventario Conteos - Vista Teórica
**Prioridad**: 🟡 P1
**Esfuerzo**: 8 horas
**Agente**: COPILOT + QWEN
**Módulos**: Inventario

**Como** usuario de inventario
**Quiero** ver stock teórico al hacer conteo
**Para** comparar con stock físico

**Criterios de aceptación**:
- [ ] Vista vw_stock_teorico_por_almacen creada
- [ ] UI conteo muestra stock teórico vs físico
- [ ] Cálculo de varianza automático
- [ ] Alertas si varianza > umbral

**Archivos afectados**:
- database/migrations/create_vw_stock_teorico.php
- app/Livewire/Inventory/CountDetail.php

**Dependencias**: US-3.5
**Bloqueantes**: No bloquea otras tareas

---

### HU-6.3: Inventario Mermas - UI Ajustes Rápidos
**Prioridad**: 🟡 P1
**Esfuerzo**: 10 horas
**Agente**: COPILOT + CLAUDE
**Módulos**: Inventario

**Como** usuario de inventario
**Quiero** registrar ajustes rápidos de inventario
**Para** corregir diferencias menores

**Criterios de aceptación**:
- [ ] UI rápida para ajustes (modal)
- [ ] Búsqueda de ítem por código/nombre
- [ ] Captura motivo de ajuste
- [ ] Afecta kardex inmediatamente
- [ ] Requiere aprobación si > umbral

**Archivos afectados**:
- app/Livewire/Inventory/QuickAdjustment.php
- resources/views/livewire/inventory/quick-adjustment.blade.php

**Dependencias**: HU-6.4
**Bloqueantes**: No bloquea otras tareas

---

### HU-6.4: Inventario Mermas - Catálogo Motivos
**Prioridad**: 🟡 P1
**Esfuerzo**: 6 horas
**Agente**: QWEN + COPILOT
**Módulos**: Inventario, Catálogos

**Como** usuario de inventario
**Quiero** catálogo de motivos de ajuste
**Para** clasificar y analizar mermas

**Criterios de aceptación**:
- [ ] Tabla cat_adjustment_reasons
- [ ] CRUD en UI catálogos
- [ ] Motivos predefinidos (robo, vencimiento, rotura, etc.)
- [ ] Análisis de mermas por motivo

**Archivos afectados**:
- database/migrations/create_adjustment_reasons.php
- app/Models/Inventory/AdjustmentReason.php
- app/Livewire/Catalogs/AdjustmentReasons.php

**Dependencias**: Ninguna
**Bloqueantes**: Bloquea HU-6.3

---

### HU-6.5: Inventario - Políticas Stock Conectadas a Motor
**Prioridad**: 🟡 P1
**Esfuerzo**: 4 horas
**Agente**: COPILOT + CODEX
**Módulos**: Inventario, Purchasing

**Como** usuario de inventario
**Quiero** que políticas de stock alimenten motor replenishment
**Para** mantener niveles óptimos automáticamente

**Criterios de aceptación**:
- [ ] UI políticas stock conectada a ReplenishmentService
- [ ] Cambios en políticas recalculan sugerencias
- [ ] Dashboard muestra ítems bajo mínimo

**Archivos afectados**:
- app/Services/Purchasing/ReplenishmentService.php
- app/Livewire/Catalogs/StockPolicies.php

**Dependencias**: HU-2.1
**Bloqueantes**: No bloquea otras tareas

---

## 10. SPRINT 7: SEGURIDAD + FRONTEND DESIGN SYSTEM (37h)

### HU-7.1: Seguridad - GUI Gestión Roles
**Prioridad**: 🟡 P1
**Esfuerzo**: 10 horas
**Agente**: CLAUDE + QWEN
**Módulos**: Seguridad

**Como** administrador
**Quiero** gestionar roles desde la UI
**Para** crear y editar roles sin tocar BD

**Criterios de aceptación**:
- [ ] UI CRUD roles (nombre, descripción)
- [ ] UI asigna permisos a rol (checkboxes agrupados)
- [ ] UI muestra usuarios con rol
- [ ] Validación: no eliminar roles con usuarios asignados

**Archivos afectados**:
- app/Livewire/Security/RolesIndex.php
- app/Livewire/Security/RoleDetail.php
- resources/views/livewire/security/roles-index.blade.php

**Dependencias**: Ninguna
**Bloqueantes**: No bloquea otras tareas

**Consideraciones de Deployment**:
- Validar permisos en producción
- Verificar que las reglas de Spatie funcionen

---

### HU-7.2: Seguridad - GUI Gestión Permisos
**Prioridad**: 🟡 P1
**Esfuerzo**: 8 horas
**Agente**: QWEN + COPILOT
**Módulos**: Seguridad

**Como** administrador
**Quiero** gestionar permisos desde la UI
**Para** crear y editar permisos sin tocar BD

**Criterios de aceptación**:
- [ ] UI CRUD permisos (nombre, módulo, tipo)
- [ ] UI agrupa permisos por módulo
- [ ] UI muestra roles con permiso
- [ ] Validación: no eliminar permisos asignados

**Archivos afectados**:
- app/Livewire/Security/PermissionsIndex.php
- app/Livewire/Security/PermissionDetail.php

**Dependencias**: HU-7.1
**Bloqueantes**: No bloquea otras tareas

---

### HU-7.3: Seguridad - Auditoría UI Mejorada
**Prioridad**: 🟡 P1
**Esfuerzo**: 7 horas
**Agente**: CLAUDE + COPILOT
**Módulos**: Seguridad

**Como** auditor
**Quiero** UI de auditoría mejorada
**Para** rastrear cambios en el sistema

**Criterios de aceptación**:
- [ ] UI dashboard auditoría (últimos 100 eventos)
- [ ] Filtros por usuario, módulo, fecha, tipo
- [ ] Detalle de evento (antes/después)
- [ ] Exportación a CSV

**Archivos afectados**:
- app/Livewire/Security/AuditLog.php
- resources/views/livewire/security/audit-log.blade.php

**Dependencias**: Ninguna
**Bloqueantes**: No bloquea otras tareas

---

### HU-7.4: Frontend - Design System Documentado
**Prioridad**: 🟡 P1
**Esfuerzo**: 12 horas
**Agente**: CODEX + CLAUDE
**Módulos**: Frontend

**Como** desarrollador
**Quiero** Design System documentado
**Para** crear interfaces consistentes

**Criterios de aceptación**:
- [ ] docs/V4.0/Frontend/DesignSystem.md creado
- [ ] Documenta componentes Bootstrap 5
- [ ] Documenta patrones Livewire (forms, modales, tablas)
- [ ] Documenta paleta de colores, tipografía
- [ ] Ejemplos de uso para cada patrón

**Archivos afectados**:
- docs/V4.0/Frontend/DesignSystem.md

**Dependencias**: US-1.1, US-1.2, US-1.3
**Bloqueantes**: No bloquea otras tareas

---

## 11. SPRINT 8: TESTS + PULIDO + DEPLOYMENT (25h)

### HU-8.1: Tests de Integración Críticos
**Prioridad**: 🔴 P0
**Esfuerzo**: 12 horas
**Agente**: COPILOT + CODEX
**Módulos**: Todos

**Como** desarrollador
**Quiero** tests de integración para flujos críticos
**Para** asegurar calidad antes de deployment

**Criterios de aceptación**:
- [ ] Test flujo recepción BORRADOR → VALIDADA → POSTEADA
- [ ] Test flujo transferencia SOLICITADA → DESPACHADA → RECIBIDA
- [ ] Test motor replenishment cálculo Min-Max
- [ ] Test consolidación PosConsumptionService
- [ ] Test versionado recetas

**Archivos afectados**:
- tests/Feature/Inventory/ReceptionWorkflowTest.php
- tests/Feature/Inventory/TransferWorkflowTest.php
- tests/Feature/Purchasing/ReplenishmentTest.php
- tests/Feature/Recipes/RecipeVersioningTest.php
- tests/Feature/Pos/PosConsumptionTest.php

**Dependencias**: Todos los HU previos
**Bloqueantes**: Bloquea HU-8.2

---

### HU-8.2: Validación Deployment Completo
**Prioridad**: 🔴 P0
**Esfuerzo**: 8 horas
**Agente**: CLAUDE + CODEX
**Módulos**: Todos

**Como** DevOps
**Quiero** validar deployment completo en producción
**Para** asegurar que todo funcione correctamente

**Criterios de aceptación**:
- [ ] Checklist de deployment ejecutado
- [ ] Tests pasando en producción
- [ ] Validación manual de 15 módulos
- [ ] Validación de funciones BD críticas
- [ ] Validación de vistas analíticas
- [ ] Validación de permisos y roles

**Archivos afectados**:
- docs/V4.0/Guia/Deployment.md (actualizar)
- docs/V4.0/Guia/Checklist_Deployment_V4.md (crear)

**Dependencias**: HU-8.1
**Bloqueantes**: No bloquea otras tareas

---

### HU-8.3: Documentación Final Deployment
**Prioridad**: 🟡 P1
**Esfuerzo**: 5 horas
**Agente**: CLAUDE + CODEX
**Módulos**: Todos

**Como** desarrollador
**Quiero** documentación final de deployment
**Para** tener referencia de proceso completo

**Criterios de aceptación**:
- [ ] docs/V4.0/Guia/Deployment.md actualizado
- [ ] Documenta proceso completo
- [ ] Incluye troubleshooting común
- [ ] Incluye rollback procedures
- [ ] Incluye validación post-deployment

**Archivos afectados**:
- docs/V4.0/Guia/Deployment.md
- docs/V4.0/Guia/Troubleshooting.md (crear)

**Dependencias**: HU-8.2
**Bloqueantes**: No bloquea otras tareas

---

## 12. RESUMEN FINAL

### Total por Módulo

| Módulo | Horas | % Total | User Stories |
|--------|-------|---------|--------------|
| Frontend | 42h | 12.4% | US-1.1, US-1.2, US-1.3, HU-7.4 |
| Purchasing | 51h | 15.0% | HU-2.1, HU-2.2, HU-2.3, US-3.6, HU-6.5 |
| Inventario | 63h | 18.5% | HU-1.1, HU-1.2, HU-1.3, US-3.5, HU-5.4, HU-6.2, HU-6.3, HU-6.4 |
| Base de Datos | 32h | 9.4% | US-2.4, US-4.3 |
| Recetas | 25h | 7.4% | US-3.1, US-3.2, HU-5.1 |
| POS | 11h | 3.2% | US-1.4, US-3.4 |
| Producción | 11h | 3.2% | US-1.5, US-3.3 |
| Transferencias | 22h | 6.5% | HU-5.2, HU-5.3 |
| Reportes | 14h | 4.1% | US-4.3, HU-6.1 |
| Seguridad | 25h | 7.4% | HU-7.1, HU-7.2, HU-7.3 |
| Código Huérfano | 28h | 8.2% | US-4.1, US-4.2 |
| Tests + Deployment | 25h | 7.4% | HU-8.1, HU-8.2, HU-8.3 |
| **TOTAL** | **340h** | **100%** | **47 User Stories** |

### Hitos Clave

| Hito | Sprint | Entregables |
|------|--------|-------------|
| **UX Crítico Resuelto** | S1 | Forms loading, notificaciones, confirmaciones, servicios consolidados |
| **Motor Replenishment Operativo** | S2 | Algoritmos, dashboard, API completos |
| **Documentación Core Completa** | S3 | 6 docs V4.0 de módulos críticos |
| **Código Limpio** | S4 | Huérfanos eliminados, modelos creados, vistas documentadas |
| **Funcionalidad Recetas + Transferencias** | S5 | Versionado UI, transferencias flujo completo |
| **Inventario Avanzado + Reportes** | S6 | Ajustes rápidos, KPIs analíticos, políticas conectadas |
| **Seguridad + Design System** | S7 | GUI permisos, design system documentado |
| **Deployment Ready** | S8 | Tests, validación, documentación final |

---

## 13. CONSIDERACIONES FINALES DE DEPLOYMENT

### Pre-Deployment Checklist (Ejecutar antes de cada sprint)

- [ ] Tests ejecutados: `php artisan test`
- [ ] Código limpio: `./vendor/bin/pint`
- [ ] Migraciones probadas: `php artisan migrate:status`
- [ ] Assets compilados: `npm run build`
- [ ] Cache limpiado: `php artisan *:clear`

### Post-Deployment Checklist (Ejecutar después de cada sprint)

- [ ] Composer install: `sudo -u www-data composer install --no-dev`
- [ ] Migraciones: `sudo -u www-data php artisan migrate --force`
- [ ] Cache: `sudo -u www-data php artisan config:cache`
- [ ] Permisos storage: `sudo chown -R www-data:www-data storage/`

### URLs de Validación

- Local: http://localhost/TerrenaLaravel
- Producción (red local): http://192.168.1.235/terrena2/
- Producción (VPN): http://100.126.124.101/terrena2/

### Funciones BD Críticas a Validar en Producción

1. fn_recipe_cost_at() - Costeo de recetas
2. fn_expandir_consumo_ticket() - Expansión de consumos POS
3. fn_confirmar_consumo() - Confirmación de consumos
4. fn_reversar_consumo() - Reversión de consumos
5. fn_consolidar_stock() - Consolidación de stock
6. fn_precorte_after_insert() - Trigger precorte
7. fn_postcorte_after_insert() - Trigger postcorte
8. [... 5 más documentadas en Sprint 2]

---

**FIN BACKLOG DE SPRINTS V4.0 - MAESTRO**
