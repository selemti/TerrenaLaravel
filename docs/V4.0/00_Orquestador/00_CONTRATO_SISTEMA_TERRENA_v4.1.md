# CONTRATO DEL SISTEMA TERRENA V4.1

**Orquestador**: MAESTRO
**Fecha**: 18 Noviembre 2025
**Versión**: 4.1 (POST-REFACTOR BD↔CÓDIGO)
**Estado**: ✅ COMPLETADO - BD y código 100% alineados

---

## 1. PROPÓSITO Y ALCANCE

Este contrato define las reglas de gobernanza, principios rectores y convenciones obligatorias para el desarrollo del sistema Terrena POS/ERP V4.0, un sistema integral de gestión gastronómica multi-sucursal.

### 1.1 Objetivo del Contrato

- Establecer fuente única de verdad (Single Source of Truth)
- Garantizar consistencia entre BD, código y documentación
- Definir roles y responsabilidades de agentes IA
- Proveer marco de trabajo para desarrollo multiagente
- Asegurar calidad y mantenibilidad del sistema

### 1.2 Audiencia

- Agentes IA: Claude, Qwen, Codex, Copilot
- Desarrolladores humanos nuevos
- Equipo de operaciones
- Stakeholders técnicos

---

## 2. PRINCIPIOS RECTORES

### 2.1 Principio de Verdad Única

**JERARQUÍA DE FUENTES DE VERDAD** (orden de prioridad):

1. **Base de Datos Real** (PostgreSQL 9.5 en producción)
   - Schema `selemti`: Modificable por Terrena
   - Schema `public`: READ-ONLY (Floreant POS legacy)
   - Extensiones Terrena en `public`: Vistas, funciones, triggers

2. **Documentación de BD** (docs/V4.0/BaseDatos/)
   - README.md - Overview arquitectura
   - Tablas.md - Catálogo completo de tablas
   - Funciones.md - Funciones SQL críticas
   - Vistas.md - Vistas por módulo
   - Triggers.md - Triggers activos
   - INTEGRACION_POS_BD.md - Integración POS
   - MAPA_BD_MODULOS.md - Mapeo BD ↔ Módulos

3. **Refactor BD↔Código** (docs/V4.0/Code/)
   - REFAC_RESUMEN_GLOBAL.md - Estado global post-refactor
   - REFAC_PLAN_MODULOS.md - Plan de refactor por módulo
   - REFAC_*_RESULTADOS.md - Resultados por módulo
   - BD_CODIGO_MAPA_CAMPOS_ALL_NORMALIZADO.md - Mapeo limpio

4. **Código Fuente**
   - Modelos Eloquent (app/Models/)
   - Servicios (app/Services/)
   - Migraciones (database/migrations/)

5. **Documentación V4.0** (docs/V4.0/)
   - Por módulo (Inventario/, Recetas/, POS/, etc.)
   - Orquestador (00_Orquestador/)

**Regla de Oro**: En caso de conflicto, prevalece el nivel superior de la jerarquía.

### 2.2 Principio de Modularidad Estricta

- **Cada módulo es autónomo**: Inventario, Recetas, Producción, Purchasing, POS, Caja, Finanzas, Catálogos, Seguridad
- **Interfaces bien definidas**: Servicios exponen contratos claros
- **Sin dependencias circulares**: Módulos de nivel inferior no conocen superiores
- **Comunicación por eventos**: Cuando sea posible, preferir eventos sobre llamadas directas

### 2.3 Principio de Mínima Modificación

- **No modificar código que funciona** sin razón válida
- **Cambios quirúrgicos**: Solo tocar lo estrictamente necesario
- **Respetar convenciones existentes**: No "mejorar" sin consenso
- **Documentar cambios**: Explicar el "por qué" de cada modificación

### 2.4 Principio de Consistencia

- **Nomenclatura uniforme**: Seguir convenciones Laravel y PostgreSQL
- **Patrones repetibles**: Usar mismos patrones para problemas similares
- **Estilo de código**: PSR-12 para PHP, PostgreSQL standards para SQL
- **Commits atómicos**: Un cambio lógico por commit

---

## 3. ARQUITECTURA Y STACK TECNOLÓGICO

### 3.1 Stack Backend

| Componente | Tecnología | Versión | Uso |
|------------|------------|---------|-----|
| Framework | Laravel | 12.x | MVC principal |
| Lenguaje | PHP | 8.2+ | Backend logic |
| Base de Datos | PostgreSQL | 9.5 (prod), 14+ (dev) | Dual schema |
| ORM | Eloquent | Laravel 12 | Modelos |
| Autenticación | JWT | tymon/jwt-auth | API auth |
| Permisos | Spatie Laravel Permission | 6.x | RBAC |
| API Docs | L5-Swagger | 8.x | OpenAPI 3.0 |

### 3.2 Stack Frontend

| Componente | Tecnología | Versión | Uso |
|------------|------------|---------|-----|
| UI Framework | Livewire | 3.7 beta | Reactive components |
| CSS Framework | Bootstrap | 5.3 | UI design system |
| JavaScript | Alpine.js | 3.x | Interactividad ligera |
| Build Tool | Vite | 5.x | Asset bundling |
| Charts | Chart.js | 4.x | Visualización datos |

### 3.3 Arquitectura Dual de BD

**PostgreSQL Dual Schema**:
```
├── public (Floreant POS - READ-ONLY para DDL original)
│   ├── ticket, ticket_item, transactions (POS core)
│   ├── menu_item, menu_category (Catálogos POS)
│   ├── terminal, sesion_cajon (Caja POS)
│   └── Extensiones Terrena:
│       ├── 32 vistas (vw_*, kds_*)
│       ├── 100+ funciones (fn_*, f_*)
│       └── 6 triggers (trg_*)
│
└── selemti (Terrena - LIBRE MODIFICACIÓN)
    ├── 147 tablas (112 activas, 35 legacy)
    ├── 38 vistas (reportes, KPIs)
    ├── 37 funciones (12 críticas)
    └── 20 triggers (integración, auditoría)
```

**Reglas de acceso**:
- `public`: Solo extensiones Terrena (vistas, funciones, triggers), NO modificar DDL de tablas originales
- `selemti`: Modificable para desarrollo, testing requerido antes de deployment
- Integración: Vía triggers y funciones específicas

### 3.4 Modularidad del Sistema

15 módulos funcionales:

**P0 (Críticos)**:
- Inventario (25 tablas) - Kardex, lotes, conteos
- Recetas (12 tablas) - Versionado, BOM, costeo
- Producción (10 tablas) - Órdenes, mise en place
- Purchasing (13 tablas) - Compras, replenishment
- POS (13 tablas) - Integración Floreant

**P1 (Importantes)**:
- Caja (10 tablas) - Sesiones, cortes, conciliación
- Caja Chica (6 tablas) - Fondos, movimientos
- Finanzas (8 tablas) - Cortes diarios, KPIs
- Reports (0 tablas propias, usa vistas)

**P2 (Soporte)**:
- Catálogos (8 tablas) - Unidades, proveedores, sucursales
- Seguridad (15 tablas) - Roles, permisos, auditoría
- Transferencias (4 tablas) - Inter-almacén
- Mermas (3 tablas) - Desperdicios
- Labor (2 tablas) - Mano de obra
- Sistema (12 tablas) - Laravel core

---

## 4. CONVENCIONES OBLIGATORIAS

### 4.1 Nomenclatura de BD

**Tablas**:
- Cabecera/Detalle: `*_cab` / `*_det` (ej: `po_cab`, `po_det`)
- Catálogos: `cat_*` (ej: `cat_unidades`, `cat_proveedores`)
- Históricos: `hist_*` o `historial_*`
- Auditoría: `*_audit_log`
- Vistas: `vw_*` o `v_*`
- Funciones: `fn_*` (business logic) o `f_*` (helpers)
- Triggers: `trg_*`

**Campos**:
- Primary Key: `id` (integer auto-increment)
- Foreign Keys: `*_id` (ej: `item_id`, `receta_id`)
- Timestamps: `created_at`, `updated_at`, `deleted_at`
- Activo/Inactivo: `activo` (boolean)
- Usuario que creó: `creado_por` (FK a users.id)
- Usuario que aprobó: `aprobado_por` (FK a users.id)

**Schemas**:
- `selemti.*` - Usar siempre nombre completo en modelos: `protected $table = 'selemti.tabla';`
- `public.*` - Usar para POS legacy

### 4.2 Nomenclatura de Código

**Modelos Eloquent**:
```php
namespace App\Models\Inventory;

class Item extends Model
{
    protected $connection = 'pgsql';  // OBLIGATORIO
    protected $table = 'selemti.items';  // OBLIGATORIO con schema
    protected $guarded = [];
    
    // Relationships
    public function category() { return $this->belongsTo(ItemCategory::class); }
    public function movements() { return $this->hasMany(MovInv::class); }
}
```

**Servicios**:
```php
namespace App\Services\Inventory;

class ReceptionService
{
    public function create(array $data): Reception { }
    public function validate(int $receptionId): bool { }
    public function post(int $receptionId): void { }
}
```

**Livewire Components**:
```php
namespace App\Livewire\Inventory;

class ReceptionCreate extends Component
{
    public $form;  // Usar Form Objects cuando sea posible
    
    public function save() { }
    public function render() { return view('livewire.inventory.reception-create'); }
}
```

**API Controllers**:
```php
namespace App\Http\Controllers\Api\Inventory;

class ItemController extends Controller
{
    public function index(Request $request): JsonResponse { }
    public function store(StoreItemRequest $request): JsonResponse { }
}
```

### 4.3 Convenciones de Git

**Commits**:
```
<tipo>(<módulo>): descripción corta

Descripción larga opcional
```

Tipos:
- `feat`: Nueva funcionalidad
- `fix`: Bug fix
- `refactor`: Refactorización sin cambio funcional
- `docs`: Solo documentación
- `test`: Agregar o modificar tests
- `chore`: Tareas de mantenimiento

Ejemplo:
```
feat(inventario): agregar state machine a recepciones

- Estados: BORRADOR, VALIDADA, POSTEADA
- Transiciones con permisos Spatie
- UI muestra estado actual
```

**Branches**:
- `main` - Producción
- `develop` - Development
- `feature/modulo-descripcion` - Features
- `fix/modulo-descripcion` - Bug fixes
- `refactor/modulo-descripcion` - Refactors

---

## 5. ROLES Y RESPONSABILIDADES DE AGENTES IA

### 5.1 Claude (Diseño y Arquitectura)

**Responsabilidades**:
- Diseño técnico de features (arquitectura, contratos)
- Revisión de UX y mensajes de error
- Documentación técnica de alto nivel
- Análisis de impacto de cambios
- Validación de consistencia documentación ↔ implementación

**Entregables típicos**:
- Specs técnicas (*.md)
- Diagramas de flujo
- Contratos de interfaces
- Documentación de arquitectura

**Ejemplo de tarea**:
- "Diseñar state machine para recepciones con estados, transiciones y permisos"
- Output esperado: `docs/V4.0/Inventario/RECEPTION_STATE_MACHINE.md`

### 5.2 Qwen (Base de Datos y SQL)

**Responsabilidades**:
- Diseño de schema BD (tablas, índices, constraints)
- Migraciones Laravel
- Funciones SQL complejas
- Triggers y automatizaciones
- Optimización de queries

**Entregables típicos**:
- Migraciones (`database/migrations/*.php`)
- Scripts SQL
- Documentación de funciones BD
- Análisis de performance

**Ejemplo de tarea**:
- "Crear migración para agregar estados a recepcion_det + tablas auxiliares"
- Output esperado: 3 archivos migration en `database/migrations/`

### 5.3 Codex (Backend y Lógica de Negocio)

**Responsabilidades**:
- Implementar servicios backend
- Crear modelos Eloquent
- Implementar API REST
- Lógica de negocio compleja
- Integración entre módulos

**Entregables típicos**:
- Servicios (`app/Services/**/*.php`)
- Modelos (`app/Models/**/*.php`)
- Controllers (`app/Http/Controllers/**/*.php`)
- Jobs (`app/Jobs/*.php`)

**Ejemplo de tarea**:
- "Implementar ReplenishmentService con algoritmos Min-Max, SMA, POS Consumption"
- Output esperado: `app/Services/Purchasing/ReplenishmentService.php`

### 5.4 Copilot (Frontend y Tests)

**Responsabilidades**:
- Implementar componentes Livewire
- Crear vistas Blade
- Escribir tests (Feature, Unit)
- Integración UI ↔ Backend
- Validación end-to-end

**Entregables típicos**:
- Componentes Livewire (`app/Livewire/**/*.php`)
- Vistas Blade (`resources/views/**/*.blade.php`)
- Tests (`tests/Feature/*.php`, `tests/Unit/*.php`)

**Ejemplo de tarea**:
- "Implementar Livewire VersionComparator con diff de ingredientes y costos"
- Output esperado: `app/Livewire/Recipes/VersionComparator.php` + blade

---

## 6. CICLO DE TRABAJO MULTIAGENTE

### 6.1 Flujo de Desarrollo de Feature

```
1. DISEÑO (Claude + Qwen)
   ├─ Spec técnica (Claude)
   ├─ Diseño BD (Qwen)
   └─ Revisión arquitectura (Claude)
   
2. IMPLEMENTACIÓN BD (Qwen)
   ├─ Migraciones
   ├─ Funciones SQL
   └─ Tests de migración
   
3. IMPLEMENTACIÓN BACKEND (Codex)
   ├─ Modelos Eloquent
   ├─ Servicios
   ├─ API Controllers
   └─ Tests unitarios
   
4. IMPLEMENTACIÓN FRONTEND (Copilot)
   ├─ Componentes Livewire
   ├─ Vistas Blade
   └─ Tests de integración
   
5. VALIDACIÓN (Todos)
   ├─ Revisión código (Claude)
   ├─ Tests E2E (Copilot)
   ├─ Performance (Qwen)
   └─ Documentación (Claude)
```

### 6.2 Handoff entre Agentes

**Artefactos de entrada/salida claros**:

Ejemplo: INV-002-D (Agregar lógica state machine a ReceptionService)

**Entrada** (de INV-002-C):
- `app/Models/Inventory/ReceptionTolerance.php` ✅
- `app/Models/Inventory/ReceptionAttachment.php` ✅
- `docs/V4.0/Inventario/RECEPTION_STATE_MACHINE.md` ✅

**Salida** (para INV-002-E):
- `app/Services/Inventory/ReceptionService.php` actualizado ✅
- Métodos: `validar()`, `postear()`, `validateTolerance()` ✅
- Tests unitarios passing ✅

### 6.3 Criterios de Aceptación

Toda subtarea debe cumplir:
- [ ] Código funcional (no comentarios "TODO: implementar")
- [ ] Tests passing (min 80% coverage para servicios críticos)
- [ ] Documentación inline (PHPDoc)
- [ ] Sin warnings de linter
- [ ] Commits atómicos con mensajes descriptivos
- [ ] Artefactos de salida entregados

---

## 7. PROCESO DE APROBACIÓN DE CAMBIOS

### 7.1 Cambios en BD (Schema selemti)

**Requieren**:
1. Migración Laravel (`database/migrations/`)
2. Documentación actualizada (`docs/V4.0/BaseDatos/Tablas.md`)
3. Tests de migración (rollback funcional)
4. Validación en staging antes de producción

**Aprobador**: Qwen (diseño) + Claude (validación arquitectura)

### 7.2 Cambios en Código Backend

**Requieren**:
1. Tests unitarios passing
2. No romper tests existentes
3. Respetar interfaces públicas (no breaking changes sin coordinación)
4. Documentación PHPDoc actualizada

**Aprobador**: Codex (implementación) + Claude (revisión)

### 7.3 Cambios en UI

**Requieren**:
1. UI funcional en todos los navegadores (Chrome, Firefox, Safari)
2. Responsive (mobile, tablet, desktop)
3. Loading states y error handling
4. Tests E2E passing

**Aprobador**: Copilot (implementación) + Claude (UX review)

### 7.4 Cambios en Documentación

**Requieren**:
1. Consistencia con código real
2. Formato Markdown correcto
3. Enlaces internos funcionando
4. Sin información obsoleta

**Aprobador**: Claude (owner de documentación)

---

## 8. GESTIÓN DE RIESGOS

### 8.1 Áreas Sensibles (NO modificar sin coordinación)

| Área | Riesgo | Coordinación Requerida |
|------|--------|------------------------|
| Funciones de costeo (`fn_recipe_cost_at`, etc.) | Impacto en reportes financieros | Testing extensivo + validación stakeholders |
| Triggers de integración POS | Rompe sincronización POS ↔ Terrena | Validación en staging con datos reales |
| Sistema UOM (77 migraciones) | Rompe conversiones de unidades | NO revertir, solo extender |
| Tablas de consumo POS | Lógica compleja de expansión recetas | Codex + Gemini (si aplica) |
| Migraciones en producción | PostgreSQL 9.5 vs 14 (dev) | Testear en staging PostgreSQL 9.5 |

### 8.2 Estrategia de Rollback

**Plan de rollback obligatorio para**:
- Migraciones que modifican tablas con >10K registros
- Cambios en funciones SQL críticas
- Cambios en triggers de integración
- Consolidación de servicios duplicados

**Elementos del plan**:
1. Script de rollback probado
2. Backup de datos afectados
3. Ventana de mantenimiento coordinada
4. Validación post-rollback

### 8.3 Testing Obligatorio

**Antes de deployment a producción**:
- [ ] Tests unitarios passing (min 80% coverage servicios críticos)
- [ ] Tests de integración passing
- [ ] Tests E2E en staging con datos reales
- [ ] Validación manual de features críticas
- [ ] Performance testing (si aplica)
- [ ] Rollback plan probado

---

## 9. DEPLOYMENT Y ENTORNOS

### 9.1 Entornos

| Entorno | URL | BD | Propósito |
|---------|-----|----|-----------| 
| **Local** | http://localhost/TerrenaLaravel | PostgreSQL 9.5 (puerto 5433) | Desarrollo |
| **Staging** | http://100.126.124.101/terrena2/ | PostgreSQL 14+ | Pre-producción |
| **Producción** | http://100.126.124.101/terrena2/ | PostgreSQL 14+ | Producción |

### 9.2 Configuración Apache Producción

```apache
Alias /terrena2 "/var/www/html/TerrenaLaravel/public"
<Directory "/var/www/html/TerrenaLaravel/public">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    RewriteBase /terrena2/
</Directory>
```

**⚠️ CRÍTICO**: Assets (CSS/JS) deben cargarse con `RewriteBase /terrena2/`

### 9.3 Checklist de Deployment

**Pre-deployment**:
- [ ] Tests passing en staging
- [ ] Backup de BD producción
- [ ] Plan de rollback preparado
- [ ] Ventana de mantenimiento coordinada
- [ ] Stakeholders notificados

**Deployment**:
- [ ] `git pull` en producción
- [ ] `php artisan migrate` (si aplica)
- [ ] `php artisan config:clear`
- [ ] `php artisan cache:clear`
- [ ] `npm run build` (si aplica)
- [ ] Verificar assets se cargan correctamente

**Post-deployment**:
- [ ] Smoke test de features críticas
- [ ] Verificar logs (sin errores)
- [ ] Validar con usuario final
- [ ] Documentar issues encontrados

---

## 10. MANTENIMIENTO Y EVOLUCIÓN

### 10.1 Revisión Periódica

**Semanal**:
- Revisión de commits de la semana
- Actualización de documentación si es necesario
- Limpieza de branches mergeados

**Mensual**:
- Revisión de cobertura de tests
- Análisis de performance (queries lentos)
- Revisión de tablas legacy para deprecación

**Trimestral**:
- Actualización de stack tecnológico (dependencies)
- Revisión de arquitectura (identificar mejoras)
- Auditoría de seguridad

### 10.2 Deprecación de Código Legacy

**Proceso**:
1. Identificar código legacy no usado (análisis estático)
2. Marcar como `@deprecated` con fecha y alternativa
3. Logging de uso en producción (si es posible)
4. Si uso = 0 por 1 mes → Eliminar en próximo release
5. Documentar en CHANGELOG

**Ejemplo**:
```php
/**
 * @deprecated Since 2025-11-18. Use ReceptionService::create() instead.
 */
public function createReception(array $data)
{
    \Log::warning('Deprecated method called: ReceptionService::createReception');
    return $this->create($data);
}
```

### 10.3 Versionamiento Semántico

Seguir SemVer 2.0.0:

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (0.X.0): Nuevas features (backward-compatible)
- **PATCH** (0.0.X): Bug fixes (backward-compatible)

Ejemplo:
- `4.0.0` → Versión inicial V4.0
- `4.1.0` → Motor Replenishment (nueva feature)
- `4.1.1` → Fix bug en cálculo de sugerencias

---

## 11. REFERENCIAS Y FUENTES DE VERDAD

### 11.1 Documentación Maestro

**Orquestador** (`docs/V4.0/00_Orquestador/`):
- ✅ CONTRATO_SISTEMA_TERRENA_v4.1.md (este documento)
- ✅ MATRIZ_ALINEACION_V4.1.md
- ✅ BACKLOG_SPRINTS_V4.1.md
- ✅ COMPENDIO_TECNICO_v4.1.md
- ✅ PLAN_SPRINT1_IMPLEMENTACION.md

**Base de Datos** (`docs/V4.0/BaseDatos/`):
- README.md - Overview
- Tablas.md - Catálogo completo
- Funciones.md - Funciones críticas
- Vistas.md - Vistas por módulo
- Triggers.md - Triggers activos
- INTEGRACION_POS_BD.md - Integración POS
- MAPA_BD_MODULOS.md - Mapeo BD ↔ Módulos

**Refactor BD↔Código** (`docs/V4.0/Code/`):
- REFAC_RESUMEN_GLOBAL.md - Estado post-refactor
- REFAC_PLAN_MODULOS.md - Plan por módulo
- REFAC_*_RESULTADOS.md - Resultados por módulo
- BD_CODIGO_MAPA_CAMPOS_ALL_NORMALIZADO.md - Mapeo limpio

### 11.2 Contactos

**Stakeholders**:
- **Owner del producto**: Gustavo Selem
- **Orquestador**: MAESTRO (consolidación multi-agente)
- **Agentes IA**: Claude, Qwen, Codex, Copilot

---

## 12. APÉNDICE: QUICK REFERENCE

### 12.1 Comandos Útiles

**Laravel**:
```bash
# Migrar BD
php artisan migrate

# Crear migración
php artisan make:migration create_tabla --create=tabla

# Crear modelo
php artisan make:model Models/Modulo/Clase

# Limpiar caches
php artisan config:clear && php artisan cache:clear

# Check BD consistency
php artisan check:db-code-consistency
```

**PostgreSQL**:
```bash
# Conectar a BD
psql -h localhost -p 5433 -U postgres -d pos

# Listar tablas
\dt selemti.*

# Ver definición de función
SELECT pg_get_functiondef('selemti.fn_recipe_cost_at'::regproc);

# Ver triggers de una tabla
\d+ selemti.precorte
```

**Git**:
```bash
# Feature branch
git checkout -b feature/inventario-recepciones-estados

# Commit
git commit -m "feat(inventario): agregar state machine a recepciones"

# Merge a develop
git checkout develop && git merge feature/inventario-recepciones-estados
```

### 12.2 Troubleshooting Común

**Error: "SQLSTATE[42P01]: Undefined table"**
- Verificar que `protected $table = 'selemti.tabla';` incluya schema
- Verificar que tabla exista: `\dt selemti.tabla`

**Error: "Assets no cargan en producción"**
- Verificar `RewriteBase /terrena2/` en `.htaccess`
- Regenerar assets: `npm run build`
- Limpiar cache: `php artisan config:clear`

**Error: "Trigger no se dispara"**
- Verificar que trigger esté activo: `\d+ selemti.tabla`
- Verificar permisos: `GRANT TRIGGER ON TABLE ...`
- Ver logs de BD para errores

---

**Última actualización**: 18 Noviembre 2025
**Versión del contrato**: 4.1
**Estado**: Alineación BD↔Código COMPLETADA ✅
