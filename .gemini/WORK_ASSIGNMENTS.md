# ASIGNACIÓN DE TRABAJO - PROYECTO TERRENA

Este archivo coordina el trabajo entre Claude, Codex y Gemini para evitar conflictos y duplicación.

## 🤖 Agentes Activos

### Claude Code (claude.ai/code)
**Rol:** Desarrollo UI/UX, Livewire Components, Frontend Integration
**Configuración:** `.claude/` + `CLAUDE.md`
**Especialización:**
- Componentes Livewire completos (Create, Index, Edit, Detail)
- Vistas Blade con Bootstrap 5
- Integración con servicios backend existentes
- Documentación completa de módulos
- Testing end-to-end de flujos

### Codex (GitHub Copilot Agent)
**Rol:** Backend Services, Business Logic, API Development
**Especialización:**
- Services layer (InventoryCountService, PurchasingService, etc.)
- Models Eloquent y relaciones complejas
- Migraciones de base de datos
- API Controllers
- Business logic y reglas de negocio

### Gemini CLI
**Rol:** Database Operations, Bug Fixes, Schema Management
**Configuración:** `.gemini/` + `GEMINI.md`
**Especialización:**
- Operaciones directas en PostgreSQL (esquema selemti)
- Corrección de inconsistencias BD vs Código
- Migraciones y seeders
- Debugging de queries SQL
- Normalización de datos

---

## 📋 TRABAJO ACTUAL (Octubre 2025)

### ✅ COMPLETADO

#### Claude:
- [x] Sistema de Caja Chica (6 componentes Livewire + docs completa)
- [x] Sistema de Conteos de Inventario (5 componentes + integración con InventoryCountService)
- [x] Integración PR #10 de Codex (merge con trabajo local)
- [x] Bug fix: almacen_id en recepcion_cab
- [x] Bug fix: Livewire layout config

#### Codex (PR #7-10):
- [x] InventoryCountService (backend completo)
- [x] PurchasingService (backend completo)
- [x] RecipeCostingService
- [x] MenuEngineeringService
- [x] AlertEngine
- [x] PosSyncService
- [x] Migraciones: inventory_counts, purchasing, costing_extension, pos_sync, etc.

### 🔄 EN PROGRESO

#### Gemini:
- [ ] **PRIORIDAD ALTA:** Verificar consistencia de `numero_recepcion` en recepcion_cab
  - Error conocido: `SQLSTATE[42703]: no existe la columna r.numero_recepcion`
  - Archivo afectado: `app/Livewire/Inventory/ReceptionsIndex.php`
  - Acción: Determinar si agregar columna o ajustar código
  - Esquema: `selemti` (modificable libremente)

- [ ] Normalizar campos faltantes en tablas de inventario
  - Revisar todas las tablas `selemti.*` vs modelos Eloquent
  - Documentar inconsistencias encontradas
  - Proponer migraciones de corrección

### 📅 PENDIENTE (Backlog)

#### Claude (Próximos módulos UI):
1. **Purchasing Module** (SIGUIENTE)
   - 6 componentes Livewire
   - 3 vistas principales: Requests, Quotes, Orders
   - Integración con PurchasingService existente
   - Documentación completa

2. **Production Module**
   - Órdenes de producción
   - Integración con ProductionService

3. **Transfers Module**
   - Transferencias entre almacenes
   - Ya tiene componente Create, falta Dispatch y Receive

#### Codex (Próximos servicios backend):
- [ ] Optimización de RecipeCostingService
- [ ] Extensión de AlertEngine con más tipos de alertas
- [ ] API endpoints para reportes

#### Gemini (Próximas tareas DB):
- [ ] Auditoría completa de esquema `selemti`
- [ ] Optimización de índices en tablas grandes
- [ ] Implementar constraints faltantes
- [ ] Seeding de datos maestros (unidades, proveedores, etc.)

---

## 🚨 REGLAS DE COORDINACIÓN

### 1. Antes de Iniciar Trabajo
- **Revisar este archivo** para ver si alguien más está trabajando en el área
- **Actualizar la sección "EN PROGRESO"** con tu tarea
- **Hacer commit** del update a este archivo antes de empezar

### 2. Áreas de Responsabilidad

| Área | Claude | Codex | Gemini |
|------|--------|-------|--------|
| Modelos Eloquent | Lee | Crea/Edita | Lee |
| Livewire Components | Crea/Edita | No toca | Lee |
| Vistas Blade | Crea/Edita | No toca | Lee |
| Services (app/Services/) | Lee/Usa | Crea/Edita | Lee |
| Migraciones | Crea si necesita | Crea backend | Crea/Ejecuta |
| Esquema `selemti` | No modifica directamente | No modifica directamente | Modifica libremente |
| Esquema `public` | Solo lectura | Solo lectura | Solo lectura* |
| Routes (web.php) | Agrega rutas UI | Agrega rutas API | Lee |
| Documentación | Crea docs completas | Comenta código | Documenta cambios DB |

\* Con confirmación explícita del usuario

### 3. Flujo de Trabajo Típico

**Ejemplo: Nuevo módulo (Purchasing)**

1. **Codex** (si no existe):
   - Crea PurchasingService con lógica de negocio
   - Crea modelos Eloquent necesarios
   - Crea migraciones
   - Push a rama feature

2. **Gemini** (preparación DB):
   - Revisa migraciones de Codex
   - Ejecuta migraciones en dev
   - Verifica consistencia con esquema existente
   - Corrige cualquier inconsistencia

3. **Claude** (UI completa):
   - Crea componentes Livewire
   - Crea vistas Blade
   - Integra con PurchasingService
   - Agrega rutas en web.php
   - Agrega enlaces en menú
   - Documenta en docs/Purchasing/README.md
   - Testing end-to-end
   - Commit con documentación completa

### 4. Comunicación entre Agentes

**Dejar mensajes en commits:**
```bash
# Claude deja mensaje para Gemini:
git commit -m "feat(purchasing): UI completa

@gemini: Revisar si falta índice en purchase_orders.vendor_id
"

# Gemini responde:
git commit -m "fix(db): agregar índice en purchase_orders.vendor_id

@claude: Índice agregado, debería mejorar performance del listado
"
```

**Usar este archivo para coordinar:**
```markdown
### 🔄 EN PROGRESO

#### Gemini:
- [x] Agregar índice en purchase_orders.vendor_id
  - **Para Claude:** Ya está optimizado, puedes probar el listado

#### Claude:
- [ ] Testing de Purchasing Module
  - **Para Gemini:** Si encuentro queries lentas te aviso
```

---

## 📊 MÉTRICAS DE PROGRESO

### Módulos Completos (UI + Backend + DB)
- [x] Caja Chica (Cash Funds)
- [x] Conteos de Inventario (Inventory Counts)
- [x] Recepciones de Inventario (Inventory Receptions)
- [x] Catálogos (Unidades, Almacenes, Proveedores, Sucursales, Stock Policy)
- [x] Recetas (Recipes)
- [x] Lotes (Inventory Batches)
- [x] Alertas de Costo (Cost Alerts)
- [ ] Compras (Purchasing) - **SIGUIENTE**
- [ ] Producción (Production)
- [ ] Transferencias (Transfers) - 30% completo
- [ ] Reportes (Reports)

### Estado General del Proyecto
- **Funcionalidad:** 60% completo
- **Testing:** 30% completo
- **Documentación:** 70% completo
- **Performance:** 50% optimizado

---

## 🔧 COMANDOS ÚTILES

### Para verificar conflictos antes de commit:
```bash
# Ver quién modificó el archivo recientemente
git log -5 --oneline -- path/to/file

# Ver branches activos
git branch -a

# Ver último commit de cada agente
git log --all --author="Claude" -1 --oneline
git log --all --author="Codex" -1 --oneline
git log --all --author="Gemini" -1 --oneline
```

### Para sincronizar trabajo:
```bash
# Antes de empezar una tarea
git pull origin main
git log -10 --oneline  # Ver últimos cambios

# Después de completar
git add .
git commit -m "feat(module): descripción"
git push origin current-branch
```

---

## 📝 NOTAS IMPORTANTES

1. **Nunca modificar archivos core sin coordinación:**
   - `app/Providers/AppServiceProvider.php`
   - `config/database.php`
   - `routes/web.php` (coordinarse para evitar conflictos)
   - `.env` (nunca commitear)

2. **Respetar convenciones:**
   - Commits en español técnico
   - Código y comentarios en inglés/español según contexto
   - Documentación siempre en español

3. **Testing obligatorio:**
   - Claude: testing manual de UI
   - Codex: unit tests de services
   - Gemini: verificar integridad de datos post-migración

4. **Backup antes de operaciones destructivas:**
   - Siempre hacer branch antes de cambios grandes
   - Gemini: backup de tablas antes de ALTER/DROP
   - Claude: backup de componentes antes de refactor mayor

---

**Última actualización:** 2025-10-24
**Actualizado por:** Claude Code

