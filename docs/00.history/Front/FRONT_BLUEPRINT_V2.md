# FRONT BLUEPRINT V2

## 1. CONTROL DE ACCESO VISUAL BASADO EN PERMISOS (NO EN ROLES)

| Módulo / Pantalla | Ruta web | Componente Livewire / Vista | Permiso requerido (sidebar / acceso) | Comportamiento sin permiso |
| --- | --- | --- | --- | --- |
| Dashboard operativo | /dashboard | dashboard.blade.php | Sidebar: autenticado<br>Acceso: autenticado | Redirigir a /login si no está autenticado. |
| Landing Inventario | /inventario | inventario.blade.php | Sidebar: `can_manage_purchasing` o `inventory.view`<br>Acceso: mismo permiso | Ocultar módulo y redirigir a /dashboard. |
| Recepciones de Inventario | /inventory/receptions | Inventory\ReceptionsIndex | Sidebar: `can_manage_purchasing`<br>Acceso: `can_manage_purchasing` | Ocultar del sidebar y devolver 403 en acceso directo. |
| Captura de Recepción | /inventory/receptions/new | Inventory\ReceptionCreate | Sidebar: `can_manage_purchasing`<br>Acceso: `can_manage_purchasing` | Mostrar 403 y deshabilitar accesos desde la lista. |
| Detalle de Recepción | /inventory/receptions/{id}/detail | Inventory\ReceptionDetail | Sidebar: `can_manage_purchasing`<br>Acceso: `can_manage_purchasing`; permitir modo sólo lectura si sólo tiene `inventory.receptions.validate` | Cuando no tenga permisos, renderizar tarjeta “Sin autorización” y evitar llamadas write. |
| Items y Movimientos Manuales | /inventory/items | Inventory\ItemsManage | Sidebar: `can_manage_purchasing` o `inventory.items.manage`<br>Acceso: `inventory.items.manage` | Ocultar del menú; si entra por URL, devolver 403. |
| Lotes por SKU | /inventory/lots | Inventory\LotsIndex | Sidebar: `can_manage_purchasing`<br>Acceso: `inventory.lots.view` (existe como `inventory.lots.view`/`inventory.lots.view`? usar `inventory.lots.view` si se gana; fallback: `can_manage_purchasing`) | Ocultar módulo; fallback mostrar mensaje “Solicita acceso a inventario”. |
| Alertas de Inventario | /inventory/alerts | Inventory\AlertsList | Sidebar: `alerts.view`<br>Acceso: `alerts.view` | Mantener tarjeta “No tienes permisos para ver alertas” en lugar de la lista. |
| Conteos – listado | /inventory/counts | InventoryCount\Index | Sidebar: `inventory.counts.manage` o `can_manage_purchasing`<br>Acceso: `inventory.counts.manage` | Ocultar módulo; si intenta acceder, 403. |
| Conteo – creación | /inventory/counts/create | InventoryCount\Create | Sidebar: `inventory.counts.manage`<br>Acceso: `inventory.counts.manage` | Deshabilitar botón “Nuevo conteo” y responder 403 en URL directa. |
| Conteo – captura | /inventory/counts/{id}/capture | InventoryCount\Capture | Sidebar: `inventory.counts.manage`<br>Acceso: `inventory.counts.manage` | Mostrar banner “No autorizado” y evitar guardar. |
| Conteo – revisión | /inventory/counts/{id}/review | InventoryCount\Review | Sidebar: `inventory.counts.manage`<br>Acceso: `inventory.counts.manage` | Mostrar información sólo lectura; impedir acciones correctivas. |
| Conteo – detalle histórico | /inventory/counts/{id}/detail | InventoryCount\Detail | Sidebar: `inventory.counts.manage`<br>Acceso: `inventory.counts.manage` o `inventory.counts.view` si se agrega | Renderizar tarjeta de acceso restringido en lugar de detalle. |
| Landing Compras | /compras | compras.blade.php | Sidebar: `can_manage_purchasing` o `purchasing.view`<br>Acceso: `purchasing.view` | Ocultar sección; redirigir a /dashboard. |
| Replenishment Dashboard | /purchasing/replenishment | Replenishment\Dashboard | Sidebar: `can_manage_purchasing`<br>Acceso: `can_manage_purchasing` | Ocultar menú y devolver 403 si accede directo. |
| Solicitudes de Compra – listado | /purchasing/requests | Purchasing\Requests\Index | Sidebar: `purchasing.manage` o `can_manage_purchasing`<br>Acceso: `purchasing.manage` | Ocultar módulo y mostrar 403. |
| Solicitud de Compra – creación | /purchasing/requests/create | Purchasing\Requests\Create | Sidebar: `purchasing.manage`<br>Acceso: `purchasing.manage` | Deshabilitar botón “Nueva solicitud”; 403 en acceso directo. |
| Solicitud de Compra – detalle | /purchasing/requests/{id}/detail | Purchasing\Requests\Detail | Sidebar: `purchasing.manage`<br>Acceso: `purchasing.manage` | Renderizar ficha read-only si sólo tiene `purchasing.view`; caso contrario, 403. |
| Órdenes de Compra – listado | /purchasing/orders | Purchasing\Orders\Index | Sidebar: `purchasing.manage`<br>Acceso: `purchasing.manage` | Ocultar módulo y devolver 403. |
| Órdenes de Compra – detalle | /purchasing/orders/{id}/detail | Purchasing\Orders\Detail | Sidebar: `purchasing.manage`<br>Acceso: `purchasing.manage` | Mostrar sólo lectura si tiene `purchasing.view`; si no, 403. |
| Transferencias – listado | /transfers | Transfers\Index | Sidebar: `inventory.transfers.approve` (o `can_manage_purchasing` si se desea más amplio)<br>Acceso: `inventory.transfers.approve` | Ocultar menú; 403 en acceso directo. |
| Transferencia nueva | /transfers/create | Transfers\Create | Sidebar: `inventory.transfers.approve`<br>Acceso: `inventory.transfers.approve` | Deshabilitar CTA y devolver 403. |
| Transferencia – detalle | /transfers/{id}/detail | Inventory\TransferDetail | Sidebar: `inventory.transfers.approve`<br>Acceso: editar con `inventory.transfers.approve`; sólo lectura con `inventory.transfers.view` | Mostrar mensaje “Sólo lectura” si carece de permiso de aprobación. |
| Landing Producción | /produccion | produccion.blade.php | Sidebar: `can_edit_production_order` o `production.manage`<br>Acceso: `can_edit_production_order` | Mostrar vista informativa sin acciones; redirigir a /dashboard si no tiene ningún permiso. |
| Recepciones POS / Auditoría Recetas (dashboard futuro) | /pos/dashboard (propuesto) | Livewire\Pos\Dashboard (propuesto) | Sidebar: `can_view_recipe_dashboard`<br>Acceso: `can_view_recipe_dashboard`; acciones requieren `can_reprocess_sales` | Ocultar botones críticos y mostrar banner “Contacta a gerente” si falta permiso de reproceso. |
| Reproceso POS – acciones | (botones sobre dashboard) | (acciones Livewire dentro de dashboard) | Sidebar: agrupado en POS<br>Acceso acción: `can_reprocess_sales` | Deshabilitar botones y mostrar tooltip “No autorizado”. |
| Recetas – listado | /recipes | Recipes\RecipesIndex | Sidebar: `can_view_recipe_dashboard`<br>Acceso: `can_view_recipe_dashboard` | Ocultar módulo; redirigir a /dashboard. |
| Receta – editor | /recipes/editor/{id?} | Recipes\RecipeEditor | Sidebar: `can_view_recipe_dashboard`; edición: `can_modify_recipe`<br>Acceso: `can_view_recipe_dashboard` (read-only) / `can_modify_recipe` (edit) | Mostrar view-only (inputs disabled) si sólo tiene `can_view_recipe_dashboard`. |
| Catalogos – índice | /catalogos | catalogos-index.blade.php | Sidebar: `can_manage_purchasing` o `inventory.items.manage`<br>Acceso: mismo permiso | Ocultar módulo y redirigir a /dashboard. |
| Catálogo de Unidades | /catalogos/unidades | Catalogs\UnidadesIndex | Sidebar: `inventory.items.manage`<br>Acceso: `inventory.items.manage` | Mostrar mensaje “Solicita acceso a catálogos” y bloquear acciones. |
| Catálogo de Conversiones | /catalogos/uom | Catalogs\UomConversionIndex | Sidebar: `inventory.items.manage`<br>Acceso: `inventory.items.manage` | Ocultar ruta y devolver 403. |
| Catálogos de Almacenes / Sucursales / Proveedores | /catalogos/* | Catalogs\AlmacenesIndex etc. | Sidebar: `can_manage_purchasing`<br>Acceso: `can_manage_purchasing` | Ocultar del sidebar y devolver 403. |
| Landing Compras vs Inventario (blades estáticos) | /compras, /inventario | compras.blade.php, inventario.blade.php | Sidebar: mismos permisos de los submódulos<br>Acceso: `can_manage_purchasing` | Ocultar accesos directos y mostrar 403. |
| Caja Chica – panel general | /cashfund | CashFund\Index | Sidebar: `cashfund.manage` (propuesto) o `cashfund.view` si se agrega para lectura<br>Acceso: `cashfund.manage` | Ocultar módulo; devolver 403. |
| Caja Chica – apertura | /cashfund/open | CashFund\Open | Sidebar: `cashfund.manage`<br>Acceso: `cashfund.manage` | Deshabilitar botón “Abrir fondo”; 403. |
| Caja Chica – movimientos | /cashfund/{id}/movements | CashFund\Movements | Sidebar: `cashfund.manage`<br>Acceso: `cashfund.manage` | Mostrar lista read-only si sólo tiene `cashfund.view`; caso contrario 403. |
| Caja Chica – arqueo | /cashfund/{id}/arqueo | CashFund\Arqueo | Sidebar: `cashfund.manage`<br>Acceso: `cashfund.manage` | Forzar 403 y ocultar CTA “Iniciar arqueo”. |
| Caja Chica – detalle | /cashfund/{id}/detail | CashFund\Detail | Sidebar: `cashfund.manage`<br>Acceso: `cashfund.manage` | Mostrar mensaje de acceso restringido. |
| Caja Chica – aprobaciones | /cashfund/approvals | CashFund\Approvals | Sidebar: `cashfund.manage`; si se mantiene middleware `approve-cash-funds`, respetarlo para acciones<br>Acceso: `cashfund.manage` (y `approve-cash-funds` para aprobar) | Ocultar pestaña; mostrar banner “No autorizado”. |
| KDS Cocina | /kds | Kds\Board | Sidebar: `kitchen.view_kds` (propuesto)<br>Acceso: `kitchen.view_kds` | Ocultar módulo y redirigir a /dashboard. |
| Landing POS cortes (legacy) | /caja/cortes | Controlador Api\Caja\CajaController@index | Sidebar: `can_manage_cash_register` (propuesto) o permiso legacy actual | Si falta permiso, redirigir con 403. |
| Reportes / KPIs | /reportes | placeholder.blade.php (reportes) | Sidebar: `reports.view` (propuesto)<br>Acceso: `reports.view` | Ocultar menú; mostrar “Solicita acceso a reportes” si llega por URL. |
| Personal / Usuarios | /personal | People\UsersIndex | Sidebar: `people.users.manage`<br>Acceso: `people.users.manage` | Ocultar módulo y devolver 403. |
| Perfil de usuario | /profile | ProfileController@index | Sidebar: siempre visible<br>Acceso: autenticado | Redirigir a /login si no está autenticado. |
| Configuración / Admin | /admin | placeholder.blade.php | Sidebar: `admin.access`<br>Acceso: `admin.access` | Ocultar opción y devolver 403. |
| Auditoría Operacional (futuro) | /audit-log (propuesto) | Audit\LogViewer (propuesto) | Sidebar: `audit.view` (propuesto)<br>Acceso: `audit.view` | Ocultar módulo y redirigir a /dashboard. |

En esta arquitectura el acceso visual es dinámico y depende de permisos efectivos del usuario autenticado (Spatie Permission en selemti.permissions). Los roles (Super Admin, inventario.manager, kitchen, etc.) son sólo agrupadores convenientes. Operativamente podemos reasignar permisos temporales: por ejemplo, si el gerente falta, un cajero puede recibir can_manage_purchasing y de inmediato verá las pantallas de recepción y podrá postear inventario. Por eso el frontend NUNCA debe basarse en el “rol de nómina”, sólo en user->can(...).

## 2. MAPA FRONT ↔ API (LIVEWIRE VS ENDPOINTS)

### Inventory\ReceptionsIndex / `/inventory/receptions`
- **Endpoints**: (planificado) `GET /api/purchasing/receptions` (pendiente); `GET /api/purchasing/receptions/{id}` para cargar detalle resumido.
- **Acciones/PERMISOS**:
  - Listado: requiere `can_manage_purchasing`.
  - Acciones de fila invocan:
    - `POST /api/purchasing/receptions/{id}/validate` → valida tolerancias (`can_manage_purchasing`).
    - `POST /api/purchasing/receptions/{id}/approve` → firma fuera de tolerancia (`can_manage_purchasing`).
    - `POST /api/purchasing/receptions/{id}/post` → postea a inventario (`can_manage_purchasing`).
- **Notas UI**: 403 debe mostrar toast “Sin permiso para recepción” y mantener la tabla en lectura.

### Inventory\ReceptionCreate / `/inventory/receptions/new`
- **Endpoints**:
  - `POST /api/purchasing/receptions/create-from-po/{purchase_order_id}`
  - `POST /api/purchasing/receptions/{id}/lines`
- **Permisos**: `can_manage_purchasing`.
- **UI**: Validar 422 de backend (líneas). 403 → cerrar modal y mostrar alerta roja.

### Inventory\ReceptionDetail / `/inventory/receptions/{id}/detail`
- **Endpoints**:
  - `GET /api/purchasing/receptions/{id}` (detalle).
  - `POST /api/purchasing/receptions/{id}/costing` (costeo final).
- **Permisos**: `can_manage_purchasing`; costeo final usa mismo permiso.
- **UI**: Si la API responde 403, renderizar vista sólo lectura con nota “Sin permiso de operación”.

### Inventory\ItemsManage / `/inventory/items`
- **Endpoints**:
  - `GET /api/inventory/items`
  - `POST /api/inventory/items`, `PUT /api/inventory/items/{id}`, `DELETE /api/inventory/items/{id}`
  - `GET /api/inventory/items/{id}/batches`, `/kardex`, `/vendors`
- **Permisos**: backend protege todo con `can_manage_purchasing`; operaciones específicas usan `inventory.items.manage`.
- **UI**: Habilitar acciones sólo cuando user->can('inventory.items.manage'); 403 → toast y revertir cambios en tabla.

### Inventory\LotsIndex / `/inventory/lots`
- **Endpoints**: `GET /api/inventory/items/{id}/batches` (filtrado por SKU).
- **Permisos**: `can_manage_purchasing`.
- **UI**: 403 → tarjeta “Necesitas permiso de inventario”.

### Inventory\AlertsList / `/inventory/alerts`
- **Endpoints**: `GET /api/alerts`, `POST /api/alerts/{id}/ack`.
- **Permisos**: `alerts.view`.
- **UI**: ocultar botón “Acknowledge” si no tiene `alerts.view`; 403 en ack → toast “No autorizado, la alerta sigue pendiente”.

### InventoryCount componentes (`Index`, `Create`, `Capture`, `Review`, `Detail`)
- **Endpoints**: por definir (se recomienda namespace `/api/inventory/counts`). Registrar TODO para crear endpoints compatibles.
- **Permisos**: `inventory.counts.manage`.
- **UI**: hasta que existan endpoints, mock local; todos los POST deben enviar `motivo` y manejar 403 con notificación.

### Transfers\Index / `/transfers`
- **Endpoints**:
  - `GET /api/inventory/transfers/{id}` (para la tarjeta lateral).
  - `POST /api/inventory/transfers/create`
- **Permisos**: `can_manage_purchasing` + `inventory.transfers.approve`.
- **UI**: filtrar botones según user->can('inventory.transfers.approve'); 403 → toast y mantener en listado.

### Transfers\Create / `/transfers/create`
- **Endpoints**: `POST /api/inventory/transfers/create`.
- **Permisos**: `inventory.transfers.approve`.
- **UI**: wire:loading para botón Guardar; 403 → modal “Necesitas permiso de transferencias”.

### Inventory\TransferDetail / `/transfers/{id}/detail`
- **Endpoints**:
  - `GET /api/inventory/transfers/{id}`
  - `POST /api/inventory/transfers/{id}/ship`
  - `POST /api/inventory/transfers/{id}/receive`
  - `POST /api/inventory/transfers/{id}/post`
- **Permisos**: `inventory.transfers.ship`, `.receive`, `.post` (todos detrás de `can_manage_purchasing`).
- **UI**: mostrar botones según permiso; 403 → toast y no cerrar diálogo.

### Purchasing\Requests components
- **Endpoints**: aún no existen en `routes/api.php` (TODO para Sprint posterior).
- **Permisos**: `purchasing.manage`.
- **UI**: mantener mocks y mostrar advertencia “API en construcción” si la llamada falla con 404.

### Purchasing\Orders components
- **Endpoints**: pendientes; se recomienda `/api/purchasing/orders`.
- **Permisos**: `purchasing.manage`.
- **UI**: idem requests.

### Replenishment\Dashboard / `/purchasing/replenishment`
- **Endpoints**: usar `GET /api/purchasing/suggestions`, `POST /api/purchasing/suggestions/{id}/approve`, `/convert`.
- **Permisos**: `can_manage_purchasing`.
- **UI**: 403 → ocultar botones Aprobar/Convertir y mostrar mensaje informativo.

### Recipes\RecipesIndex / `/recipes`
- **Endpoints**: `GET /api/recipes/{id}/cost` (lista de tarjetas), `GET /api/pos/dashboard/missing-recipes` (diagnósticos).
- **Permisos**: `can_view_recipe_dashboard`.
- **UI**: bloquear cards si user no tiene permiso; 403 → toast.

### Recipes\RecipeEditor / `/recipes/editor/{id?}`
- **Endpoints**:
  - `GET /api/recipes/{id}/cost`
  - `POST /api/recipes/{recipeId}/recalculate`
- **Permisos**: `can_view_recipe_dashboard` (leer), `can_modify_recipe` (editar guardar).
- **UI**: sin `can_modify_recipe`, inputs disabled y mostrar banner amarillo “Modo lectura”.

### CashFund componentes (`Index`, `Open`, `Movements`, `Arqueo`, `Detail`, `Approvals`)
- **Endpoints**: por definir en `/api/cashfund/...` (aún no existen).
- **Permisos**: propuesto `cashfund.manage`; aprobaciones adicionales pueden requerir `approve-cash-funds`.
- **UI**: mostrar modales solicitando motivo/evidencia; 403 → toast y revertir formulario.

### Kds\Board / `/kds`
- **Endpoints**: feed en tiempo real (websocket / polling). Preparar endpoint `GET /api/kds/orders` (TODO).
- **Permisos**: `kitchen.view_kds`.
- **UI**: si 403, mostrar pantalla “No tienes acceso al KDS”.

### Catalogs componentes
- **Endpoints**: `GET /api/catalogs/unidades`, `/uom`, `/almacenes`, `/sucursales`, `/movement-types`.
- **Permisos**: `can_manage_purchasing`.
- **UI**: 403 → mensaje informativo y esconder formularios.

### People\UsersIndex / `/personal`
- **Endpoints**: (pendiente) `/api/people/users`, `/api/people/roles`.
- **Permisos**: `people.users.manage`.
- **UI**: 403 → modal “Acceso restringido”.

### POS diagnostics & reprocess (pantalla Livewire pendiente)
- **Endpoints**:
  - `GET /api/pos/tickets/{ticketId}/diagnostics`
  - `GET /api/pos/dashboard/missing-recipes`
  - `POST /api/pos/tickets/{ticketId}/reprocess`
  - `POST /api/pos/tickets/{ticketId}/reverse`
- **Permisos**: `can_view_recipe_dashboard` (leer), `can_reprocess_sales` (acciones).
- **UI**: ocultar botones de acción si falta `can_reprocess_sales`; toast en 403.

### Reportes / `/reportes`
- **Endpoints**: `/api/reports/...` (kpis, ventas, stock, anomalías). Todas protegidas con `can_view_recipe_dashboard`; algunas añaden `can_manage_purchasing`.
- **Permisos**: propuesto `reports.view` + back exige `can_view_recipe_dashboard`.
- **UI**: fallback a tarjeta “Solicita acceso a reportes”; 403 → toast.

### Auditoría Operacional (futuro Audit\LogViewer)
- **Endpoints**: propuesto `GET /api/audit-log` con filtros, protegido por `audit.view`.
- **Permisos**: `audit.view`.
- **UI**: si 403, redirigir a /dashboard y registrar intento.

## 3. LAYOUT BASE Y COMPONENTES COMPARTIDOS

- **layouts/app.blade.php** será el layout autenticado estándar.
  - **Header / Topbar**: muestra usuario logueado, sucursal/terminal activa y badges de alertas (visible sólo si user->can('alerts.view')).
  - **Sidebar dinámico**: genera secciones leyendo `user()->can(...)`:
    - “Inventario” visible con `can_manage_purchasing` o `inventory.view`.
    - “Compras / Reposición” con `can_manage_purchasing` o `purchasing.view`.
    - “POS / Auditoría Recetas” con `can_view_recipe_dashboard`.
    - “Reproceso POS” (acciones críticas) sólo con `can_reprocess_sales`.
    - “Producción” con `can_edit_production_order`.
    - “Recetas” con `can_view_recipe_dashboard`.
    - “Caja Chica” con `cashfund.manage`.
    - “KDS” con `kitchen.view_kds`.
    - “Reportes” con `reports.view`.
    - “Auditoría” con `audit.view`.
  - **Contenido principal**: slot para componentes Livewire por ruta.
  - **Footer**: opcional, reutilizable para build-info.

- **Componentes compartidos**:
  - `<livewire:shared.alert-banner />`: muestra alertas de inventario/POS; sólo renderiza si user->can('alerts.view').
  - `<livewire:shared.sidebar />` (o `<x-sidebar />` blade): construye menú basado en `/api/me/permissions` (token Sanctum).
  - `<x-confirm-modal />`: modal reutilizable (Blade + Alpine) que solicita `motivo` y `evidencia_url` (opcional) antes de acciones críticas (postear recepción, ship/receive/post transfer, reprocesar ticket, postear batch). Debe integrarse con la política de auditoría.
  - Patrones Livewire estándar: `wire:loading` / `wire:target` en botones, toasts consistentes para 200/422/403.
  - Gestión de `403` desde backend: toast “No autorizado para esta acción” + mantener la UI estable (sin recargar).

Esta capa común unifica experiencia entre Inventario, Compras, Producción, Auditoría POS, KDS, Caja Chica, Reportes y Auditoría Operacional futura.

## 4. MÓDULOS OPERATIVOS CLAVE

- **KDS Cocina (`/kds`, Livewire\Kds\Board)**  
  Propósito: tablero tiempo real de órdenes en cocina, reflejando agotados y reroutes desde MenuAvailabilityService.  
  Permiso propuesto: `kitchen.view_kds`. La UI debe ocultarse para sucursales sin KDS y usuarios sin permiso.

- **Caja Chica / Cash Fund (`/cashfund/*`, Livewire\CashFund\*)**  
  Acciones: apertura de fondo, movimientos en turno, arqueo y aprobaciones.  
  Permiso propuesto: `cashfund.manage` (además de `approve-cash-funds` para flows de aprobación si se requiere granularidad). El sidebar debe reaccionar cuando se delega temporalmente el permiso a otro usuario (ej. cajero supliendo al gerente).

- **Auditoría POS / Reproceso de Tickets (endpoints `/api/pos/...`)**  
  Pantallas que consumen `PosConsumptionController`: diagnósticos, dashboard de recetas pendientes, reproceso y reversa.  
  Permisos: `can_view_recipe_dashboard` para visualizar; `can_reprocess_sales` para botones de reproceso/reversa. La UI debe mostrar botones deshabilitados con tooltip si el permiso de acción falta.

- **Producción Interna / Batches (`/produccion`)**  
  Propósito: planear, consumir y postear producción (subrecetas, mermas).  
  Permiso requerido: `can_edit_production_order`. Esta pantalla alimenta la disponibilidad para POS, por lo que debe exigir motivo/evidencia en cada posteo.

- **Reportes / KPIs (`/reportes` + `/api/reports/...`)**  
  Incluye KPIs de sucursal/terminal, ventas, costo teórico vs real, anomalías.  
  Permiso propuesto: `reports.view` (además de `can_view_recipe_dashboard` para compatibilidad con backend actual). Información sensible, sólo dirección/gerencia deben verla.

- **Auditoría Operacional / Historial Crítico (futuro `/audit-log`)**  
  Datastore: `selemti.audit_log` rellenada por `AuditLogService`.  
  Permiso propuesto: `audit.view`. Debe listar quién autorizó recepciones, quién marcó transferencias como enviadas/recibidas, quién reprocesó POS, incluyendo motivo y evidencia.

Filosofía operativa: El sistema NO ata pantallas a un puesto fijo (“gerente”, “cajero”). Ata pantallas a permisos. Eso nos permite operar aun cuando falta alguien: si el gerente no está, se le puede dar temporalmente cashfund.manage o can_manage_purchasing a otro usuario y la UI debe reaccionar en caliente (sidebar cambia, botones se habilitan). Esta flexibilidad es un requisito de negocio, no un nice-to-have.

## 5. CIERRE

Blueprint Front V2 completado. Listo para iniciar Sprint Front 1.0 (sidebar dinámico por permisos, guard visual de pantallas, cableado Livewire ↔ API con token Sanctum, y trazabilidad visible vía auditoría).
