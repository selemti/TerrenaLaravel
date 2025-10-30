# Wireflows · Inventario + POS + Recetas (alineado a docs existentes)

> Basado en: **POS_REPROCESSING.md** (reproceso y tipos de movimiento) y **POS_CONSUMPTION_SERVICE.md** (política de integración, banderas), además del **README (Módulo Recetas)** para mapeo POS↔Recetas y modificadores.

## 0. Convenciones UX
- Una sola pantalla de **Inventarios** con pestañas: *Dashboard*, *Consumo POS*, *Reproceso*, *Conteos*, *Snapshots*, *Kardex*.
- Acciones secundarias en **modales**: *Alta/edición de Item*, *Mapeo POS→Receta*, *Asociación de Modificadores*, *Detalle de Ticket*.
- **Datatables** con filtros persistentes por Sucursal, Fecha, Estado (semáforos).
- **Wizard** solo donde reduce errores (Reproceso guiado y Conteo Físico).
- **Atajos**: `g` (go-to) para cambiar de sucursal/fecha, `r` para recargar, `m` para abrir mapeo rápido.

---

## 1) Dashboard de Salud (Inventario)
**Objetivo:** Semáforos del día y accesos rápidos a colas de trabajo.

**Cards** (kpi + acción):
- *Unmapped menu items* → lista (ir a Mapeo).  
- *Líneas pendientes de procesar* (`requiere_reproceso`/`procesado=false`) → ir a Reproceso.  
- *Conteos abiertos* → ir a Conteos.  
- *Items con stock teórico negativo* → ir a Kardex.  
- *Cobertura Snapshot* → ir a Snapshots.

**Tabla resumen por grupo:**
- Grupo, Pendientes, Última acción, Responsable, CTA.

**Eventos/Logs:** `warning.unmapped.menu_items`, `warning.negative.stock`, `inventory.count.open`.

---

## 2) Consumo POS (Monitor de Confirmación)
**Grid maestro**: Tickets del día (public.*) con estado derivado en selemti.*  
**Detalle deslizable**: líneas y modificadores.

**Columnas clave:**
- Ticket, Hora, Sucursal, Items, Modificadores, Estado (expandido/confirmado), Flags (`requiere_reproceso`, `procesado`).

**Acciones fila:**
- *Ver detalle expandido* (modal).  
- *Confirmar* (si aplica).  
- *Abrir Kardex del item* (nueva pestaña).

**Eventos:** `pos.consumption.expand.*`, `pos.consumption.confirm.*`.

---

## 3) Reproceso (Wizard 3 pasos)
**Paso 1: Detectar**  
- Lista de líneas con `requiere_reproceso=true` (selemti.inv_consumo_pos/_det).  
- Filtro por `menu_item` y por disponibilidad de mapeo actual.

**Paso 2: Mapear/Validar**  
- Modal *Mapeo POS→Receta* (rápido): seleccionar `recipe_id` y (si aplica) `receta_modificador_id` para modificadores.  
- Validación de stock negativo potencial (pre-cálculo).

**Paso 3: Ejecutar/Revertir**  
- Botón *Reprocesar*.  
- Registro de movimientos con tipo `AJUSTE_REPROCESO_POS`.  
- Opción de *Reverso* sobre último lote generado (`AJUSTE_REVERSO`).

**Eventos:** `pos.reprocess.detected`, `pos.reprocess.executed`.

---

## 4) Mapear POS → Recetas y Modificadores (Modal único)
**Búsqueda** por nombre POS, categoría, recientemente vendidos.  
**Formulario**:
- `menu_item_id` → `recipe_id` (Receta Base).  
- Grupo de **modificadores** (cada opción → `receta_modificador_id` de subreceta).  
- Switch **activo**.

**Validaciones**: receta publicada vigente, subreceta disponible, costo actualizado.

**Evento:** `warning.unmapped.menu_items` (se cierra al mapear).

---

## 5) Snapshots (Reporte y forzar UPSERT)
**Lista** por fecha/sucursal: `items_snapshotted`, faltantes y costo unitario efectivo.  
**Acciones**: *Forzar UPSERT para faltantes*, *Exportar CSV*.

**Evento:** `inventory.snapshot.generated`.

---

## 6) Conteos Físicos (Wizard)
**Paso 1:** Crear Conteo (áreas, responsables, método).  
**Paso 2:** Captura asistida (teclado/lector, tolerancias, autocomplete por código).  
**Paso 3:** Cierre y Posteo (genera ajuste mov_inv si aplica).

**Eventos:** `inventory.count.open`, `inventory.count.closed`.

---

## 7) Kardex (Detalle por Item)
- Timeline de `mov_inv` con filtros (fecha, tipo, referencia).  
- Indicadores de costo (WAC), lotes, y vínculos a recepciones/producciones/tickets.

---

## 8) Recetas/Subrecetas (Editor + Vínculo POS)
- Lista con versiones publicadas y vigencias.  
- Editor de ingredientes con merma y rendimiento.  
- Vínculo directo a PLU POS (pos_map) y a modificadores.

**Eventos:** `recipe.cost_snapshot.generated`, `recipe.cost.recalc.executed` (si se re-calcula).

---

## 9) Estados/Reglas clave (alineadas a docs)
- **No tocar `public.*`** (solo lectura).  
- Banderas en `selemti.inv_consumo_pos/_det`: `requiere_reproceso`, `procesado`, `fecha_proceso`.  
- Tipos de movimiento especiales: `AJUSTE_REPROCESO_POS`, `AJUSTE_REVERSO`, `APERTURA_INVENTARIO`.

---

## 10) Navegación
- Menú: Inventarios
  - Dashboard
  - Consumo POS
  - Reproceso
  - Conteos
  - Snapshots
  - Kardex
  - Recetas

Atajos y breadcrumbs consistentes.