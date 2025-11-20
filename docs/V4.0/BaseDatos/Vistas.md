# VISTAS - Sistema Terrena

**MAESTRO (Consolidación CLAUDE + QWEN + CODEX + COPILOT)**
**Fecha**: 14 Noviembre 2025

---

## OVERVIEW

**Total de vistas en `selemti`**: 38 vistas
**Total de vistas en `public`**: 32 vistas (sistema POS Floreant)

**Distribución**:
- Vistas de reportes: 27 (71%)
- Vistas de compatibilidad legacy: 11 (29%)
- Vistas sin uso detectado: 5 (13%)

**Alineación con V4.0**: 87%

---

## 1. VISTAS DE REPORTES (9 vistas) - ⭐⭐⭐⭐⭐ EXCELENTE

Estas vistas alimentan el dashboard y reportes principales del sistema.

### ✅ 1.1 vw_sesion_dpr

**Módulo**: Caja / Reportes
**Propósito**: Dashboard de sesiones con detalle de Drawer Pull Report
**Estado**: ✅ DOCUMENTADO

**Uso**:
- Dashboard de caja
- Reporte de sesiones
- Análisis de variaciones

**Columnas principales**:
- `sesion_id`, `terminal_id`, `sucursal_id`
- `apertura_ts`, `cierre_ts`
- `total_ventas`, `total_cobrado`, `variacion`
- `estatus` (ACTIVA, CERRADA, PENDIENTE)

**Joins**:
```
sesion_cajon
    LEFT JOIN precorte
    LEFT JOIN postcorte
    LEFT JOIN conciliacion
    JOIN terminal (public)
    JOIN branch (public)
```

**Documentación completa**: `/docs/V4.0/Caja/`

---

### ✅ 1.2 vw_dashboard_ticket_base

**Módulo**: Reportes / Ventas
**Propósito**: Base de datos de tickets para dashboard
**Estado**: ✅ DOCUMENTADO

**Uso**:
- Dashboard principal
- KPIs de ventas
- Análisis de tickets

**Columnas principales**:
- `ticket_id`, `fecha`, `sucursal`, `terminal`
- `total`, `total_discount`, `due_amount`
- `paid`, `voided`, `status`

**Source**: `public.ticket` (Floreant POS)

**Transformaciones**:
- Normaliza formas de pago
- Calcula totales netos
- Filtra tickets void

**Documentación**: `/docs/V4.0/Reportes/`

---

### ✅ 1.3 vw_dashboard_resumen_sucursal

**Módulo**: Reportes / Ventas
**Propósito**: Resumen de ventas por sucursal (diario)
**Estado**: ✅ DOCUMENTADO

**Uso**:
- Dashboard ejecutivo
- Comparación entre sucursales

**Columnas**:
- `sucursal_id`, `sucursal_nombre`, `fecha`
- `total_tickets`, `total_ventas`, `ticket_promedio`
- `total_descuentos`, `cancelaciones`

**Agregación**: GROUP BY sucursal, fecha

**Documentación**: `/docs/V4.0/Reportes/`

---

### ✅ 1.4 vw_dashboard_resumen_terminal

**Módulo**: Reportes / Ventas
**Propósito**: Resumen de ventas por terminal
**Estado**: ✅ DOCUMENTADO

**Uso**:
- Dashboard de sucursal
- Performance por caja

**Columnas**:
- `terminal_id`, `terminal_name`, `fecha`
- `total_tickets`, `total_ventas`, `ticket_promedio`

**Agregación**: GROUP BY terminal, fecha

**Documentación**: `/docs/V4.0/Reportes/`

---

### ✅ 1.5 vw_dashboard_ventas_categorias

**Módulo**: Reportes / Ventas
**Propósito**: Ventas agrupadas por categoría de producto
**Estado**: ✅ DOCUMENTADO

**Uso**:
- Análisis de mix de productos
- Categorías top selling

**Columnas**:
- `categoria_id`, `categoria_nombre`, `fecha`
- `total_items`, `total_ventas`, `porcentaje_mix`

**Source**: `public.ticket_item` JOIN `public.menu_category`

**Documentación**: `/docs/V4.0/Reportes/`

---

### ✅ 1.6 vw_dashboard_ventas_productos

**Módulo**: Reportes / Ventas
**Propósito**: Ventas agrupadas por producto
**Estado**: ✅ DOCUMENTADO

**Uso**:
- Top selling items
- Análisis de popularidad

**Columnas**:
- `menu_item_id`, `nombre`, `fecha`
- `qty_vendida`, `total_ventas`, `precio_promedio`

**Source**: `public.ticket_item` JOIN `public.menu_item`

**Ordenamiento**: ORDER BY total_ventas DESC

**Documentación**: `/docs/V4.0/Reportes/`

---

### ✅ 1.7 vw_dashboard_ventas_hora

**Módulo**: Reportes / Ventas
**Propósito**: Distribución de ventas por hora del día
**Estado**: ✅ DOCUMENTADO

**Uso**:
- Análisis de patrones de tráfico
- Planeación de turnos

**Columnas**:
- `hora` (0-23), `fecha`
- `total_tickets`, `total_ventas`, `ticket_promedio`

**Agregación**: GROUP BY EXTRACT(HOUR FROM create_date)

**Documentación**: `/docs/V4.0/Reportes/`

---

### ✅ 1.8 vw_dashboard_formas_pago

**Módulo**: Reportes / Ventas
**Propósito**: Distribución de ventas por forma de pago
**Estado**: ✅ DOCUMENTADO

**Uso**:
- Análisis de métodos de pago
- Mix de formas de pago

**Columnas**:
- `forma_pago`, `fecha`
- `total_transacciones`, `monto_total`, `porcentaje_mix`

**Source**: `public.transactions` JOIN `selemti.formas_pago`

**Documentación**: `/docs/V4.0/Reportes/`

---

### ✅ 1.9 vw_dashboard_ordenes

**Módulo**: Reportes / KDS
**Propósito**: Dashboard de órdenes para Kitchen Display System
**Estado**: ✅ DOCUMENTADO

**Uso**:
- KDS (Kitchen Display System)
- Monitor de cocina

**Columnas**:
- `orden_id`, `ticket_id`, `mesa`, `estado`
- `items`, `tiempo_preparacion`, `prioridad`

**Source**: `public.kitchen_ticket` JOIN `public.kitchen_ticket_item`

**Filtro**: WHERE estado IN ('PENDING', 'IN_PROGRESS')

**Documentación**: `/docs/V4.0/KDS/`

---

## 2. VISTAS DE INVENTARIO (7 vistas) - ⭐⭐⭐⭐ BIEN

### ⚠️ 2.1 vw_kardex

**Módulo**: Inventario / Kardex
**Propósito**: Vista completa del kardex de movimientos
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**:
- Reporte de kardex por item
- Trazabilidad de movimientos

**Columnas**:
- `item_id`, `item_codigo`, `item_nombre`
- `fecha`, `tipo_movimiento`, `qty`, `uom`
- `costo_unitario`, `costo_total`
- `ref_tipo`, `ref_id` (documento origen)

**Source**: `mov_inv` JOIN `items` JOIN `cat_unidades`

**Documentación**: Pendiente

---

### ⚠️ 2.2 vw_stock_por_lote_fefo

**Módulo**: Inventario / Stock
**Propósito**: Stock disponible por lote ordenado FEFO (First Expire First Out)
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**:
- Picking de lotes (FEFO)
- Control de vencimientos

**Columnas**:
- `item_id`, `lote_id`, `lote_codigo`
- `fecha_vencimiento`, `qty_disponible`
- `almacen_id`, `almacen_nombre`

**Source**: `inventory_batch` JOIN `items`

**Ordenamiento**: ORDER BY fecha_vencimiento ASC

**Documentación**: Pendiente

---

### ⚠️ 2.3 vw_item_last_price

**Módulo**: Inventario / Precios
**Propósito**: Último precio de compra por item
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**:
- Cotizaciones
- Análisis de precios

**Columnas**:
- `item_id`, `proveedor_id`
- `ultimo_precio`, `fecha_ultimo_precio`
- `uom`, `qty_minima`

**Source**: `item_vendor_prices`

**Agregación**: MAX(vigente_desde)

**Documentación**: Pendiente

---

### ⚠️ 2.4 vw_item_last_price_pref

**Módulo**: Inventario / Precios
**Propósito**: Precio preferido por item (proveedor preferido)
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**:
- Generación de requisiciones
- Sugerencias de compra

**Columnas**:
- `item_id`, `proveedor_preferido_id`
- `precio_preferido`, `fecha`

**Source**: `item_vendor_prices` WHERE `preferido = true`

**Documentación**: Pendiente

---

### ⚠️ 2.5 vw_movimientos_anomalos

**Módulo**: Inventario / Auditoría
**Propósito**: Detecta movimientos anómalos de inventario
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**:
- Auditoría de inventario
- Detección de fraudes

**Columnas**:
- `mov_id`, `item_id`, `fecha`, `qty`
- `tipo_anomalia` (CANTIDAD_EXCESIVA, COSTO_ANOMALO, etc.)

**Lógica**:
- Detecta cantidades > 3 desviaciones estándar
- Detecta costos atípicos
- Detecta movimientos fuera de horario

**Documentación**: Pendiente

---

### ⚠️ 2.6 v_stock_actual

**Módulo**: Inventario / Stock
**Propósito**: Stock actual por item y almacén
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**:
- Consulta rápida de stock
- Dashboard de inventario

**Columnas**:
- `item_id`, `almacen_id`
- `qty_disponible`, `costo_promedio`
- `valor_total`

**Source**: Agregación de `mov_inv` GROUP BY item, almacén

**Documentación**: Pendiente

---

### ❌ 2.7 v_stock_brechas

**Módulo**: Inventario / Stock
**Propósito**: Detecta brechas de stock (faltantes/sobrantes vs teórico)
**Estado**: ❌ SIN USO DETECTADO

**Uso**: No se encontró referencia en código

**Acción**: Validar uso, deprecar si no se usa

---

## 3. VISTAS DE CATÁLOGOS LEGACY (11 vistas) - ⭐⭐⭐ COMPATIBILIDAD

Estas vistas mantienen compatibilidad con código legacy durante la migración.

### ⚠️ 3.1 unidad_medida

**Módulo**: Catálogos (Legacy)
**Propósito**: Vista de compatibilidad para `cat_unidades`
**Estado**: ⚠️ DEPRECAR (compatibilidad)

**Definición**:
```sql
CREATE OR REPLACE VIEW unidad_medida AS
SELECT * FROM cat_unidades;
```

**Uso**: Código legacy que aún no migró a `cat_unidades`

**Acción**: Migrar código que la usa → `cat_unidades`

**Documentación**: `/docs/BD/Normalizacion/`

---

### ⚠️ 3.2 unidades_medida

**Módulo**: Catálogos (Legacy)
**Propósito**: Vista duplicada de `unidad_medida`
**Estado**: ⚠️ DEPRECAR

**Acción**: Consolidar con `unidad_medida` o eliminar

---

### ⚠️ 3.3 uom_conversion

**Módulo**: Catálogos (Legacy)
**Propósito**: Vista de compatibilidad para `cat_uom_conversion`
**Estado**: ⚠️ DEPRECAR

**Definición**:
```sql
CREATE OR REPLACE VIEW uom_conversion AS
SELECT * FROM cat_uom_conversion;
```

**Acción**: Migrar código → `cat_uom_conversion`

---

### ⚠️ 3.4 conversiones_unidad

**Módulo**: Catálogos (Legacy)
**Propósito**: Vista duplicada de `uom_conversion`
**Estado**: ⚠️ DEPRECAR

**Acción**: Consolidar o eliminar

---

### ⚠️ 3.5 v_almacen

**Módulo**: Catálogos (Legacy)
**Propósito**: Vista de compatibilidad para `cat_almacenes`
**Estado**: ⚠️ DEPRECAR

**Definición**:
```sql
CREATE OR REPLACE VIEW v_almacen AS
SELECT * FROM cat_almacenes;
```

---

### ⚠️ 3.6 v_bodega

**Módulo**: Catálogos (Legacy)
**Propósito**: Vista de compatibilidad (bodega = almacén)
**Estado**: ⚠️ DEPRECAR

**Definición**:
```sql
CREATE OR REPLACE VIEW v_bodega AS
SELECT * FROM cat_almacenes;
```

---

### ⚠️ 3.7 v_sucursal

**Módulo**: Catálogos (Legacy)
**Propósito**: Vista de compatibilidad para `cat_sucursales`
**Estado**: ⚠️ DEPRECAR

---

### ⚠️ 3.8 v_rol

**Módulo**: Seguridad (Legacy)
**Propósito**: Vista de compatibilidad para `roles` (Spatie)
**Estado**: ⚠️ DEPRECAR

---

### ⚠️ 3.9 v_usuario

**Módulo**: Seguridad (Legacy)
**Propósito**: Vista de compatibilidad para `users`
**Estado**: ⚠️ DEPRECAR

---

### ⚠️ 3.10 v_cat_unidades_compat

**Módulo**: Catálogos (Legacy)
**Propósito**: Vista de compatibilidad con campos legacy
**Estado**: ⚠️ DEPRECAR

**Definición**: Mapea nombres de campos legacy → nuevos

---

### ⚠️ 3.11 v_unidad_medida_singular_compat

**Módulo**: Catálogos (Legacy)
**Propósito**: Vista para nombres singulares de UOM
**Estado**: ⚠️ DEPRECAR

---

**Estrategia de deprecación**:

1. Mantener vistas legacy hasta Q1 2026
2. Agregar comentarios: `COMMENT ON VIEW ... IS 'DEPRECATED - Use cat_* directly'`
3. Logging de uso para identificar código que las usa
4. Migrar código → tablas nuevas
5. Deprecar cuando uso = 0

---

## 4. VISTAS DE RECETAS/PRODUCCIÓN (5 vistas) - ⭐⭐⭐ PARCIAL

### ⚠️ 4.1 v_receta

**Módulo**: Recetas (Legacy)
**Propósito**: Vista de compatibilidad para `receta_cab`
**Estado**: ⚠️ DEPRECAR

**Acción**: Migrar código → `receta_cab`

---

### ⚠️ 4.2 v_receta_insumo

**Módulo**: Recetas (Legacy)
**Propósito**: Vista de compatibilidad para BOM
**Estado**: ⚠️ DEPRECAR

**Acción**: Migrar código → `receta_insumo`

---

### ⚠️ 4.3 v_insumo

**Módulo**: Inventario (Legacy)
**Propósito**: Vista de compatibilidad para `items`
**Estado**: ⚠️ DEPRECAR

**Acción**: Migrar código → `items`

---

### ⚠️ 4.4 v_lote

**Módulo**: Inventario (Legacy)
**Propósito**: Vista de compatibilidad para `inventory_batch`
**Estado**: ⚠️ DEPRECAR

**Acción**: Migrar código → `inventory_batch`

---

### ❌ 4.5 v_merma_por_item

**Módulo**: Inventario / Mermas
**Propósito**: Análisis de mermas agregadas por item
**Estado**: ❌ SIN USO DETECTADO

**Uso**: No se encontró referencia en código

**Acción**: Validar uso, deprecar si no se usa

---

## 5. VISTAS DE POS (2 vistas) - ⭐⭐⭐⭐ BIEN

### ⚠️ 5.1 vw_pos_map_resuelto

**Módulo**: POS / Mapeo
**Propósito**: Mapeo menu_item ↔ receta con nombres resueltos
**Estado**: ✅ EN USO (modelo huérfano)

**Uso**:
- Dashboard de mapeo POS
- Validación de mapeos

**Columnas**:
- `menu_item_id`, `menu_item_name` (POS)
- `receta_id`, `receta_nombre` (selemti)
- `porciones`, `costo_porcion`

**Source**: `pos_map` JOIN `public.menu_item` JOIN `receta_cab`

**Documentación**: Pendiente

---

### ⚠️ 5.2 vw_ticket_promedio_sucursal_dia

**Módulo**: Reportes / Ventas
**Propósito**: Ticket promedio por sucursal y día
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**:
- KPI de ticket promedio
- Comparación entre sucursales

**Columnas**:
- `sucursal_id`, `fecha`
- `total_tickets`, `total_ventas`, `ticket_promedio`

**Agregación**: AVG(total_price) GROUP BY sucursal, fecha

**Documentación**: Pendiente

---

## 6. VISTAS DE PURCHASING (2 vistas) - ⭐⭐⭐⭐ BIEN

### ❌ 6.1 vw_replenishment_dashboard

**Módulo**: Purchasing / Reabasto
**Propósito**: Dashboard de sugerencias de reabasto
**Estado**: ❌ MÓDULO NO DOCUMENTADO

**Uso**:
- Dashboard de reabasto (NO implementado)
- Motor de replenishment 0%

**Columnas**:
- `item_id`, `stock_actual`, `stock_minimo`
- `qty_sugerida`, `proveedor_sugerido`

**Source**: `replenishment_suggestions` JOIN `items`

**Acción**: Implementar módulo de reabasto (Sprint 2 según BACKLOG)

---

### ⚠️ 6.2 vw_items_con_uom

**Módulo**: Inventario / Catálogos
**Propósito**: Items con unidades de medida resueltas (nombres)
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**:
- Listados de items
- Recepciones, requisiciones

**Columnas**:
- `item_id`, `item_codigo`, `item_nombre`
- `uom_base`, `uom_compra`, `uom_salida` (nombres resueltos)

**Source**: `items` JOIN `cat_unidades` (3 veces)

**Documentación**: Pendiente

---

## 7. VISTAS DE VENTAS (2 vistas) - ⭐⭐⭐⭐ BIEN

### ✅ 7.1 vw_ventas_por_hora

**Módulo**: Reportes / Ventas
**Propósito**: Ventas agregadas por hora (igual que `vw_dashboard_ventas_hora`)
**Estado**: ✅ DOCUMENTADO

**Uso**:
- Reportes de ventas
- Análisis de patrones

**Documentación**: `/docs/V4.0/Reportes/`

---

### ❌ 7.2 v_ingenieria_menu_completa

**Módulo**: Reportes / Menu Engineering
**Propósito**: Análisis completo de ingeniería de menú
**Estado**: ❌ SIN USO DETECTADO

**Uso**: No se encontró referencia en código

**Columnas esperadas**:
- `menu_item_id`, `popularidad`, `rentabilidad`
- `clasificacion` (STAR, PLOWHORSE, PUZZLE, DOG)

**Acción**: Validar uso, deprecar si no se usa

---

## 8. VISTAS DEL ESQUEMA PUBLIC - SISTEMA FLOREANT POS

Todas estas vistas fueron creadas por Terrena para explotar datos del sistema Floreant POS (esquema `public`). Son fundamentales para la integración POS ↔ Terrena.

### Top 10 vistas public más usadas:

| Vista | Propósito | Uso en selemti |
|-------|-----------|----------------|
| `vw_ticket_base` | Base de tickets normalizada | ✅ vw_dashboard_ticket_base |
| `vw_report_sales_detail` | Detalle de ventas | ✅ Reportes |
| `vw_report_sales_summary` | Resumen de ventas | ✅ Reportes |
| `vw_report_balance_detail` | Balance de caja | ✅ Conciliación |
| `vw_diag_orphans_tickets` | Tickets huérfanos | ✅ Diagnóstico |
| `vw_sales_kpis` | KPIs de ventas | ✅ Dashboard |
| `vw_sales_daily_branch` | Ventas diarias por sucursal | ✅ Reportes |
| `vw_discounts_detail_line` | Detalle de descuentos | ✅ Auditoría |
| `vw_item_mods_today` | Modificadores hoy | ✅ KDS |
| `ticket_folio_complete` | Folio completo de ticket | ✅ Impresión |

### 8.1 VISTAS DE REPORTES Y KPIs

| Vista | Propósito | Uso principal | Estado |
|-------|-----------|---------------|--------|
| `vw_sales_daily_branch` | Ventas diarias por sucursal | Reporte ejecutivo | EN USO |
| `vw_sales_daily_branch_range` | Ventas con rango de fechas | Reporte detallado | EN USO |
| `vw_sales_kpis` | KPIs principales de ventas | Dashboard | EN USO |
| `vw_sales_mix_payment_today` | Mezcla de pagos diarios | Análisis de pagos | EN USO |
| `vw_sales_exceptions_today` | Excepciones de ventas | Auditoría | EN USO |
| `vw_top_items_today` | Items principales del día | Análisis de rotación | EN USO |
| `vw_ventas_por_hora` | Ventas por hora | Análisis horario | EN USO |

### 8.2 VISTAS DE DIAGNÓSTICOS

| Vista | Propósito | Uso principal | Estado |
|-------|-----------|---------------|--------|
| `vw_daily_diagnostics_summary` | Diagnóstico diario resumen | Reporte de inconsistencias | DIAGNÓSTICO |
| `vw_diag_discount_header_vs_lines` | Descuentos encabezado vs líneas | Validación de descuentos | DIAGNÓSTICO |
| `vw_diag_drawer_vs_cash_transactions` | Cajón vs transacciones en efectivo | Validación de fondo / cambio | DIAGNÓSTICO |
| `vw_diag_folio_date_inconsistency` | Inconsistencias en fechas de folio | Validación de fechas | DIAGNÓSTICO |
| `vw_diag_high_discounts` | Tickets con descuentos altos | Control de descuentos | DIAGNÓSTICO |
| `vw_diag_neto_vs_cobros` | Ventas netas vs cobros | Validación de pagos | DIAGNÓSTICO |
| `vw_diag_orphans_tickets` | Tickets huérfanos | Validación de integridad | DIAGNÓSTICO |
| `vw_diag_orphans_tx` | Transacciones huérfanas | Validación de integridad | DIAGNÓSTICO |
| `vw_diag_pagos_egresos` | Pagos vs egresos | Validación de flujo de caja | DIAGNÓSTICO |
| `vw_diag_paid_but_no_payments` | Tickets pagados sin pagos | Validación de integridad | DIAGNÓSTICO |
| `vw_diag_service_charge_vs_paid` | Cargos de servicio vs pagos | Validación de cobros | DIAGNÓSTICO |
| `vw_diag_unnormalized_payments` | Pagos no normalizados | Validación de pagos | DIAGNÓSTICO |

### 8.3 VISTAS DE MODIFICADORES (KDS)

| Vista | Propósito | Uso principal | Estado |
|-------|-----------|---------------|--------|
| `vw_item_mods_by_item_today` | Modificadores por ítem del día | Análisis de personalizaciones | KDS |
| `vw_item_mods_daily_summary` | Resumen diario de modificadores | Reporte de personalizaciones | KDS |
| `vw_item_mods_today` | Modificadores del día | Seguimiento KDS | KDS |

### 8.4 VISTAS DE REPORTES FINANCIEROS

| Vista | Propósito | Uso principal | Estado |
|-------|-----------|---------------|--------|
| `vw_report_balance_detail` | Detalle de balance para reportes | Conciliación | REPORTES |
| `vw_report_journal_lines` | Líneas de diario | Reporte contable | REPORTES |
| `vw_report_journal_payments` | Pagos de diario | Reporte contable | REPORTES |
| `vw_report_menu_usage` | Uso de menú | Reporte de análisis | REPORTES |
| `vw_report_sales_detail` | Detalle de ventas | Reporte detallado | REPORTES |
| `vw_report_sales_exceptions` | Excepciones de ventas | Auditoría | REPORTES |
| `vw_report_sales_summary` | Resumen de ventas | Reporte ejecutivo | REPORTES |

### 8.5 VISTAS DE DESCUENTOS

| Vista | Propósito | Uso principal | Estado |
|-------|-----------|---------------|--------|
| `vw_discounts_daily` | Reporte diario de descuentos | Análisis de descuentos | DIAGNÓSTICO |
| `vw_discounts_detail_line` | Detalle de descuentos por línea | Auditoría de descuentos | DIAGNÓSTICO |

### 8.6 VISTAS DE KDS (Kitchen Display System)

| Vista | Propósito | Uso principal | Estado |
|-------|-----------|---------------|--------|
| `kds_orders_enhanced` | Órdenes para KDS mejoradas | Sistema de cocina | KDS |
| `vw_item_mods_today` | Modificadores para KDS | Personalizaciones | KDS |

### 8.7 VISTAS DE SOPORTE/INTEGRACIÓN

| Vista | Propósito | Uso principal | Estado |
|-------|-----------|---------------|--------|
| `ticket_folio_complete` | Completar información de folios | Impresión de tickets | INTEGRACIÓN |
| `vw_ticket_base` | Vista base de tickets | Análisis de ventas | REPORTES |

**NOTA IMPORTANTE**: Las vistas en `public` son extensiones del sistema Floreant POS desarrolladas por Terrena. No son parte del sistema original de POS, sino piezas de integración y análisis desarrolladas para la explotación de datos del POS.

---

## 9. VISTAS SIN USO DETECTADAS (5 vistas)

| Vista | Módulo | Razón Sin Uso | Acción Recomendada |
|-------|--------|---------------|-------------------|
| `v_stock_brechas` | Inventario | No se encontró referencia en código | ⚠️ Validar uso, deprecar |
| `v_merma_por_item` | Inventario | No se encontró referencia en código | ⚠️ Validar uso, deprecar |
| `v_ingenieria_menu_completa` | Reportes | No se encontró referencia en código | ⚠️ Validar uso, deprecar |
| `vw_replenishment_dashboard` | Purchasing | Módulo no implementado (0%) | ⚠️ Implementar o eliminar |
| (varias duplicadas) | Catálogos | Múltiples vistas para misma tabla | ✅ Consolidar |

---

## 10. ESTRATEGIA DE MANTENIMIENTO

### 10.1 Vistas de Reportes (Mantener)

**Acción**: Documentar completamente
**Prioridad**: ALTA
**Esfuerzo**: 12 horas

**Pendientes**:
- `vw_kardex`
- `vw_stock_por_lote_fefo`
- `vw_item_last_price`
- `vw_item_last_price_pref`
- `vw_movimientos_anomalos`
- `v_stock_actual`
- `vw_pos_map_resuelto`
- `vw_ticket_promedio_sucursal_dia`
- `vw_items_con_uom`

### 10.2 Vistas Legacy (Deprecar)

**Acción**: Plan de deprecación
**Prioridad**: MEDIA
**Esfuerzo**: 8 horas

**Estrategia**:
1. Marcar como DEPRECATED en comentarios
2. Logging de uso
3. Migrar código que las usa
4. Eliminar cuando uso = 0

**Vistas a deprecar** (11 vistas):
- `unidad_medida`, `unidades_medida`
- `uom_conversion`, `conversiones_unidad`
- `v_almacen`, `v_bodega`, `v_sucursal`
- `v_rol`, `v_usuario`
- `v_receta`, `v_receta_insumo`, `v_insumo`, `v_lote`

### 10.3 Vistas Sin Uso (Validar)

**Acción**: Validar si se necesitan
**Prioridad**: BAJA
**Esfuerzo**: 4 horas

**Vistas**:
- `v_stock_brechas`
- `v_merma_por_item`
- `v_ingenieria_menu_completa`

### 10.4 Vistas Duplicadas (Consolidar)

**Acción**: Consolidar en una sola vista
**Prioridad**: MEDIA
**Esfuerzo**: 6 horas

**Duplicados detectados**:
- `unidad_medida` vs `unidades_medida`
- `uom_conversion` vs `conversiones_unidad`
- `vw_ventas_por_hora` vs `vw_dashboard_ventas_hora`

---

## RESUMEN

### Por Estado

```
✅ Documentadas:        9 (24%)
⚠️ Sin documentar:      24 (63%)
❌ Sin uso:             5 (13%)
```

### Por Tipo

```
Reportes activos:       27 (71%)
Compatibilidad legacy:  11 (29%)
```

### Por Módulo

| Módulo | Vistas | Estado |
|--------|--------|--------|
| Reportes/Dashboard | 9 | ✅ EXCELENTE |
| Inventario | 7 | ⚠️ PARCIAL |
| Catálogos (legacy) | 11 | ⚠️ DEPRECAR |
| Recetas/Producción | 5 | ⚠️ PARCIAL |
| POS | 2 | ⚠️ PARCIAL |
| Purchasing | 2 | ⚠️ PARCIAL |
| Ventas | 2 | ✅ BIEN |

### Esfuerzo Total

**Para alcanzar 95% documentación vistas**: ~30 horas

- Documentar vistas activas: 12h
- Plan deprecación legacy: 8h
- Validar vistas sin uso: 4h
- Consolidar duplicadas: 6h

---

**Última actualización**: 14 Noviembre 2025
**Autor**: Claude Code (MAESTRO)