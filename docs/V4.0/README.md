# Terrena V4.0 · Índice de documentación

## Propósito

Este directorio concentra la versión vigente de la documentación funcional/técnica. Cada ficha debe enlazar rutas, controladores, vistas y tablas reales; cualquier material fuera de `docs/V4.0/` se considera histórico o fuente de apoyo.

## Lineamientos transversales

| Tema | Fuente vigente | Estado |
|------|----------------|--------|
| Layout & UI Kit | `docs/V4.0/Frontend/Layout.md` + `resources/views/layouts/{terrena,app,guest}.blade.php` | ✅ Publicado (2025-11-12) |
| Componentes reutilizables | `docs/V4.0/Frontend/Componentes.md` + `resources/views/components/ui/*` | ✅ Publicado (2025-11-12) |
| Arquitectura y wiring | `docs/V4.0/Arquitectura/README.md` + `docs/Arquitectura/ROUTES_CONTROLLERS_VIEWS-20251017-0251.md` | ✅ Publicado (2025-11-12) |
| Stack & convenciones | `docs/V4.0/Guia/Stack.md` + `AGENTS.md` | ✅ Publicado (2025-11-13) |
| **Deployment & Actualización** | **`docs/V4.0/Guia/Deployment.md`** | **✅ Publicado (2025-11-14)** |

> Mantener estas fichas al día es obligatorio antes de abrir nuevos módulos o permisos.

## Documentos publicados

| Área | Archivo | Alcance |
|------|---------|---------|
| Frontend · Layout | `docs/V4.0/Frontend/Layout.md` | Estructura `layouts.terrena/app/guest`, slots, assets, reglas para evitar contenedores duplicados y garantizar permisos (`TerrenaHasPerm`). |
| Frontend · Componentes | `docs/V4.0/Frontend/Componentes.md` | Design system activo: cards, tablas, modales, badges, toasts, registro de componentes y política de actualizaciones. |
| Arquitectura | `docs/V4.0/Arquitectura/README.md` | Stack Laravel 10 + Livewire, rutas, colas Redis, storage, integraciones y checklist de despliegue. |
| Stack & convenciones | `docs/V4.0/Guia/Stack.md` | Requerimientos de tooling, comandos locales, políticas de seguridad, commits y checklist transversal. |
| **Deployment** | **`docs/V4.0/Guia/Deployment.md`** | **Proceso completo de actualización Local→Producción, arquitectura de ambientes (Windows/Ubuntu), configuración Apache Alias, permisos, troubleshooting, rollback.** |
| Inventario · Items | `docs/V4.0/Inventario/Items.md` | Alta/gestión de catálogo (`InsumoCreate`, `ItemsManage`, API `/api/inventory/items*`, tablas `selemti.items` y catálogos). |
| Inventario · Recepciones | `docs/V4.0/Inventario/Recepciones.md` | Wizard de recepciones, `ReceptionService`, `recepcion_*`, `inventory_batch`, integración con lotes/mov_inv. |
| Inventario · Dashboard/Kardex | `docs/V4.0/Inventario/Disponibilidad.md` | KPIs, Kardex, `ItemsIndex`, `LotsIndex`, vista legacy `/inventario`, riesgos del “movimiento rápido”. |
| Inventario · Transferencias | `docs/V4.0/Inventario/Transferencias.md` | Flujo SOLICITADA→POSTEADA, `TransferService`, `transfer_*`, Livewire `Transfers/*`, pendientes API. |
| Inventario · Conteos físicos | `docs/V4.0/Inventario/Conteos.md` | `InventoryCountService`, componentes `InventoryCount/*`, tablas `inventory_counts/_lines`, ajustes `mov_inv`. |
| Inventario · Mermas y ajustes | `docs/V4.0/Inventario/Mermas.md` | Registro de mermas en `production_orders`, `inventory_wastes`, `mov_inv`, relación con Produmix/wireflows y reportes de desperdicio. |
| Recetas & Costeo | `docs/V4.0/Recetas/README.md` | Editor y listado Livewire, catálogos de UOM, APIs `/api/recipes/*`, `RecipeCostingService`, snapshots, comandos `recipes:sync-pos` y `recetas:recalcular-costos`. |
| Producción | `docs/V4.0/Produccion/README.md` | Estado actual de `/produccion`, APIs `/api/production/batch/*`, servicio operativo `App\Services\Inventory\ProductionService`, integración con Replenishment y movimientos `mov_inv`. |
| POS & Consumos | `docs/V4.0/POS/README.md` | UI de mapeo, `pos_map`, servicios de consumo/reproceso (`PosConsumptionService`), comandos `pos:reprocess`, y riesgos de endpoints pendientes. |
| Finanzas operativas | `docs/V4.0/Finanzas/README.md` | Caja chica (Livewire + modelos), APIs `/api/caja/*` (precortes/postcortes/alertas), `DailyCloseService` y lineamientos de cierre diario. |
| Compras & Replenishment | `docs/V4.0/Purchasing/README.md` | Replenishment dashboard, `PurchasingService`, solicitudes/cotizaciones/órdenes, API `/api/purchasing/*`, recepciones y devoluciones. |
| Reportes · Ventas | `docs/V4.0/Reports/README.md` | Rutas `/reports/sales/*`, `BaseReportController`, exports PDF/XLSX, funciones SQL `f_*`. |
| Caja · Histórico de cortes | `docs/V4.0/Caja/HistoricoCortes.md` | KPIs, filtros, `AnalyticsService`, APIs `postcorte/alertas`, vista `resources/views/caja/*`. |

## Ruta sugerida de trabajo

1. **Depuración legacy**: ejecutar el plan descrito abajo para mover especificaciones viejas (`docs/V2`, `docs/noviembre`, `_archive`) y dejar sólo `docs/V4.0` como fuente activa.
2. **QA cross-module**: validar que cada ficha V4.0 tenga dueño/permisos definidos y actualizar `config/permissions.php`/`docs/UI-UX/v6/PERMISSIONS_MATRIX_V6.md` en paralelo.

## Checklist de validación para cada ficha

- Conectar a la BD usando las credenciales de `.env` y la IP `172.24.240.1` (WSL ↔ host) antes de describir campos/tablas.
- Verificar rutas activas (`routes/web.php`, `routes/api.php`) y controladores/Livewire asociados.
- Incluir referencias a servicios, jobs y migraciones que toquen el flujo.
- Registrar riesgos o gaps detectados y próximos pasos antes de enviar cambios.
- **Antes de deployment a producción:** seguir proceso documentado en `docs/V4.0/Guia/Deployment.md`.

## Backlog inmediato

1. Implementar el plan de depuración legacy (ver sección siguiente) y registrar en este índice cada carpeta migrada a `_archive`.
2. Completar la revisión de permisos para todos los módulos documentados (alinear policies/rutas con `docs/UI-UX/v6/PERMISSIONS_MATRIX_V6.md`).

## Plan de depuración de documentación legacy

1. **Inventario**: listar carpetas fuera de `docs/V4.0/` (`docs/V2`, `docs/V3`, `docs/noviembre`, `docs/Recetas/*.md`, etc.) y clasificar cada archivo como: migrado (ya existe en V4.0), pendiente (requiere migración) o histórico (mover a `_archive/legacy-<fecha>`).
2. **Cross-check**: antes de mover un archivo, confirma que el contenido ya exista en la ficha V4.0 correspondiente (ej. `docs/Recetas/STATUS_RECETAS_3.0.md` → `docs/V4.0/Recetas/README.md`). Si falta información, intégrala en la ficha V4.0 y anota la referencia.
3. **Movimiento**: usa `git mv` para trasladar archivos clasificados como históricos a `_archive/<dominio>/...` conservando la fecha en el nombre (p. ej. `_archive/recetas/STATUS_RECETAS_3.0.md`).
4. **Registro**: añade una nota breve en este índice (sección “Documentos publicados” o en la ficha correspondiente) indicando que la fuente legacy fue archivada.
5. **Automatiza**: cuando todo el dominio esté migrado, elimina las rutas legacy del código (por ejemplo, `routes/api.php` con endpoints `.php`) sólo después de validar que ningún cliente las consume.

## Recomendaciones activas por módulo

- **Frontend** (`docs/V4.0/Frontend/{Layout,Componentes}.md`): ningún contenedor raíz extra en las vistas; toda nueva UI debe registrar cambios en el catálogo `<x-ui.*>`.
- **Arquitectura** (`docs/V4.0/Arquitectura/README.md`): asegurar `auth:sanctum` en cualquier endpoint nuevo y ejecutar `./vendor/bin/pint` + `php artisan test` antes de merge.
- **Inventario · Items** (`docs/V4.0/Inventario/Items.md`): retirar definitivamente `InsumoController`, mapear categorías desde DB y proteger el generador de códigos con transacciones.
- **Inventario · Recepciones** (`docs/V4.0/Inventario/Recepciones.md`): consolidar `ReceptionService` vs `ReceivingService`, definir estados BORRADOR→VALIDADA→POSTEADA y obligar evidencias en aprobaciones.
- **Inventario · Disponibilidad/Kardex** (`docs/V4.0/Inventario/Disponibilidad.md`): conectar KPIs a stock real (`v_stock_resumen`) y desactivar “movimiento rápido” hasta que exista servicio con permisos/auditoría.
- **Inventario · Transferencias** (`docs/V4.0/Inventario/Transferencias.md`): exponer API REST real, reemplazar mocks en `Transfers\Index` y alinear nomenclaturas (SOLICITADA/APROBADA/...).
- **Inventario · Conteos** (`docs/V4.0/Inventario/Conteos.md`): actualizar modelos para columnas `creado_por/cerrado_por`, crear vista de stock teórico y añadir policies `inventory.counts.*`.
- **Compras & Replenishment** (`docs/V4.0/Purchasing/README.md`): agregar middleware `auth:sanctum` a `/api/purchasing/suggestions*`, completar `ReturnService`, y crear UI para cotizaciones antes de habilitar el flujo completo.
- **Recetas & Costeo** (`docs/V4.0/Recetas/README.md`): habilitar versionado real (más de `version=1`), alinear Livewire de conversiones con su vista, y asegurar que las tablas auxiliares (`recipe_labor_steps`, `recipe_overhead_allocations`, `item_cost_history`) existan en todos los entornos antes de depender del job diario.
- **Producción** (`docs/V4.0/Produccion/README.md`): sustituir el API stub (`App\Services\Production\ProductionService`) por la implementación real, validar permisos (`production.batch.*`) y conectar la UI con `Inventory\ProductionService` para evitar dobles movimientos.
- **POS & Consumos** (`docs/V4.0/POS/README.md`): registrar los endpoints de `PosConsumptionController` en `routes/api.php`, limpiar los formularios Livewire (campos obsoletos) y obligar motivos/evidencias al reprocesar tickets antes de exponer el módulo.
- **Finanzas** (`docs/V4.0/Finanzas/README.md`): reactivar middleware en `/api/caja/*`, formalizar permisos `cashfund.*`/`caja.*`, y sincronizar Caja Chica/Histórico de cortes con el cierre diario (`DailyCloseService`) para evitar divergencias entre módulos.
- **Inventario · Mermas** (`docs/V4.0/Inventario/Mermas.md`): implementar la UI de ajustes rápidos descrita en los wireflows, catalogar motivos (`MERMA_PRODUCCION`, `DAÑO`, etc.), y asegurar que el API público de producción usa `Inventory\ProductionService` para registrar `inventory_wastes` reales.
