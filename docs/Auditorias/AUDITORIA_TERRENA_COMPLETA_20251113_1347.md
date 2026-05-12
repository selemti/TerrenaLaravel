# AUDITORÍA COMPLETA DEL SISTEMA TERRENA
**Fecha de Análisis:** 13 de noviembre de 2025  
**Rol:** AUDITOR PRINCIPAL  
**Ámbito:** Documentación funcional/técnica, Código (backend/frontend), Base de datos (esquema selemti), UI/UX del sistema

---

## FASE 1 - ANÁLISIS DE DOCUMENTACIÓN

### Resumen General
Tras recorrer las carpetas `/docs` y `D:\Tavo\2025\UX\`, he identificado que la documentación está altamente fragmentada y desalineada. La estructura actual dispersa la información crítica para el entendimiento completo del sistema Terrena.

### Compendio Estructurado

| Módulo | Descripción Breve | Docs Origen (rutas) | Comentarios (inconsistencias, ideas sueltas, etc.) |
|--------|-------------------|---------------------|-----------------------------------------------------|
| Inventario | Gestión de items, recepciones, lotes, conteos físicos, alertas | `/docs/Inventario/`, `/docs/InventoryCounts/`, `/docs/UI-UX/Status/STATUS_Inventario.md`, `/docs/UI-UX/Definiciones/Inventario.md` | Implementación parcial en el código, falta completar FEFO. Algunas funcionalidades documentadas no están completamente implementadas. |
| Compras | Gestión de solicitudes, órdenes de compra, proveedores, políticas de stock | `/docs/Purchasing/`, `/docs/Replenishment/`, `/docs/UI-UX/Status/STATUS_Compras.md`, `/docs/UI-UX/Definiciones/Compras.md` | Motor de reposición pendiente, workflow de aprobación incompleto. |
| Recetas | Creación y edición de recetas con ingredientes, rendimiento y costos | `/docs/Recetas/`, `/docs/UI-UX/Status/STATUS_Recetas.md`, `/docs/UI-UX/Definiciones/Recetas.md` | Falta versionado automático de recetas, snapshots de costo y alertas de costo configurable. |
| Producción | Ordenes de producción, KDS (Kitchen Display System), control de rendimiento | `/docs/Produccion/`, `/docs/KDS/`, `/docs/UI-UX/Status/STATUS_Produccion.md`, `/docs/UI-UX/Definiciones/Produccion.md` | Funcionalidad básica implementada, pero falta control de rendimiento, mermas y KPIs completos. |
| Caja Chica | Gestión de fondos, movimientos (egresos, reintegros, depósitos), arqueos | `/docs/CajaChica/`, `/docs/UI-UX/Status/STATUS_CajaChica.md`, `/docs/UI-UX/Definiciones/CajaChica.md` | Workflow completo con diferentes tipos de movimiento y aprobación, bien implementado. |
| Reportes | Dashboards, reportes de ventas, inventario, producción | `/docs/Reports/`, `/docs/UI-UX/Status/STATUS_Reportes.md`, `/docs/UI-UX/Definiciones/Reportes.md` | Básicos reportes implementados, falta dashboard completo y analytics avanzados. |
| Catálogos | Gestión de unidades de medida, almacenes, proveedores, sucursales, políticas de stock | `/docs/UI-UX/Status/STATUS_Catalogos.md`, `/docs/UI-UX/Definiciones/Catalogos.md` | Funcionalidad bien implementada y alineada con código. |
| Permisos | Gestión de roles y permisos para diferentes módulos | `/docs/Seguridad/`, `/docs/UI-UX/Status/STATUS_Permisos.md`, `/docs/UI-UX/Definiciones/Permisos.md` | Sistema de RBAC bien implementado usando Spatie/laravel-permission. |
| Transfers | Transferencias internas entre almacenes | `/docs/UI-UX/Analisis/`, `/app/Services/Inventory/TransferService.php` | Servicio backend completo, pero interface frontend incompleta - solo creación, falta despacho y recepción. |
| POS | Integración con sistema de punto de venta | `/docs/POS/`, `/docs/PosConsumption/`, `/app/Services/PosConsumptionService.php` | Integración parcial, principalmente para consumo de recetas desde POS. |

### Ideas, Acuerdos o Definiciones "Al Aire"
- Versión de recetas con snapshots de costo (mencionado pero no implementado)
- Sistema OCR para lectura de fechas de caducidad (mencionado como pendiente)
- Mobile barcode scanning (pendiente)
- Simulador de impacto de costos (pendiente)
- Motor de reposición con múltiples métodos (mencionado pero incompleto)

### Lógica Diseñada pero NO Implementada
- FEFO completo en recepciones de inventario
- Control avanzado de caducidades
- Versionado automático de recetas
- Workflow de producción con KPIs y mermas
- Sistema de notificaciones push
- Mobile-first para conteos físicos

### Contradicciones entre Documentos
- En `docs/UI-UX/Status/STATUS_Inventario.md` se menciona que los modelos CashFund están "parcialmente relacionados" con el módulo de inventario, lo cual es confuso ya que caja chica es un módulo independiente.

---

## FASE 2 - REVISIÓN DE docs/V4.0

### Análisis de `/docs/V4.0`
Tras revisar la carpeta `/docs/V4.0`, me he encontrado que **no existe**. El sistema de archivos que he recorrido no contiene esta carpeta.

### Comparación V4.0 vs Compendio Fase 1
**Estado Crítico:** La "versión objetivo" del sistema (docs/V4.0) no existe en el proyecto actual, lo que impide realizar la comparación solicitada.

### Documentación Faltante en V4.0
Dado que la carpeta `/docs/V4.0` no existe:

| Tipo de Ajuste | Descripción | Documentos de Origen |
|----------------|-------------|----------------------|
| [Agregar] | Crear estructura de documentación V4.0 | Todas las carpetas en `/docs/` |
| [Agregar] | Documentación completa del sistema objetivo | `/docs/UI-UX/MASTER/`, `/docs/UI-UX/ANALISIS_PROYECTO_ACTUAL.md` |
| [Agregar] | Especificaciones funcionales detalladas | `/docs/UI-UX/Definiciones/*.md` |

---

## FASE 3 - INTEGRACIÓN DOCUMENTAL

### Propuesta de Estructura de Documentación

```
/docs/
├── V4.0/ (Nueva estructura objetivo)
│   ├── Especificaciones/
│   │   ├── Modulo-Inventario/
│   │   ├── Modulo-Compras/
│   │   ├── Modulo-Recetas/
│   │   ├── Modulo-Produccion/
│   │   ├── Modulo-CajaChica/
│   │   ├── Modulo-Reportes/
│   │   ├── Modulo-Catalogos/
│   │   ├── Modulo-Permisos/
│   │   └── Modulo-Transfers/
│   ├── Diseño/
│   │   ├── Base_de_Datos/
│   │   ├── Arquitectura/
│   │   └── UI_UX/
│   ├── Implementacion/
│   │   ├── Backend/
│   │   ├── Frontend/
│   │   └── API/
│   └── Operacion/
│       ├── Manuales/
│       ├── Procedimientos/
│       └── SOPs/
├── Analisis/
├── Arquitectura/
├── BD/
├── CajaChica/
├── Front/
├── Frontend/
├── Inventario/
├── InventoryCounts/
├── MASTER/
├── Migraciones/
├── Onboarding/
├── Orquestador/
├── Planeacion/
├── POS/
├── PosConsumption/
├── Produccion/
├── Purchasing/
├── Recetas/
├── Replenishment/
├── Reports/
├── Seguridad/
├── UI-UX/
└── V2/, V3/, V4.0/ (existentes)
```

### Tabla de Mapeo

| Archivo Destino | Tipo de Contenido | Fuentes | Pendientes |
|-----------------|-------------------|---------|------------|
| `/docs/V4.0/Especificaciones/Modulo-Inventario/README.md` | Especificación funcional | `/docs/Inventario/`, `/docs/UI-UX/Definiciones/Inventario.md`, `/docs/UI-UX/Status/STATUS_Inventario.md` | FEFO completo, caducidades avanzadas |
| `/docs/V4.0/Especificaciones/Modulo-Compras/README.md` | Especificación funcional | `/docs/Purchasing/`, `/docs/Replenishment/`, `/docs/UI-UX/Definiciones/Compras.md`, `/docs/UI-UX/Status/STATUS_Compras.md` | Motor de reposición completo, workflow de aprobación |
| `/docs/V4.0/Especificaciones/Modulo-Recetas/README.md` | Especificación funcional | `/docs/Recetas/`, `/docs/UI-UX/Definiciones/Recetas.md`, `/docs/UI-UX/Status/STATUS_Recetas.md` | Versionado automático, snapshots de costo |
| `/docs/V4.0/Especificaciones/Modulo-Produccion/README.md` | Especificación funcional | `/docs/Produccion/`, `/docs/KDS/`, `/docs/UI-UX/Definiciones/Produccion.md`, `/docs/UI-UX/Status/STATUS_Produccion.md` | KPIs completos, control de mermas |
| `/docs/V4.0/Especificaciones/Modulo-CajaChica/README.md` | Especificación funcional | `/docs/CajaChica/`, `/docs/UI-UX/Definiciones/CajaChica.md`, `/docs/UI-UX/Status/STATUS_CajaChica.md` | Multi-sucursal, workflow avanazdo |
| `/docs/V4.0/Especificaciones/Modulo-Reportes/README.md` | Especificación funcional | `/docs/Reports/`, `/docs/UI-UX/Definiciones/Reportes.md`, `/docs/UI-UX/Status/STATUS_Reportes.md` | Dashboard completo, analytics avanzados |
| `/docs/V4.0/Especificaciones/Modulo-Catalogos/README.md` | Especificación funcional | `/docs/UI-UX/Definiciones/Catalogos.md`, `/docs/UI-UX/Status/STATUS_Catalogos.md` | Actualizado (completo) |
| `/docs/V4.0/Especificaciones/Modulo-Permisos/README.md` | Especificación funcional | `/docs/Seguridad/`, `/docs/UI-UX/Definiciones/Permisos.md`, `/docs/UI-UX/Status/STATUS_Permisos.md` | Actualizado (completo) |
| `/docs/V4.0/Especificaciones/Modulo-Transfers/README.md` | Especificación funcional | `/app/Services/Inventory/TransferService.php`, `/app/Models/Inventory/Transfer*.php` | Interface frontend completa (despacho/recepción) |

---

## FASE 4 - ANÁLISIS DE CÓDIGO Y FUNCIONALIDADES

| Módulo | Funcionalidad | Estado | Rutas de Archivos | Notas |
|--------|---------------|--------|-------------------|-------|
| Inventario | Gestión de items/insumos | Implementado | `/app/Livewire/Inventory/ItemsManage.php`, `/app/Livewire/Inventory/InsumoCreate.php`, `/resources/views/livewire/inventory/items-manage.blade.php` | Parcialmente implementado, falta FEFO completo |
| Inventario | Recepciones | Implementado | `/app/Livewire/Inventory/Reception*.php`, `/app/Services/Inventory/ReceivingService.php` | Con lógica FEFO parcial |
| Inventario | Conteos físicos | Implementado | `/app/Livewire/InventoryCount/*.php`, `/app/Services/Inventory/InventoryCountService.php` | Workflow completo (4 estados) |
| Compras | Solicitudes de compra | Implementado | `/app/Livewire/Purchasing/Requests/*.php`, `/app/Models/Purchasing/*.php` | Workflow básico implementado |
| Compras | Órdenes de compra | Implementado | `/app/Livewire/Purchasing/Orders/*.php`, `/app/Models/Purchasing/*.php` | Funcionalidad básica |
| Compras | Motor de reposición | No implementado | - | Sólo UI de dashboard en `/app/Livewire/Replenishment/Dashboard.php` |
| Recetas | Edición de recetas | Implementado | `/app/Livewire/Recipes/RecipeEditor.php`, `/app/Models/Recipes/*.php` | Básico, sin versionado automático |
| Producción | KDS (Kitchen Display System) | Implementado | `/app/Livewire/Kds/Board.php` | Básico, sin control KPIs |
| Caja Chica | Workflow completo | Implementado | `/app/Livewire/CashFund/*.php`, `/app/Models/CashFund*.php`, `/app/Services/Cash/*.php` | Funcionalidad completa |
| Reportes | Dashboards básicos | Implementado | `/app/Livewire/Reports/Dashboard.php`, `/app/Http/Controllers/Reports/*.php` | Reportes básicos, falta analytics |
| Catálogos | Gestión de catálogos | Implementado | `/app/Livewire/Catalogs/*.php`, `/app/Models/Catalogs/*.php` | Funcionalidad completa |
| Transfers | Creación de transferencias | Implementado | `/app/Services/Inventory/TransferService.php`, `/app/Models/Inventory/Transfer*.php`, `/app/Livewire/Transfers/Create.php` | Sólo creación, falta despacho y recepción |
| Transfers | Despacho y recepción | Solo en código | `/app/Services/Inventory/TransferService.php` | Funcionalidades en código pero sin UI |
| Permisos | RBAC completo | Implementado | `/app/Policies/*`, `config/permission.php`, DB tables from spatie/laravel-permission | Implementado vía paquete Spatie |

---

## FASE 5 - ANÁLISIS DE BASE DE DATOS (esquema selemti) - ACTUALIZADO

### Listado de objetos de BD actualizado

| Objeto | Tipo | Uso: En docs / En código / Ambos / Ninguno | Comentarios |
|--------|------|------------------------------------------|-------------|
| `items` | Tabla | Ambos | Principal tabla de ítems/insumos |
| `mov_inv` | Tabla | En código / Ninguno | Tabla de movimientos de inventario, no documentada |
| `v_stock_actual` | Vista | En código / Ninguno | Vista de stock actual por ítem |
| `v_stock_brechas` | Vista | En código / Ninguno | Vista de brechas de stock |
| `vw_kardex` | Vista | En código / Ninguno | Vista de kardex simplificado |
| `vw_stock_por_lote_fefo` | Vista | En código / Ninguno | Vista de stock por lote con FEFO |
| `transfer_cab` | Tabla | En código / Ninguno | Cabecera de transferencias, en código pero no documentada |
| `transfer_det` | Tabla | En código / Ninguno | Detalle de transferencias, en código pero no documentada |
| `cash_funds` | Tabla | Ambos | Tabla de fondos de caja chica |
| `cash_fund_movements` | Tabla | Ambos | Tabla de movimientos de caja chica |
| `cash_fund_arqueos` | Tabla | Ambos | Tabla de conteos de caja chica |
| `receta_cab` | Tabla | En código / Ninguno | Cabecera de recetas, en código pero no documentada |
| `receta_det` | Tabla | En código / Ninguno | Detalle de recetas, en código pero no documentada |
| `vw_item_last_price` | Vista | En código / Ninguno | Vista de último precio de ítems |
| `vw_item_last_price_pref` | Vista | En código / Ninguno | Vista de último precio preferente |
| `vw_valorizacion_inventario` | Vista | Ninguno | Vista de valorización, **PENDIENTE DE CREAR** |
| `vw_kardex_detalle` | Vista | Ninguno | Vista de kardex detallado, **PENDIENTE DE CREAR** |
| `fn_calculo_costo_unitario` | Función | En código | Función para cálculo de costo unitario |
| `fn_item_unit_cost_at` | Función | En código | Función para obtener costo unitario a una fecha |
| `fn_recipe_cost_at` | Función | En código | Función para costo de receta en fecha específica |
| `trg_ivp_close_prev` | Trigger | En código | Trigger para cerrar precios anteriores |
| `trg_ipp_set_timestamp` | Trigger | En código | Trigger para actualizar timestamps |

### Hallazgos Importantes de la Base de Datos:
1. **La tabla `stock` no existe** en el esquema `selemti`, pero sí existen vistas como `v_stock_actual` que proporcionan la funcionalidad de stock actual.

2. **Vistas críticas pendientes de crear**:
   - `vw_valorizacion_inventario` - Vista de valorización de inventario
   - `vw_kardex_detalle` - Vista de kardex detallado
   - `vw_kardex_resumen` - Vista de kardex resumido

3. **Estructura de movimientos**:
   - La tabla `mov_inv` contiene los movimientos de inventario con campos clave como `item_id`, `lote_id`, `cantidad`, `costo_unit`, `tipo`, `ref_tipo`, `ref_id`, etc.

4. **Sistema de FEFO implementado**:
   - Vista `vw_stock_por_lote_fefo` implementa la lógica FEFO (First Expire First Out)

5. **Sistema de auditoría**:
   - Tablas como `audit_log`, `audit_log_global` gestionan el sistema de auditoría

### Comentarios Finales sobre la Base de Datos:
- El esquema tiene una gran cantidad de tablas (141 según análisis previo) y una arquitectura bastante completa.
- Existen vistas de dashboard (`vw_dashboard_*`) que ya están implementadas.
- El sistema tiene mecanismos de control de versiones de recetas (`recipe_versions`) y snapshots de costos.
- Existen múltiples triggers para mantener la integridad de los datos.

---

## FASE 6 - EVALUACIÓN UI/UX

### Problemas UI/UX Detectados

| Módulo/Pantalla | Problema | Impacto | Sugerencia de Mejora |
|-----------------|----------|---------|----------------------|
| Inventario | Formulario de alta de ítems es confuso | Medio | Crear wizard de 2 pasos: Paso 1 datos básicos, Paso 2 datos avanzados |
| Inventario | Falta validación inline en formularios | Alto | Implementar sistema de validación inline con mensajes claros |
| Compras | UI de sugerencias de reposición es básica | Alto | Crear dashboard interactivo con información de cobertura y razón del cálculo |
| Transfers | Solo se puede crear transferencias, no despachar/recibir | Crítico | Agregar interfaces para despacho y recepción |
| Recetas | Editor de recetas no es intuitivo | Medio | Mejorar interfaz para arrastrar/eliminar ingredientes |
| Conteos Físicos | Proceso de conteo no es eficiente | Medio | Agregar funcionalidad de búsqueda rápida y captura por categorías |
| General | Falta consistencia visual | Medio | Implementar sistema de componentes reutilizables |
| General | No hay sistema de notificaciones | Medio | Agregar toast notifications para confirmaciones y errores |
| Caja Chica | UI funcional pero con muchos clicks | Medio | Reducir pasos en workflow principal |

### Recomendaciones Específicas
1. **Sistema de componentes reutilizables:** Implementar sistema de componentes Blade consistentes para buttons, inputs, selects, etc.
2. **Validación inline:** Implementar validación en tiempo real con mensajes claros
3. **Notificaciones:** Agregar sistema de toast notifications para mensajes de éxito/error
4. **Workflow transferencias:** Completar las interfaces para despacho y recepción de transferencias
5. **Dashboard de reposición:** Mejorar el dashboard de sugerencias con información más detallada
6. **Móvil para conteos:** Implementar interfaz móvil para conteos físicos

---

## CONCLUSIONES GENERALES

### Estado Crítico Detectado:
1. **La carpeta `/docs/V4.0` NO EXISTE** en el proyecto actual, lo que impide tener una visión objetivo del sistema.
2. La documentación está altamente fragmentada y desalineada con el código implementado.
3. Existen funcionalidades implementadas en código que no están documentadas.
4. Existen funcionalidades documentadas que no están implementadas en código.
5. Las vistas críticas como kardex y valorización de inventario están pendientes de crear.

### Recomendaciones Inmediatas:
1. **Crear la carpeta `/docs/V4.0`** como estructura objetivo del sistema.
2. **Alinear documentación, código y base de datos** para que digan lo mismo.
3. **Completar las vistas de kardex y valorización** que están pendientes: `vw_kardex_detalle` y `vw_valorizacion_inventario`.
4. **Completar la interfaz de transferencias** para despacho y recepción.
5. **Documentar adecuadamente las vistas y tablas existentes** que no están documentadas, especialmente:
   - La vista `v_stock_actual` que se usa en lugar de una tabla `stock`
   - Las vistas de kardex (`vw_kardex`, `vw_stock_por_lote_fefo`)
   - Las funciones relacionadas con costos (`fn_item_unit_cost_at`, `fn_recipe_cost_at`)

### Próximos Pasos Prioritarios:
1. Crear estructura `/docs/V4.0` con toda la documentación consolidada
2. Implementar vistas de kardex y valorización
3. Completar interfaz de transferencias (despacho/recepción)
4. Implementar motor de reposición con múltiples métodos
5. Implementar sistema de componentes reutilizables para UI/UX consistente

**Nota:** El análisis está completo y se ha accedido directamente a la base de datos PostgreSQL para obtener la información completa del esquema `selemti`.