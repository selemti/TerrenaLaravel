# Inventario · Dashboard, Kardex y disponibilidad (V4.0)

## 1. Alcance

Describe la vista general de inventario (`/inventario`) y los componentes Livewire que muestran stock, KPIs y Kardex (`/inventory/items`, `/inventory/lots`). Sustituye wireframes legacy de dashboards; cualquier ajuste debe documentarse aquí antes de desplegar.

## 2. Referencias y tablas

| Fuente | Descripción |
|--------|-------------|
| `Route::view('/inventario', 'inventario')` | Tablero estático Bootstrap con filtros, KPIs y tablas mock (`resources/views/inventario.blade.php`). |
| `App\Livewire\Inventory\ItemsIndex` + `resources/views/livewire/inventory/items-index.blade.php` | Listado dinámico de catálogo con KPIs, modal de Kardex y “movimiento rápido”. |
| `App\Livewire\Inventory\LotsIndex` + `resources/views/inventory/lots-index.blade.php` | Lista los últimos 100 lotes desde `inventory_batch`. |
| Vistas/Tablas | `selemti.items`, `selemti.item_categories`, `selemti.cat_unidades`, `selemti.inventory_batch`, `selemti.mov_inv`, vista esperada `selemti.v_kardex_item`. |
| Docs legacy | `docs/Orquestador/wireflows_inventory.md`, `docs/Orquestador/wireflows_inventory_pos.md` (estructura esperada de dashboard y Kardex). |

## 3. Componentes y rutas activas

| Ruta | Componente/Vista | Propósito |
|------|------------------|-----------|
| `/inventario` | Blade estático | Dashboard legacy con filtros UI y modales Bootstrap. No tiene back-end conectado. |
| `/inventory/items` | `Livewire\Inventory\ItemsManage` (catálogo), pero incluye `ItemsIndex` dentro de la vista para KPIs/Kardex. |
| `/inventory/lots` | `Livewire\Inventory\LotsIndex` | Tabla de lotes recientes para monitorear caducidades. |

El layout usado es siempre `layouts.terrena`. Permisos del menú controlados por `can_manage_purchasing`.

## 4. Flujo del dashboard / ItemsIndex

1. **Filtros y KPIs** (`app/Livewire/Inventory/ItemsIndex.php:19-118`): filtros por texto, sucursal, categoría y caducidad, con persistencia en query string. KPIs (`itemsDistintos`, `valorInventario`, `bajoStock`, `porVencer`) se calculan en `calcKpis()`, hoy solo suman `costo_promedio` y tienen TODOs para stock real.
2. **Listado** (`baseQuery()`): consulta `selemti.items` + `cat_unidades` + `item_categories`. Campos `existencia`, mínimos y proveedor principal aún están en `NULL` o pendientes (`resources/views/livewire/inventory/items-index.blade.php:31-129`).
3. **Modal Kardex** (`openKardex()`): espera la vista `selemti.v_kardex_item` con columnas `ts`, `tipo`, `ref`, `entrada`, `salida`, `saldo`, `costo`, `notas`. Trae los últimos 200 registros por `item_id`.
4. **Movimiento rápido** (`saveMove()`): inserta directamente en `mov_inv` con `tipo` (`ENTRADA`, `SALIDA`, `TRANSFERENCIA`, `MERMA`). No existen validaciones de stock, tolerancias ni bitácora; la referencia se marca como `ref_tipo = 'UI'`. Es crítico restringirlo por permiso y mover la lógica a un servicio antes de usarlo en producción.
5. **UI legacy (`resources/views/inventario.blade.php`)**: replica filtros, KPIs, tabla y modales similares pero puramente front-end. Servía como mock; mantenerlo sincronizado o retirar cuando `ItemsIndex` asuma todo.

## 5. Módulo de lotes

- `LotsIndex` lee `inventory_batch` y `items` (sin prefijo `selemti`, corregir) y muestra ID, item, lote, caducidad, estado y `cantidad_actual`. Ordena por caducidad y limita a 100 (ver `app/Livewire/Inventory/LotsIndex.php:15-35` y `resources/views/inventory/lots-index.blade.php:1-34`).
- Depende de que `ReceptionService` inserte lotes correctamente y de que otros movimientos (transferencias, conteos) actualicen `cantidad_actual`.

## 6. Reglas y requerimientos

1. **Fuente de stock**: mientras no exista tabla/vista `v_stock_resumen`, las KPIs de ItemsIndex no tendrán datos reales. Definir vista en `selemti` (sucursal/almacén) y enlazarla al `baseQuery`.
2. **Kardex**: los movimientos deben venir exclusivamente de servicios formales (Recepciones, Transferencias, Conteos). Deshabilitar el botón “Movimiento rápido” hasta contar con workflow auditado.
3. **Permisos**: agregar abilities específicas (`inventory.dashboard.view`, `inventory.movements.quick`) y validarlas en el componente antes de permitir inserciones en `mov_inv`.
4. **Schemas**: todo query debe respetar `DB_SCHEMA` (hoy `LotsIndex` usa tablas sin prefijo). Alinear a `selemti.*` para ambientes multi esquema.
5. **Dashboards/Reportes**: cuando existan vistas `v_kpi_inventario` o dashboards en `/reports`, documentarlas aquí y enlazar `BaseReportController`.

## 7. Riesgos / tareas abiertas

1. **KPIs mock**: los valores en `resources/views/inventario.blade.php` y `ItemsIndex` son placeholders. Sin conectar a `mov_inv`/stock_policy el dashboard puede inducir a errores operativos.
2. **Movimiento rápido sin auditoría**: inserta en `mov_inv` sin constraints ni logging. Debe pasar por un servicio con validaciones (stock negativo, límites, bitácora) y registrar auditoría.
3. **Vista Kardex**: validar que `selemti.v_kardex_item` exista y contenga los campos esperados; de lo contrario, el modal mostrará vacío.
4. **Permisos API**: se requieren endpoints para consultar stock/kardex por item (ej. `GET /api/inventory/items/{id}/kardex`) protegidos con `auth`. Hoy el componente accede directo a la BD.
5. **Duplicidad de dashboards**: `inventario.blade.php` y `ItemsIndex` muestran contenidos similares con estilos distintos. Definir uno solo y retirar el otro para evitar mantenimiento doble.
6. **Integración con reportes**: la sección `/reports` ya ofrece KPIs; al actualizar dashboards unificar colores/datos usando `config/reports.php`.

## 8. Checklist al modificar el dashboard

- [ ] Confirmaste las vistas/tablas (`selemti.items`, `inventory_batch`, `mov_inv`, `v_kardex_item`) conectándote a la BD correcta (`172.24.240.1` en WSL).
- [ ] Cualquier cambio en queries respeta `DB_SCHEMA` y agrega filtros por sucursal/almacén cuando aplique.
- [ ] Si se toca el movimiento rápido, la lógica se mueve a un servicio con permisos y auditoría documentados aquí.
- [ ] Actualizaste este archivo, `docs/V4.0/Frontend/Componentes.md` (si cambian cards/tablas) y el índice general (`docs/V4.0/README.md`).
- [ ] Si se añade un dashboard/report nuevo, se enlazó bajo `/reports` y se documentó el origen de datos.
