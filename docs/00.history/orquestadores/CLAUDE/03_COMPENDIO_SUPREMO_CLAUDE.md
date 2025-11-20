# COMPENDIO SUPREMO FUSIÓN - CLAUDE

**Orquestador**: Claude Code
**Fecha**: 14 Noviembre 2025
**Fuente**: Auditoría Exhaustiva FASE1-FASE6 (13 Nov 2025)

---

## INTRODUCCIÓN

Este documento representa el **conocimiento consolidado más profundo** del sistema Terrena POS/ERP, resultado de una auditoría exhaustiva de 6 fases que analizó:

- **729 archivos de documentación** (486 /docs + 243 D:\Tavo\2025\UX\)
- **479 archivos de código** (80 modelos, 64 controladores, 34 servicios, 58 Livewire, 76 migraciones, 167 vistas)
- **147 tablas de BD** (38 vistas, 37 funciones, 20 triggers, 100+ FK)
- **42 componentes UI** (layouts, Livewire, Alpine.js, Bootstrap 5)

**Propósito**: Servir como referencia suprema para agentes IA y desarrolladores humanos que trabajen en el sistema.

---

## PARTE I: VISIÓN DEL SISTEMA

### 1.1 ¿Qué es Terrena?

Terrena es un **sistema ERP/POS integral** diseñado específicamente para **restaurantes multi-sucursal**, que unifica la gestión completa del ciclo operativo:

```
CICLO OPERATIVO TERRENA:

1. ABASTECIMIENTO
   Compras → Cotizaciones → Órdenes → Recepciones
   ↓
2. INVENTARIO
   Stock → Lotes → Kardex → Conteos → Transferencias
   ↓
3. PRODUCCIÓN
   Recetas → Órdenes Producción → Mise en Place → Rendimientos
   ↓
4. VENTAS
   POS (FloreantPOS) → Consumo → Mapeo Recetas → Kardex
   ↓
5. FINANZAS
   Cortes Caja → Precorte → Postcorte → Conciliación → Reportes
   ↓
6. ANÁLISIS
   KPIs → Dashboards → Reportes → Toma de Decisiones
```

### 1.2 Lo que Terrena NO es

- ❌ NO es un sistema POS propio (integra con FloreantPOS)
- ❌ NO es contabilidad completa (solo operativa)
- ❌ NO es sistema de RRHH
- ❌ NO es CRM
- ❌ NO es e-commerce

### 1.3 Usuarios Clave

| Rol | Módulos | Objetivo Principal |
|-----|---------|-------------------|
| **Almacenista** | Inventario | Control stock, trazabilidad lotes, ajustes |
| **Comprador** | Purchasing | Requisiciones, cotizaciones, órdenes |
| **Chef/Cocina** | Recetas, Producción | Recetas, órdenes producción, mise en place |
| **Cajero** | Caja | Precorte, postcorte, fondos de caja |
| **Supervisor** | Caja, Reportes | Aprobación cortes, validación varianzas |
| **Gerente** | Reportes, Ventas | KPIs, análisis costos, decisiones |
| **Controller** | Finanzas, Reportes | Análisis financiero, rentabilidad |
| **Administrador** | Seguridad, Catálogos | Usuarios, permisos, catálogos maestros |

---

## PARTE II: ARQUITECTURA TÉCNICA PROFUNDA

### 2.1 Stack Tecnológico Completo

```yaml
Backend:
  Framework: Laravel 12
  PHP: 8.2+
  Base de Datos: PostgreSQL 9.5
  Esquemas BD:
    - selemti (trabajo, modificable)
    - public (FloreantPOS legacy, READ-ONLY)

Frontend:
  Framework UI: Livewire 3.7 beta
  CSS: Bootstrap 5 (oficial) + Tailwind 3 (legacy, deprecar)
  JavaScript: Alpine.js 3.x
  Build: Vite 4.x

Seguridad:
  Auth: JWT (tymon/jwt-auth)
  Permisos: Spatie Laravel Permission
  API Docs: L5-Swagger

Infraestructura:
  Servidor Web: Apache 2.4 (XAMPP en dev)
  Colas: Redis (jobs)
  Cache: Redis

Herramientas:
  Linter: Laravel Pint
  Testing: PHPUnit
  Logs: Laravel Pail
  Queue: Laravel Queue Worker
```

### 2.2 Dual Database Architecture

**Concepto Crítico**: Terrena usa DOS esquemas en PostgreSQL:

```sql
-- Esquema 1: SELEMTI (Trabajo)
-- Propósito: Todas las operaciones nuevas del sistema
-- Permisos: MODIFICABLE por Gemini CLI y desarrolladores
-- Convención: Usar para TODAS las funcionalidades Terrena

CREATE SCHEMA selemti;

-- Tablas principales:
selemti.items                    -- Catálogo items
selemti.mov_inv                  -- Kardex (movimientos)
selemti.receta_cab               -- Recetas
selemti.sesion_cajon             -- Sesiones caja
selemti.purchase_requests        -- Requisiciones
selemti.cash_funds               -- Fondos caja chica
-- ... 147 tablas total

-- Esquema 2: PUBLIC (Legacy FloreantPOS)
-- Propósito: Sistema POS legacy (producción activa)
-- Permisos: READ-ONLY (NO modificar sin confirmación)
-- Convención: Solo lectura para integración

public.ticket                    -- Tickets de venta
public.ticket_item               -- Items de ticket
public.menu_item                 -- Menú POS
public.transactions              -- Transacciones pago
-- ... tablas FloreantPOS
```

**Regla de Oro**:
- ✅ Crear tablas/vistas/funciones en `selemti`
- ❌ NO modificar `public` sin aprobación explícita

### 2.3 Estructura de Código Detallada

```
C:\xampp3\htdocs\TerrenaLaravel/
│
├── app/
│   ├── Models/                    # 80 modelos (75% documentados)
│   │   ├── Caja/                 # SesionCajon, Precorte, Postcorte
│   │   ├── Inv/                  # Item, Batch, MovimientoInventario, Unidad
│   │   ├── Rec/                  # Receta, RecetaDetalle, RecetaVersion, Modificador
│   │   ├── Pos/                  # Ticket, TicketItem, MenuItem, MenuCategory
│   │   ├── Core/                 # Auditoria, SesionCaja, User, Role
│   │   ├── Purchasing/           # PurchaseRequest, VendorQuote, PurchaseOrder
│   │   ├── CashFund/             # CashFund, CashFundMovement
│   │   └── Catalogs/             # Unidad, Almacen, Sucursal, Proveedor
│   │
│   ├── Services/                  # 34 servicios (44% documentados ⚠️)
│   │   ├── Inventory/
│   │   │   ├── ReceptionService.php        # Recepciones de inventario
│   │   │   ├── InventoryCountService.php   # Conteos físicos (Codex)
│   │   │   ├── TransferService.php         # Transferencias
│   │   │   ├── InventoryAdjustmentService.php  # ⚠️ Sin doc
│   │   │   └── BatchTrackingService.php    # ⚠️ Sin doc
│   │   ├── Purchasing/
│   │   │   └── PurchasingService.php       # Requisiciones→Órdenes (Codex)
│   │   ├── Caja/
│   │   │   ├── AlertasService.php          # ⚠️ Sin doc
│   │   │   └── AnalyticsService.php        # ⚠️ Sin doc
│   │   ├── Pos/
│   │   │   └── PosConsumptionService.php   # 🔴 TRIPLICADO (3 ubicaciones)
│   │   ├── Production/
│   │   │   └── ProductionService.php       # 🔴 DUPLICADO (2 ubicaciones)
│   │   └── CashFundService.php             # ✅ Completo (modelo ejemplar)
│   │
│   ├── Http/Controllers/          # 64 controladores (70% documentados)
│   │   ├── Api/Caja/
│   │   │   ├── PrecorteController.php
│   │   │   ├── PostcorteController.php
│   │   │   └── CajaController.php
│   │   ├── Api/Unidades/
│   │   │   └── UnidadesController.php
│   │   ├── TransferApiController.php      # ⚠️ Huérfano (no en routes)
│   │   └── RecipeCostController.php       # ⚠️ Parcialmente doc
│   │
│   ├── Livewire/                  # 58 componentes (69% documentados)
│   │   ├── Catalogs/             # UnidadesIndex, AlmacenesIndex, ProveedoresIndex
│   │   ├── Inventory/            # ItemsIndex, ReceptionsIndex, ReceptionCreate
│   │   ├── Purchasing/
│   │   │   ├── Requests/         # Index, Create, Detail
│   │   │   └── Orders/           # Index, Detail
│   │   ├── CashFund/             # ✅ 6 componentes (100% doc, modelo ejemplar)
│   │   ├── InventoryCount/       # Index, Create, Detail
│   │   ├── Recipes/              # RecipesIndex, RecipeEditor
│   │   └── Transfers/            # Create
│   │
│   ├── Helpers/
│   │   └── CajaHelper.php        # qp(), J(), ver() - auto-loaded
│   │
│   └── Repositories/             # 5 repositorios Pos/ (sin doc)
│       └── Pos/
│           ├── TicketRepository.php
│           ├── MenuItemRepository.php
│           ├── ConsumoRepository.php
│           └── ... (2 más)
│
├── database/
│   ├── migrations/               # 76 migraciones (66% documentadas)
│   │   └── 2025_11_04_000900_create_additional_sales_report_views.php
│   └── seeders/
│       ├── UsersSeeder.php
│       └── RolesSeeder.php
│
├── resources/
│   ├── views/
│   │   ├── layouts/
│   │   │   ├── terrena.blade.php        # ✅ Layout oficial Bootstrap 5
│   │   │   └── app.blade.php            # ⚠️ Legacy Tailwind (deprecar)
│   │   ├── livewire/                    # 167 vistas (48% documentadas ⚠️)
│   │   │   ├── catalogs/
│   │   │   ├── inventory/
│   │   │   ├── purchasing/
│   │   │   └── cash-fund/               # ✅ 12 vistas completas
│   │   └── caja/
│   │       └── _wizard_modals.blade.php # Wizard precorte/postcorte
│   └── js/
│       └── app.js                       # Alpine.js init, Bootstrap

├── routes/
│   ├── web.php                  # Rutas Livewire
│   └── api.php                  # REST APIs

└── docs/
    ├── V4.0/                    # ✅ Documentación oficial (19 docs, 76% score)
    │   ├── 00_Orquestador/
    │   ├── Arquitectura/
    │   ├── Frontend/
    │   ├── Inventario/
    │   ├── Recetas/
    │   ├── Produccion/
    │   ├── POS/
    │   ├── Purchasing/
    │   ├── Caja/
    │   └── Reports/
    └── 00.history/              # Referencia histórica (729 docs)
        ├── auditorias/
        │   └── AUDITORIA_2025_11_13/
        │       ├── FASE1_COMPENDIO_DOCUMENTACION.md
        │       ├── FASE2_ANALISIS_V4.0.md
        │       ├── FASE3_ESTRUCTURA_INTEGRADA.md
        │       ├── FASE4_ANALISIS_CODIGO.md
        │       ├── FASE5_ANALISIS_BD_SELEMTI.md
        │       └── FASE6_EVALUACION_UI_UX.md
        └── orquestadores/
            ├── CLAUDE/
            ├── QWEN/
            ├── CODEX/
            └── COPILOT/
```

---

## PARTE III: BASE DE DATOS PROFUNDA

### 3.1 Esquema selemti - Inventario Completo

**Estadísticas** (FASE5):
- 147 tablas (44% con modelos, 56% huérfanas)
- 38 vistas (74% documentadas)
- 37 funciones (32% documentadas ⚠️)
- 20 triggers (75% documentados)
- 100+ Foreign Keys
- Tamaño total: ~15 MB (BD nueva, pocos datos)

### 3.2 Tablas por Módulo

#### CAJA (10 tablas) - EXCELENTE ⭐⭐⭐⭐⭐

```sql
-- Tabla principal: Sesiones de caja
selemti.sesion_cajon (152 kB, 132 registros)
  id, sucursal, terminal_id, cajero_usuario_id,
  apertura_ts, cierre_ts, estatus, opening_float, closing_float

-- Precorte
selemti.precorte (80 kB, 33 registros)
  id, sesion_id, estatus, creado_en, aprobado_en

selemti.precorte_efectivo (80 kB)
  id, precorte_id, denominacion, cantidad_billetes, total

selemti.precorte_otros (64 kB)
  id, precorte_id, forma_pago_id, monto

-- Postcorte
selemti.postcorte (72 kB, 27 registros)
  id, sesion_id, aprobado_por, rechazado_por, estatus

selemti.conciliacion (24 kB)
  id, postcorte_id, tipo_varianza, monto_varianza

-- Alertas
selemti.alertas_cortes (24 kB)
  id, sesion_id, postcorte_id, tipo_alerta, destinatario_id

-- Legacy (vacías, deprecar)
selemti.caja_fondo* (5 tablas) → reemplazado por cash_funds
```

**Triggers**:
```sql
trg_precorte_after_insert → fn_precorte_after_insert()
  -- Auto-genera snapshot y actualiza estado sesión

trg_postcorte_after_insert → fn_postcorte_after_insert()
  -- Auto-genera conciliación automática

trg_precorte_after_update_aprobado → fn_precorte_after_update_aprobado()
  -- Auto-cierra sesión cuando se aprueba

trg_precorte_efectivo_bi → fn_precorte_efectivo_bi()
  -- Validación de efectivo
```

#### INVENTARIO (25 tablas) - BIEN ⭐⭐⭐⭐

```sql
-- Catálogo de items
selemti.items (152 kB, 6 activos)
  id VARCHAR(20) PK,  -- Formato: ITEM-XXXX
  nombre, descripcion, categoria_id,
  unidad_medida_id INT FK → cat_unidades,
  unidad_compra_id INT FK → cat_unidades,
  unidad_salida_id INT FK → cat_unidades,
  costo_promedio NUMERIC(10,2),
  activo BOOLEAN,
  tipo producto_tipo ENUM,
  es_producible, es_consumible_operativo, es_empaque_to_go

-- Kardex (movimientos de inventario)
selemti.mov_inv (104 kB, 0 registros actualmente)
  id BIGSERIAL PK,
  ts TIMESTAMP,
  item_id VARCHAR(20) FK → items,
  lote_id INT FK → inventory_batch,
  cantidad NUMERIC(14,6),
  uom_original_id INT,
  costo_unit NUMERIC(14,6),
  tipo VARCHAR(20) CHECK(ENTRADA/SALIDA/AJUSTE/MERMA/TRASPASO),
  ref_tipo VARCHAR(50),  -- 'RECEPCION', 'TRANSFERENCIA', etc.
  ref_id BIGINT,
  sucursal_id, usuario_id

-- Lotes (batch tracking)
selemti.inventory_batch (40 kB)
  id, item_id FK → items, batch_code, fecha_elaboracion,
  fecha_caducidad, cantidad_inicial, cantidad_actual

-- Recepciones
selemti.recepcion_cab (32 kB)
  id, sucursal_id, proveedor_id, usuario_id, fecha, estatus

selemti.recepcion_det (40 kB)
  id, recepcion_id FK → recepcion_cab,
  item_id FK → items, cantidad, uom_id, costo_unitario

-- Conteos físicos
selemti.inventory_counts (64 kB)
  id, almacen_id, fecha_inicio, fecha_fin, estatus, tipo_conteo

selemti.inventory_count_lines (40 kB)
  id, count_id FK → inventory_counts,
  item_id FK → items, cantidad_sistema, cantidad_fisica, varianza

-- Transferencias
selemti.transfer_cab (0 registros - tabla nueva)
  id, origen_almacen_id, destino_almacen_id, fecha, estatus

selemti.transfer_det (0 registros)
  id, transfer_id, item_id, cantidad, uom_id

-- Mermas
selemti.inventory_wastes (48 kB)
  id, item_id, batch_id, cantidad, motivo, fecha

selemti.merma (48 kB) -- ⚠️ Duplicado con inventory_wastes
selemti.perdida_log (24 kB)

-- Snapshots de stock
selemti.inventory_snapshot (40 kB)
  id, item_id, fecha, cantidad, costo_promedio

-- Políticas de stock (vacía - no implementado)
selemti.stock_policy (40 kB, 0 registros)
selemti.inv_stock_policy (16 kB, 0 registros)
```

**Vistas Clave**:
```sql
vw_kardex
  -- Vista completa del kardex con joins a items, lotes, etc.

vw_stock_por_lote_fefo
  -- Stock por lote con FEFO (First Expired First Out)

vw_item_last_price
  -- Último precio de compra por item

vw_stock_actual
  -- Stock actual por item y almacén
```

**Triggers**:
```sql
trg_items_assign_code → fn_assign_item_code()
  -- Auto-asigna código ITEM-XXXX en inserts

trg_invshot_biur → tg_invshot_autofill()
  -- Auto-completa datos en snapshots

trg_ivp_after_insert → fn_after_price_insert_alert()
  -- Genera alerta cuando cambia precio

trg_ivp_close_prev → fn_ivp_upsert_close_prev()
  -- Cierra precio previo al insertar nuevo
```

#### RECETAS (12 tablas) - PARCIAL ⭐⭐⭐

```sql
-- Recetas principales
selemti.receta_cab (56 kB)
  id VARCHAR(20) PK,  -- Formato: REC-XXXX
  nombre_plato, codigo_plato_pos,
  categoria_plato, porciones_standard,
  instrucciones_preparacion, tiempo_preparacion_min,
  costo_standard_porcion, precio_venta_sugerido,
  activo

-- Versiones de recetas
selemti.receta_version (40 kB, 0 registros)
  id, receta_id FK → receta_cab, version_number,
  fecha_vigencia, activo, notas_cambios

⚠️ PROBLEMA: También existe selemti.recipe_versions (24 kB)
  -- Naming inconsistente! Consolidar

-- Insumos de recetas
selemti.receta_insumo (48 kB)
  id, receta_version_id FK → receta_version,
  item_id FK → items, cantidad, uom_id,
  costo_unitario, secuencia

-- Snapshots de costos
selemti.recipe_cost_snapshots (32 kB)
  id, recipe_id FK → receta_cab, snapshot_date,
  total_cost, labor_cost, overhead_cost
  -- ⚠️ Modelo huérfano (RecipeCostSnapshot sin doc)

-- Historial de costos
selemti.recipe_cost_history (24 kB)
selemti.hist_cost_receta (24 kB)
selemti.historial_costos_receta (32 kB)
  -- ⚠️ Múltiples tablas con mismo propósito!

-- Labor y overhead
selemti.recipe_labor_steps (32 kB)
selemti.recipe_overhead_allocations (32 kB)
selemti.overhead_definitions (40 kB)
selemti.labor_roles (32 kB)

-- Modificadores POS
selemti.modificadores_pos (24 kB)
  id, receta_modificador_id FK → receta_cab, nombre, precio
```

**Funciones Críticas NO Documentadas**:
```sql
fn_recipe_cost_at(recipe_id INT, fecha TIMESTAMP) RETURNS NUMERIC
  -- Calcula costo de receta en fecha específica
  -- 🔴 CRÍTICO: Core business logic sin documentación

fn_recipes_using_item(item_id VARCHAR) RETURNS TABLE
  -- BOM Implosion: ¿En qué recetas se usa este item?
  -- 🔴 CRÍTICO: Feature clave solicitada, sin doc
```

#### PURCHASING (13 tablas) - BIEN ⭐⭐⭐⭐

```sql
-- Solicitudes de compra
selemti.purchase_requests (64 kB)
  id BIGSERIAL PK, folio VARCHAR(40) UNIQUE,
  sucursal_id, created_by, requested_by, requested_at,
  estado VARCHAR(24) DEFAULT 'BORRADOR',
  importe_estimado, fecha_requerida, almacen_destino_id,
  justificacion, urgente, origen_suggestion_id

⚠️ PROBLEMA: Existe también app/Models/PurchaseRequest.php
  -- ¡Modelo duplicado en 2 ubicaciones!

selemti.purchase_request_lines (40 kB)
  id, request_id FK → purchase_requests,
  item_id FK → items, cantidad_solicitada,
  uom_id, precio_estimado

-- Cotizaciones
selemti.purchase_vendor_quotes (32 kB)
  id, request_id FK → purchase_requests,
  vendor_id FK → cat_proveedores,
  fecha_cotizacion, vigencia_hasta, estatus

selemti.purchase_vendor_quote_lines (40 kB)
  id, quote_id FK → purchase_vendor_quotes,
  request_line_id, cantidad_cotizada,
  precio_unitario, tiempo_entrega

-- Órdenes de compra
selemti.purchase_orders (40 kB)
  id, vendor_id FK → cat_proveedores,
  folio, fecha_orden, fecha_entrega_esperada,
  estatus, total, notas

selemti.purchase_order_lines (32 kB)
  id, order_id FK → purchase_orders,
  item_id FK → items, cantidad,
  precio_unitario, subtotal

-- Documentos adjuntos
selemti.purchase_documents (40 kB)
  id, entity_type ('REQUEST', 'ORDER'),
  entity_id, tipo_documento, ruta_archivo

-- Sugerencias de reabasto (VACÍA - no implementado)
selemti.purchase_suggestions (50 kB)
selemti.purchase_suggestion_lines (40 kB)
selemti.replenishment_suggestions (96 kB, 0 registros)
  -- 🔴 GAP CRÍTICO: Motor de replenishment no implementado
```

#### POS (10 tablas) - PARCIAL ⭐⭐⭐

```sql
-- Mapeo POS → Recetas
selemti.pos_map (40 kB, 0 registros)
  id, pos_menu_item_id, pos_menu_item_name,
  receta_id FK → receta_cab, ratio, activo
  -- ⚠️ Modelo huérfano (PosMap sin doc)

-- Sincronización POS
selemti.pos_sync_batches (16 kB)
  -- ⚠️ Sin modelo Eloquent

selemti.pos_sync_logs (32 kB)
  id, batch_id FK → pos_sync_batches,
  entity_type, entity_id, operacion, resultado
  -- ⚠️ Sin modelo Eloquent

selemti.pos_reprocess_log (40 kB)
selemti.pos_reverse_log (40 kB)
  -- ⚠️ Sin modelos Eloquent

-- Modificadores
selemti.pos_modifiers_map (32 kB)

-- Menú
selemti.menu_items (24 kB)
selemti.menu_item_sync_map (24 kB)
  -- ⚠️ Sin modelo Eloquent

selemti.menu_engineering_snapshots (24 kB)
  -- ⚠️ Sin modelo Eloquent

-- Consumo de tickets
selemti.ticket_det_consumo (40 kB)
selemti.inv_consumo_pos (40 kB)
selemti.inv_consumo_pos_det (32 kB)
selemti.inv_consumo_pos_log (24 kB)
```

**Funciones Críticas POS**:
```sql
fn_expandir_consumo_ticket(ticket_id BIGINT) RETURNS VOID
  -- Expande ticket POS → consumo de items según recetas
  -- 🔴 CRÍTICO: Core de integración POS-Recetas, sin doc

fn_confirmar_consumo_ticket(ticket_id BIGINT) RETURNS VOID
  -- Confirma consumo y actualiza kardex
  -- 🔴 ALTO: Sin documentación

fn_reversar_consumo_ticket(ticket_id BIGINT) RETURNS VOID
  -- Reversa consumo (cancelación de ticket)
  -- 🔴 ALTO: Sin documentación

ingesta_ticket() RETURNS VOID
  -- Ingesta tickets desde FloreantPOS
  -- ⚠️ Documentación breve

inferir_recetas_de_ventas() RETURNS VOID
  -- Infiere recetas desde ventas históricas
  -- ⚠️ Sin documentación

registrar_consumo_porcionado() RETURNS VOID
  -- Registra consumo por porción
  -- ⚠️ Sin documentación
```

#### CATÁLOGOS (8 tablas) - EXCELENTE ⭐⭐⭐⭐⭐

```sql
-- Unidades de medida (UOM)
selemti.cat_unidades (88 kB)
  id BIGSERIAL PK, clave VARCHAR, nombre VARCHAR,
  activo BOOLEAN, categoria VARCHAR

-- Conversiones UOM (NORMALIZACIÓN COMPLETA - 77 migraciones)
selemti.cat_uom_conversion (112 kB)
  id, origen_id FK → cat_unidades,
  destino_id FK → cat_unidades,
  factor NUMERIC(12,6),
  activo

-- Almacenes
selemti.cat_almacenes (40 kB)
  id, clave, nombre, sucursal_id FK → cat_sucursales, activo

-- Proveedores
selemti.cat_proveedores (80 kB)
  id, rfc, nombre, razon_social, telefono, email,
  tipo_comprobante, uso_cfdi, metodo_pago, forma_pago,
  regimen_fiscal, contacto_*, direccion, ciudad, estado, pais

-- Sucursales
selemti.cat_sucursales (56 kB)
  id, clave, nombre, ubicacion, pos_location, activo

-- Legacy (deprecar después de migración final)
selemti.almacen (16 kB) → reemplazado por cat_almacenes
selemti.bodega (24 kB) → reemplazado por cat_almacenes
selemti.sucursal (16 kB) → reemplazado por cat_sucursales
```

**Vistas de Compatibilidad**:
```sql
-- Mantener para código legacy, deprecar cuando uso = 0
vw_unidad_medida              → cat_unidades
vw_conversiones_unidad        → cat_uom_conversion
v_almacen                     → cat_almacenes
v_sucursal                    → cat_sucursales
```

#### REPORTES (9 vistas) - EXCELENTE ⭐⭐⭐⭐⭐

```sql
-- Dashboard principal
vw_sesion_dpr
  -- Vista maestra de sesiones con datos pre-calculados
  -- ✅ Completa, documentada, en uso

-- Dashboards de ventas
vw_dashboard_ticket_base       -- Base de tickets
vw_dashboard_resumen_sucursal  -- Resumen por sucursal
vw_dashboard_resumen_terminal  -- Resumen por terminal
vw_dashboard_ventas_categorias -- Ventas por categoría
vw_dashboard_ventas_productos  -- Ventas por producto
vw_dashboard_ventas_hora       -- Ventas por hora
vw_dashboard_formas_pago       -- Formas de pago
vw_dashboard_ordenes           -- Órdenes de compra

-- Ventas
vw_ventas_por_hora
vw_ticket_promedio_sucursal_dia

-- Todas documentadas en:
-- docs/Reports/RESUMEN_COMPLETO_REPORTES_2025_11_04.md
```

#### SEGURIDAD (15 tablas) - BIEN ⭐⭐⭐⭐

```sql
-- Spatie Permission
selemti.permissions (48 kB)
selemti.roles (48 kB)
selemti.model_has_permissions (40 kB)
selemti.model_has_roles (40 kB)
selemti.role_has_permissions (56 kB)

-- Usuarios
selemti.users (48 kB)
  id, name, email, email_verified_at, password,
  remember_token, created_at, updated_at

-- Auditoría
selemti.audit_log (224 kB - LA MÁS GRANDE)
  id, user_id FK → users, tabla, operacion,
  registro_id, datos_antes JSONB, datos_despues JSONB,
  ip, user_agent, created_at

selemti.audit_log_global (48 kB)
  -- Auditoría cross-sistema

-- Sesiones
selemti.sessions (96 kB)
selemti.personal_access_tokens (96 kB)
selemti.password_reset_tokens (16 kB)

-- Legacy (deprecar)
selemti.usuario (24 kB) → reemplazado por users
selemti.rol (24 kB) → reemplazado por roles (Spatie)
selemti.user_roles (0 registros) → eliminar
```

---

## PARTE IV: CÓDIGO PROFUNDO

### 4.1 Servicios Clave

#### ReceptionService (Recepciones de Inventario)

```php
// app/Services/Inventory/ReceptionService.php

class ReceptionService
{
    /**
     * Crea recepción de inventario atómicamente
     *
     * @param array $header [sucursal_id, proveedor_id, usuario_id, fecha]
     * @param array $lines [[item_id, cantidad, uom_id, costo_unitario, lote_code], ...]
     * @return int ID de recepción creada
     *
     * Flujo:
     * 1. Crear recepcion_cab
     * 2. Por cada línea:
     *    a. Crear recepcion_det
     *    b. Crear/actualizar inventory_batch (lote)
     *    c. Normalizar cantidad a UOM base
     *    d. Insertar en mov_inv (kardex) tipo=ENTRADA
     *    e. Actualizar costo_promedio en items
     * 3. Todo en transacción DB
     */
    public function createReception(array $header, array $lines): int
    {
        return DB::transaction(function () use ($header, $lines) {
            // 1. Cabecera
            $recepcion = RecepcionCab::create($header);

            foreach ($lines as $line) {
                // 2a. Detalle
                $det = RecepcionDet::create([
                    'recepcion_id' => $recepcion->id,
                    ...$line
                ]);

                // 2b. Lote
                $batch = InventoryBatch::firstOrCreate([
                    'item_id' => $line['item_id'],
                    'batch_code' => $line['lote_code']
                ], [
                    'fecha_elaboracion' => now(),
                    'fecha_caducidad' => now()->addDays(30), // ejemplo
                    'cantidad_inicial' => 0,
                    'cantidad_actual' => 0
                ]);

                // 2c. Normalizar a UOM base
                $item = Item::find($line['item_id']);
                $factor = $this->getConversionFactor(
                    $line['uom_id'],
                    $item->unidad_medida_id
                );
                $cantidadBase = $line['cantidad'] * $factor;

                // 2d. Kardex
                MovInv::create([
                    'item_id' => $line['item_id'],
                    'lote_id' => $batch->id,
                    'cantidad' => $cantidadBase,
                    'uom_original_id' => $line['uom_id'],
                    'qty_original' => $line['cantidad'],
                    'costo_unit' => $line['costo_unitario'] / $factor,
                    'tipo' => 'ENTRADA',
                    'ref_tipo' => 'RECEPCION',
                    'ref_id' => $recepcion->id,
                    'sucursal_id' => $header['sucursal_id'],
                    'usuario_id' => $header['usuario_id']
                ]);

                // 2e. Actualizar costo promedio (PEPS/promedio ponderado)
                $this->updateAverageCost($line['item_id']);

                // Actualizar stock batch
                $batch->increment('cantidad_actual', $cantidadBase);
            }

            return $recepcion->id;
        });
    }
}
```

#### PurchasingService (Requisiciones → Órdenes)

```php
// app/Services/Purchasing/PurchasingService.php
// Creado por: Codex (GitHub Copilot Agent)

class PurchasingService
{
    /**
     * Workflow completo de compras
     *
     * Estados Requisición:
     * BORRADOR → APROBADA → COTIZADA → ORDENADA → RECIBIDA
     *
     * Estados Orden:
     * BORRADOR → ENVIADA → CONFIRMADA → RECIBIDA → CERRADA
     */

    public function createRequest(array $data): PurchaseRequest
    {
        // Crear requisición en BORRADOR
        // Validar items existen
        // Calcular importe estimado
        // Asignar folio automático
    }

    public function addQuote(int $requestId, int $vendorId, array $lines): VendorQuote
    {
        // Agregar cotización de proveedor
        // Validar todas las líneas cotizadas
        // Calcular total
        // Actualizar estado request → COTIZADA
    }

    public function createOrderFromQuote(int $quoteId): PurchaseOrder
    {
        // Convertir cotización → orden de compra
        // Copiar líneas con precios
        // Generar folio OC
        // Actualizar estado request → ORDENADA
        // Estado orden → ENVIADA
    }

    public function receiveOrder(int $orderId, array $receivedQuantities): int
    {
        // Integración con ReceptionService
        // Crear recepción de inventario
        // Actualizar estado orden → RECIBIDA
        // Cerrar request → RECIBIDA
        return $receptionId;
    }
}
```

#### CashFundService (Caja Chica - MODELO EJEMPLAR)

```php
// app/Services/CashFundService.php
// ✅ 100% documentado, 100% implementado
// MODELO A SEGUIR para otros servicios

class CashFundService
{
    /**
     * Gestión completa de fondos de caja chica
     *
     * Estados del Fondo:
     * ACTIVO → LIQUIDADO → CERRADO
     *
     * Tipos de Movimiento:
     * - APERTURA: Creación del fondo
     * - REEMBOLSO: Entrada de efectivo
     * - GASTO: Salida documentada
     * - LIQUIDACION: Cierre del fondo
     *
     * Auditoría Completa:
     * - Tabla cash_fund_movement_audit_log
     * - Registra: user_id, antes, después, IP, timestamp
     */

    public function createFund(array $data): CashFund
    {
        DB::transaction(function () use ($data) {
            $fund = CashFund::create([
                'responsable_user_id' => $data['responsable_id'],
                'monto_inicial' => $data['monto'],
                'saldo_actual' => $data['monto'],
                'estatus' => 'ACTIVO',
                'created_by_user_id' => auth()->id()
            ]);

            // Movimiento de apertura
            $this->createMovement($fund->id, [
                'tipo' => 'APERTURA',
                'monto' => $data['monto'],
                'concepto' => 'Apertura de fondo',
                'created_by_user_id' => auth()->id()
            ]);

            return $fund;
        });
    }

    public function createMovement(int $fundId, array $data): CashFundMovement
    {
        // Validaciones
        $fund = CashFund::findOrFail($fundId);

        if ($fund->estatus !== 'ACTIVO') {
            throw new \Exception('Fondo no activo');
        }

        if ($data['tipo'] === 'GASTO' && !isset($data['comprobante'])) {
            throw new \Exception('Gasto requiere comprobante');
        }

        // Crear movimiento
        $movement = CashFundMovement::create($data);

        // Actualizar saldo
        $nuevoSaldo = $data['tipo'] === 'REEMBOLSO'
            ? $fund->saldo_actual + $data['monto']
            : $fund->saldo_actual - $data['monto'];

        $fund->update(['saldo_actual' => $nuevoSaldo]);

        // Auditoría
        $this->auditMovement($movement, 'CREATE');

        return $movement;
    }

    public function createArqueo(int $fundId, array $billetes): CashFundArqueo
    {
        // Arqueo de efectivo con denominaciones
        // Similar a precorte_efectivo
        // Valida que suma = saldo_actual
    }
}
```

### 4.2 Código Duplicado CRÍTICO

#### PosConsumptionService - TRIPLICADO 🔴

```
Ubicación 1: app/Services/PosConsumptionService.php
Ubicación 2: app/Services/Pos/PosConsumptionService.php
Ubicación 3: app/Services/Legacy/PosConsumptionService.php

Problema:
- Tres versiones del MISMO servicio
- Cambios en una NO se replican en otras
- Riesgo de bugs inconsistentes
- Confusión sobre cuál usar

Acción Requerida:
1. Comparar 3 versiones línea por línea
2. Identificar versión canónica (probablemente Pos/)
3. Consolidar en app/Services/Pos/PosConsumptionService.php
4. Actualizar todos los imports
5. Eliminar versiones duplicadas
6. Tests end-to-end
```

#### ProductionService - DUPLICADO 🔴

```
Ubicación 1: app/Services/ProductionService.php
Ubicación 2: app/Services/Production/ProductionService.php

Acción: Similar a PosConsumptionService
```

### 4.3 Helpers Globales

#### CajaHelper (Auto-loaded)

```php
// app/Helpers/CajaHelper.php
// Incluido automáticamente vía composer.json

/**
 * qp() - Query Parameter flexible
 * Lee parámetro de query string O body
 * Útil para legacy endpoints
 */
function qp(Request $request, string $key, $default = null)
{
    return $request->query($key)
        ?? $request->input($key)
        ?? $default;
}

/**
 * J() - JSON Response shorthand
 * Estructura estándar de respuesta
 */
function J(array $data, int $code = 200): JsonResponse
{
    return response()->json([
        'ok' => $code >= 200 && $code < 300,
        'data' => $data,
        'timestamp' => now()->toIso8601String()
    ], $code);
}

/**
 * ver() - Verificación de varianza en cortes
 * Determina si el corte cuadra
 */
function ver(float $diferencia): string
{
    $umbral = 0.50; // 50 centavos

    if (abs($diferencia) <= $umbral) {
        return 'CUADRA';
    } elseif ($diferencia > 0) {
        return 'A_FAVOR';  // Sobra dinero
    } else {
        return 'EN_CONTRA'; // Falta dinero
    }
}
```

---

## PARTE V: UI/UX PROFUNDA (FASE6)

### 5.1 Score General: 6.5/10

**Desglose**:
```
Navegación:        7/10 ⭐⭐⭐⭐⭐⭐⭐
Layouts:           8/10 ⭐⭐⭐⭐⭐⭐⭐⭐
Forms:             3/10 ⭐⭐⭐          🔴 CRÍTICO
Modales:           5/10 ⭐⭐⭐⭐⭐
Notificaciones:    3/10 ⭐⭐⭐          🔴 CRÍTICO
Tablas/Listas:     6/10 ⭐⭐⭐⭐⭐⭐
Design System:     7/10 ⭐⭐⭐⭐⭐⭐⭐
Accesibilidad:     6/10 ⭐⭐⭐⭐⭐⭐
Responsividad:     8/10 ⭐⭐⭐⭐⭐⭐⭐⭐
Feedback Usuario:  4/10 ⭐⭐⭐⭐        🔴 CRÍTICO
```

### 5.2 Gaps Críticos UI/UX

#### 🔴 GAP #1: Forms Sin Loading States (0% cobertura)

**Problema**:
```blade
<!-- ACTUAL (INCORRECTO) -->
<button type="submit" class="btn btn-primary">
    Guardar
</button>

<!-- Problemas:
- Usuario no sabe si form se está enviando
- Botón clickeable durante submit (doble envío)
- Sin spinner o indicador visual
- Usuario abandona pensando que no funcionó
-->
```

**Solución**:
```blade
<!-- CORRECTO con wire:loading -->
<button type="submit" class="btn btn-primary"
        wire:loading.attr="disabled"
        wire:target="save">
    <span wire:loading.remove wire:target="save">Guardar</span>
    <span wire:loading wire:target="save" style="display:none">
        <span class="spinner-border spinner-border-sm me-1"></span>
        Guardando...
    </span>
</button>
```

**Archivos Afectados**: ~40 formularios
- app/Livewire/Catalogs/*.php (todos)
- app/Livewire/Inventory/*.php (todos)
- app/Livewire/Purchasing/*.php (todos)
- app/Livewire/CashFund/*.php (todos)

**Esfuerzo**: 4 horas

#### 🔴 GAP #2: Sistema de Notificaciones Roto (70% falla)

**Problema**: 3 patrones incompatibles

```php
// Patrón 1 (✅ Funciona 50% - solo con redirect)
session()->flash('ok', 'Guardado exitosamente');
// Problema: Falla con updates parciales Livewire

// Patrón 2 (❌ FALLA - no listener)
$this->dispatch('toast', body: 'Movimiento guardado');
// Problema: Evento 'toast' NO EXISTE en sistema
// Resultado: SILENCIO TOTAL

// Patrón 3 (❌ FALLA - no listener)
$this->dispatch('notify', [
    'type' => 'warning',
    'message' => 'No se pudo aprobar'
]);
// Problema: Listener 'notify' NO EXISTE
// Resultado: SILENCIO TOTAL
```

**Solución**: Sistema unificado Toast.php

```php
// 1. Crear componente Livewire
// app/Livewire/Toast.php
class Toast extends Component
{
    public $messages = [];

    protected $listeners = ['notify'];

    public function notify($type, $message)
    {
        $id = uniqid();
        $this->messages[] = compact('id', 'type', 'message');
        $this->dispatch('show-toast-' . $id);
    }

    public function removeMessage($id)
    {
        $this->messages = array_filter(
            $this->messages,
            fn($msg) => $msg['id'] !== $id
        );
    }
}

// 2. Vista con auto-hide
// resources/views/livewire/toast.blade.php
<div class="toast-container position-fixed top-0 end-0 p-3">
    @foreach($messages as $msg)
    <div class="toast show" wire:key="toast-{{ $msg['id'] }}">
        <div class="toast-header bg-{{ $msg['type'] }}">
            <strong>{{ ucfirst($msg['type']) }}</strong>
            <button wire:click="removeMessage('{{ $msg['id'] }}')"
                    class="btn-close"></button>
        </div>
        <div class="toast-body">{{ $msg['message'] }}</div>
    </div>
    @endforeach
</div>

<script>
// Auto-hide después 5 segundos
@foreach($messages as $msg)
Livewire.on('show-toast-{{ $msg['id'] }}', () => {
    setTimeout(() => {
        @this.call('removeMessage', '{{ $msg['id'] }}');
    }, 5000);
});
@endforeach
</script>

// 3. Incluir en layout
// resources/views/layouts/terrena.blade.php
@livewire('toast')

// 4. Uso UNIFICADO en todos los componentes
$this->dispatch('notify',
    type: 'success',
    message: 'Guardado exitosamente'
);
```

**Esfuerzo**: 6 horas

#### 🔴 GAP #3: Delete Sin Confirmación (50% cobertura)

**Archivos SIN confirmación**:
- app/Livewire/Catalogs/UnidadesIndex.php
- app/Livewire/Catalogs/AlmacenesIndex.php
- app/Livewire/Purchasing/Requests/Index.php
- app/Livewire/InventoryCount/Index.php
- ... (~15 componentes)

**Solución**: Modal reutilizable

```blade
<!-- resources/views/components/confirm-delete.blade.php -->
<div class="modal fade" id="confirmDeleteModal" wire:ignore.self>
    <div class="modal-dialog modal-sm">
        <div class="modal-content">
            <div class="modal-header bg-danger text-white">
                <h5>Confirmar Eliminación</h5>
            </div>
            <div class="modal-body">
                ¿Está seguro que desea eliminar este registro?
                <strong>Esta acción no se puede deshacer.</strong>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" data-bs-dismiss="modal">
                    Cancelar
                </button>
                <button class="btn btn-danger"
                        wire:click="confirmDelete"
                        wire:loading.attr="disabled">
                    <span wire:loading.remove>Eliminar</span>
                    <span wire:loading>Eliminando...</span>
                </button>
            </div>
        </div>
    </div>
</div>
```

**Esfuerzo**: 4 horas

### 5.3 Layout Principal (terrena.blade.php)

```blade
<!-- resources/views/layouts/terrena.blade.php -->
<!-- Bootstrap 5, Responsive, Sidebar -->

<body>
    <!-- Top Bar -->
    <div class="top-bar">
        <div class="page-title">@yield('title')</div>
        <div class="alerts">...</div>
        <div class="user-menu">
            <img src="{{ auth()->user()->avatar }}" />
            {{ auth()->user()->name }}
        </div>
    </div>

    <!-- Sidebar -->
    <div class="sidebar" id="sidebar">
        <!-- Responsive:
             Desktop (>992px): 280px ancho
             Tablet (768-991px): 84px (solo iconos)
             Mobile (<768px): Off-canvas
        -->
        <nav>
            <a href="{{ route('dashboard') }}" class="nav-link">
                <i class="fas fa-home"></i>
                <span>Dashboard</span>
            </a>

            <!-- Caja -->
            <div class="nav-section">
                <button data-bs-toggle="collapse"
                        data-bs-target="#cajaSubmenu"
                        aria-expanded="false">  <!-- ⚠️ No actualiza -->
                    <i class="fas fa-cash-register"></i>
                    <span>Caja</span>
                </button>
                <div id="cajaSubmenu" class="collapse">
                    <a href="{{ route('caja.cortes') }}">Cortes</a>
                    <a href="{{ route('caja.fondos') }}">Fondos</a>
                </div>
            </div>

            <!-- ... (15 módulos) -->
        </nav>
    </div>

    <!-- Main Content -->
    <div class="main-content">
        @yield('content')
    </div>

    <!-- Status Bar (Footer) -->
    <div class="status-bar">
        <div class="clock">
            <span id="clock"></span>
        </div>
        <div class="session-status">
            Sesión: {{ auth()->user()->current_session }}
        </div>
    </div>

    <!-- Toast Container -->
    @livewire('toast')
</body>

<script>
// ⚠️ PROBLEMA: Permisos async causan layout shift
document.addEventListener('DOMContentLoaded', function() {
    Livewire.dispatch('check-permissions');  // Async!
    // Links aparecen, luego desaparecen = Mala UX
});

// ⚠️ PROBLEMA: aria-expanded no actualiza
// Debería:
document.querySelectorAll('[data-bs-toggle="collapse"]').forEach(toggle => {
    toggle.addEventListener('click', function() {
        const expanded = this.getAttribute('aria-expanded') === 'true';
        this.setAttribute('aria-expanded', !expanded);
    });
});
</script>
```

### 5.4 Patrones Livewire

**Patrón Completo de Componente**:

```php
// app/Livewire/Catalogs/UnidadesIndex.php

namespace App\Livewire\Catalogs;

use Livewire\Component;
use Livewire\WithPagination;
use App\Models\Unidad;

class UnidadesIndex extends Component
{
    use WithPagination;

    // Búsqueda (ESTÁNDAR: $search con debounce 400ms)
    public $search = '';

    // Paginación
    public $perPage = 15;

    // Modal create/edit
    public $showModal = false;
    public $modalMode = 'create'; // 'create' | 'edit'

    // Form data (usar Form Objects en Laravel 11)
    public $unidadId;
    public $clave;
    public $nombre;
    public $activo = true;

    // Modal delete
    public $showDeleteModal = false;
    public $deleteId;

    protected $rules = [
        'clave' => 'required|max:10',
        'nombre' => 'required|max:50',
        'activo' => 'boolean'
    ];

    // Real-time validation
    public function updated($property)
    {
        $this->validateOnly($property);
    }

    public function openCreate()
    {
        $this->reset(['unidadId', 'clave', 'nombre', 'activo']);
        $this->modalMode = 'create';
        $this->showModal = true;
    }

    public function openEdit($id)
    {
        $unidad = Unidad::findOrFail($id);
        $this->unidadId = $unidad->id;
        $this->clave = $unidad->clave;
        $this->nombre = $unidad->nombre;
        $this->activo = $unidad->activo;
        $this->modalMode = 'edit';
        $this->showModal = true;
    }

    public function save()
    {
        $this->validate();

        if ($this->modalMode === 'create') {
            Unidad::create([
                'clave' => $this->clave,
                'nombre' => $this->nombre,
                'activo' => $this->activo
            ]);
            $message = 'Unidad creada exitosamente';
        } else {
            Unidad::findOrFail($this->unidadId)->update([
                'clave' => $this->clave,
                'nombre' => $this->nombre,
                'activo' => $this->activo
            ]);
            $message = 'Unidad actualizada exitosamente';
        }

        $this->showModal = false;

        // ✅ Sistema unificado de notificaciones
        $this->dispatch('notify',
            type: 'success',
            message: $message
        );
    }

    public function confirmDelete($id)
    {
        $this->deleteId = $id;
        $this->showDeleteModal = true;
    }

    public function delete()
    {
        Unidad::findOrFail($this->deleteId)->delete();
        $this->showDeleteModal = false;

        $this->dispatch('notify',
            type: 'success',
            message: 'Unidad eliminada exitosamente'
        );
    }

    public function render()
    {
        $unidades = Unidad::query()
            ->when($this->search, function($query) {
                $query->where('clave', 'like', "%{$this->search}%")
                      ->orWhere('nombre', 'like', "%{$this->search}%");
            })
            ->paginate($this->perPage);

        return view('livewire.catalogs.unidades-index', [
            'unidades' => $unidades
        ]);
    }
}
```

**Vista Correspondiente**:

```blade
<!-- resources/views/livewire/catalogs/unidades-index.blade.php -->

<div>
    <!-- Filters Bar -->
    <div class="filters-bar mb-3">
        <div class="row">
            <div class="col-md-6">
                <!-- ✅ ESTÁNDAR: debounce 400ms -->
                <input type="text"
                       wire:model.live.debounce.400ms="search"
                       class="form-control"
                       placeholder="Buscar...">
            </div>
            <div class="col-md-6 text-end">
                <button wire:click="openCreate" class="btn btn-primary">
                    <i class="fas fa-plus me-1"></i> Nueva Unidad
                </button>
            </div>
        </div>
    </div>

    <!-- Table -->
    <div class="card">
        <div class="table-responsive">
            <table class="table">
                <thead>
                    <tr>
                        <th>Clave</th>
                        <th>Nombre</th>
                        <th>Activo</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($unidades as $unidad)
                    <tr>
                        <td>{{ $unidad->clave }}</td>
                        <td>{{ $unidad->nombre }}</td>
                        <td>
                            <span class="badge text-bg-{{ $unidad->activo ? 'success' : 'secondary' }}">
                                {{ $unidad->activo ? 'Sí' : 'No' }}
                            </span>
                        </td>
                        <td>
                            <button wire:click="openEdit({{ $unidad->id }})"
                                    class="btn btn-sm btn-primary"
                                    data-bs-toggle="tooltip"
                                    title="Editar">
                                <i class="fas fa-edit"></i>
                            </button>
                            <button wire:click="confirmDelete({{ $unidad->id }})"
                                    class="btn btn-sm btn-danger"
                                    data-bs-toggle="tooltip"
                                    title="Eliminar">
                                <i class="fas fa-trash"></i>
                            </button>
                        </td>
                    </tr>
                    @empty
                    <!-- ✅ MEJORADO: Empty state con gráfico -->
                    <tr>
                        <td colspan="4" class="text-center py-5">
                            <i class="fas fa-inbox fa-3x text-muted mb-3"></i>
                            <p class="text-muted mb-2">No se encontraron unidades</p>
                            @can('create-unidades')
                            <button wire:click="openCreate" class="btn btn-sm btn-primary">
                                <i class="fas fa-plus me-1"></i> Crear Nueva
                            </button>
                            @endcan
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Pagination -->
        <div class="card-footer">
            {{ $unidades->links() }}
        </div>
    </div>

    <!-- Modal Create/Edit -->
    @if($showModal)
    <div class="modal fade show d-block" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <form wire:submit.prevent="save">
                    <div class="modal-header">
                        <h5>{{ $modalMode === 'create' ? 'Nueva' : 'Editar' }} Unidad</h5>
                        <button type="button"
                                wire:click="$set('showModal', false)"
                                class="btn-close"></button>
                    </div>
                    <div class="modal-body">
                        <!-- Clave -->
                        <div class="mb-3">
                            <label class="form-label">Clave *</label>
                            <input type="text"
                                   wire:model.blur="clave"
                                   class="form-control @error('clave') is-invalid @enderror">
                            @error('clave')
                            <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        <!-- Nombre -->
                        <div class="mb-3">
                            <label class="form-label">Nombre *</label>
                            <input type="text"
                                   wire:model.blur="nombre"
                                   class="form-control @error('nombre') is-invalid @enderror">
                            @error('nombre')
                            <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        <!-- Activo -->
                        <div class="mb-3">
                            <div class="form-check">
                                <input type="checkbox"
                                       wire:model="activo"
                                       class="form-check-input"
                                       id="activo">
                                <label class="form-check-label" for="activo">Activo</label>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button"
                                wire:click="$set('showModal', false)"
                                class="btn btn-secondary">
                            Cancelar
                        </button>

                        <!-- ✅ CRÍTICO: Loading state -->
                        <button type="submit"
                                class="btn btn-primary"
                                wire:loading.attr="disabled"
                                wire:target="save">
                            <span wire:loading.remove wire:target="save">Guardar</span>
                            <span wire:loading wire:target="save" style="display:none">
                                <span class="spinner-border spinner-border-sm me-1"></span>
                                Guardando...
                            </span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    <div class="modal-backdrop fade show"></div>
    @endif

    <!-- Modal Delete -->
    @if($showDeleteModal)
    <div class="modal fade show d-block" tabindex="-1">
        <div class="modal-dialog modal-sm">
            <div class="modal-content">
                <div class="modal-header bg-danger text-white">
                    <h5>Confirmar Eliminación</h5>
                </div>
                <div class="modal-body">
                    ¿Está seguro que desea eliminar esta unidad?
                    <strong>Esta acción no se puede deshacer.</strong>
                </div>
                <div class="modal-footer">
                    <button wire:click="$set('showDeleteModal', false)"
                            class="btn btn-secondary">
                        Cancelar
                    </button>
                    <button wire:click="delete"
                            class="btn btn-danger"
                            wire:loading.attr="disabled">
                        <span wire:loading.remove>Eliminar</span>
                        <span wire:loading>Eliminando...</span>
                    </button>
                </div>
            </div>
        </div>
    </div>
    <div class="modal-backdrop fade show"></div>
    @endif
</div>
```

---

## PARTE VI: FLUJOS DE NEGOCIO CRÍTICOS

### 6.1 Flujo: Compras → Inventario (End-to-End)

```
1. REQUISICIÓN DE COMPRA
   Usuario: Comprador

   a) Crear purchase_request (estado: BORRADOR)
   b) Agregar purchase_request_lines (items, cantidades)
   c) Calcular importe_estimado
   d) Enviar a aprobación (estado: APROBADA)

2. COTIZACIONES
   Usuario: Comprador

   a) Solicitar cotizaciones a proveedores (manual/email)
   b) Registrar purchase_vendor_quotes
   c) Agregar purchase_vendor_quote_lines (precios, tiempos)
   d) Comparar cotizaciones (UI tabla comparativa)
   e) Seleccionar mejor proveedor
   f) Estado request: COTIZADA

3. ORDEN DE COMPRA
   Usuario: Comprador

   a) Crear purchase_order desde cotización
   b) Copiar líneas con precios finales
   c) Generar folio OC
   d) Enviar a proveedor (email/print)
   e) Estado request: ORDENADA
   f) Estado order: ENVIADA

4. RECEPCIÓN DE MERCANCÍA
   Usuario: Almacenista

   a) Proveedor entrega mercancía
   b) Almacenista crea recepcion_cab
   c) Por cada item:
      - Verificar cantidad vs OC
      - Verificar calidad
      - Asignar lote (batch_code, caducidad)
      - Registrar recepcion_det
   d) ReceptionService.createReception():
      - Crear/actualizar inventory_batch
      - Insertar mov_inv (tipo=ENTRADA)
      - Actualizar costo_promedio en items
      - Incrementar stock
   e) Estado order: RECIBIDA
   f) Estado request: RECIBIDA

5. RESULTADO FINAL

   - Stock actualizado en items
   - Kardex registrado en mov_inv
   - Lotes trazables en inventory_batch
   - Costo promedio actualizado
   - Orden y requisición cerradas
```

### 6.2 Flujo: POS → Consumo → Kardex

```
1. VENTA EN POS (FloreantPOS - esquema public)
   Usuario: Cajero

   a) Cliente ordena en POS
   b) FloreantPOS crea:
      - public.ticket (total, mesa, usuario)
      - public.ticket_item (menu_item_id, cantidad, precio)
      - public.transactions (pagos)
   c) Ticket se cierra en POS

2. INGESTA A TERRENA
   Trigger: Automático (cada X minutos) o Manual

   a) Función: ingesta_ticket()
   b) Lee tickets nuevos de public.ticket
   c) Copia a selemti para procesamiento

3. MAPEO POS → RECETAS
   Automático

   a) Consultar selemti.pos_map:
      - pos_menu_item_id → receta_id
      - ratio (ej: 1 plato = 1 receta)
   b) Si no hay mapeo:
      - Alerta a usuario
      - Requiere mapeo manual
   c) Si hay mapeo:
      - Continúa a expansión

4. EXPANSIÓN DE CONSUMO
   Función: fn_expandir_consumo_ticket(ticket_id)

   a) Por cada ticket_item:
      - Buscar receta mapeada
      - Consultar receta_insumo (BOM)
      - Calcular cantidad por porción
   b) Generar ticket_det_consumo:
      - ticket_item_id
      - item_id (insumo)
      - cantidad_consumida
      - uom_id
   c) Agregar a tabla inv_consumo_pos

5. CONFIRMACIÓN DE CONSUMO
   Función: fn_confirmar_consumo_ticket(ticket_id)

   a) Validar que expansión existe
   b) Por cada línea de consumo:
      - Normalizar a UOM base
      - Insertar mov_inv (tipo=SALIDA, ref_tipo=TICKET)
      - Decrementar stock en inventory_batch (FEFO)
      - Actualizar costo_promedio
   c) Marcar ticket como CONFIRMADO

6. REVERSIÓN (si ticket se cancela)
   Función: fn_reversar_consumo_ticket(ticket_id)

   a) Buscar mov_inv con ref_tipo=TICKET, ref_id=ticket_id
   b) Crear movimientos inversos (ENTRADA)
   c) Restaurar stock
   d) Marcar ticket como REVERSADO

7. RESULTADO FINAL

   - Venta en POS
   - Consumo de insumos registrado
   - Kardex actualizado
   - Stock reducido
   - Costeo de recetas actualizado
   - Trazabilidad completa POS → Receta → Insumos
```

### 6.3 Flujo: Corte de Caja Diario

```
1. APERTURA DE SESIÓN
   Usuario: Cajero

   a) Cajero inicia turno en terminal
   b) Crear selemti.sesion_cajon:
      - terminal_id
      - cajero_usuario_id
      - apertura_ts = NOW()
      - estatus = 'ACTIVA'
      - opening_float (fondo inicial, ej: $500)
   c) Registrar en audit_log

2. OPERACIÓN DURANTE TURNO
   Automático (POS registra ventas)

   - Tickets se crean en public.ticket
   - Transacciones en public.transactions
   - FloreantPOS maneja todo
   - Terrena solo observa (READ-ONLY)

3. FIN DE TURNO - PRECORTE
   Usuario: Cajero

   a) Cajero decide cerrar
   b) Crear selemti.precorte:
      - sesion_id FK → sesion_cajon
      - estatus = 'PENDIENTE'
      - creado_en = NOW()
   c) Contar efectivo por denominación:
      - precorte_efectivo (billetes 1000, 500, 200, 100, 50, 20)
      - precorte_otros (tarjetas, transferencias, vales)
   d) Sistema calcula:
      - total_contado = SUM(precorte_efectivo + precorte_otros)
      - total_esperado = SUM(public.transactions WHERE sesion...)
      - varianza = total_contado - total_esperado
   e) Helper ver(varianza):
      - Si |varianza| <= $0.50: 'CUADRA'
      - Si varianza > 0: 'A_FAVOR' (sobra dinero)
      - Si varianza < 0: 'EN_CONTRA' (falta dinero)
   f) Trigger: trg_precorte_after_insert
      - Genera snapshot de caja
      - Actualiza sesion_cajon.estatus = 'LISTO_PARA_CORTE'

4. SUPERVISIÓN - POSTCORTE
   Usuario: Supervisor

   a) Supervisor revisa precorte
   b) Si aprueba:
      - Crear selemti.postcorte:
        - sesion_id
        - aprobado_por = supervisor_user_id
        - aprobado_en = NOW()
        - estatus = 'APROBADO'
      - Trigger: trg_postcorte_after_insert
        - Genera conciliacion automática
        - Cierra sesion_cajon.estatus = 'CERRADA'
        - cierre_ts = NOW()
   c) Si rechaza:
      - postcorte.estatus = 'RECHAZADO'
      - postcorte.rechazado_por = supervisor_user_id
      - postcorte.notas_rechazo = '...'
      - Cajero debe re-contar (nuevo precorte)

5. ALERTAS Y NOTIFICACIONES
   Servicio: AlertasService (⚠️ sin doc)

   a) Si varianza > umbral ($50):
      - Crear selemti.alertas_cortes
      - destinatario_id = gerente
      - tipo_alerta = 'VARIANZA_ALTA'
   b) Enviar notificación (email/push)

6. REPORTES
   Vista: vw_sesion_dpr

   - Dashboard con todas las sesiones
   - KPIs: total_ventas, total_transacciones, varianzas
   - Filtros: fecha, sucursal, terminal, cajero
   - Exportar a Excel/PDF

7. RESULTADO FINAL

   - Sesión cerrada y conciliada
   - Efectivo depositado
   - Varianzas documentadas
   - Auditoría completa
   - Reportes generados
```

---

## PARTE VII: PATRONES Y CONVENCIONES

### 7.1 Convenciones de Naming

#### Modelos

```php
// Singular, PascalCase
Item, Receta, PurchaseRequest, CashFund

// Relaciones
public function items() { return $this->hasMany(Item::class); }
public function receta() { return $this->belongsTo(Receta::class); }
```

#### Tablas BD

```sql
-- Plural, snake_case
items, recetas, purchase_requests, cash_funds

-- Join tables: singular_singular
item_vendor, role_has_permissions

-- Pivot con data extra: nombre descriptivo
receta_insumo (no receta_item)
```

#### Controladores

```php
// PascalCase + Controller suffix
ItemsController, PurchaseRequestsController

// REST actions
index(), create(), store(), show($id), edit($id), update($id), destroy($id)

// API
ItemApiController, RecipeCostController
```

#### Servicios

```php
// PascalCase + Service suffix
ReceptionService, PurchasingService, CashFundService

// Métodos: verbo + sustantivo
createReception(), addQuote(), calculateCost()
```

#### Livewire

```php
// Namespace: App\Livewire\{Module}\{Action}
App\Livewire\Inventory\ItemsIndex
App\Livewire\Purchasing\Requests\Create

// Archivo: snake_case
app/Livewire/Inventory/ItemsIndex.php
resources/views/livewire/inventory/items-index.blade.php
```

#### Rutas

```php
// Kebab-case
Route::get('/inventory/items', ...);
Route::post('/purchase-requests/create', ...);

// Named routes: dot notation
route('inventory.items.index')
route('purchase.requests.create')
```

### 7.2 Convenciones de Código

#### Respuestas API

```php
// Éxito
return response()->json([
    'ok' => true,
    'data' => $result,
    'timestamp' => now()->toIso8601String()
], 200);

// Error
return response()->json([
    'ok' => false,
    'error' => 'validation_failed',
    'message' => 'Los datos no son válidos',
    'errors' => $validator->errors(),
    'timestamp' => now()->toIso8601String()
], 422);

// Usando helper CajaHelper::J()
return J(['items' => $items], 200);
```

#### Transacciones BD

```php
// SIEMPRE usar transacciones para operaciones multi-tabla
DB::transaction(function () {
    $recepcion = RecepcionCab::create($header);

    foreach ($lines as $line) {
        RecepcionDet::create([...]);
        MovInv::create([...]);
        // Si falla cualquiera, rollback automático
    }

    return $recepcion->id;
});
```

#### Validación Livewire

```php
// Reglas en propiedad
protected $rules = [
    'nombre' => 'required|min:3|max:100',
    'email' => 'required|email|unique:users,email',
    'activo' => 'boolean'
];

// Real-time validation on blur
public function updated($property)
{
    $this->validateOnly($property);
}

// Mensajes personalizados
protected $messages = [
    'nombre.required' => 'El nombre es obligatorio',
    'email.unique' => 'Este email ya está registrado'
];

// Atributos legibles
protected $validationAttributes = [
    'nombre' => 'nombre del item',
    'email' => 'correo electrónico'
];
```

---

## PARTE VIII: ROADMAP Y PRIORIDADES

### 8.1 Objetivos Cuantificables

```
Meta Global: Sistema con 94% de madurez en 8 sprints (4 meses)

Dimensión          | Actual | Objetivo | Gap    | Prioridad
-------------------|--------|----------|--------|----------
Documentación      | 76%    | 94%      | +18%   | 🔴 CRÍTICA
Código             | 61%    | 80%      | +19%   | 🔴 CRÍTICA
Base de Datos      | 90%    | 95%      | +5%    | 🟡 ALTA
UI/UX              | 6.5/10 | 8.0/10   | +1.5   | 🔴 CRÍTICA
Tests              | 30%    | 70%      | +40%   | 🟡 ALTA
```

### 8.2 Quick Wins (2 semanas)

**Sprint 1 - 24 horas**:
1. Forms loading states (4h) → +1.0 punto UX
2. Sistema toasts unificado (6h) → +0.5 punto UX
3. Confirmaciones delete (4h) → +0.3 punto UX
4. Consolidar PosConsumptionService (4h) → -1 duplicación crítica
5. Consolidar ProductionService (3h) → -1 duplicación
6. Fix layout shift permisos (3h) → +0.2 punto UX

**Resultado Sprint 1**:
- UX: 6.5 → 8.2 (+1.7) ✅ OBJETIVO ALCANZADO
- Código duplicado: 4 → 2 (-50%)
- Impacto inmediato en experiencia usuario

### 8.3 Roadmap Completo (8 sprints)

Ver `02_BACKLOG_SPRINTS_CLAUDE_v2.md` para detalle completo.

**Resumen**:
```
Sprint 1-2:  UI/UX + Duplicaciones (55h)
Sprint 3-4:  Docs Core (52h)
Sprint 5-6:  Código Huérfano (95h)
Sprint 7-8:  BD + Tests (87h)

Total: 289 horas / 8 sprints / 4 meses
```

---

## CONCLUSIÓN

Este Compendio Supremo representa el **conocimiento más profundo y completo** del sistema Terrena POS/ERP, consolidado a partir de:

- **6 fases de auditoría exhaustiva** (13 Nov 2025)
- **729 archivos de documentación** analizados
- **479 archivos de código** revisados
- **147 tablas de BD** documentadas
- **42 componentes UI** evaluados

**Propósito**: Servir como **referencia definitiva** para cualquier agente IA o desarrollador humano que trabaje en el sistema.

**Uso Recomendado**:
1. Leer CONTRATO (visión del sistema)
2. Revisar MATRIZ ALINEACIÓN (estado actual vs objetivo)
3. Consultar BACKLOG (trabajo planificado)
4. Profundizar en COMPENDIO (este documento)

**Mantenimiento**:
- Actualizar después de cada sprint
- Incorporar cambios significativos
- Mantener sincronizado con código y BD

---

**FIN COMPENDIO SUPREMO FUSIÓN - CLAUDE**

*Versión 1.0 - 14 Noviembre 2025*
*Orquestador: Claude Code*
*Basado en: Auditoría FASE1-FASE6 (13 Nov 2025)*
