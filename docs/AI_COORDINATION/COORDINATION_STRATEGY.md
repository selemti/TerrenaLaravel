# ESTRATEGIA DE COORDINACIÓN MULTI-AGENTE
**Proyecto**: Terrena POS - Sprint Final
**Objetivo**: Completar sistema completo esta semana
**Fecha**: 25-Nov-2025

## 🎯 META SEMANAL

**Completar 100% de Terrena POS** con trabajo coordinado entre:
- **CLAUDE CODE** (Frontend/UI)
- **CODEX** (Backend/Servicios)
- **QWEN** (Documentación/Validación)

**Deadline**: Fin de semana (7 días)

---

## 🚨 RESTRICCIÓN CRÍTICA: PROTECCIÓN DE BASE DE DATOS

### Incidente Previo
- Un agente ejecutó migraciones no coordinadas
- Resultado: Pérdida de 159 tablas (de 182 a 23)
- Recuperación costosa en tiempo y esfuerzo

### Regla de Oro
**NINGÚN AGENTE** puede ejecutar:
- ❌ `php artisan migrate`
- ❌ Queries DDL (ALTER, CREATE, DROP TABLE)
- ❌ Modificaciones directas de esquema
- ❌ Scripts SQL raw sin aprobación

### Base de Datos Actual (PROTEGIDA)
- **182 tablas** en schema `selemti`
- **35 vistas** materializadas
- **Estado**: VALIDADO y FUNCIONAL
- **Modificaciones**: Solo mediante coordinador (Claude Code)

---

## 👥 ROLES Y RESPONSABILIDADES

### CLAUDE CODE (CLAUDE-WORKER-FRONTEND-V4.1)
**Rol**: Coordinador General + Frontend

**Responsabilidades**:
- ✅ Coordinar trabajo entre agentes
- ✅ Crear componentes Livewire
- ✅ Diseñar interfaces (Bootstrap 5)
- ✅ Integrar servicios de CODEX con UI
- ✅ Aprobar/revisar trabajo de otros agentes
- ✅ **ÚNICO autorizado** para modificaciones de BD (si absolutamente necesario)
- ✅ Ejecutar tests de integración finales
- ✅ Documentar módulos completos

**NO HACE**:
- ❌ Backend services (lo hace CODEX)
- ❌ Documentación técnica de BD (lo hace QWEN)

**Archivos**:
- `app/Livewire/**/*`
- `resources/views/**/*`
- `routes/web.php`
- `docs/MODULES/**/*`

### CODEX (GitHub Copilot Agent)
**Rol**: Backend Developer

**Responsabilidades**:
- ✅ Implementar clases Service
- ✅ Crear Controllers API
- ✅ Escribir tests unitarios (PHPUnit)
- ✅ Crear tests de integración (patrón tinker)
- ✅ Validar lógica de negocio
- ✅ Seguir patrones de ReceptionService/TransferService

**NO HACE**:
- ❌ Modificar BD (ni migraciones ni queries DDL)
- ❌ Crear componentes Livewire
- ❌ Modificar vistas Blade

**Archivos**:
- `app/Services/**/*`
- `app/Http/Controllers/API/**/*`
- `app/Http/Requests/**/*`
- `tests/Unit/**/*`
- `test_*_complete.php`

### QWEN
**Rol**: Arquitecto de Documentación + QA

**Responsabilidades**:
- ✅ Documentar esquema de BD (SOLO lectura)
- ✅ Validar alineación código-BD
- ✅ Crear planes de test
- ✅ Review de seguridad y performance
- ✅ Documentar flujos de negocio
- ✅ Proveer esquemas para otros agentes

**NO HACE**:
- ❌ Modificar BD (SOLO comandos \d y SELECT)
- ❌ Implementar código
- ❌ Ejecutar tests que modifiquen datos

**Archivos**:
- `docs/BD/**/*`
- `docs/CODE_VALIDATION/**/*`
- `docs/BUSINESS_FLOWS/**/*`
- `docs/TESTING/**/*`

---

## 🔄 FLUJO DE TRABAJO COORDINADO

### Fase 1: QWEN - Documentación (Días 1-2)
**Input**: BD actual (182 tablas)
**Output**: Documentación completa

**Tareas** (ver QWEN_PROMPTS.md):
1. Documentar esquema de inventario → `INVENTARIO_SCHEMA_ACTUAL.md`
2. Validar modelos vs BD → `MODELS_VS_BD_VALIDATION.md`
3. Documentar flujos existentes → `RECEPCIONES_FLOW.md`, `TRANSFERENCIAS_FLOW.md`
4. Crear plan de tests → `INTEGRATION_TEST_PLAN.md`
5. Review de seguridad → `SECURITY_PERFORMANCE_REVIEW.md`

**Entregables para**:
- CODEX: Esquemas de BD para implementar servicios
- CLAUDE: Validaciones de modelos para UI

**Tiempo estimado**: 2 días

### Fase 2: CODEX - Backend (Días 2-4)
**Input**: Documentación de QWEN
**Output**: Servicios funcionales y testeados

**Tareas** (ver CODEX_PROMPTS.md):
1. Implementar InventoryCountService
2. Crear test_count_complete.php y ejecutar
3. Implementar ProductionService
4. Crear test_production_complete.php y ejecutar
5. Crear Controllers API
6. Tests unitarios (PHPUnit)

**Patrón de trabajo**:
```
Implementar Servicio → Test integración → Controller → Tests unitarios
```

**Entregables para**:
- CLAUDE: Servicios listos para integrar en Livewire
- QWEN: Código para review

**Tiempo estimado**: 3 días

### Fase 3: CLAUDE - Frontend (Días 4-6)
**Input**: Servicios de CODEX
**Output**: Interfaces completas

**Tareas**:
1. Crear Livewire components para Conteos
   - `app/Livewire/Counts/Index.php`
   - `app/Livewire/Counts/Create.php`
   - `app/Livewire/Counts/Detail.php`
   - `app/Livewire/Counts/Review.php`
2. Crear components para Producción
   - `app/Livewire/Production/Index.php`
   - `app/Livewire/Production/Create.php`
   - `app/Livewire/Production/Detail.php`
3. Integrar con APIs de CODEX
4. Crear vistas Blade (Bootstrap 5)
5. Tests end-to-end con UI

**Entregables**:
- Módulos completos funcionales
- Documentación de usuario

**Tiempo estimado**: 3 días

### Fase 4: Integración y QA (Días 6-7)
**Responsable**: CLAUDE (coordinador)
**Participan**: Todos

**Actividades**:
1. Tests de integración completos
2. Fixes de bugs encontrados
3. Optimizaciones de performance
4. Documentación final
5. Deploy a staging

---

## 📋 MÓDULOS PENDIENTES (Priorización)

### PRIORIDAD ALTA (Esta semana - OBLIGATORIO)
1. **Inventory Counts** (Conteos Físicos)
   - Backend: CODEX
   - Frontend: CLAUDE
   - Docs: QWEN
   - Estado: Pendiente

2. **Production Orders** (Órdenes de Producción)
   - Backend: CODEX
   - Frontend: CLAUDE
   - Docs: QWEN
   - Estado: Pendiente

3. **Recipes Management** (Gestión de Recetas)
   - Backend: Existe (por CODEX anterior)
   - Frontend: CLAUDE
   - Docs: QWEN
   - Estado: Backend listo, UI pendiente

### PRIORIDAD MEDIA (Si da tiempo)
4. **POS Consumption** (Consumo desde POS)
   - Backend: CODEX
   - Frontend: CLAUDE
   - Estado: Pendiente

5. **Kardex UI** (Interfaz de Movimientos)
   - Backend: Existe (mov_inv)
   - Frontend: CLAUDE
   - Estado: Solo UI pendiente

### COMPLETADOS ✅
- ✅ **Recepciones** (100% funcional)
- ✅ **Transferencias** (100% funcional)
- ✅ **Login/Auth** (100% funcional)
- ✅ **Dashboard** (100% funcional)

---

## 🔐 PROTOCOLO DE SEGURIDAD

### Antes de CUALQUIER ejecución
1. **CODEX**: ¿Vas a ejecutar migrate o DDL? → **DETENER** → Consultar a CLAUDE
2. **QWEN**: ¿Es un comando de escritura? → **DETENER** → Solo lectura permitida
3. **CLAUDE**: ¿Cambio afecta BD? → Documentar en DEVLOG antes de ejecutar

### Comandos PROHIBIDOS (para CODEX y QWEN)
```bash
❌ php artisan migrate
❌ php artisan migrate:fresh
❌ php artisan db:seed (si modifica tablas)
❌ psql -c "ALTER TABLE ..."
❌ psql -c "CREATE TABLE ..."
❌ psql -c "DROP TABLE ..."
```

### Comandos PERMITIDOS
```bash
✅ php artisan tinker (para tests)
✅ psql -c "\d tabla" (QWEN - inspección)
✅ psql -c "SELECT ..." (QWEN - lectura)
✅ php artisan test (tests unitarios)
```

---

## 📊 TRACKING DE PROGRESO

### Daily Standup (Simulated)
Cada agente reporta en `docs/AI_COORDINATION/DAILY_STATUS_[YYYYMMDD].md`:

```markdown
# Daily Status - [Fecha]

## QWEN
- ✅ Completado: [tareas]
- 🔄 En progreso: [tareas]
- ⏳ Bloqueado por: [dependencias]

## CODEX
- ✅ Completado: [tareas]
- 🔄 En progreso: [tareas]
- ⏳ Bloqueado por: [dependencias]

## CLAUDE
- ✅ Completado: [tareas]
- 🔄 En progreso: [tareas]
- ⏳ Bloqueado por: [dependencias]

## Issues
- [Problema 1]
- [Problema 2]
```

### Métricas de Éxito
- [ ] 5 prompts de QWEN ejecutados
- [ ] 5 prompts de CODEX ejecutados
- [ ] 3 módulos completos (Counts, Production, Recipes)
- [ ] 0 corrupciones de BD
- [ ] Tests passing: 100%
- [ ] Documentación completa

---

## 🚀 KICKOFF - Primeros Pasos

### PASO 1: QWEN inicia (HOY)
**Usuario ejecuta**:
```
Copiar y pegar PROMPT 1 de docs/AI_COORDINATION/QWEN_PROMPTS.md a QWEN
```

**Resultado esperado**: `docs/BD/INVENTARIO_SCHEMA_ACTUAL.md` creado

### PASO 2: QWEN continúa (HOY)
**Usuario ejecuta**:
```
Copiar y pegar PROMPT 2 de QWEN_PROMPTS.md a QWEN
```

**Resultado esperado**: `docs/CODE_VALIDATION/MODELS_VS_BD_VALIDATION.md` creado

### PASO 3: CODEX inicia (MAÑANA)
**Usuario ejecuta**:
```
Copiar y pegar PROMPT 1 de docs/AI_COORDINATION/CODEX_PROMPTS.md a CODEX
```

**Resultado esperado**: `app/Services/Inventory/InventoryCountService.php` creado

### PASO 4: Validación intermedia (MAÑANA)
**CLAUDE ejecuta**:
```bash
php -r "require 'vendor/autoload.php'; \$app = require_once 'bootstrap/app.php'; \$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap(); require 'test_count_complete.php';"
```

**Resultado esperado**: ✅ TEST 3 COMPLETADO

---

## 📞 COMUNICACIÓN ENTRE AGENTES

### Archivos de Coordinación
- `docs/AI_COORDINATION/HANDOFFS.md` - Para pasar trabajo entre agentes
- `docs/AI_COORDINATION/BLOCKERS.md` - Para reportar impedimentos
- `docs/AI_COORDINATION/QUESTIONS.md` - Para dudas técnicas

### Ejemplo de Handoff (CODEX → CLAUDE):
```markdown
# HANDOFF: InventoryCountService → UI

**De**: CODEX
**Para**: CLAUDE
**Fecha**: [Fecha]

## Servicio Completado
- Archivo: `app/Services/Inventory/InventoryCountService.php`
- Controller: `app/Http/Controllers/API/InventoryCountController.php`
- Tests: ✅ test_count_complete.php PASSING

## API Endpoints Disponibles
- POST /api/inventory/counts - Crear conteo
- POST /api/inventory/counts/{id}/lines - Agregar línea
- POST /api/inventory/counts/{id}/close - Cerrar
- POST /api/inventory/counts/{id}/post - Postear

## Formato de Request/Response
[Ver documentación en controller]

## Estado de BD
- Tabla: selemti.inventory_counts
- Relaciones: inventory_count_lines
- Estado: Validado y funcional

## Notas para Frontend
- State machine: ABIERTO → EN_PROGRESO → CERRADO → POSTEADO
- Varianzas se muestran solo después de CERRADO
- Solo POSTEADO afecta inventario
```

---

## ✅ CHECKLIST FINAL (Fin de Semana)

### Completitud de Módulos
- [ ] Inventory Counts: Backend ✅ Frontend ✅ Tests ✅ Docs ✅
- [ ] Production Orders: Backend ✅ Frontend ✅ Tests ✅ Docs ✅
- [ ] Recipes: Backend ✅ Frontend ✅ Tests ✅ Docs ✅
- [ ] POS Consumption: Backend ✅ Frontend ✅ Tests ✅ Docs ✅
- [ ] Kardex UI: Frontend ✅ Docs ✅

### Calidad
- [ ] Todos los tests passing
- [ ] 0 errores en Laravel log
- [ ] Performance aceptable (< 500ms por request)
- [ ] Seguridad validada por QWEN
- [ ] Documentación completa

### Base de Datos
- [ ] 182 tablas intactas
- [ ] 35 vistas funcionando
- [ ] Sin migraciones no coordinadas
- [ ] Backup generado

### Documentación
- [ ] README.md actualizado
- [ ] API docs (Swagger) completo
- [ ] User guides creados
- [ ] Technical architecture documentado

---

## 🎓 LECCIONES APRENDIDAS

### De Recepciones/Transferencias (Referencia)
1. **Siempre verificar BD antes de codificar** → Evita desalineaciones
2. **Tests de integración primero** → Valida que BD está lista
3. **State machines claras** → Facilita UI y debugging
4. **Audit trail completo** → usuario_id, validada_por, posteada_por
5. **Transacciones atómicas** → DB::transaction() para operaciones multi-tabla

### Aplicar a nuevos módulos
- ✅ Copiar patrón de ReceptionService
- ✅ Crear test_*_complete.php antes de UI
- ✅ Documentar estado de BD antes de implementar
- ✅ Validar con tests antes de entregar a CLAUDE

---

**Última actualización**: 25-Nov-2025
**Preparado por**: Claude Code (CLAUDE-WORKER-FRONTEND-V4.1)
**Estado**: LISTO PARA EJECUCIÓN
**Próximo paso**: Usuario ejecuta QWEN PROMPT 1
