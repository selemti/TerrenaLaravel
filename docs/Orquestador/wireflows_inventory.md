
# Wireflows — Inventarios, Recetas y Cierre (alineado a TerrenaLaravel)

> Basado en tus vistas/legacy y APIs existentes. La premisa: **menos pantallas, más paneles** con modales/side-panels y datatables server-side. Atajos de teclado, escáner, y validaciones en línea.

## 1) Dashboard Inventario ("/inventario")
**Objetivo:** visión 360° y accesos rápidos.
- **Hero KPIs:** Stock teórico vs físico (día), valuación, pendientes (recepciones, transferencias, conteos).
- **Tabs / Cards (grid):**
  1. **Kardex** (server datatable): filtros por Item, almacén, rango de fechas. Acciones: exportar CSV, ver detalle en modal.
  2. **Movimientos rápidos**: botones "Recepción", "Transferencia", "Ajuste", cada uno abre **wizard** en modal.
  3. **Conteos**: crear/continuar conteo del día; estatus y discrepancias.
  4. **Cierre diario**: semáforo (POS/Consumo/Snapshot) y botón “ver log” (lee canal `daily_close`).
- **Componentes UX:**
  - Barra de búsqueda global (⌘/Ctrl+K).
  - Filtros persistentes (localStorage por usuario).
  - Skeletons + toasts de éxito/advertencia.
  - Acciones masivas (checkbox header).

## 2) Wizard Recepción (modal de 3 pasos)
**Entrada:** desde Dashboard o menú Compras → Recepciones.
- Paso 1 **Proveedor y Documento**: combo async (proveedor), factura/folio, fecha; sucursal/almacén preseleccionados por rol.
- Paso 2 **Partidas**: datatable editable (código/scan, descripción, presentación, cantidad, costo unitario, IVA). Atajos: **Enter** agrega fila, **F2** edita costo.
- Paso 3 **Revisión y Posteo**: resumen + validaciones (negativos, duplicados, costo fuera de rango histórico). **Postear** crea movimientos y actualiza WAC.
- **UX extra:** botón “Alta rápida de item” abre **side-panel** (no salir del wizard).

## 3) Wizard Transferencia (modal de 3 pasos)
- Paso 1: Origen/Destino (combo con permisos), motivo.
- Paso 2: Partidas (datatable escaneable).
- Paso 3: Confirmación + posteo (bloquea si stock insuficiente).

## 4) Ajustes rápidos (modal de 2 pasos)
- Paso 1: Selección de item (combo + scan) y motivo (merma, daño, inventario).
- Paso 2: Cantidad (+/-), evidencia opcional (foto/notas). Postea movimientos tipo AJUSTE.

## 5) Conteos de inventario (wizard en página)
- Crear/continuar conteo del día por zona/almacén.
- Modo **Lista** (pre-carga ítems frecuentes) o **Libre** (scan).
- Cierre de conteo: discrepancias y botón **Aplicar ajuste** (genera mov_inv).

## 6) Recetas y Subrecetas (unificada)
**Meta:** reemplazar legacy separada por un **editor unificado**:
- **Lista** (izquierda): recetas y subrecetas (search + filtros por categoría/estatus).
- **Editor** (derecha): formulario con:
  - Header: nombre, rendimiento (porciones), **mapa a Item POS** (combo async) y **modificadores**→subrecetas (multi-combo).
  - **Detalles**: grid editable (item/subreceta, unidad, cantidad, merma%). Arrastrar para reordenar.
  - **Costo**: panel con costo estándar y desglose por ingrediente (usa costo_promedio y vigencias).
  - **Acciones**: publicar versión, clonar receta, simular costo con precio proveedor.
- **UX:** side-panel “Alta rápida de insumo”, validaciones de ciclos (subreceta no puede referenciarse a sí misma).

## 7) Mapping POS ↔ Recetas
- **Pantalla de mapeo**: listado de Items del POS no mapeados; columna **Receta** (combo async crear/seleccionar).
- **Modificadores**: grid “Item POS → Subreceta”. Permite asignar Porción y costo adicional si aplica.
- **Botón** “Forzar consumo teórico de prueba” (sandbox) para validar mapping.

## 8) Monitoreo Cierre Diario
- **Semáforo** por sucursal y fecha (POS, Consumo, Snapshot). Botones “ver pendientes” → abre listados (tickets sin consumo, recepciones/transferencias abiertas, conteos abiertos).
- **Panel de logs** (lee canal `daily_close`): filtro por trace_id, rango.

## 9) Reproceso de Costos (01:10)
- Vista simple: fecha, sucursal, #insumos con cambio, #subrecetas/recetas recalculadas, alertas de margen. Export JSON.

## 10) UX Cross-cutting
- **Modales y side-panels** para alta/edición sin abandonar contexto (Items, Proveedores, Recetas).
- **Combos async** con *typeahead*, favoritos y “últimos usados”.
- **Atajos:** Enter/Añadir; Ctrl+S/Guardar; Alt+↑↓ mover fila.
- **Prevención de errores:** validaciones en línea; bloqueos de stock negativo; tooltips de unidad/base; factor de conversión visible.
- **Estados vacíos útiles:** CTA para importar/migrar catálogo.
- **Accesibilidad:** focus visible, navegación teclado, textos ≥ 14px.

---

## Entregables para IA (prompts de implementación)
- **Componente** `InventoryDashboard` + **Wizards** (`ReceivingWizard`, `TransferWizard`, `CountWizard`, `AdjustModal`).
- **Editor** `RecipeEditor` unificado con side-panels de alta rápida.
- **Pantalla** `PosRecipeMapping` con acciones de prueba.
- **Monitor** `DailyCloseMonitor` + lector de logs.

> Nota: reusar rutas y servicios existentes; si una acción ya existe vía API, **no** reimplementar, solo orquestar desde UI.
