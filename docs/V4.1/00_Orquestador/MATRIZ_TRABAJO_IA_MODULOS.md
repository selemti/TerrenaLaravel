# MATRIZ_TRABAJO_IA_MODULOS.md  
Versión: 4.1

Matriz que determina qué IA es responsable de qué tarea, qué puede ejecutarse en paralelo, y qué depende de qué.

---

## 🧠 IA Activas

| IA | Rol Principal | Capacidad | Acceso BD | Notas |
|----|--------------|-----------|-----------|-------|
| Claude | Arquitecto + BD + auditoría | Muy alta | ✔️ | Alto costo de tokens |
| Qwen | BD + migraciones | Alta | ✔️ | Excelente para SQL |
| Codex | Backend Laravel | Alta | ❌ | No accede BD directamente |
| Copilot | UI/UX + PHP asistido | Media | ❌ | Ideal para Livewire |

---

## 📌 MATRIZ MODULAR

| Módulo | Backend | BD | UI | Estado |
|--------|---------|-----|-----|--------|
| Inventario | CODEX | QWEN | COPILOT | DONE |
| Recetas | CODEX | QWEN | COPILOT | IN_PROGRESS |
| Producción | CODEX | QWEN | COPILOT | PENDING |
| Purchasing | CODEX | QWEN | COPILOT | IN_PROGRESS |
| POS | CLAUDE | QWEN | — | DONE |
| Caja | CLAUDE | — | COPILOT | DONE |
| Finanzas | CLAUDE | — | COPILOT | DONE |
| Reports | CLAUDE | — | — | DONE |
| Seguridad | CODEX | — | — | DONE |
| Catálogos | CODEX | — | COPILOT | DONE |

---

## 🔗 Dependencias Críticas

- **Codex NO puede continuar si Qwen no actualiza migraciones.**
- **Copilot espera a Codex para construir UI.**
- **Qwen siempre valida contra la BD real o dumps SELEMTI/PUBLIC.**

### Asignaciones activas (Sprint 1)

| Task_ID | IA Responsable | Estado | Última Act. |
|---------|----------------|--------|-------------|
| INV-001-QWEN-BD | QWEN | DONE ✅ | 2025-11-19 |
| INV-002-AUDIT | CLAUDE | DONE ✅ | 2025-11-20 |
| INV-002-CODEX-FIX | CODEX | DONE ✅ | 2025-11-23 00:52 |
| INV-003-AUDIT | CLAUDE | DONE ✅ | 2025-11-23 |
| INV-003-CODEX-FIX | CODEX | PENDING ⚠️ | - |
| REC-001-AUDIT | CLAUDE | DONE ✅ | 2025-11-19 |
| INV-001-CODEX-TEST | CODEX | POR_VALIDAR 🟡 | 2025-11-25 01:52 |

---

TODO: Cada IA debe actualizar esta matriz al terminar cada paso.
