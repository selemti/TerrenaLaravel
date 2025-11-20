# PERMISOS Y RESPONSABILIDADES - FASE 1: COMPRAS

**Fecha:** 2025-10-24
**Alcance:** Flujo CORE de compras (BORRADOR → APROBADA → ORDENADA → POSTEADA → CERRADA)
**Propósito:** Definir permisos granulares y UI para cada transición de estado

---

## 🔐 MODELO DE PERMISOS DINÁMICOS

### **Filosofía:**
- **NO** usar roles fijos ("Gerente", "Almacenista", "Cocina")
- **SÍ** usar permisos granulares administrables desde configuración
- Cualquier usuario puede tener cualquier combinación de permisos
- El administrador del sistema asigna/delega permisos según necesidades operativas

### **Estructura de Permisos:**
```
{módulo}.{entidad}.{acción}

Ejemplos:
- purchasing.suggestions.create
- purchasing.requests.approve
- inventory.receptions.post
- purchasing.returns.credit_note
```

### **Futuro: Integración con Labor Manager**
```
selemti.job_positions           -- Puestos (Chef, Almacenista, Gerente)
selemti.user_positions          -- Asignación usuario → puesto
selemti.organization_units      -- Estructura jerárquica (departamentos)
selemti.position_permissions    -- Permisos por puesto (template)

→ Usará selemti.users como base
→ Permitirá cálculo de costos de mano de obra
→ Labor tracking y productividad
```

---

## 📋 PERMISOS POR FUNCIONALIDAD

### **Ejemplos de Asignación Típica (Sugerida, NO Obligatoria):**

| Permiso | Típicamente asignado a | Scope |
|---------|------------------------|-------|
| `purchasing.suggestions.view` | Usuarios de compras/almacén | Puede ver solo su sucursal o global |
| `purchasing.suggestions.create` | Usuarios con gestión de almacén | Por sucursal |
| `purchasing.suggestions.approve` | Usuarios con autoridad de compras | Global |
| `purchasing.requests.approve` | Usuarios con autoridad de compras | Global |
| `purchasing.orders.send` | Usuarios con autoridad de compras | Global |
| `inventory.receptions.post` | Usuarios con permisos financieros | ⚠️ CRÍTICO: Postea a Kardex |
| `inventory.receptions.approve_diff` | Usuarios con autoridad operativa | Aprobar diferencias > tolerancia |

**Nota:** El administrador puede asignar cualquiera de estos permisos a cualquier usuario según la operación real del negocio.

---

## 📊 MATRIZ DE RESPONSABILIDADES POR ESTADO

### **FLUJO CORE: SUGERENCIAS DE COMPRA**

```
PENDIENTE → REVISADA → APROBADA → CONVERTIDA
```

| Estado Inicial | Transición | Estado Final | Permiso Requerido | Acción UI | Notas |
|----------------|------------|--------------|-------------------|-----------|-------|
| - | **Crear Sugerencia** | `PENDIENTE` | Sistema (cron) | Comando: `purchasing:generate-suggestions` | Automático |
| - | **Crear Sugerencia Manual** | `PENDIENTE` | `purchasing.suggestions.create` | Botón: "Nueva Sugerencia" | Cualquier usuario con el permiso |
| `PENDIENTE` | **Revisar** | `REVISADA` | `purchasing.suggestions.review` | Botón: "Marcar Revisada" | Valida datos antes de aprobar |
| `REVISADA` | **Aprobar** | `APROBADA` | `purchasing.suggestions.approve` | Botón: "Aprobar Sugerencia" | Autoriza la necesidad |
| `APROBADA` | **Convertir a Request** | `CONVERTIDA` | `purchasing.suggestions.convert` | Botón: "Crear Solicitud" | Genera purchase_request |
| `PENDIENTE/REVISADA` | **Rechazar** | `RECHAZADA` | `purchasing.suggestions.reject` | Botón: "Rechazar" + campo motivo | Cancela sugerencia |

**Notas:**
- Visibilidad: Usuarios con permiso `purchasing.suggestions.view` pueden ver sugerencias
  - Scope puede configurarse por sucursal o global según la asignación del permiso
- Sistema genera sugerencias automáticamente cada día (cron a las 06:00 AM)

---

### **FLUJO CORE: SOLICITUDES DE COMPRA (Purchase Requests)**

```
BORRADOR → APROBADA → ORDENADA → CERRADA
```

| Estado Inicial | Transición | Estado Final | Permiso Requerido | Acción UI | Notas |
|----------------|------------|--------------|-------------------|-----------|-------|
| - | **Crear Solicitud** | `BORRADOR` | `purchasing.requests.create` | Botón: "Nueva Solicitud" | Manual |
| - | **Convertir desde Sugerencia** | `BORRADOR` | Sistema (automático) | - | Desde sugerencia aprobada |
| `BORRADOR` | **Enviar a Aprobación** | `APROBADA` | `purchasing.requests.approve` | Botón: "Aprobar Solicitud" | Autoriza gasto |
| `APROBADA` | **Generar Orden** | `ORDENADA` | `purchasing.orders.create` | Botón: "Crear Orden de Compra" | Genera PO |
| `ORDENADA` | **Cerrar** | `CERRADA` | Sistema (automático) | - | Cuando PO se cierra |
| `BORRADOR` | **Cancelar** | `CANCELADA` | `purchasing.requests.cancel` | Botón: "Cancelar" + motivo | Cancela solicitud |

**Notas:**
- Al convertir Sugerencia → Request:
  - Se copian items, cantidades, proveedores
  - Estado inicial: `BORRADOR`
  - Usuario debe revisar antes de aprobar
- Campo `urgente = true` muestra badge rojo en lista
- `fecha_requerida` determina prioridad en cola

---

### **FLUJO CORE: ÓRDENES DE COMPRA (Purchase Orders)**

```
BORRADOR → APROBADA → EN_TRANSITO → RECIBIDA → CERRADA
```

| Estado Inicial | Transición | Estado Final | Permiso Requerido | Acción UI | Notas |
|----------------|------------|--------------|-------------------|-----------|-------|
| - | **Crear Orden** | `BORRADOR` | `purchasing.orders.create` | Generada desde Request | Automática desde request aprobada |
| `BORRADOR` | **Aprobar Orden** | `APROBADA` | `purchasing.orders.approve` | Botón: "Aprobar y Enviar" | Autoriza compra |
| `APROBADA` | **Enviar a Proveedor** | `EN_TRANSITO` | `purchasing.orders.send` | Botón: "Enviar a Proveedor" | Genera PDF/email |
| `EN_TRANSITO` | **Material Arribó** | `RECIBIDA` | `inventory.receptions.create` | Inicio de recepción física | Crea recepción |
| `RECIBIDA` | **Cerrar Orden** | `CERRADA` | Sistema (automático) | - | Cuando recepción se postea |
| `BORRADOR/APROBADA` | **Cancelar Orden** | `CANCELADA` | `purchasing.orders.cancel` | Botón: "Cancelar Orden" + motivo | Cancela PO |

**Notas:**
- Al enviar a proveedor:
  - Se genera PDF de la orden
  - Se envía email al contacto del proveedor
  - Se registra `enviado_en` timestamp
- Si hay múltiples recepciones parciales: estado se mantiene en `RECIBIDA` hasta que qty total esté completa

---

### **FLUJO CORE: RECEPCIONES (Inventory Receptions)**

```
EN_PROCESO → VALIDADA → POSTEADA_A_INVENTARIO → CERRADA
```

| Estado Inicial | Transición | Estado Final | Permiso Requerido | Acción UI | Notas |
|----------------|------------|--------------|-------------------|-----------|-------|
| - | **Iniciar Recepción** | `EN_PROCESO` | `inventory.receptions.create` | Botón: "Recibir Material" (desde PO) | Crea recepción |
| `EN_PROCESO` | **Capturar Cantidades** | `EN_PROCESO` | `inventory.receptions.edit` | Formulario: qty_recibida por item | Captura física |
| `EN_PROCESO` | **Validar** | `VALIDADA` | `inventory.receptions.validate` | Botón: "Confirmar Cantidades" | Valida datos |
| `VALIDADA` | **Postear a Inventario** | `POSTEADA_A_INVENTARIO` | **`inventory.receptions.post`** | Botón: "Postear a Kardex" ⚠️ | **CRÍTICO: Genera mov_inv INMUTABLE** |
| `POSTEADA_A_INVENTARIO` | **Cerrar Recepción** | `CERRADA` | Sistema (automático) | - | Cierre automático |

**Acciones Especiales:**
- **Si Diferencia > Tolerancia:**
  - Sistema bloquea botón "Postear a Kardex"
  - Requiere aprobación de Gerente Operaciones
  - Permiso adicional: `inventory.receptions.approve_diff`
  - Modal: "Diferencia detectada: -5% en ITEM001. ¿Aprobar de todas formas?"

**Notas:**
- ⚠️ **CRÍTICO:** Estado `POSTEADA_A_INVENTARIO` genera movimientos **INMUTABLES** en `mov_inv`
- Una vez posteada, NO se puede editar
- Correcciones se hacen con devoluciones o ajustes (nuevos movimientos)

---

### **FLUJO CORE: DEVOLUCIONES A PROVEEDOR (Purchase Returns)**

```
BORRADOR → APROBADA → EN_TRANSITO → RECIBIDA_PROVEEDOR → NOTA_CREDITO → CERRADA
```

| Estado Inicial | Transición | Estado Final | Permiso Requerido | Acción UI | Notas |
|----------------|------------|--------------|-------------------|-----------|-------|
| - | **Crear Devolución** | `BORRADOR` | `purchasing.returns.create` | Botón: "Devolver Material" (desde PO) | Crea devolución |
| `BORRADOR` | **Aprobar Devolución** | `APROBADA` | `purchasing.returns.approve` | Botón: "Aprobar Devolución" | Autoriza devolución |
| `APROBADA` | **Enviar a Proveedor** | `EN_TRANSITO` | `purchasing.returns.send` | Captura guía + transportista | Material en ruta |
| `EN_TRANSITO` | **Proveedor Recibió** | `RECIBIDA_PROVEEDOR` | `purchasing.returns.confirm` | Botón: "Confirmar Recepción Proveedor" | Confirmación |
| `RECIBIDA_PROVEEDOR` | **Postear a Inventario** | `POSTEADA_A_INVENTARIO` | **`purchasing.returns.post`** | ⚠️ Postea a Kardex | **Genera mov_inv negativo (INMUTABLE)** |
| `POSTEADA_A_INVENTARIO` | **Nota Crédito** | `NOTA_CREDITO` | `purchasing.returns.credit_note` | Captura folio NC + monto | Registro financiero |
| `NOTA_CREDITO` | **Cerrar** | `CERRADA` | `purchasing.returns.close` | Botón: "Cerrar Devolución" | Cierra ciclo |

**Notas:**
- Devoluciones generan `mov_inv` tipo `DEVOLUCION_PROVEEDOR` con qty **negativa**
- Motivos comunes: `DEFECTUOSO`, `CADUCADO`, `ERROR_PROVEEDOR`, `EXCESO`
- Tracking de guía de envío es obligatorio

---

## 🖥️ PANTALLAS Y VISTAS REQUERIDAS

### **1. Dashboard General (Todos los Roles)**
**Ruta:** `/purchasing/dashboard`
**Componente:** Livewire `PurchasingDashboard`

**Widgets:**
- Total sugerencias pendientes (badge urgente)
- Requests esperando aprobación
- Órdenes en tránsito
- Recepciones con diferencias
- Gráfico: Compras del mes

**Permisos:** `purchasing.dashboard.view`

---

### **2. Lista de Sugerencias (Encargado Almacén + Gerente Compras)**
**Ruta:** `/purchasing/suggestions`
**Componente:** Livewire `SuggestionsList`

**Filtros:**
- Estado (PENDIENTE, REVISADA, APROBADA, CONVERTIDA, RECHAZADA)
- Prioridad (URGENTE, ALTA, NORMAL, BAJA)
- Sucursal (si es gerente global)
- Fecha generación

**Columnas:**
- Folio
- Fecha
- Sucursal
- Total items
- Monto estimado
- Prioridad (badge)
- Estado (badge)
- Acciones (según rol y estado)

**Acciones por fila:**
- Ver detalle (icono ojo)
- Revisar (botón)
- Aprobar (botón)
- Convertir a Request (botón)
- Rechazar (botón)

**Permisos:** `purchasing.suggestions.index`

---

### **3. Detalle de Sugerencia**
**Ruta:** `/purchasing/suggestions/{id}`
**Componente:** Livewire `SuggestionDetail`

**Secciones:**
- Header: Folio, Estado, Prioridad, Fecha
- Items: Tabla con:
  - Item código + nombre
  - Stock actual
  - Stock mín/máx
  - Días cobertura
  - Qty sugerida (editable si estado = REVISADA)
  - Proveedor sugerido
  - Costo estimado
- Total estimado
- Notas
- Auditoría: Quién generó, quién revisó, cuándo

**Acciones:**
- Ajustar cantidades (solo si REVISADA)
- Aprobar
- Convertir a Request
- Rechazar

**Permisos:** `purchasing.suggestions.view`

---

### **4. Lista de Solicitudes (Gerente Compras)**
**Ruta:** `/purchasing/requests`
**Componente:** Livewire `PurchaseRequestsList`

**Filtros:**
- Estado (BORRADOR, APROBADA, ORDENADA, CERRADA, CANCELADA)
- Urgente (checkbox)
- Sucursal
- Fecha requerida (rango)

**Columnas:**
- Folio
- Fecha creación
- Fecha requerida (⚠️ si < 3 días)
- Sucursal
- Almacén destino
- Total items
- Importe estimado
- Urgente (badge)
- Estado
- Acciones

**Permisos:** `purchasing.requests.index`

---

### **5. Crear/Editar Solicitud**
**Ruta:** `/purchasing/requests/create` o `/purchasing/requests/{id}/edit`
**Componente:** Livewire `PurchaseRequestForm`

**Campos:**
- Sucursal (select)
- Almacén destino (select)
- Fecha requerida (date picker)
- Urgente (checkbox)
- Justificación (textarea)
- Items (tabla dinámica):
  - Buscar item (autocomplete)
  - Qty
  - UOM
  - Proveedor preferido
  - Costo estimado
  - Acciones (eliminar)
- Notas generales

**Permisos:** `purchasing.requests.create`, `purchasing.requests.edit`

---

### **6. Lista de Órdenes (Gerente Compras)**
**Ruta:** `/purchasing/orders`
**Componente:** Livewire `PurchaseOrdersList`

**Filtros:**
- Estado
- Proveedor
- Fecha creación (rango)
- Sucursal

**Columnas:**
- Folio PO
- Request origen
- Fecha
- Proveedor
- Total
- Estado
- Acciones (Aprobar, Enviar, Ver PDF, Recibir)

**Permisos:** `purchasing.orders.index`

---

### **7. Detalle de Orden + PDF**
**Ruta:** `/purchasing/orders/{id}`
**Componente:** Livewire `PurchaseOrderDetail`

**Vista imprimible (PDF):**
- Logo empresa
- Datos proveedor
- Folio PO
- Fecha emisión
- Tabla de items:
  - Código
  - Descripción
  - Qty
  - UOM
  - Precio unitario
  - Subtotal
- Subtotal
- IVA
- Total
- Condiciones de pago
- Firma autorización

**Acciones:**
- Descargar PDF
- Enviar email a proveedor
- Aprobar orden
- Cancelar

**Permisos:** `purchasing.orders.view`, `purchasing.orders.pdf`

---

### **8. Recepción de Material (Almacenista)**
**Ruta:** `/inventory/receptions/create?from_po={po_id}`
**Componente:** Livewire `ReceptionForm`

**Flujo:**
1. Escanear código de orden (o seleccionar de lista)
2. Cargar items de la orden
3. Capturar por cada item:
   - Qty ordenada (read-only)
   - Qty recibida (input)
   - Lote (input)
   - Fecha caducidad (date)
   - Rechazado (checkbox + motivo)
4. Sistema calcula diferencias automáticamente
5. Si diferencia > tolerancia: mostrar alerta
6. Botón "Confirmar Cantidades" (→ VALIDADA)

**Permisos:** `inventory.receptions.create`

---

### **9. Posteo a Inventario (Contador)**
**Ruta:** `/inventory/receptions/{id}/post`
**Componente:** Livewire `ReceptionPostForm`

**Vista:**
- Resumen de recepción
- Tabla de items con diferencias (si las hay)
- Costo total
- **Confirmación crítica:**
  - "⚠️ Esta acción generará movimientos DEFINITIVOS en Kardex"
  - "NO podrán editarse después. Solo corregir con ajustes."
  - Checkbox: "Confirmo que validé costos y cantidades"
  - Botón: "Postear a Inventario" (requiere doble confirmación)

**Al postear:**
- Crea registros en `mov_inv` tipo `COMPRA`
- Actualiza stock en vista `vw_stock_actual`
- Cambia estado recepción a `POSTEADA_A_INVENTARIO`
- Envía notificación a Gerente Operaciones

**Permisos:** `inventory.receptions.post` (rol crítico)

---

### **10. Devoluciones a Proveedor (Almacenista + Gerente)**
**Ruta:** `/purchasing/returns/create?from_po={po_id}`
**Componente:** Livewire `PurchaseReturnForm`

**Campos:**
- Orden de compra origen
- Proveedor (auto-llenado)
- Motivo general (select)
- Items a devolver (tabla):
  - Item
  - Qty ordenada
  - Qty recibida
  - Qty a devolver (input)
  - Lote
  - Motivo específico (textarea)
- Notas generales

**Permisos:** `purchasing.returns.create`

---

## 🔐 CATÁLOGO COMPLETO DE PERMISOS - FASE 1 (COMPRAS)

| Permiso | Descripción | Criticidad |
|---------|-------------|------------|
| `purchasing.dashboard.view` | Ver dashboard general de compras | Normal |
| `purchasing.suggestions.index` | Listar sugerencias de compra | Normal |
| `purchasing.suggestions.view` | Ver detalle de sugerencia | Normal |
| `purchasing.suggestions.create` | Crear sugerencia manual | Normal |
| `purchasing.suggestions.review` | Marcar sugerencia como revisada | Normal |
| `purchasing.suggestions.approve` | Aprobar sugerencia | Media |
| `purchasing.suggestions.convert` | Convertir sugerencia a request | Media |
| `purchasing.suggestions.reject` | Rechazar sugerencia | Normal |
| `purchasing.requests.index` | Listar solicitudes de compra | Normal |
| `purchasing.requests.view` | Ver detalle de solicitud | Normal |
| `purchasing.requests.create` | Crear solicitud de compra | Normal |
| `purchasing.requests.approve` | Aprobar solicitud (autoriza gasto) | Alta |
| `purchasing.requests.cancel` | Cancelar solicitud | Media |
| `purchasing.orders.index` | Listar órdenes de compra | Normal |
| `purchasing.orders.view` | Ver detalle de orden | Normal |
| `purchasing.orders.create` | Crear orden de compra | Media |
| `purchasing.orders.approve` | Aprobar orden de compra | Alta |
| `purchasing.orders.send` | Enviar orden a proveedor (email/PDF) | Media |
| `purchasing.orders.pdf` | Descargar PDF de orden | Normal |
| `purchasing.orders.cancel` | Cancelar orden de compra | Alta |
| `inventory.receptions.index` | Listar recepciones | Normal |
| `inventory.receptions.view` | Ver detalle de recepción | Normal |
| `inventory.receptions.create` | Iniciar recepción de material | Normal |
| `inventory.receptions.edit` | Capturar cantidades recibidas | Normal |
| `inventory.receptions.validate` | Confirmar cantidades | Normal |
| **`inventory.receptions.post`** | **⚠️ Postear a Kardex (genera mov_inv INMUTABLE)** | **CRÍTICO** |
| `inventory.receptions.approve_diff` | Aprobar diferencias > umbral de tolerancia | Alta |
| `purchasing.returns.index` | Listar devoluciones a proveedor | Normal |
| `purchasing.returns.view` | Ver detalle de devolución | Normal |
| `purchasing.returns.create` | Crear devolución a proveedor | Normal |
| `purchasing.returns.approve` | Aprobar devolución | Media |
| `purchasing.returns.send` | Enviar material a proveedor | Normal |
| `purchasing.returns.confirm` | Confirmar recepción por proveedor | Normal |
| **`purchasing.returns.post`** | **⚠️ Postear devolución a Kardex (mov_inv negativo)** | **CRÍTICO** |
| `purchasing.returns.credit_note` | Registrar nota de crédito | Media |
| `purchasing.returns.close` | Cerrar devolución | Normal |

**Notas sobre Criticidad:**
- **CRÍTICO:** Afecta directamente el Kardex (`mov_inv`). Movimientos inmutables. Requiere auditoría especial.
- **Alta:** Autoriza gastos o cambios importantes. Requiere aprobación de nivel superior.
- **Media:** Operaciones importantes pero reversibles.
- **Normal:** Operaciones cotidianas sin impacto financiero directo.

---

## 🔔 NOTIFICACIONES Y ALERTAS

| Evento | Destinatarios (Permisos) | Canal | Mensaje |
|--------|--------------------------|-------|---------|
| Sugerencia generada con prioridad URGENTE | Usuarios con `purchasing.suggestions.view` (scope: sucursal origen) | Email + UI | "Nueva sugerencia urgente: {folio}" |
| Sugerencia aprobada | Usuarios con `purchasing.suggestions.convert` | UI | "Sugerencia {folio} aprobada, lista para convertir" |
| Request creada con urgente=true | Usuarios con `purchasing.requests.approve` | Email | "Solicitud urgente creada: {folio}" |
| Orden aprobada | Proveedor (email) | Email + PDF | "Nueva orden de compra: {folio}" |
| Material arribado | Usuarios con `inventory.receptions.create` (scope: almacén destino) | UI | "Orden {folio} lista para recibir" |
| Recepción con diferencias > tolerancia | Usuarios con `inventory.receptions.approve_diff` | Email + UI | "Diferencia de {X}% en recepción {folio}" |
| Recepción posteada a inventario | Usuarios con `purchasing.orders.view` y `inventory.receptions.post` | UI | "Recepción {folio} posteada exitosamente" |
| Devolución creada | Usuarios con `purchasing.returns.approve` | UI | "Nueva devolución requiere aprobación: {folio}" |
| Nota de crédito recibida | Usuarios con `purchasing.returns.credit_note` | Email | "NC del proveedor {nombre}: {monto}" |

---

**FIN DEL DOCUMENTO DE ROLES OPERATIVOS - FASE 1**

**⚠️ PENDIENTE:** Agregar esta sección al documento v2.1 principal
