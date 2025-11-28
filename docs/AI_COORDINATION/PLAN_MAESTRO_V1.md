# PLAN MAESTRO - Terrena POS
**Versión**: 1.0
**Fecha**: 26 de noviembre de 2025
**Coordinador**: Claude Code
**Agentes**: CODEX (implementación), QWEN (análisis/BD), CLAUDE (orquestación)

---

## OBJETIVOS PRINCIPALES

1. ✅ **[OBJ 1] Finalizar Inventarios** - 95% completo
2. 🔥 **[OBJ 2] Homologar TODA la interfaz al Design System** - 3% completo (57 componentes pendientes)
3. 🎯 **[OBJ 3] Mejorar UI/UX + Simplificar menú** - 0% completo
4. 🔧 **[OBJ 4] Completar Recetas y Producciones** - 40% completo (backend faltante)
5. 📋 **[OBJ 5] Documentar estatus completo del sistema** - En progreso

---

## ESTRATEGIA DE EJECUCIÓN

### Principios:
1. **Trabajo paralelo máximo**: CODEX y QWEN trabajan simultáneamente en diferentes áreas
2. **Validación continua**: Claude revisa cada entrega antes de continuar
3. **Documentación incremental**: Cada fase genera su propia documentación
4. **Enfoque modular**: Migrar módulos completos, no componentes aislados
5. **Prioridad al usuario**: Primero lo visible y funcional

### Fases:
- **FASE 1-2**: Trabajo paralelo intensivo (migración UI + backend producción)
- **FASE 3**: Consolidación y mejoras UX
- **FASE 4**: Documentación final y entrega

---

## 📋 FASE 1: MIGRACIÓN DESIGN SYSTEM - MÓDULOS CRÍTICOS
**Duración estimada**: 12-18 horas reales
**Agente principal**: CODEX
**Validador**: CLAUDE

### FASE 1A: Catálogos (6 componentes)
**Prioridad**: ALTA - Módulos pequeños y frecuentemente usados

**PROMPT para CODEX**:
```
TAREA: Migrar 6 componentes del módulo Catálogos al Design System

CONTEXTO:
- Ya existen 6 componentes del Design System en resources/views/components/
- <x-card>, <x-kpi-card>, <x-badge>, <x-button>, <x-stat>, <x-alert>
- Referencia de uso: resources/views/livewire/inventory/items-index.blade.php

COMPONENTES A MIGRAR:
1. resources/views/livewire/catalogs/almacenes-index.blade.php
2. resources/views/livewire/catalogs/proveedores-index.blade.php
3. resources/views/livewire/catalogs/stock-policy-index.blade.php
4. resources/views/livewire/catalogs/sucursales-index.blade.php
5. resources/views/livewire/catalogs/unidades-index.blade.php
6. resources/views/livewire/catalogs/uom-conversion-index.blade.php

CAMBIOS REQUERIDOS:
- Reemplazar <div class="card"> por <x-card>
- Reemplazar badges Bootstrap por <x-badge type="...">
- Reemplazar botones por <x-button variant="..." size="...">
- Mantener funcionalidad wire: y Alpine.js intacta
- Preservar IDs y clases necesarias para JavaScript
- NO cambiar lógica de los componentes Livewire PHP

REGLAS:
1. Un componente a la vez, NO hacer batch de todos juntos
2. Probar cada componente en el navegador antes de continuar
3. Documentar cada cambio en docs/DESIGN_SYSTEM/05_MIGRACIONES.md
4. Seguir el formato de documentación ya establecido

ENTREGABLE:
- 6 archivos migrados
- Documentación de cambios
- Confirmación de pruebas visuales

¿Entendido? Comienza con almacenes-index.blade.php
```

**Validación Claude**:
- ✅ Revisar sintaxis de componentes
- ✅ Verificar que no se perdió funcionalidad
- ✅ Validar documentación
- ✅ Confirmar pruebas

---

### FASE 1B: Purchasing (5 componentes)
**Prioridad**: ALTA - Módulo completo y funcional

**PROMPT para CODEX**:
```
TAREA: Migrar 5 componentes del módulo Purchasing al Design System

COMPONENTES:
1. resources/views/livewire/purchasing/requests/index.blade.php
   - Tiene 5 KPIs que deben migrar a <x-kpi-card>
   - Filtros envolver en <x-card variant="bordered">
   - Tabla envolver en <x-card padding="none">
2. resources/views/livewire/purchasing/requests/create.blade.php
3. resources/views/livewire/purchasing/requests/detail.blade.php
4. resources/views/livewire/purchasing/orders/index.blade.php
5. resources/views/livewire/purchasing/orders/detail.blade.php

ESPECIAL ATENCIÓN en purchasing/requests/index.blade.php:
- Líneas 14-55: 5 cards con estadísticas → <x-kpi-card>
- Líneas 58-101: Card de filtros → <x-card>
- Líneas 104-185: Tabla → <x-card padding="none"> con header slot

REGLAS: Igual que FASE 1A

ENTREGABLE: 5 archivos migrados + documentación
```

---

### FASE 1C: Transferencias (5 componentes)
**Prioridad**: ALTA - Módulo de inventario crítico

**PROMPT para CODEX**:
```
TAREA: Migrar 5 componentes del módulo Transferencias al Design System

COMPONENTES:
1. resources/views/livewire/transfers/index.blade.php
2. resources/views/livewire/transfers/create.blade.php
3. resources/views/livewire/transfers/dispatch.blade.php
4. resources/views/livewire/transfers/receive.blade.php
5. resources/views/livewire/transfers/detail.blade.php

CAMBIOS PRINCIPALES:
- Migrar badges de estado a <x-badge>
- Cards de información a <x-card>
- Botones de acción a <x-button>

REGLAS: Igual que FASE 1A

ENTREGABLE: 5 archivos migrados + documentación
```

---

## 🔧 FASE 2: BACKEND PRODUCCIONES (Paralelo con FASE 1)
**Duración estimada**: 15-20 horas
**Agente principal**: CODEX
**Validador**: QWEN (BD) + CLAUDE (integración)

### FASE 2A: Service Layer Producción

**PROMPT para CODEX**:
```
TAREA: Crear Service completo para módulo de Producciones

CONTEXTO:
- Modelos existentes: Receta, RecetaDetalle, RecetaVersion
- Falta: OrdenProduccion, OrdenProduccionDetalle
- Base de datos: PostgreSQL schema selemti
- Patrón a seguir: app/Services/Inventory/ReceptionService.php

REQUERIMIENTOS:

1. CREAR MODELOS:
   - app/Models/Rec/OrdenProduccion.php
     - Campos: id, receta_id, lote_produccion, cantidad_objetivo, cantidad_real,
               estado (PLANIFICADA, EN_PROCESO, COMPLETADA, POSTEADA, CANCELADA),
               fecha_inicio, fecha_fin, notas, created_by, completed_by
     - Relaciones: receta(), detalles(), createdBy(), completedBy()

   - app/Models/Rec/OrdenProduccionDetalle.php
     - Campos: id, orden_id, item_id, cantidad_teorica, cantidad_real,
               unidad_medida_id, costo_unitario, costo_total
     - Relaciones: orden(), item(), unidadMedida()

2. CREAR MIGRACIÓN:
   database/migrations/YYYY_MM_DD_create_ordenes_produccion_tables.php
   - Tabla: selemti.ordenes_produccion
   - Tabla: selemti.ordenes_produccion_det
   - Índices: receta_id, estado, fecha_inicio, created_by

3. CREAR SERVICE:
   app/Services/Production/ProductionService.php

   Métodos requeridos:
   - createOrder(int $recetaId, float $cantidadObjetivo): int
     → Crea orden en estado PLANIFICADA
     → Calcula insumos teóricos desde RecetaDetalle

   - startOrder(int $ordenId): void
     → Cambia estado a EN_PROCESO
     → Valida stock disponible de insumos

   - consumeIngredients(int $ordenId, array $consumos): void
     → Registra consumo real de insumos
     → Genera movimientos en mov_inv con ref_tipo='produccion'

   - completeOrder(int $ordenId, float $cantidadReal): void
     → Cambia estado a COMPLETADA
     → Valida que todos los insumos fueron consumidos

   - postOrder(int $ordenId): void
     → Cambia estado a POSTEADA
     → Genera entrada de producto terminado en mov_inv
     → Crea batch para el producto terminado
     → Calcula costo real (suma de insumos consumidos)

   - cancelOrder(int $ordenId, string $razon): void
     → Cambia estado a CANCELADA
     → Reversa movimientos si orden estaba en proceso

4. VALIDACIONES:
   - Solo RecetaVersion publicada puede generar órdenes
   - Validar stock antes de iniciar producción
   - Validar que cantidad_real <= cantidad_objetivo * 1.1 (10% tolerancia)
   - No permitir cancelar orden POSTEADA

5. TRANSACCIONES:
   - Todos los métodos usan DB::transaction()
   - Rollback automático en caso de error

ENTREGABLE:
- 2 modelos con relaciones y casts
- 1 migración
- 1 service con 6 métodos completamente funcionales
- Documentación en docblocks PHPDoc

VALIDACIÓN:
- QWEN revisará schema y validará contra BD
- Claude revisará lógica de negocio y transacciones
```

---

### FASE 2B: UI Producciones (5-7 componentes)

**PROMPT para CODEX** (después de FASE 2A aprobada):
```
TAREA: Crear UI completa para módulo de Producciones usando Design System

CONTEXTO:
- ProductionService ya creado y validado
- Usar componentes Design System desde el inicio
- Patrón a seguir: purchasing/requests/* y inventory-count/*

COMPONENTES A CREAR:

1. resources/views/livewire/production/orders-index.blade.php
   - Listado de órdenes con filtros (estado, receta, fechas)
   - KPIs: Total órdenes, En proceso, Completadas hoy, Eficiencia promedio
   - Usar <x-kpi-card> para KPIs
   - Tabla con <x-card padding="none">
   - Badges para estados con <x-badge>
   - Botón "Nueva orden" con <x-button variant="primary">

2. resources/views/livewire/production/order-create.blade.php
   - Selector de receta (solo versiones publicadas)
   - Input cantidad objetivo
   - Preview de insumos requeridos
   - Validación de stock disponible
   - Botón crear orden

3. resources/views/livewire/production/order-detail.blade.php
   - Información de la orden
   - Estado y transiciones permitidas
   - Tabla de insumos (teórico vs real)
   - Botones: Iniciar, Registrar consumos, Completar, Postear, Cancelar
   - Según estado, mostrar/ocultar botones

4. resources/views/livewire/production/consume-ingredients.blade.php
   - Modal para registrar consumo de insumos
   - Lista de insumos teóricos
   - Inputs para cantidad real consumida
   - Diferencias (real - teórico) con colores
   - Botón guardar con validación

5. resources/views/livewire/production/complete-order.blade.php
   - Modal para completar orden
   - Input cantidad real producida
   - Resumen de consumos
   - Cálculo de eficiencia (real/objetivo)
   - Confirmación

6. resources/views/produccion.blade.php (reemplazar existente)
   - Ya NO "módulo en preparación"
   - Ahora redirecciona a production.orders-index
   - O embebe directamente el componente @livewire('production.orders-index')

COMPONENTES PHP LIVEWIRE:
- app/Livewire/Production/OrdersIndex.php
- app/Livewire/Production/OrderCreate.php
- app/Livewire/Production/OrderDetail.php
- app/Livewire/Production/ConsumeIngredients.php
- app/Livewire/Production/CompleteOrder.php

RUTAS (agregar a routes/web.php):
```php
Route::middleware(['auth'])->prefix('production')->name('production.')->group(function () {
    Route::get('/', OrdersIndex::class)->name('orders.index');
    Route::get('/create', OrderCreate::class)->name('orders.create');
    Route::get('/{id}', OrderDetail::class)->name('orders.detail');
});
```

REGLAS:
- USAR Design System desde el inicio, NO Bootstrap raw
- Seguir patrones de purchasing e inventory-count
- Documentar en docs/PRODUCTION/

ENTREGABLE:
- 5 componentes Livewire Blade
- 5 clases PHP Livewire
- Rutas configuradas
- Actualizar produccion.blade.php
- Documentación completa
```

---

## 📋 FASE 3: MIGRACIÓN DESIGN SYSTEM - MÓDULOS RESTANTES
**Duración estimada**: 20-30 horas
**Agente principal**: CODEX (batch processing)
**Validador**: CLAUDE

### FASE 3A: Inventario restante (11 componentes)

**PROMPT para CODEX**:
```
TAREA: Migrar 11 componentes restantes del módulo Inventario al Design System

NOTA: items-index.blade.php ya está migrado, úsalo como referencia

COMPONENTES:
1. resources/views/livewire/inventory/lots-index.blade.php
2. resources/views/livewire/inventory/transfer-detail.blade.php
3. resources/views/livewire/inventory/insumo-create.blade.php
4. resources/views/livewire/inventory/inventory-counts-index.blade.php
5. resources/views/livewire/inventory/orquestador-panel.blade.php
6. resources/views/livewire/inventory/physical-counts.blade.php
7. resources/views/livewire/inventory/items-manage.blade.php
8. resources/views/livewire/inventory/item-create.blade.php
9. resources/views/livewire/inventory/reception-detail.blade.php
10. resources/views/livewire/inventory/alerts-list.blade.php
11. resources/views/livewire/inventory/item-price-create.blade.php

ESTRATEGIA:
- Hacer en grupos de 3-4 componentes
- Documentar cada grupo
- Validar antes de continuar

ENTREGABLE: 11 archivos migrados + documentación
```

---

### FASE 3B: Inventory Count (5 componentes)

**PROMPT para CODEX**:
```
TAREA: Migrar 5 componentes del módulo Inventory Count al Design System

COMPONENTES:
1. resources/views/livewire/inventory-count/index.blade.php
2. resources/views/livewire/inventory-count/create.blade.php
3. resources/views/livewire/inventory-count/capture.blade.php
4. resources/views/livewire/inventory-count/review.blade.php
5. resources/views/livewire/inventory-count/detail.blade.php

ENTREGABLE: 5 archivos migrados + documentación
```

---

### FASE 3C: Cash Fund (6 componentes)

**PROMPT para CODEX**:
```
TAREA: Migrar 6 componentes del módulo Cash Fund al Design System

COMPONENTES:
1. resources/views/livewire/cash-fund/index.blade.php
2. resources/views/livewire/cash-fund/open.blade.php
3. resources/views/livewire/cash-fund/detail.blade.php
4. resources/views/livewire/cash-fund/movements.blade.php
5. resources/views/livewire/cash-fund/approvals.blade.php
6. resources/views/livewire/cash-fund/arqueo.blade.php

ENTREGABLE: 6 archivos migrados + documentación
```

---

### FASE 3D: Recetas (6 componentes)

**PROMPT para CODEX**:
```
TAREA: Migrar 6 componentes del módulo Recetas al Design System

COMPONENTES:
1. resources/views/livewire/recipes/recipes-index.blade.php
2. resources/views/livewire/recipes/recipe-editor.blade.php
3. resources/views/livewire/recipes/conversiones-index.blade.php
4. resources/views/livewire/recipes/presentaciones-index.blade.php
5. resources/views/livewire/recipes/version-activator.blade.php
6. resources/views/livewire/recipes/version-comparator.blade.php

ENTREGABLE: 6 archivos migrados + documentación
```

---

### FASE 3E: Módulos menores (14 componentes)

**PROMPT para CODEX**:
```
TAREA: Migrar componentes de módulos menores al Design System

GRUPOS:

A. POS Mapping (5 componentes):
   - livewire/pos/pos-mapping-index.blade.php
   - livewire/pos/pos-map-index.blade.php
   - livewire/pos/unmapped-items-widget.blade.php
   - livewire/pos/pos-map.blade.php
   - livewire/pos/pos-mapping-form.blade.php

B. Auditoría (2 componentes):
   - livewire/audit/index.blade.php
   - livewire/audit/log-viewer.blade.php

C. Reportes (2 componentes):
   - livewire/reports/dashboard.blade.php
   - livewire/reports/drill-down.blade.php

D. Personal (1 componente):
   - livewire/people/users-index.blade.php

E. Otros (4 componentes):
   - livewire/replenishment/dashboard.blade.php
   - livewire/kds/board.blade.php
   - livewire/unidades/index.blade.php
   - livewire/crud/generic-index.blade.php

ESTRATEGIA: Hacer grupo por grupo (A → B → C → D → E)

ENTREGABLE: 14 archivos migrados + documentación
```

---

## 🎨 FASE 4: UI/UX Y MENÚ
**Duración estimada**: 12-19 horas
**Agente principal**: CLAUDE (diseño) + CODEX (implementación)
**Validador**: Usuario

### FASE 4A: Análisis del menú actual

**TAREA CLAUDE**:
```
1. Leer resources/views/layouts/terrena.blade.php
2. Analizar estructura del menú y navegación
3. Identificar problemas:
   - Ítems duplicados
   - Agrupaciones ilógicas
   - Profundidad excesiva
   - Falta de jerarquía visual
4. Proponer nueva estructura simplificada:
   - Máximo 6-7 secciones principales
   - Agrupación lógica por flujo de trabajo
   - Iconos consistentes
   - Búsqueda global opcional
5. Crear mockup en Markdown con estructura propuesta
6. Presentar al usuario para aprobación
```

---

### FASE 4B: Implementación menú simplificado

**PROMPT para CODEX** (después de aprobación):
```
TAREA: Implementar nuevo menú simplificado en terrena.blade.php

ESTRUCTURA APROBADA:
[Copiar estructura aprobada por usuario]

CAMBIOS:
- Actualizar sidebar en layouts/terrena.blade.php
- Implementar collapse/expand para subsecciones
- Añadir iconos FontAwesome consistentes
- Implementar indicador de sección activa
- Responsive para móvil

ENTREGABLE:
- layouts/terrena.blade.php actualizado
- CSS adicional si necesario en design-system.css
- Documentación de cambios
```

---

### FASE 4C: Mejoras UX generales

**TAREA CLAUDE + CODEX**:
1. Añadir breadcrumbs en todas las vistas
2. Mejorar mensajes de feedback (toasts unificados)
3. Loading states consistentes
4. Confirmaciones de acciones destructivas
5. Shortcuts de teclado para acciones comunes

---

## 📊 FASE 5: MÓDULO DE REPORTES
**Duración estimada**: 15-20 horas
**Agente principal**: CODEX
**Validador**: CLAUDE

### FASE 5A: Dashboard de Reportes

**PROMPT para CODEX**:
```
TAREA: Crear módulo básico de Reportes con dashboards

COMPONENTES:

1. resources/views/reportes.blade.php (reemplazar)
   - Dashboard principal con 4 secciones:
     a) Ventas (KPIs + gráfico últimos 7 días)
     b) Inventario (Stock valorizado, alertas, movimientos)
     c) Compras (Solicitudes, órdenes, proveedores top)
     d) Producción (Órdenes, eficiencia, costos)

2. resources/views/livewire/reports/sales-dashboard.blade.php
   - KPIs: Ventas hoy, Ticket promedio, Items más vendidos
   - Gráfico de línea con Chart.js
   - Tabla top 10 productos

3. resources/views/livewire/reports/inventory-dashboard.blade.php
   - KPIs: Valor total stock, Items bajo mínimo, Mermas del mes
   - Gráfico de barras por categoría
   - Alertas de stock

4. resources/views/livewire/reports/purchasing-dashboard.blade.php
   - KPIs: Solicitudes pendientes, Órdenes del mes, Gasto total
   - Top 5 proveedores
   - Timeline de órdenes

USAR Design System desde el inicio
Chart.js para gráficos (ya incluido en proyecto)

ENTREGABLE:
- 1 página principal + 3 componentes Livewire
- 3 clases PHP Livewire con lógica de KPIs
- Documentación
```

---

## 🔍 FASE 6: VALIDACIÓN Y DOCUMENTACIÓN FINAL
**Duración estimada**: 13-20 horas
**Agente principal**: QWEN (análisis) + CLAUDE (consolidación)
**Validador**: Usuario final

### FASE 6A: Auditoría Técnica Completa

**PROMPT para QWEN**:
```
TAREA: Auditoría técnica completa del sistema

ANÁLISIS REQUERIDO:

1. BASE DE DATOS:
   - Listar todas las tablas de selemti schema
   - Validar integridad referencial
   - Identificar índices faltantes
   - Sugerir optimizaciones

2. MODELOS ELOQUENT:
   - Validar que todos los modelos tienen connection correcta
   - Validar fillable/guarded
   - Validar casts
   - Validar relaciones

3. SERVICIOS:
   - Listar todos los Services creados
   - Validar que usan transacciones
   - Validar manejo de errores
   - Identificar código duplicado

4. RUTAS:
   - Auditar routes/web.php
   - Auditar routes/api.php
   - Identificar rutas sin uso
   - Validar middleware de autenticación

5. PERFORMANCE:
   - Identificar N+1 queries potenciales
   - Sugerir eager loading
   - Identificar vistas sin paginación
   - Sugerir caché donde aplique

ENTREGABLE:
- docs/AUDIT/TECHNICAL_AUDIT_FINAL.md (informe completo)
- docs/AUDIT/OPTIMIZATION_RECOMMENDATIONS.md
- Lista de issues críticos vs. mejoras opcionales
```

---

### FASE 6B: Documentación de Usuario

**TAREA CLAUDE**:
```
Crear documentación completa para usuarios finales:

1. docs/USER_GUIDE/01_INTRODUCCION.md
   - Qué es Terrena POS
   - Módulos principales
   - Roles y permisos

2. docs/USER_GUIDE/02_INVENTARIO.md
   - Gestión de items
   - Recepciones de mercancía
   - Transferencias entre almacenes
   - Conteos físicos
   - Alertas de stock

3. docs/USER_GUIDE/03_COMPRAS.md
   - Crear solicitudes
   - Cotizaciones
   - Órdenes de compra
   - Seguimiento

4. docs/USER_GUIDE/04_PRODUCCION.md
   - Gestión de recetas
   - Órdenes de producción
   - Consumo de insumos
   - Costeo

5. docs/USER_GUIDE/05_CAJA_CHICA.md
   - Abrir fondo
   - Registrar egresos
   - Arqueo y cierre
   - Aprobaciones

6. docs/USER_GUIDE/06_REPORTES.md
   - Dashboard principal
   - Reportes de ventas
   - Reportes de inventario
   - Exportaciones

7. docs/USER_GUIDE/07_CATALOGOS.md
   - Sucursales y almacenes
   - Unidades de medida
   - Proveedores
   - Políticas de stock

FORMATO: Markdown con screenshots (capturas de pantalla)
ESTILO: Paso a paso, lenguaje claro, ejemplos prácticos
```

---

### FASE 6C: Documentación Técnica

**TAREA CLAUDE**:
```
Consolidar toda la documentación técnica:

1. Actualizar README.md principal
2. Actualizar CLAUDE.md con nuevos módulos
3. Crear docs/ARCHITECTURE/SYSTEM_OVERVIEW.md
4. Crear docs/ARCHITECTURE/DATABASE_SCHEMA.md (consolidar trabajo de QWEN)
5. Crear docs/ARCHITECTURE/SERVICE_LAYER.md
6. Crear docs/API/ENDPOINTS_REFERENCE.md
7. Crear docs/DEPLOYMENT/PRODUCTION_CHECKLIST.md

Incluir diagramas donde sea necesario (Mermaid)
```

---

## 📋 CHECKLIST DE VALIDACIÓN

### Por Fase:

#### FASE 1 (Migración módulos críticos):
- [ ] 6 componentes Catálogos migrados y funcionando
- [ ] 5 componentes Purchasing migrados y funcionando
- [ ] 5 componentes Transferencias migrados y funcionando
- [ ] Documentación en 05_MIGRACIONES.md actualizada
- [ ] Pruebas visuales en navegador completadas
- [ ] No hay errores de consola JavaScript
- [ ] Funcionalidad Livewire intacta

#### FASE 2 (Backend Producciones):
- [ ] 2 modelos creados con relaciones
- [ ] Migración ejecutada sin errores
- [ ] ProductionService con 6 métodos implementados
- [ ] Validación QWEN aprobada (schema correcto)
- [ ] Validación CLAUDE aprobada (lógica de negocio)
- [ ] 5 componentes Livewire UI creados
- [ ] Rutas configuradas
- [ ] produccion.blade.php actualizado
- [ ] Módulo completamente funcional

#### FASE 3 (Migración restantes):
- [ ] 11 componentes Inventario migrados
- [ ] 5 componentes Inventory Count migrados
- [ ] 6 componentes Cash Fund migrados
- [ ] 6 componentes Recetas migrados
- [ ] 14 componentes módulos menores migrados
- [ ] Total: 57 componentes validados
- [ ] Documentación completa

#### FASE 4 (UI/UX y Menú):
- [ ] Análisis del menú completado
- [ ] Propuesta aprobada por usuario
- [ ] Nuevo menú implementado
- [ ] Breadcrumbs añadidos
- [ ] Toasts unificados
- [ ] Loading states implementados
- [ ] Confirmaciones de acciones destructivas

#### FASE 5 (Reportes):
- [ ] Dashboard principal de reportes creado
- [ ] Sales dashboard funcional
- [ ] Inventory dashboard funcional
- [ ] Purchasing dashboard funcional
- [ ] Gráficos Chart.js funcionando

#### FASE 6 (Validación final):
- [ ] Auditoría técnica QWEN completada
- [ ] 7 documentos de usuario creados
- [ ] 7 documentos técnicos actualizados
- [ ] README.md actualizado
- [ ] CLAUDE.md actualizado
- [ ] Sistema 100% documentado

---

## 🎯 CRITERIOS DE ÉXITO FINAL

### Funcional:
✅ 100% de componentes Livewire usando Design System
✅ Módulo de Producción completamente operativo
✅ Módulo de Reportes con dashboards básicos
✅ Menú simplificado y navegación intuitiva
✅ Cero errores críticos en consola
✅ Cero warnings PHP en logs

### Técnico:
✅ Todos los modelos con connection correcta
✅ Todos los Services usan transacciones
✅ Todas las rutas con middleware de autenticación
✅ Todas las tablas con índices apropiados
✅ Ningún N+1 query en vistas principales

### Documentación:
✅ README.md actualizado y completo
✅ 7 documentos de usuario creados
✅ Documentación técnica consolidada
✅ CLAUDE.md reflejando estado actual
✅ API documentation actualizada

### Usuario:
✅ Interfaz 100% homogénea
✅ Navegación simplificada e intuitiva
✅ Feedback visual claro en todas las acciones
✅ Performance aceptable (< 2s carga de vistas)
✅ Responsive en móvil y tablet

---

## 📊 ESTIMACIÓN TOTAL

### Horas de trabajo por agente:

| Fase | CODEX | QWEN | CLAUDE | Total |
|------|-------|------|--------|-------|
| FASE 1 | 12-15h | - | 3-4h | 15-19h |
| FASE 2 | 18-22h | 3-4h | 4-5h | 25-31h |
| FASE 3 | 25-35h | - | 5-8h | 30-43h |
| FASE 4 | 6-8h | - | 6-11h | 12-19h |
| FASE 5 | 12-15h | - | 3-5h | 15-20h |
| FASE 6 | - | 8-12h | 5-8h | 13-20h |
| **TOTAL** | **73-95h** | **11-16h** | **26-41h** | **110-152h** |

### Con trabajo paralelo máximo:
**Tiempo real estimado: 50-75 horas calendario** (2-3 semanas)

---

## 🚀 SECUENCIA DE EJECUCIÓN

### Semana 1:
- **Día 1-2**: FASE 1A + 1B (Catálogos + Purchasing) - CODEX
- **Día 1-2**: FASE 2A (Service Producción) - CODEX paralelo
- **Día 3**: Validación QWEN (schema BD) + CLAUDE (lógica)
- **Día 4-5**: FASE 1C (Transferencias) + FASE 2B (UI Producción) - CODEX
- **Día 5**: Validación CLAUDE

### Semana 2:
- **Día 1-3**: FASE 3A + 3B (Inventario + Counts) - CODEX
- **Día 4-5**: FASE 3C + 3D (Cash Fund + Recetas) - CODEX
- **Día 5**: FASE 4A (Análisis menú) - CLAUDE

### Semana 3:
- **Día 1**: FASE 3E (Módulos menores) - CODEX
- **Día 1-2**: FASE 4B + 4C (Implementar menú + UX) - CODEX + CLAUDE
- **Día 3**: FASE 5 (Reportes) - CODEX
- **Día 4-5**: FASE 6 (Validación + Docs) - QWEN + CLAUDE

---

## 📝 INSTRUCCIONES DE COORDINACIÓN

### Para CODEX:
1. Esperar prompts específicos por fase
2. NO avanzar a siguiente fase sin aprobación de CLAUDE
3. Documentar TODOS los cambios en 05_MIGRACIONES.md
4. Probar cada componente antes de marcar como completo
5. Seguir patrones ya establecidos en items-index.blade.php

### Para QWEN:
1. Validar schema de BD en FASE 2
2. Realizar auditoría técnica completa en FASE 6
3. Recomendar optimizaciones de performance
4. Documentar hallazgos en markdown estructurado

### Para CLAUDE (yo):
1. Coordinar secuencia de trabajo
2. Validar cada entrega antes de aprobar
3. Resolver ambigüedades y decisiones de diseño
4. Consolidar documentación final
5. Comunicar progreso al usuario

---

## ⚠️ RIESGOS Y MITIGACIONES

### Riesgo 1: Migración rompe funcionalidad existente
**Mitigación**:
- Migrar un componente a la vez
- Probar en navegador antes de continuar
- Mantener backup de archivos originales
- Validar funcionalidad Livewire intacta

### Riesgo 2: Producción backend no se integra bien
**Mitigación**:
- Validación exhaustiva de QWEN en schema
- Validación de CLAUDE en lógica de negocio
- Crear pruebas unitarias para Service
- Documentar transacciones y rollbacks

### Riesgo 3: Sobrecarga de trabajo para CODEX
**Mitigación**:
- Dividir en fases pequeñas y manejables
- Permitir breaks entre fases
- Priorizar calidad sobre velocidad
- Validaciones frecuentes

### Riesgo 4: Menú simplificado no satisface al usuario
**Mitigación**:
- Presentar propuesta ANTES de implementar
- Permitir iteraciones en el diseño
- Mantener flexibilidad para cambios
- Documentar decisiones de UX

---

**FIN DEL PLAN MAESTRO**

---

## 🎬 PRÓXIMOS PASOS INMEDIATOS

1. ✅ Presentar este plan al usuario para aprobación
2. ⏳ Esperar confirmación o ajustes del usuario
3. 🚀 Iniciar FASE 1A: Migración Catálogos con CODEX
4. ⚡ Iniciar FASE 2A en paralelo: Service Producción con CODEX

**Estado**: Plan listo para ejecución
**Esperando**: Aprobación del usuario
