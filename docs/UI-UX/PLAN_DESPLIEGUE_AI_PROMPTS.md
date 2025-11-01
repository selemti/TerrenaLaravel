# Plan de Despliegue Paralelo y Paquete de Prompts IA

## 1. Resumen Ejecutivo
- **Objetivo**: Operativizar el roadmap UI/UX enterprise asegurando squads paralelos con entradas de IA consistentes.
- **Pilares**: (a) Design System y cimientos UX de la Fase 2, (b) verticalización de módulos core (Inventario, Compras/Replenishment, Recetas/Costos, Producción, Reportes/Permisos), (c) gobernanza de prompts para IA que reduzca tokens y retrabajos.
- **Fuentes Base**: `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md`, `docs/UI-UX/STATUS_MAESTRO_TERRENA.md`, y fichas `docs/UI-UX/Status/*.md`.

## 2. Estructura de Trabajo Paralelo
| Squad | Alcance | Dependencias Clave | Hitos Iniciales |
|-------|---------|---------------------|-----------------|
| **Foundation** | Componentes Blade, validación unificada, notificaciones (Fase 2.1-2.3). | Ninguna, pero desbloquea al resto. | Catálogo de `<x-*>` publicado + guía de uso.
| **Inventario & Catálogos** | Wizard de altas, FEFO avanzado, mobile counts, políticas de stock. | Foundation (componentes), Compras (políticas). | Alta guiada 2 pasos y validaciones inline.
| **Compras/Replenishment** | Motor sugerencias, dashboard, políticas stock. | Inventario (datos actualizados), Foundation. | Motor de sugerencias mínimo viable.
| **Recetas/Costos** | Versionado, snapshots, alertas costo. | Inventario (costos), Foundation. | Modelo `RecipeVersion` + UI de histórico.
| **Producción (Produmix)** | UI operativa completa, tableros de ejecución. | Recetas (implosión), Inventario (consumos). | Flujo Planificar → Ejecutar → Consumir en UI.
| **Reportes & Permisos** | Exports, drill-down, auditoría, matriz visual de roles. | Foundation, módulos fuente de datos. | Export PDF/CSV base + matriz interactiva.
| **QA & Release** | Coordinación de testing transversal, regression packs, checklists de despliegue. | Todos. | Playbook de QA basado en KPI.

## 3. Roadmap Integrado
1. **Semana 0 (Preparación)**
   - Foundation arma librería `<x-*>` y lineamientos de validación/notificaciones.
   - QA define estándares de pruebas y checklists por módulo.
2. **Semana 1-2 (Fase 2 completa)**
   - Foundation entrega design system y migración de componentes críticos.
   - Inventario adapta wizard de altas y conteos con nuevos componentes.
3. **Semana 3-4 (Fase 3 + arranque Fase 4)**
   - Inventario completa mobile counts y FEFO.
   - Compras arranca motor de sugerencias apoyado en snapshots inventario.
   - Recetas modela versionado y comienza UI de historial.
4. **Semana 5-6 (Fases 4-5)**
   - Producción publica tablero operativo.
   - Reportes implementa exports y drill-down inicial.
   - Permisos integra matriz visual y auditoría de cambios.
5. **Semana 7 (Cierre)**
   - QA ejecuta regression suites, smoke conjunto y valida KPIs.
   - Documentación final y handover.

## 4. Ritual de Documentación
- Cada squad actualiza un changelog diario en `docs/UI-UX/Status/STATUS_<Modulo>.md` usando secciones **Hecho / En Curso / Bloqueos / Próximo**.
- Registrar decisiones de arquitectura o UX en la carpeta `docs/UI-UX/Definiciones/` con formato RFC (Contexto, Decisión, Impacto).
- QA consolida resultados de pruebas en `docs/UI-UX/QA/` (crear carpeta si no existe) con evidencias y matrices de traceabilidad.

## 5. Prompt Pack Optimizado
### 5.1 Template Base (para cualquier squad)
```
Contexto:
- Proyecto: TerrenaLaravel ERP restaurantes (Laravel 10, Blade, Livewire, Tailwind).
- Documentos base: {lista de archivos relevantes con rutas}.
- Objetivo puntual: {definir en <=20 palabras}.

Instrucciones:
1. Lee solo los documentos listados y resume requisitos en bullets.
2. Propón entregables concretos (código, pruebas, docs) alineados a Definition of Done del módulo.
3. Lista dependencias externas o datos que falten.
4. Devuelve plan de trabajo en máximo 200 palabras.
```
**Uso**: Reemplaza `{lista...}` con rutas exactas y `{definir...}` con verbo + resultado. Limita palabras para ahorrar tokens.

### 5.2 Foundation Squad
```
Contexto Documental:
- docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md (Fase 2)
- docs/UI-UX/STATUS_MAESTRO_TERRENA.md (Fase 2 entregables)
- resources/views/components (catálogo actual)

Objetivo puntual: Definir backlog sprint para completar design system Blade.
```
**Salida esperada**: componentes priorizados, criterios de adopción, pruebas mínimas.

### 5.3 Inventario & Catálogos
```
Contexto Documental:
- docs/UI-UX/Status/STATUS_Inventario.md
- docs/UI-UX/definición/Inventario.md (flows FEFO y conteos)
- docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md (Fase 3)

Objetivo puntual: Diseñar iteración que entregue wizard 2 pasos y validación inline.
```
**Nota**: Solicitar checklist de validaciones obligatorias y mock de mobile counts.

### 5.4 Compras/Replenishment
```
Contexto Documental:
- docs/UI-UX/Status/STATUS_Compras.md
- docs/UI-UX/Replenishment/*.md (motor y políticas)
- docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md (Fase 4)

Objetivo puntual: Planear implementación del motor de pedidos sugeridos con KPIs.
```
**Pedir** dependencias de datos (snapshots inventario) y pruebas necesarias.

### 5.5 Recetas/Costos
```
Contexto Documental:
- docs/UI-UX/Status/STATUS_Recetas.md
- docs/UI-UX/Recetas/*.md (versionado, costos)
- docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md (Gaps críticos)

Objetivo puntual: Definir backlog para versionado y snapshots automáticos.
```
**Incluir** criterios de aceptación para alertas de costo.

### 5.6 Producción (Produmix)
```
Contexto Documental:
- docs/UI-UX/Status/STATUS_Produccion.md
- docs/UI-UX/Produccion/*.md (flujos completos)
- docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md (Fase 5)

Objetivo puntual: Mapear UI Planificar → Ejecutar → Consumir con métricas.
```
**Solicitar** integración con recetas y POS.

### 5.7 Reportes & Permisos
```
Contexto Documental:
- docs/UI-UX/Status/STATUS_Reportes.md
- docs/UI-UX/Status/STATUS_Permisos.md
- docs/UI-UX/REPORTING_AND_KPIS.md
- docs/UI-UX/SECURITY_AND_ROLES.md

Objetivo puntual: Diseñar entregable conjunto exports + matriz visual de roles.
```
**Pedir** reglas de auditoría y coverage de KPIs.

### 5.8 QA & Release
```
Contexto Documental:
- docs/UI-UX/STATUS_MAESTRO_TERRENA.md (fases y hitos)
- docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md (Plan de testing)

Objetivo puntual: Generar playbook de QA y checklist de despliegue sin downtime.
```
**Forzar** salida con matrices de pruebas y definición de smoke/regresión.

## 6. Gobernanza y Métricas
- **Cadencia**: Dailies de squads (15 min) + weekly steering con leads.
- **KPIs**: % adopción design system, # gaps cerrados por módulo, tiempo ciclo QA.
- **Riesgos**: Dependencia de snapshots (Inventario → Compras → Recetas → Producción), saturación de Livewire sin refactor foundation.
- **Mitigación**: Lanzamientos progresivos, feature toggles por módulo, tablero de dependencias compartido.

## 7. Próximos Pasos
1. Validar plan con leads técnicos y UX (reunión kickoff).
2. Ajustar prompts según feedback y publicar en `docs/UI-UX/PLAN_DESPLIEGUE_AI_PROMPTS.md` (este documento).
3. Iniciar ejecución en la rama `feature/plan-despliegue-uiux` con control de cambios y actualizaciones diarias.
