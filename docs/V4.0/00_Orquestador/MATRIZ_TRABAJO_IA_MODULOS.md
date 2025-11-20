# MATRIZ DE TRABAJO MULTI-IA POR MÓDULOS (SPRINT 1 – V4.1)

Este archivo es la **fuente de verdad operativa** para el trabajo de las IAs
sobre Terrena V4.1.

## Leyenda

- **Estado**:
  - `PENDING`      → La tarea aún no se ha iniciado
  - `IN_PROGRESS`  → La IA está trabajando en ella
  - `DONE`         → Tarea completada y documentada
  - `BLOCKED`      → Hay un bloqueo externo (falta info, decisión, etc.)
  - `SKIP`         → Decidido no ejecutar por ahora

- **IA_Responsable**:
  - `QWEN`    → BD, migraciones, SQL, análisis de esquema
  - `CODEX`   → Servicios backend, jobs, API, lógica de negocio
  - `COPILOT` → UI (Livewire/Blade) y tests front
  - `CLAUDE`  → Diseño funcional/técnico, documentación de alto nivel
  - `MANUAL`  → Trabajo que hará Gustavo u otro humano

---

## TABLA MAESTRA DE TAREAS – SPRINT 1

> Nota: Esta tabla solo cubre **Sprint 1** (INV-001, INV-002, INV-003, REC-001).  
> Los siguientes sprints se agregan abajo en nuevas secciones.

| Task_ID             | Épica    | Módulo     | Área          | Tipo_trabajo | IA_Responsable | Estado    | Descripción breve                                                                 | Entradas_clave                                                                                                    | Salidas_sugeridas                                                                                      |
|---------------------|----------|-----------|--------------|--------------|----------------|-----------|------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| INV-001-QWEN-BD     | INV-001  | Inventario | Replenishment | BD           | QWEN           | PENDING   | Preparar estructura BD para motor de Replenishment (políticas, históricos, etc.).  | PLAN_SPRINT1_IMPLEMENTACION.md; Tablas.md; MAPA_BD_MODULOS.md; INTEGRACION_POS_BD.md                             | Migraciones Laravel; CHANGES_INV-001-QWEN-BD.md                                                        |
| INV-001-CODEX-SRV   | INV-001  | Inventario | Replenishment | Backend      | CODEX          | DONE      | ✅ Motor implementado (3 algoritmos: MIN_MAX, SMA, POS_CONSUMPTION). Job scheduler + API REST (6 endpoints). CORREGIDO: Usa ReplenishmentSuggestion (tabla existe en BD). | BD_SCHEMA_SELEMTI.sql; REFAC_PLAN_MODULOS.md; BD_CODIGO_MAPA*.md; Modelo ReplenishmentSuggestion existente | ✅ ReplenishmentService mejorado; ✅ Job CalculateReplenishmentSuggestions; ✅ ReplenishmentController (API REST); ✅ Rutas registradas; DEVLOG_SPRINT1_INV-001-CODEX-SRV.md |
| INV-001-COPILOT-UI  | INV-001  | Inventario | Replenishment | UI           | COPILOT        | SKIP      | UI dashboard de sugerencias de compra y explicación de cálculo.                   | Diseño UI (futuro); servicios backend listos; componentes existentes en Frontend                                  | Componentes Livewire/Blade; UI_Inv-001-Replenishment.md                                                |
| REC-001-QWEN-BD     | REC-001  | Recetas    | Versionado    | BD           | QWEN           | PENDING   | Ajustes BD para versionado real de recetas (históricos, flags, estados).          | PLAN_SPRINT1_IMPLEMENTACION.md; Tablas.md; Funciones.md; MAPA_BD_MODULOS.md                                      | Migraciones Laravel; CHANGES_REC-001-QWEN-BD.md                                                        |
| REC-001-CODEX-SRV   | REC-001  | Recetas    | Versionado    | Backend      | CODEX          | DONE      | ✅ RecipeVersionService implementado (5 métodos: createNewVersion, publishVersion, compareVersions, etc.). Backend completo, UI pendiente Copilot. | BD_SCHEMA_SELEMTI.sql; REFAC_Recetas_RESULTADOS.md; BD_CODIGO_MAPA*.md; Modelos Rec/* existentes | ✅ RecipeVersionService; DEVLOG_SPRINT1_REC-001-CODEX-BE.md |
| REC-001-COPILOT-UI  | REC-001  | Recetas    | Versionado    | UI+Tests     | COPILOT        | DONE      | Comparador de versiones, activador de versión y pruebas de integración para versionado. | RecipeVersionService.php; 02_BACKLOG_SPRINTS_V4.1.md                                                        | VersionComparator/Activator Livewire; RecipeVersioningTest.php; DEVLOG_SPRINT1_REC-001-COPILOT-UI.md  |
| INV-002-QWEN-BD     | INV-002  | Inventario | Recepciones   | BD           | QWEN           | PENDING   | Completar estados BORRADOR → VALIDADA → POSTEADA y campos relacionados.           | PLAN_SPRINT1_IMPLEMENTACION.md; Tablas.md; MAPA_BD_MODULOS.md; README.md (BaseDatos)                             | Migraciones; CHANGES_INV-002-QWEN-BD.md                                                                 |
| INV-002-CODEX-SRV   | INV-002  | Inventario | Recepciones   | Backend      | CODEX          | DONE      | ✅ State machine implementada (BORRADOR→VALIDADA→POSTEADA). ReceptionService extendido con 3 métodos. ⚠️ Requiere migraciones INV-002-QWEN-BD (columnas validada_por, posteada_por faltantes). | BD_SCHEMA_SELEMTI.sql; REFAC_Inventario_RESULTADOS.md; ReceptionService existente | ✅ ReceptionService extendido; DEVLOG_SPRINT1_INV-002-CODEX-SRV.md |
| INV-002-COPILOT-UI  | INV-002  | Inventario | Recepciones   | UI+Tests     | COPILOT        | DONE      | UI de estados, carga de evidencias y pruebas de integración para recepciones.     | ReceptionService.php; ReceivingService.php; Recepciones.md                                                    | ReceptionCreate/Detail Livewire; ReceptionStateTest.php; DEVLOG_SPRINT1_INV-002-COPILOT-UI.md         |
| INV-003-QWEN-BD     | INV-003  | Inventario | Transferencias| BD           | QWEN           | PENDING   | Estados SOLICITADA → DESPACHADA → RECIBIDA, más discrepancias y relaciones.       | PLAN_SPRINT1_IMPLEMENTACION.md; Tablas.md; MAPA_BD_MODULOS.md                                                    | Migraciones; CHANGES_INV-003-QWEN-BD.md                                                                 |
| INV-003-CODEX-SRV   | INV-003  | Inventario | Transferencias| Backend      | CODEX          | DONE      | ✅ Flujo completo implementado (SOLICITADA→APROBADA→EN_TRANSITO→RECIBIDA→POSTEADA). TransferService + TransferApiController + 7 endpoints REST. ⚠️ Requiere migraciones INV-003-QWEN-BD (columnas fecha_*, aprobada_por, posteada_por, observaciones). | BD_SCHEMA_SELEMTI.sql; REFAC_Inventario_RESULTADOS.md; TransferService existente | ✅ TransferService completo; ✅ TransferApiController; ✅ Rutas API; DEVLOG_SPRINT1_INV-003-CODEX-SRV.md |
| INV-003-COPILOT-UI  | INV-003  | Inventario | Transferencias| UI+Tests     | COPILOT        | DONE      | Interfaces de despacho/recepción de transferencias y pruebas de integración.      | TransferService.php; Transferencias.md                                                                         | TransferDispatch/Receive Livewire; TransferFlowTest.php; DEVLOG_SPRINT1_INV-003-COPILOT-UI.md         |

> Puedes actualizar **Estado** manualmente o dejar que cada IA lo vaya actualizando si tiene permisos para escribir el archivo.

---

## Notas de uso

- Cada IA debe:
  1. Leer esta tabla.
  2. Filtrar las filas donde `IA_Responsable` coincide con su nombre (QWEN, CODEX, etc.).
  3. Escoger la primera tarea con `Estado = PENDING`.
  4. Marcarla como `IN_PROGRESS` mientras trabaja.
  5. Al terminar, marcar como `DONE` y crear los archivos de salida en las rutas indicadas.

- Si una tarea está `BLOCKED`, debe incluirse la causa en `Salidas_sugeridas` o en un archivo de notas específico.
