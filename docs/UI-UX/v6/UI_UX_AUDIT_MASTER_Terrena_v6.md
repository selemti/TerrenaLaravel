# UI/UX AUDIT MASTER · Terrena v6 → v7 (ERP SaaS)
**Fecha:** 2025-10-31 05:08  
**Autoría:** Auditoría UI/UX + Operaciones (POS/ERP)  
**Ámbito:** localhost/TerrenaLaravel (Front: Livewire 3 + Tailwind · Back: Laravel 11) · BD: public (Floreant POS · solo lectura) + selemti (ERP)

---

## 0) Principios de Diseño (Guía base ERP SaaS con semáforos por estado)

- **Look & Feel:** Minimal, enterprise, limpio. Priorizar legibilidad + densidad de información sin ruido visual.
- **Grid:** Contenedor ancho fijo (xl/2xl), **12 columnas**, gutters uniformes, tarjetas (cards) con `rounded-2xl` y `shadow-sm`.
- **Tipografía:** Titulares `text-xl/2xl`, cuerpo `text-sm`, metadatos `text-xs`.
- **Iconografía:** lucide-react (o Heroicons). Semántica por estado.
- **Estados (colores):**  
  - Primario acciones: `bg-primary/90 hover:bg-primary` (Tailwind theme).  
  - Info: azul (`text-blue-700 bg-blue-50 border-blue-200`).  
  - Éxito: verde (`text-green-700 bg-green-50 border-green-200`).  
  - Advertencia: ámbar (`text-amber-700 bg-amber-50 border-amber-200`).  
  - Error: rojo (`text-red-700 bg-red-50 border-red-200`).  
  - Neutro: gris (`text-slate-600 bg-slate-50 border-slate-200`).  
- **Feedback in-page:** Toasters no bloqueantes, banners de estado y **resumenes pegajosos** en top del módulo (KPIs/contadores).
- **Accesibilidad:** Contraste AA, hit-area mínima 40px, foco visible, soporte teclado.
- **Rendimiento UI:** Paginación server-side, debounce en búsquedas, loads optimistas, skeletons y spinners uniformes.
- **Tokens (Tailwind config):** `--card`, `--muted`, `--ring`, `--success`, `--warning`, `--danger` para unificar estilos en todo el ERP.

---

## 1) Sistema de Navegación (Marco Global)

- **Header App:** Nombre sucursal activa, selector rápido de fecha (bdate), selector de terminal (opcional), perfil/plantilla-permisos.
- **Sidebar persistente:** Módulos: Dashboard, POS Mapping, Orquestador, Inventario, Compras, Recetas, Producción, Conteos, Reportes, Configuración.
- **Breadcrumbs:** `Módulo / Submódulo / Pantalla` (+ badges de estado).  
- **Barra de estado del Orquestador:** Chips: `Ventas mapeadas`, `Consumo POS`, `Reproceso`, `Snapshot`, `Conteos`, `Costos`. Cada chip con color según verificación v6.
- **Footer técnico:** versión (git sha), ambiente, tiempo de respuesta, nombre de servicio.

---

## 2) Componentes Reutilizables (Catálogo)

1. **Toolbar** (título, filtros, búsqueda, botones primarios, downloable).
2. **Card KPI** (título, valor, subtexto, icono, estado).
3. **DataTable Enterprise**  
   - Features: columnas configurables, multi-filtro, orden, selección masiva, exportar CSV, acciones por fila (3 puntos).
   - Slots: `row`, `empty`, `loading`, `footer`.
4. **Drawer lateral** (create/edit) con formularios CRUD.
5. **Confirm Dialogs** (estandarizado, async).
6. **Alert Banner por estado** (info/success/warn/error).
7. **Stepper de proceso** (consumo → reproceso → snapshot → cierre).
8. **Date/Branch/Terminal Picker** (context bar).
9. **SQL Auditor Panel** (textarea de solo lectura + botón ejecutar + badges resultado).
10. **Scheduler Tile** (cron, próxima ejecución, último run, logs).

> **Meta:** Estos componentes deben estar centralizados (ej. `resources/views/components/erp/*`) para **reutilizarlos** en todos los módulos.

---

## 3) Módulos y Pantallas (Estado actual vs. objetivo)

> Basado en capturas, docs (`/docs/Orquestador`), y SQL v6. Cada pantalla incluye: propósito, estado actual, problemas, mejoras y tareas para agentes IA.

### 3.1 Orquestador (Dashboard General)
**Rutas previstas:** `/orquestador`, `/orquestador/kpis`  
**Propósito:** Consolida el estado del día por sucursal/fecha; controles rápidos.  
**Estado actual:** Panel funcional llamando `DailyCloseService` y `RecalcularCostosRecetasService`. Validado con verification v6.  
**Problemas UI/UX:**  
- Semáforos distribuidos y no normalizados visualmente.  
- Falta **histórico** y drilldown por verificación.  
**Mejoras:**  
- **Barra de estado** con 6 chips conectados a **v6** (bloques 1,1.b,2,3,4,5,6,8).  
- Timeline de ejecución (eventos: consumo, reproceso, snapshot, conteos, costos).  
- Botones: `Ejecutar verificación v6`, `Descargar reporte`, `Abrir auditor SQL`.
**Tareas IA:**  
- Refactor UI a componente `OrchestratorStatusBar`.  
- Endpoint `GET /api/orchestrator/summary?bdate&branch`.  
- Drilldown modales por cada verificación (tabla + export).

---

### 3.2 POS Mapping (MENU/MODIFIER)
**Ruta:** `/pos/map`  
**Propósito:** Mapear `public.menu_item` y `ticket_item_modifier` → `selemti.pos_map` (tipos: MENU/MODIFIER).  
**Estado actual:** CRUD existente + consultas v6 (1 y 1.b) integradas.  
**Problemas:** Falta **vista de pendientes** clara; edición lote; vigencias.  
**Mejoras:**  
- Tabs: `Pendientes (v6) · Vigentes · Caducados · Todos`.  
- Tabla: Item POS (id, pg_id, nombre), tipo, receta_id, vigencias (`valid_from/to`), meta.  
- Drawer `Asignar receta` (búsqueda por nombre, por categoría, quick-pick recientes).  
- Acciones masivas: aplicar `receta_id` y vigencia a selección.  
**Tareas IA:**  
- Componente `PosMapTable` con **DataTable Enterprise**.  
- Servicio `GET /api/pos/pending` (usa v6.1 y v6.1b).  
- Writer `POST /api/pos/map/bulk`. Documentar en `UI_Mapping_README.md`.

---

### 3.3 Consumo POS & Reproceso
**Ruta:** `/pos/consumo`  
**Propósito:** Visualizar expansión (`inv_consumo_pos/_det`), reprocesar pendientes, y auditar `mov_inv`.  
**Estado actual:** Verificaciones v6 (2,3,7) listas; UI no centraliza todo.  
**Problemas:** Falta de **paso a paso** e indicadores (qué falta, por qué, cómo resolver).  
**Mejoras:**  
- Stepper: `Expandido` → `Pendientes reproceso` → `Movimientos OK`.  
- Panel izquierdo: Filtros por fecha, sucursal, terminal.  
- Tabla central: pendientes (`requiere_reproceso=true`) con botón **Reprocesar** + notas.  
- Panel derecho: Historial de reprocesos (últimos 7 días) + difs.
**Tareas IA:**  
- Endpoint `POST /api/pos/reprocesar` (idempotente).  
- Log `selemti.reproceso_log` (si no existe, sólo documentar; no DDL en v6).  
- UI con `negotiated toast` de confirmación + refresco de verificaciones 2/3.

---

### 3.4 Snapshot Diario
**Ruta:** `/inventario/snapshot`  
**Propósito:** Asegurar cobertura por sucursal (v6.4) y revisar negativos (v6.5).  
**Estado actual:** Scripts v6 ok; UI parcial.  
**Problemas:** No hay **dashboard de cobertura** ni desglose por item.  
**Mejoras:**  
- KPIs: Items con movimiento / snapshoteados / faltantes.  
- Tabla `faltantes_en_snapshot` con CTA **Generar snapshot** (si política lo permite).  
- Gráfica líneas (7 días): total movs vs snapshots.  
**Tareas IA:**  
- `GET /api/snapshot/coverage?bdate&branch` (usa v6.4).  
- `GET /api/snapshot/negatives?bdate&branch` (usa v6.5).  
- Componente `SnapshotCoverage` + `NegativesTable`.

---

### 3.5 Conteos Físicos (Cierre)
**Ruta:** `/inventario/conteos`  
**Propósito:** Crear/listar/cerrar conteos (`inventory_counts/_lines`).  
**Estado actual:** Componente `InventoryCount\Index` lista; integración v6.8 pendiente de evidencias.  
**Problemas:** No hay **workflow claro** ni UI de captura rápida.  
**Mejoras:**  
- Lista: filtros por estado (Programado/En curso/Cerrado).  
- Editor: Captura rápida (scanner, búsqueda, +/-), diferencia teórica vs contada.  
- Cierre: diálogo de confirmación + **verificación v6.8** post-cierre = “0 abiertos”.  
**Tareas IA:**  
- Servicio `POST /api/counts/close` con validaciones.  
- UI `CountCapture` (teclado/lector) + export.

---

### 3.6 Recetas: Costeo & Snapshots
**Ruta:** `/recetas/costos`  
**Propósito:** Programar/revisar snapshots (`recipe_cost_history`).  
**Estado actual:** Tarea agendada; documentación v6; requiere visibilidad UI.  
**Problemas:** No hay **panel de evidencia** ni desglose de receta.  
**Mejoras:**  
- Scheduler Tile: cron 01:10 MX, último/next run, log (`Costos_Scheduler_Log_*.md`).  
- Tabla: recetas sin snapshot vigente a fecha (v6.6).  
- Drawer: desglose costo (MP, merma, mano de obra, overhead; si existe `extended`).  
**Tareas IA:**  
- `GET /api/recipes/missing-cost?date` (v6.6).  
- `GET /api/recipes/cost/:id?at=date` (history).  
- UI `RecipeCostPanel` + botón `Recalcular ahora` (controlado por permisos/plantilla).

---

### 3.7 Compras (Pedido Sugerido · Base)
**Ruta:** `/compras/sugerido`  
**Propósito:** Base dinámica para pedido sugerido usando POS + stock + parámetros.  
**Estado actual:** Parcial; hay docs de políticas (FORECAST, PRODUMIX).  
**Problemas:** Falta vista unificada con **simulador**.  
**Mejoras:**  
- Simulador: horizonte (días), política, mínimos/máximos, sucursal, proveedor.  
- Tabla: sugerido por MP (consumo POS x factor), override manual, notas.  
**Tareas IA:**  
- `GET /api/purchase/suggest?policy&horizon&branch` (read-only).  
- Export a CSV y generar `Orden preliminar` (si política permite).

---

### 3.8 Producción (BOM/Órdenes)
**Ruta:** `/produccion/ordenes`  
**Propósito:** Planear órdenes de producción desde demanda (ventas/forecast) y stock.  
**Estado actual:** Flujos documentados; UI fragmentada.  
**Problemas:** Falta generador guiado y check de insumos críticos.  
**Mejoras:**  
- Wizard 3 pasos: Demanda → BOM → Insumos críticos → Generar Orden.  
- KPIs: capacidad, mermas previstas, costo estimado.  
**Tareas IA:**  
- `GET /api/production/suggest?date&branch` (read-only); UI Wizard.

---

### 3.9 Reportes
**Ruta:** `/reportes`  
**Propósito:** Centralizar auditorías (v6) y KPIs.  
**Estado actual:** Disperso.  
**Mejoras:**  
- Pestañas: Auditoría SQL (v6), Inventario, Costos, POS.  
- Cada pestaña con `Download` y `Run Now`.  
**Tareas IA:** Componente `ReportsHub` con tabs y embebido de auditor v6.

---

### 3.10 Seguridad (Plantillas + Permisos)
**Ruta:** `/seguridad/plantillas`  
**Propósito:** Gestionar **plantillas** de permisos y excepciones por usuario.  
**Estado actual:** Existe en capturas; faltan patrones UI estándar.  
**Mejoras:**  
- Tabla Plantillas: nombre, descripción, #permisos, #usuarios asociados.  
- Drawer: toggles por permiso (agrupados), herencia, excepciones.  
- Vista Usuario: diff Plantilla vs. Excepciones (chip rojo si hay conflicto).  
**Tareas IA:**  
- `GET /api/security/roles` (plantillas), `GET /api/security/users/:id/overrides` (read-only).  
- UI `PermissionsMatrix`.

---

## 4) Matriz de Requerimientos → Agentes IA (Entradas mínimas + Artefactos)

| ID | Módulo | Entradas obligatorias | Artefactos esperados | Validación |
|----|--------|------------------------|----------------------|------------|
| A01 | Orquestador | v6.sql, servicios existentes | `OrchestratorStatusBar`, endpoints summary | Chips reflejan v6 OK |
| A02 | POS Mapping | v6 (1,1.b), tablas pos_map | `PosMapTable`, bulk map | Pendientes=0 |
| A03 | Consumo/Reproceso | v6 (2,3,7) | Stepper & reproceso | Post-run: 0 pendientes |
| A04 | Snapshot | v6 (4,5) | Coverage + negatives UI | KPI coherentes |
| A05 | Conteos | v6 (8) | Index + Capture + Close | 0 abiertos |
| A06 | Costos Recetas | v6 (6), cron | Panel costos + logs | Nuevos snapshots |
| A07 | Compras | políticas docs | Simulador | Export CSV |
| A08 | Producción | BOM docs | Wizard producción | Orden simulada |
| A09 | Reportes | v6 completo | ReportsHub | Export funciona |
| A10 | Seguridad | Plantillas, permisos | PermissionsMatrix | Diffs correctos |

---

## 5) Prompts listos (ahorro de tokens)

### Prompt Base para todos los agentes
```
Rol: Ingeniero(a) IA Full Stack (Laravel 11 + Livewire 3 + Tailwind).
No toques esquemas de BD. Reutiliza componentes del catálogo ERP.
Contexto: /docs/Orquestador (v6), BD public (read-only) + selemti.
Entrega limpia, productiva y probada (componentes + endpoints + readme).
```

### A02 · POS Mapping
```
Implementa /pos/map con tabs (Pendientes, Vigentes, Caducados, Todos).
Usa verification_queries_psql_v6.sql (bloques 1 y 1.b) para “Pendientes”.
Crea componente DataTable enterprise + Drawer de asignación de receta con vigencias.
Acciones masivas para asignar receta_id y fechas. Export CSV.
No modifiques esquemas. Documenta en UI_Mapping_README.md.
```

### A05 · Conteos
```
Implementa /inventario/conteos con filtros por estado, captura rápida y cierre.
Tras cierre, ejecuta verificación v6 (bloque 8) y muestra confirmación.
Export CSV de líneas. Sin cambios de esquema.
```

*(Incluye más prompts derivados según la Matriz A01–A10 cuando delegues).*

---

## 6) Roadmap v6 → v7 (Transición controlada)

1. **Unificación visual**: aplicar tokens y componentes catálogos en POS Map, Conteos, Orquestador.  
2. **Evidencias operativas**: cada acción genera un `.md` en `/docs/Orquestador/Evidencias/` con fecha.  
3. **KPIs mínimos**: snapshot coverage, pendientes reproceso, conteos abiertos, recetas sin snapshot.  
4. **Hardening UX**: accesibilidad, estados consistentes, loaders, vacíos amigables.  
5. **Escalabilidad**: tablas con 10k+ filas (server-side), filtros persistentes por usuario.

---

## 7) Checklist de Aceptación (por módulo)
- Navegación clara con breadcrumbs y barra de estado por verificación v6.
- DataTables con búsqueda, paginación, export y acciones por fila.
- Formularios en drawer con validación y ayuda contextual.
- Estados visuales coherentes (info/success/warn/error).
- Logs/Evidencias para acciones críticas (scheduler, cierres, reprocesos).
- Sin cambios de esquema. Sin deuda visual nueva.

---

## 8) Anexos (Referencias)
- `verification_queries_psql_v6.sql` (bloques 1,1.b,2,3,4,5,6,7,8)
- `*_COST_CALCULATION*.md`, `POS_CONSUMPTION_SERVICE.md`, `POS_REPROCESSING.md`
- Capturas de pantalla (mapa UI actual)
- `discover_schema_psql_v2.sql` y `verification_queries_psql_range.sql`

---

> **Nota final:** Esta guía es “ready-for-agents”: cada subsección trae lo mínimo necesario para producir, reutilizando piezas y validando con v6.
