# Inventario · Conteos físicos (V4.0)

## 1. Alcance

Fuente oficial del módulo de conteos físicos: estados, tablas, componentes Livewire (`InventoryCount/*`) y servicio `InventoryCountService`. Reemplaza el material disperso en `docs/InventoryCounts/README.md` cuando trabajemos bajo V4.0.

## 2. Tablas y modelos

| Tabla | Modelo | Campos clave | Notas |
|-------|--------|--------------|-------|
| `inventory_counts` (`selemti`) | `App\Models\InventoryCount` | `folio`, `sucursal_id`, `almacen_id`, `estado`, `programado_para`, `iniciado_en`, `cerrado_en`, `creado_por`, `cerrado_por`, `total_items`, `total_variacion`, `notas` | Estados válidos: `BORRADOR`, `EN_PROCESO`, `AJUSTADO`, `CANCELADO`. |
| `inventory_count_lines` | `App\Models\InventoryCountLine` | `inventory_count_id`, `item_id`, `inventory_batch_id`, `qty_teorica`, `qty_contada`, `qty_variacion`, `uom`, `motivo`, `meta` | Accessors calculan variación absoluta y porcentaje. |
| `mov_inv` | — | `tipo='AJUSTE'`, `qty`, `uom`, `sucursal_id`, `almacen_id`, `ref_tipo='inventory_count'`, `ref_id` | Ajustes generados por `InventoryCountService::createAdjustmentMovement`. |
| Catálogos | `selemti.items`, `inventory_batch`, `cat_sucursales`, `cat_almacenes` | Usados para selección de ítems y contextos de conteo. |

## 3. Servicios y flujo backend

**Servicio:** `App\Services\Inventory\InventoryCountService`

1. `open($header, $lines)`  
   - Genera folio (`nextFolio`) y crea cabecera con estado `EN_PROCESO`.  
   - Inserta líneas con `qty_teorica` (stock teórico) y deja `qty_contada` en cero.  
   - Actualiza `total_items` con la suma de cantidades teóricas.

2. `finalize($countId, $lines, $userId, $notes)`  
   - Bloquea el conteo (`lockForUpdate`).  
   - Actualiza cantidades contadas y variaciones para cada línea (usa `normalizeLine`).  
   - Inserta ajustes en `mov_inv` (`tipo=AJUSTE`, `ref_tipo='inventory_count'`).  
   - Marca `estado=AJUSTADO`, `cerrado_por`, `cerrado_en`, suma `total_variacion`.

3. `createAdjustmentMovement(...)`  
   - Inserta en `mov_inv` sólo si la variación ≠ 0. Registra `meta` con `{"origen": "conteo"}`.

Estados no implementados en el servicio (ej. `BORRADOR`, `CANCELADO`) deben manejarse desde los componentes antes de llamar al servicio.

## 4. Componentes Livewire y rutas

| Ruta | Componente | Función |
|------|------------|---------|
| `/inventory/counts` | `InventoryCount\Index` | Listado con filtros por estado, sucursal, almacén, búsqueda de folio/notas. |
| `/inventory/counts/create` | `InventoryCount\Create` | Selecciona ítems (consulta `selemti.items`), obtiene stock teórico desde `mov_inv`, crea conteo vía `InventoryCountService::open`. |
| `/inventory/counts/{id}/capture` | `InventoryCount\Capture` | Captura cantidades físicas (actualiza líneas en tiempo real). |
| `/inventory/counts/{id}/review` | `InventoryCount\Review` | Revisa KPIs, confirma ajustes (`finalize`). |
| `/inventory/counts/{id}/detail` | `InventoryCount\Detail` | Vista solo lectura de conteos cerrados. |

Rutas definidas en `routes/web.php` bajo prefijo `/inventory/counts`. Permisos: menú controlado por `inventory.counts.manage` (o `can_manage_purchasing`); ajustar policies antes de exponer públicamente.

## 5. Flujo operativo

1. **Crear** (`Create`): seleccionar sucursal/almacén (opcional), fecha programada, elegir ítems (buscador, seleccionar todos). Cada ítem carga `qty_teorica` sumando `mov_inv` (filtrado por almacén si se selecciona).
2. **Capturar** (`Capture`): registrar `qty_contada`, guardar progreso. Estado sigue `EN_PROCESO`.
3. **Revisión** (`Review`): calcular exactitud, mostrar variaciones, permitir regresar a captura si hay errores.
4. **Ajustar** (`Review::finalizarConteo` → `InventoryCountService::finalize`): genera movimientos `AJUSTE`, marca `estado=AJUSTADO`.
5. **Detalle** (`Detail`): consulta final para auditoría/reportes.

Estados `BORRADOR` y `CANCELADO` sólo existen en la documentación legacy; hoy el servicio arranca directo en `EN_PROCESO`. Si se requieren, hay que ampliar tablas/modelo/servicio y documentarlo aquí.

## 6. Riesgos y pendientes

1. **Diferencias de columnas**: migración `2025_11_15_010000_create_inventory_counts_tables.php` usa `creado_por/cerrado_por` (`creado_por` vs `created_by`). El modelo `InventoryCount` debe usar los nombres correctos (hoy inconsistente). Ajustar modelo/migración antes de nuevas funcionalidades.  
2. **Cargas de stock**: `Create` calcula `qty_teorica` sumando `mov_inv`. Necesitamos una vista consolidada (`v_stock_resumen`) para evitar sumas pesadas en cada selección.  
3. **Permisos/granularidad**: no hay policies; cualquiera con acceso al menú podría generar ajustes. Implementar `inventory.counts.manage` y logs de auditoría.  
4. **Cancelación/Borrador**: no existe flujo para guardar conteos sin iniciar o cancelarlos. Si se requiere, extender servicio y modelos.  
5. **Mov_inv directo**: los ajustes se insertan sin validación adicional; revisar si se necesita autorización adicional o justificación (foto, motivo).  
6. **Testing**: no hay pruebas automatizadas para `InventoryCountService` en este repo (solo existe README). Agregar tests antes de cambios mayores.

## 7. Checklist al modificar conteos

- [ ] Confirmaste esquema real (`inventory_counts`, `inventory_count_lines`) conectando a la BD (WSL → `172.24.240.1`).  
- [ ] `InventoryCountService` cubre el estado o lógica que tocaste (open/finalize).  
- [ ] Los componentes Livewire actualizados reflejan el estado real y siguen usando el servicio.  
- [ ] Documentaste aquí cualquier cambio en estados, columnas o endpoints.  
- [ ] Si agregaste o modificaste movimientos de ajuste, confirmaste su impacto en `mov_inv`/Kardex.
