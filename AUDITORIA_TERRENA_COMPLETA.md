# AUDITORÍA COMPLETA DEL SISTEMA TERRENA

**Fecha de análisis:** jueves, 13 de noviembre de 2025  
**Auditor:** Qwen Code  
**Proyecto:** TerrenaLaravel - ERP para Restaurantes

---

## RESUMEN EJECUTIVO

Después de realizar un análisis exhaustivo de 6 fases, se identificaron importantes brechas entre la documentación y la implementación actual del sistema Terrena. Aunque la base arquitectónica es sólida con una base de datos enterprise-grade (esquema `selemti` con 141 tablas normalizadas), muchas funcionalidades documentadas no están completamente implementadas.

**Hallazgos críticos:**
- El motor de Replenishment está completamente documentado pero no implementado
- El versionado de recetas está planificado pero no implementado
- La UI operativa de producción está documentada pero no existe
- Existen varios servicios duplicados o con funcionalidad parcial

---

## FASE 1 - Análisis de documentación en `/docs` y `D:\\Tavo\\2025\\UX\\`

### Tabla de módulos por documentación

| Módulo | Descripción breve | Docs origen (rutas) | Comentarios (inconsistencias, ideas sueltas, etc.) |
|--------|------------------|-------------------|---------------------------------------------------|
| Inventario | Gestión de items, recepciones, conteos, transferencias | `/docs/Inventario/*`, `/docs/V4.0/Inventario/*`, `docs/UI-UX/ANÁLISIS MÓDULO INVENTARIO - TERRENA LARAVEL.md` | Documentación bastante completa, pero existen discrepancias entre la versión V4.0 y las descripciones históricas. Se mencionan servicios como `TransferService` que aún no están completamente implementados. |
| Recetas | Gestión de recetas, costeo, unidades de medida | `/docs/Recetas/*`, `/docs/V4.0/Recetas/README.md`, `/docs/Recetas/STATUS_RECETAS_*.md` | Documentación detallada con múltiples versiones, pero hay una diferencia entre la funcionalidad actual (solo versión 1) y la funcionalidad deseada (versionado completo). |
| Producción | Órdenes de producción, planificación | `/docs/Produccion/*`, `/docs/V4.0/Produccion/README.md` | Documentación parcial, la UI operativa está mencionada pero no implementada completamente. |
| Compras/Replenishment | Solicitudes, órdenes de compra, motor de sugerencias | `/docs/Purchasing/README.md`, `/docs/V4.0/Purchasing/README.md`, `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md` | Existe un plan detallado para el motor de Replenishment, pero está marcado como pendiente de implementación. |
| POS | Integración con sistema POS, mapeos, auditoría | `/docs/POS/*`, `/docs/V4.0/POS/README.md`, `/docs/PosConsumption/*` | Buena documentación de integración, pero algunos endpoints están sin exponer en las rutas. |
| Caja Chica | Gestión de fondos, movimientos, arqueos | `/docs/CajaChica/*`, `/docs/V4.0/Finanzas/README.md` | Documentación funcional, pero el módulo está algo desacoplado del resto del sistema. |
| Reportes | KPIs, dashboards, exportaciones | `/docs/Reports/*`, `/docs/V4.0/Reports/README.md` | Existen vistas y funciones SQL documentadas, pero falta funcionalidad de exportación. |
| Arquitectura | Stack tecnológico, patrones de diseño | `/docs/Arquitectura/*`, `/docs/V4.0/Arquitectura/README.md` | Documentación técnica muy completa, alineada con la implementación actual. |
| UI/UX | Componentes, patrones de diseño | `/docs/UI-UX/*`, `docs/V4.0/Frontend/Componentes.md`, `docs/V4.0/Frontend/Layout.md` | Existe un plan maestro detallado, con componentes reutilizables definidos. |
| Seguridad/Permisos | Sistema de roles y permisos | `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md`, `docs/V4.0/Guia/Stack.md` | Sistema basado en Spatie Permissions documentado con 44 permisos atómicos y 7 roles predefinidos. |

### Ideas, acuerdos o definiciones que quedaron "al aire"

1. **Motor de Replenishment**: Documentado en detalle en `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md` pero marcado como pendiente de implementación (sprint 2).

2. **Versionado de Recetas**: Documentado pero en la práctica solo se usa la versión 1, sin funcionalidad de versionado real.

3. **UI de Producción**: Existe un servicio operativo pero la UI operativa está marcada como pendiente.

4. **API POS sin exponer**: El controlador `App\Http\Controllers\Pos\RecipeCostController` no está expuesto en las rutas, aunque está implementado.

5. **Integración con órdenes de compra**: En recepciones, existe la documentación de que debería haber asociación con PO pero no está implementada.

### Lógica diseñada pero NO implementada

1. **Validación/aprobación en recepciones**: `ReceptionService` marca todo como `RECIBIDO` pero el flujo deseado incluye `BORRADOR → VALIDADO → POSTEADO`.

2. **UI de ajustes rápidos**: Documentada en wireflows de `docs/V4.0/Inventario/Mermas.md` pero no implementada.

3. **Múltiples versiones de recetas**: Documentadas en `docs/V4.0/Recetas/README.md` pero el editor actual sobreescribe siempre `version=1`.

### Contradicciones entre documentos

1. **Servicios duplicados**: Existe `ReceptionService` y `ReceivingService` documentados como diferentes módulos, lo que puede causar confusión.

2. **UI inconsistente en conversiones**: En `docs/V4.0/Recetas/README.md` se menciona que la vista Blade espera propiedades (`u_origen`, `showForm`) que no existen en el componente Livewire actual.

**Resumen general**: La documentación de Terrena es bastante completa en cuanto a arquitectura y planificación general (especialmente en `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md`), pero existe una brecha significativa entre lo documentado y lo implementado, especialmente en funcionalidades avanzadas como el motor de Replenishment, versionado de recetas, y flujos completos de validación/aprobación.

**NOTA IMPORTANTE:** No se pudo acceder directamente a la carpeta `D:\\Tavo\\2025\\UX\\` desde este entorno de desarrollo. El análisis no incluye el contenido de esa carpeta.

---

## FASE 2 - Revisión de /docs/V4.0 comparando con compendio de Fase 1

### Comparación por módulos:

#### 1. Módulo Inventario
**Documentación V4.0 completa:**
- `/docs/V4.0/Inventario/Items.md` - Alta de ítems
- `/docs/V4.0/Inventario/Recepciones.md` - Recepciones y lotes  
- `/docs/V4.0/Inventario/Disponibilidad.md` - Dashboard/Kardex
- `/docs/V4.0/Inventario/Transferencias.md` - Transferencias
- `/docs/V4.0/Inventario/Conteos.md` - Conteos físicos
- `/docs/V4.0/Inventario/Mermas.md` - Mermas y ajustes

**¿Completo y alineado?** Parcialmente. La documentación está bien estructurada pero falta implementación de varios servicios como `TransferService` real y `ReceptionService` con flujos completos de validación/aprobación.

**Qué le falta a V4.0:**
- Detalles sobre el servicio `TransferService` y su implementación real (actualmente solo hay código de transferencias pero no está completamente funcional según la documentación)
- Detalles sobre el flujo completo de validación/aprobación en recepciones
- Documentación sobre el cálculo de stock disponible real con todos los estados (confirmado, en tránsito, etc.)

#### 2. Módulo Recetas
**Documentación V4.0 completa:**
- `/docs/V4.0/Recetas/README.md` - Recetas y costeo

**¿Completo y alineado?** Parcialmente. La documentación técnica es completa, pero hay brechas importantes:
- Versionado de recetas mencionado pero no implementado completamente
- Funciones de costeo documentadas pero no todas implementadas
- UI de versionado mencionada pero solo se usa versión 1

**Qué le falta a V4.0:**
- Documentación sobre el versionado real de recetas
- Detalles sobre la UI para gestionar múltiples versiones
- Documentación sobre la propagación de cambios de costos a través de versiones

#### 3. Módulo Producción
**Documentación V4.0 completa:**
- `/docs/V4.0/Produccion/README.md` - Producción

**¿Completo y alineado?** Parcialmente. Se menciona que hay un servicio operativo (`Inventory\\ProductionService`) pero la UI operativa está pendiente.

**Qué le falta a V4.0:**
- Documentación de la UI operativa de producción
- Detalles sobre la integración real entre el API y el servicio de producción
- Documentación sobre los flujos completos de órdenes de producción

#### 4. Módulo Compras/Replenishment
**Documentación V4.0 completa:**
- `/docs/V4.0/Purchasing/README.md` - Compras y Replenishment

**¿Completo y alineado?** No, está muy incompleto. El motor de Replenishment está mencionado pero no implementado, a pesar de que hay una documentación muy detallada en `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md`.

**Qué le falta a V4.0:**
- Documentación sobre el motor de Replenishment real con todos sus algoritmos
- Detalles sobre las políticas de stock (Min-Max, SMA, POS consumption)
- UI de pedidos sugeridos con razón de cálculo
- Simulador de Costo

#### 5. Módulo POS
**Documentación V4.0 completa:**
- `/docs/V4.0/POS/README.md` - POS y Consumos

**¿Completo y alineado?** Parcialmente. La documentación existe pero hay endpoints sin exponer.

**Qué le falta a V4.0:**
- Documentación sobre la exposición real de los endpoints POS
- Detalles sobre el `Pos\\RecipeCostController` que no está en las rutas

#### 6. Módulo Caja Chica
**Documentación V4.0 completa:**
- `/docs/V4.0/Finanzas/README.md` - Finanzas operativas

**¿Completo y alineado?** Parcialmente. Documenta caja chica pero hay poca información sobre la integración con otros módulos financieros.

**Qué le falta a V4.0:**
- Documentación más detallada sobre el flujo completo de caja chica
- Integración con reportes de cierre y conciliación

### Lista de ajustes recomendados para V4.0:

#### [Agregar]:
1. **Motor de Replenishment** con todos sus algoritmos (Min-Max, SMA, POS consumption)
2. **UI de versionado de recetas completa** con manejo de múltiples versiones
3. **Documentación del estado real de transferencias** (borrador → solicitada → despachada → recibida)
4. **Flujo de validación/aprobación en recepciones** con tolerancias y evidencias

#### [Corregir]:
1. **Documentación sobre `ReceptionService` vs `ReceivingService`** para aclarar cual es cual
2. **UI inconsistente en conversiones** para reflejar el estado real del componente
3. **Endpoint de POS faltante** en `Pos\\RecipeCostController`

#### [Eliminar]:
1. **Descripciones de funcionalidades no implementadas** como la UI de producción completa
2. **Documentación de "features a futuro"** que no están implementadas

---

## FASE 3 - Integración documental proponiendo estructura ordenada

### Estructura propuesta de documentación (árbol de carpetas/archivos):

```
docs/V4.0/
├── Arquitectura/
│   ├── README.md (estructura ya existe)
│   ├── Estructura-Proyecto.md
│   └── Diagramas/
├── Frontend/
│   ├── Layout.md (ya existe)
│   ├── Componentes.md (ya existe)
│   ├── UI-UX-Guidelines.md
│   └── Wireframes/
├── Catalogos/
│   ├── Unidades.md
│   ├── Conversiones.md
│   ├── Proveedores.md
│   ├── Categorias.md
│   ├── Sucursales.md
│   └── Almacenes.md
├── Inventario/
│   ├── Items.md (ya existe)
│   ├── Recepciones.md (ya existe)
│   ├── Disponibilidad.md (ya existe)
│   ├── Transferencias.md (ya existe)
│   ├── Conteos.md (ya existe)
│   ├── Mermas.md (ya existe)
│   ├── Kardex.md
│   └── PoliticasStock.md
├── Recetas/
│   ├── README.md (ya existe)
│   ├── Versionado.md
│   ├── Costeo.md
│   └── Subrecetas.md
├── Produccion/
│   ├── README.md (ya existe)
│   ├── OrdenesProduccion.md
│   ├── Planificacion.md
│   └── KPIs.md
├── Purchasing/
│   ├── Solicitudes.md
│   ├── OrdenesCompra.md
│   ├── Cotizaciones.md
│   ├── Replenishment.md
│   └── Devoluciones.md
├── POS/
│   ├── README.md (ya existe)
│   ├── Mapeos.md
│   ├── Consumos.md
│   └── Auditoria.md
├── Caja/
│   ├── FondoCaja.md
│   ├── Cortes.md
│   ├── Arqueos.md
│   └── Conciliaciones.md
├── Finanzas/
│   ├── README.md (ya existe)
│   ├── Indicadores.md
│   └── Reportes.md
├── Seguridad/
│   ├── Permisos.md
│   ├── Roles.md
│   └── Auditoria.md
├── Reportes/
│   ├── README.md (ya existe)
│   ├── KPIs.md
│   ├── Ventas.md
│   ├── Inventario.md
│   ├── Produccion.md
│   └── Exportaciones.md
└── Guia/
    ├── Stack.md (ya existe)
    ├── Convenciones.md
    └── Checklist.md
```

### Tabla de mapeo:

| Archivo destino | Tipo de contenido | Fuentes | Pendientes |
|----------------|------------------|---------|------------|
| `docs/V4.0/Catalogos/PoliticasStock.md` | Política de stock, min-max, lead times | `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md`, BD | Implementación real de motor |
| `docs/V4.0/Inventario/Kardex.md` | Kardex, movimientos, trazabilidad | `docs/V4.0/Inventario/Disponibilidad.md`, views SQL | Implementación UI completa |
| `docs/V4.0/Recetas/Versionado.md` | Versionado de recetas, flujos | `docs/V4.0/Recetas/README.md`, `docs/Recetas/STATUS_RECETAS_*.md` | Implementación real de UI |
| `docs/V4.0/Produccion/OrdenesProduccion.md` | Órdenes de producción, ciclos | `docs/V4.0/Produccion/README.md`, `docs/Produccion/PRODUCTION_FLOW.md` | UI operativa completa |
| `docs/V4.0/Purchasing/Replenishment.md` | Motor de sugerencias, algoritmos | `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md`, `docs/BD/scripts/` | Implementación completa |
| `docs/V4.0/Seguridad/Permisos.md` | Matriz de permisos, roles | `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md`, `docs/UI-UX/v6/PERMISSIONS_MATRIX_V6.md` | Implementación real de GUI de permisos |
| `docs/V4.0/Caja/Conciliaciones.md` | Conciliación bancaria, corte | `docs/CajaChica/`, vistas SQL | Documentación de flujos pendientes |
| `docs/V4.0/Reportes/Exportaciones.md` | Exportación CSV/PDF | `docs/Reports/`, vistas SQL | Implementación de funcionalidad |

### Recomendaciones adicionales:

1. **Consolidar documentación redundante**: Muchos detalles sobre componentes de UI y estructura están dispersos entre diferentes archivos. Crear un solo punto de información por tema.

2. **Actualizar estado real de implementación**: Algunos archivos describen funcionalidades que no están completamente implementadas. Marcar claramente qué es funcional y qué está pendiente.

3. **Alinear con base de datos**: Muchos archivos mencionan tablas y vistas que deben estar reflejadas en la documentación actualizada.

4. **Agregar dependencias entre módulos**: Documentar cómo se relacionan los diferentes módulos entre sí (por ejemplo, cómo una recepción afecta las sugerencias de pedidos).

---

## FASE 4 - Análisis de código y funcionalidades del proyecto

### Análisis por módulo:

#### 1. Módulo Inventario

**Funcionalidades implementadas:**
- `app/Livewire/Inventory/InsumoCreate.php` y `ItemsManage.php` - Alta y gestión de ítems
- `app/Services/Inventory/ReceptionService.php` - Servicio de recepciones
- `app/Livewire/Inventory/ReceptionsIndex.php`, `ReceptionCreate.php`, `ReceptionDetail.php` - UI de recepciones
- `app/Services/Inventory/TransferService.php` - Servicio de transferencias (parcialmente implementado)
- `app/Livewire/Inventory/Transferencias.php` - UI de transferencias (con estados parciales)
- `app/Models/Inv/Item.php` y `InventoryBatch.php` - Modelos principales
- `app/Models/InventoryCount.php` y `InventoryCountLine.php` - Conteos de inventario

**Funcionalidades NO implementadas según documentación:**
- Flujos completos de validación/aprobación en recepciones (solo se implementa RECIBIDO)
- Estados completos en transferencias (solo parcialmente implementado)
- UI de ajustes rápidos mencionados en wireflows

**Código que no está completamente documentado:**
- `app/Services/Inventory/InventoryCountService.php` - Servicio para conteos pero la documentación V4.0 es limitada
- `app/Services/Inventory/ProductionService.php` - Mencionado pero no detallado completamente

#### 2. Módulo Recetas

**Funcionalidades implementadas:**
- `app/Livewire/Recipes/RecipesIndex.php` y `RecipeEditor.php` - UI de recetas
- `app/Models/Rec/Receta.php`, `RecetaVersion.php`, `RecetaDetalle.php` - Modelos de recetas
- `app/Services/Costing/RecipeCostingService.php` - Servicio de costeo
- `app/Services/Recetas/RecalcularCostosRecetasService.php` - Recálculo de costos
- `app/Livewire/Recipes/UnidadesIndex.php` y `ConversionesIndex.php` - Catálogos de UOM

**Funcionalidades NO implementadas según documentación:**
- Sistema completo de versionado (actualmente solo se usa versión 1)
- UI de comparación de versiones
- Funcionalidad completa de costeo con múltiples versiones

**Código que no está completamente documentado:**
- `App\Models\\Rec\\RecetaShadow.php` - Recetas sombra del POS con poca documentación
- `app/Services/Pos/PosConsumptionService.php` - Servicio de consumo POS con funcionalidad pero poca documentación

#### 3. Módulo Compras/Replenishment

**Funcionalidades implementadas:**
- `app/Livewire/Purchasing/PurchaseOrder.php`, `PurchaseRequest.php` - Solicitudes y órdenes de compra
- `app/Models/Purchasing/PurchaseOrder.php`, `PurchaseRequest.php` - Modelos
- `app/Services/Purchasing/ReceivingService.php` - Servicio de recepción (posible duplicado con Inventory\\ReceptionService)

**Funcionalidades NO implementadas según documentación:**
- Motor de Replenishment con sus algoritmos (Min-Max, SMA, POS consumption)
- UI de pedidos sugeridos con razón de cálculo
- Simulador de Costo

**Código que no está completamente documentado:**
- Las relaciones entre `ReceivingService` e `Inventory\\ReceptionService` - posiblemente duplicados o con diferentes propósitos no claros

#### 4. Módulo Producción

**Funcionalidades implementadas:**
- `app/Models/ProductionOrder.php` - Modelo de órdenes de producción
- `app/Services/Inventory/ProductionService.php` - Servicio de producción (mencionado en V4.0)

**Funcionalidades NO implementadas según documentación:**
- UI operativa de producción completa
- KPIs de rendimiento documentados

#### 5. Módulo POS

**Funcionalidades implementadas:**
- `app/Livewire/Pos/PosMap.php` - UI de mapeo POS
- `app/Models/PosMap.php` - Modelo de mapeo
- `app/Services/Pos/PosConsumptionService.php` - Servicio de consumo POS

**Funcionalidades NO implementadas según documentación:**
- `App\\Http\\Controllers\\Pos\\RecipeCostController` - Controlador POS mencionado pero no expuesto en rutas

#### 6. Módulo Caja Chica

**Funcionalidades implementadas:**
- `app/Models/CashFund.php`, `CashFundMovement.php`, `CashFundArqueo.php` - Modelos de caja
- `app/Livewire/CashFund/*` - Componentes Livewire de caja
- `app/Services/Cash/*` - Servicios de caja

**Funcionalidades NO implementadas según documentación:**
- Algunas funcionalidades avanzadas de verificación y checklist mencionadas en documentación histórica

### Tabla de mapeo por módulo:

| Módulo | Funcionalidad | Estado | Rutas de archivos | Notas |
|--------|---------------|--------|-------------------|-------|
| Inventario | Alta de ítems | Implementado | `app/Livewire/Inventory/InsumoCreate.php` | Funcional completo |
| Inventario | Recepciones | Parcial | `app/Services/Inventory/ReceptionService.php`, `app/Livewire/Inventory/*` | Falta validación/aprobación |
| Inventario | Transferencias | Parcial | `app/Services/Inventory/TransferService.php`, `app/Livewire/Inventory/Transferencias.php` | Estados parcialmente implementados |
| Recetas | Editor de recetas | Implementado | `app/Livewire/Recipes/RecipeEditor.php` | Sin versionado real |
| Recetas | Costeo | Implementado | `app/Services/Costing/RecipeCostingService.php` | Funcional pero limitado |
| Compras | Órdenes de compra | Implementado | `app/Livewire/Purchasing/PurchaseOrder.php` | Sin motor de sugerencias |
| Compras | Motor de Replenishment | No implementado | - | Documentado pero no implementado |
| Producción | Órdenes de producción | Parcial | `app/Services/Inventory/ProductionService.php` | UI operativa pendiente |
| POS | Mapeo | Implementado | `app/Livewire/Pos/PosMap.php` | Endpoint POS no expuesto |
| Caja Chica | Fondo de caja | Implementado | `app/Livewire/CashFund/*` | Completo en lo básico |

---

## FASE 5 - Análisis de base de datos (esquema selemti)

### Lista de objetos de BD con análisis de uso:

| Objeto | Tipo | Uso: En docs / En código / Ambos / Ninguno | Comentarios |
|--------|------|------------------------------------------|-------------|
| `almacen` | Tabla | Ambos | Relacionada con `sucursal`, usada en inventarios y transferencias |
| `auditoria` | Tabla | En docs | Sistema de auditoría global mencionado en documentación |
| `cat_unidades` | Tabla | Ambos | Catálogo de unidades de medida, usado en recetas e inventarios |
| `conversiones_unidad` | Tabla | Ambos | Conversiones entre unidades, mencionadas en UOM strategy docs |
| `cost_layer` | Tabla | En docs | Relacionada con costeo de inventarios, mencionada en recetas/inventario |
| `formas_pago` | Tabla | En docs | Formas de pago POS, posiblemente usadas en caja |
| `historial_costos_item` | Tabla | Ambos | Histórico de costos por ítem, usado en recetas y costeo |
| `historial_costos_receta` | Tabla | Ambos | Histórico de costos por receta, mencionado en recetas |
| `inventory_batch` | Tabla | Ambos | Lotes de inventario, centro del sistema de inventario |
| `item_vendor` | Tabla | Ambos | Proveedores por ítem, usado en recepciones y compras |
| `items` | Tabla | Ambos | Tabla principal de ítems, usada en todo el sistema |
| `job_recalc_queue` | Tabla | En docs | Cola de recálculos, mencionada en servicios de recetas |
| `modificadores_pos` | Tabla | Ambos | Modificadores POS, vinculados a recetas |
| `mov_inv` | Tabla | Ambos | Movimientos de inventario, base del kardex |
| `op_produccion_cab` | Tabla | En docs | Órdenes de producción, mencionadas en producción |
| `param_sucursal` | Tabla | En docs | Parámetros por sucursal, usados en caja/cortes |
| `perdida_log` | Tabla | En docs | Registro de pérdidas/mermas, mencionadas en documentación |
| `pos_map` | Tabla | Ambos | Mapeo entre POS y recetas, clave para integración |
| `postcorte` | Tabla | Ambos | Datos de postcorte, usado en módulo de caja |
| `precorte` | Tabla | Ambos | Datos de precorte, usado en módulo de caja |
| `proveedor` | Tabla | En docs | Catálogo de proveedores, usado en compras |
| `receta_cab` | Tabla | Ambos | Cabecera de recetas, usada en módulo de recetas |
| `receta_det` | Tabla | Ambos | Detalle de recetas, usado en módulo de recetas |
| `receta_shadow` | Tabla | En docs | Recetas inferidas del POS, mencionadas en documentación |
| `receta_version` | Tabla | Ambos | Versiones de recetas, mencionadas en versionado |
| `sesion_cajon` | Tabla | Ambos | Sesiones de caja, usado en módulo de caja |
| `stock_policy` | Tabla | En docs | Políticas de stock, mencionadas en Replenishment |
| `sucursal` | Tabla | Ambos | Catálogo de sucursales, usado en todo el sistema |
| `ticket_det_consumo` | Tabla | En docs | Consumo de ítems por ticket, usado en análisis POS |
| `ticket_venta_cab` | Tabla | En docs | Cabecera de ventas POS, usado en análisis POS |
| `ticket_venta_det` | Tabla | En docs | Detalle de ventas POS, usado en análisis POS |
| `unidades_medida` | Tabla | Ambos | Unidades de medida, usado en inventario y recetas |
| `users` | Tabla | Ambos | Usuarios del sistema, usado en permisos y auditoría |

### Vistas identificadas:

| Objeto | Tipo | Uso: En docs / En código / Ambos / Ninguno | Comentarios |
|--------|------|------------------------------------------|-------------|
| `v_ingenieria_menu_completa` | Vista | En docs | Vista con recetas y costos, usada en informes |
| `v_items_con_uom` | Vista | En docs | Vista de ítems con UOM, usada en UI |
| `v_merma_por_item` | Vista | En docs | Métricas de merma por ítem |
| `v_stock_actual` | Vista | Ambos | Stock actual por ítem |
| `v_stock_brechas` | Vista | En docs | Brechas de stock vs políticas |
| `vw_anulaciones_por_terminal_dia` | Vista | En docs | Anulaciones por terminal |
| `vw_conciliacion_efectivo` | Vista | En docs | Conciliación de efectivo |
| `vw_conciliacion_sesion` | Vista | En docs | Conciliación de sesiones |
| `vw_conciliacion_tarjetas` | Vista | En docs | Conciliación de tarjetas |
| `vw_descuentos_por_terminal_dia` | Vista | En docs | Descuentos por terminal |
| `vw_fast_tickets` | Vista | En docs | Tickets rápidos |
| `vw_fast_tx` | Vista | En docs | Transacciones rápidas |
| `vw_pagos_por_terminal_dia` | Vista | En docs | Pagos por terminal |
| `vw_resumen_conciliacion_terminal_dia` | Vista | En docs | Resumen de conciliación |
| `vw_sesion_descuentos` | Vista | En docs | Descuentos por sesión |
| `vw_sesion_dpr` | Vista | En docs | Informes de sesión detallados |
| `vw_sesion_reembolsos_efectivo` | Vista | En docs | Reembolsos de efectivo |
| `vw_sesion_retiros` | Vista | En docs | Retiros por sesión |
| `vw_sesion_ventas` | Vista | En docs | Ventas por sesión |

### Análisis de alineación con código y documentación:

**Tablas bien alineadas con documentación y código:**
- `items`, `inventory_batch`, `mov_inv` - Forman la base del módulo de inventario
- `receta_cab`, `receta_det`, `receta_version` - Forman la base del módulo de recetas
- `pos_map` - Usada para integración POS
- `cash` relacionadas (`postcorte`, `precorte`, `sesion_cajon`) - Usadas en módulo de caja

**Tablas con funcionalidad parcial o pendiente:**
- `stock_policy` - Mencionada en Replenishment pero el motor no está completamente implementado
- `op_produccion_cab` - Mencionada en producción pero la UI operativa está pendiente
- `receta_shadow` - Existe en BD pero no hay UI para validar recetas inferidas

**Vistas que necesitan integración con código:**
- `v_stock_brechas`, `v_merma_por_item` - Vistas de reportes mencionadas pero posiblemente no usadas en UI
- `vw_*` vistas de conciliación - Relacionadas con módulo de caja pero posiblemente no completamente integradas

### Análisis de relaciones clave:

La base de datos está bien estructurada con relaciones adecuadas entre:
- `items` ↔ `inventory_batch` (ítems y sus lotes)
- `inventory_batch` ↔ `mov_inv` (lotes y movimientos)
- `items` ↔ `receta_det` (ítems como ingredientes de recetas)
- `receta_cab` ↔ `receta_version` (recetas y sus versiones)
- `receta_det` → `receta_cab` (subrecetas)
- `items` ↔ `item_vendor` (ítems y proveedores)

**Comentarios finales:**
La base de datos `selemti` está bien estructurada y normalizada como se menciona en la documentación. La mayoría de las tablas y vistas mencionadas en la documentación existen realmente en el esquema. Sin embargo, hay varias funcionalidades mencionadas en la documentación que no están completamente implementadas en el código, lo que se alinea con los hallazgos de las fases anteriores.

---

## FASE 6 - Evaluación UI/UX del sistema

### Análisis de componentes UI existentes

#### 1. Componentes Reutilizables
**Buenas prácticas detectadas:**
- Estructura de componentes Blade en `resources/views/components/` organizada por funcionalidad
- Componentes de UI genéricos como `<x-ui.input>`, `<x-ui.select>`, `<x-ui.card>`, etc.
- Componentes específicos como `<x-inventory.item-card>`, `<x-transfer.transfer-form>`

**Áreas de mejora:**
- Algunos componentes no están completamente documentados en `docs/V4.0/Frontend/Componentes.md`
- Posible inconsistencia en estilos entre componentes nuevos y legacy

#### 2. Layout y Estructura
**Buenas prácticas detectadas:**
- Uso de `layouts.terrena` como layout principal
- Sidebar de navegación con enfoque en módulos (Inventario, Recetas, Compras, etc.)
- Sistema de permisos integrado en la UI

**Áreas de mejora:**
- La navegación puede volverse confusa con el aumento de módulos
- Posible falta de consistencia en el enfoque de los elementos después de acciones (focus management)

#### 3. Módulo de Inventario

**Problemas de UI/UX identificados:**
- **Formulario de alta de ítems**: Aunque hay un "wizard de 2 pasos" documentado, el proceso real puede no ser tan intuitivo
- **Recepciones**: La UI de recepciones parece compleja para usuarios operativos; falta evidencia de validación en tiempo real
- **Transferencias**: El proceso de transferencia (borrador → solicitada → despachada → recibida) no está completamente implementado en UI
- **Conteos**: La experiencia de conteo físico puede ser mejorada para operaciones rápidas

**Sugerencias de mejora:**
- Implementar validación en tiempo real con Alpine.js en todos los formularios
- Añadir tooltips explicativos en campos confusos
- Crear componentes móviles para conteos físicos
- Simplificar el flujo de recepciones con pasos claramente indicados

#### 4. Módulo de Recetas

**Problemas de UI/UX identificados:**
- **Versionado**: Aunque documentado, la UI no refleja completamente la funcionalidad de múltiples versiones
- **Costeo**: La visualización de costos puede ser más clara y detallada
- **Editor**: El editor de recetas puede volverse complejo con recetas de múltiples niveles

**Sugerencias de mejora:**
- Añadir visualización clara de la estructura de ingredientes (BOM)
- Implementar comparación visual entre versiones de recetas
- Añadir resumen de costos y márgenes en tiempo real
- Mostrar alertas de costo alto directamente en el editor

#### 5. Módulo de Compras y Replenishment

**Problemas de UI/UX identificados:**
- **Motor de Replenishment**: No implementado en UI, aunque está bien documentado
- **Sugerencias de pedidos**: Falta una UI intuitiva para gestionar las sugerencias de compra
- **Órdenes de compra**: Posible falta de integración visual con recepciones

**Sugerencias de mejora:**
- Implementar un dashboard de sugerencias con justificación clara de cada recomendación
- Añadir simulador de costos antes de confirmar órdenes
- Crear flujo integrado entre órdenes y recepciones

#### 6. Módulo de Producción

**Problemas de UI/UX identificados:**
- **UI operativa**: Documentada pero posiblemente no implementada completamente
- **Seguimiento de OPs**: Posible falta de visibilidad en el estado de las órdenes de producción
- **Consumo teórico vs real**: No claramente visualizado

**Sugerencias de mejora:**
- Implementar KDS (Kitchen Display System) para seguimiento de producción
- Crear panel de control visual para supervisores de producción
- Añadir métricas de eficiencia y merma en tiempo real

#### 7. Módulo de Caja Chica

**Problemas de UI/UX identificados:**
- **Flujo de operación**: Aunque funcional, puede necesitar refinamiento para usuarios cotidianos
- **Arqueos**: Proceso de conteo físico puede mejorarse con mejor UX

**Sugerencias de mejora:**
- Simplificar el proceso de arqueo con interfaz tipo conteo físico
- Añadir confirmación visual de diferencias
- Implementar checklist de verificación

#### 8. Consistencia Visual General

**Problemas de UI/UX identificados:**
- **Estilos mezclados**: Posible mezcla de Bootstrap 5 (legacy) y Tailwind CSS
- **Componentes inconsistentes**: Algunas pantallas pueden usar estilos antiguos vs nuevos
- **Experiencia móvil**: Posible falta de atención al diseño responsive

**Sugerencias de mejora:**
- Establecer una guía de estilos unificada
- Migrar completamente a Tailwind CSS para consistencia
- Implementar diseño responsive en todas las pantallas críticas

### Tabla de problemas UI/UX por módulo:

| Problema | Impacto | Sugerencia de mejora |
|----------|---------|---------------------|
| Proceso de recepción complejo | Medio | Implementar wizard con validación en tiempo real |
| Falta de versionado visible en recetas | Alto | Crear UI específica para gestionar diferentes versiones |
| Motor de Replenishment no implementado | Muy Alto | Priorizar implementación del dashboard de sugerencias |
| UI de producción incompleta | Medio | Desarrollar panel operativo para producción |
| Formularios sin validación en línea | Medio | Implementar validación con Alpine.js |
| Inconsistencia entre estilos legacy y nuevos | Medio | Unificar enfoque de diseño con Tailwind |
| Falta de visibilidad en transferencias | Medio | Completar flujo con estados: borrador → solicitada → despachada → recibida |
| Condiciones de carrera en UI | Bajo | Implementar feedback visual durante operaciones asíncronas |

---

## RECOMENDACIONES FINALES

### Prioridades de implementación:

1. **Motor de Replenishment** - Funcionalidad crítica que está documentada pero no implementada, con impacto directo en la gestión de inventarios y compras.

2. **Versionado de recetas** - Necesario para mantener el historial de cambios y para la gestión de costos precisos.

3. **UI operativa de producción** - Complementaria al servicio que ya existe pero sin interfaz para usuarios.

4. **Completar flujos de validación/aprobación** - En recepciones y transferencias para garantizar integridad de datos.

5. **Mejorar experiencia de usuario** - Implementar validaciones en línea, mejorar la navegación, y unificar los estilos visuales.

### Seguimiento de alineación:

- **Documentación vs Código**: Alinear `docs/V4.0` con la realidad del código implementado
- **Código vs Base de datos**: Verificar que todas las relaciones y vistas documentadas estén correctamente implementadas
- **Experiencia de usuario**: Priorizar mejoras que impacten directamente en la usabilidad del sistema

**Conclusión:** La base del sistema Terrena es sólida, pero hay una brecha significativa entre la visión documentada y la implementación real. El sistema tiene potencial para ser un ERP de clase mundial con las implementaciones adecuadas.