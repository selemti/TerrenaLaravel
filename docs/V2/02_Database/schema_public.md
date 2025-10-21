# Esquema `public` (PostgreSQL 9.5)

_Fuente de verdad combinada_: migraciones Laravel (`database/migrations`) + parches en `BD/patches/public`.  
_Última revisión_: octubre 2025.

---

## 1. Objetos cubiertos por `BD/patches/public`

Los parches generados desde `backup_pre_deploy_20251017_221857.sql` contienen principalmente funciones y vistas para conciliación de caja y KDS.

### 1.1 Funciones (archivo `BD/patches/public/10_pos_operaciones.sql`)

| Función | Descripción resumida |
|---------|----------------------|
| `public.fn_correct_drawer_report(report_date date)` | Ajusta el total de `drawer_pull_report` con base en tickets no anulados. |
| `public.fn_daily_reconciliation(report_date date)` | KPIs de conciliación diaria por terminal (tickets vs transacciones). |
| `public.fn_reconciliation_detail(report_date date)` | Detalle de conciliación (ventas, devoluciones, propinas). |

> Todas las funciones incluyen `BEGIN/END` y usan objetos clásicos del POS (`drawer_pull_report`, `ticket`, `transactions`, etc.).

### 1.2 Vistas (archivo `BD/patches/public/20_consultas.sql`)

- `public.kds_orders_enhanced`: vista enriquecida para tablero KDS (folio, prioridad, terminal, tiempos).  
- Dependencias adicionales (comentarios/ACL) están documentadas en `missing_objects.json`.

Si se regeneran parches, asegurarse de aplicar primero `10_pos_operaciones.sql` y luego `20_consultas.sql`.

---

## 2. Tablas gestionadas por Laravel (migraciones)

| Tabla | Migración | Columnas clave | Comentarios |
|-------|-----------|----------------|-------------|
| `users`, `password_reset_tokens`, `sessions` | `0001_01_01_000000_create_users_table.php` | Usuarios base Breeze; incluye verificación previa `Schema::hasTable`. | Usar para autenticación web. |
| `cache`, `cache_locks` | `0001_01_01_000001_create_cache_table.php` | `key`, `value`, `expiration`. | Backend `cache:file`. |
| `jobs`, `job_batches`, `failed_jobs` | `0001_01_01_000002_create_jobs_table.php` | Primitivos de colas. | Sin jobs definidos aún. |
| `permissions`, `roles`, `model_has_permissions`, `model_has_roles`, `role_has_permissions` | `2025_09_26_205955_create_permission_tables.php` | Patrones Spatie; migración idempotente. | Definir seeds de roles. |

### 2.1 Catálogos Laravel (creados en octubre 2025)

| Tabla | Columnas principales | Notas |
|-------|----------------------|-------|
| `cat_unidades` | `id`, `clave` (única, 16), `nombre` (64), `activo` (bool), `created_at/updated_at`. | Puede duplicar `selemti.cat_unidades`; revisar sincronización. |
| `cat_uom_conversion` | `id`, `origen_id`, `destino_id`, `factor`, timestamps, índice único (`origen_id`,`destino_id`). | FK hacia `cat_unidades`. |
| `cat_sucursales` | `id`, `clave` (única), `nombre`, `ubicacion`, `activo`, timestamps. | Semilla pendiente. |
| `cat_almacenes` | `id`, `clave` (única), `nombre`, `sucursal_id` (`cascadeOnDelete`), `activo`, timestamps. | Requiere `cat_sucursales`. |
| `cat_proveedores` | `id`, `rfc` (único), `nombre`, `telefono`, `email`, `activo`, timestamps. | CRUD Livewire operativo. |
| `inv_stock_policy` | `id`, `item_id` (string 64), `sucursal_id`, `min_qty`, `max_qty`, `reorder_qty`, `activo`, timestamps, índice único (`item_id`,`sucursal_id`). | FK hacia `items` (POS) y `cat_sucursales`. |

> Estas tablas **no** existen en los parches originales de Floreant/Selemti. Son la capa de catálogos propia de Terrena; documentar migraciones cuando se comparta con terceros.

---

## 3. Relación con objetos `selemti`

Los parches `selemti/10_tables.sql` definen tablas homólogas:

| Tabla Laravel (`public`) | Tabla POS (`selemti`) | Observaciones |
|--------------------------|-----------------------|---------------|
| `cat_unidades` | `selemti.cat_unidades` / `selemti.unidades_medida` | Laravel puede actuar como staging; decidir table única. |
| `cat_uom_conversion` | `selemti.conversiones_unidad` / `uom_conversion` | Verificar si conviene usar la tabla del POS directamente. |
| `cat_sucursales` | `selemti.sucursal` | Mapear `clave` ←→ `id` POS. |
| `cat_almacenes` | `selemti.almacen` / `sucursal_almacen_terminal` | Resolver duplicidad y FKs cruzadas. |
| `cat_proveedores` | `selemti.proveedor` | Unificar antes de poblar datos productivos. |
| `inv_stock_policy` | `selemti.stock_policy` | Evaluar si mantener en `public` o mover a `selemti`. |

Definir estrategia de sincronización (ETL o migración total a `public`). Mientras tanto, mantenemos `DB_SCHEMA=selemti,public` para lectura cruzada.

---

## 4. Pendientes / Próximos pasos

- [ ] Documentar tablas existentes del POS que se consumen desde Laravel (`items`, `mov_inv`, `recepcion_*`, `receta_*`).  
- [ ] Crear vistas `public.v_stock_resumen` y `public.v_kardex_item` (actualmente esperadas por Livewire).  
- [ ] Integrar scripts relevantes de `BD/patches/public` y `BD/patches/selemti` en `docs/V2/02_Database/scripts/` con instrucciones de ejecución.  
- [ ] Alinear catálogos (`cat_*`) entre `public` y `selemti` para evitar duplicados.  
- [ ] Agregar diagrama ER actualizado y notas de versionado.

Actualiza este archivo tras cada cambio estructural significativo.
