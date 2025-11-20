# BACKLOG DE SPRINTS v2 - CLAUDE

**Orquestador**: Claude Code
**Fecha**: 14 Noviembre 2025
**Fuente**: FASE1-FASE6 + Matriz Alineación
**Duración Sprint**: 2 semanas
**Total Sprints**: 8 (16 semanas / 4 meses)

---

## ROADMAP GENERAL

```
Sprint 1-2:  Gaps Críticos UI/UX + Duplicaciones Código (55h)
Sprint 3-4:  Documentación Core Módulos (52h)
Sprint 5-6:  Código Huérfano Prioritario (95h)
Sprint 7-8:  BD + Tests + Pulido (87h)

Total: 289 horas / 8 sprints
```

---

## SPRINT 1: GAPS CRÍTICOS UI/UX (Semanas 1-2)

**Objetivo**: Resolver 3 gaps críticos de UI/UX (FASE6) que afectan experiencia usuario en TODO el sistema.

**Esfuerzo Total**: 24 horas

### US-1.1: Agregar Loading States a Forms (4h) 🔴 CRÍTICA

**Como** usuario del sistema
**Quiero** ver indicadores de carga cuando envío formularios
**Para** saber que mi acción se está procesando y evitar doble envío

**Criterios de Aceptación**:
- [ ] Todos los formularios (40+) muestran spinner durante envío
- [ ] Botón submit se deshabilita durante procesamiento
- [ ] Texto del botón cambia a "Guardando..." / "Procesando..."
- [ ] Patrón reutilizable creado (componente Blade o directiva)

**Tareas Técnicas**:
1. Crear componente `<x-submit-button>` reutilizable (1h)
2. Aplicar a forms Inventario (ItemsIndex, ReceptionsIndex) (0.5h)
3. Aplicar a forms Purchasing (Requests/Create, Orders) (0.5h)
4. Aplicar a forms Caja (Precorte, Postcorte) (0.5h)
5. Aplicar a forms Catálogos (Unidades, Almacenes, Proveedores) (0.5h)
6. Aplicar a forms restantes (~30 forms) (1h)

**Archivos**:
- `resources/views/components/submit-button.blade.php` (nuevo)
- `app/Livewire/**/*Index.php` (40+ componentes)

**Tests**:
- Browser test: Submit form, verificar spinner visible
- Browser test: Verificar botón deshabilitado durante envío

---

### US-1.2: Sistema Unificado de Notificaciones (6h) 🔴 CRÍTICA

**Como** usuario del sistema
**Quiero** recibir confirmaciones visuales de éxito/error en mis acciones
**Para** saber que mi operación se completó correctamente

**Criterios de Aceptación**:
- [ ] Sistema único de toasts (no 3 patrones rotos)
- [ ] Toasts se muestran en todas las operaciones (crear, editar, eliminar)
- [ ] Auto-hide después de 5 segundos
- [ ] Tipos: success, error, warning, info

**Tareas Técnicas**:
1. Crear `app/Livewire/Toast.php` componente (2h)
2. Crear `resources/views/livewire/toast.blade.php` vista (1h)
3. Agregar a layout `terrena.blade.php` (0.5h)
4. Migrar `session()->flash()` a `dispatch('notify')` (1h)
5. Migrar `dispatch('toast')` a `dispatch('notify')` (1h)
6. Actualizar ~30 componentes con patrón unificado (0.5h)

**Archivos**:
- `app/Livewire/Toast.php` (nuevo)
- `resources/views/livewire/toast.blade.php` (nuevo)
- `resources/views/layouts/terrena.blade.php` (editar)
- `app/Livewire/**/*.php` (30+ componentes)

**Tests**:
- Feature test: Crear item, verificar toast success
- Feature test: Error validación, verificar toast error
- Browser test: Toast auto-hide después 5 segundos

---

### US-1.3: Confirmaciones de Eliminación (4h) 🔴 CRÍTICA

**Como** usuario del sistema
**Quiero** confirmar antes de eliminar registros
**Para** evitar pérdida accidental de datos

**Criterios de Aceptación**:
- [ ] Modal de confirmación en todas las operaciones delete (15+)
- [ ] Texto claro: "Esta acción no se puede deshacer"
- [ ] Botones: "Cancelar" (gris) y "Eliminar" (rojo)
- [ ] Loading state en botón "Eliminar"

**Tareas Técnicas**:
1. Crear modal `confirm-delete.blade.php` reutilizable (1.5h)
2. Aplicar a Catálogos (Unidades, Almacenes, Proveedores) (0.5h)
3. Aplicar a Inventario (Items, Recepciones, Lotes) (0.5h)
4. Aplicar a Purchasing (Requests, Orders) (0.5h)
5. Aplicar a Caja Chica (Fondos, Movimientos) (0.5h)
6. Aplicar a componentes restantes (~5) (0.5h)

**Archivos**:
- `resources/views/components/confirm-delete.blade.php` (nuevo)
- `app/Livewire/Catalogs/*.php` (5 componentes)
- `app/Livewire/Inventory/*.php` (4 componentes)
- `app/Livewire/Purchasing/*.php` (3 componentes)

**Tests**:
- Browser test: Click delete, modal aparece
- Browser test: Click cancelar, modal cierra sin eliminar
- Browser test: Click eliminar, registro se borra

---

### US-1.4: Consolidar PosConsumptionService (4h) 🔴 CRÍTICA

**Como** desarrollador
**Quiero** una sola versión canónica de PosConsumptionService
**Para** evitar bugs por cambios inconsistentes

**Criterios de Aceptación**:
- [ ] Solo existe 1 archivo `PosConsumptionService.php`
- [ ] Todas las referencias apuntan a ubicación única
- [ ] Tests pasan
- [ ] Versiones duplicadas eliminadas

**Tareas Técnicas**:
1. Comparar 3 versiones, identificar diferencias (1h)
2. Consolidar en `app/Services/Pos/PosConsumptionService.php` (1h)
3. Actualizar imports en todos los archivos (1h)
4. Eliminar versiones duplicadas (0.5h)
5. Ejecutar tests, corregir fallos (0.5h)

**Archivos**:
- `app/Services/Pos/PosConsumptionService.php` (consolidado)
- `app/Services/PosConsumptionService.php` (eliminar)
- `app/Services/Legacy/PosConsumptionService.php` (eliminar)

**Tests**:
- Unit test: Métodos principales funcionan
- Feature test: Consumo de ticket end-to-end

---

### US-1.5: Consolidar ProductionService (3h) 🔴 ALTA

**Como** desarrollador
**Quiero** una sola versión de ProductionService
**Para** evitar duplicación de lógica

**Criterios de Aceptación**:
- [ ] Solo existe 1 archivo `ProductionService.php`
- [ ] Ubicación: `app/Services/Production/ProductionService.php`
- [ ] Tests pasan

**Tareas Técnicas**:
1. Comparar 2 versiones (0.5h)
2. Consolidar en `Production/` (1h)
3. Actualizar imports (1h)
4. Eliminar duplicado (0.5h)

**Archivos**:
- `app/Services/Production/ProductionService.php` (consolidado)
- `app/Services/ProductionService.php` (eliminar)

---

### US-1.6: Fix Layout Shift Permisos (3h) 🔴 ALTA

**Como** usuario
**Quiero** que el menú no cambie después de cargar
**Para** tener una experiencia visual estable

**Criterios de Aceptación**:
- [ ] Permisos se calculan en servidor
- [ ] Links se renderizan directamente con permisos
- [ ] No hay carga asíncrona de permisos
- [ ] CLS (Cumulative Layout Shift) = 0

**Tareas Técnicas**:
1. Crear `app/View/Components/Sidebar.php` (1h)
2. Calcular permisos en constructor (0.5h)
3. Actualizar `terrena.blade.php` para usar componente (1h)
4. Remover código async de permisos (0.5h)

**Archivos**:
- `app/View/Components/Sidebar.php` (nuevo)
- `resources/views/layouts/terrena.blade.php` (editar)

---

**SPRINT 1 COMPLETADO**: 24 horas
**Resultado Esperado**: UX Score 6.5 → 8.0 (+1.5 puntos)

---

## SPRINT 2: FUNCIONES BD CRÍTICAS (Semanas 3-4)

**Objetivo**: Documentar 12 funciones críticas de BD (FASE5) que implementan lógica core de negocio.

**Esfuerzo Total**: 31 horas

### US-2.1: Documentar Funciones de Costeo (15h) 🔴 CRÍTICA

**Como** desarrollador
**Quiero** documentación completa de funciones de costeo
**Para** entender y mantener cálculos de costos

**Criterios de Aceptación**:
- [ ] 5 funciones documentadas con ejemplos
- [ ] Parámetros, retorno, casos de uso explicados
- [ ] Ejemplos SQL de invocación

**Tareas Técnicas**:
1. Documentar `fn_recipe_cost_at(recipe_id, fecha)` (3h)
2. Documentar `fn_item_unit_cost_at(item_id, fecha)` (3h)
3. Documentar `recalcular_costos_periodo(fecha_inicio, fecha_fin)` (3h)
4. Documentar `fn_recipes_using_item(item_id)` - BOM Implosion (3h)
5. Documentar `sp_snapshot_recipe_cost()` (3h)

**Archivos**:
- `docs/V4.0/BaseDatos/03_FUNCIONES_CRITICAS.md` (nuevo)

**Tests**:
- SQL test: Invocar cada función con datos reales
- Validar resultados vs esperado

---

### US-2.2: Documentar Funciones POS (9h) 🔴 CRÍTICA

**Como** desarrollador
**Quiero** documentación de funciones de consumo POS
**Para** entender integración POS-Recetas

**Criterios de Aceptación**:
- [ ] 3 funciones documentadas
- [ ] Flujo completo explicado

**Tareas Técnicas**:
1. Documentar `fn_expandir_consumo_ticket(ticket_id)` (3h)
2. Documentar `fn_confirmar_consumo_ticket(ticket_id)` (3h)
3. Documentar `fn_reversar_consumo_ticket(ticket_id)` (3h)

**Archivos**:
- `docs/V4.0/BaseDatos/03_FUNCIONES_CRITICAS.md` (actualizar)

---

### US-2.3: Crear 8 Modelos Eloquent Faltantes (16h) 🟡 ALTA

**Como** desarrollador
**Quiero** modelos Eloquent para tablas huérfanas
**Para** acceder a BD con ORM en vez de SQL raw

**Criterios de Aceptación**:
- [ ] 8 modelos creados con relaciones
- [ ] $connection = 'pgsql' especificado
- [ ] $table especificado
- [ ] PHPDoc completo

**Tareas Técnicas**:
1. `app/Models/Pos/PosSyncLog.php` (2h)
2. `app/Models/Pos/PosSyncBatch.php` (2h)
3. `app/Models/Alert/AlertEvent.php` (2h)
4. `app/Models/Alert/AlertRule.php` (2h)
5. `app/Models/System/JobRecalcQueue.php` (2h)
6. `app/Models/System/RecalcLog.php` (2h)
7. `app/Models/Menu/MenuEngineeringSnapshot.php` (2h)
8. `app/Models/Menu/MenuItemSyncMap.php` (2h)

**Archivos**:
- 8 nuevos modelos en `app/Models/`

**Tests**:
- Unit test: Crear registro con modelo
- Unit test: Relaciones funcionan

---

**SPRINT 2 COMPLETADO**: 31 horas
**Resultado Esperado**: BD Alineación 90% → 93% (+3%)

---

## SPRINT 3: DOCUMENTACIÓN RECETAS + PRODUCCIÓN (Semanas 5-6)

**Objetivo**: Ampliar documentación de módulos críticos con docs muy breves.

**Esfuerzo Total**: 26 horas

### US-3.1: Ampliar docs/V4.0/Recetas/README.md (8h) 🟡 ALTA

**Como** desarrollador
**Quiero** documentación completa de Recetas
**Para** entender sistema de versionado y costeo

**Criterios de Aceptación**:
- [ ] README ampliado de 135 a 300+ líneas
- [ ] Secciones: CRUD, Versionado, Costeo, Modificadores
- [ ] Ejemplos de código
- [ ] Diagramas de flujo

**Tareas Técnicas**:
1. Ampliar sección CRUD básico (2h)
2. Agregar sección Versionado (2h)
3. Agregar sección Costeo (2h)
4. Agregar sección Modificadores (2h)

**Archivos**:
- `docs/V4.0/Recetas/README.md` (actualizar)

---

### US-3.2: Crear docs/V4.0/Recetas/02_VERSIONADO.md (6h) 🟡 ALTA

**Como** desarrollador
**Quiero** doc dedicada a versionado de recetas
**Para** implementar feature faltante

**Criterios de Aceptación**:
- [ ] Explicación de por qué versionado
- [ ] Estructura de tabla receta_version
- [ ] Flujo de creación de versiones
- [ ] API endpoints

**Tareas Técnicas**:
1. Diseño conceptual versionado (2h)
2. Estructura BD (1h)
3. Flujo de usuario (2h)
4. API specs (1h)

**Archivos**:
- `docs/V4.0/Recetas/02_VERSIONADO.md` (nuevo)

---

### US-3.3: Ampliar docs/V4.0/Produccion/README.md (8h) 🟡 ALTA

**Como** desarrollador
**Quiero** documentación completa de Producción
**Para** implementar UI operativa

**Criterios de Aceptación**:
- [ ] README ampliado de 100 a 300+ líneas
- [ ] Secciones: Órdenes, Planificación, Mise en Place, Mermas
- [ ] Wireframes UI

**Tareas Técnicas**:
1. Ampliar sección Órdenes (2h)
2. Agregar sección Planificación (2h)
3. Agregar sección Mise en Place (2h)
4. Agregar sección Mermas y Rendimientos (2h)

**Archivos**:
- `docs/V4.0/Produccion/README.md` (actualizar)

---

### US-3.4: Crear docs/V4.0/Produccion/02_MISE_EN_PLACE.md (4h) 🟢 MEDIA

**Como** chef
**Quiero** sistema de mise en place documentado
**Para** planificar producción diaria

**Criterios de Aceptación**:
- [ ] Explicación de concepto mise en place
- [ ] Flujo de planificación
- [ ] Integración con órdenes

**Tareas Técnicas**:
1. Diseño conceptual (1.5h)
2. Flujo de usuario (1.5h)
3. Wireframes (1h)

**Archivos**:
- `docs/V4.0/Produccion/02_MISE_EN_PLACE.md` (nuevo)

---

**SPRINT 3 COMPLETADO**: 26 horas

---

## SPRINT 4: DOCUMENTACIÓN POS + VENTAS + BD (Semanas 7-8)

**Objetivo**: Completar documentación de módulos POS, Ventas y Base de Datos.

**Esfuerzo Total**: 26 horas

### US-4.1: Ampliar docs/V4.0/POS/README.md (8h) 🟡 ALTA

**Criterios de Aceptación**:
- [ ] README ampliado de 110 a 250+ líneas
- [ ] Secciones: Integración, Mapeo, Sincronización, Repositorios

**Tareas**: 4 secciones x 2h cada una

---

### US-4.2: Crear docs/V4.0/Ventas/01_CONSUMO_POS_RECETAS.md (8h) 🔴 CRÍTICA

**Criterios de Aceptación**:
- [ ] Flujo completo POS → Consumo → Kardex
- [ ] Explicación de mapeo
- [ ] Función fn_expandir_consumo_ticket()

**Tareas**:
1. Diseño conceptual (2h)
2. Flujo técnico (3h)
3. Ejemplos SQL (2h)
4. Wireframes (1h)

---

### US-4.3: Crear docs/V4.0/BaseDatos/01_ESQUEMA_SELEMTI.md (6h) 🟡 ALTA

**Criterios de Aceptación**:
- [ ] ERD del esquema selemti
- [ ] Tabla de tablas (147)
- [ ] Relaciones clave

**Tareas**:
1. Generar ERD (2h)
2. Tabla de tablas (2h)
3. Documentar relaciones top 20 FK (2h)

---

### US-4.4: Crear docs/V4.0/BaseDatos/02_VISTAS_SISTEMA.md (4h) 🟡 ALTA

**Criterios de Aceptación**:
- [ ] Tabla de 38 vistas
- [ ] Propósito de cada vista
- [ ] Ejemplos de uso

**Tareas**:
1. Listar 38 vistas (1h)
2. Documentar propósito (2h)
3. Ejemplos SQL (1h)

---

**SPRINT 4 COMPLETADO**: 26 horas
**Resultado Esperado**: Cobertura Documental 76% → 85% (+9%)

---

## SPRINT 5: CÓDIGO HUÉRFANO - SERVICIOS (Semanas 9-10)

**Objetivo**: Documentar servicios críticos sin documentación.

**Esfuerzo Total**: 38 horas

### US-5.1: Documentar Servicios de Inventario (12h) 🟡 ALTA

**Tareas**:
1. `RecalcularCostosRecetasService.php` (3h)
2. `InventoryAdjustmentService.php` (3h)
3. `BatchTrackingService.php` (3h)
4. `StockPolicyService.php` (3h)

---

### US-5.2: Documentar Servicios de Caja (8h) 🟡 ALTA

**Tareas**:
1. `AlertasService.php` (4h)
2. `AnalyticsService.php` (4h)

---

### US-5.3: Documentar Servicios de POS (10h) 🟡 ALTA

**Tareas**:
1. `MenuSyncService.php` (5h)
2. `WasteTrackingService.php` (5h)

---

### US-5.4: Documentar Servicios de Producción (8h) 🟡 ALTA

**Tareas**:
1. `ProductionScheduleService.php` (4h)
2. `VendorService.php` (4h)

---

**SPRINT 5 COMPLETADO**: 38 horas
**Resultado Esperado**: Cobertura Servicios 44% → 70% (+26%)

---

## SPRINT 6: CÓDIGO HUÉRFANO - MODELOS + LIVEWIRE (Semanas 11-12)

**Objetivo**: Documentar modelos y componentes Livewire huérfanos.

**Esfuerzo Total**: 57 horas

### US-6.1: Documentar Modelos Críticos (20h) 🟡 ALTA

**Tareas**:
1. `RecipeCostSnapshot.php` (2h)
2. `PosMap.php` (2h)
3. `StockPolicy.php` (2h)
4. `Warehouse.php` (2h)
5. `Vendor.php` (2h)
6. `ProductionSchedule.php` (2h)
7. `WasteLog.php` (2h)
8. `MenuItemSync.php` (2h)
9. 4 modelos adicionales (4h)

---

### US-6.2: Documentar Componentes Livewire (18h) 🟡 ALTA

**Tareas**:
1. `OrquestadorPanel.php` (2h)
2. `BatchTrackingIndex.php` (2h)
3. `StockPolicyIndex.php` (2h)
4. `VendorIndex.php` (2h)
5. `ProductionScheduleIndex.php` (2h)
6. `WasteTrackingIndex.php` (2h)
7. `MenuSyncPanel.php` (2h)
8. 4 componentes adicionales (4h)

---

### US-6.3: Documentar Controladores API (19h) 🟡 ALTA

**Tareas**:
1. `TransferApiController.php` (3h)
2. `RecipeCostController.php` (3h)
3. `BatchTrackingController.php` (3h)
4. `StockPolicyController.php` (2h)
5. `VendorController.php` (2h)
6. `ProductionScheduleController.php` (3h)
7. `WasteTrackingController.php` (3h)

---

**SPRINT 6 COMPLETADO**: 57 horas
**Resultado Esperado**: Código Huérfano 39% → 25% (-14%)

---

## SPRINT 7: BD + UI PULIDO (Semanas 13-14)

**Objetivo**: Plan deprecación legacy + Estandarización UI.

**Esfuerzo Total**: 27 horas

### US-7.1: Plan Deprecación Tablas Legacy (12h) 🟡 ALTA

**Tareas**:
1. Documentar plan de migración (4h)
2. Scripts de migración datos (4h)
3. Marcar tablas "DEPRECATED" (2h)
4. Logging de uso (2h)

---

### US-7.2: Estandarizar Modales wire:ignore (12h) 🟢 MEDIA

**Tareas**:
1. Elegir patrón estándar (1h)
2. Migrar 15 modales (10h)
3. Documentar estándar (1h)

---

### US-7.3: Mejorar Empty States (3h) 🟢 BAJA

**Tareas**:
1. Crear componente EmptyState (1h)
2. Aplicar a 30 listas (2h)

---

**SPRINT 7 COMPLETADO**: 27 horas

---

## SPRINT 8: TESTS + DOCUMENTACIÓN FINAL (Semanas 15-16)

**Objetivo**: Incrementar cobertura tests y completar docs faltantes.

**Esfuerzo Total**: 60 horas

### US-8.1: Tests Cobertura +40% (60h) 🟡 ALTA

**Tareas**:
1. Unit tests servicios (20h)
2. Feature tests controladores (20h)
3. Browser tests flujos críticos (20h)

---

**SPRINT 8 COMPLETADO**: 60 horas
**Resultado Esperado**: Test Coverage 30% → 70% (+40%)

---

## RESUMEN TOTAL BACKLOG

| Sprint | Objetivo | Horas | Resultado |
|--------|----------|-------|-----------|
| 1 | Gaps UI/UX Críticos | 24 | UX 6.5 → 8.0 |
| 2 | Funciones BD Críticas | 31 | BD 90% → 93% |
| 3 | Docs Recetas + Producción | 26 | Docs +5% |
| 4 | Docs POS + Ventas + BD | 26 | Docs +4% |
| 5 | Servicios Huérfanos | 38 | Servicios 44% → 70% |
| 6 | Modelos + Livewire | 57 | Huérfano 39% → 25% |
| 7 | BD Legacy + UI | 27 | Estandarización |
| 8 | Tests | 60 | Tests 30% → 70% |
| **TOTAL** | **8 sprints** | **289h** | **Sistema 94% objetivo** |

**FIN BACKLOG v2 - CLAUDE**
