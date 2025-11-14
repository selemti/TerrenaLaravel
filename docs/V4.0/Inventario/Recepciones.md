# Inventario · Recepciones y lotes (V4.0)

## 1. Alcance

Fuente de verdad para el flujo de recepción de mercancía y creación de lotes en `selemti`. Sustituye cualquier especificación dispersa en `docs/V2` o `docs/Orquestador`. Todo cambio al proceso debe actualizar este archivo antes del merge.

## 2. Tablas y catálogos

| Tabla | Campos clave | Comentarios |
|-------|--------------|-------------|
| `selemti.recepcion_cab` | `id`, `numero_recepcion`, `proveedor_id`, `sucursal_id`, `almacen_id`, `fecha_recepcion`, `estado`, `total_presentaciones`, `total_canonico`, `creado_por` | Cabecera creada por `ReceptionService`. `estado` inicial = `RECIBIDO`. |
| `selemti.recepcion_det` | `recepcion_id`, `item_id`, `inventory_batch_id`, `qty_presentacion`, `qty_canonica`, `uom_compra`, `uom_base`, `fecha_caducidad`, `temperatura_recepcion`, `precio_unit` | Detalle por línea; se enlaza con lotes. |
| `selemti.inventory_batch` | `id`, `item_id`, `lote_proveedor`, `cantidad_original`, `cantidad_actual`, `uom_base`, `caducidad`, `sucursal_id`, `almacen_id`, `meta` | Lotes resultantes; `meta` almacena `uom_purchase`, `qty_pack`, `pack_size`. |
| `selemti.mov_inv` | `tipo`, `item_id`, `inventory_batch_id`, `qty`, `uom`, `sucursal_id`, `almacen_id`, `ref_tipo`, `ref_id`, `meta` | Movimiento `tipo = RECEPCION` por cada lote. |
| Catálogos | `selemti.cat_proveedores`, `cat_sucursales`, `cat_almacenes`, `items` | Usados por el formulario. |

## 3. Flujo operativo

### 3.1 Listado de recepciones

- **Ruta:** `GET /inventory/receptions`
- **Componente:** `App\Livewire\Inventory\ReceptionsIndex`
- **Vista:** `resources/views/inventory/receptions-index.blade.php`
- **Comportamiento:** consulta `selemti.recepcion_cab` + joins opcionales a `cat_proveedores`, `cat_sucursales`, `cat_almacenes`. Muestra últimas 50 recepciones y habilita el modal de creación (`dispatch('reception-modal-toggled')`).

### 3.2 Alta / wizard de recepción

- **Ruta:** `GET /inventory/receptions/new` o modal dentro del listado.
- **Componente:** `App\Livewire\Inventory\ReceptionCreate`
- **Validaciones:** proveedor requerido, sucursal/almacén opcionales pero existentes, al menos una línea con `item_id` válido (`selemti.items`), UOM base en `{GR,ML,PZ}`, cantidades > 0, fechas válidas.
- **Acciones:** cada línea captura lote, caducidad, temperatura, evidencia (archivo). Al guardar:
  1. Normaliza cada línea (convierte item a `int`, upper UOM, guarda `doc_url` en storage `public/evidencias`).
  2. Llama `ReceptionService::createReception($header,$lines)`.
  3. Emite evento `reception-saved` para cerrar el modal o redirige al listado con flash.

### 3.3 Servicio y posteo en inventario

- **Servicio:** `App\Services\Inventory\ReceptionService`
- **Proceso interno:** dentro de una transacción:
  1. Inserta cabecera en `recepcion_cab` con número `RC-YYYYMMDD-####`.
  2. Por cada línea crea un registro en `inventory_batch` (lote), inserta `recepcion_det` y registra un movimiento `mov_inv` con `tipo = RECEPCION`.
  3. Actualiza totales de cabecera (`total_presentaciones`, `total_canonico`).
- **Estado inicial:** `estado = 'RECIBIDO'`. Aún no existe flujo de validación/aprobación en este servicio; se documenta como pendiente abajo.

### 3.4 Detalle y acciones

- **Componente:** `App\Livewire\Inventory\ReceptionDetail`
- **Estado actual:** consume endpoints mock (`/api/purchasing/receptions/{id}`) y permisos `/api/me/permissions`. Falta integrar con el servicio real y `auth`.
- **Acciones esperadas:** Validar, aprobar, postear (pendiente de implementación en API). Cualquier flujo nuevo debe registrarse aquí y en `routes/api.php`.

## 4. Rutas y endpoints

| Tipo | Ruta | Fuente |
|------|------|--------|
| Web | `GET /inventory/receptions` | `routes/web.php` (`Route::get(..., ReceptionsIndex::class)`) |
| Web | `GET /inventory/receptions/new` | `routes/web.php` |
| API (pendiente auth) | `/api/purchasing/receptions/*` | `routes/api.php` (mock controllers) |
| API vigente | `/api/caja/alertas*` (consumido por layout) | Recordatorio para permisos, no parte directa del flujo |

**Permisos UI:** Menú controlado por `can_manage_purchasing` (`layouts/terrena.blade.php`). Debemos agregar permisos específicos (`inventory.receptions.manage`, `inventory.receptions.validate`, etc.) cuando el backend los exponga.

## 5. Reglas de negocio

1. **Catálogos obligatorios**: proveedores, sucursales y almacenes deben existir y estar activos; si falta alguno, el formulario debe impedir la recepción.
2. **Lotes/FEFO**: cada línea genera un lote con `cantidad_original = cantidad_actual`. `caducidad` debe usarse para FEFO/Kardex.
3. **Movimientos**: todo lote produce un `mov_inv` `tipo=RECEPCION` apuntando a `ref_id = recepcion_id`. Esto alimenta dashboards y conteos.
4. **Temperatura y evidencia**: captura opcional, pero se guarda en lote/detalle (`temperatura_recepcion`, `meta.doc_url`).
5. **Numeración**: `RC-YYYYMMDD-####` consecutivo diario; se genera en base a recuento de cabeceras del día.

## 6. Riesgos y tareas abiertas

1. **Protecciones de API**: `/api/purchasing/receptions/*` hoy opera sin auth real (HTTP::get interno). Debe moverse a controladores reales con middleware `auth:sanctum` y policies.
2. **Permisos granulares**: falta enlazar botones de validar/aprobar/postear con permisos de Spatie; hoy sólo depende del menú `can_manage_purchasing`.
3. **Service único**: existe `ReceptionService` y `ReceivingService` (legacy). Antes de extender funcionalidades, consolidar en un solo servicio.
4. **Estados**: `ReceptionService` marca todo como `RECIBIDO`. El flujo deseado incluye `BORRADOR → VALIDADO → POSTEADO` con tolerancias. Debemos definir columnas (`estado`, `requiere_aprobacion`) y actualizar el servicio.
5. **View Detail**: `ReceptionDetail` aún usa endpoints mock. Implementar API real y manejo de errores.
6. **Integración con compras**: cuando existan órdenes de compra, este flujo debe asociar la recepción a la PO y validar cantidades. Documentar cuando esté listo.

---

## 7. Checklist al modificar el módulo

- [ ] Validaste tablas reales en BD (`selemti.recepcion_*`, `inventory_batch`, `mov_inv`) conectando a la IP correcta (WSL → `172.24.240.1`).
- [ ] Actualizaste las rutas (`routes/web.php`/`api.php`) y permisos correspondientes.
- [ ] `ReceptionService` y los componentes Livewire reflejan la lógica nueva (estados, lotes, etc.).
- [ ] Este documento fue actualizado con cualquier regla nueva (ej. tolerancias, integración con PO).
- [ ] Si tocaste UI, también actualizaste `docs/V4.0/Frontend/{Layout,Componentes}.md` según aplique.
