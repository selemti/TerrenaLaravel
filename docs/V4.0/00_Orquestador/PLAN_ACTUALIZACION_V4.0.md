# PLAN DE ACTUALIZACIÓN V4.0 - ORQUESTADOR CLAUDE
**Fecha**: 14 Noviembre 2025
**Versión**: 1.0
**Basado en**: Auditoría FASE1-FASE6 + Análisis multi-agente (CLAUDE, QWEN, CODEX, COPILOT)

---

## 1. CONTEXTO Y OBJETIVO

### 1.1 Situación Actual
- **V4.0 actual**: 20 documentos markdown que cubren 11/15 módulos (73%)
- **Score documental**: 76% → Objetivo: 94%
- **Fuentes dispersas**: 729 archivos en múltiples ubicaciones (/docs, D:\Tavo\2025\UX\, legacy)
- **Documentación de agentes**: 4 orquestadores en docs/00.history/orquestadores/ (CLAUDE, QWEN, CODEX, COPILOT)

### 1.2 Objetivo del Plan
Consolidar **docs/V4.0/** como **fuente única de verdad** para el sistema Terrena POS/ERP mediante:
1. Identificación de documentos faltantes, duplicados y obsoletos
2. Migración de contenido valioso desde fuentes legacy y agentes
3. Creación de estructura documental completa (44 documentos objetivo)
4. Estandarización de formato y contenido según patrón del Compendio Supremo CLAUDE

### 1.3 Principios Rectores
- ✅ **NO modificar** archivos fuera de docs/V4.0/
- ✅ **NO sobrescribir** archivos de otros agentes (00.history/orquestadores/)
- ✅ **NO escribir** en docs/00.history/ (solo lectura)
- ✅ **V4.0 es la única fuente de verdad** para desarrollo
- ✅ **Reconocer colaboradores**: QWEN, CODEX, COPILOT como agentes colaboradores

---

## 2. INVENTARIO ACTUAL V4.0

### 2.1 Documentos Existentes (20)

| # | Archivo | Módulo | Estado | Score | Acción |
|---|---------|--------|--------|-------|--------|
| 1 | 00_Orquestador/00_CONTRATO_SISTEMA_TERRENA_v3.md | Orquestador | ✅ Existe | 90% | **ACTUALIZAR** con hallazgos FASE1-6 |
| 2 | Arquitectura/README.md | Arquitectura | ✅ Existe | 85% | **ACTUALIZAR** con stack confirmado |
| 3 | Caja/HistoricoCortes.md | Caja | ✅ Existe | 95% | Mantener |
| 4 | Caja/REDIRECCION_DETALLE_A_WIZARD.md | Caja | ✅ Existe | 90% | Mantener |
| 5 | Finanzas/README.md | Finanzas | ✅ Existe | 70% | **AMPLIAR** con DailyCloseService |
| 6 | Frontend/Componentes.md | Frontend | ✅ Existe | 80% | **ACTUALIZAR** con gaps UX FASE6 |
| 7 | Frontend/Layout.md | Frontend | ✅ Existe | 85% | **ACTUALIZAR** con patrones Bootstrap 5 |
| 8 | Guia/Stack.md | Guía | ✅ Existe | 90% | **ACTUALIZAR** con versiones confirmadas |
| 9 | Inventario/Conteos.md | Inventario | ✅ Existe | 90% | Mantener |
| 10 | Inventario/Disponibilidad.md | Inventario | ✅ Existe | 85% | **ACTUALIZAR** con vw_kardex |
| 11 | Inventario/Items.md | Inventario | ✅ Existe | 95% | Mantener |
| 12 | Inventario/Mermas.md | Inventario | ✅ Existe | 60% | **AMPLIAR** con InventoryWaste |
| 13 | Inventario/Recepciones.md | Inventario | ✅ Existe | 90% | **ACTUALIZAR** con estados BORRADOR→VALIDADA→POSTEADA |
| 14 | Inventario/Transferencias.md | Inventario | ✅ Existe | 75% | **AMPLIAR** con TransferService completo |
| 15 | POS/README.md | POS | ✅ Existe | 60% | **AMPLIAR** con PosConsumptionService |
| 16 | Produccion/README.md | Producción | ✅ Existe | 55% | **AMPLIAR** con ProductionService y UI |
| 17 | Purchasing/README.md | Purchasing | ✅ Existe | 85% | **ACTUALIZAR** con motor Replenishment |
| 18 | README.md | Índice | ✅ Existe | 80% | **ACTUALIZAR** con estructura completa |
| 19 | Recetas/README.md | Recetas | ✅ Existe | 70% | **AMPLIAR** con versionado y costeo |
| 20 | Reports/README.md | Reportes | ✅ Existe | 88% | Mantener |

### 2.2 Módulos Sin Documentar (4)

| Módulo | Prioridad | Estado | Acción |
|--------|-----------|--------|--------|
| **Catálogos** | 🟡 ALTA | Sin doc V4.0 | **CREAR** Catalogos/README.md |
| **Seguridad** | 🟡 ALTA | Sin doc V4.0 | **CREAR** Seguridad/README.md |
| **Base de Datos** | 🟡 ALTA | Sin doc V4.0 | **CREAR** BaseDatos/README.md |
| **Transferencias** | 🟢 MEDIA | Parcial en Inventario | **SEPARAR** de Inventario/Transferencias.md |

---

## 3. DOCUMENTOS FALTANTES (24 NUEVOS)

### 3.1 Críticos (9 documentos - Prioridad P0)

| # | Archivo | Módulo | Contenido | Fuente |
|---|---------|--------|-----------|--------|
| 1 | **00_Orquestador/MATRIZ_ALINEACION_V4.0.md** | Orquestador | Matriz consolidada 15 módulos (fusión 4 agentes) | CLAUDE, QWEN, CODEX, COPILOT |
| 2 | **00_Orquestador/BACKLOG_SPRINTS_V4.0.md** | Orquestador | Backlog unificado 8 sprints (289h) | CLAUDE + validación agentes |
| 3 | **00_Orquestador/COMPENDIO_TECNICO.md** | Orquestador | Compendio técnico fusionado | Fusión 4 compendios supremos |
| 4 | **BaseDatos/README.md** | Base Datos | Esquema selemti (147 tablas, 38 vistas, 37 funciones) | FASE5 + COPILOT BD extraction |
| 5 | **BaseDatos/Funciones.md** | Base Datos | 12 funciones críticas sin doc | FASE5 + análisis código |
| 6 | **BaseDatos/Vistas.md** | Base Datos | 38 vistas BD (vw_sesion_dpr, vw_dashboard_*) | FASE5 + Reports |
| 7 | **Catalogos/README.md** | Catálogos | UOM, Almacenes, Proveedores, Sucursales | Livewire/Catalogs/ |
| 8 | **Seguridad/README.md** | Seguridad | Spatie Permissions, Roles, Policies | app/Policies/ + config/ |
| 9 | **Frontend/GapsUX_Criticos.md** | Frontend | 3 gaps críticos FASE6 (loading, toasts, confirmaciones) | FASE6 completo |

### 3.2 Altos (8 documentos - Prioridad P1)

| # | Archivo | Módulo | Contenido | Fuente |
|---|---------|--------|-----------|--------|
| 10 | **Inventario/Ajustes.md** | Inventario | Ajustes de inventario (mov_inv tipo AJUSTE) | InventoryAdjustmentService |
| 11 | **Inventario/Kardex.md** | Inventario | mov_inv, vw_kardex, trazabilidad | Disponibilidad.md + FASE5 |
| 12 | **Recetas/Versionado.md** | Recetas | receta_version, RecetaVersion.php | COPILOT contrato + modelos |
| 13 | **Recetas/Costeo.md** | Recetas | RecipeCostingService, fn_recipe_cost_at() | Services/Costing/ + FASE5 |
| 14 | **Recetas/Mapeo_POS.md** | Recetas | pos_map, PosMap.php, recipes:sync-pos | POS/README.md + comandos |
| 15 | **Produccion/Ordenes.md** | Producción | production_orders, ProductionService | FASE4 + COPILOT |
| 16 | **Produccion/Mermas.md** | Producción | inventory_wastes, perdida_log | Inventario/Mermas.md migrado |
| 17 | **POS/Consumos.md** | POS | PosConsumptionService, inv_consumo_pos | Services/Pos/ + FASE4 |

### 3.3 Medios (7 documentos - Prioridad P2)

| # | Archivo | Módulo | Contenido | Fuente |
|---|---------|--------|-----------|--------|
| 18 | **Purchasing/Replenishment.md** | Purchasing | Motor sugerencias, inv_stock_policy | PurchasingService + COPILOT |
| 19 | **Purchasing/Recepciones_Compras.md** | Purchasing | ReceivingService vs ReceptionService | FASE4 duplicados |
| 20 | **Finanzas/CajaChica.md** | Finanzas | CashFund, 6 componentes Livewire | Livewire/CashFund/ |
| 21 | **Finanzas/Cortes.md** | Finanzas | Precorte/Postcorte, DailyCloseService | Api/Caja/ + triggers |
| 22 | **Reports/KPIs.md** | Reportes | 38 vistas, dashboards | vw_dashboard_* + Controllers |
| 23 | **Reports/Ventas.md** | Reportes | SalesDetailController, exports | Reports/ + FASE1 |
| 24 | **Arquitectura/Convenciones.md** | Arquitectura | PSR-12, Laravel Pint, naming | CLAUDE compendio Part VII |

---

## 4. DOCUMENTOS DUPLICADOS A CONSOLIDAR

### 4.1 Duplicados Detectados

| Documento Duplicado | Ubicación Original | Ubicación Duplicada | Acción |
|---------------------|-------------------|---------------------|--------|
| **Contrato Sistema** | 00.history/orquestadores/CLAUDE/00_CONTRATO_SISTEMA_CLAUDE_v2.md | V4.0/00_Orquestador/00_CONTRATO_SISTEMA_TERRENA_v3.md | **FUSIONAR** en v3.md |
| **Matriz Alineación** | 4 versiones (CLAUDE, QWEN, CODEX, COPILOT) | NO existe en V4.0 | **CREAR** consolidado en V4.0 |
| **Backlog Sprints** | 4 versiones (CLAUDE, QWEN, CODEX, COPILOT) | NO existe en V4.0 | **CREAR** consolidado en V4.0 |
| **Mermas** | Inventario/Mermas.md | Produccion/ (implícito) | **MANTENER** en Inventario, referenciar desde Producción |
| **Recepciones** | Inventario/Recepciones.md | Purchasing/ (implícito) | **MANTENER** en Inventario, referenciar desde Purchasing |

### 4.2 Estrategia de Consolidación

**Regla general**:
- Si existe en V4.0 → **ACTUALIZAR** V4.0 con insights de agentes
- Si NO existe en V4.0 → **CREAR** nuevo en V4.0 fusionando 4 perspectivas
- Si existe en múltiples agentes → **FUSIONAR** con tabla comparativa reconociendo autores

---

## 5. DOCUMENTOS LEGACY A MOVER

### 5.1 Documentos Obsoletos (NO migrar, solo archivar)

| Documento Legacy | Ubicación | Estado | Acción |
|------------------|-----------|--------|--------|
| docs/noviembre/* | /docs/noviembre/ | Obsoleto | **IGNORAR** (ya en 00.history/) |
| docs/BD/NoviembreDocs/* | /docs/BD/NoviembreDocs/ | Obsoleto | **IGNORAR** (ya en 00.history/) |
| docs/CajaChica/* (legacy) | /docs/CajaChica/ | Obsoleto | **IGNORAR** (V4.0/Finanzas/CajaChica.md nuevo) |
| conversationAntes.txt | V4.0/ | Temporal | **MOVER** a 00.history/temp/ |

### 5.2 Documentos a Referenciar (NO duplicar)

| Documento Reference | Ubicación | Uso | Acción |
|---------------------|-----------|-----|--------|
| **COMPENDIO_SUPREMO_CLAUDE.md** | 00.history/orquestadores/CLAUDE/ | Referencia técnica profunda | **REFERENCIAR** desde V4.0/README.md |
| **FASE1-FASE6** | 00.history/auditorias/AUDITORIA_2025_11_13/ | Evidencia auditoría | **REFERENCIAR** desde 00_Orquestador/CONTRATO |
| **Compendios otros agentes** | 00.history/orquestadores/{QWEN,CODEX,COPILOT}/ | Perspectivas complementarias | **REFERENCIAR** desde 00_Orquestador/COMPENDIO_TECNICO |

---

## 6. MIGRACIÓN DE CONTENIDO DESDE AGENTES

### 6.1 Contenido QWEN a Integrar

| Insight QWEN | Documento V4.0 Destino | Sección |
|--------------|------------------------|---------|
| Historia del proyecto (FASE1-6) | 00_Orquestador/CONTRATO_SISTEMA_TERRENA_v3.md | § 1.3 Historia |
| Módulos y conexiones | 00_Orquestador/COMPENDIO_TECNICO.md | § 2 Arquitectura Modular |
| Estado técnico actual | Arquitectura/README.md | § 3 Stack Confirmado |
| Lecciones aprendidas FASE1-6 | 00_Orquestador/COMPENDIO_TECNICO.md | § 10 Lecciones |

### 6.2 Contenido CODEX a Integrar

| Insight CODEX | Documento V4.0 Destino | Sección |
|---------------|------------------------|---------|
| Radiografía global (729 archivos) | 00_Orquestador/CONTRATO_SISTEMA_TERRENA_v3.md | § 3.1 Fuente de Verdad |
| Brechas técnicas (189 huérfanos) | 00_Orquestador/BACKLOG_SPRINTS_V4.0.md | Sprint 5-6 |
| Brechas UX (score 6.5/10) | Frontend/GapsUX_Criticos.md | § 1-3 Gaps |
| Principios operación (P1-P4) | 00_Orquestador/CONTRATO_SISTEMA_TERRENA_v3.md | § 5 Principios |
| Duplicaciones críticas | 00_Orquestador/BACKLOG_SPRINTS_V4.0.md | Sprint 1, 7 |

### 6.3 Contenido COPILOT a Integrar

| Insight COPILOT | Documento V4.0 Destino | Sección |
|-----------------|------------------------|---------|
| Stack tecnológico real | Arquitectura/README.md | § 2.1 Stack |
| Estructura proyecto confirmada | Arquitectura/README.md | § 2.2 Estructura |
| BD selemti (185 tablas) | BaseDatos/README.md | § 1 Inventario Completo |
| Funcionalidades confirmadas | 00_Orquestador/MATRIZ_ALINEACION_V4.0.md | Columna "Implementación" |
| Gaps críticos (motor replenishment) | Purchasing/Replenishment.md | § 1 Gap Crítico |
| Tablas con datos vs vacías | BaseDatos/README.md | § 2 Estado Actual |

---

## 7. DEFINICIONES A CONSOLIDAR

### 7.1 Definición Única "¿Qué es Terrena?"

**Versión Consolidada** (fusión 4 agentes):

> Terrena es un **ERP/POS integral para restaurantes multi-sucursal** que gestiona el ciclo operativo completo:
> - **Recepción de insumos** y control de inventario (kardex, lotes, transferencias)
> - **Costeo y producción de recetas** (versionado, BOM explosion/implosion)
> - **Registro de ventas POS** (integración Floreant, mapeo productos)
> - **Control financiero diario** (cortes de caja, precorte/postcorte, caja chica)
> - **Compras y replenishment** (solicitudes, órdenes, motor sugerencias)
> - **Reportes operativos** (KPIs, dashboards, exports)
>
> Proporciona una **plataforma unificada** para administración de recursos, control de costos en tiempo real y toma de decisiones basada en datos operativos consolidados.

**Ubicación**: V4.0/00_Orquestador/CONTRATO_SISTEMA_TERRENA_v3.md § 1 + README.md

### 7.2 Definición "¿Qué NO es Terrena?"

**Versión Consolidada**:

> Terrena NO es:
> - ❌ Un POS propio (integra con Floreant POS existente)
> - ❌ Sistema de contabilidad completa (solo operaciones de caja)
> - ❌ Sistema RRHH (solo usuarios y permisos operativos)
> - ❌ CRM o e-commerce
> - ❌ Sistema de reservaciones o delivery

**Ubicación**: V4.0/00_Orquestador/CONTRATO_SISTEMA_TERRENA_v3.md § 1.2

### 7.3 Usuarios Clave del Sistema

**Lista Consolidada** (7 roles confirmados):

| Rol | Módulos Principales | Permisos Clave |
|-----|---------------------|----------------|
| **Almacenista** | Inventario, Recepciones, Transferencias | inventory.*, receptions.*, transfers.* |
| **Comprador** | Purchasing, Proveedores | purchasing.*, vendors.* |
| **Chef / Producción** | Recetas, Producción, Mermas | recipes.*, production.*, wastes.* |
| **Cajero** | Caja, POS | cashfund.*, caja.precorte.* |
| **Gerente Sucursal** | Caja, Reportes, Inventario | caja.*, reports.view.*, inventory.view.* |
| **Controller** | Finanzas, Reportes, Aprobaciones | caja.postcorte.*, cashfund.approve.*, reports.* |
| **Administrador** | Todos, Seguridad | *.* (superadmin) |

**Ubicación**: V4.0/Seguridad/README.md § 2 + 00_Orquestador/CONTRATO § 7

---

## 8. MÓDULOS FALTANTES A DOCUMENTAR

### 8.1 Módulos No Documentados (5)

| # | Módulo | Prioridad | Implementación | Evidencia Código | Acción |
|---|--------|-----------|----------------|------------------|--------|
| 1 | **Catálogos** | 🟡 ALTA | 90% | Livewire/Catalogs/* (6 componentes) | **CREAR** Catalogos/README.md |
| 2 | **Seguridad** | 🟡 ALTA | 80% | Policies/, config/permissions.php | **CREAR** Seguridad/README.md |
| 3 | **Base de Datos** | 🟡 ALTA | 90% | Esquema selemti (FASE5) | **CREAR** BaseDatos/README.md |
| 4 | **Transferencias** | 🟡 ALTA | 75% | Parcial en Inventario/ | **SEPARAR** módulo independiente |
| 5 | **Mermas** | 🟢 MEDIA | 60% | Parcial en Inventario/Producción | **SEPARAR** o mantener referenciado |

### 8.2 Sub-módulos a Expandir (6)

| Módulo Padre | Sub-módulo | Estado Actual | Acción |
|--------------|------------|---------------|--------|
| Inventario | Ajustes | No documentado | **CREAR** Inventario/Ajustes.md |
| Inventario | Kardex | Implícito en Disponibilidad | **SEPARAR** Inventario/Kardex.md |
| Recetas | Versionado | Mencionado, no detallado | **CREAR** Recetas/Versionado.md |
| Recetas | Costeo | Mencionado, no detallado | **CREAR** Recetas/Costeo.md |
| Recetas | Mapeo POS | En POS/README | **MOVER** a Recetas/Mapeo_POS.md |
| Purchasing | Replenishment | Mencionado, no detallado | **CREAR** Purchasing/Replenishment.md |

---

## 9. CONTENIDO A IGNORAR (LEGACY)

### 9.1 Carpetas Legacy a NO Migrar

| Carpeta | Razón | Estado en 00.history |
|---------|-------|----------------------|
| docs/noviembre/* | Documentación temporal Nov 2025 | ✅ Ya archivada |
| docs/BD/NoviembreDocs/* | Docs BD temporales | ✅ Ya archivada |
| docs/BD/Olds/* | Reportes deploy antiguos | ✅ Ya archivada |
| docs/CajaChica/ (legacy) | V4.0/Finanzas/CajaChica.md lo reemplaza | ✅ Ya archivada |
| docs/Migraciones/ (legacy) | Histórico, no necesario en V4.0 | ⚠️ Mantener para referencia |
| docs/Planeacion/ (legacy) | Histórico, reemplazado por V4.0 | ⚠️ Mantener para referencia |

### 9.2 Archivos Temporales a Limpiar

| Archivo | Ubicación | Acción |
|---------|-----------|--------|
| conversationAntes.txt | V4.0/ | **MOVER** a 00.history/temp/ |
| *.backup | V4.0/ | **ELIMINAR** (si existen) |
| ~$*.md | V4.0/ | **ELIMINAR** (locks temporales) |

---

## 10. ROADMAP DE EJECUCIÓN

### 10.1 Fase 1: Documentos Orquestador (8 horas)

| Tarea | Esfuerzo | Prioridad | Entregable |
|-------|----------|-----------|------------|
| **Actualizar CONTRATO_SISTEMA_TERRENA_v3.md** con hallazgos FASE1-6 | 3h | P0 | Contrato v3 actualizado |
| **Crear MATRIZ_ALINEACION_V4.0.md** fusionando 4 agentes | 2h | P0 | Matriz consolidada |
| **Crear BACKLOG_SPRINTS_V4.0.md** fusionando 4 agentes | 2h | P0 | Backlog unificado |
| **Crear COMPENDIO_TECNICO.md** fusionando 4 compendios | 1h | P0 | Compendio técnico V4.0 |

### 10.2 Fase 2: Base de Datos (12 horas)

| Tarea | Esfuerzo | Prioridad | Entregable |
|-------|----------|-----------|------------|
| **Crear BaseDatos/README.md** (147 tablas, 38 vistas) | 4h | P0 | Doc BD principal |
| **Crear BaseDatos/Funciones.md** (12 funciones críticas) | 4h | P0 | Doc funciones PL/pgSQL |
| **Crear BaseDatos/Vistas.md** (38 vistas) | 3h | P1 | Doc vistas materializadas |
| **Crear BaseDatos/Triggers.md** (20 triggers) | 1h | P2 | Doc triggers activos |

### 10.3 Fase 3: Módulos Críticos (16 horas)

| Tarea | Esfuerzo | Prioridad | Entregable |
|-------|----------|-----------|------------|
| **Crear Catalogos/README.md** | 3h | P0 | Doc catálogos |
| **Crear Seguridad/README.md** | 3h | P0 | Doc seguridad y permisos |
| **Crear Frontend/GapsUX_Criticos.md** | 2h | P0 | Doc gaps UX FASE6 |
| **Ampliar Produccion/README.md** + crear Ordenes.md | 3h | P1 | Doc producción completo |
| **Ampliar POS/README.md** + crear Consumos.md | 3h | P1 | Doc POS completo |
| **Actualizar Recetas/README.md** | 2h | P1 | Doc recetas mejorado |

### 10.4 Fase 4: Sub-módulos y Expansiones (12 horas)

| Tarea | Esfuerzo | Prioridad | Entregable |
|-------|----------|-----------|------------|
| **Crear Inventario/Ajustes.md** | 2h | P1 | Doc ajustes inventario |
| **Crear Inventario/Kardex.md** | 2h | P1 | Doc kardex detallado |
| **Crear Recetas/Versionado.md** | 2h | P1 | Doc versionado recetas |
| **Crear Recetas/Costeo.md** | 2h | P1 | Doc costeo detallado |
| **Crear Purchasing/Replenishment.md** | 2h | P1 | Doc motor sugerencias |
| **Crear Finanzas/CajaChica.md** | 2h | P2 | Doc caja chica |

### 10.5 Fase 5: Actualizaciones y Refinamiento (8 horas)

| Tarea | Esfuerzo | Prioridad | Entregable |
|-------|----------|-----------|------------|
| **Actualizar Arquitectura/README.md** con stack confirmado | 2h | P1 | Doc arquitectura |
| **Actualizar Frontend/Componentes.md** con gaps UX | 2h | P1 | Doc componentes |
| **Actualizar Frontend/Layout.md** con Bootstrap 5 | 1h | P2 | Doc layout |
| **Crear Arquitectura/Convenciones.md** | 2h | P2 | Doc convenciones código |
| **Actualizar V4.0/README.md** con índice completo | 1h | P1 | Índice V4.0 final |

### 10.6 Resumen Roadmap

| Fase | Esfuerzo | Prioridad | Documentos | Inicio |
|------|----------|-----------|------------|--------|
| **Fase 1** - Orquestador | 8h | P0 | 4 docs | Inmediato |
| **Fase 2** - Base Datos | 12h | P0 | 4 docs | Semana 1 |
| **Fase 3** - Módulos Críticos | 16h | P0-P1 | 6 docs | Semana 1-2 |
| **Fase 4** - Sub-módulos | 12h | P1-P2 | 6 docs | Semana 2 |
| **Fase 5** - Refinamiento | 8h | P1-P2 | 5 docs | Semana 3 |
| **TOTAL** | **56 horas** | - | **25 docs** | 3 semanas |

---

## 11. ESTRUCTURA V4.0 FINAL (44 DOCUMENTOS)

### 11.1 Árbol Documental Objetivo

```
docs/V4.0/
├── README.md                                    [ACTUALIZAR] Índice maestro
│
├── 00_Orquestador/                              [CARPETA CRÍTICA]
│   ├── 00_CONTRATO_SISTEMA_TERRENA_v3.md       [ACTUALIZAR] Contrato con FASE1-6
│   ├── MATRIZ_ALINEACION_V4.0.md               [CREAR] Matriz 15 módulos
│   ├── BACKLOG_SPRINTS_V4.0.md                 [CREAR] Backlog 8 sprints
│   ├── COMPENDIO_TECNICO.md                    [CREAR] Compendio fusionado
│   └── PLAN_ACTUALIZACION_V4.0.md              [ESTE ARCHIVO]
│
├── Arquitectura/                                [CARPETA EXISTENTE]
│   ├── README.md                                [ACTUALIZAR] Stack + estructura
│   └── Convenciones.md                          [CREAR] Naming + PSR-12
│
├── BaseDatos/                                   [CARPETA NUEVA]
│   ├── README.md                                [CREAR] 147 tablas, 38 vistas
│   ├── Funciones.md                             [CREAR] 37 funciones PL/pgSQL
│   ├── Vistas.md                                [CREAR] 38 vistas detalladas
│   └── Triggers.md                              [CREAR] 20 triggers activos
│
├── Catalogos/                                   [CARPETA NUEVA]
│   └── README.md                                [CREAR] UOM, Almacenes, Proveedores
│
├── Seguridad/                                   [CARPETA NUEVA]
│   └── README.md                                [CREAR] Spatie + Policies
│
├── Inventario/                                  [CARPETA EXISTENTE]
│   ├── Items.md                                 [MANTENER]
│   ├── Recepciones.md                           [ACTUALIZAR] Estados BORRADOR→POSTEADA
│   ├── Conteos.md                               [MANTENER]
│   ├── Transferencias.md                        [AMPLIAR] TransferService completo
│   ├── Mermas.md                                [AMPLIAR] InventoryWaste
│   ├── Disponibilidad.md                        [ACTUALIZAR] vw_kardex
│   ├── Ajustes.md                               [CREAR] Ajustes manuales
│   └── Kardex.md                                [CREAR] mov_inv detallado
│
├── Recetas/                                     [CARPETA EXISTENTE]
│   ├── README.md                                [ACTUALIZAR] Visión general
│   ├── Versionado.md                            [CREAR] RecetaVersion
│   ├── Costeo.md                                [CREAR] RecipeCostingService
│   └── Mapeo_POS.md                             [CREAR] pos_map, sync-pos
│
├── Produccion/                                  [CARPETA EXISTENTE]
│   ├── README.md                                [AMPLIAR] ProductionService + UI
│   ├── Ordenes.md                               [CREAR] production_orders
│   └── Mermas.md                                [CREAR] inventory_wastes en producción
│
├── Purchasing/                                  [CARPETA EXISTENTE]
│   ├── README.md                                [ACTUALIZAR] Motor replenishment
│   ├── Replenishment.md                         [CREAR] inv_stock_policy
│   └── Recepciones_Compras.md                   [CREAR] ReceivingService
│
├── POS/                                         [CARPETA EXISTENTE]
│   ├── README.md                                [AMPLIAR] Visión general
│   └── Consumos.md                              [CREAR] PosConsumptionService
│
├── Caja/                                        [CARPETA EXISTENTE]
│   ├── HistoricoCortes.md                       [MANTENER]
│   └── REDIRECCION_DETALLE_A_WIZARD.md         [MANTENER]
│
├── Finanzas/                                    [CARPETA EXISTENTE]
│   ├── README.md                                [AMPLIAR] DailyCloseService
│   ├── CajaChica.md                             [CREAR] CashFund completo
│   └── Cortes.md                                [CREAR] Precorte/Postcorte
│
├── Reports/                                     [CARPETA EXISTENTE]
│   ├── README.md                                [MANTENER]
│   ├── KPIs.md                                  [CREAR] 38 vistas, dashboards
│   └── Ventas.md                                [CREAR] SalesDetailController
│
├── Frontend/                                    [CARPETA EXISTENTE]
│   ├── Layout.md                                [ACTUALIZAR] Bootstrap 5
│   ├── Componentes.md                           [ACTUALIZAR] Gaps UX
│   └── GapsUX_Criticos.md                       [CREAR] FASE6 completo
│
└── Guia/                                        [CARPETA EXISTENTE]
    └── Stack.md                                 [ACTUALIZAR] Versiones confirmadas
```

### 11.2 Estadísticas Finales

| Métrica | Antes | Después | Delta |
|---------|-------|---------|-------|
| **Documentos totales** | 20 | 44 | +24 (120%) |
| **Carpetas módulos** | 11 | 15 | +4 (36%) |
| **Cobertura módulos** | 11/15 (73%) | 15/15 (100%) | +4 módulos |
| **Score documental** | 76% | 94% | +18 puntos |
| **Docs P0 (críticos)** | 11 | 20 | +9 |
| **Docs P1 (altos)** | 6 | 15 | +9 |
| **Docs P2 (medios)** | 3 | 9 | +6 |

---

## 12. CRITERIOS DE ÉXITO

### 12.1 Métricas Cuantitativas

| Métrica | Meta | Medición |
|---------|------|----------|
| **Cobertura documental** | ≥ 94% | 44 docs creados / 44 objetivo |
| **Cobertura módulos** | 15/15 (100%) | Todos los módulos con README |
| **Funciones BD documentadas** | ≥ 90% | 12 críticas + 25 restantes |
| **Vistas BD documentadas** | 100% | 38/38 vistas |
| **Duplicados resueltos** | 0 | Consolidación CONTRATO, MATRIZ, BACKLOG |
| **Referencias agentes** | 4/4 | CLAUDE, QWEN, CODEX, COPILOT mencionados |

### 12.2 Métricas Cualitativas

| Criterio | Verificación |
|----------|--------------|
| **Consistencia formato** | Todos los README siguen patrón Compendio Supremo |
| **Trazabilidad código** | Cada documento enlaza archivos reales (app/, resources/) |
| **Trazabilidad BD** | Cada documento enlaza tablas/vistas/funciones (selemti.*) |
| **No contradicciones** | Sin información conflictiva entre documentos |
| **Fuente única verdad** | V4.0 es referencia oficial, 00.history es apoyo |

---

## 13. RIESGOS Y MITIGACIONES

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| **Sobrescribir docs de agentes** | Baja | Alto | Escribir SOLO en V4.0/, LEER de 00.history/ |
| **Perder información valiosa** | Media | Alto | Fusionar, no reemplazar; tabla comparativa de agentes |
| **Desincronización con código** | Media | Alto | Validar archivos existen antes de documentar |
| **Documentación obsoleta** | Media | Medio | Agregar fecha actualización en cada doc |
| **Esfuerzo subestimado** | Alta | Medio | Buffer 20% adicional (56h → 67h) |

---

## 14. PRÓXIMOS PASOS INMEDIATOS

### 14.1 Aprobación (30 min)
- [ ] Revisar este plan con stakeholders
- [ ] Aprobar estructura V4.0 final (44 docs)
- [ ] Aprobar roadmap 3 semanas (56h)
- [ ] Confirmar prioridades P0 vs P1 vs P2

### 14.2 Inicio Fase 1 (8 horas)
- [ ] Actualizar CONTRATO_SISTEMA_TERRENA_v3.md con FASE1-6
- [ ] Crear MATRIZ_ALINEACION_V4.0.md fusionando 4 agentes
- [ ] Crear BACKLOG_SPRINTS_V4.0.md fusionando 4 backlogs
- [ ] Crear COMPENDIO_TECNICO.md como síntesis técnica

### 14.3 Comunicación
- [ ] Notificar a QWEN, CODEX, COPILOT del plan
- [ ] Solicitar revisión de docs fusionados
- [ ] Establecer canal de feedback durante ejecución

---

**FIN DEL PLAN DE ACTUALIZACIÓN V4.0**
**Próxima acción**: Crear MATRIZ_DOCUMENTAL_ACTUALIZADA.md (análisis detallado 44 documentos)
