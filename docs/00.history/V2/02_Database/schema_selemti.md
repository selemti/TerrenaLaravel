# Esquema `selemti` (PostgreSQL 9.5)

_Esquema principal del POS Terrena (derivado de Floreant). Las definiciones completas están en `BD/patches/selemti/*.sql`._  
_Última revisión_: octubre 2025.

---

## 1. Estructura de los parches

Los archivos fueron generados automáticamente a partir de `backup_pre_deploy_20251017_221857.sql`. Deben ejecutarse en el siguiente orden:

1. `00_base.sql` – tipos `ENUM` y configuraciones iniciales (`consumo_policy`, `mov_tipo`, `producto_tipo`, etc.).  
2. `05_sequences.sql` / `15_sequence_owned_by.sql` – secuencias para tablas nuevas.  
3. `10_tables.sql` – tablas faltantes (inventario, recetas, caja, catálogos).  
4. `20_constraints.sql` – claves primarias/foráneas y `CHECK`.  
5. `25_indexes.sql` – índices adicionales.  
6. `30_functions.sql` – lógica PL/pgSQL (precortes, costos, recepción).  
7. `40_views.sql` – vistas de apoyo (inventario, ventas, recetas).  
8. `50_triggers.sql` – triggers de auditoría y automatización.  
9. `60_comments.sql` – descripciones y ACL.

La lista detallada de objetos pendientes se encuentra en `BD/patches/missing_objects.json`.

---

## 2. Tablas Relevantes

### 2.1 Catálogos POS

| Tabla | Descripción | Observaciones |
|-------|-------------|---------------|
| `sucursal` | Catálogo de sucursales (`id` texto). | Equivalente funcional a `public.cat_sucursales`. |
| `almacen` / `bodega` | Almacenes/bodegas por sucursal. | Ver relación con `public.cat_almacenes`. |
| `proveedor` | Proveedores (`id` texto). | Evaluar migración a `public.cat_proveedores`. |
| `unidades_medida` / `cat_unidades` | Unidades del POS. | CRUD Livewire opera sobre `selemti.unidades_medida`. |
| `conversiones_unidad` / `uom_conversion` | Factores de conversión. | Revisar duplicidad con `public.cat_uom_conversion`. |
| `stock_policy` | Políticas de stock nativas. | Considerar si `public.inv_stock_policy` debe reemplazarla. |
| `param_sucursal`, `pos_map`, `sucursal_almacen_terminal` | Configuración POS ⇔ Terrena. | Mantener sincronizado. |

### 2.2 Inventario

| Tabla | Uso | Comentarios |
|-------|-----|-------------|
| `items`, `insumo`, `insumo_presentacion` | Maestro de artículos e insumos. | `App\Models\Inv\Item` utiliza `items`. |
| `recepcion_cab`, `recepcion_det`, `inventory_batch` | Recepciones y lotes. | `ReceptionService` escribe aquí. |
| `mov_inv` | Movimientos de inventario / kardex. | Consumido por Livewire (`ItemsIndex`). |
| `lote`, `merma`, `perdida_log` | Control de lotes y mermas. | Requiere triggers (ver `50_triggers.sql`). |
| `historial_costos_*`, `cost_layer`, `job_recalc_queue` | Costo promedio y recalculo. | Revisar funciones `recalcular_costos_periodo`. |

### 2.3 Recetas y Producción

| Tabla | Descripción |
|-------|-------------|
| `receta`, `receta_cab`, `receta_det`, `receta_insumo`, `receta_version`, `receta_shadow` | Definiciones de recetas, versiones y componentes. |
| `op_cab`, `op_produccion_cab`, `op_insumo`, `op_yield` | Órdenes de producción y rendimiento. |
| `hist_cost_receta`, `hist_cost_insumo` | Históricos de costos. |

### 2.4 Caja y Cortes

| Tabla | Descripción |
|-------|-------------|
| `conciliacion` | Registro de conciliaciones (precorte/postcorte). |
| `ticket_venta_cab`, `ticket_venta_det`, `ticket_det_consumo` | Tickets procesados para reportes. |
| `ticket_venta_*`, `op_cab`, `param_sucursal` | Compatibles con scripts `precorte_conciliacion_*.sql`. |

### 2.5 Seguridad / Framework

Incluye tablas equivalentes a las migraciones Laravel (`users`, `roles`, `permissions`, `cache`, `jobs`, `failed_jobs`, etc.), pero con IDs y tipos específicos del POS. Evitar crear duplicados en `public` salvo que se definan estrategias de sincronización.

---

## 3. Vistas y Funciones

- **Vistas clave** (ver `40_views.sql`): `v_stock_resumen`, `v_kardex_item`, `vw_reconciliation_status`, `kds_orders_enhanced`. Deben revisarse y copiarse a `public` si es necesario exponerlas fuera del esquema.  
- **Funciones relevantes** (`30_functions.sql`): `fn_precorte_after_insert`, `fn_generar_postcorte`, `recalcular_costos_periodo`, `inferir_recetas_de_ventas`, etc. Algunas se mencionan en `missing_objects.json` como faltantes en ambientes actuales.

---

## 4. Integración con Laravel

- **Configuración**: `.env` → `DB_SCHEMA=selemti,public` para priorizar objetos POS.  
- **Modelos**: `App\Models\Catalogs\Unidad`, `App\Models\Inv\Item`, `App\Models\Catalogs\StockPolicy` (versión POS) apuntan a este esquema.  
- **Livewire**: inventario y recetas esperan que vistas y tablas estén presentes aquí.  
- **Catálogos**: decidir si los nuevos catálogos `public.cat_*` reemplazarán a las tablas POS o servirán como staging. Documentar mapeo en `schema_public.md`.

---

## 5. Fuentes externas complementarias

- `D:\Tavo\2025\UX\Inventarios\selemti_deploy_inventarios_FINAL_v2.sql` – scripts adicionales para inventario.  
- `D:\Tavo\2025\UX\Cortes\precorte_conciliacion_*.sql` – consultas y vistas de conciliación.  
- `D:\Tavo\2025\UX\00. Recetas\Query Recetas\*.sql` – scripts de recetas y procesos APPCC.

Registrar en `docs/V2/02_Database/scripts/README.md` cada vez que uno de estos scripts se incorpore oficialmente al repositorio.

---

## 6. Tareas pendientes

- [ ] Validar qué tablas/fks de los parches siguen faltando en ambientes actuales (usar `missing_objects.json`).  
- [ ] Documentar estrategia de sincronización entre `public` y `selemti` para catálogos y stock.  
- [ ] Convertir scripts críticos en migraciones o seeds automatizados.  
- [ ] Agregar responsables y procedimientos de despliegue para este esquema.

Actualiza este archivo cuando se modifiquen las definiciones o se integren nuevos parches.
