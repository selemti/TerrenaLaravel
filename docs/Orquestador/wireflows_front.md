
# Wireflows FRONT (Delegables a IA)

> Principios UI: todo en **una pantalla** por flujo, acciones secundarias en **modal/drawer**, teclado listo, filtros arriba, feedback inmediato (toasts), loading esquelético, autosave donde aplique.

---

## A) Hub de Inventario

### 1. Ruta
`/inventario/hub`

### 2. Header (filtros y acciones)
- Select **Sucursal** (combo async)
- Date **Fecha** (por defecto hoy / cierre)
- Select **Familia** (opcional)
- Input **Buscar** (Item/clave)
- Botones: **Conteo rápido** (abre modal), **Exportar CSV**, **Config columnas**

### 3. Tabla principal (DataTable con virtual scroll)
Columnas sugeridas:
- Item (nombre + clave + badge de unidad)
- Stock teórico
- Costo unit.
- **Valor teórico** (calc)
- Conteo (editable inline **si** hay conteo abierto)
- Variancia (qty / $) (badge rojo/amarillo/verde)
- Último mov. (tipo + hace X tiempo)
- Acciones (⋯) → Ver movimientos, Ajuste (modal), Transferir (modal)

### 4. Fila expandible (accordion)
- **Movimientos del día** (lista compacta)
- Recepciones/Transfer/Ajustes relacionados
- Mini KPI: rotación 7/30 días, Días de inventario

### 5. Modales/drawers
- **Alta/Edición de Item** (no salir de la página): nombre, unidad base (Kg/Lt/Pza), factores conversión, categoría, mínimo/máximo.
- **Ajuste de inventario**: motivo, qty, evidencia (opcional), previsualización de impacto ($).
- **Transferencia**: destino, qty, folio.
- **Conteo rápido**: escanear/teclear item, qty; teclado numérico; atajos (Enter guarda, Esc cierra).

### 6. Atajos de teclado
- ↑↓ navegar filas, **Enter** editar conteo, **Ctrl+S** guardar, **/** foco en buscar.

### 7. Estados vacíos/errores
- Sin datos → mensaje con CTA “Crear item” o “Cambiar filtros”.
- Error → toast con reintento.

### 8. API necesarias
- `GET /api/inventory/hub?branch=&date=&q=&family=`
- `POST /api/inventory/adjustments` (modal)
- `POST /api/inventory/transfers` (modal)
- `POST /api/inventory/counts/lines` (inline)
- `GET /api/inventory/items/:id/movements?date=`

---

## B) Ventas con Costo/Margen

### 1. Ruta
`/ventas/lineas`

### 2. Filtros
- Sucursal, Rango de fechas, Item POS (multi), Usuario (cajero/mesero)
- Toggle **Solo con modificadores**

### 3. Tabla
- Fecha-Hora (ticket)
- Ítem POS (con **chip de modificadores**; click = abre detalle)
- Cantidad
- Importe
- **Costo receta** (considerando subrecetas y mods)
- **Margen** y **%**
- Usuario (quién vendió), Terminal
- Acciones → Ver ticket (drawer), Ir a receta

### 4. Drawer “Detalle de línea”
- Receta aplicada (versión), lista de insumos y costos
- Modificadores con costo
- KPIs de esa línea: margen, %
- Botón “Abrir ticket completo”

### 5. Totales y export
- Totales por página y globales (en footer)
- Export CSV/Excel (respeta filtros)

### 6. API
- `GET /api/sales/lines?branch=&from=&to=&item=&user=&with_mods=`
- `GET /api/sales/lines/:id` (detalle)
- `GET /api/tickets/:id`

---

## C) Conciliación Teórico vs Físico

### 1. Ruta
`/inventario/conciliacion`

### 2. Filtros
- Sucursal, Fecha (de snapshot), Familia, Top N por **impacto $**

### 3. Tarjeta de KPIs (arriba)
- Valor Teórico total
- Variancia $ total (badge color)
- % Ítems con variancia
- Top 5 discrepancias (chips clicables)

### 4. Tabla principal
- Item
- Teórico qty / Físico qty
- Variancia qty
- **Variancia $**
- Estado (sin conteo / con conteo / pendiente investigación)
- Acción: **Abrir investigación** (modal)

### 5. Modal “Investigación”
- Causa probable (select): merma, captura, robo, surtido, etc.
- Notas, responsable, adjuntos
- Acción “Generar ajuste” (opcional) con previsualización del impacto
- Guarda “case” para auditoría

### 6. API
- `GET /api/inventory/snapshot?branch=&date=&family=&top=`
- `POST /api/inventory/investigations`
- `POST /api/inventory/adjustments`

---

## D) Navegación & Organización de menú

- **Inventarios**
  - Hub Inventario
  - Conciliación
  - Movimientos (lectura)
- **Ventas**
  - Líneas con margen
  - Tickets
- **Recetas**
  - Recetas
  - Subrecetas
- **Operación**
  - Recepciones
  - Transferencias
  - Ajustes
- **Auditoría**
  - Conteos
  - Investigaciones
  - Logs de cierre (solo lectura)

---

## E) Componentes UX transversales

- **Modales/drawers** para crear/editar sin navegar fuera.
- **Validaciones inmediatas** (+ Tooltips de error).
- **Skeleton loaders** y **toasts** de confirmación.
- **Teclas rápidas** y enfoque accesible (tabindex correcto).
- **Estados vacíos** con CTA útiles.
