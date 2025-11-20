# PLAN DE IMPLEMENTACIÓN SPRINT 1 - Terrena V4.0

**Orquestador**: MAESTRO
**Fecha**: 18 Noviembre 2025
**Sprint**: Sprint 1 (2 semanas)
**Esfuerzo total**: 55 horas
**Estado BD↔Código**: ✅ COMPLETADO (ver REFAC_RESUMEN_GLOBAL.md)

---

## 1. VISIÓN DEL SPRINT

**Objetivo**: Implementar funcionalidades críticas de Inventario, Recetas y Purchasing que desbloquean operación diaria y proveen base para Sprints subsecuentes.

**Prioridades**:
- ✅ BD ya alineada con código (refactor completado)
- 🎯 Motor de Replenishment (Purchasing) - crítico, 0% implementado
- 🎯 Versionado completo de Recetas - funcionalidad parcial, necesita UI
- 🎯 Recepciones con estados (BORRADOR → VALIDADA → POSTEADA)
- 🎯 Transferencias con flujo completo (origen → tránsito → destino)

---

## 2. ITEMS DEL SPRINT 1

### 2.1 INV-001: Motor de Replenishment (31 horas)

**Estado actual**: 0% implementado
**Criticidad**: 🔴 P0 - Bloquea eficiencia operativa de compras
**Alcance funcional**:
1. Algoritmos de cálculo de sugerencias de compra:
   - Min-Max (stock mínimo/máximo configurado por ítem)
   - SMA - Simple Moving Average (promedio móvil de consumo)
   - POS Consumption (basado en tickets históricos expandidos)
2. Dashboard web de sugerencias con filtros y acciones
3. API REST para integración externa
4. Job scheduler para cálculo automático diario

**Impacto en BD**:
- Tablas existentes a usar:
  * `selemti.stock_policy` (min/max por ítem/almacén)
  * `selemti.items` (catálogo)
  * `selemti.mov_inv` (movimientos históricos para SMA)
  * `public.ticket`, `public.ticket_item` (consumo POS)
- Tablas NUEVAS a crear:
  * `selemti.replenishment_config` (configuración algoritmo por ítem)
  * `selemti.purchase_suggestions` (sugerencias generadas)
  * `selemti.purchase_suggestion_history` (auditoría de aceptar/rechazar)

**Impacto en código**:
- NUEVO: `app/Services/Purchasing/ReplenishmentService.php`
- NUEVO: `app/Jobs/CalculateReplenishmentSuggestions.php`
- NUEVO: `app/Models/Purchasing/ReplenishmentConfig.php`
- NUEVO: `app/Models/Purchasing/PurchaseSuggestion.php`
- NUEVO: `app/Livewire/Purchasing/ReplenishmentDashboard.php`
- NUEVO: `app/Http/Controllers/Api/Purchasing/ReplenishmentController.php`
- MODIFICAR: `routes/api.php` (nuevos endpoints)

**Dependencias**:
- ✅ Tablas `stock_policy`, `items`, `mov_inv` ya existen y están documentadas
- ✅ Función `fn_expandir_consumo_ticket()` existe en BD (requiere documentación en Sprint 2)
- ⚠️ Requiere configuración de cron job en producción

**Artefactos de entrada**:
- `docs/V4.0/BaseDatos/Tablas.md` (sección Purchasing)
- `docs/V4.0/Purchasing/` (documentación existente)
- `docs/V4.0/00_Orquestador/02_BACKLOG_SPRINTS_V4.0.md` (HU-2.1, HU-2.2, HU-2.3)
- `docs/V4.0/00_Orquestador/03_COMPENDIO_TECNICO.md` (arquitectura)

---

### 2.2 REC-001: Versionado de Recetas Completo (16 horas)

**Estado actual**: 60% implementado (BD y servicios OK, UI parcial)
**Criticidad**: 🟡 P1 - Requerido para control de costos y trazabilidad
**Alcance funcional**:
1. UI completa para crear nueva versión desde versión activa
2. Comparador visual de versiones (diff de ingredientes y costos)
3. Activación de versión con confirmación y auditoría
4. Snapshot de costos por versión (`recipe_cost_snapshot`)
5. Integración con POS (activar versión actualiza `pos_map`)

**Impacto en BD**:
- Tablas existentes a usar (✅ ya existen):
  * `selemti.receta` (header de receta)
  * `selemti.receta_version` (versiones de receta)
  * `selemti.receta_insumo` (ingredientes por versión)
  * `selemti.recipe_cost_snapshot` (snapshot de costo)
  * `selemti.pos_map` (mapeo POS ↔ receta)
- Tablas NUEVAS: Ninguna (estructura completa ya existe)
- Vistas existentes:
  * `selemti.vw_receta_version_comparacion` (comparar 2 versiones)

**Impacto en código**:
- EXISTENTE (refactorizado): `app/Services/Recipes/RecipeVersionService.php`
- EXISTENTE (refactorizado): `app/Models/Recipes/RecetaVersion.php`
- NUEVO: `app/Livewire/Recipes/VersionComparator.php`
- NUEVO: `app/Livewire/Recipes/VersionActivator.php`
- MODIFICAR: `app/Livewire/Recipes/RecipeEditor.php` (agregar botón "Nueva Versión")
- NUEVO: `resources/views/livewire/recipes/version-comparator.blade.php`

**Dependencias**:
- ✅ Refactor Recetas completado (REFAC_RECETAS_RESULTADOS.md)
- ✅ Función `fn_recipe_cost_at()` existe en BD (requiere documentación en Sprint 2)
- ⚠️ Consolidar `PosConsumptionService` (US-1.4) antes de integrar con POS

**Artefactos de entrada**:
- `docs/V4.0/Code/REFAC_RECETAS_RESULTADOS.md`
- `docs/V4.0/BaseDatos/Tablas.md` (sección Recetas)
- `docs/V4.0/Recetas/README.md`
- `BD_SCHEMA_SELEMTI.sql` (tablas receta*)

---

### 2.3 INV-002: Recepciones BORRADOR → VALIDADA → POSTEADA (21 horas)

**Estado actual**: 40% implementado (flujo básico existe, falta state machine)
**Criticidad**: 🔴 P0 - Control de calidad en recepciones
**Alcance funcional**:
1. State machine de 3 estados:
   - **BORRADOR**: Captura inicial, editable, NO afecta inventario
   - **VALIDADA**: Revisión gerencial, NO editable, NO afecta inventario
   - **POSTEADA**: Irreversible, afecta `mov_inv` y genera lote
2. Transiciones de estado con permisos específicos
3. UI con indicador visual de estado actual
4. Tolerancias de recepción por proveedor (alerta si qty recibida difiere de esperada)
5. Adjuntar evidencias (fotos, PDFs) a recepciones

**Impacto en BD**:
- Tablas existentes a modificar:
  * `selemti.recepcion_det` - agregar columna `estado` (enum: BORRADOR, VALIDADA, POSTEADA)
  * `selemti.recepcion_det` - agregar columnas `validada_por`, `validada_at`, `posteada_por`, `posteada_at`
- Tablas NUEVAS:
  * `selemti.reception_tolerances` (tolerancias por proveedor)
  * `selemti.reception_attachments` (evidencias adjuntas)
  * `selemti.reception_state_audit` (auditoría de transiciones de estado)

**Impacto en código**:
- EXISTENTE: `app/Services/Inventory/ReceptionService.php` (agregar lógica state machine)
- MODIFICAR: `app/Livewire/Inventory/ReceptionCreate.php`
- MODIFICAR: `app/Livewire/Inventory/ReceptionDetail.php` (agregar upload de evidencias)
- NUEVO: `app/Models/Inventory/ReceptionTolerance.php`
- NUEVO: `app/Models/Inventory/ReceptionAttachment.php`
- NUEVO: `database/migrations/2025_11_18_add_reception_states.php`
- NUEVO: `database/migrations/2025_11_18_create_reception_tolerances.php`
- NUEVO: `database/migrations/2025_11_18_create_reception_attachments.php`

**Dependencias**:
- ✅ Refactor Inventario completado (REFAC_INVENTARIO_RESULTADOS.md)
- ✅ Tabla `recepcion_det` ya existe y está alineada con código
- ⚠️ Requiere permisos Spatie: `recepciones.validar`, `recepciones.postear`

**Artefactos de entrada**:
- `docs/V4.0/Code/REFAC_INVENTARIO_RESULTADOS.md`
- `docs/V4.0/BaseDatos/Tablas.md` (sección Inventario)
- `docs/V4.0/Inventario/Recepciones.md`
- `BD_SCHEMA_SELEMTI.sql` (tabla recepcion_det)

---

### 2.4 INV-003: Transferencias con Flujo Completo (19 horas)

**Estado actual**: 50% implementado (flujo básico existe, falta UI despacho/recepción)
**Criticidad**: 🟡 P1 - Multi-almacén requiere transferencias confiables
**Alcance funcional**:
1. Flujo completo de transferencias:
   - **PENDIENTE**: Transfer creada, NO ha salido de origen
   - **EN_TRANSITO**: Despachada de origen, NO ha llegado a destino
   - **RECIBIDA**: Completada en destino, afecta inventario en ambos almacenes
   - **CANCELADA**: Cancelada antes de despachar
2. UI de despacho (confirmar salida, seleccionar lote origen)
3. UI de recepción (confirmar llegada, capturar qty recibida vs esperada)
4. Generación automática de movimientos `mov_inv` en ambos almacenes al completar
5. Trazabilidad de lotes (lote origen → lote destino)

**Impacto en BD**:
- Tablas existentes a usar:
  * `selemti.transfer_cab` (header de transferencia)
  * `selemti.transfer_det` (detalle de ítems)
  * `selemti.mov_inv` (movimientos generados al completar)
  * `selemti.inventory_batch` (lotes origen/destino)
- Tablas existentes a modificar:
  * `selemti.transfer_cab` - agregar columnas `despachada_at`, `recibida_at`
  * `selemti.transfer_det` - agregar columnas `lote_origen_id`, `lote_destino_id`, `qty_recibida`
- Tablas NUEVAS:
  * `selemti.transfer_state_audit` (auditoría de transiciones)

**Impacto en código**:
- EXISTENTE: `app/Services/Inventory/TransferService.php` (agregar métodos despachar/recibir)
- EXISTENTE: `app/Models/Inventory/TransferCab.php` (refactorizado)
- NUEVO: `app/Livewire/Inventory/TransferDispatch.php`
- NUEVO: `app/Livewire/Inventory/TransferReceive.php`
- MODIFICAR: `app/Livewire/Inventory/TransferList.php` (agregar acciones)
- NUEVO: `resources/views/livewire/inventory/transfer-dispatch.blade.php`
- NUEVO: `resources/views/livewire/inventory/transfer-receive.blade.php`
- NUEVO: `database/migrations/2025_11_18_enhance_transfers.php`

**Dependencias**:
- ✅ Refactor Inventario completado (REFAC_INVENTARIO_RESULTADOS.md)
- ✅ Tablas `transfer_cab`, `transfer_det` ya existen
- ✅ Script SQL `fix_transfer_tables.sql` ya aplicado (ver Code/)
- ⚠️ Requiere permisos Spatie: `transferencias.despachar`, `transferencias.recibir`

**Artefactos de entrada**:
- `docs/V4.0/Code/REFAC_INVENTARIO_RESULTADOS.md`
- `docs/V4.0/BaseDatos/Tablas.md` (sección Inventario - Transferencias)
- `docs/V4.0/Inventario/Transferencias.md`
- `docs/V4.0/Code/fix_transfer_tables.sql`
- `BD_SCHEMA_SELEMTI.sql` (tablas transfer_*)

---

## 3. DESCOMPOSICIÓN EN SUBTAREAS PARA AGENTES IA

### 3.1 INV-001: Motor de Replenishment (8 subtareas)

| Subtarea ID | Descripción | Agente sugerido | Esfuerzo | Artefactos entrada | Artefactos salida esperados |
|-------------|-------------|-----------------|----------|-------------------|---------------------------|
| INV-001-A | Diseño técnico del servicio ReplenishmentService con firmas de métodos y contratos | Claude + Qwen | 3h | `Tablas.md`, `BACKLOG_SPRINTS_V4.0.md` (HU-2.1) | `docs/V4.0/Purchasing/REPLENISHMENT_DESIGN.md` con spec técnica detallada |
| INV-001-B | Crear migraciones para tablas nuevas (replenishment_config, purchase_suggestions, purchase_suggestion_history) | Qwen | 2h | `REPLENISHMENT_DESIGN.md`, `BD_SCHEMA_SELEMTI.sql` | 3 archivos migration en `database/migrations/` |
| INV-001-C | Implementar modelos Eloquent (ReplenishmentConfig, PurchaseSuggestion) | Codex | 2h | Migraciones creadas, `BD_SCHEMA_SELEMTI.sql` | `app/Models/Purchasing/ReplenishmentConfig.php`, `app/Models/Purchasing/PurchaseSuggestion.php` |
| INV-001-D | Implementar ReplenishmentService con algoritmos Min-Max, SMA, POS Consumption | Codex + Copilot | 8h | `REPLENISHMENT_DESIGN.md`, modelos creados, `fn_expandir_consumo_ticket()` | `app/Services/Purchasing/ReplenishmentService.php` con 3 algoritmos funcionales |
| INV-001-E | Implementar Job CalculateReplenishmentSuggestions para scheduler | Codex | 2h | ReplenishmentService implementado | `app/Jobs/CalculateReplenishmentSuggestions.php` + configuración en `app/Console/Kernel.php` |
| INV-001-F | Implementar Livewire component ReplenishmentDashboard con filtros y acciones | Copilot + Claude | 7h | ReplenishmentService, modelos | `app/Livewire/Purchasing/ReplenishmentDashboard.php` + blade |
| INV-001-G | Implementar API REST endpoints (GET /api/purchasing/suggestions, POST accept/reject) | Codex | 4h | ReplenishmentService | `app/Http/Controllers/Api/Purchasing/ReplenishmentController.php`, actualizar `routes/api.php` |
| INV-001-H | Documentación Swagger + tests básicos | Copilot + Claude | 3h | API implementada | `storage/api-docs/purchasing.yaml` actualizado, tests en `tests/Feature/ReplenishmentTest.php` |

**Total**: 31 horas

---

### 3.2 REC-001: Versionado de Recetas Completo (5 subtareas)

| Subtarea ID | Descripción | Agente sugerido | Esfuerzo | Artefactos entrada | Artefactos salida esperados |
|-------------|-------------|-----------------|----------|-------------------|---------------------------|
| REC-001-A | Diseño técnico UI: comparador de versiones + activador | Claude | 2h | `REFAC_RECETAS_RESULTADOS.md`, `Tablas.md` (Recetas) | `docs/V4.0/Recetas/UI_VERSIONADO_DESIGN.md` con wireframes y flujos |
| REC-001-B | Implementar Livewire VersionComparator (diff de ingredientes y costos) | Copilot | 5h | `UI_VERSIONADO_DESIGN.md`, `RecipeVersionService.php` | `app/Livewire/Recipes/VersionComparator.php` + blade |
| REC-001-C | Implementar Livewire VersionActivator (activar con confirmación) | Copilot | 4h | `UI_VERSIONADO_DESIGN.md`, `RecipeVersionService.php` | `app/Livewire/Recipes/VersionActivator.php` + blade |
| REC-001-D | Modificar RecipeEditor para agregar botón "Nueva Versión desde Activa" | Codex | 3h | VersionComparator, VersionActivator | `app/Livewire/Recipes/RecipeEditor.php` actualizado |
| REC-001-E | Tests de integración: crear versión, comparar, activar | Copilot | 2h | Componentes implementados | `tests/Feature/RecipeVersioningTest.php` |

**Total**: 16 horas

---

### 3.3 INV-002: Recepciones BORRADOR → VALIDADA → POSTEADA (7 subtareas)

| Subtarea ID | Descripción | Agente sugerido | Esfuerzo | Artefactos entrada | Artefactos salida esperados |
|-------------|-------------|-----------------|----------|-------------------|---------------------------|
| INV-002-A | Diseño técnico state machine: estados, transiciones, permisos | Claude + Qwen | 2h | `REFAC_INVENTARIO_RESULTADOS.md`, `Recepciones.md` | `docs/V4.0/Inventario/RECEPTION_STATE_MACHINE.md` |
| INV-002-B | Crear migraciones para agregar estados a recepcion_det + tablas nuevas | Qwen | 2h | `RECEPTION_STATE_MACHINE.md`, `BD_SCHEMA_SELEMTI.sql` | 3 archivos migration: estados, tolerances, attachments |
| INV-002-C | Implementar modelos ReceptionTolerance, ReceptionAttachment | Codex | 2h | Migraciones creadas | `app/Models/Inventory/ReceptionTolerance.php`, `app/Models/Inventory/ReceptionAttachment.php` |
| INV-002-D | Agregar lógica state machine a ReceptionService (validar, postear, validaciones) | Codex | 5h | `RECEPTION_STATE_MACHINE.md`, `ReceptionService.php` | `app/Services/Inventory/ReceptionService.php` actualizado con state machine |
| INV-002-E | Modificar ReceptionCreate y ReceptionDetail para mostrar estado y acciones | Copilot | 5h | ReceptionService actualizado | `app/Livewire/Inventory/ReceptionCreate.php`, `ReceptionDetail.php` actualizados + blades |
| INV-002-F | Implementar upload de evidencias en ReceptionDetail | Copilot | 3h | ReceptionAttachment modelo | `app/Livewire/Inventory/ReceptionDetail.php` con upload funcional |
| INV-002-G | Tests de integración: crear borrador, validar, postear, tolerancias | Copilot | 2h | Componentes implementados | `tests/Feature/ReceptionStateTest.php` |

**Total**: 21 horas

---

### 3.4 INV-003: Transferencias con Flujo Completo (6 subtareas)

| Subtarea ID | Descripción | Agente sugerido | Esfuerzo | Artefactos entrada | Artefactos salida esperados |
|-------------|-------------|-----------------|----------|-------------------|---------------------------|
| INV-003-A | Diseño técnico flujo de transferencias: estados, UI despacho/recepción | Claude | 2h | `REFAC_INVENTARIO_RESULTADOS.md`, `Transferencias.md` | `docs/V4.0/Inventario/TRANSFER_FLOW_DESIGN.md` |
| INV-003-B | Crear migración para agregar columnas a transfer_cab y transfer_det | Qwen | 2h | `TRANSFER_FLOW_DESIGN.md`, `fix_transfer_tables.sql` | `database/migrations/2025_11_18_enhance_transfers.php` |
| INV-003-C | Agregar métodos despachar() y recibir() a TransferService con generación de mov_inv | Codex | 5h | `TRANSFER_FLOW_DESIGN.md`, `TransferService.php` | `app/Services/Inventory/TransferService.php` actualizado |
| INV-003-D | Implementar Livewire TransferDispatch (confirmar despacho, seleccionar lote) | Copilot | 4h | TransferService actualizado | `app/Livewire/Inventory/TransferDispatch.php` + blade |
| INV-003-E | Implementar Livewire TransferReceive (confirmar recepción, capturar qty recibida) | Copilot | 4h | TransferService actualizado | `app/Livewire/Inventory/TransferReceive.php` + blade |
| INV-003-F | Tests de integración: crear transfer, despachar, recibir, verificar mov_inv | Copilot | 2h | Componentes implementados | `tests/Feature/TransferFlowTest.php` |

**Total**: 19 horas

---

## 4. RESUMEN DE SUBTAREAS POR AGENTE

| Agente | Subtareas asignadas | Horas totales | Tipo de trabajo |
|--------|---------------------|---------------|-----------------|
| **Claude** | INV-001-A, REC-001-A, INV-002-A, INV-003-A, INV-001-H | 12h | Diseño técnico, arquitectura, UX |
| **Qwen** | INV-001-A, INV-001-B, INV-002-A, INV-002-B, INV-003-B | 11h | Diseño BD, migraciones, SQL |
| **Codex** | INV-001-C, INV-001-D, INV-001-G, REC-001-D, INV-002-C, INV-002-D, INV-003-C | 28h | Servicios backend, modelos, API |
| **Copilot** | INV-001-D, INV-001-E, INV-001-F, INV-001-H, REC-001-B, REC-001-C, REC-001-E, INV-002-E, INV-002-F, INV-002-G, INV-003-D, INV-003-E, INV-003-F | 41h | UI Livewire, tests, integración |

**Total**: 92h (distribuido entre 4 agentes, algunas tareas en paralelo)
**Duración real**: ~55h (considerando paralelización)

---

## 5. CRITERIOS DE ACEPTACIÓN DEL SPRINT

### 5.1 INV-001: Motor de Replenishment
- [ ] ReplenishmentService implementado con 3 algoritmos funcionales
- [ ] Dashboard web funcional con filtros por almacén/categoría/proveedor
- [ ] API REST con endpoints GET /suggestions, POST /accept, POST /reject
- [ ] Job scheduler configurado para ejecución diaria
- [ ] Documentación Swagger completa
- [ ] Tests básicos passing (min 80% coverage)
- [ ] Validado en producción con datos históricos reales

### 5.2 REC-001: Versionado de Recetas
- [ ] UI crear nueva versión desde versión activa funcional
- [ ] Comparador visual de versiones muestra diff de ingredientes y costos
- [ ] Activar versión actualiza pos_map correctamente
- [ ] Snapshot de costos se genera al activar versión
- [ ] Tests de integración passing
- [ ] Validado en producción con receta real

### 5.3 INV-002: Recepciones Estados
- [ ] State machine BORRADOR → VALIDADA → POSTEADA funcional
- [ ] UI muestra estado actual y acciones disponibles
- [ ] Solo estado POSTEADA afecta mov_inv
- [ ] Tolerancias por proveedor funcionan correctamente
- [ ] Upload de evidencias funcional
- [ ] Permisos Spatie configurados y validados
- [ ] Tests de integración passing
- [ ] Validado en producción con recepción real

### 5.4 INV-003: Transferencias Flujo
- [ ] Flujo PENDIENTE → EN_TRANSITO → RECIBIDA funcional
- [ ] UI despacho y recepción funcionan correctamente
- [ ] mov_inv se genera automáticamente al completar
- [ ] Trazabilidad de lotes funciona (lote origen → destino)
- [ ] Tests de integración passing
- [ ] Validado en producción con transferencia real entre almacenes

---

## 6. RIESGOS Y MITIGACIONES

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|-----------|
| Algoritmos de replenishment no son precisos con datos históricos | Media | Alto | Validar con stakeholders antes de deployment, permitir ajuste manual |
| fn_expandir_consumo_ticket() no documentada causa confusión | Alta | Medio | Documentar en Sprint 2 (US-2.4), por ahora usar como está |
| Permisos Spatie no configurados en producción | Media | Alto | Crear migration de permisos y roles antes de deployment |
| Consolidación de PosConsumptionService introduce bugs | Media | Medio | Tests exhaustivos antes de eliminar copias, rollback plan |
| UI Livewire no funciona correctamente en producción (RewriteBase) | Media | Alto | Validar assets en http://100.126.124.101/terrena2/ antes de cerrar Sprint |
| Migraciones fallan en PostgreSQL 14 producción (vs 9.5 local) | Baja | Alto | Testear migraciones en entorno staging primero |

---

## 7. ORDEN DE EJECUCIÓN RECOMENDADO

### Fase 1 (Días 1-3): Diseño y BD
1. **Diseño técnico** (Claude + Qwen):
   - INV-001-A: Diseño ReplenishmentService
   - REC-001-A: Diseño UI Versionado
   - INV-002-A: Diseño State Machine Recepciones
   - INV-003-A: Diseño Flujo Transferencias

2. **Migraciones** (Qwen):
   - INV-001-B: Migraciones Replenishment
   - INV-002-B: Migraciones Recepciones Estados
   - INV-003-B: Migración Transferencias

### Fase 2 (Días 4-7): Backend y Servicios
3. **Modelos y Servicios** (Codex):
   - INV-001-C, INV-001-D: Replenishment modelos + servicio
   - INV-002-C, INV-002-D: Recepciones modelos + state machine
   - INV-003-C: TransferService métodos despachar/recibir

4. **Jobs y API** (Codex):
   - INV-001-E: Job CalculateReplenishmentSuggestions
   - INV-001-G: API REST Replenishment

### Fase 3 (Días 8-12): Frontend y UI
5. **Componentes Livewire** (Copilot):
   - INV-001-F: ReplenishmentDashboard
   - REC-001-B, REC-001-C, REC-001-D: Versionado UI
   - INV-002-E, INV-002-F: Recepciones UI
   - INV-003-D, INV-003-E: Transferencias UI

### Fase 4 (Días 13-14): Tests y Validación
6. **Tests y Documentación** (Copilot + Claude):
   - INV-001-H: Swagger + tests Replenishment
   - REC-001-E: Tests Versionado
   - INV-002-G: Tests Recepciones
   - INV-003-F: Tests Transferencias

7. **Validación en Producción** (Equipo completo):
   - Validar cada feature con datos reales
   - Ajustar según feedback
   - Documentar issues encontrados

---

## 8. PRÓXIMOS PASOS POST-SPRINT 1

Una vez completado Sprint 1, el equipo estará listo para:
- **Sprint 2**: Documentar funciones BD críticas (fn_recipe_cost_at, fn_expandir_consumo_ticket, etc.)
- **Sprint 3**: Documentación core de 15 módulos
- **Sprint 4**: Limpieza de código huérfano prioritario
- Las funcionalidades de Sprint 1 desbloquean:
  * Eficiencia operativa en compras (Replenishment)
  * Control de costos en recetas (Versionado)
  * Control de calidad en recepciones (Estados)
  * Operación multi-almacén confiable (Transferencias)

---

## 9. REFERENCIAS

- **Backlog oficial**: `docs/V4.0/00_Orquestador/02_BACKLOG_SPRINTS_V4.0.md`
- **Arquitectura**: `docs/V4.0/00_Orquestador/03_COMPENDIO_TECNICO.md`
- **BD documentada**: `docs/V4.0/BaseDatos/*.md`
- **Refactor completado**: `docs/V4.0/Code/REFAC_RESUMEN_GLOBAL.md`
- **Schemas BD**: `BD_SCHEMA_PUBLIC.sql`, `BD_SCHEMA_SELEMTI.sql`

---

**Notas finales**:
- Este plan asume que el refactor BD↔código está COMPLETADO y validado (ver REFAC_RESUMEN_GLOBAL.md).
- Las subtareas están diseñadas para ser ejecutadas por agentes IA especializados.
- Cada subtarea tiene artefactos de entrada y salida claros para facilitar handoff entre agentes.
- El orden de ejecución respeta dependencias técnicas y permite paralelización donde es posible.
