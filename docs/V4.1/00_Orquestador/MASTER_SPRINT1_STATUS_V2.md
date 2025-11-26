# MASTER_SPRINT1_STATUS_V2 – Terrena V4.1

- Sprint: 1
- Objetivo: Cerrar inventarios, compras, recetas, producción y POS para flujo operativo base.
- Última actualización IA: 2025-11-25 (CLAUDE - INV-002 + INV-003 COPILOT-UI DONE)

Estados permitidos:
- PENDING
- IN_PROGRESS
- DONE
- BLOCKED
- POR_VALIDAR

---

## 1. Estado global por Épica (plantilla)

| Epica    | Tareas_totales | DONE | IN_PROGRESS | BLOCKED | PENDING | Comentario_resumen                    |
|----------|----------------|------|-------------|---------|---------|---------------------------------------|
| INV-001  | 4              | 3    | 0           | 0       | 1       | BE/BD/UI listos; tests creados pero POR_VALIDAR (driver DB faltante). Dataset BLOCKED (mp_id issue ISSUE-001). |
| REC-001  | 4              | 2    | 0           | 0       | 2       | Service versionado DONE ✅ (audit + backend), falta BD/UI/tests |
| INV-002  | 5              | 4    | 0           | 0       | 1       | Audit DONE ✅, backend corregido, UI DONE ✅ (CLAUDE 2025-11-25). Pendiente: tests CODEX (INV-002-CODEX-TEST). |
| INV-003  | 5              | 3    | 0           | 0       | 2       | Audit DONE ✅, Fix DONE ✅ (CODEX), UI DONE ✅ (CLAUDE 2025-11-25). Pendientes: tests + backend SRV. |
| POS-CORE | 3              | 2    | 0           | 0       | 1       | Refactor POS + correcciones hechos, falta tests/UI |
| Otros    | 0              | 0    | 0           | 0       | 0       | (Completar si se usan más épicas)     |

> Esta tabla es orientativa. Cada IA debe ajustar números cuando cierre/abra tareas abajo.

---

## 2. Bloques por IA

### [CLAUDE] – Arquitectura / BD / Auditoría

| Task_ID                 | Epica    | Descripcion breve                                 | Estado      | Bloqueador                 | Archivo_principal                                      | Ultima_actualizacion | Notas                                                                 |
|-------------------------|----------|---------------------------------------------------|-------------|----------------------------|--------------------------------------------------------|----------------------|------------------------------------------------------------------------|
| INV-001-CLAUDE-FIX      | INV-001  | Alinear ReplenishmentService con BD real         | DONE        | -                          | DEVLOG_SPRINT1_INV-001-CLAUDE-FIX.md                   | 2025-11-18           | Listo. No tocar salvo bug crítico documentado.                         |
| BD-AUDIT-REFAC-GLOBAL   | ALL      | Verificar que refactor 10 módulos siga válido    | DONE        | -                          | REFAC_RESUMEN_GLOBAL.md                                | 2025-11-18           | Hecho. Usar como referencia, no desalinear.                            |
| BD-VERIFICAR-DATASETS   | INV-001  | Verificar dataset REPLENISHMENT_DATASET_MIGRACION | BLOCKED     | mp_id extraction logic    | REPLENISHMENT_DATASET_MIGRACION.sql, DEVLOG_SPRINT1_INV-001-CLAUDE-BD-DATASET.md | 2025-11-19           | DONE audit, BLOCKED execution. Items.id format incompatible with mp_id extraction (línea 210). Requires dataset fix before execution. Ver DEVLOG completo.    |
| REC-001-AUDIT           | REC-001  | Auditar RecipeVersionService vs BD/dumps        | DONE        | -                           | RecipeVersionService.php, Funciones.md, Tablas.md      | 2025-11-19           | DONE by CLAUDE ✅ RecipeVersionService aprobado. No inventa columnas. Todos los campos existen en BD real (receta_cab, receta_version, receta_det). Ver DEVLOG_SPRINT1_REC-001-CLAUDE-AUDIT.md |
| INV-002-AUDIT           | INV-002  | Auditar ReceptionService vs BD/dumps            | DONE        | -                           | DEVLOG_SPRINT1_INV-002-CLAUDE-AUDIT.md                 | 2025-11-20 15:30     | DONE by CLAUDE ✅ Auditoría completada. Servicio tiene lógica correcta PERO 12 columnas fantasma críticas detectadas. BLOQUEADO para producción. Ver DEVLOG completo + ISSUE-002. |
| INV-003-AUDIT           | INV-003  | Auditar TransferService vs BD/dumps (preventivo) | DONE        | -                           | DEVLOG_SPRINT1_INV-003-CLAUDE-AUDIT.md                 | 2025-11-23 14:50     | DONE by CLAUDE ✅ Auditoría completada. 22+ columnas fantasma detectadas (transfer_cab: 10, transfer_det: 4, mov_inv: 8+). BLOQUEADOR CRÍTICO. Ver DEVLOG + ISSUE-003. Movement.php tiene errores transversales (afecta INV-002+003). |

> Claude debe tomar la primera tarea `PENDING` sin bloqueador, marcar `IN_PROGRESS`, y al terminar dejarla en `DONE` o `BLOCKED`.

---

### [QWEN] – BD / Migraciones / SQL

| Task_ID                 | Epica    | Descripcion breve                                      | Estado      | Bloqueador           | Archivo_principal                                | Ultima_actualizacion | Notas                                                                 |
|-------------------------|----------|--------------------------------------------------------|-------------|----------------------|--------------------------------------------------|----------------------|------------------------------------------------------------------------|
| INV-001-QWEN-BD         | INV-001  | Asegurar estructuras BD para Replenishment            | DONE        | -                    | BD_SCHEMA_SELEMTI.sql, Tablas.md, DEVLOG_SPRINT1_INV-001-QWEN-BD.md | 2025-11-19           | DONE by QWEN. Todas las estructuras validadas. 5 tablas core OK, 1 discrepancia no bloqueante (stock_policy legacy). Ver DEVLOG completo. |
| INV-002-QWEN-BD         | INV-002  | Migraciones/ajustes para state machine recepciones    | DONE        | INV-002-CODEX-FIX    | BD_SCHEMA_SELEMTI.sql, REFACT docs, Tablas.md, DEVLOG_SPRINT1_INV-002_QWEN-BD.md    | 2025-11-23 16:10     | DONE by QWEN (2025-11-23 16:10). Agregando columnas para state machine: validada_por/at, posteada_por/at. Migración: 2025_11_23_160000_add_state_machine_columns_to_recepcion_cab.php. Ver DEVLOG. |
| INV-003-QWEN-BD         | INV-003  | Migraciones/ajustes para transferencias               | DONE        | Claude INV-002-AUDIT | BD_SCHEMA_SELEMTI.sql, Tablas.md, DEVLOG_SPRINT1_INV-003_QWEN-BD.md                 | 2025-11-23 16:20     | DONE by QWEN (2025-11-23 16:20). Agregando columnas para state machine: validada_por/at, posteada_por/at. Migración: 2025_11_23_161500_add_state_machine_columns_to_traspaso_cab.php. Ver DEVLOG.                   |
| REC-001-QWEN-BD         | REC-001  | Migraciones menores para versionado de recetas        | DONE        | Claude REC-001-AUDIT | BD_SCHEMA_SELEMTI.sql, Funciones.md, Tablas.md, DEVLOG_SPRINT1_REC-001_QWEN-BD.md   | 2025-11-23 16:30     | DONE by QWEN (2025-11-23 16:30). Estructura de versionado de recetas verificada, ya está completa. No se requieren migraciones adicionales. Ver DEVLOG.          |

---

### [CODEX] – Backend Laravel

| Task_ID                    | Epica    | Descripcion breve                                             | Estado      | Bloqueador           | Archivo_principal                               | Ultima_actualizacion | Notas                                                                 |
|----------------------------|----------|----------------------------------------------------------------|-------------|----------------------|-----------------------------------------------|----------------------|------------------------------------------------------------------------|
| INV-001-CODEX-SRV          | INV-001  | Servicio Replenishment + API                                  | DONE        | -                    | ReplenishmentService.php, ReplenishmentController.php | 2025-11-18           | Funcional. No tocar sin leer ambos DEVLOG (CODEX-SRV y CLAUDE-FIX).   |
| INV-001-CODEX-TEST         | INV-001  | Tests básicos Replenishment                                   | POR_VALIDAR | Driver DB            | tests/Feature/…, DEVLOG_SPRINT1_INV-001-CODEX-TEST.md | 2025-11-25 01:52     | Tests creados (MIN_MAX, POS_CONSUMPTION, API). Ejecución pendiente: entorno sin driver SQLite; se requiere pdo_pgsql con BD de prueba o habilitar pdo_sqlite. |
| REC-001-CODEX-BE           | REC-001  | Backend versionado recetas (RecipeVersionService)             | DONE        | -                    | RecipeVersionService.php                       | 2025-11-19           | DONE by CODEX ✅ Service validado por CLAUDE. BD alineada, estructura correcta. Solo faltan tests (tarea separada). |
| INV-002-CODEX-SRV          | INV-002  | Backend state machine recepciones (ReceptionService)          | POR_VALIDAR | INV-002-CODEX-TEST  | ReceptionService.php, DEVLOG_SPRINT1_INV-002-CLAUDE-AUDIT.md | 2025-11-23 00:52     | Backend alineado a BD tras INV-002-CODEX-FIX. Pendiente ejecutar tests y ajustar UI. |
| INV-002-CODEX-FIX          | INV-002  | Corregir 12 columnas fantasma en ReceptionService            | DONE        | -                    | ReceptionService.php, ISSUE_INV-002-RECEPTION-COLUMNAS-FANTASMA.md | 2025-11-23 00:52     | DONE by CODEX (2025-11-23 00:52). Se alineó inventory_batch/mov_inv y se eliminó método legacy createReception. DEVLOG_SPRINT1_INV-002-CODEX-FIX.md. |
| INV-003-CODEX-FIX          | INV-003  | Corregir 22+ columnas fantasma en TransferService + modelos | DONE        | -                    | Movement.php, TransferService.php, TransferHeader.php, TransferLine.php, DEVLOG_SPRINT1_INV-003-CODEX-FIX.md | 2025-11-23 ~01:00    | DONE by CODEX ✅ Se corrigieron 37 errores (Movement, TransferHeader, TransferLine, TransferService). Opción A implementada. Re-check CLAUDE aprobatorio (DEVLOG_SPRINT1_INV-003-CLAUDE-RECHECK-V2.md): 100% alineado con BD. |
| INV-003-CODEX-SRV          | INV-003  | Backend flujo transferencias                                  | PENDING     | -                    | TransferService.php (u otro según backlog)     | -                    | DESBLOQUEADO ✅ (INV-003-CODEX-FIX DONE). Puede implementarse sobre código corregido. |

*(Donde fechas con `?` déjalas y que la primera IA que toque esa fila las actualice.)*

---

### [COPILOT] – UI / Livewire

| Task_ID                    | Epica    | Descripcion breve                                  | Estado      | Bloqueador             | Archivo_principal sugerido                      | Ultima_actualizacion | Notas                                                                |
|----------------------------|----------|----------------------------------------------------|-------------|------------------------|-------------------------------------------------|----------------------|----------------------------------------------------------------------|
| INV-001-COPILOT-UI        | INV-001  | Dashboard Replenishment (listado + filtros + detalle) | DONE        | -                      | Livewire\Replenishment\Dashboard.php, dashboard.blade.php | 2025-11-19           | DONE by COPILOT. Dashboard completo (95→370 líneas PHP, 70→392 líneas Blade). Features: 7 filtros + queryString, 6 estadísticas cards, acciones (aprobar/rechazar/convertir) con modales Bootstrap 5. Ver DEVLOG_SPRINT1_INV-001-COPILOT-UI.md |
| REC-001-COPILOT-UI        | REC-001  | UI comparador/publicador de versiones de recetas   | PENDING     | REC-001-QWEN-BD     | Livewire\Recetas\VersionManager.php            | -                    | Backend DONE ✅ Bloqueado por migraciones BD (QWEN). Tomar contratos desde RecipeVersionService. |
| INV-002-COPILOT-UI        | INV-002  | UI workflow recepciones (BORRADOR→VALIDADA→POSTEADA) | DONE        | -                      | ReceptionDetail.php, DEVLOG_FRONT_INV-RECEPTIONS-CLAUDE.md | 2025-11-25 14:30     | DONE by CLAUDE ✅ (2025-11-25 14:30 UTC-6). Alineación completa con ReceptionService validado. Removido ReceivingService legacy, actionApprove() eliminado. State machine UI: BORRADOR→VALIDADA→POSTEADA. Ver DEVLOG completo. |
| INV-003-COPILOT-UI        | INV-003  | UI transferencias (state machine completa)        | DONE        | -                      | TransferDetail.php, DEVLOG_FRONT_INV-TRANSFERS-CLAUDE.md | 2025-11-25 15:30     | DONE by CLAUDE ✅ (2025-11-25 15:30 UTC-6). Eliminados mocks de Index/Create (100% BD real). Creado TransferDetail con state machine: SOLICITADA→APROBADA→EN_TRANSITO→RECIBIDA→POSTEADA. 5 GAPs corregidos. Cobertura: 40%→100%. Ver DEVLOG completo. |

---

## 3. Reglas de actualización de este archivo

1. **Al iniciar una tarea**:
   - Cambiar `Estado` de `PENDING` → `IN_PROGRESS`.
   - Actualizar `Ultima_actualizacion`.
   - Añadir breve nota en `Notas` indicando IA y fecha.

2. **Al terminar**:
   - Cambiar `Estado` a `DONE` o `BLOCKED`.
   - Si es `BLOCKED`, especificar claramente en `Bloqueador` qué falta.
   - En `Notas`, indicar archivos modificados y DEVLOG generado.

3. **Prohibido borrar filas.**  
   - Si se cancela una tarea, poner `Estado=CANCELLED` y explicar en `Notas`.

4. **Si una IA detecta que algo de esta tabla es falso**:
   - Actualizarlo, pero:
     - Dejar nota indicando qué se corrigió.
     - Referenciar el DEVLOG/archivo que respalda el cambio.

---

## 4. Checkpoints del sprint (a usar por cualquier IA)

| Checkpoint       | Descripcion                                | Verificacion sugerida                                             | Estado     | Notas |
|------------------|--------------------------------------------|-------------------------------------------------------------------|-----------|-------|
| BD-RESTORED      | BD PostgreSQL en estado correcto           | Queries en Tablas.md + conteos básicos                           | DONE ✅   | 2025-11-19: Claude verificó estructura BD. selemti: 147 tablas, public: 108 tablas. Todas las tablas core existen y son compatibles con código. |
| INV-001-OK       | Motor replenishment estable                | Pruebas manuales + resultado no vacío cuando proceda             | BLOCKED ⚠️ | ReplenishmentService funcional (DEVLOG_SPRINT1_INV-001-CLAUDE-FIX.md), pero dataset bloqueado por mp_id issue. Ver ISSUE_INV-001-DATASET-MP-ID-FIX.md |
| REC-001-BE-OK    | Versionado recetas bien alineado           | Auditoría Claude + tests básicos Codex                           | DONE ✅   | 2025-11-19: RecipeVersionService auditado y aprobado. Estructura 100% alineada con BD. |
| INV-002-BE-OK    | Recepciones state machine estable          | Auditoría + corrección + tests                                   | POR_VALIDAR | 2025-11-23: Backend corregido (DEVLOG_SPRINT1_INV-002-CODEX-FIX.md). Faltan tests (INV-002-CODEX-TEST) y validación end-to-end. |
| INV-003-BE-OK    | Transferencias estables                    | Auditoría + tests                                                | POR_VALIDAR | 2025-11-23: Audit DONE ✅, Fix DONE ✅ (CODEX), Re-check CLAUDE aprobatorio ✅ (100% alineado con BD). Pendiente: tests CODEX (INV-003-CODEX-TEST). Ver DEVLOG_SPRINT1_INV-003-CLAUDE-RECHECK-V2.md |
| UI-CORE-READY    | UIs clave de Sprint 1 funcionando          | Navegación manual + pruebas de flujo completo                    | PENDING   |       |

> Cualquier IA puede actualizar estos checkpoints cuando tenga evidencia concreta (DEVLOG + pruebas).
