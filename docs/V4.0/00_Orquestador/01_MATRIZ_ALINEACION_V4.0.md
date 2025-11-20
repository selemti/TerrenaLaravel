# MATRIZ DE ALINEACIÓN V4.0

**Orquestador**: MAESTRO (Consolidación CLAUDE + QWEN + CODEX + COPILOT)
**Fecha**: 14 Noviembre 2025
**Fuente**: FASE1-FASE6 + 4 Orquestadores
**Estado**: Consolidado v4.0

---

## 1. INTRODUCCIÓN

Esta matriz consolida el estado actual del sistema Terrena POS/ERP a través de los 15 módulos identificados, evaluando su alineación entre documentación, código implementado, base de datos y UI/UX. La información proviene de la fusión del trabajo de 4 agentes de IA (CLAUDE, QWEN, CODEX, COPILOT), la auditoría completa del sistema (FASE1-FASE6) y la documentación específica de deployment.

### 1.1 Metodología de Evaluación

Cada módulo se evalúa según 4 dimensiones:
- **Documentación**: Estado actual en docs/V4.0/ (0-100%)
- **Código**: Implementación en app/, resources/, etc. (0-100%)
- **Base de Datos**: Tablas, vistas, funciones relacionadas en esquema selemti (0-100%)
- **UI/UX**: Interfaces, flujos, componentes disponibles (0-100%)

### 1.2 Leyenda de Prioridades

| Prioridad | Color | Criterio |
|-----------|-------|----------|
| **P0 - Crítica** | 🔴 | Funcionalidad core, requerida para operación |
| **P1 - Alta** | 🟡 | Funcionalidad importante, mejora operación |
| **P2 - Media** | 🟢 | Funcionalidad complementaria o futura |

### 1.3 Estados de Alineación

- ✅ **Completo**: Funcionalidad 90-100% alineada entre docs, código, BD y UI
- ⚠️ **Parcial**: Funcionalidad 50-89% alineada, con gaps identificados
- ❌ **Faltante**: Funcionalidad <50% alineada o no implementada

---

## 2. MÓDULO: INVENTARIO

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 80% | Inventario/ (Items, Recepciones, Conteos, Transferencias, Mermas) | Ajustes, Kardex, Políticas |
| **Código** | 85% | 12 servicios, 15 modelos, 8 Livewire (inventory/*) | Ajustes parcial, Kardex no documentado |
| **Base de Datos** | 90% | items, mov_inv, inventory_batch, stock, lotes | vw_kardex_detalle pendiente |
| **UI/UX** | 80% | 18 vistas Blade, componentes Livewire | Ajustes sin UI, Kardex sin detalle |

**Promedio de Alineación**: 84% | **Prioridad**: 🔴 P0

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Alta de ítems | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Recepciones - Wizard | ✅ | ✅ | ✅ | ✅ | ⚠️ | Falta flujo BORRADOR→VALIDADA→POSTEADA | 🟠 |
| Recepciones - Tolerancias | ✅ | ❌ | ⚠️ | ❌ | ❌ | Sistema tolerancias no implementado | 🟠 |
| Recepciones - Evidencias | ✅ | ❌ | ❌ | ❌ | ❌ | Carga fotos/docs no implementada | 🟡 |
| Recepciones - Vinculación PO | ✅ | ❌ | ⚠️ | ❌ | ❌ | Recepciones independientes de POs | 🟡 |
| Transferencias - Estados | ✅ | ⚠️ | ✅ | ⚠️ | ❌ | Solo 2 de 5 estados | 🟡 |
| Transferencias - API REST | ✅ | ❌ | ✅ | ❌ | ❌ | Endpoints no implementados | 🟡 |
| Conteos físicos | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conteos - Vista teórica | ✅ | ❌ | ⚠️ | ❌ | ❌ | Vista stock teórico faltante | 🟡 |
| Mermas - Básico | ✅ | ⚠️ | ✅ | ⚠️ | ⚠️ | Funcionalidad limitada | 🟡 |
| Mermas - UI rápida | ✅ | ❌ | ✅ | ❌ | ❌ | UI ajustes rápidos faltante | 🟡 |
| Mermas - Motivos | ✅ | ❌ | ❌ | ❌ | ❌ | Catálogo motivos sin implementar | 🟡 |
| Kardex | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| KPIs disponibilidad | ✅ | ⚠️ | ✅ | ⚠️ | ⚠️ | No todos KPIs conectados | 🟡 |
| Stock valorizado | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |

### Insights por Agente

- **[CLAUDE]**: Buen soporte para recepciones y conteos, faltan 4 docs (Lotes, Kardex, Ajustes, Políticas)
- **[QWEN]**: Interacción con Recetas y Producción fundamental, flujos incompletos BORRADOR → VALIDADA → POSTEADA
- **[CODEX]**: 82 tablas huérfanas, integración con POS, falta política de reorden y ajustes manuales
- **[COPILOT]**: FEFO implementado en vw_stock_por_lote_fefo, BatchTrackingService sin doc

### Archivos Clave

- docs/V4.0/Inventario/Items.md (parcial)
- app/Models/Inv/* (Item, Batch, MovimientoInventario)
- app/Services/Inventory/ReceptionService.php, BatchTrackingService.php
- app/Livewire/Inventory/* (ItemsIndex, ReceptionsIndex, 8 componentes)
- selemti.items (152 kB, 6 activos), mov_inv (104 kB, 0 registros)

### Gaps Críticos

1. 4 docs faltantes: Lotes, Kardex, Ajustes, Políticas
2. InventoryAdjustmentService.php sin doc
3. BatchTrackingService.php sin doc
4. 8 componentes Livewire sin doc
5. Forms sin loading states
6. Empty states sin gráficos

### Deployment Considerations

- Verificar funcionalidad en entorno producción (http://100.126.124.101/terrena2/)
- Validar acceso a módulo con diferentes roles
- Asegurar FEFO funcional en producción

---

## 3. MÓDULO: RECETAS

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 70% | Recetas/README.md (135 líneas) | Versionado, Costeo, BOM Implosion |
| **Código** | 75% | RecetaCab, RecetaDet, RecetaVersion modelos | Costeo sin UI, Versionado sin historial |
| **Base de Datos** | 85% | receta_cab, receta_det, receta_version, receta_insumo, recipe_cost_snapshots | Naming duplicado (receta_version vs recipe_versions) |
| **UI/UX** | 70% | RecipeEditor, RecipesIndex | Costeo sin UI, Versionado sin historial |

**Promedio de Alineación**: 75% | **Prioridad**: 🔴 P0

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Editor básico | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Subrecetas | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Versionado - Estructura | ✅ | ✅ | ✅ | ❌ | ❌ | UI versionado no implementada | 🟠 |
| Versionado - Lógica | ✅ | ❌ | ✅ | ❌ | ❌ | Editor solo version=1 | 🟠 |
| Versionado - Comparación | ✅ | ❌ | ⚠️ | ❌ | ❌ | Comparador faltante | 🟡 |
| Versionado - Activar/desactivar | ✅ | ❌ | ⚠️ | ❌ | ❌ | Control versiones faltante | 🟡 |
| Costeo automático | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Costeo histórico | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | API no expuesta | 🟡 |
| Snapshots | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Job no programado | 🟡 |
| Recálculo masivo | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin UI manual | 🟡 |
| Catálogo UOM | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conversiones | ✅ | ✅ | ✅ | ✅ | ⚠️ | UI inconsistente props | 🟡 |
| Función conversión | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Recetas Shadow - Tabla | ⚠️ | ⚠️ | ✅ | ❌ | ❌ | UI validación faltante | 🟢 |
| Recetas Shadow - Inferencia | ⚠️ | ✅ | ✅ | ❌ | ❌ | Proceso sin UI | 🟢 |
| Sincronización POS | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin UI sync | 🟡 |

### Insights por Agente

- **[CLAUDE]**: Falta sistema de versionado automático, doc muy breve (135 líneas)
- **[QWEN]**: Conexión con Producción y POS fundamental, BOM implodado no completamente funcional
- **[CODEX]**: fn_recipe_cost_at() sin documentar, redactar BOMImplosion y IntegracionPOS
- **[COPILOT]**: Recetas usadas en POS vía pos_map, versionado BD lista pero lógica ausente

### Archivos Clave

- docs/V4.0/Recetas/README.md (135 líneas, muy breve)
- app/Models/Rec/* (Receta, RecetaDetalle, RecetaVersion)
- app/Livewire/Recipes/* (RecipesIndex, RecipeEditor)
- selemti.receta_cab (56 kB), receta_version (40 kB), recipe_cost_snapshots (32 kB)

### Gaps Críticos

1. Documentación muy breve (135 líneas para módulo complejo)
2. Sistema versionado no documentado, UI no existe
3. Naming duplicado: receta_version vs recipe_versions
4. RecipeCostSnapshot modelo huérfano
5. BOM Implosion no completamente funcional

### Deployment Considerations

- fn_recipe_cost_at() crítico para operación en producción
- Requiere vistas específicas en BD para cálculo de costos
- Versionado debe funcionar en producción

---

## 4. MÓDULO: PRODUCCIÓN

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 55% | Produccion/README.md (100 líneas) | Planificación, Mise en Place, Mermas |
| **Código** | 60% | ProductionService (2 ubicaciones!), production_orders | KPIs, Mermas sin UI completa |
| **Base de Datos** | 70% | prod_cab, prod_det, production_orders | Sin vistas analíticas, 4 tablas vacías |
| **UI/UX** | 65% | Produccion/Kds/Board | KPIs, Rendimiento sin UI, panel operativo no existe |

**Promedio de Alineación**: 63% | **Prioridad**: 🟡 P1

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Servicio backend | ✅ | ✅ | ✅ | ❌ | ❌ | UI operativa no implementada | 🟡 |
| API REST | ✅ | ⚠️ | ✅ | ❌ | ❌ | Endpoints no completos | 🟡 |
| CRUD órdenes | ✅ | ✅ | ✅ | ❌ | ❌ | UI CRUD faltante | 🟡 |
| KPIs rendimiento | ✅ | ❌ | ⚠️ | ❌ | ❌ | Dashboard KPIs faltante | 🟡 |
| Mermas producción | ✅ | ⚠️ | ✅ | ❌ | ❌ | Registro no implementado | 🟡 |
| Mise en place | ⚠️ | ❌ | ❌ | ❌ | ❌ | No en scope actual | 🟢 |

### Insights por Agente

- **[CLAUDE]**: KDS implementado pero sin KPIs, ProductionService DUPLICADO (2 ubicaciones)
- **[QWEN]**: Conexión con Inventario y Recetas clave, UI operativa pendiente
- **[CODEX]**: Falta control de mermas y rendimiento, estados OP no migrados
- **[COPILOT]**: Integra con Recetas para explosion/implosion, backend existe pero UI no

### Archivos Clave

- docs/V4.0/Produccion/README.md (100 líneas, muy breve)
- app/Models/OrdenProduccion.php, ProductionSchedule.php
- app/Services/ProductionService.php (2 ubicaciones!)
- selemti.production_orders (72 kB), op_cab (30 kB)

### Gaps Críticos

1. ProductionService.php DUPLICADO (2 ubicaciones)
2. Documentación mínima (100 líneas)
3. UI operativa NO EXISTE
4. 4 tablas sin uso (op_produccion_cab, sol_prod_*, prod_*)
5. Módulo 60% implementado

### Deployment Considerations

- Validar funcionalidad KDS en entorno de producción
- Verificar integración con Inventario y Recetas
- Consolidar ProductionService antes de deployment

---

## 5. MÓDULO: PURCHASING

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 85% | Purchasing/README.md | Replenishment incompleto |
| **Código** | 85% | PurchasingService, ReceivingService | Motor de reposición sin UI, PurchaseRequest duplicado |
| **Base de Datos** | 90% | purchase_requests, purchase_orders, purchase_suggestions | replenishment_suggestions parcial |
| **UI/UX** | 80% | Componentes Purchasing/* | Dashboard de reposición sin UI |

**Promedio de Alineación**: 85% (31% sin motor replenishment) | **Prioridad**: 🔴 P0

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Solicitudes CRUD | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| POs CRUD | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Cotizaciones | ✅ | ❌ | ❌ | ❌ | ❌ | Módulo faltante | 🟡 |
| Devoluciones | ✅ | ⚠️ | ❌ | ❌ | ❌ | Módulo incompleto | 🟡 |
| Políticas stock | ✅ | ❌ | ✅ | ❌ | ❌ | Motor completo no implementado | 🔴 |
| Algoritmo Min-Max | ✅ | ❌ | ⚠️ | ❌ | ❌ | No implementado | 🔴 |
| Algoritmo SMA | ✅ | ❌ | ⚠️ | ❌ | ❌ | No implementado | 🔴 |
| POS Consumption | ✅ | ❌ | ⚠️ | ❌ | ❌ | Algoritmo no implementado | 🔴 |
| Dashboard sugerencias | ✅ | ❌ | ✅ | ❌ | ❌ | No implementado | 🔴 |
| Razón cálculo | ✅ | ❌ | ❌ | ❌ | ❌ | Trazabilidad faltante | 🔴 |
| Simulador costo | ✅ | ❌ | ⚠️ | ❌ | ❌ | Faltante | 🟡 |
| API Sugerencias | ✅ | ⚠️ | ❌ | ❌ | ❌ | No implementada | 🔴 |
| Recepciones duplicadas | ✅ | ⚠️ | ✅ | ⚠️ | ❌ | Servicio duplicado | 🟡 |

### Insights por Agente

- **[CLAUDE]**: Motor de reposición pendiente, PurchaseRequest duplicado
- **[QWEN]**: Conexión con Inventario y Catálogos, motor replenishment no implementado
- **[CODEX]**: 90 registros en purchase_suggestions, fase 2 pendiente
- **[COPILOT]**: Replenishment engine con múltiples algoritmos pendientes, **31% alineación CRÍTICO**

### Archivos Clave

- docs/V4.0/Purchasing/01_REQUISICIONES.md
- docs/V4.0/Purchasing/02_ORDENES.md
- app/Models/Purchasing/PurchaseRequest.php (2 ubicaciones!)
- app/Services/Purchasing/PurchasingService.php (Codex)
- app/Livewire/Purchasing/Requests/* (3 componentes)
- selemti.purchase_requests (64 kB), purchase_orders (40 kB)

### Gaps Críticos

1. **Motor Replenishment 0% implementado** (CRÍTICO)
2. PurchaseRequest.php duplicado (app/Models/ y app/Models/Purchasing/)
3. Doc de Reposición Automática faltante
4. Comparación de cotizaciones manual
5. 7 algoritmos y features de replenishment sin implementar

### Deployment Considerations

- Validar motor de reposición con datos históricos
- Asegurar migraciones completas en producción
- Consolidar PurchaseRequest antes de deployment

---

## 6. MÓDULO: POS

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 60% | POS/README.md (110 líneas) | Consumos, Sincronización, Repositorios |
| **Código** | 70% | PosConsumptionService (triplicado!), ticket_venta_* | Integración inconsistente, 5 repos sin doc |
| **Base de Datos** | 80% | ticket_venta_cab, ticket_venta_det, pos_map | Sin vistas consolidadas, 10 tablas sin modelo |
| **UI/UX** | 70% | Parcial en Floreant | No hay UI propia, sync básica |

**Promedio de Alineación**: 70% | **Prioridad**: 🟡 P1

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Mapeo POS-Recetas | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Mapeo modificadores | ✅ | ⚠️ | ✅ | ❌ | ❌ | UI faltante | 🟡 |
| Consumo automático | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | UI limitada | 🟡 |
| Fn confirmar | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin UI directa | 🟢 |
| Fn expandir | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin UI directa | 🟢 |
| Fn reversar | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin UI directa | 🟡 |
| Reproceso tickets | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | UI faltante | 🟡 |
| Auditoría consumos | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Dashboard limitado | 🟡 |
| API Recipe Cost | ⚠️ | ✅ | ✅ | ❌ | ❌ | No en routes | 🟡 |
| Sync batches | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | UI sync faltante | 🟢 |

### Insights por Agente

- **[CLAUDE]**: Duplicación de PosConsumptionService crítico (3 ubicaciones)
- **[QWEN]**: Integra con Recetas y Reportes, endpoints no expuestos en rutas
- **[CODEX]**: 3 ubicaciones de PosConsumptionService, endpoints sin exponer
- **[COPILOT]**: Mapeo productos a recetas via pos_map, expansión vía fn_expandir_consumo_ticket

### Archivos Clave

- docs/V4.0/POS/README.md (110 líneas, muy breve)
- app/Models/Pos/* (Ticket, MenuItem, MenuCategory)
- app/Services/PosConsumptionService.php (3 ubicaciones!)
- app/Repositories/Pos/* (5 repositorios sin doc)
- selemti.pos_map (40 kB), pos_sync_logs (32 kB), menu_items (24 kB)

### Gaps Críticos

1. PosConsumptionService.php TRIPLICADO (CRÍTICO)
2. Documentación muy breve (110 líneas)
3. 5 repositorios sin documentar
4. 10 tablas sin modelo (pos_sync_logs, pos_reprocess_log, etc.)
5. UI sincronización básica

### Deployment Considerations

- Consolidar PosConsumptionService en producción
- Asegurar que pos_map esté sincronizado
- fn_expandir_consumo_ticket() funcional en producción

---

## 7. MÓDULO: VENTAS

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 75% | Reportes/README.md, ventas mencionadas | Ventas como módulo separado |
| **Código** | 80% | Ventas en Reports/, POS integración | Sin modelo dedicado |
| **Base de Datos** | 85% | ticket_venta_*, pos_*, sesion_cajon | Sin vistas analíticas |
| **UI/UX** | 80% | Reportes con ventas | Sin dashboard dedicado |

**Promedio de Alineación**: 80% | **Prioridad**: 🔴 P0

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Tickets | ⚠️ | ✅ | ✅ | ⚠️ | ⚠️ | UI de análisis | 🟡 |
| Consumos | ⚠️ | ✅ | ✅ | ⚠️ | ⚠️ | UI de análisis | 🟡 |

### Insights por Agente

- **[CLAUDE]**: Debe integrarse con Reportes
- **[QWEN]**: Conexión con Caja, Inventario fundamental
- **[CODEX]**: 150+ vistas de reportes de ventas, mantener en history
- **[COPILOT]**: Expansión consumos POS vía fn_expandir_consumo_ticket

### Deployment Considerations

- Validar expansión de tickets POS en producción
- Verificar vistas analíticas de ventas
- fn_expandir_consumo_ticket() debe estar funcional

---

## 8. MÓDULO: CAJA

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 95% | Caja/HistoricoCortes.md, Caja/REDIRECCION_DETALLE_A_WIZARD.md | Cortes analíticos |
| **Código** | 95% | 8 controladores Api/Caja/, 12 modelos | UI mejoras UX |
| **Base de Datos** | 95% | sesion_cajon, precorte, postcorte, formas_pago | Completos |
| **UI/UX** | 90% | Componentes Caja/* | Loading, notificaciones |

**Promedio de Alineación**: 94% | **Prioridad**: ✅ P0

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Fondos CRUD | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Movimientos CRUD | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Arqueos | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Precorte | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Precorte trigger | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin visibilidad UI | 🟢 |
| Postcorte | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Postcorte trigger | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin visibilidad UI | 🟢 |
| Sesiones cajón | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conciliación efectivo | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conciliación tarjetas | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conciliación sesiones | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Histórico UI | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Alertas cortes | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Dashboard mejorable | 🟡 |
| AlertasService | ⚠️ | ✅ | ✅ | ✅ | ⚠️ | Sin documentar | 🟡 |

### Insights por Agente

- **[CLAUDE]**: Excelente implementación, AlertasService sin doc
- **[QWEN]**: Conexión con Finanzas
- **[CODEX]**: 200+ registros en sesion_cajon, 95% completo
- **[COPILOT]**: Triggers precorte/postcorte funcionando, **módulo mejor alineado (96%)**

### Archivos Clave

- docs/V4.0/Caja/* (3 docs)
- app/Http/Controllers/Api/Caja/* (3 controllers)
- app/Helpers/CajaHelper.php
- selemti.sesion_cajon (152 kB, 132 sesiones)
- resources/views/caja/_wizard_modals.blade.php

### Deployment Considerations

- Validar sesiones de caja en producción
- Verificar triggers precorte/postcorte
- Asegurar permisos adecuados para cortes

---

## 9. MÓDULO: CAJA CHICA

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 100% | CajaChica docs en docs/00.history/ | Migrar a Finanzas |
| **Código** | 100% | CashFundService, 6 modelos, 6 Livewire | Completos |
| **Base de Datos** | 100% | cash_funds, cash_fund_movements, cash_fund_arqueos | Completos |
| **UI/UX** | 100% | UI completa y funcional | Completos |

**Promedio de Alineación**: 100% | **Prioridad**: ✅ P0

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Fondo de Caja | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Movimientos | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Arqueos | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Cierres Diarios | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |

### Insights por Agente

- **[CLAUDE]**: Módulo modelo, excelente implementación
- **[QWEN]**: Flujo 6 pasos bien implementado
- **[CODEX]**: 400+ registros, 100% completo
- **[COPILOT]**: 6 componentes Livewire, 3 modelos críticos, **módulo mejor alineado**

### Archivos Clave

- docs/CajaChica/FondoCaja/CAJA_CHICA_LIFECYCLE.md
- app/Models/CashFund.php
- app/Services/CashFundService.php
- app/Livewire/CashFund/* (6 componentes)
- selemti.cash_funds (96 kB, 1 registro)

### Deployment Considerations

- Validar flujo completo en entorno de producción
- Verificar funcionamiento de CashFundService
- Asegurar que las transacciones se registren correctamente

---

## 10. MÓDULO: REPORTES

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 90% | Reports/README.md | KPIs analíticos, catálogo v9 |
| **Código** | 90% | 8 controladores, 12 vistas | KPIs avanzados, exportaciones |
| **Base de Datos** | 95% | 38 vistas vw_dashboard_* | Completos |
| **UI/UX** | 90% | Dashboard completo | UX refinada, exportaciones |

**Promedio de Alineación**: 94% | **Prioridad**: ✅ P0

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Dashboard principal | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| KPIs sucursal | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| KPIs terminal | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas detalle | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas resumen | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas balance | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas excepciones | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas mix | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Journal | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Menu usage | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Stock valorizado | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Consumo vs movimientos | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Anomalías | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ticket promedio | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas por hora | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Export PDF | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | Incompletas | 🟡 |
| Export XLSX | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | Incompletas | 🟡 |
| DrillDown | ⚠️ | ✅ | ⚠️ | ⚠️ | ⚠️ | Limitado | 🟡 |

### Insights por Agente

- **[CLAUDE]**: Buen soporte analítico, 10 vistas BD sin doc individual
- **[QWEN]**: Conexión con todos módulos, KPIs visualización incompleta
- **[CODEX]**: 38 vistas de dashboard, incorporar catálogo v9
- **[COPILOT]**: KPIs en tiempo real, 15 de 18 completos

### Archivos Clave

- docs/Reports/RESUMEN_COMPLETO_REPORTES_2025_11_04.md
- docs/Migraciones/MIGRACIONES_COMPLETADAS_2025_11_05.md
- selemti.vw_sesion_dpr, vw_dashboard_*, vw_report_sales_*
- database/migrations/* (77 migraciones UOM)

### Deployment Considerations

- Validar vistas de dashboard en producción
- Verificar rendimiento de vistas analíticas
- Asegurar que los KPIs se actualicen correctamente

---

## 11. MÓDULO: FINANZAS

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 70% | Finanzas/README.md | CajaChica migrada, Cortes, aprobaciones |
| **Código** | 65% | DailyCloseService, AlertasService | Cortes incompletos |
| **Base de Datos** | 75% | precorte, postcorte, conciliacion | Completos |
| **UI/UX** | 70% | Componentes Caja/ | UI refinada, conciliación |

**Promedio de Alineación**: 70% | **Prioridad**: 🟢 P2

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Caja | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Cortes | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conciliaciones | ⚠️ | ✅ | ✅ | ⚠️ | ⚠️ | UI de conciliación | 🟡 |
| DailyCloseService | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | No ubicado | 🟡 |

### Insights por Agente

- **[CLAUDE]**: Conexión con Caja
- **[QWEN]**: Cortes diarios, workflow aprobaciones multi-nivel faltante
- **[CODEX]**: Triggers automáticos, falta workflow aprobaciones
- **[COPILOT]**: Daily close automáticos

### Deployment Considerations

- Validar proceso de cierre diario en producción
- Verificar triggers automáticos en BD
- Asegurar que DailyCloseService funcione correctamente

---

## 12. MÓDULO: BASE DE DATOS

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 75% | Parcial en docs/, sin docs/V4.0/ | Completar en V4.0, 12 funciones sin doc |
| **Código** | 90% | 147 tablas, 38 vistas, 37 funciones | Sin modelo para 82 tablas |
| **Base de Datos** | 90% | Esquema selemti completo | Completos |
| **UI/UX** | 0% | Sin UI directa | No aplica |

**Promedio de Alineación**: 64% | **Prioridad**: 🔴 P0

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Tablas | ✅ | ✅ | ✅ | - | ✅ | Ninguno | 🟢 |
| Vistas | ⚠️ | ✅ | ✅ | - | ⚠️ | Documentación incompleta | 🟡 |
| Funciones | ⚠️ | ✅ | ✅ | - | ⚠️ | 12 funciones críticas sin doc | 🔴 |

### Insights por Agente

- **[CLAUDE]**: 12 funciones críticas sin documentar
- **[QWEN]**: Dual schema (selemti, public)
- **[CODEX]**: 189 archivos huérfanos, 26 migraciones sin doc
- **[COPILOT]**: PostgreSQL 9.5, 147 tablas

### Gaps Críticos

1. 12 funciones críticas sin documentar
2. 10 vistas BD sin doc individual
3. 82 tablas sin modelo Eloquent
4. 26 migraciones sin documentación

### Deployment Considerations

- Asegurar esquema selemti en producción
- Validar funciones críticas en servidor (fn_recipe_cost_at, fn_expandir_consumo_ticket)
- Verificar acceso a ambos esquemas (selemti, public)

---

## 13. MÓDULO: FRONTEND

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 75% | Frontend/Componentes.md, Frontend/Layout.md | Gaps UX, Design System |
| **Código** | 80% | 58 componentes Livewire, vistas Blade | UX críticos |
| **Base de Datos** | 0% | No aplica | No aplica |
| **UI/UX** | 65% | Score FASE6 6.5/10 | Loading, toasts, confirmación |

**Promedio de Alineación**: 55% | **Prioridad**: 🟡 P1

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Componentes | ✅ | ✅ | - | ✅ | ✅ | Ninguno | 🟢 |
| Layout | ✅ | ✅ | - | ✅ | ✅ | Ninguno | 🟢 |
| Loading states | ⚠️ | ❌ | - | ❌ | ❌ | 40 forms sin loading | 🔴 |
| Notificaciones | ⚠️ | ⚠️ | - | ⚠️ | ❌ | Sistema roto | 🔴 |
| Confirmaciones delete | ⚠️ | ❌ | - | ❌ | ❌ | Sin confirmaciones | 🔴 |
| Design System | ❌ | ⚠️ | - | ⚠️ | ❌ | Guía faltante | 🟡 |

### Insights por Agente

- **[CLAUDE]**: Gaps UX críticos identificados
- **[QWEN]**: Bootstrap 5, Alpine.js
- **[CODEX]**: 40 forms sin loading states, crear DesignSystem.md
- **[COPILOT]**: Patrones inconsistentes

### Gaps Críticos

1. 40 forms sin loading states (CRÍTICO)
2. Sistema de notificaciones roto (CRÍTICO)
3. Confirmaciones delete sin implementar (CRÍTICO)
4. Design System sin documentar
5. Patrones inconsistentes

### Deployment Considerations

- Validar UX en entorno de producción
- Verificar que assets (CSS/JS) se carguen correctamente
- Asegurar que RewriteBase esté configurado como /terrena2/

---

## 14. MÓDULO: SEGURIDAD

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 75% | Sin docs/V4.0 | Crear Seguridad/README.md, Roles, AuditLog |
| **Código** | 80% | Spatie permissions, Policies | UI perms incompleta |
| **Base de Datos** | 85% | permissions, roles, model_has_* | Completos |
| **UI/UX** | 60% | Básico en People/Users | UI perms incompleta |

**Promedio de Alineación**: 75% | **Prioridad**: 🔴 P0

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Sistema roles | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno backend | 🟢 |
| Permisos atómicos | ✅ | ✅ | ✅ | ✅ | ⚠️ | Matriz no 100% sync | 🟡 |
| GUI roles | ⚠️ | ❌ | ✅ | ❌ | ❌ | GUI faltante | 🟡 |
| GUI permisos | ⚠️ | ❌ | ✅ | ❌ | ❌ | GUI faltante | 🟡 |
| GUI asignación | ⚠️ | ⚠️ | ✅ | ⚠️ | ⚠️ | GUI mejorable | 🟡 |
| Auditoría global | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | UI limitada | 🟡 |
| Auditoría específica | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | UI limitada | 🟡 |
| Middleware | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |

### Insights por Agente

- **[CLAUDE]**: 7 roles identificados
- **[QWEN]**: RBAC completo, UI de gestión faltante
- **[CODEX]**: 45 permisos definidos, falta doc independiente
- **[COPILOT]**: 7 roles con jerarquía

### Deployment Considerations

- Validar permisos en producción
- Verificar que las reglas de Spatie funcionen
- Asegurar que el token de sesión se genere correctamente

---

## 15. MÓDULO: CATÁLOGOS

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 85% | Parcial documentado | Crear Catalogos/README.md |
| **Código** | 90% | 6 componentes Livewire, modelos | Completos |
| **Base de Datos** | 90% | cat_unidades, cat_almacenes, etc. | Completos |
| **UI/UX** | 90% | UI completa catálogos | Completos |

**Promedio de Alineación**: 89% | **Prioridad**: ✅ P0

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Unidades medida | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conversiones UOM | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Proveedores | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Almacenes | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Sucursales | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Políticas stock | ✅ | ✅ | ✅ | ✅ | ⚠️ | UI sin motor | 🟡 |
| Categorías ítems | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | CRUD mejorable | 🟡 |

### Insights por Agente

- **[CLAUDE]**: 6 componentes Livewire
- **[QWEN]**: Unidades, almacenes, proveedores, sucursales completos
- **[CODEX]**: 4 modelos principales
- **[COPILOT]**: Conversiones UOM implementadas

### Deployment Considerations

- Validar catálogos en producción
- Verificar conversiones de unidades
- Asegurar integridad referencial

---

## 16. MÓDULO: TRANSFERENCIAS

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 60% | Inventario/Transferencias.md parcial | Despacho/recepción incompletos |
| **Código** | 75% | TransferService completo | UI despacho/recepción, TransferApiController huérfano |
| **Base de Datos** | 85% | transfer_cab, transfer_det | Completos |
| **UI/UX** | 50% | Solo creación, sin despacho/recepción | UI pendiente |

**Promedio de Alineación**: 68% | **Prioridad**: 🟡 P1

### Funcionalidades Detalladas

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Estados - SOLICITADA | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Estados - DESPACHADA | ✅ | ⚠️ | ✅ | ❌ | ❌ | UI faltante | 🟡 |
| Estados - RECIBIDA | ✅ | ⚠️ | ✅ | ❌ | ❌ | UI faltante | 🟡 |
| API REST | ✅ | ❌ | ✅ | ❌ | ❌ | Endpoints no implementados | 🟡 |

### Insights por Agente

- **[CLAUDE]**: UI solo creación, sin despacho/recepción, TransferApiController huérfano
- **[QWEN]**: 5 estados de transferencia, estados incompletos
- **[CODEX]**: TransferService funcional
- **[COPILOT]**: API parcial, UI incompleta, solo 2 de 5 estados

### Deployment Considerations

- Validar TransferService en producción
- Implementar UI de despacho/recepción en servidor
- Verificar estados de transferencia

---

## 17. DEPLOYMENT Y OPERACIONES

### 17.1 Consideraciones de Despliegue

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| **Ambiente Local** | ✅ | Windows + XAMPP, PostgreSQL 9.5, Puerto 5433 |
| **Ambiente Producción** | ✅ | Ubuntu + Apache, PostgreSQL 14+, Alias `/terrena2` |
| **URLs de Acceso** | ✅ | http://192.168.1.235/terrena2/, http://100.126.124.101/terrena2/ |
| **Configuración Apache** | ✅ | VirtualHost con Alias `/terrena2`, RewriteBase `/terrena2/` |
| **Proceso de Deployment** | ✅ | WinSCP/SFTP, backup antes, permisos post-copias |
| **Archivos a copiar** | ✅ | app/, resources/, routes/, public/build/, etc. |
| **Archivos a excluir** | ✅ | .env, vendor/, node_modules/, storage/logs/ |

### 17.2 Checklist de Despliegue

**Pre-deployment**:
- [ ] Tests ejecutados: `php artisan test`
- [ ] Código limpio: `./vendor/bin/pint`
- [ ] Migraciones probadas: `php artisan migrate:status`
- [ ] Assets compilados: `npm run build`
- [ ] Cache limpiado: `php artisan *:clear`

**Post-deployment**:
- [ ] Composer install: `sudo -u www-data composer install --no-dev`
- [ ] Migraciones: `sudo -u www-data php artisan migrate --force`
- [ ] Cache: `sudo -u www-data php artisan config:cache`
- [ ] Permisos storage: `sudo chown -R www-data:www-data storage/`

---

## 18. RESUMEN GENERAL

| Módulo | Documentación | Código | Base de Datos | UI/UX | Promedio | Prioridad |
|--------|---------------|--------|---------------|-------|----------|-----------|
| Inventario | 80% | 85% | 90% | 80% | 84% | 🔴 P0 |
| Recetas | 70% | 75% | 85% | 70% | 75% | 🔴 P0 |
| Producción | 55% | 60% | 70% | 65% | 63% | 🟡 P1 |
| Purchasing | 85% | 85% | 90% | 80% | 85% (31% sin motor) | 🔴 P0 |
| POS | 60% | 70% | 80% | 70% | 70% | 🟡 P1 |
| Ventas | 75% | 80% | 85% | 80% | 80% | 🔴 P0 |
| Caja | 95% | 95% | 95% | 90% | 94% | ✅ P0 |
| Caja Chica | 100% | 100% | 100% | 100% | 100% | ✅ P0 |
| Reportes | 90% | 90% | 95% | 90% | 94% | ✅ P0 |
| Finanzas | 70% | 65% | 75% | 70% | 70% | 🟢 P2 |
| Base de Datos | 75% | 90% | 90% | 0% | 64% | 🔴 P0 |
| Frontend | 75% | 80% | 0% | 65% | 55% | 🟡 P1 |
| Seguridad | 75% | 80% | 85% | 60% | 75% | 🔴 P0 |
| Catálogos | 85% | 90% | 90% | 90% | 89% | ✅ P0 |
| Transferencias | 60% | 75% | 85% | 50% | 68% | 🟡 P1 |

**Promedio General**: **76.7%**

---

## 19. TOP 10 GAPS CRÍTICOS

| # | Módulo | Gap | Prioridad | Impacto | Deployment |
|---|--------|-----|-----------|---------|------------|
| 1 | **Purchasing** | Motor Replenishment 0% | 🔴 P0 | Operación, compras | 🔴 Motor completo requerido en producción |
| 2 | **POS** | PosConsumptionService x3 | 🔴 P0 | Consistencia | 🔴 Consolidar en producción |
| 3 | **Frontend** | Forms sin loading states | 🔴 P0 | UX, doble submit | ✅ Requiere RewriteBase /terrena2/ |
| 4 | **Frontend** | Notificaciones rotas | 🔴 P0 | UX, feedback | ✅ Validar assets en producción |
| 5 | **Frontend** | Confirmaciones delete | 🔴 P0 | Seguridad | ✅ Verificar en entorno producción |
| 6 | **Base de Datos** | 12 funciones sin doc | 🔴 P0 | Operación | 🔴 fn_recipe_cost_at() requerida en producción |
| 7 | **Producción** | ProductionService x2 | 🟡 P1 | Consistencia | 🔴 Consolidar antes de deployment |
| 8 | **Recetas** | Versionado sin UI | 🟡 P1 | Historia, operación | ✅ BD lista, implementar UI |
| 9 | **Transferencias** | UI despacho/recepción | 🟡 P1 | Operación | ✅ Implementar en servidor |
| 10 | **Inventario** | Recepciones - Estados | 🟡 P1 | Operación | ✅ Completar flujo BORRADOR→VALIDADA→POSTEADA |

---

## 20. ROADMAP SUGERIDO (340h / 8 sprints)

| Sprint | Horas | Enfoque | Objetivos | Consideraciones Producción |
|--------|-------|---------|-----------|-----------------------------|
| Sprint 1 | 55h | UX Crítico + Consolidación | Forms loading, notificaciones, confirmaciones, consolidar PosConsumptionService x3, ProductionService x2 | Validar en servidor con RewriteBase /terrena2/ |
| Sprint 2 | 51h | Motor Replenishment + BD | Motor completo (31h), documentar 12 funciones BD críticas (20h) | fn_recipe_cost_at() en producción |
| Sprint 3 | 42h | Documentación Core | 15 docs V4.0 completos (Recetas, Producción, POS, etc.) | Asegurar documentación de deployment |
| Sprint 4 | 40h | Código Huérfano Prioritario | Eliminar duplicados, huérfanos críticos | Consolidar servicios duplicados antes de deployment |
| Sprint 5 | 48h | Funcionalidad Recetas + Transferencias | Recetas versionado UI, Transferencias UI despacho/recepción | fn_recipe_cost_at() debe funcionar |
| Sprint 6 | 42h | Reportes + Inventario | KPIs analíticos, recepciones estados completos | Validar vistas en producción |
| Sprint 7 | 37h | Seguridad + Frontend | GUI permisos, Design System | Validar en entorno producción |
| Sprint 8 | 25h | Tests + Pulido | Aseguramiento calidad, deployment final | Validar procesos de deployment |
| **Total** | **340h** | - | - | - |

---

## 21. REFERENCIAS

- FASE1-FASE6: Auditoría completa del sistema (13 Noviembre 2025)
- CLAUDE: Contrato original, compendio supremo, 15 módulos con gaps detallados
- QWEN: Análisis modular por feature, tabla de conexiones y severidades
- CODEX: Radiografía técnica, gaps por módulo, acción inmediata
- COPILOT: Stack confirmado, funcionalidades con % alineación, matriz exhaustiva
- `docs/V4.0/Guia/Deployment.md`: Proceso de deployment
- `docs/V4.0/Guia/Stack.md`: Stack y convenciones

---

**FIN MATRIZ DE ALINEACIÓN V4.0 - MAESTRO**
