# 00_MASTER_ORQUESTADOR_IA – Terrena V4.1

Este archivo define **cómo deben trabajar TODAS las IA** (Claude, Qwen, Codex, Copilot) en Terrena V4.1.

Siempre que una IA sea invocada para trabajar en este proyecto, debe:

1. **Leer este archivo completo**
2. **Leer**:
   - `docs/V4.1/00_Orquestador/PLAN_SPRINT1_IMPLEMENTACION.md`
   - `docs/V4.1/00_Orquestador/MASTER_SPRINT1_STATUS_V2.md`
   - `docs/V4.1/00_Orquestador/02_BACKLOG_SPRINTS_V4.1.md`
   - `docs/V4.1/00_Orquestador/01_MATRIZ_ALINEACION_V4.1.md`
3. Trabajar **sin pedir Task_ID al usuario**, tomando la siguiente tarea marcada como `PENDING` y asignada a su IA.

---

## 1. Jerarquía de verdad

Cuando haya conflicto de información, la jerarquía es:

1. **BD real PostgreSQL** (conectada vía `.env`)
2. **Dumps SQL**:
   - `database/BD_SCHEMA_PUBLIC.sql`
   - `database/BD_SCHEMA_SELEMTI.sql`
3. Documentación técnica más reciente:
   - `docs/V4.0/BaseDatos/*.md`
   - `docs/V4.0/Code/REFAC_*_RESULTADOS.md`
   - `docs/V4.0/Code/REFAC_*_CORRECCIONES_CLAUDE.md`
   - `docs/V4.0/Code/BD_CODIGO_MAPA_CAMPOS_ALL_NORMALIZADO.md`
4. Código Laravel:
   - `app/Services/**`
   - `app/Models/**`
   - `app/Http/**`
5. Docs de orquestador V4.1:
   - `00_CONTRATO_SISTEMA_TERRENA_v4.1.md`
   - `01_MATRIZ_ALINEACION_V4.1.md`
   - `02_BACKLOG_SPRINTS_V4.1.md`
   - `PLAN_SPRINT1_IMPLEMENTACION.md`
   - `MASTER_SPRINT1_STATUS_V2.md`
   - `MATRIZ_TRABAJO_IA_MODULOS.md`

**Regla de oro:**  
Está **PROHIBIDO** inventar nombres de tablas, columnas, funciones o vistas.  
Si un nombre no existe en BD real ni en los dumps, **no se usa**.

---

## 2. Reglas globales para TODAS las IA

1. **No inventar estructura de BD**
   - Antes de usar una tabla o columna:
     - Verificar en BD real (si tienes acceso)
     - O en `BD_SCHEMA_PUBLIC.sql` / `BD_SCHEMA_SELEMTI.sql`
   - Si no aparece, no lo uses y documenta el problema como ISSUE, no como implementación.

2. **Consumo mínimo de tokens**
   - No transcribir archivos completos.
   - Solo citar fragmentos estrictamente necesarios.
   - Referenciar rutas de archivos en vez de pegar contenido largo.

3. **Documentar TODO cambio**
   - Cada tarea debe generar un `DEVLOG` en:
     - `docs/V4.1/Code/` (para trabajo nuevo)
     - o `docs/V4.0/Code/` si es corrección sobre algo histórico claramente marcado.
   - Formato de archivo:  
     `DEVLOG_SPRINT1_<EPICA>-<IA>-<ROL>.md`  
     Ejemplo: `DEVLOG_SPRINT1_INV-001-CODEX-SRV.md`

4. **Actualizar estado de Sprint**
   - Al iniciar tarea: cambiar estado a `IN_PROGRESS`.
   - Al terminar: cambiar a `DONE` o `BLOCKED`.
   - Archivo maestro: `MASTER_SPRINT1_STATUS_V2.md`.

5. **No romper lo que ya está validado**
   - No modificar:
     - `ReplenishmentService.php` sin referenciar `DEVLOG_SPRINT1_INV-001-CLAUDE-FIX.md`.
     - Código y BD ya marcados como OK en `REFAC_*_CORRECCIONES_CLAUDE.md`.
   - Si detectas problema, crea un `ISSUE_*.md` en `docs/V4.1/Code/` y documenta.

---

## 3. Cómo elegir la siguiente tarea (sin preguntar al usuario)

Cada IA debe:

1. Abrir `docs/V4.1/00_Orquestador/MASTER_SPRINT1_STATUS_V2.md`.
2. Buscar su sección:

   - `[CLAUDE]` para Claude
   - `[QWEN]` para Qwen
   - `[CODEX]` para Codex
   - `[COPILOT]` para Copilot

3. En su sección, localizar la primera fila con:
   - `Estado = PENDING` **y**
   - `Bloqueador = -` (sin bloqueos) **o** bloqueador marcado como `DONE`.

4. Tomar esa fila como su **Task activa**.

5. Actualizar inmediatamente en el mismo archivo:
   - `Estado: PENDING → IN_PROGRESS`
   - `Ultima_actualizacion`: timestamp aproximado
   - Añadir una línea en el campo `Notas` tipo:
     - `IN_PROGRESS by CLAUDE (2025-11-19 HH:MM)`

---

## 4. Flujo de trabajo por IA

### 4.1 Claude (Arquitecto / BD / Auditoría)

- Enfocado en:
  - Auditorías BD ↔ Código
  - Correcciones complejas
  - Diseño de specs para otras IA

**Cuando tome una tarea:**

1. Validar siempre contra BD real y/o dumps.
2. Si corrige lógica crítica:
   - Generar DEVLOG con:
     - Evidencia SQL (queries + resultados)
     - Antes / Después
3. Marcar dependencias resueltas en `MASTER_SPRINT1_STATUS_V2.md`.

---

### 4.2 Qwen (BD / Migraciones / SQL)

- Enfocado en:
  - Migraciones pendientes
  - Scripts SQL de soporte (datasets mínimos)
  - Consultas de validación

**Reglas especiales:**

1. Antes de crear migración:
   - Confirmar que la estructura NO existe en BD ni en dumps.
2. No ejecutar DROP / TRUNCATE masivo.
3. Para datasets:
   - Respetar todas las FKs.
   - Intentar usar items reales existentes (`items`, `menu_item`, etc.).
4. Cada migración / script importante:
   - Documentarlo en `DEVLOG_SPRINT1_*_QWEN-BD.md`.
   - Si aplica, poner script en `docs/V4.1/BaseDatos/`.

---

### 4.3 Codex (Backend Laravel)

- Enfocado en:
  - `app/Services/**`
  - `app/Http/Controllers/**`
  - `routes/*`
  - Tests de backend

**Reglas especiales:**

1. Nunca definir un campo que no exista en BD real o dumps.
2. Antes de usar una columna:
   - Buscar en `BD_CODIGO_MAPA_CAMPOS_ALL_NORMALIZADO.md`.
3. Si el mapa dice `MISMATCH` o `FANTASMA`:
   - Revisar `REFAC_*_RESULTADOS.md` y `*_CORRECCIONES_CLAUDE.md`.
   - Aplicar lo que ya se definió ahí (no inventar una tercera versión).
4. Siempre que cree/ajuste servicios:
   - Intentar agregar tests (aunque sean básicos).

---

### 4.4 Copilot (UI / Livewire)

- Enfocado en:
  - Componentes Livewire 3
  - Vistas Blade
  - UX / validaciones en front

**Reglas especiales:**

1. Consumir SIEMPRE servicios y endpoints ya creados por Codex.
2. Leer previamente:
   - `PLAN_SPRINT1_IMPLEMENTACION.md`
   - `03_COMPENDIO_TECNICO_v4.1.md`
   - Documentos del módulo correspondiente en:
     - `docs/V4.0/Inventario/`
     - `docs/V4.0/Recetas/`
     - etc.
3. No inventar endpoints; usar los que existan en `routes/api.php` / `routes/web.php`.

---

## 5. Estructura de archivos de coordinación

### 5.1 Orquestador

- `00_CONTRATO_SISTEMA_TERRENA_v4.1.md` → Reglas generales del proyecto
- `01_MATRIZ_ALINEACION_V4.1.md` → Estado documental por módulo
- `02_BACKLOG_SPRINTS_V4.1.md` → Épicas y tareas por sprint
- `PLAN_SPRINT1_IMPLEMENTACION.md` → Alcance detallado del Sprint 1
- `MASTER_SPRINT1_STATUS_V2.md` → Estado vivo de tareas por IA (archivo maestro)
- `MATRIZ_TRABAJO_IA_MODULOS.md` → Mapa IA ↔ Módulos ↔ Tareas

### 5.2 Devlogs y resultados

- `docs/V4.1/Code/DEVLOG_*.md` → Nuevas implementaciones Sprint 1+
- `docs/V4.0/Code/REFAC_*_RESULTADOS.md` → Refactor BD↔Código (histórico, pero vinculante)
- `docs/V4.0/Code/REFAC_*_CORRECCIONES_CLAUDE.md` → Correcciones validadas por Claude

---

## 6. Reglas finales

1. **Siempre actualizar `MASTER_SPRINT1_STATUS_V2.md`** al inicio y al final de cada tarea.
2. **Nunca trabajar fuera de tu módulo** sin documentarlo y justificarlo en DEVLOG.
3. **Nunca inventar estructuras de BD.**
4. **Siempre dejar rastro**: DEVLOG + cambios documentados.
5. **Si hay duda entre V4.0 y V4.1**:
   - Preferir siempre V4.1 para orquestación.
   - Usar V4.0 como insumo técnico/histórico.

> Si este archivo y el backlog dicen cosas distintas, **manda lo que diga este archivo + BD real**.
