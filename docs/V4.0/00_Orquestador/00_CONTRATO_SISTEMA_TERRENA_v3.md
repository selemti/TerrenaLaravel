# CONTRATO SISTEMA TERRENA POS/ERP v3.0 - MAESTRO

**Orquestador**: Claude Code (Versión Maestra Unificada)
**Fecha**: 14 Noviembre 2025
**Fuentes**: Auditoría FASE1-FASE6 + Orquestadores QWEN/CODEX/COPILOT/CLAUDE
**Estado BD**: PostgreSQL 9.5, esquema `selemti` (147 tablas, 38 vistas, 37 funciones, 20 triggers)

---

## 1. DEFINICIÓN Y ALCANCE DEL SISTEMA

### 1.1 ¿Qué es Terrena?

**Definición Consolidada** (fusión 4 agentes):

> Terrena es un **ERP/POS integral para restaurantes multi-sucursal** que gestiona el ciclo operativo completo:
> - **Recepción de insumos** y control de inventario (kardex, lotes, transferencias)
> - **Costeo y producción de recetas** (versionado, BOM explosion/implosion)
> - **Registro de ventas POS** (integración Floreant, mapeo productos)
> - **Control financiero diario** (cortes de caja, precorte/postcorte, caja chica)
> - **Compras y replenishment** (solicitudes, órdenes, motor sugerencias)
> - **Reportes operativos** (KPIs, dashboards, exports)
>
> Proporciona una **plataforma unificada** para administración de recursos, control de costos en tiempo real y toma de decisiones basada en datos operativos consolidados.

### 1.2 ¿Qué NO es Terrena?

> Terrena NO es:
> - ❌ Un POS propio (integra con Floreant POS existente)
> - ❌ Sistema de contabilidad completa (solo operaciones de caja)
> - ❌ Sistema RRHH (solo usuarios y permisos operativos)
> - ❌ CRM o e-commerce
> - ❌ Sistema de reservaciones o delivery

### 1.3 Historia del Proyecto

**Origen** (QWEN insight):
Terrena comenzó como un sistema POS/ERP para restaurantes con el objetivo de integrar operaciones de inventario, producción, compras y reportes. A lo largo del desarrollo, se identificaron múltiples gaps entre la documentación y la implementación real del sistema.

**Auditoría 13 Noviembre 2025** (6 fases críticas):
1. **FASE 1**: Análisis documental completo (729 archivos: 486 /docs + 243 D:\Tavo\2025\UX\)
2. **FASE 2**: Revisión V4.0 vs compendio (73% cobertura, score 76%)
3. **FASE 3**: Estructura integrada propuesta (44 docs objetivo, 12 días roadmap)
4. **FASE 4**: Análisis código vs documentación (479 archivos, 61% cobertura, 39% huérfano)
5. **FASE 5**: Análisis BD selemti (147 tablas, 90% alineación, funciones críticas sin doc)
6. **FASE 6**: Evaluación UI/UX (score 6.5/10, gaps críticos en forms/notificaciones)

**Resultado**: Este contrato v3 consolida hallazgos de 4 orquestadores (CLAUDE, QWEN, CODEX, COPILOT) y auditoría completa.

### 1.4 Usuarios Clave del Sistema (7 roles confirmados)

| Rol | Módulos Principales | Permisos Clave |
|-----|---------------------|----------------|
| **Almacenista** | Inventario, Recepciones, Transferencias | inventory.*, receptions.*, transfers.* |
| **Comprador** | Purchasing, Proveedores | purchasing.*, vendors.* |
| **Chef / Producción** | Recetas, Producción, Mermas | recipes.*, production.*, wastes.* |
| **Cajero** | Caja, POS | cashfund.*, caja.precorte.* |
| **Gerente Sucursal** | Caja, Reportes, Inventario | caja.*, reports.view.*, inventory.view.* |
| **Controller** | Finanzas, Reportes, Aprobaciones | caja.postcorte.*, cashfund.approve.*, reports.* |
| **Administrador** | Todos, Seguridad | *.* (superadmin) |

### 1.5 Módulos del Sistema (15 confirmados - FASE1)

| # | Módulo | Implementación | Documentación | Prioridad | Estado |
|---|--------|----------------|---------------|-----------|--------|
| 1 | Inventario | 85% | 80% | 🔴 CRÍTICA | Bueno |
| 2 | Recetas | 75% | 70% | 🔴 CRÍTICA | Mejorable |
| 3 | Producción | 60% | 55% | 🟡 ALTA | Gaps importantes |
| 4 | Purchasing | 85% | 85% | 🔴 CRÍTICA | Bueno |
| 5 | POS | 70% | 60% | 🟡 ALTA | Mejorable |
| 6 | Ventas | 80% | 75% | 🔴 CRÍTICA | Bueno |
| 7 | Caja | 95% | 95% | ✅ CRÍTICA | Excelente |
| 8 | Caja Chica | 100% | 100% | ✅ CRÍTICA | Excelente |
| 9 | Reportes | 90% | 90% | ✅ ALTA | Excelente |
| 10 | Finanzas | 65% | 70% | 🟢 MEDIA | Mejorable |
| 11 | Base de Datos | 90% | 75% | 🟡 ALTA | Bueno |
| 12 | Frontend | 80% | 75% | 🟡 ALTA | Bueno |
| 13 | Seguridad | 80% | 75% | 🟡 ALTA | Bueno |
| 14 | Catálogos | 90% | 85% | ✅ MEDIA | Excelente |
| 15 | Transferencias | 75% | 60% | 🟡 ALTA | Mejorable |

**Promedio General**:
- Implementación: **80.3%**
- Documentación: **76.0%** → Objetivo: **94%**

---

## 2. FUENTE DE VERDAD Y ESTRUCTURA DOCUMENTAL

### 2.1 Documentación Canónica (Única Fuente Oficial)

**Ubicación**: `docs/V4.0/`

**Estado actual** (FASE2):
- 20 documentos markdown existentes
- 11/15 módulos cubiertos (73%)
- Score: 76% → Objetivo: 94%

**Estructura V4.0 Final** (44 documentos objetivo):

```
docs/V4.0/
├── README.md                            # Índice maestro
│
├── 00_Orquestador/                      # Gobernanza del sistema
│   ├── 00_CONTRATO_SISTEMA_TERRENA_v3.md    [ESTE ARCHIVO]
│   ├── 01_MATRIZ_ALINEACION_V4.0.md         [Matriz 15 módulos]
│   ├── 02_BACKLOG_SPRINTS_V4.0.md           [Backlog 8 sprints]
│   ├── 03_COMPENDIO_TECNICO.md              [Síntesis técnica]
│   ├── PLAN_ACTUALIZACION_V4.0.md           [Plan consolidación]
│   └── MATRIZ_DOCUMENTAL_ACTUALIZADA.md     [Análisis 44 docs]
│
├── Arquitectura/                        # Stack y convenciones
│   ├── README.md                        # Stack confirmado
│   └── Convenciones.md                  # Naming, PSR-12
│
├── BaseDatos/                           # Esquema selemti
│   ├── README.md                        # 147 tablas, 38 vistas
│   ├── Funciones.md                     # 37 funciones PL/pgSQL
│   ├── Vistas.md                        # 38 vistas detalladas
│   └── Triggers.md                      # 20 triggers activos
│
├── Catalogos/                           # Maestros
│   └── README.md                        # UOM, Almacenes, Proveedores
│
├── Seguridad/                           # Auth y permisos
│   └── README.md                        # Spatie + Policies
│
├── Inventario/                          # Gestión de stock
│   ├── Items.md                         # Catálogo items
│   ├── Recepciones.md                   # Recepciones compras
│   ├── Conteos.md                       # Conteos físicos
│   ├── Transferencias.md                # Transferencias inter-almacén
│   ├── Mermas.md                        # Mermas y desperdicios
│   ├── Disponibilidad.md                # Stock y KPIs
│   ├── Ajustes.md                       # Ajustes manuales
│   └── Kardex.md                        # mov_inv trazabilidad
│
├── Recetas/                             # Recetario
│   ├── README.md                        # Visión general
│   ├── Versionado.md                    # RecetaVersion
│   ├── Costeo.md                        # RecipeCostingService
│   └── Mapeo_POS.md                     # pos_map, sync-pos
│
├── Produccion/                          # Cocina
│   ├── README.md                        # ProductionService
│   ├── Ordenes.md                       # production_orders
│   └── Mermas.md                        # Mermas producción
│
├── Purchasing/                          # Compras
│   ├── README.md                        # Motor replenishment
│   ├── Replenishment.md                 # inv_stock_policy
│   └── Recepciones_Compras.md           # ReceivingService
│
├── POS/                                 # Integración Floreant
│   ├── README.md                        # Mapeo y consumos
│   └── Consumos.md                      # PosConsumptionService
│
├── Caja/                                # Operación diaria
│   ├── HistoricoCortes.md               # KPIs cortes
│   └── REDIRECCION_DETALLE_A_WIZARD.md  # Wizard UI
│
├── Finanzas/                            # Control financiero
│   ├── README.md                        # DailyCloseService
│   ├── CajaChica.md                     # CashFund completo
│   └── Cortes.md                        # Precorte/Postcorte
│
├── Reports/                             # Reportería
│   ├── README.md                        # Visión general
│   ├── KPIs.md                          # 38 vistas, dashboards
│   └── Ventas.md                        # SalesDetailController
│
├── Frontend/                            # UI/UX
│   ├── Layout.md                        # Bootstrap 5
│   ├── Componentes.md                   # Design system
│   └── GapsUX_Criticos.md               # FASE6 gaps
│
└── Guia/                                # Desarrollo
    ├── Stack.md                         # Versiones confirmadas
    └── Deployment.md                    # Proceso de deployment
```

### 2.2 Auditorías y Referencias (Solo Lectura)

**NO modificar, solo consultar**:

**Auditorías**: `docs/00.history/auditorias/AUDITORIA_2025_11_13/`
- FASE1_COMPENDIO_DOCUMENTACION.md (729 archivos)
- FASE2_ANALISIS_V4.0.md (score 76%)
- FASE3_ESTRUCTURA_INTEGRADA.md (44 docs objetivo)
- FASE4_ANALISIS_CODIGO.md (479 archivos)
- FASE5_ANALISIS_BD_SELEMTI.md (147 tablas)
- FASE6_EVALUACION_UI_UX.md (score 6.5/10)
- RESUMEN_EJECUTIVO.md (consolidado)

**Orquestadores**: `docs/00.history/orquestadores/`
- CLAUDE/ (4 docs: contrato, matriz, backlog, compendio supremo)
- QWEN/ (4 docs: estructura modular)
- CODEX/ (4 docs: precisión técnica)
- COPILOT/ (4 docs: claridad gaps)

**Uso**: Referencia para consultas, NO reemplaza V4.0.

### 2.3 Proceso de Consolidación (00.history → V4.0)

**Regla de Oro**:
```
00.history/  →  [LEER, CONSOLIDAR]  →  docs/V4.0/  →  [ÚNICA FUENTE DE VERDAD]
```

**Pasos**:
1. Leer insights de 4 orquestadores
2. Fusionar con FASE1-FASE6
3. Crear/actualizar docs en V4.0/
4. V4.0 se convierte en única fuente oficial
5. 00.history permanece como referencia histórica (READ-ONLY)

---

## 3. ARQUITECTURA TÉCNICA CONFIRMADA

### 3.1 Stack Tecnológico (FASE4 + COPILOT + docs/V4.0/Guia/Stack.md)

| Componente | Tecnología | Versión Confirmada |
|------------|------------|-------------------|
| **Framework Backend** | Laravel | 12 |
| **PHP** | PHP | 8.2+ |
| **Base de Datos** | PostgreSQL | 9.5 |
| **Esquema Trabajo** | selemti | - |
| **Esquema Legacy** | public (Floreant) | READ-ONLY |
| **Frontend Framework** | Livewire | 3.7 beta |
| **UI Framework** | Bootstrap | 5.3 |
| **JavaScript** | Alpine.js | 3.x |
| **CSS (deprecado)** | Tailwind CSS | 3.x → migrar a Bootstrap |
| **Build Tool** | Vite | 4.x |
| **Autenticación** | JWT | tymon/jwt-auth |
| **Permisos** | Spatie Laravel Permission | - |
| **API Docs** | L5-Swagger | - |
| **Servidor Dev** | Apache/XAMPP | 2.4 |
| **WSL IP** | 172.24.240.1 | PostgreSQL desde host |
| **Servidor Producción** | Apache 2.4.58 | Ubuntu 22.04 |
| **URL Producción** | Alias Apache | `/terrena2` |

### 3.2 Base de Datos Selemti (FASE5 Completo)

**Estadísticas Globales**:
```
Tablas:              147 (65 con modelos Eloquent, 82 huérfanas)
Vistas:              38 (28 documentadas, 10 sin doc)
Funciones:           37 (12 documentadas, 25 críticas sin doc)
Triggers:            20 (15 documentados, todos activos)
Foreign Keys:        100+ relaciones
Tablas Legacy:       35 (24% del total, pendientes deprecación)
```

**Tablas Críticas Top 10** (por tamaño):
```
1. audit_log (224 kB)                    - Auditoría de cambios
2. sesion_cajon (152 kB)                 - Sesiones de caja
3. items (152 kB)                        - Catálogo de ítems
4. cat_uom_conversion (112 kB)           - Conversiones de unidades
5. mov_inv (104 kB)                      - Kardex (movimientos inventario)
6. cash_funds (96 kB)                    - Fondo fijo caja chica
7. replenishment_suggestions (96 kB)     - Sugerencias reabastecimiento
8. sessions (96 kB)                      - Sesiones Laravel
9. personal_access_tokens (96 kB)        - Tokens JWT
10. auditoria (88 kB)                    - Auditoría legacy
```

**Funciones Críticas NO Documentadas** (FASE5 - 🔴 P0):
```
1. fn_recipe_cost_at(recipe_id, fecha)         - Costeo recetas histórico (CORE)
2. fn_recipes_using_item(item_id)              - BOM Implosion (CLAVE)
3. fn_item_unit_cost_at(item_id, fecha)        - Costeo items (CORE)
4. fn_expandir_consumo_ticket(ticket_id)       - Expansión consumo POS (CORE)
5. recalcular_costos_periodo(inicio, fin)      - Recalculo masivo (CRÍTICO)
6. fn_stock_disponible(item_id, almacen_id)    - Stock disponible
7. fn_movimientos_kardex(item_id, ...)         - Movimientos kardex
8. fn_receta_rendimiento(receta_id)            - Rendimiento receta
9. fn_precorte_after_insert()                  - Trigger precorte
10. fn_postcorte_after_insert()                - Trigger postcorte
11. fn_audit_trigger()                         - Auditoría automática
12. fn_inventory_batch_before_update()         - Validaciones batch
```

**Vistas Clave** (38 total):
```
Dashboard:      vw_dashboard_* (13 vistas KPIs)
Caja:           vw_sesion_dpr, vw_conciliacion_* (7 vistas)
Inventario:     vw_kardex, vw_stock_resumen (5 vistas)
Reportes:       vw_report_sales_* (8 vistas)
POS:            vw_pos_map_resuelto (1 vista)
```

### 3.3 Dual Database Architecture

**SQLite** (opcional desarrollo):
- Connection: `database` (default Laravel)
- Uso: Desarrollo local opcional
- Estado: Configurado pero no usado en producción

**PostgreSQL 9.5** (producción):
- Connection: `pgsql` (REQUERIDO en todos los modelos)
- Esquemas:
  - **`selemti`**: Esquema de trabajo (libremente modificable)
  - **`public`**: Floreant POS legacy (READ-ONLY, NO modificar sin confirmación)

**Convención Modelos**:
```php
<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    protected $connection = 'pgsql';  // OBLIGATORIO
    protected $table = 'selemti.items';  // OBLIGATORIO con schema
    protected $guarded = [];

    protected $casts = [
        'activo' => 'boolean',
        'costo_promedio' => 'decimal:2',
        'created_at' => 'datetime',
    ];
}
```

### 3.4 Estructura de Código (FASE4 - 479 archivos)

**Estado General**:
- **Cobertura**: 61% documentado, 39% huérfano
- **Duplicación**: PosConsumptionService (3 ubicaciones), ProductionService (2)
- **Objetivo**: 80% cobertura

**Inventario Detallado**:
```
app/
├── Models/ (80 modelos)
│   ├── Caja/          SesionCajon, Precorte, Postcorte, Terminal
│   ├── Inv/           Item, InventoryBatch, MovimientoInventario
│   ├── Rec/           Receta, RecetaDetalle, RecetaVersion, RecetaShadow
│   ├── Pos/           Ticket, MenuItem, PosMap, Transaccion
│   ├── Core/          Auditoria, User, Role
│   ├── Purchasing/    PurchaseRequest, PurchaseOrder, VendorQuote
│   └── CashFund/      CashFund, CashFundMovement, CashFundSettlement
│
├── Services/ (34 servicios)
│   ├── Inventory/     ReceptionService, TransferService, ProductionService
│   ├── Purchasing/    PurchasingService, ReceivingService
│   ├── Costing/       RecipeCostingService
│   ├── Pos/           PosConsumptionService (🔴 TRIPLICADO)
│   ├── Caja/          AlertasService, AnalyticsService
│   └── Cash/          CashFundService, DailyCloseService
│
├── Http/Controllers/ (64 controladores)
│   ├── Api/Caja/      PrecorteController, PostcorteController, AlertasController
│   ├── Api/Inventory/ ItemsController, TransferController
│   ├── Api/Unidades/  UnidadesController
│   └── Reports/       SalesDetailController, BaseReportController
│
├── Livewire/ (58 componentes)
│   ├── Catalogs/      UnidadesIndex, AlmacenesIndex, ProveedoresIndex
│   ├── Inventory/     ItemsIndex, ReceptionsIndex, ReceptionCreate, LotsIndex
│   ├── Purchasing/    Requests/Index, Requests/Create, Orders/Index
│   ├── CashFund/      Index, Detail, Create, Movements, Settlements, Approvals
│   ├── InventoryCount/ Index, Create, Detail, Review
│   ├── Recipes/       RecipeEditor, RecipesIndex
│   ├── Pos/           PosMap
│   └── Transfers/     Index, Create
│
└── Helpers/
    └── CajaHelper.php  qp(), J(), ver() [auto-loaded]

database/migrations/ (76 migraciones)
resources/views/ (167 vistas Blade)
routes/
├── web.php         Rutas Livewire
└── api.php         REST APIs
```

**Código Huérfano** (189 archivos - 39%):
- 19 servicios sin doc
- 20 modelos sin doc
- 18 componentes Livewire sin doc
- 26 migraciones sin doc
- 87 vistas Blade sin doc

---

## 4. DEPLOYMENT Y PRODUCCIÓN (docs/V4.0/Guia/Deployment.md)

### 4.1 Arquitectura de Ambientes

**Ambiente Local (Desarrollo)**:
- Sistema Operativo: Windows 10/11
- Servidor Web: Apache 2.4 (XAMPP)
- PHP: 8.3
- Base de Datos: PostgreSQL 14+ (puerto 5433)
  - Host: 127.0.0.1 (local) o 172.24.240.1 (WSL)
  - Esquema: selemti
  - Usuario: postgres
- Ruta Proyecto: C:\xampp3\htdocs\TerrenaLaravel\
- URL Local: http://localhost/TerrenaLaravel

**Ambiente Producción (Ubuntu Server)**:
- Sistema Operativo: Ubuntu 22.04 LTS
- Servidor Web: Apache 2.4.58
- PHP: 8.x
- Base de Datos: PostgreSQL 14+ (puerto 5432)
  - Host: localhost
  - Esquema: selemti
  - Usuario: [según .env producción]
- Ruta Proyecto: /var/www/kds/terrenaPos/
- URLs Acceso:
  - Red Local: http://192.168.1.235/terrena2/
  - Tailscale VPN: http://100.126.124.101/terrena2/
- Usuario SSH: terrena

### 4.2 Proceso de Deployment

**Pre-requisitos**:
- ✅ WinSCP (transferencia archivos SFTP)
- ✅ PuTTY o plink (conexión SSH)
- ✅ Git (control de versiones)
- ✅ Composer (local para generar lock actualizado)
- ✅ npm (local para build assets)

**Archivos que SÍ se copian**:
```
✅ app/                          # Código PHP (controllers, models, services, livewire)
✅ resources/views/              # Vistas Blade/Livewire
✅ resources/js/                 # JavaScript (si cambió)
✅ resources/css/                # CSS (si cambió)
✅ routes/                       # Rutas web/api
✅ config/                       # Configuraciones (excepto .env)
✅ database/migrations/          # Nuevas migraciones
✅ database/seeders/             # Seeders actualizados
✅ public/build/                 # Assets compilados (npm run build)
✅ composer.json                 # Si hay nuevas dependencias
✅ composer.lock                 # SIEMPRE copiar con composer.json
✅ package.json                  # Si hay nuevas dependencias JS
✅ package-lock.json             # SIEMPRE copiar con package.json
```

**Archivos que NO se copian**:
```
❌ .env                          # Producción tiene su propia configuración
❌ vendor/                       # Se regenera con composer install
❌ node_modules/                 # Se regenera con npm install
❌ storage/logs/                 # Logs del servidor no se sobrescriben
❌ storage/framework/cache/      # Cache del servidor
❌ storage/framework/sessions/   # Sesiones activas
❌ .git/                         # Control de versiones (opcional)
❌ tests/                        # Tests no van a producción
❌ .gitignore, .editorconfig     # Configuración desarrollo
```

### 4.3 Configuración Apache Producción

```
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot /var/www/kds

    # Alias para Terrena
    Alias /terrena2 /var/www/kds/terrenaPos/public
    <Directory /var/www/kds/terrenaPos/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        DirectoryIndex index.php

        <FilesMatch "^\.env">
            Require all denied
        </FilesMatch>
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/kds_error.log
    CustomLog ${APACHE_LOG_DIR}/kds_access.log combined
</VirtualHost>
```

**Configuración .htaccess (CRÍTICO)**:
```
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On
    RewriteBase /terrena2/    # ← CRÍTICO: Debe coincidir con Alias Apache

    # Resto de la configuración...
</IfModule>
```

---

## 5. PRINCIPIOS RECTORES (CODEX P1-P4 + Extensiones)

### P1. Doc Antes de Code (CODEX)

**Toda funcionalidad DEBE documentarse en `docs/V4.0/` ANTES de implementar**:

```
Paso 1: Escribir especificación en docs/V4.0/{modulo}/
Paso 2: Diseñar BD (tablas, vistas, funciones)
Paso 3: Diseñar API (endpoints, requests, responses)
Paso 4: Implementar código (modelos, servicios, controladores)
Paso 5: Actualizar docs con detalles de implementación
```

**Ejemplo Correcto**:
```
1. Crear docs/V4.0/Recetas/Versionado.md con especificación completa
2. Diseñar tabla receta_version con columnas y relaciones
3. Crear migración database/migrations/2025_11_XX_create_receta_version.php
4. Implementar modelo app/Models/Rec/RecetaVersion.php
5. Implementar servicio app/Services/Recetas/RecipeVersionService.php
6. Crear componente Livewire app/Livewire/Recipes/VersionHistory.php
7. Actualizar docs/V4.0/Recetas/Versionado.md con ejemplos código
```

### P2. Integridad Histórica (CODEX)

**Ningún archivo en `docs/V4.0/` se elimina**. Archivos obsoletos se mueven a `docs/00.history/_reference/`.

**Trazabilidad Cruzada** (CODEX P3):
Cada documento debe enlazar:
- Código: archivos app/, routes/, resources/
- Base Datos: tablas, vistas, funciones (selemti.*)
- UI: componentes Livewire, vistas Blade
- APIs: endpoints /api/*

### P3. Consistencia Tríada Docs-Código-BD

Todo cambio DEBE reflejarse en tres dimensiones:

```
┌─────────────────┐
│  Documentación  │  docs/V4.0/  [PRIMERO]
│  (Especificación)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     Código      │  app/  [SEGUNDO]
│ (Implementación)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Base de Datos  │  selemti schema  [TERCERO]
│ (Estructura)    │
└─────────────────┘
```

### P4. Modularidad Estricta (QWEN)

**Cada módulo opera independientemente con interfaces claras**:

```
Módulo A ──[Interface/Contract]──> Módulo B

Ejemplos:
Inventario ──[ItemRepository]──> Recetas
Recetas ──[RecipeService]──> POS
POS ──[PosConsumptionService]──> Inventario (consumos)
```

**NO acoplar directamente**. Usar:
- Repositorios para queries
- Servicios para lógica de negocio
- Eventos Laravel para comunicación asíncrona

### P5. Backlog Centralizado (QWEN + Este Contrato)

**TODO el trabajo se registra en `02_BACKLOG_SPRINTS_V4.0.md`**:

```
Nivel 1: Roadmap 8 Sprints (Fase 1-5)
Nivel 2: User Stories por Sprint
Nivel 3: Tareas Técnicas por Story
Nivel 4: Subtareas (docs/código/BD)
```

**NO se trabaja fuera del backlog**. Nuevas necesidades → agregar al backlog → priorizar.

### P6. Regla de Oro para Agentes IA

**NO MODIFICAR carpetas/módulos fuera de asignación específica**:

```
Agente A asignado a: Inventario
✅ Puede modificar:
   - docs/V4.0/Inventario/
   - app/Models/Inv/
   - app/Services/Inventory/
   - app/Livewire/Inventory/
   - database/migrations/*_inventory_*

❌ NO puede modificar:
   - docs/V4.0/Caja/
   - app/Services/Caja/
   - Otros módulos sin aprobación

Excepción: Interfaces compartidas requieren coordinación con Orquestador
```

---

## 6. GAPS CRÍTICOS CONSOLIDADOS (FASE2-6 + 4 Agentes)

### 6.1 Código (FASE4 - 61% cobertura)

**🔴 CRÍTICO - Código Duplicado** (CLAUDE, CODEX):
```
1. PosConsumptionService.php - 3 ubicaciones:
   - app/Services/Pos/PosConsumptionService.php
   - app/Services/Inventory/PosConsumptionService.php
   - app/Services/Legacy/PosConsumptionService.php
   Impacto: Lógica inconsistente entre versiones
   Riesgo: Errores en cálculo de consumos POS
   Solución: Consolidar en app/Services/Pos/ (Sprint 1 - 4h)

2. ProductionService.php - 2 ubicaciones:
   - app/Services/Production/ProductionService.php (stub)
   - app/Services/Inventory/ProductionService.php (real)
   Solución: Consolidar en app/Services/Production/ (Sprint 7 - 4h)
```

**🔴 CRÍTICO - Código Huérfano** (189 archivos - 39%):
```
19 servicios sin documentar:
   - RecalcularCostosRecetasService, InventoryAdjustmentService, etc.

20 modelos sin documentar:
   - RecipeCostSnapshot, PosMap, AlertEvent, etc.

18 componentes Livewire sin documentar:
   - OrquestadorPanel, BatchTrackingIndex, etc.

26 migraciones sin documentar:
   - Octubre-Noviembre 2025

87 vistas Blade sin comentarios:
   - resources/views/components/ui/*
```

**Esfuerzo**: 116 horas (alcanzar 80% cobertura)

### 6.2 Base de Datos (FASE5 - 90% alineación)

**🔴 CRÍTICO - Funciones Sin Documentar** (12 de 37 - 32% cobertura):
```
fn_recipe_cost_at()              - Costeo recetas (CORE BUSINESS)
fn_recipes_using_item()          - BOM Implosion (FEATURE CLAVE)
fn_item_unit_cost_at()           - Costeo items (CORE BUSINESS)
fn_expandir_consumo_ticket()     - Expansión consumo POS (CORE)
recalcular_costos_periodo()      - Recalculo masivo (OPERACIÓN CRÍTICA)
fn_stock_disponible()            - Stock disponible
fn_movimientos_kardex()          - Movimientos kardex
fn_receta_rendimiento()          - Rendimiento receta
fn_precorte_after_insert()       - Trigger precorte
fn_postcorte_after_insert()      - Trigger postcorte
fn_audit_trigger()               - Auditoría automática
fn_inventory_batch_before_update() - Validaciones batch
```

**🟡 ALTO - Tablas Sin Modelo** (82 de 147 - 56% huérfanas):
```
pos_sync_logs, pos_sync_batches, alert_events, alert_rules,
job_recalc_queue, menu_engineering_snapshots, recipe_labor_steps,
recipe_overhead_allocations, item_cost_history, etc.
```

**🟡 ALTO - Tablas Legacy** (35 - 24%):
```
caja_fondo* (5), insumo* (5), almacen/bodega/sucursal (3),
usuario/rol (2), *_legacy (8), otras (12)
Plan: Deprecar en Sprint 7
```

**Esfuerzo**: 48 horas (alcanzar 95% alineación)

### 6.3 UI/UX (FASE6 - Score 6.5/10 → Objetivo 8.0/10)

**🔴 CRÍTICO - Gap 1: Forms Sin Loading States** (0% cobertura - 40 forms):
```
Problema: Usuario no sabe si form se está enviando
Riesgo: Doble submit, abandono de página, frustración
Componentes afectados:
  - ReceptionCreate, PurchaseRequestCreate, TransferCreate
  - ItemForm, RecipeEditor, CashFundCreate
  - [... 34 más]

Patrón actual (SIN feedback):
<button wire:click="save">Guardar</button>

Patrón esperado (CON feedback):
<button wire:click="save"
        wire:loading.attr="disabled"
        wire:target="save">
    <span wire:loading.remove wire:target="save">Guardar</span>
    <span wire:loading wire:target="save">
        <span class="spinner-border spinner-border-sm"></span>
        Guardando...
    </span>
</button>

Solución: Sprint 1 - 4 horas (6 min por form × 40 forms)
```

**🔴 CRÍTICO - Gap 2: Notificaciones Rotas** (70% falla silenciosa):
```
Problema: 3 patrones incompatibles, eventos sin listeners

Patrón 1 (funciona): session()->flash() → solo con redirect
Patrón 2 (ROTO): dispatch('toast') → NO HAY LISTENER
Patrón 3 (ROTO): dispatch('notify') → NO HAY LISTENER

Fragmentación detectada:
- 12 componentes: toastr.js (script no siempre cargado)
- 8 componentes: SweetAlert2 (versión legacy)
- 5 componentes: alert() nativo (no profesional)
- 17 componentes: sin notificación (fallo silencioso)

Resultado: Usuarios NO ven confirmaciones de éxito/error

Solución: Sistema unificado Toast Bootstrap 5 (Sprint 1 - 6h)
```

**🔴 CRÍTICO - Gap 3: Confirmaciones Delete** (50% sin confirmación - 15 componentes):
```
Problema: Operaciones destructivas sin confirmación
Riesgo: Pérdida de datos accidental

Componentes sin confirmación:
- ItemsIndex (delete item)
- UnidadesIndex (delete UOM)
- ProveedoresIndex (delete vendor)
- AlmacenesIndex (delete warehouse)
- RecipesIndex (delete recipe)
- PurchaseRequestsIndex (cancel request)
- TransfersIndex (cancel transfer)
- [... 8 más]

Solución: Modal confirmación estándar (Sprint 1 - 4h)
```

**🟡 ALTO - Gap 4: Modales Fragmentados** (2 patrones):
```
Patrón A: wire:ignore (50% componentes) - Mejor performance
Patrón B: Inline @if (50% componentes) - Más simple
Resultado: Experiencia inconsistente

Solución: Estandarizar Patrón A (Sprint 1 - 2h)
```

**🟡 ALTO - Gap 5: Layout Shift Permisos Async**:
```
Problema: Links aparecen/desaparecen al cargar permisos
Impacto: Core Web Vitals (CLS), mala UX
Componente: TerrenaHasPerm (sidebar)

Solución: Skeleton loaders (Sprint 1 - 4h)
```

**Esfuerzo Total UX**: 40-50 horas (alcanzar 8/10 score)

### 6.4 Documentación (FASE2 - 76% score)

**Faltantes Críticos** (25 documentos - 18 alta prioridad):
```
P0 (9 docs críticos):
- BaseDatos/README.md, Funciones.md, Vistas.md
- Catalogos/README.md
- Seguridad/README.md
- Frontend/GapsUX_Criticos.md
- 00_Orquestador/MATRIZ_ALINEACION_V4.0.md
- 00_Orquestador/BACKLOG_SPRINTS_V4.0.md
- 00_Orquestador/COMPENDIO_TECNICO.md

P1 (8 docs altos):
- Inventario/Ajustes.md, Kardex.md
- Recetas/Versionado.md, Costeo.md, Mapeo_POS.md
- Produccion/Ordenes.md, Mermas.md
- POS/Consumos.md

P2 (8 docs medios):
- Purchasing/Replenishment.md, Recepciones_Compras.md
- Finanzas/CajaChica.md, Cortes.md
- Reports/KPIs.md, Ventas.md
- Frontend/Layout.md (actualizar), Componentes.md (actualizar)
```

**Esfuerzo**: 56 horas (alcanzar 94% score, 44 docs totales)

---

## 7. ROLES Y RESPONSABILIDADES

### 7.1 Orquestador Maestro (Claude Code - Este Sistema)

**Responsabilidades**:
1. Coordinar el roadmap de actualización V4.0 (56h, 44 docs)
2. Alinear documentación con código y base de datos reales
3. Asegurar consistencia entre los 15 módulos
4. Gestionar backlog consolidado de 4 agentes
5. Mantener trazabilidad cruzada Docs-Código-BD
6. Garantizar calidad y coherencia de contenido

**Autoridad**:
- Definir la estructura documental V4.0
- Asignar prioridades P0/P1/P2
- Validar contenido con evidencia del sistema
- Aprobar cambios en documentos críticos

### 7.2 Agentes Colaboradores

**QWEN** (Modularidad y estructura):
- Enfoque: Arquitectura modular, interconexiones
- Responsabilidad: Análisis de conexiones entre módulos
- Apoyo: Historia del proyecto, lecciones aprendidas

**CODEX** (Precisión técnica):
- Enfoque: Análisis detallado del sistema actual
- Responsabilidad: Radiografía código (479 archivos), gaps UX (FASE6)
- Apoyo: Métricas de cobertura, huérfanos, duplicados

**COPILOT** (Claridad funcional):
- Enfoque: Funcionalidades confirmadas, claridad en gaps
- Responsabilidad: Stack tecnológico confirmado, BD selemti
- Apoyo: Documentación de funcionalidades operativas

### 7.3 Desarrolladores

**Reglas de trabajo**:
1. Todo cambio debe reflejarse en los 3 niveles (docs/código/BD)
2. Consultar 02_BACKLOG_SPRINTS_V4.0.md antes de comenzar trabajo
3. Documentar en docs/V4.0/ ANTES de implementar código
4. Enviar PRs solo con evidencia de trazabilidad cruzada
5. Usar convenciones de código definidas en Arquitectura/Convenciones.md

---

## 8. PLANIFICACIÓN ESTRATÉGICA

### 8.1 Roadmap V4.0 (56 horas, 3 semanas)

| Fase | Horas | Contenido | Prioridad | Responsable |
|------|-------|-----------|-----------|-------------|
| **Fase 1** | 8h | Documentos Orquestador (4 docs) | P0 | CLAUDE |
| **Fase 2** | 12h | Base de Datos (4 docs) | P0 | CLAUDE |
| **Fase 3** | 16h | Módulos Críticos (6 docs) | P0-P1 | CLAUDE |
| **Fase 4** | 12h | Sub-módulos (6 docs) | P1-P2 | CLAUDE |
| **Fase 5** | 8h | Refinamiento (5 docs) | P1-P2 | CLAUDE |
| **Total** | **56h** | **44 documentos** | - | - |

### 8.2 KPIs de Éxito

| Métrica | Actual | Objetivo | Indicador |
|---------|--------|----------|-----------|
| **Cobertura documental** | 76% | 94% | 44/44 docs completos |
| **Cobertura módulos** | 11/15 | 15/15 | Todos los módulos con docs |
| **Funciones BD documentadas** | 12/37 | 37/37 | 100% de funciones críticas |
| **Código huérfano** | 189 archivos | ≤20 archivos | 80%+ cobertura |
| **UX Score** | 6.5/10 | 8.0/10 | Gaps críticos resueltos |
| **Trazabilidad Docs-Código-BD** | 61% | 90% | Enlaces cruzados completos |

---

## 9. CICLO DE VIDA DE DESARROLLO

### 9.1 Proceso de Desarrollo

```
1. PLANIFICACIÓN (en 02_BACKLOG_SPRINTS_V4.0.md)
   ↓
2. DOCUMENTACIÓN (en docs/V4.0/{modulo}/)
   ↓
3. IMPLEMENTACIÓN (código y BD)
   ↓
4. VALIDACIÓN (trazabilidad docs-código-BD)
   ↓
5. PRUEBAS y ACEPTACIÓN
   ↓
6. DEPLOYMENT y MONITOREO (docs/V4.0/Guia/Deployment.md)
```

### 9.2 Criterios de Calidad

**Documentos deben incluir**:
- Descripción clara del módulo/submódulo
- Relación con otros módulos
- Referencias a código específico (rutas, métodos)
- Referencias a base de datos (tablas, vistas, funciones)
- Casos de uso y flujos principales
- Gaps conocidos y recomendaciones

**Código debe estar**:
- Cubierto por documentación en V4.0
- Alineado con especificaciones documentadas
- Acompañado de pruebas unitarias/integración
- Con evidencia de trazabilidad en comentarios

---

## 10. GESTIÓN DE CAMBIOS

### 10.1 Proceso de Aprobación

**Cambios P0 (Críticos)**:
- Requieren validación del Orquestador Maestro
- Se aprueban con PR + 2 reviewers + QA
- No se despliegan sin alineación docs-código-BD

**Cambios P1 (Altos)**:
- Requieren revisión del equipo técnico
- Se aprueban con PR + 1 reviewer + QA
- Documentación debe actualizarse antes de merge

**Cambios P2 (Medios)**:
- Requieren revisión técnica
- Se aprueban con PR + 1 reviewer
- Documentación puede actualizarse post-merge si justificado

### 10.2 Proceso de Validación

```
1. PR con evidencia de trazabilidad docs-código-BD
2. Validación de consistencia entre 3 niveles
3. PR + comentarios + revisiones
4. Aprobación + CI (tests, lint)
5. Despliegue + monitoreo + feedback
```

---

## 11. DEPLOYMENT Y MANTENIMIENTO

### 11.1 Proceso de Deployment

**Verificación Pre-Deployment**:
- Tests ejecutados: `php artisan test`
- Código limpio: `./vendor/bin/pint` (PSR-12)
- Migraciones probadas: `php artisan migrate:status`
- Assets compilados: `npm run build` (producción)
- Cache limpiado:
```
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
```

**Post-Deployment (SIEMPRE ejecutar)**:
- Actualizar dependencias Composer: `sudo -u www-data composer install --no-dev --optimize-autoloader`
- Ejecutar migraciones nuevas: `sudo -u www-data php artisan migrate --force`
- Limpiar caché Laravel: `sudo -u www-data php artisan config:clear`
- Optimizar para producción: `sudo -u www-data php artisan config:cache`
- Reiniciar queue workers: `sudo -u www-data php artisan queue:restart`

### 11.2 Indicadores de Salud

**Documentación**:
- Frecuencia de actualización de docs/V4.0/
- Cantidad de enlaces rotos (docs → código)
- Tasa de cobertura de nuevas funcionalidades

**Código**:
- Porcentaje de código documentado
- Número de archivos huérfanos
- Tasa de cumplimiento de convenciones

**Base de Datos**:
- Número de tablas sin modelo Eloquent
- Número de funciones sin documentación
- Consistencia entre estructura y documentación

### 11.3 Proceso de Actualización

**Mensual**:
- Revisión de alineación docs-código-BD
- Actualización de métricas de cobertura
- Identificación de nuevos gaps
- Revisión de backlog priorizado

**Trimestral**:
- Revisión estratégica de arquitectura
- Validación de principios rectores
- Ajuste de roadmap V4.0
- Reporte ejecutivo de estado

---

**Fecha de Aprobación**: 14 Noviembre 2025  
**Versión**: 3.0  
**Próxima Revisión**: 14 Diciembre 2025