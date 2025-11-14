# Compras & Replenishment (V4.0)

## 1. Alcance y fuentes

Fuente vigente para todo el flujo de abastecimiento: sugerencias → solicitudes → cotizaciones → órdenes → recepciones/devoluciones. Se alinea únicamente con el código real:

- Componentes Livewire `App\Livewire\Purchasing\Requests\{Index,Create,Detail}` y `App\Livewire\Purchasing\Orders\{Index,Detail}` con sus vistas en `resources/views/livewire/purchasing/**/*`.
- Dashboard de reposición `App\Livewire\Replenishment\Dashboard` (`resources/views/livewire/replenishment/dashboard.blade.php`).
- Servicios `App\Services\Purchasing\PurchasingService`, `App\Services\Replenishment\ReplenishmentService`, `App\Services\Purchasing\ReturnService` y `App\Services\Inventory\ReceivingService`.
- Modelos `app/Models/{PurchaseRequest,PurchaseRequestLine,VendorQuote,PurchaseOrder,PurchaseOrderLine}` y `app/Models/Purchasing/{PurchaseSuggestion,PurchaseSuggestionLine}`.
- API controllers `app/Http/Controllers/Purchasing/{PurchaseSuggestionController,ReceivingController,ReturnController}`.
- Esquema real en Postgres `selemti` (`BD/SelemTI_Estrucutra_Pedido_29_10_25_10_40_v4.sql` § purchase_* / replenishment / stock_policy). Validar contra la BD usando `DB_HOST=172.24.240.1` desde WSL.

Cualquier documento previo (`docs/Purchasing/README.md`, `docs/Replenishment/*.md`) pasa a histórico una vez que la información exista aquí.

## 2. Tablas y modelos clave

| Tabla `selemti` | Modelo / archivo | Comentarios |
|-----------------|------------------|-------------|
| `purchase_requests` + `purchase_request_lines` | `App\Models\PurchaseRequest`, `PurchaseRequestLine` | Estados BORRADOR → COTIZADA → APROBADA → ORDENADA / CANCELADA. Campos descritos en `BD/SelemTI_Estrucutra_Pedido_29_10_25_10_40_v4.sql:5815-5930`. |
| `purchase_vendor_quotes` + `_lines` | `App\Models\VendorQuote`, `VendorQuoteLine` | Cotizaciones múltiples por solicitud; `VendorQuote::ESTADO_{RECIBIDA,APROBADA,...}`. |
| `purchase_orders` + `_lines` | `App\Models\PurchaseOrder`, `PurchaseOrderLine` | Estados BORRADOR → APROBADA → ENVIADA → RECIBIDA → CERRADA / CANCELADA; relaciones con usuarios y proveedores. |
| `purchase_documents` | `App\Models\PurchaseDocument` | Adjuntos (PO firmada, recibos). No hay UI en V4.0 aún. |
| `purchase_suggestions` + `_lines` | `App\Models\Purchasing\PurchaseSuggestion`, `PurchaseSuggestionLine` | Recomendaciones calculadas (folios `PSC-YYYYMM-####`). Referenciadas desde `PurchasingService::listSuggestions/convertSuggestionToRequest`. |
| `replenishment_suggestions` | `App\Models\ReplenishmentSuggestion` | Dashboard en `/purchasing/replenishment`; estados `PENDIENTE/REVISADA/APROBADA/CONVERTIDA/RECHAZADA`. |
| `stock_policy` | `App\Models\StockPolicy` | Parámetros mínimo/máximo por item/sucursal/almacén que alimentan las sugerencias (`ReplenishmentService::generateDailySuggestions`). |
| `mov_inv`, `recepcion_*`, `inventory_batch` | Usados por `ReceivingService` y futuras devoluciones para impactar inventario. Detalle en `docs/V4.0/Inventario/Recepciones.md`. |

## 3. Flujos operativos

### 3.1 Solicitudes de compra
1. **Listado** `GET /purchasing/requests` → `App\Livewire\Purchasing\Requests\Index` (`resources/views/livewire/purchasing/requests/index.blade.php`). Filtros por folio, estado, sucursal y rango (`estadoFilter`, `sucursalFilter`, `fechaDesde/Hasta`). KPIs calculados con scopes `PurchaseRequest::borrador/aprobada/...`.
2. **Creación** `GET /purchasing/requests/create` → `Requests\Create`. El modal de ítems busca en `selemti.items` (`searchItem`) y bloquea duplicados. `crearSolicitud()` valida lineas y usa `PurchasingService::createRequest($payload)` para escribir en `selemti.purchase_requests` y `_lines`. Estado inicial = `BORRADOR`.
3. **Detalle** `GET /purchasing/requests/{id}/detail` → `Requests\Detail`. Muestra líneas, badges (`$line->estado_badge`), cotizaciones relacionadas (`$request->quotes`). Cualquier acción adicional (enviar a cotizar, aprobar) debe pasar por `PurchasingService`.

### 3.2 Cotizaciones y aprobación
- **Captura**: `PurchasingService::submitQuote($requestId, $payload)` valida cada línea contra `purchase_request_lines` (`assertRequestLineBelongsToRequest`) y escribe en `purchase_vendor_quotes`/`_lines`. Auto-actualiza la solicitud a `COTIZADA`.
- **Aprobación**: `approveQuote($quoteId, $userId)` marca la cotización como `APROBADA`, registra usuario (`aprobada_por`) y pasa la solicitud a `APROBADA`.
- **Generar orden**: `issuePurchaseOrder($quoteId, $payload)` crea cabecera `purchase_orders` y líneas, arranca en `BORRADOR` o `APROBADA` según payload, y lleva la solicitud a `ORDENADA`.
- **UI pendiente**: no existe componente Livewire para capturar cotizaciones; hoy el flujo es via servicio/API o seeders. Documentar cualquier implementación nueva aquí antes de liberar.

### 3.3 Órdenes de compra
- **Listado** `GET /purchasing/orders` → `Orders\Index` consulta `App\Models\PurchaseOrder` con filtros `search`, `estadoFilter`, `vendorFilter`. KPIs por estado (`PurchaseOrder::borrador/aprobada/...`).
- **Detalle** `GET /purchasing/orders/{id}/detail` → `Orders\Detail` (vista `resources/views/livewire/purchasing/orders/detail.blade.php`). Incluye líneas, resumen financiero y badges (`$order->estado_badge`). Columnas `fecha_promesa` e indicadores `is_vencida`/`can_enviar` (accessors en el modelo).
- **Requisitos**: antes de mover una orden a `RECIBIDA`, debe existir recepción asociada (ver 3.5). Los permisos visuales dependen de `can_manage_purchasing` en el layout; afinar con Spatie (`purchase.requests.*`, `purchase.orders.*`) al exponer acciones.

### 3.4 Replenishment y sugerencias automáticas
- **Dashboard** `GET /purchasing/replenishment` → `App\Livewire\Replenishment\Dashboard`. Usa `ReplenishmentSuggestion` + scopes (`pendiente`, `urgentes`, etc.) para KPIs y tabla (selección múltiple, aprobaciones, conversión masiva). Vista `resources/views/livewire/replenishment/dashboard.blade.php`.
- **Generación** `ReplenishmentService::generateDailySuggestions()` recorre `stock_policy` (`App\Models\StockPolicy`) para cada item/sucursal, calcula consumo promedio (`calcularConsumoPromedio`), prioridad (URGENTE/ALTA/...), folio `RPL-YYYYMM-####` y guarda en `replenishment_suggestions`. Opciones: `sucursal_id`, `almacen_id`, `dias_analisis`, `auto_aprobar`.
- **Conversión**: el dashboard llama `convertirACompra()` → `ReplenishmentService::convertToPurchaseRequest($suggestionId)` que usa internamente `PurchasingService` para crear una `purchase_request` (campo `origen_suggestion_id`). Solo aplica cuando la sugerencia `tipo=COMPRA`.
- **API**: `PurchaseSuggestionController` (`routes/api.php:329-337`) expone `/api/purchasing/suggestions` para listar/aprobar/convertir usando `PurchasingService`. Falta middleware `auth:sanctum` (ver riesgos).

### 3.5 Recepciones y devoluciones ligadas a compras
- **Recepciones desde PO**: `routes/api.php:334-343` mapea a `App\Http\Controllers\Purchasing\ReceivingController`. Métodos:
  - `createFromPO($purchase_order_id)` → `ReceivingService::createDraftReception` (estado `BORRADOR` en `recepcion_cab`).
  - `setLines`, `validateReception`, `approve`, `postReception` delegan a `ReceivingService` (ver `docs/V4.0/Inventario/Recepciones.md`). Middleware `auth:sanctum` + `permission:can_manage_purchasing` ya aplicado en el constructor, pero faltan policies por acción.
  - `finalizeCosting` y `show` siguen pendientes.
- **Devoluciones a proveedor**: `/api/purchasing/returns/*` apunta a `ReturnController` → `App\Services\Purchasing\ReturnService`. El servicio es un esqueleto (todos los métodos devuelven TODO). Antes de exponerlo, definir tablas (`purchase_returns`, `purchase_return_lines` aún no existen) y lógica de inventario (`mov_inv` negativo).

## 4. Rutas y permisos

### Web (Livewire)
| Ruta | Controlador/Componente | Notas |
|------|-----------------------|-------|
| `/purchasing/replenishment` | `App\Livewire\Replenishment\Dashboard` | Dashboard de sugerencias; requiere menú `can_manage_purchasing`. |
| `/purchasing/requests` | `Purchasing\Requests\Index` | Listado con filtros y KPIs. |
| `/purchasing/requests/create` | `Purchasing\Requests\Create` | Wizard para requisiciones. |
| `/purchasing/requests/{id}/detail` | `Purchasing\Requests\Detail` | Detalle + cotizaciones. |
| `/purchasing/orders` | `Purchasing\Orders\Index` | Vista general de órdenes. |
| `/purchasing/orders/{id}/detail` | `Purchasing\Orders\Detail` | Información completa de una OC. |

Todas las vistas extienden `layouts.terrena` y deberían usar los componentes documentados en `docs/V4.0/Frontend/Componentes.md` (cards KPI, tablas, modales).

### API (`routes/api.php:329-357`)
| Endpoint | Controlador | Estado |
|----------|-------------|--------|
| `GET /api/purchasing/suggestions` | `PurchaseSuggestionController@index` | Sin middleware → **agregar `auth:sanctum` + permisos**. |
| `POST /api/purchasing/suggestions/{id}/approve` | `PurchaseSuggestionController@approve` | Aprueba y marca usuario (`revisado_por_user_id`). |
| `POST /api/purchasing/suggestions/{id}/convert` | `PurchaseSuggestionController@convert` | Genera `purchase_request` vía servicio. |
| `POST /api/purchasing/receptions/create-from-po/{id}` | `ReceivingController@createFromPO` | Protegido por middleware, falta validar payload/permiso específico. |
| `POST /api/purchasing/receptions/{id}/{lines|validate|approve|post|costing}` | `ReceivingController` | Estados: BORRADOR → VALIDADA → POSTEADA. |
| `POST /api/purchasing/returns/{...}` | `ReturnController` | Servicio sin implementación real; no usar en producción hasta completarlo. |

## 5. Reglas y convenciones

1. **Folios**: `PurchasingService::generateFolio()` crea `PR-YYYYMM-####`, `OC-YYYYMM-####`, `REQ-YYYYMM-####`. No se capturan manualmente.
2. **Permisos**: de momento todo cuelga de `can_manage_purchasing`. Debemos registrar permisos Spatie específicos: `purchasing.requests.manage`, `purchasing.quotes.approve`, `purchasing.orders.view`, `replenishment.suggestions.review`, etc., y aplicarlos en componentes/API.
3. **Catálogos**: Items provienen de `selemti.items` (ver `docs/V4.0/Inventario/Items.md`). Sucursales/proveedores desde `selemti.cat_sucursales` y `catalogs.proveedores`.
4. **Integraciones**: Sugerencias usan `stock_policy` y `mov_inv` para consumo promedio. Antes de confiar en las cantidades, validar los datos en la BD (conexión `172.24.240.1`) y documentar cualquier vista (`v_stock_resumen`) adicional.
5. **Componentes UI**: Cards de KPIs y tablas deben migrarse a `<x-ui.card>`, `<x-ui.table>` según `docs/V4.0/Frontend/Componentes.md`; la vista actual usa Bootstrap directo.

## 6. Riesgos y tareas abiertas

1. **API sin auth**: `/api/purchasing/suggestions*` carece de `auth:sanctum` y policies; requiere middleware y permisos antes de exposición pública (`routes/api.php:329-337`).
2. **Cotizaciones sin UI**: no existe módulo en V4.0 para capturar/analizar quotes; todo depende de `PurchasingService`. Necesitamos componentes (Index/Detail) y registrar riesgos de seguridad cuando se haga.
3. **ReturnService incompleto**: `App\Services\Purchasing\ReturnService` es un stub; los endpoints `/api/purchasing/returns/*` no deben usarse hasta que se definan tablas y movimientos Kardex.
4. **Recepciones duplicadas**: `ReceivingService` coexiste con `ReceptionService` (inventario). Definir cuál es la fuente única y actualizar `docs/V4.0/Inventario/Recepciones.md` cuando se migre por completo.
5. **Dashboard con queries pesadas**: `Replenishment\Dashboard` carga `ReplenishmentSuggestion::with(item,sucursal)` y aplica filtros en memoria. Para ambientes con miles de sugerencias hay que mover filtros al SQL (`ReplenishmentSuggestion` scopes) y agregar índices (`estado`, `prioridad`, `sucursal_id`).
6. **Stock_policy**: `ReplenishmentService` consulta directamente `stock_policy` con `DB::connection('pgsql')`; asegurar que la tabla exista y esté poblada (migraciones todavía no viven en Laravel). Documentar cualquier script que la alimente.
7. **Validaciones pendientes en Recepciones**: `ReceivingController` tiene TODOs para motivos, evidencias y tolerancias; hasta cerrar esos puntos no se debe postear a inventario automáticamente.

## 7. Checklist al modificar el módulo

- [ ] Validaste los datos reales en `selemti` conectándote a la BD (WSL → `172.24.240.1`) antes de cambiar servicios o UI.
- [ ] Rutas web (`routes/web.php:298-309`) y API (`routes/api.php:329-357`) fueron actualizadas junto con los permisos correspondientes.
- [ ] `PurchasingService`, `ReplenishmentService` y los modelos asociados reflejan el nuevo comportamiento (folios, estados, campos).
- [ ] Cualquier ajuste UI utiliza los componentes documentados en `docs/V4.0/Frontend/{Layout,Componentes}.md`.
- [ ] Este archivo y el índice general (`docs/V4.0/README.md`) se actualizaron describiendo el alcance nuevo y los riesgos detectados.

Siguiendo estas pautas mantenemos el flujo de compras sincronizado entre documentación, código y base de datos.
