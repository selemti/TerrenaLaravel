# MASTER_SPRINT1_STATUS.md

## Sprint 1 – Estado Maestro de Implementación (Backend + BD + UI)

Este documento coordina el trabajo entre todas las IA (Codex, Qwen, Copilot, Claude).
Es la única fuente de verdad del Sprint 1.

---

## 1. Épicas del Sprint 1

### INV-001 – Motor de Replenishment
- Backend: DONE
- BD: DONE
- UI: PENDING
- Tests: PENDING

### REC-001 – Versionado Recetas
- Backend: DONE
- BD: PENDING (migraciones menores)
- UI: PENDING
- Tests: PENDING

### INV-002 – Recepciones (State Machine)
- Backend: DONE
- BD: PENDING (nuevas columnas)
- UI: PENDING
- Tests: PENDING

### INV-003 – Transferencias
- Backend: DONE
- BD: PENDING (nuevas columnas)
- UI: PENDING
- Tests: PENDING

---

## 2. Dependencias

- Qwen debe entregar las migraciones de BD antes de que Copilot implemente UI completa.
- Codex puede avanzar en TESTS inmediatamente.
- Claude puede validar BD y documentación sin bloquear a otros.
- Copilot debe leer los servicios ya hechos por Codex.

---

## 3. Tareas por IA

### QWEN – Migraciones
- Crear migraciones INV-002-QWEN-BD
- Crear migraciones INV-003-QWEN-BD
- Crear migraciones REC-001-QWEN-BD

Actualizar al terminar:
```
[QWEN]
INV-002-QWEN-BD: DONE/PENDING
INV-003-QWEN-BD: DONE/PENDING
REC-001-QWEN-BD: DONE/PENDING
```

---

### CODEX – Backend y Tests
- Crear tests unitarios para:
  - ReplenishmentService
  - RecipeVersionService
  - ReceptionService
  - TransferService

Actualizar al terminar:
```
[CODEX]
INV-001-CODEX-TEST: DONE/PENDING
REC-001-CODEX-TEST: DONE/PENDING
INV-002-CODEX-TEST: DONE/PENDING
INV-003-CODEX-TEST: DONE/PENDING
```

---

### COPILOT – UI Livewire
- UI Replenishment Dashboard
- UI Versionado Recetas
- UI Recepciones
- UI Transferencias

Actualizar al terminar:
```
[COPILOT]
UI_REPLENISHMENT: DONE/PENDING
UI_VERSIONADO_RECETAS: DONE/PENDING
UI_RECEPCIONES: DONE/PENDING
UI_TRANSFERENCIAS: DONE/PENDING
```

---

### CLAUDE – Documentación y Validación
- Documentar funciones SQL críticas
- Validación del Sprint
- Auditoría BD ↔ Código

Actualizar:
```
[CLAUDE]
BD_FUNCIONES: DONE/PENDING
SPRINT_VALIDACION: DONE/PENDING
```

---

## 4. Reglas de Trabajo

1. Cada IA **solo actualiza su bloque** en este archivo.
2. Ninguna IA puede borrar o modificar el trabajo de otra.
3. Todas las IA deben consultar este archivo ANTES y DESPUÉS de trabajar.
4. Este archivo se encuentra en:
   `docs/V4.1/00_Orquestador/MASTER_SPRINT1_STATUS.md`

---

## 5. Estado Global Actual

| Épica   | Backend | BD | UI | Tests | Estado Final |
|--------|---------|----|----|-------|--------------|
| INV-001 | DONE | DONE | PENDING | PENDING | 🔵 En progreso |
| REC-001 | DONE | PENDING | PENDING | PENDING | 🔵 En progreso |
| INV-002 | DONE | PENDING | PENDING | PENDING | 🔵 En progreso |
| INV-003 | DONE | PENDING | PENDING | PENDING | 🔵 En progreso |

---

## 6. Notas adicionales

- Ningún archivo fuera de su módulo puede ser modificado por una IA sin autorización del Orquestador.
- Las funciones existentes NO deben ser renombradas ni movidas.
- Las migraciones SIEMPRE deben respetar la BD real (BD_SCHEMA_SELEMTI.sql).

