# Rutas y API — TerrenaLaravel
> Actualizado: Abril 2026 | 150+ endpoints API + 60+ rutas web

## API REST (`/api/*`)

Base URL: `http://localhost:8000/api`

### Auth
| Método | Ruta | Descripción | Auth |
|--------|------|------------|------|
| POST | `/api/auth/login` | Login, retorna token Sanctum | No |

---

### Caja (`/api/caja/*`) — 18 endpoints
> ⚠️ Middleware `auth:sanctum` deshabilitado — pendiente reactivar

| Método | Ruta | Descripción |
|--------|------|------------|
| GET | `/api/caja/cajas` | Lista de cajas/terminales |
| GET | `/api/caja/ticket/{id}` | Detalle de ticket Floreant |
| GET | `/api/caja/sesiones/activa` | Sesión de cajón activa |
| GET | `/api/caja/formas-pago` | Catálogo de formas de pago |
| GET | `/api/caja/conciliacion/{sesion_id}` | Datos de conciliación |
| GET | `/api/caja/precortes` | Lista de precortes |
| POST | `/api/caja/precortes` | Crear precorte |
| GET | `/api/caja/precortes/{id}` | Ver precorte |
| POST | `/api/caja/precortes/{id}` | Actualizar precorte |
| GET | `/api/caja/precortes/{id}/totales` | Totales del precorte |
| GET/POST | `/api/caja/precortes/{id}/status` | Estado del precorte |
| POST | `/api/caja/precortes/{id}/enviar` | Enviar a aprobación |
| GET | `/api/caja/sesion/{id}/totales` | Totales de sesión |
| GET | `/api/caja/postcortes/pendientes` | Postcortes pendientes |
| POST | `/api/caja/postcortes` | Crear postcorte |
| GET | `/api/caja/postcortes/{id}` | Ver postcorte |
| POST | `/api/caja/postcortes/{id}/aprobar` | Aprobar postcorte |
| POST | `/api/caja/postcortes/{id}/rechazar` | Rechazar postcorte |
| GET | `/api/caja/alertas` | Lista de alertas | 
| GET | `/api/caja/alertas/count` | Contador de alertas |
| PUT | `/api/caja/alertas/{id}/marcar-leida` | Marcar alerta leída |

---

### Inventario (`/api/inventory/*`) — 27 endpoints
> Middleware: `auth:sanctum`

| Método | Ruta | Descripción |
|--------|------|------------|
| GET | `/api/inventory/kpis` | KPIs de inventario |
| GET | `/api/inventory/stock` | Stock actual |
| GET | `/api/inventory/stock/list` | Lista detallada de stock |
| POST | `/api/inventory/movements` | Registrar movimiento manual |
| GET | `/api/inventory/items` | Lista de ítems/insumos |
| GET | `/api/inventory/items/{id}` | Detalle de ítem |
| POST | `/api/inventory/items` | Crear ítem |
| PUT | `/api/inventory/items/{id}` | Actualizar ítem |
| DELETE | `/api/inventory/items/{id}` | Desactivar ítem |
| GET | `/api/inventory/items/{id}/kardex` | Kardex de movimientos |
| GET | `/api/inventory/items/{id}/batches` | Lotes del ítem |
| GET | `/api/inventory/items/{id}/vendors` | Proveedores del ítem |
| POST | `/api/inventory/items/{id}/vendors` | Agregar proveedor |
| POST | `/api/inventory/prices` | Actualizar precios |
| GET | `/api/inventory/transfers` | Lista de transferencias |
| POST | `/api/inventory/transfers` | Crear transferencia |
| GET | `/api/inventory/transfers/{id}` | Detalle transferencia |
| POST | `/api/inventory/transfers/{id}/approve` | Aprobar |
| POST | `/api/inventory/transfers/{id}/ship` | Despachar |
| POST | `/api/inventory/transfers/{id}/receive` | Recibir |
| POST | `/api/inventory/transfers/{id}/post` | Postear a inventario |
| POST | `/api/inventory/orquestador/daily-close` | Cierre diario |
| POST | `/api/inventory/orquestador/recalcular-costos` | Recalcular WAC |
| POST | `/api/inventory/orquestador/generar-snapshot` | Snapshot de costos |

---

### Recetas (`/api/recipes/*`) — 5 endpoints

| Método | Ruta | Descripción |
|--------|------|------------|
| GET | `/api/recipes/{id}/cost` | Costo actual de receta |
| GET | `/api/recipes/{id}/bom/implode` | BOM desplegado |
| POST | `/api/recipes/{id}/cost/snapshot` | Guardar snapshot de costo |
| GET | `/api/recipes/{id}/cost/history` | Histórico de costos |
| GET | `/api/recipes/{id}/cost/compare` | Comparar versiones |

---

### Producción (`/api/production/*`) — 4 endpoints

| Método | Ruta | Descripción |
|--------|------|------------|
| POST | `/api/production/batch/plan` | Planear lote de producción |
| POST | `/api/production/batch/{id}/consume` | Consumir insumos |
| POST | `/api/production/batch/{id}/complete` | Completar producción |
| POST | `/api/production/batch/{id}/post` | Postear a inventario |

---

### Compras (`/api/purchasing/*`) — 11 endpoints

| Método | Ruta | Descripción |
|--------|------|------------|
| GET | `/api/purchasing/replenishment/suggestions` | Sugerencias de reposición |
| GET | `/api/purchasing/replenishment/suggestions/{id}` | Detalle sugerencia |
| POST | `/api/purchasing/replenishment/calculate` | Calcular reposición |
| POST | `/api/purchasing/replenishment/suggestions/{id}/approve` | Aprobar sugerencia |
| POST | `/api/purchasing/replenishment/suggestions/{id}/reject` | Rechazar |
| POST | `/api/purchasing/replenishment/suggestions/{id}/convert` | Convertir a OC |
| POST | `/api/purchasing/receptions/create-from-po` | Crear recepción desde OC |
| POST | `/api/purchasing/receptions/lines` | Agregar líneas |
| POST | `/api/purchasing/receptions/validate` | Validar recepción |
| POST | `/api/purchasing/receptions/post` | Postear a inventario |
| POST | `/api/purchasing/receptions/costing` | Calcular costos |
| POST | `/api/purchasing/returns/create-from-po` | Crear devolución |
| POST | `/api/purchasing/returns/approve` | Aprobar devolución |
| POST | `/api/purchasing/returns/ship` | Despachar devolución |
| POST | `/api/purchasing/returns/confirm` | Confirmar recepción proveedor |
| POST | `/api/purchasing/returns/post` | Postear |
| POST | `/api/purchasing/returns/credit-note` | Nota de crédito |

---

### Reportes (`/api/reports/*`) — 25 endpoints
> Middleware: `auth:sanctum, permission:reports.view`

| Método | Ruta | Descripción |
|--------|------|------------|
| GET | `/api/reports/kpis/sucursal` | KPIs por sucursal |
| GET | `/api/reports/kpis/terminal` | KPIs por terminal |
| GET | `/api/reports/ventas/familia` | Ventas por familia |
| GET | `/api/reports/ventas/hora` | Ventas por hora |
| GET | `/api/reports/ventas/top` | Top productos |
| GET | `/api/reports/ventas/dia` | Ventas por día |
| GET | `/api/reports/ventas/categorias` | Por categoría |
| GET | `/api/reports/ventas/sucursales` | Por sucursal |
| GET | `/api/reports/ventas/ordenes_recientes` | Órdenes recientes |
| GET | `/api/reports/ventas/formas` | Por forma de pago |
| GET | `/api/reports/ticket/promedio` | Ticket promedio |
| GET | `/api/reports/sales/detail` | Detalle de ventas |
| GET | `/api/reports/sales/summary` | Resumen de ventas |
| GET | `/api/reports/sales/balance` | Balance de ventas |
| GET | `/api/reports/sales/exceptions` | Excepciones (descuentos, anulaciones) |
| GET | `/api/reports/sales/mix` | Sales mix |
| GET | `/api/reports/sales/mods` | Reporte de modificadores |
| GET | `/api/reports/sales/drawer` | Drawer pull report |
| GET | `/api/reports/sales/diagnostics` | Diagnóstico de ventas |
| GET | `/api/reports/menu/usage` | Uso de menú |
| GET | `/api/reports/tickets/open` | Tickets abiertos |
| GET | `/api/reports/purchasing/late-po` | OC tardías |
| GET | `/api/reports/inventory/over-tolerance` | Stock fuera de tolerancia |
| GET | `/api/reports/inventory/top-urgent` | Ítems urgentes |

---

### Catálogos (`/api/catalogs/*`) — 5 endpoints

| Método | Ruta | Descripción |
|--------|------|------------|
| GET | `/api/catalogs/categories` | Categorías |
| GET | `/api/catalogs/almacenes` | Almacenes |
| GET | `/api/catalogs/sucursales` | Sucursales |
| GET | `/api/catalogs/unidades` | Unidades de medida |
| GET | `/api/catalogs/movement-types` | Tipos de movimiento |

---

### Unidades (`/api/unidades/*`) — 9 endpoints

| Método | Ruta | Descripción |
|--------|------|------------|
| GET | `/api/unidades` | Lista unidades |
| GET | `/api/unidades/{id}` | Detalle unidad |
| POST | `/api/unidades` | Crear unidad |
| PUT | `/api/unidades/{id}` | Actualizar |
| DELETE | `/api/unidades/{id}` | Eliminar |
| GET | `/api/unidades/conversiones` | Lista conversiones |
| POST | `/api/unidades/conversiones` | Crear conversión |
| PUT | `/api/unidades/conversiones/{id}` | Actualizar |
| DELETE | `/api/unidades/conversiones/{id}` | Eliminar |

---

### Otros endpoints

| Método | Ruta | Descripción | Auth |
|--------|------|------------|------|
| GET | `/api/me/permissions` | Permisos del usuario actual | Sanctum |
| GET | `/api/alerts` | Alertas del sistema | Sanctum |
| POST | `/api/alerts/{id}/ack` | Confirmar alerta | Sanctum |
| GET | `/api/audit-log` | Log de auditoría | Sanctum + permission:audit.view |
| GET | `/api/close/status` | Estado de cierre diario | — |

---

## Rutas Web (Livewire 3)

| Ruta | Componente / Vista | Módulo |
|------|--------------------|--------|
| `/dashboard` | view: dashboard | Dashboard |
| `/catalogos/unidades` | CatalogUnidadesIndex | Catálogos |
| `/catalogos/uom` | CatalogUomConversionIndex | Catálogos |
| `/catalogos/almacenes` | CatalogAlmacenesIndex | Catálogos |
| `/catalogos/proveedores` | CatalogProveedoresIndex | Catálogos |
| `/catalogos/sucursales` | CatalogSucursalesIndex | Catálogos |
| `/catalogos/stock-policy` | CatalogStockPolicyIndex | Catálogos |
| `/inventory/items` | InventoryItemsManage | Inventario |
| `/inventory/items/new` | InventoryInsumoCreate | Inventario |
| `/inventory/receptions` | InventoryReceptionsIndex | Inventario |
| `/inventory/receptions/new` | InventoryReceptionCreate | Inventario |
| `/inventory/receptions/{id}/detail` | InventoryReceptionDetail | Inventario |
| `/inventory/lots` | InventoryLotsIndex | Inventario |
| `/inventory/alerts` | InventoryAlertsList | Inventario |
| `/inventory/counts` | InventoryCountIndex | Conteos |
| `/inventory/counts/create` | InventoryCount/Create | Conteos |
| `/inventory/counts/{id}/capture` | InventoryCount/Capture | Conteos |
| `/inventory/counts/{id}/review` | InventoryCount/Review | Conteos |
| `/inventory/counts/{id}/detail` | InventoryCount/Detail | Conteos |
| `/inventory/orquestador` | OrquestadorPanel | Inventario |
| `/recipes` | RecipesIndexLW | Recetas |
| `/recipes/editor/{id?}` | RecipeEditorLW | Recetas |
| `/recipes/{id}/versions` | VersionComparator | Recetas |
| `/transfers` | TransfersIndex | Transferencias |
| `/transfers/create` | TransfersCreate | Transferencias |
| `/transfers/{id}/detail` | TransferDetail | Transferencias |
| `/transfers/{id}/dispatch` | TransferDispatch | Transferencias |
| `/transfers/{id}/receive` | TransferReceive | Transferencias |
| `/purchasing/replenishment` | ReplenishmentDashboard | Compras |
| `/purchasing/requests` | PurchasingRequestsIndex | Compras |
| `/purchasing/requests/create` | PurchasingRequestsCreate | Compras |
| `/purchasing/requests/{id}/detail` | PurchasingRequestsDetail | Compras |
| `/purchasing/orders` | PurchasingOrdersIndex | Compras |
| `/purchasing/orders/{id}/detail` | PurchasingOrdersDetail | Compras |
| `/cashfund` | CashFundIndex | Caja Chica |
| `/cashfund/open` | CashFundOpen | Caja Chica |
| `/cashfund/{id}/movements` | CashFundMovements | Caja Chica |
| `/cashfund/{id}/arqueo` | CashFundArqueo | Caja Chica |
| `/cashfund/{id}/detail` | CashFundDetail | Caja Chica |
| `/cashfund/approvals` | CashFundApprovals | Caja Chica |
| `/reports` | ReportsDashboard | Reportes |
| `/reports/drill-down/{type}/{id?}` | ReportsDrillDown | Reportes |
| `/reports/sales` | SalesReportController | Reportes |
| `/reports/sales/mix` | SalesMixController | Reportes |
| `/reports/sales/drawer` | SalesDrawerController | Reportes |
| `/reports/sales/diagnostics` | SalesDiagController | Reportes |
| `/reports/sales/mods` | SalesModsController | Reportes |
| `/reports/menu/usage` | MenuUsageController | Reportes |
| `/reports/tickets/open` | OpenTicketsController | Reportes |
| `/caja/cortes` | CajaController | Caja |
| `/caja/cortes/aprobaciones` | view: caja.aprobaciones | Caja |
| `/caja/cortes/historico` | CortesHistoricoController | Caja |
| `/kds` | KdsBoard | KDS |
| `/pos/map` | PosMapIndex | POS Sync |
| `/audit/logs` | AuditLogController | Auditoría |
| `/admin` | view: admin | Admin |
| `/admin/tickets/management` | TicketManagementController | Admin |
| `/profile` | ProfileController | Usuario |
