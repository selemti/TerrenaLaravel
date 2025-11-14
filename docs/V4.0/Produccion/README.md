# Producción interna (V4.0)

## 1. Alcance y fuentes

Documento maestro para el módulo de producción/mise-en-place. Se alimenta del código real:

- Vista placeholder `resources/views/produccion.blade.php` (links y tabla de endpoints).
- Controlador API `app/Http/Controllers/Production/ProductionController.php`.
- Servicios:
  - `App\Services\Production\ProductionService` (stub usado por el API REST).
  - `App\Services\Inventory\ProductionService` (implementación completa usada por Replenishment y scripts internos).
- Modelos `App\Models\ProductionOrder` y tablas auxiliares (`production_order_inputs`, `production_order_outputs`, `inventory_wastes`, `inventory_batch`, `mov_inv`).
- Integraciones: `App\Services\Replenishment\ReplenishmentService::convertToProductionOrder()` crea órdenes de producción desde sugerencias.
- Configuración de rutas `routes/web.php:206-215` (vista) y `routes/api.php:294-297` (endpoints).

Todo cambio debe reflejarse aquí antes de exponer nuevos botones o automatizaciones.

## 2. Tablas y modelos relevantes

| Tabla | Campos clave | Uso |
|-------|--------------|-----|
| `production_orders` (`App\Models\ProductionOrder`) | `folio`, `recipe_id`, `item_id`, `qty_programada`, `qty_producida`, `qty_merma`, `sucursal_id`, `almacen_id`, `estado`, `programado_para`, `iniciado_en`, `cerrado_en`, `meta`. | Cabecera de cada batch. `createOrder()` la llena con `estado=EN_PROCESO`; el API pretende manejar estados BORRADOR→PLANIFICADA→EN_PROCESO→COMPLETADA→POSTEADA. |
| `production_order_inputs` | `production_order_id`, `item_id`, `inventory_batch_id`, `qty`, `uom`, `meta`. | Insumos consumidos; `createOrder()` inserta cada línea y genera `mov_inv` `tipo=PROD_OUT`. |
| `production_order_outputs` | `production_order_id`, `item_id`, `inventory_batch_id`, `qty`, `uom`, `lote_producido`, `fecha_caducidad`, `meta`. | Productos terminados; también genera `mov_inv` `tipo=PROD_IN` y crea lotes en `inventory_batch` si hace falta. |
| `inventory_wastes` | `production_order_id`, `item_id`, `qty`, `uom`, `motivo`, `meta`. | Mermas opcionales, con `mov_inv` `tipo=MERMA`. |
| `inventory_batch` | Se usa para crear lotes de PT y registrar mermas con lote propio. |
| `mov_inv` | Recibe los movimientos `PROD_OUT`, `PROD_IN`, `MERMA`. |

> Nota: El API REST actual (`App\Services\Production\ProductionService`) no persiste nada; la lógica real vive en `App\Services\Inventory\ProductionService`. Hasta que ambos converjan, la única forma de crear batches completos es mediante `ReplenishmentService::convertToProductionOrder()` o llamadas directas al servicio de inventario.

## 3. Flujos y rutas

### 3.1 UI (placeholder)
- `GET /produccion` (`resources/views/produccion.blade.php`) muestra los endpoints disponibles y aclara que el flujo interactivo está pendiente. El sidebar usa `['active' => 'produccion']`.

### 3.2 API REST (stub actual)
Prefijo `Route::prefix('production')->group(...)` en `routes/api.php:294-297` con middleware `auth:sanctum` + `permission:can_edit_production_order` (constructor del controller). Los endpoints devuelven respuestas básicas usando `App\Services\Production\ProductionService`, que hoy solo valida parámetros y devuelve estatus:

| Acción | Método/Ruta | Servicio | Estado resultante |
|--------|-------------|----------|-------------------|
| Planificar batch | `POST /api/production/batch/plan` | `planBatch($recipeId,$qty,$user)` | Regresa `{status:'PLANIFICADA'}` sin persistir. |
| Registrar consumo | `POST /api/production/batch/{id}/consume` | `consumeIngredients($batchId, $lines, $user)` | Responde `EN_PROCESO`, no afecta BD. |
| Completar | `POST /api/production/batch/{id}/complete` | `completeBatch(...)` | Devuelve `COMPLETADA`. |
| Postear | `POST /api/production/batch/{id}/post` | `postBatchToInventory(...)` | Devuelve `POSTEADA` y registra auditoría, pero no genera `mov_inv`. |

Las rutas exigen un `motivo` para `post` y registran auditoría vía `AuditLogService`, pero falta persistencia real. No expongas estos endpoints a usuarios finales hasta conectar con el servicio operativo (`Inventory\ProductionService`).

### 3.3 Servicio operativo (`App\Services\Inventory\ProductionService`)

Usado por `ReplenishmentService::convertToProductionOrder()` al convertir sugerencias de tipo `PRODUCCION` y por pruebas unitarias. `createOrder($header,$inputs,$outputs,$wastes)`:
1. Valida que haya al menos un insumo y un PT.
2. Inserta cabecera `production_orders` y genera `folio` `PR-YYYYMMDD-####`.
3. Inserta inputs (`production_order_inputs`) y genera `mov_inv` `tipo=PROD_OUT`.
4. Inserta outputs, crea lotes en `inventory_batch`, y genera `mov_inv` `tipo=PROD_IN`.
5. Inserta mermas opcionales (`inventory_wastes`) con `mov_inv` `tipo=MERMA`.
6. Actualiza la cabecera con `qty_producida`, `qty_merma`, `estado=COMPLETADO`.

Los helpers `normalizeInput/normalizeOutput/normalizeWaste` aseguran cantidades positivas, UOM y lotes. Si `outputs` no traen `inventory_batch_id`, se crea uno nuevo (UUID por defecto). Este servicio es el único que hoy impacta inventario; cualquier UI/API debe orquestarlo en lugar del stub.

### 3.4 Integración con Replenishment
- En `App\Livewire\Replenishment\Dashboard`, la acción “Convertir a Producción” llama `ReplenishmentService::convertToProductionOrder($suggestionId)`.
- Este método valida que la sugerencia tenga tipo `PRODUCCION`, que el item tenga receta asociada, construye `orderHeader` y, por ahora, no arma los inputs (TODO). Luego ejecuta `Inventory\ProductionService::createOrder(...)` y marca la sugerencia como `CONVERTIDA`.
- Riesgo: las sugerencias no cubren validación de materia prima ni BOM; se delega a la receta/inputs proporcionados manualmente.

## 4. Reglas y pendientes

1. **Unificar servicios**: El API debería usar `App\Services\Inventory\ProductionService`; mientras no ocurra, los endpoints documentados son solo mock y pueden inducir a errores si algún integrador los consume esperando resultados reales.
2. **Estados/permissions**: `ProductionOrder` define constantes BORRADOR/PLANIFICADA/EN_PROCESO/COMPLETADO/PAUSADA/CANCELADA, pero el flujo actual (Replenishment + servicio) sólo usa `EN_PROCESO` → `COMPLETADO`. Falta manejo de aprobaciones, pausa y cancelación.
3. **Inputs/outputs reales**: `convertToProductionOrder()` no calcula BOM; depende de `inputs` pasados vía overrides. Cualquier conversión automática debe consultar `RecetaVersion` para poblar `production_order_inputs`.
4. **Mov_inv duplicados**: `Inventory\ProductionService` postea `PROD_OUT/PROD_IN` dentro de la transacción `createOrder`. Si más adelante se implementa `postBatchToInventory`, hay que evitar dobles movimientos.
5. **Validaciones de stock**: No hay verificación contra inventario actual al consumir insumos. Se debe consultar `inventory_batch`/`stock` antes de permitir `PROD_OUT`.
6. **Lotes y caducidad**: Los outputs permiten `lot`/`exp_date`, pero si no se envían se generan UUID sin caducidad. Definir estándar de nomenclatura y reglas FEFO.
7. **UI pendiente**: `resources/views/produccion.blade.php` es meramente informativa. Falta un componente Livewire (o SPA) que permita planear, capturar y cerrar batches, reutilizando `<x-ui.*>` según los lineamientos frontend.

## 5. Checklist al tocar producción

- [ ] ¿Usaste `App\Services\Inventory\ProductionService` para crear/modificar órdenes? Si interactúas con el API, asegúrate de migrarlo al servicio operativo.
- [ ] Confirmaste las tablas reales (`production_orders`, inputs/outputs/wastes, `inventory_batch`, `mov_inv`) conectando a la BD (`172.24.240.1` desde WSL).
- [ ] Rutas web/API actualizadas (`routes/web.php` para la vista, `routes/api.php:294-297` para endpoints) con el middleware/permisos correctos.
- [ ] Documentaste aquí cualquier cambio en el flujo (nuevos estados, campos, endpoints) antes de publicar.
- [ ] Si agregas UI, usa `layouts.terrena`, componentes documentados en `docs/V4.0/Frontend/*` y registra los nuevos botones/permisos en `config/permissions`.
- [ ] Corriste `php artisan test` (o al menos los tests unitarios de `Inventory\ProductionService`) y `./vendor/bin/pint` si tocaste PHP.

Siguiendo este documento evitamos divergencias entre las APIs mock y el servicio real que mueve inventario, preparando el terreno para una UI completa de producción en Terrena V4.0.
