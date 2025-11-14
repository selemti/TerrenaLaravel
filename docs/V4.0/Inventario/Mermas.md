# Inventario · Mermas y ajustes (V4.0)

## 1. Alcance y fuentes

Fuente oficial para todo lo relacionado con registro de mermas, ajustes y KPIs de desperdicio. Se basa en:

- Servicios de producción: `App\Services\Inventory\ProductionService` (implementación activa) y `App\Services\Production\ProductionService` (API stub).  
- Modelos/tablas: `production_orders`, `production_order_inputs/outputs`, `inventory_wastes`, `mov_inv`, `RecetaDetalle` (`merma_porcentaje`), `items` (`merma_pct`), vistas `v_merma_por_item`.  
- UI/Reports: `App\Livewire\Reports\Dashboard` (widgets de merma), `App\Livewire\Reports\DrillDown`, `ReportExportService`.  
- Wireflows y especificaciones: `docs/Produccion/PRODUMIX.md`, `docs/Produccion/PRODUCTION_FLOW.md`, `docs/Orquestador/wireflows_inventory*.md` (ajustes rápidos, implosión), `docs/noviembre/11-11-2025/INVENTARIO_ITEMS_DIAGNOSTICO.md`.  
- Pendientes de UX (modales de ajuste/merma) documentados en `docs/Orquestador/wireflows_inventory.md` §4.

## 2. Tablas y campos clave

| Tabla | Campos | Uso |
|-------|--------|-----|
| `selemti.production_orders` | `qty_merma`, `estado`, `creado_por`… | Cabecera del batch; `Inventory\ProductionService::createOrder()` actualiza `qty_merma` con la suma de `inventory_wastes`. |
| `selemti.inventory_wastes` | `production_order_id`, `item_id`, `qty`, `uom`, `motivo`, `meta` | Registro granular de merma declarada desde producción; también se usa para incidentes manuales cuando existan formularios. |
| `selemti.mov_inv` | `tipo` (`PROD_OUT`, `PROD_IN`, `MERMA`, `AJUSTE_*`) | Movimientos generados por producción, conteos o ajustes rápidos. Los tipos especiales mencionados en los wireflows (`MERMA_PRODUCCION`, `AJUSTE_REPROCESO_POS`) se registran aquí. |
| `selemti.receta_det` (`App\Models\Rec\RecetaDetalle`) | `merma_porcentaje` | Define merma esperada por ingrediente; usada por `RecalcularCostosRecetasService` al calcular factores. |
| `selemti.items` | `merma_pct` (capturado en `App\Livewire\Inventory\InsumoCreate`) | Campo pensado para merma estándar del insumo; los diagnósticos de 2025-11-11 señalaban que no se persistía, hoy se inserta pero falta validación/reportes. |
| `selemti.v_merma_por_item` / `inventory_wastes` | Vistas/reportes | Usadas por dashboards (`Livewire\Reports\Dashboard`) para KPIs “Mermas por categoría”. |

## 3. Flujos operativos

### 3.1 Mermas dentro de producción
- `Inventory\ProductionService::createOrder($header, $inputs, $outputs, $wastes)` acepta un arreglo `wastes`. Cada entrada genera:  
  1. Registro en `inventory_wastes`.  
  2. Movimiento `mov_inv` `tipo='MERMA'` con `ref_tipo='production_order'`.  
  3. Actualización de `production_orders.qty_merma`.  
- Los formularios Produmix/wireflows (ver `docs/Produccion/PRODUMIX.md` y `PRODUCTION_FLOW.md`) requieren que todo batch registre user, motivo y evidencias; hoy solo el servicio operativo lo hace. El API REST (`App\Services\Production\ProductionService`) aún es un stub, por lo que las mermas controladas solo ocurren cuando Replenishment llama al servicio operativo.

### 3.2 Ajustes rápidos / mermas incidentales
- El wireflow “Ajustes rápidos” (`docs/Orquestador/wireflows_inventory.md` §4) define un modal de dos pasos (item/motivo → cantidad + evidencia) que debe postear `mov_inv` `tipo=AJUSTE/MERMA`. Esta UI no está implementada en V4.0; hasta entonces, los usuarios solo pueden registrar mermas vía producción o conteos.  
- `docs/Orquestador/wireflows_inventory_pos.md` sugiere editor con “merma y rendimiento” por receta; la base se cubre con `RecipeEditor` (`merma_porcentaje` en cada ingrediente), pero falta la vista agregada para visualizar mermas de recetas completas.

### 3.3 Conteos físicos y snapshots
- Conteos (`docs/V4.0/Inventario/Conteos.md`) generan movimientos `AJUSTE` cuando se aplica la diferencia. Para trazabilidad deben clasificar motivos (merma, daño, inventario) según el wireflow; actualmente esa clasificación no existe.  
- `DailyCloseService` integra mermas indirectamente: al generar snapshots compara inventario teórico vs físico (si hay `inventory_counts`). No registra `inventory_wastes` adicionales, solo reporta discrepancias.

### 3.4 Reportes y KPIs
- `App\Livewire\Reports\Dashboard` expone widgets `mermas_por_categoria`, `merma_promedio` usando `inventory_wastes` y `production_orders.qty_merma`.  
- `ReportExportService` trata columnas que contengan “merma” o “eficiencia” como métricas clave (formato decimal).  
- Cualquier nueva fuente de merma debe añadir SQL/Vistas para alimentar estos widgets.

## 4. Servicios y endpoints relevantes

| Servicio / Endpoint | Descripción | Estado |
|---------------------|-------------|--------|
| `App\Services\Inventory\ProductionService` | Único servicio que hoy impacta `inventory_wastes` y `mov_inv` “MERMA”. | Activo (llamado por Replenishment). |
| `App\Services\Production\ProductionService` + `/api/production/batch/*` | API pública que debería registrar mermas, pero actualmente solo retorna stubs (`TODO` en documentación). | **Pendiente de implementar**. |
| Ajustes rápidos (wireflow) | Modal para registrar mermas manuales fuera de producción. | **Pendiente** (no existe componente ni endpoint). |
| `Livewire\Reports\Dashboard` / `/reports` | Visualiza KPIs de merma. | Activo; depende de que las tablas se alimenten. |

## 5. Riesgos y pendientes

1. **API vs servicio operativo**: hasta que el API `/api/production/batch/*` use `Inventory\ProductionService`, las mermas registradas vía UI serán inconsistentes (solo Replenishment genera datos reales).  
2. **Falta de UI para ajustes rápidos**: el flujo descrito en los wireflows (seleccionar item → motivo → cantidad) no existe; hoy los usuarios dependen de manipular la BD o ProductionService para registrar desperdicio incidental.  
3. **Campos `merma_pct` vs `merma_porcentaje`**: se capturan en `InsumoCreate`/`RecetaDetalle`, pero no hay reportes que los utilicen ni validación contra los diagnósticos de 2025-11-11.  
4. **Clasificación de motivos**: `inventory_wastes` guarda `motivo` libre. Falta catálogo (MERMA_PRODUCCION, MERMA_CALIDAD, DAÑO, etc.) para alimentar dashboards y auditoría.  
5. **Auditoría**: ni el API stub ni los wireflows contemplan evidencias obligatorias (foto, comentario). `ProductionService` tampoco guarda adjuntos.  
6. **Depuración legacy**: los docs Produmix/ProductionFlow siguen vigentes y no están en V4.0; esta ficha los referencia, pero al migrar funcionalidades habrá que mover los originales a `_archive` y mantener la versión resumida aquí.

## 6. Checklist al modificar o registrar mermas

- [ ] ¿Usaste `App\Services\Inventory\ProductionService` para registrar la merma? Si consumiste el API `/api/production/batch/*`, verifica que ya esté conectado.  
- [ ] Confirmaste los campos reales en BD (`inventory_wastes`, `production_orders.qty_merma`, `mov_inv.tipo='MERMA'`, `items.merma_pct`, `receta_det.merma_porcentaje`).  
- [ ] Si agregaste UI/endpoint de “ajuste rápido”, seguiste el wireflow (`docs/Orquestador/wireflows_inventory.md`) y protegiste la ruta con permisos específicos (`inventory.adjustments.manage`).  
- [ ] Actualizaste los reportes (`Livewire\Reports\Dashboard`, vistas `v_merma_por_item`) para reflejar nuevas fuentes de merma.  
- [ ] Registraste motivos/evidencias en `inventory_wastes.meta` o un catálogo oficial y anotaste el cambio en esta ficha + `docs/V4.0/README.md`.  
- [ ] Ejecutaste `php artisan test` (tests de `Inventory\ProductionService` y reportes) y `./vendor/bin/pint` tras modificar código relacionado.

Con esta ficha cerramos el ciclo de documentación de mermas, integrando lo definido en Produmix/wireflows con el código efectivo y resaltando las brechas pendientes en Terrena V4.0.
