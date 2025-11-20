# BACKLOG & SPRINTS v2.0
## Orquestador: COPILOT
**Fecha:** 2025-11-14

---

## METODOLOGÍA

**Priorización:** Valor negocio × Impacto operativo × Riesgo técnico  
**Duración sprint:** 2 semanas  
**Criterio DONE:** Código + Tests + Docs V4.0 actualizada + Deploy dev

---

## SPRINT 0 - PREPARACIÓN (1 semana)

### Objetivos
- Ambiente desarrollo estable
- Datos de prueba mínimos
- Documentación baseline

### Tareas
- [ ] Seed BD con 50 ítems, 20 recetas, 5 proveedores
- [ ] Configurar Redis para colas
- [ ] Validar migraciones actualizadas
- [ ] Crear suite tests base por módulo
- [ ] Actualizar .env.example con todas las vars

**Entregables:**
- BD con data mínima operativa
- Tests E2E baseline (smoke tests)
- Guía setup actualizada

---

## SPRINT 1 - CONSOLIDACIÓN RECEPCIONES (P0)

### Objetivos
🔴 Resolver duplicidad servicios  
🟠 Implementar flujo validación completo

### Historias de Usuario

#### HU-1.1: Consolidar servicios recepciones
**Como** desarrollador  
**Quiero** un solo servicio de recepciones  
**Para** evitar confusión y bugs

**Tareas:**
- [ ] Auditar ReceptionService vs ReceivingService
- [ ] Definir responsabilidades únicas
- [ ] Migrar lógica a servicio único
- [ ] Actualizar controladores y Livewire
- [ ] Tests unitarios consolidados
- [ ] Docs V4.0/Inventario/Recepciones.md actualizada

**Estimación:** 5 puntos  
**Criterio:** Un solo servicio activo, otro deprecated

#### HU-1.2: Flujo BORRADOR→VALIDADA→POSTEADA
**Como** supervisor almacén  
**Quiero** validar recepciones antes de postear  
**Para** controlar calidad y discrepancias

**Tareas:**
- [ ] Agregar campo status a recepcion_cab (si no existe)
- [ ] Implementar transiciones de estado en servicio
- [ ] Validaciones por estado (permisos)
- [ ] UI: botones Validar/Postear según estado
- [ ] Triggers BD para bloquear edición POSTEADA
- [ ] Tests de flujo completo
- [ ] Docs V4.0 actualizada con flujo

**Estimación:** 8 puntos  
**Criterio:** 3 estados funcionales con validaciones

#### HU-1.3: Sistema de tolerancias
**Como** supervisor  
**Quiero** definir tolerancias por ítem/proveedor  
**Para** aceptar variaciones menores automáticamente

**Tareas:**
- [ ] Tabla tolerance_rules (item_id, vendor_id, tolerance_pct)
- [ ] Lógica validación en servicio
- [ ] UI config tolerancias por ítem
- [ ] Alertas en recepción si excede tolerancia
- [ ] Tests casos borde
- [ ] Docs V4.0 sección tolerancias

**Estimación:** 8 puntos  
**Criterio:** Tolerancias configurables y aplicadas

**Total Sprint 1:** 21 puntos (2 semanas)

---

## SPRINT 2 - MOTOR REPLENISHMENT FASE 1 (P0)

### Objetivos
🔴 Implementar algoritmo Min-Max funcional  
🔴 Dashboard sugerencias con razón

### Historias de Usuario

#### HU-2.1: Algoritmo Min-Max
**Como** comprador  
**Quiero** sugerencias automáticas basadas en Min-Max  
**Para** mantener stock óptimo

**Tareas:**
- [ ] Servicio ReplenishmentService.php
- [ ] Función calcularMinMax(item_id, sucursal_id)
- [ ] Poblar inv_stock_policy con datos prueba
- [ ] Tests algoritmo con escenarios
- [ ] Comando Artisan replenishment:calculate
- [ ] Job diario para cálculo automático
- [ ] Docs V4.0/Purchasing/Replenishment.md

**Estimación:** 13 puntos  
**Criterio:** Algoritmo calcula correctamente min-max

#### HU-2.2: Dashboard sugerencias básico
**Como** comprador  
**Quiero** ver sugerencias de pedido  
**Para** crear POs rápidamente

**Tareas:**
- [ ] Livewire ReplenishmentDashboard funcional
- [ ] Conectar a vw_replenishment_dashboard
- [ ] Tabla con: ítem, stock actual, min, max, sugerencia
- [ ] Columna "Razón" (ej: "Stock actual 5 < Min 10")
- [ ] Filtros: sucursal, categoría, urgencia
- [ ] Acción: Crear PO desde sugerencias
- [ ] Tests E2E dashboard
- [ ] Docs V4.0 con capturas UI

**Estimación:** 13 puntos  
**Criterio:** Dashboard muestra sugerencias con razón

#### HU-2.3: API sugerencias REST
**Como** sistema externo  
**Quiero** consumir sugerencias vía API  
**Para** integrar con otros sistemas

**Tareas:**
- [ ] Endpoint GET /api/purchasing/suggestions
- [ ] Parámetros: sucursal, fecha, categoría
- [ ] Response JSON con sugerencias + razón
- [ ] Middleware auth:sanctum
- [ ] Tests API
- [ ] Docs V4.0 endpoints

**Estimación:** 5 puntos  
**Criterio:** Endpoint funcional y documentado

**Total Sprint 2:** 31 puntos (2 semanas + buffer)

---

## SPRINT 3 - VERSIONADO RECETAS (P0)

### Objetivos
🟠 Versionado real funcional  
🟠 UI comparación versiones

### Historias de Usuario

#### HU-3.1: Lógica versionado
**Como** chef  
**Quiero** crear múltiples versiones de receta  
**Para** probar cambios sin afectar la actual

**Tareas:**
- [ ] Modificar RecipeEditor para manejar versiones
- [ ] Botón "Nueva versión" crea version+1
- [ ] Al guardar, incrementa version automáticamente
- [ ] Selector de versión en editor
- [ ] Campo active en receta_version
- [ ] Solo 1 versión activa por receta
- [ ] Tests versionado
- [ ] Docs V4.0/Recetas actualizada

**Estimación:** 13 puntos  
**Criterio:** Editor maneja múltiples versiones

#### HU-3.2: UI comparación versiones
**Como** chef  
**Quiero** comparar 2 versiones lado a lado  
**Para** ver diferencias antes de activar

**Tareas:**
- [ ] Componente Livewire RecipeCompare
- [ ] Vista diff ingredientes (agregados/eliminados/modificados)
- [ ] Vista diff costos entre versiones
- [ ] Botón "Activar versión"
- [ ] Historial de cambios
- [ ] Tests UI
- [ ] Docs V4.0 con casos uso

**Estimación:** 13 puntos  
**Criterio:** Comparador funcional con diff claro

#### HU-3.3: Activar/desactivar versiones
**Como** gerente  
**Quiero** activar versión específica  
**Para** aplicar cambios en producción

**Tareas:**
- [ ] Lógica desactivar versión actual
- [ ] Lógica activar nueva versión
- [ ] Validación: solo 1 activa a la vez
- [ ] Propagación de cambios (recosteo si aplica)
- [ ] Permisos recipes.versions.activate
- [ ] Auditoría de cambios de versión
- [ ] Tests permisos y validaciones
- [ ] Docs V4.0 sección activación

**Estimación:** 8 puntos  
**Criterio:** Activación segura con validaciones

**Total Sprint 3:** 34 puntos (2 semanas + buffer)

---

## SPRINT 4 - PRODUCCIÓN UI OPERATIVA (P1)

### Objetivos
🟡 Panel operativo producción  
🟡 Registro mermas producción

### Historias de Usuario

#### HU-4.1: CRUD órdenes producción
**Como** jefe cocina  
**Quiero** crear órdenes de producción  
**Para** planificar mise en place

**Tareas:**
- [ ] Livewire ProductionOrders/Index
- [ ] Livewire ProductionOrders/Create
- [ ] Livewire ProductionOrders/Detail
- [ ] Conectar a ProductionService existente
- [ ] Estados: PLANIFICADA, EN_PROCESO, COMPLETADA
- [ ] UI selección receta + cantidad
- [ ] Cálculo automático ingredientes
- [ ] Tests CRUD
- [ ] Docs V4.0/Produccion UI operativa

**Estimación:** 13 puntos  
**Criterio:** CRUD completo funcional

#### HU-4.2: Dashboard producción
**Como** supervisor cocina  
**Quiero** ver órdenes del día  
**Para** monitorear producción

**Tareas:**
- [ ] Livewire ProductionDashboard
- [ ] Vista órdenes por estado
- [ ] Filtros: fecha, receta, estado
- [ ] Acción: Cambiar estado orden
- [ ] KPIs: órdenes completadas, pendientes, tardías
- [ ] Tests dashboard
- [ ] Docs V4.0 dashboard

**Estimación:** 8 puntos  
**Criterio:** Dashboard con KPIs en tiempo real

#### HU-4.3: Registro mermas en producción
**Como** cocinero  
**Quiero** registrar mermas durante producción  
**Para** ajustar inventario real

**Tareas:**
- [ ] Campo mermas en production_orders
- [ ] Relación production_orders → inventory_wastes
- [ ] UI captura mermas al completar orden
- [ ] Catálogo motivos (DAÑO, SOBREPRODUCCIÓN, etc)
- [ ] Movimiento automático mov_inv al registrar
- [ ] Validación permisos
- [ ] Tests flujo completo
- [ ] Docs V4.0/Mermas sección producción

**Estimación:** 8 puntos  
**Criterio:** Mermas registradas y reflejadas en inventario

**Total Sprint 4:** 29 puntos (2 semanas)

---

## SPRINT 5 - MOTOR REPLENISHMENT FASE 2 (P0)

### Objetivos
🔴 Algoritmos SMA y POS Consumption  
🔴 Combinación políticas

### Historias de Usuario

#### HU-5.1: Algoritmo SMA (Simple Moving Average)
**Como** comprador  
**Quiero** sugerencias basadas en promedio consumo  
**Para** ítems sin min-max definido

**Tareas:**
- [ ] Función calcularSMA(item_id, dias=30)
- [ ] Consulta consumo histórico mov_inv
- [ ] Cálculo promedio + desviación estándar
- [ ] Sugerencia = SMA * días_leadtime * 1.2 (buffer)
- [ ] Tests con datos históricos
- [ ] Integrar en ReplenishmentService
- [ ] Docs V4.0 algoritmo SMA

**Estimación:** 13 puntos  
**Criterio:** SMA calcula correctamente con histórico

#### HU-5.2: Algoritmo POS Consumption
**Como** comprador  
**Quiero** sugerencias basadas en ventas POS  
**Para** ítems con demanda variable

**Tareas:**
- [ ] Función calcularPOSConsumption(item_id)
- [ ] Consulta inv_consumo_pos histórico
- [ ] Proyección consumo próximos N días
- [ ] Considerar estacionalidad (día semana, eventos)
- [ ] Tests con patrones consumo
- [ ] Integrar en ReplenishmentService
- [ ] Docs V4.0 algoritmo POS

**Estimación:** 13 puntos  
**Criterio:** Consumo POS proyecta demanda

#### HU-5.3: Combinación políticas por ítem
**Como** comprador  
**Quiero** configurar política por ítem  
**Para** usar mejor algoritmo según tipo

**Tareas:**
- [ ] Campo policy_type en inv_stock_policy (MIN_MAX, SMA, POS_CONSUMPTION, MANUAL)
- [ ] UI config política en catálogo ítems
- [ ] ReplenishmentService selecciona algoritmo según policy_type
- [ ] Razón indica qué algoritmo usó
- [ ] Tests combinación políticas
- [ ] Docs V4.0 combinación

**Estimación:** 8 puntos  
**Criterio:** Política configurable por ítem

**Total Sprint 5:** 34 puntos (2 semanas + buffer)

---

## SPRINT 6 - TRANSFERENCIAS COMPLETAS (P1)

### Objetivos
🟡 Estados completos flujo  
🟡 API REST transferencias

### Historias de Usuario

#### HU-6.1: Estados BORRADOR → RECIBIDA
**Como** almacenista  
**Quiero** flujo completo de transferencias  
**Para** trazabilidad entre almacenes

**Tareas:**
- [ ] Actualizar TransferService con 5 estados
- [ ] Transiciones validadas por estado
- [ ] Permisos por estado (transfers.approve, transfers.dispatch, etc)
- [ ] UI botones según estado actual
- [ ] Movimientos mov_inv solo al RECIBIR
- [ ] Tests flujo completo
- [ ] Docs V4.0/Inventario/Transferencias actualizada

**Estimación:** 13 puntos  
**Criterio:** 5 estados funcionales con validaciones

#### HU-6.2: API REST transferencias
**Como** sistema externo  
**Quiero** gestionar transferencias vía API  
**Para** integración multi-almacén

**Tareas:**
- [ ] POST /api/inventory/transfers (crear)
- [ ] GET /api/inventory/transfers (listar)
- [ ] GET /api/inventory/transfers/{id} (detalle)
- [ ] PATCH /api/inventory/transfers/{id}/status (cambiar estado)
- [ ] Tests API
- [ ] Middleware auth:sanctum + permisos
- [ ] Docs V4.0 endpoints

**Estimación:** 8 puntos  
**Criterio:** CRUD REST completo funcional

#### HU-6.3: Notificaciones transferencias
**Como** almacenista destino  
**Quiero** notificación de transferencias entrantes  
**Para** prepararme a recibir

**Tareas:**
- [ ] Evento TransferDispatched
- [ ] Listener notifica almacén destino
- [ ] Notificación in-app (bell icon)
- [ ] Opcional: email si configurado
- [ ] Tests notificaciones
- [ ] Docs V4.0 notificaciones

**Estimación:** 5 puntos  
**Criterio:** Notificación recibida al despachar

**Total Sprint 6:** 26 puntos (2 semanas)

---

## SPRINT 7 - MEJORAS UI/UX (P2)

### Objetivos
🟡 UI ajustes rápidos mermas  
🟡 GUI permisos  
🟡 Exportaciones avanzadas

### Historias de Usuario

#### HU-7.1: UI ajustes rápidos mermas
**Como** almacenista  
**Quiero** registrar mermas en 3 clics  
**Para** agilizar operación diaria

**Tareas:**
- [ ] Componente Livewire QuickWaste
- [ ] Modal: seleccionar ítem + cantidad + motivo
- [ ] Validación stock disponible
- [ ] Movimiento automático mov_inv
- [ ] Registro inventory_wastes
- [ ] Tests UI
- [ ] Docs V4.0/Inventario/Mermas UI rápida

**Estimación:** 8 puntos  
**Criterio:** Merma registrada en < 30 segundos

#### HU-7.2: GUI gestión permisos
**Como** administrador  
**Quiero** asignar permisos visualmente  
**Para** no usar Tinker

**Tareas:**
- [ ] Livewire PermissionsManager
- [ ] Vista matriz: Roles × Permisos
- [ ] Checkboxes para asignar/quitar
- [ ] Búsqueda y filtros
- [ ] Validación permisos admin
- [ ] Tests permisos
- [ ] Docs V4.0/Seguridad GUI

**Estimación:** 13 puntos  
**Criterio:** Matriz visual funcional

#### HU-7.3: Exportaciones PDF avanzadas
**Como** gerente  
**Quiero** exportar reportes a PDF con logo  
**Para** presentaciones profesionales

**Tareas:**
- [ ] Servicio PdfExportService
- [ ] Templates Blade para reports
- [ ] Logo empresa en header
- [ ] Botón "Exportar PDF" en reportes
- [ ] Tests generación PDF
- [ ] Docs V4.0/Reports exportaciones

**Estimación:** 8 puntos  
**Criterio:** PDFs con formato profesional

**Total Sprint 7:** 29 puntos (2 semanas)

---

## SPRINT 8 - POLISH & DEUDA TÉCNICA (P2-P3)

### Objetivos
🟡 API POS en routes  
🟢 Recetas shadow UI  
🟢 Cleanup legacy

### Historias de Usuario

#### HU-8.1: Exponer API POS Recipe Cost
**Como** sistema POS  
**Quiero** consultar costo recetas vía API  
**Para** calcular márgenes

**Tareas:**
- [ ] Registrar RecipeCostController en routes/api.php
- [ ] GET /api/pos/recipe-cost/{id}
- [ ] Middleware auth:sanctum
- [ ] Tests endpoint
- [ ] Docs V4.0/POS endpoints

**Estimación:** 3 puntos  
**Criterio:** Endpoint funcional y documentado

#### HU-8.2: UI recetas shadow
**Como** chef  
**Quiero** validar recetas inferidas del POS  
**Para** corregir mapeos incorrectos

**Tareas:**
- [ ] Livewire RecipesShadow/Index
- [ ] Listado recetas inferidas
- [ ] Acción: Aprobar (crear receta real)
- [ ] Acción: Rechazar (eliminar shadow)
- [ ] Tests UI
- [ ] Docs V4.0/Recetas shadow

**Estimación:** 8 puntos  
**Criterio:** Validación recetas shadow funcional

#### HU-8.3: Migrar Bootstrap → Tailwind
**Como** desarrollador  
**Quiero** UI 100% Tailwind  
**Para** consistencia visual

**Tareas:**
- [ ] Auditar componentes con Bootstrap legacy
- [ ] Reemplazar clases Bootstrap por Tailwind
- [ ] Remover Bootstrap de package.json
- [ ] Tests visuales (screenshots)
- [ ] Docs V4.0/Frontend actualizada

**Estimación:** 13 puntos  
**Criterio:** Sin Bootstrap en código

#### HU-8.4: Cleanup docs legacy
**Como** desarrollador  
**Quiero** solo docs V4.0 activas  
**Para** evitar confusión

**Tareas:**
- [ ] Mover docs/V2, docs/V3 → docs/00.history/
- [ ] Actualizar referencias en código
- [ ] README.md apunta solo a V4.0
- [ ] Tests rutas docs
- [ ] Commit limpieza

**Estimación:** 5 puntos  
**Criterio:** Solo V4.0 en docs/ activo

**Total Sprint 8:** 29 puntos (2 semanas)

---

## BACKLOG FUTURO (Post V2.0)

### Performance
- [ ] Índices BD optimizados (vw_kardex, vw_dashboard_*)
- [ ] Cache Redis para reportes pesados
- [ ] Paginación lazy loading catálogos grandes

### Integraciones
- [ ] Webhook notificaciones Slack/Teams
- [ ] API Facturación electrónica
- [ ] Sincronización multi-sucursal

### Avanzado
- [ ] Planificación producción con IA
- [ ] Predicción demanda ML
- [ ] App móvil conteos físicos

---

## RESUMEN ROADMAP

| Sprint | Duración | Puntos | Prioridad | Módulo Principal |
|--------|----------|--------|-----------|------------------|
| S0 | 1 sem | - | Setup | Preparación |
| S1 | 2 sem | 21 | P0 | Inventario - Recepciones |
| S2 | 2 sem | 31 | P0 | Compras - Replenishment F1 |
| S3 | 2 sem | 34 | P0 | Recetas - Versionado |
| S4 | 2 sem | 29 | P1 | Producción - UI |
| S5 | 2 sem | 34 | P0 | Compras - Replenishment F2 |
| S6 | 2 sem | 26 | P1 | Inventario - Transferencias |
| S7 | 2 sem | 29 | P2 | UI/UX - Mejoras |
| S8 | 2 sem | 29 | P2-P3 | Polish & Deuda |
| **TOTAL** | **17 sem** | **233 puntos** | | **V2.0 Release** |

**Release V2.0:** Estimado 4-5 meses  
**Velocity estimado:** 15-18 puntos/semana

---

**FIN BACKLOG v2.0 - COPILOT**
