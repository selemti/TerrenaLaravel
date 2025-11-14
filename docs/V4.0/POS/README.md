# POS · Consumos y mapeo (V4.0)

## 1. Alcance y fuentes

Describe el flujo actual de integración con Floreant POS: mapeo PLU ↔ receta, ingesta de ventas, diagnósticos, reprocesos y comandos de mantenimiento. Se soporta en:

- UI/LW: `resources/views/pos/mapping-index.blade.php`, `App\Livewire\Pos\{PosMappingIndex,PosMappingForm,PosMapIndex}` y vistas `resources/views/livewire/pos/*.blade.php`.
- Modelos `App\Models\PosMap` y `App\Models\Pos\*` (tickets, items, modificadores, terminales).
- Servicios/clases POS:
  - `App\Services\Pos\PosConsumptionService` (diagnósticos, reprocesos, reversas).
  - `App\Services\Operations\PosConsumptionService` (proceso batch usado por jobs/CLI).
  - Repositorios en `app/Services/Pos/Repositories/*` (tickets, consumo, inventario, recetas, costos).
- Controladores `App\Http\Controllers\Pos\{PosConsumptionController,RecipeCostController}`.
- Comandos `app/Console/Commands/PosReprocess.php` y `recipes:sync-pos` (para habilitar recetas de PLUs/modificadores).
- Documentación de referencia `docs/PosConsumption/*.md`, `docs/UI-UX/definición/POS.md`, `docs/Recetas/README.md`.

## 2. Tablas y funciones

| Recurso | Descripción |
|---------|-------------|
| `selemti.pos_map` (`App\Models\PosMap`) | Mapea PLUs POS (`plu`, `tipo=MENU|MODIFIER`, `receta_id`, `valid_from/to`, `vigente_desde`, `recipe_version_id`). Usado por las pantallas Livewire y `PosConsumptionService`. |
| `selemti.inv_consumo_pos` / `inv_consumo_pos_det` | Cabecera/detalle del consumo registrado por ticket (`ticket_id`, `branch_id`, `requiere_reproceso`, cantidades teóricas). |
| `selemti.pos_reprocess_log` | Bitácora de reprocesos manuales (`ticket_id`, `user_id`, `motivo`). |
| `selemti.mov_inv` | Registra movimientos `SALIDA_VENTA`, `REPROCESO_POS_ANULACION`, etc., cuando se confirma o revierte un ticket. |
| Tablas POS (esquema `public`): `ticket`, `ticket_item`, `menu_item`, `menu_modifier`, `terminal`. Se consultan desde los repositorios y el dashboard de mapeo. |
| Funciones PostgreSQL clave (ver `docs/PosConsumption/IMPLEMENTACION_COMPLETA.md`): `selemti.fn_expandir_consumo_ticket`, `selemti.fn_confirmar_consumo_ticket`, `selemti.fn_recipe_cost_at`. |

## 3. Flujos principales

### 3.1 Mapeo POS ↔ Recetas

- **Vista**: `/pos/mapping` (`resources/views/pos/mapping-index.blade.php`) monta `<livewire:pos.pos-mapping-index />`, protegido por `permission:pos.mapping.view`.
- **Listado**: `PosMappingIndex` filtra por `plu`, `receta_id`, `tipo` y pagina resultados (`pos_map` + `recipe`). Incluye widget `unmapped-items-widget` para ventas sin receta (consulta a `public.ticket`/`menu_item` y `pos_map`).
- **Formulario**: `PosMappingForm` crea o edita registros (`tipo`, `plu`, `receta_id`, vigencias). Aún muestra campos no existentes (`sucursal_id`/`activo`), por lo que se debe limpiar el formulario antes de exponerlo a usuarios finales.
- **Sincronización automática**: `recipes:sync-pos` (comando CLI) importa `menu_item` y `menu_modifier` creando recetas placeholder `REC-#####` y `REC-MOD-#####` y registros en `pos_map`. Ejecutarlo cada vez que se despliegan PLUs/modificadores nuevos en Floreant.

### 3.2 Ingesta y consumo (servicio operativo)

`App\Services\Operations\PosConsumptionService::processTicket($ticketId)` es el motor actual cuando el POS dispara consumos:
1. Previene duplicados (`inv_consumo_pos`).
2. Obtiene ticket + items desde `public.ticket*`.
3. Resuelve `pos_map` para cada PLU. Si falta mapeo, marca `requiere_reproceso=true`.
4. Inserta cabecera/detalle (`inv_consumo_pos`, `_det`) y movimientos `mov_inv` `tipo=SALIDA_VENTA`.
5. Retorna estatus (`success`, `ticket_not_found`, etc.).

Este servicio se usa en:
- `App\Console\Commands\PosReprocess` (CLI `pos:reprocess`), que revierte movimientos (`REPROCESO_POS_ANULACION`), borra consumos y vuelve a llamar `processTicket`.
- `App\Services\Operations\DailyCloseService` (cuando se valida un cierre diario).

### 3.3 Diagnóstico, reproceso y reversa (servicio interactivo)

`App\Services\Pos\PosConsumptionService` encapsula operaciones manuales:

| Método | Descripción |
|--------|-------------|
| `ingestarTicket($ticketId)` | Consulta `TicketRepository` y `ConsumoPosRepository` para saber si ya hubo consumo, devuelve estado `ALREADY_PROCESSED`, `OK`, `ERROR`. |
| `reprocesarTicket($ticketId,$userId)` | Reverte movimientos previos (`hasMovInvForTicket`), ejecuta `fn_expandir_consumo_ticket` y `fn_confirmar_consumo_ticket(..., true)`, registra en `pos_reprocess_log`. Se usa en botones de reproceso y en el controller. |
| `reversarTicket($ticketId,$userId,$motivo)` | Reversión manual con auditoría (inserta `mov_inv` opuestos y marca el consumo). |
| `diagnosticarTicket($ticketId)` | Devuelve `PosConsumptionDiagnostics` con estado del ticket, mapeos, consumo registrado y alertas (se usa para dashboards semáforo). |

El controller `App\Http\Controllers\Pos\PosConsumptionController` expone endpoints pensados para `/api/pos/tickets/*` (diagnósticos, reproceso, reversa, `missing-recipes`), pero **aún no están registrados en `routes/api.php`** (ver `docs/Onboarding/2025-10-27-contexto-del-proyecto.txt`). Antes de exponerlos hay que añadir el prefijo `Route::prefix('pos')->middleware([...])->group(...)` y configurar permisos (`can_reprocess_sales`, `can_view_recipe_dashboard`), además de throttling/auditoría.

### 3.4 Costos POS

`App\Http\Controllers\Pos\RecipeCostController` reutiliza `PosConsumptionService` + `CostosRepository` para recalcular costos de una receta desde POS. No tiene rutas activas; cuando se publique, agregar endpoints `/api/pos/recipes/{id}/cost` (ver `docs/UI-UX/definición/POS.md`) con middleware `can_view_recipe_dashboard`.

## 4. Reglas y dependencias

1. **Mapeo obligatorio**: antes de vender un PLU en producción, asegúrate de crear su receta (`REC-*`) y registrar el `pos_map`. Ventas sin mapeo se acumulan en `inv_consumo_pos.requiere_reproceso = true`.
2. **Permisos**: botones de mapeo usan `permission:pos.mapping.view`; reproceso/reversa deben validar `can_reprocess_sales` + motivo/evidencia (ver TODOs en el controller).
3. **Consistencia con Recetas**: `pos_map.receta_id` debe apuntar a recetas documentadas en `docs/V4.0/Recetas/README.md`. Al actualizar BOM, considera volver a correr `fn_expandir_consumo_ticket` para tickets pendientes.
4. **Reprocesos**: cualquier reproceso CLI requiere `--force` en producción (`pos:reprocess`). No ejecutes en caliente sin auditar `pos_reprocess_log`.
5. **Conexiones**: los repositorios consultan PostgreSQL `public.*` y `selemti.*` usando la conexión `pgsql`. Desde WSL usa `DB_HOST=172.24.240.1`.
6. **POS dashboards**: Los widgets de “ventas sin mapeo” usan consultas SQL crudas (ver `PosMapIndex::loadUnmappedSales`); actualiza el filtro `sucursal_key` y los joins antes de desplegar en sucursales reales.

## 5. Riesgos abiertos

1. **Endpoints no registrados**: `PosConsumptionController` y `RecipeCostController` no están montados en `routes/api.php`; cualquier cliente externo debe esperar a que se agreguen con middleware `auth:sanctum`.
2. **Formularios inconsistentes**: Las vistas `resources/views/livewire/pos/pos-map-index.blade.php` y `pos-map.blade.php` esperan propiedades (`search`, `u_origen`, `sucursal_id`) que hoy no existen en los componentes, provocando errores JS/Blade. Se debe sincronizar antes de habilitar la UI a usuarios finales.
3. **Validaciones pendientes**: Reproceso y reversa aceptan `motivo` pero no exigen `evidencia_url`. Los TODOs en `PosConsumptionController` señalan que será obligatorio al pasar a producción.
4. **Consumo duplicado**: `operations\PosConsumptionService` no detecta cambios en tickets ya procesados. Si se reabre un ticket y se edita, no se vuelve a restar inventario automáticamente; se requiere reproceso manual.
5. **Dependencia de funciones**: `fn_expandir_consumo_ticket`/`fn_confirmar_consumo_ticket` deben existir en la BD; si se renombra el esquema o se cambia la firma, `PosConsumptionService` fallará silenciosamente. Documenta cualquier cambio SQL en `docs/PosConsumption/IMPLEMENTACION_COMPLETA.md`.
6. **Seguridad**: Falta rate-limiting/throttling para los endpoints POS; antes de exponerlos públicamente, configura `Route::middleware(['auth:sanctum', 'throttle:...'])`.

## 6. Checklist antes de tocar POS

- [ ] Revisaste `pos_map` y confirmaste que el PLU/receta existe y tiene vigencias correctas.
- [ ] Si añadiste endpoints, los registraste en `routes/api.php` con middleware `auth:sanctum`, permisos específicos y `use App\Http\Controllers\Pos\...`.
- [ ] Validaste en la BD real (`172.24.240.1`) que `inv_consumo_pos`, `mov_inv` y las funciones `fn_expandir_consumo_ticket`/`fn_confirmar_consumo_ticket` estén disponibles.
- [ ] Al modificar Livewire o vistas, usaste `layouts.terrena` y componentes documentados, y sincronizaste propiedades (sin campos obsoletos).
- [ ] Para reprocesos/reversas, registraste auditoría mediante `AuditLogService` y guardaste motivos/evidencias.
- [ ] Corres `php artisan test` (especialmente `tests/Feature/PosConsumptionServiceTest.php`) y `./vendor/bin/pint` si tocaste PHP.
- [ ] Actualizaste esta ficha y, si aplica, `docs/V4.0/Recetas/README.md` (por la relación recetas/POS) cuando cambies el flujo de consumo.

Manteniendo estas prácticas aseguramos que los consumos POS reflejen fielmente las ventas reales y que cualquier diferencia se pueda diagnosticar y corregir rápidamente en Terrena V4.0.
