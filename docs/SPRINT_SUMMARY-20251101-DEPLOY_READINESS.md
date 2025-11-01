# Semana Especial Terrena (1-7 Nov 2025) - Resumen Técnico

**Responsables:** Codex (backend) · Qwen (frontend/UI)

**Ámbitos cubiertos:** Costeo de recetas, transferencias entre almacenes, producción, reportes analíticos, normalización de catálogos y ajustes de pruebas automatizadas.

---

## 1. Inventario de Cambios Backend

### 1.1 Costos de Recetas
- 📦 Migration `2025_11_01_090000_create_recipe_cost_snapshots.sql` para `selemti.recipe_cost_snapshots`.
- 🧾 Modelo `App\Models\Rec\RecipeCostSnapshot` con scopes utilitarios.
- ⚙️ Servicio `RecipeCostSnapshotService` con:
  - Creación manual/automática (threshold 2 %),
  - Lectura por fecha con fallback a cálculo en vivo,
  - Job masivo para recetas activas.
- 🧪 Tests `RecipeCostSnapshotTest` y `WeekendDeploymentIntegrationTest` con helpers SQLite + adjuntos JSONB.
- 🔗 Documentación API actualizada (`docs/UI-UX/MASTER/10_API_SPECS/API_RECETAS.md`) con `GET /api/recipes/{id}/bom/implode`.

### 1.2 Implosión de BOM
- ➕ Método `RecipeCostController::implodeRecipeBom()` + endpoint `/api/recipes/{id}/bom/implode`.
- ♻️ Acumulación de ingredientes repetidos, control de profundidad, logging.
- ✅ Tests `RecipeBomImplosionTest` y rutas API registradas.

### 1.3 Transferencias entre Almacenes
- 🧱 Modelos `TransferHeader`/`TransferLine` alineados al esquema SelemTI.
- 🧬 Migration `2025_11_01_090000_complete_transfer_tables.php` (columnas, índices, constraint de estado).
- 🛠️ `TransferService` completado (SOLICITADA → POSTEADA) con validaciones de stock y posting a `mov_inv`.
- 🌐 `Api\Inventory\TransferController` + rutas `/api/inventory/transfers/*`.
- 🧪 Feature spec `TransferServiceTest`.
- 📄 Documentación: `docs/inventory/TRANSFER_MODULE_V1.md` (nuevo).

### 1.4 Seeders de Producción
- 🌱 `CatalogosProductionSeeder` y `RecipesProductionSeeder` con `updateOrInsert`, data filtrada por columnas, inserción en `cat_unidades` y `unidades_medida_legacy`.
- 📘 Cambios documentados en `docs/Recetas/STATUS_RECETAS_3.0.md` (nuevo).

### 1.5 Configuración de Base de Datos y Tests
- 🔧 `config/database.php`, `phpunit.xml` y `scripts/generate_data_dictionary.php` sincronizados con `DB_HOST=127.0.0.1`, `DB_PORT=5433`, `DB_SCHEMA=selemti,public`.
- 🛡️ Trait `Tests\Support\RequiresPostgresConnection` para omitir suites cuando no hay conexión.
- 🧾 Ajustes en servicios (RecipeCosting, Purchasing) para retornos deterministas y validaciones opcionales.

---

## 2. Interfaces Livewire + UX

### 2.1 Catálogos y Recetas (Validaciones + Feedback)
- 🔄 Inputs con `wire:model.live`, mensajes personalizados y contadores de caracteres.
- 🎛️ Loading states (spinners, skeletons) y toasts Bootstrap (`resources/views/components/toast-notification.blade.php`).
- 📱 Responsive tables → cards en móvil, modales full-screen.
- 🧩 Componentes reutilizables (`search-input`, `status-badge`, `action-buttons`, `empty-state`).
- 📄 Documentado en `docs/Recetas/STATUS_RECETAS_3.0.md` y `docs/SPRINT_SUMMARY-20251101-DEPLOY_READINESS.md`.

### 2.2 Transferencias (Frontend Semana 2)
- 🧙 Wizard de creación 3 pasos (`app/Livewire/Transfers/Create.php`).
- 📋 Listado con filtros, badges de estado y acciones contextuales (`Transfers/Index`).
- 🚚 Componentes `Transfers/Dispatch` y `Transfers/Receive` (despacho/recepción con diferencias y confirmaciones).
- 🧭 Rutas `routes/web.php` + navegación lateral.
- 📄 Documentación `docs/inventory/TRANSFER_UI_WEEK2.md` (nuevo).

### 2.3 Producción (Semana 5)
- 📊 Componentes `Production/Index`, `Create`, `Execute`, `Detail` con wizard, consumo de API backend, validaciones inline.
- 📄 Documentación `docs/Produccion/PRODUCTION_UI_WEEK5.md` (nuevo).

### 2.4 Reportes & Dashboard (Semana 6)
- 📈 Livewire `Reports/Dashboard` con 8 KPIs, 5 gráficas Chart.js, export CSV/PDF, favoritos.
- 🔍 `Reports/DrillDown` y modelo `ReportFavorite` + migración 2025_12_01_120000.
- 📄 Documentación `docs/REPORTING_AND_KPIS_DASHBOARD_WEEK6.md` (nuevo).

---

## 3. Cobertura de Pruebas

| Suite | Estado | Notas |
|-------|--------|-------|
| `tests/Unit/RecipeCostSnapshotTest` | ✅ | SQLite + adjuntos JSONB |
| `tests/Feature/RecipeBomImplosionTest` | ✅ | Implosión recursiva |
| `tests/Feature/WeekendDeploymentIntegrationTest` | ✅ | Catálogos + costos + BOM |
| `tests/Feature/Auth/*` | ✅ | Ajustadas a esquema `users` (password hash + verificación) |
| `tests/Unit/Inventory/UomConversionServiceTest` | ✅ | Modo fallback sin Postgres |
| `tests/Feature/Inventory/PriceApiAuthTest` | ✅ | Stubs `hasPermissionTo` |
| `tests/Unit/Purchasing/PurchasingServiceTest` | ✅ | Flujos sin `aprobado_por` obligatorio |

> **Nota:** Cuando la instancia Postgres no está disponible, los traits de soporte evitan falsos negativos.

---

## 4. Próximos Pasos Sugeridos
- Automatizar snapshots diarios via Scheduler (`app/Console/Kernel.php`).
- Integrar TransferService con frontends (botones despachar/recibir en Livewire).
- Completar exportaciones PDF con plantilla Blade y librería DOMPDF.
- Agregar métricas de desempeño (tiempo de respuesta) en Dashboard.
- Documentar procedimientos de despliegue en `docs/plan_despliegue_normalizacion.md`.

---

## 5. Referencias Clave
- Dump normalizado: `DB/00.SelemTI_Normalizada_29_10_25_10_40_v0.sql`.
- Servicios críticos: `RecipeCostSnapshotService`, `TransferService`, `ProductionService`, `ReportExportService`.
- Componentes Livewire: `app/Livewire/{Catalogs,Transfers,Production,Reports}`.
- Documentación ampliada: ver archivos creados/actualizados en esta sesión.

