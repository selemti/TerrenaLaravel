# COORDINACIÓN MULTI-AGENTE - Terrena POS Sprint Final

## 📋 RESUMEN EJECUTIVO

**Objetivo**: Completar Terrena POS esta semana con trabajo coordinado entre 3 agentes de IA.

**Agentes**:
- **CLAUDE CODE** - Frontend/UI + Coordinación
- **CODEX** - Backend/Servicios
- **QWEN** - Documentación/Validación

**Estado Actual**:
- ✅ Base de datos: 182 tablas validadas y funcionales
- ✅ Módulos completos: Recepciones, Transferencias, Login, Dashboard
- ⏳ Módulos pendientes: Inventory Counts, Production, Recipes, POS Consumption, Kardex UI

**🚨 RESTRICCIÓN CRÍTICA**: NINGÚN agente puede ejecutar migraciones o modificar esquema de BD.

---

## 🚀 INICIO RÁPIDO

### Para el Usuario (Coordinador Humano)

#### PASO 1: Iniciar QWEN (Hoy)
```
1. Abrir sesión con QWEN
2. Copiar contenido de: docs/AI_COORDINATION/QWEN_PROMPTS.md → PROMPT 1
3. Pegar en QWEN y ejecutar
4. Esperar resultado: docs/BD/INVENTARIO_SCHEMA_ACTUAL.md
```

#### PASO 2: Continuar QWEN (Hoy)
```
1. Copiar QWEN_PROMPTS.md → PROMPT 2
2. Pegar en QWEN y ejecutar
3. Esperar resultado: docs/CODE_VALIDATION/MODELS_VS_BD_VALIDATION.md
```

#### PASO 3: Iniciar CODEX (Mañana)
```
1. Abrir sesión con CODEX
2. Copiar contenido de: docs/AI_COORDINATION/CODEX_PROMPTS.md → PROMPT 1
3. Pegar en CODEX y ejecutar
4. Esperar resultado: app/Services/Inventory/InventoryCountService.php
```

#### PASO 4: Validar trabajo de CODEX
```bash
# Ejecutar test de integración creado por CODEX
php -r "require 'vendor/autoload.php'; \$app = require_once 'bootstrap/app.php'; \$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap(); require 'test_count_complete.php';"

# Resultado esperado: ✅ TEST 3 COMPLETADO
```

#### PASO 5: Claude crea Frontend
```
Claude creará automáticamente los componentes Livewire una vez que CODEX entregue los servicios.
```

---

## 📁 ESTRUCTURA DE ARCHIVOS

```
docs/AI_COORDINATION/
├── README.md                       ← Estás aquí (inicio rápido)
├── COORDINATION_STRATEGY.md        ← Estrategia completa detallada
├── QWEN_PROMPTS.md                 ← 5 prompts para QWEN (copiar/pegar)
├── CODEX_PROMPTS.md                ← 5 prompts para CODEX (copiar/pegar)
├── HANDOFFS.md                     ← Para pasar trabajo entre agentes
├── BLOCKERS.md                     ← Para reportar impedimentos
└── DAILY_STATUS_[DATE].md          ← Status diario de cada agente
```

---

## 🎯 PROMPTS DISPONIBLES

### Para QWEN (5 prompts)
1. **Documentar Esquema de BD** → `INVENTARIO_SCHEMA_ACTUAL.md`
2. **Validar Modelos vs BD** → `MODELS_VS_BD_VALIDATION.md`
3. **Documentar Flujos de Negocio** → `RECEPCIONES_FLOW.md`, `TRANSFERENCIAS_FLOW.md`
4. **Plan de Tests** → `INTEGRATION_TEST_PLAN.md`
5. **Review Seguridad/Performance** → `SECURITY_PERFORMANCE_REVIEW.md`

**Ver detalles**: `QWEN_PROMPTS.md`

### Para CODEX (5 prompts)
1. **InventoryCountService** → Servicio completo de conteos físicos
2. **ProductionService** → Servicio de órdenes de producción
3. **API Controllers** → Controllers REST para ambos servicios
4. **Tests Unitarios** → PHPUnit tests con mocks
5. **Tests de Integración** → Scripts tipo test_reception_complete.php

**Ver detalles**: `CODEX_PROMPTS.md`

### Para CLAUDE (trabajo continuo)
Claude trabajará en:
- Componentes Livewire para módulos nuevos
- Integración de servicios de CODEX
- Vistas Blade (Bootstrap 5)
- Tests end-to-end
- Documentación de usuario

---

## ⚡ REGLAS DE ORO

### 1. Protección de Base de Datos
**NUNCA ejecutar**:
- ❌ `php artisan migrate`
- ❌ `ALTER TABLE`, `CREATE TABLE`, `DROP TABLE`
- ❌ Modificaciones de esquema sin aprobación de Claude

**Razón**: Incidente previo borró 159 tablas.

### 2. Seguir Patrones Validados
**Siempre usar como referencia**:
- ✅ `app/Services/Inventory/ReceptionService.php` (state machines)
- ✅ `app/Services/Inventory/TransferService.php` (transacciones)
- ✅ `test_reception_complete.php` (tests de integración)

### 3. Validar Antes de Avanzar
**Cada agente debe**:
- Ejecutar tests después de implementar
- Documentar lo que entrega
- Reportar blockers inmediatamente

---

## 📊 MÓDULOS Y ASIGNACIONES

| Módulo | Backend | Frontend | Docs | Prioridad | Estado |
|--------|---------|----------|------|-----------|--------|
| Recepciones | ✅ | ✅ | ✅ | - | COMPLETO |
| Transferencias | ✅ | ✅ | ✅ | - | COMPLETO |
| Inventory Counts | CODEX | CLAUDE | QWEN | ALTA | Pendiente |
| Production | CODEX | CLAUDE | QWEN | ALTA | Pendiente |
| Recipes | ✅ | CLAUDE | QWEN | ALTA | Backend listo |
| POS Consumption | CODEX | CLAUDE | QWEN | MEDIA | Pendiente |
| Kardex UI | ✅ | CLAUDE | QWEN | MEDIA | Solo UI falta |

---

## 🔄 FLUJO DE TRABAJO (Secuencial)

### Día 1-2: QWEN - Documentación
```
QWEN ejecuta PROMPT 1 → Esquema BD
QWEN ejecuta PROMPT 2 → Validación modelos
QWEN ejecuta PROMPT 3 → Flujos de negocio
QWEN ejecuta PROMPT 4 → Plan de tests
QWEN ejecuta PROMPT 5 → Review seguridad
```
**Output**: 5 documentos en `docs/`

### Día 2-4: CODEX - Backend
```
CODEX ejecuta PROMPT 1 → InventoryCountService
Usuario valida: test_count_complete.php
CODEX ejecuta PROMPT 2 → ProductionService
Usuario valida: test_production_complete.php
CODEX ejecuta PROMPT 3 → API Controllers
CODEX ejecuta PROMPT 4 → Tests unitarios
```
**Output**: Servicios funcionales y testeados

### Día 4-6: CLAUDE - Frontend
```
Claude crea Livewire/Counts/*
Claude crea Livewire/Production/*
Claude crea Livewire/Recipes/*
Claude integra con APIs de CODEX
Claude crea vistas Blade
```
**Output**: Interfaces completas

### Día 6-7: Integración
```
Tests end-to-end
Bug fixes
Performance tuning
Documentación final
```
**Output**: Sistema completo y deployable

---

## 📞 CÓMO REPORTAR PROBLEMAS

### Si un agente encuentra un blocker:

1. **Crear archivo**: `docs/AI_COORDINATION/BLOCKERS.md`
2. **Formato**:
```markdown
# BLOCKER - [Agente] - [Fecha]

## Descripción
[Qué está bloqueado]

## Contexto
[Qué se estaba haciendo]

## Error/Issue
[Mensaje de error o problema específico]

## Necesita
[Qué se necesita del coordinador o de otro agente]

## Prioridad
- [ ] CRÍTICO (detiene todo)
- [ ] ALTO (bloquea módulo)
- [ ] MEDIO (workaround posible)
```

3. **Notificar a coordinador humano**

---

## ✅ CHECKLIST DE INICIO

Antes de comenzar, verificar:

- [ ] Base de datos tiene 182 tablas (ejecutar: `\dt selemti.*` en psql)
- [ ] Tests existentes pasan:
  ```bash
  php -r "require 'vendor/autoload.php'; \$app = require_once 'bootstrap/app.php'; \$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap(); require 'test_reception_complete.php';"
  php -r "require 'vendor/autoload.php'; \$app = require_once 'bootstrap/app.php'; \$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap(); require 'test_transfer_complete.php';"
  ```
- [ ] Usuario soporte@selemti.com puede hacer login
- [ ] Dashboard carga sin errores
- [ ] Archivos de prompts están listos:
  - [ ] QWEN_PROMPTS.md
  - [ ] CODEX_PROMPTS.md
  - [ ] COORDINATION_STRATEGY.md

---

## 🎯 MÉTRICAS DE ÉXITO

Al final de la semana:

### Funcionalidad
- [ ] 8 módulos completos (4 nuevos + 4 existentes)
- [ ] Todos los tests passing (100%)
- [ ] 0 errores críticos en logs

### Base de Datos
- [ ] 182 tablas intactas
- [ ] 0 corrupciones
- [ ] Backup generado

### Documentación
- [ ] README.md actualizado
- [ ] API docs completo
- [ ] User guides creados
- [ ] Architecture documentada

### Calidad
- [ ] Performance < 500ms por request
- [ ] Seguridad validada por QWEN
- [ ] Code review aprobado

---

## 📚 REFERENCIAS RÁPIDAS

### Archivos Clave de Referencia
- `app/Services/Inventory/ReceptionService.php` - Patrón de servicios
- `app/Services/Inventory/TransferService.php` - Transacciones
- `app/Models/Inventory/TransferHeader.php` - Configuración PostgreSQL
- `test_reception_complete.php` - Patrón de tests

### Comandos Útiles
```bash
# Ver tablas de BD
psql -h localhost -p 5433 -U postgres -d pos -c "\dt selemti.*"

# Ejecutar test de integración
php -r "require 'vendor/autoload.php'; \$app = require_once 'bootstrap/app.php'; \$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap(); require 'test_reception_complete.php';"

# Ver logs en tiempo real
php artisan pail

# Tests unitarios
php artisan test

# Compilar assets
npm run build
```

### Estado de Módulos
Ver: `docs/SPRINTS/MASTER_SPRINT1_STATUS_V2.md`

---

## 🆘 SOPORTE

**Contacto**: Coordinador humano del proyecto

**En caso de emergencia**:
1. Detener todos los agentes
2. Documentar el problema en BLOCKERS.md
3. Notificar al coordinador
4. NO intentar fixes experimentales que afecten BD

---

**Preparado por**: Claude Code (CLAUDE-WORKER-FRONTEND-V4.1)
**Fecha**: 25-Nov-2025
**Versión**: 1.0
**Estado**: LISTO PARA EJECUCIÓN

---

## ▶️ SIGUIENTE PASO

**Usuario**: Ejecutar QWEN PROMPT 1

```
1. Abrir QWEN
2. Copiar todo el PROMPT 1 de docs/AI_COORDINATION/QWEN_PROMPTS.md
3. Pegar y ejecutar
4. Esperar archivo: docs/BD/INVENTARIO_SCHEMA_ACTUAL.md
```

¡Buena suerte! 🚀
