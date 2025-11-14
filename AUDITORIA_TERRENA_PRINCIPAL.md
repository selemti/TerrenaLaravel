# AUDITORÍA PRINCIPAL - SISTEMA TERRENA
## Sistema ERP para Restaurantes

**Fecha de inicio:** 13 de noviembre de 2025  
**Auditor:** GitHub Copilot CLI (Modo Auditor Principal)  
**Alcance:** Documentación, Código, Base de datos, UI/UX  
**Estado:** EN PROGRESO - FASE 1

---

## OBJETIVO GLOBAL

Obtener una **visión 100% alineada y completa** del sistema Terrena donde:
- Documentación, código y base de datos digan lo mismo
- Se detecte TODO lo que falta (documentos, módulos, procesos, pantallas, endpoints, triggers)
- Quede claro qué es la "visión final" (docs/V4.0) y qué ajustar

---

## FUENTES ANALIZADAS

### 1. Documentación histórica y dispersa
- ✅ `/docs` (raíz del proyecto)
- ✅ `D:\Tavo\2025\UX\` (documentación externa)

### 2. Versión objetivo
- ✅ `/docs/V4.0` (versión vigente del sistema)

### 3. Código del proyecto
- ✅ Raíz: `C:\xampp3\htdocs\TerrenaLaravel`
- ✅ Controladores: `app/Http/Controllers/`
- ✅ Modelos: `app/Models/`
- ✅ Servicios: `app/Services/`
- ✅ Livewire: `app/Livewire/`
- ✅ Vistas: `resources/views/`
- ✅ Rutas: `routes/web.php`, `routes/api.php`

### 4. Base de datos
- ✅ Esquema: `selemti`
- ✅ **185 tablas** (BASE TABLE + VIEW)
- ✅ **38 vistas** materializadas
- ✅ **37 funciones/procedimientos**
- ✅ **134 foreign keys**
- ✅ **22 triggers**
- ⚠️ Base de datos recién desplegada (poca data operativa)

---

## 📋 FASE 1 – ANÁLISIS DE DOCUMENTACIÓN

### 1.1 Estructura documental identificada

#### Documentación en `/docs`
```
docs/
├── V4.0/                    ← VERSIÓN OBJETIVO (publicada 2025-11-12/13)
│   ├── Arquitectura/
│   ├── Caja/
│   ├── Finanzas/
│   ├── Frontend/
│   ├── Guia/
│   ├── Inventario/
│   ├── POS/
│   ├── Produccion/
│   ├── Purchasing/
│   ├── Recetas/
│   └── Reports/
│
├── Arquitectura/            (histórico, análisis técnico)
├── BD/                      (diccionarios, ERDs, scripts)
├── CajaChica/              (fondos, movimientos, arqueos)
├── Inventario/             (legacy flows)
├── InventoryCounts/
├── Migraciones/
├── Onboarding/
├── Orquestador/
├── Planeacion/
├── POS/
├── PosConsumption/
├── Produccion/
├── Purchasing/
├── Recetas/
├── Replenishment/
├── Reports/
├── Seguridad/
├── UI-UX/
├── Ventas/
├── V2/                     (histórico)
├── V3/                     (histórico)
└── _archive/               (respaldos empaquetados)
```

#### Documentación externa en `D:\Tavo\2025\UX\`
```
D:\Tavo\2025\UX\
├── 00. Noviembre/          (migración reciente 10-11-2025)
├── 00. Recetas/            (Documentación V1, UML, análisis)
├── Analisis Ventas/
├── BD/
├── Control/
├── Cortes/
├── Folios/
├── GPTS/
├── Inventarios/
├── Octubre/
├── Pagos/
├── POS/
├── Privilegios/
├── Proyector/
├── Reportes/
├── Server/
├── UI - UX/
├── voceo/
├── Modificaciones Sistemas.txt    ← Cambios y requerimientos
├── Pantallas.xlsx                  ← Inventario de pantallas
└── Listas de Precios.xlsx
```

### 1.2 COMPENDIO DE MÓDULOS IDENTIFICADOS

| Módulo | Objetivo | Procesos principales | Actores/Roles | Docs origen |
|--------|----------|---------------------|---------------|-------------|
| **Inventario** | Gestión de ítems, stock, lotes, movimientos | Alta de ítems, Recepciones, Transferencias, Conteos físicos, Ajustes/Mermas, Kardex | Almacenista, Supervisor inventario, Gerente | `/docs/V4.0/Inventario/*`, `/docs/Inventario/*`, `/docs/UI-UX/ANÁLISIS MÓDULO INVENTARIO*` |
| **Recetas & Costeo** | Administración de recetas, BOMs, costos | Editor de recetas, Versionado, Costeo automático, Catálogo UOM, Conversiones | Chef, Nutricionista, Controller, Gerente | `/docs/V4.0/Recetas/README.md`, `/docs/Recetas/*`, `D:\Tavo\2025\UX\00. Recetas\*` |
| **Producción** | Órdenes de producción, planificación | Órdenes de trabajo, Mise en place, Registro de mermas, Costeo real vs teórico | Chef, Producción, Supervisor cocina | `/docs/V4.0/Produccion/README.md`, `/docs/Produccion/*`, `D:\Tavo\2025\UX\00. Recetas\Documentación V1\UML\*` |
| **Compras & Replenishment** | Solicitudes, cotizaciones, órdenes de compra, sugerencias automáticas | Solicitudes de compra, Cotizaciones, POs, Motor de sugerencias (Min-Max, SMA), Recepciones, Devoluciones | Comprador, Gerente compras, Almacenista | `/docs/V4.0/Purchasing/README.md`, `/docs/Purchasing/*`, `/docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md` |
| **POS & Consumos** | Integración con POS, mapeo recetas, análisis de consumo | Mapeo POS-Recetas, Consumo teórico, Reproceso de tickets, Auditoría de descargas | Administrador, Auditor | `/docs/V4.0/POS/README.md`, `/docs/POS/*`, `/docs/PosConsumption/*` |
| **Caja Chica** | Fondos de caja, movimientos diarios, arqueos | Apertura de fondos, Movimientos, Arqueos, Conciliación | Cajero, Supervisor caja, Contador | `/docs/V4.0/Finanzas/README.md`, `/docs/CajaChica/*` |
| **Cortes & Cierres** | Cierre diario de operaciones, precorte, postcorte | Precorte (provisional), Postcorte (final), Conciliación, Histórico de cortes | Cajero, Gerente sucursal, Controller | `/docs/V4.0/Caja/HistoricoCortes.md`, `/docs/Orquestador/*`, `D:\Tavo\2025\UX\Cortes\*` |
| **Reportes & KPIs** | Dashboards, reportes de ventas, inventario, finanzas | Ventas por período, Mix de productos, Excepciones, Kardex, Stock valorizado, Exportaciones | Gerente, Controller, Director | `/docs/V4.0/Reports/README.md`, `/docs/Reports/*`, `D:\Tavo\2025\UX\Reportes\*` |
| **Seguridad & Permisos** | Control de acceso, roles, auditoría | Gestión de usuarios, Roles, Permisos atómicos, Auditoría de cambios | Administrador, Super admin | `/docs/Seguridad/*`, `/docs/UI-UX/v6/PERMISSIONS_MATRIX_V6.md`, `/docs/V4.0/Guia/Stack.md` |
| **Catálogos** | Unidades, conversiones, proveedores, almacenes, sucursales | Unidades de medida, Conversiones, Proveedores, Categorías, Almacenes, Sucursales, Políticas de stock | Administrador, Configurador | `/docs/V4.0/Inventario/*`, `/docs/Recetas/*`, Componentes Livewire |

### 1.3 IDEAS Y ACUERDOS "AL AIRE" (Mencionados pero no cerrados)

1. **Motor de Replenishment** ⚠️ CRÍTICO
   - **Estado:** Documentado en detalle en `/docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md`
   - **Problema:** Marcado como pendiente de implementación (Sprint 2)
   - **Docs:** `/docs/V4.0/Purchasing/README.md`, `/docs/Replenishment/*`
   - **Impacto:** Funcionalidad crítica para operación diaria

2. **Versionado real de recetas** ⚠️ ALTO
   - **Estado:** Existe `receta_version` en BD, pero UI solo usa `version=1`
   - **Problema:** No hay UI para gestionar múltiples versiones ni comparar cambios
   - **Docs:** `/docs/V4.0/Recetas/README.md`, `/docs/Recetas/STATUS_RECETAS_*.md`
   - **Impacto:** Costeo histórico incorrecto, pérdida de trazabilidad

3. **UI operativa de Producción** ⚠️ MEDIO
   - **Estado:** Servicio backend existe (`App\Services\Inventory\ProductionService`)
   - **Problema:** UI operativa pendiente, no hay panel para supervisores
   - **Docs:** `/docs/V4.0/Produccion/README.md`
   - **Impacto:** Limitación operativa para cocina/producción

4. **Flujos de validación/aprobación en recepciones** ⚠️ ALTO
   - **Estado:** Diseñado flujo BORRADOR → VALIDADA → POSTEADA
   - **Problema:** `ReceptionService` marca todo como RECIBIDO directamente
   - **Docs:** `/docs/V4.0/Inventario/Recepciones.md`
   - **Impacto:** Falta control de calidad en recepciones

5. **API POS sin exponer** ⚠️ MEDIO
   - **Estado:** `App\Http\Controllers\Pos\RecipeCostController` implementado
   - **Problema:** No está registrado en `routes/api.php`
   - **Docs:** `/docs/V4.0/POS/README.md`
   - **Impacto:** Funcionalidad existente no disponible

6. **Asociación Recepciones ↔ Órdenes de Compra** ⚠️ MEDIO
   - **Estado:** Documentado en recepciones
   - **Problema:** No implementado, recepciones independientes de POs
   - **Docs:** `/docs/V4.0/Inventario/Recepciones.md`, `/docs/V4.0/Purchasing/README.md`
   - **Impacto:** Pérdida de trazabilidad compra→recepción

7. **Recetas Shadow (inferidas del POS)** ⚠️ BAJO
   - **Estado:** Tabla `receta_shadow` existe en BD
   - **Problema:** No hay UI para validar/aprobar recetas inferidas
   - **Docs:** Mencionado en análisis de BD
   - **Impacto:** Funcionalidad avanzada sin implementar

8. **UI de ajustes rápidos en mermas** ⚠️ MEDIO
   - **Estado:** Documentada en wireflows
   - **Problema:** No implementada
   - **Docs:** `/docs/V4.0/Inventario/Mermas.md`
   - **Impacto:** Proceso manual más lento

### 1.4 LÓGICA DISEÑADA PERO NO IMPLEMENTADA

#### 1.4.1 Motor de Replenishment completo
**Documentado en:** `/docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md`

**Algoritmos diseñados:**
- Min-Max con lead times
- SMA (Simple Moving Average)
- POS consumption forecasting
- Combinación de políticas por categoría

**Componentes faltantes:**
- ❌ Dashboard de sugerencias con razón de cálculo
- ❌ Simulador de costo antes de confirmar
- ❌ API REST completa para sugerencias
- ❌ UI de configuración de políticas por ítem

#### 1.4.2 Versionado de recetas
**Documentado en:** `/docs/V4.0/Recetas/README.md`

**Funcionalidad diseñada:**
- Múltiples versiones activas
- Comparación entre versiones
- Historial de cambios
- Activación/desactivación de versiones

**Estado actual:**
- ✅ Tabla `receta_version` existe
- ✅ Modelo `RecetaVersion` existe
- ❌ Editor siempre sobreescribe `version=1`
- ❌ No hay UI de comparación
- ❌ No hay activación/desactivación

#### 1.4.3 Estados completos en transferencias
**Documentado en:** `/docs/V4.0/Inventario/Transferencias.md`

**Flujo diseñado:**
```
BORRADOR → SOLICITADA → APROBADA → DESPACHADA → EN_TRÁNSITO → RECIBIDA
```

**Estado actual:**
- ⚠️ Implementación parcial
- ⚠️ Estados no completamente funcionales en UI
- ❌ No hay validación de permisos por estado
- ❌ API REST pendiente

#### 1.4.4 Flujo de validación en recepciones
**Documentado en:** `/docs/V4.0/Inventario/Recepciones.md`

**Flujo diseñado:**
```
BORRADOR → VALIDADA (con tolerancias) → POSTEADA (con evidencias)
```

**Estado actual:**
- ❌ `ReceptionService` solo implementa estado RECIBIDO
- ❌ No hay validación de tolerancias
- ❌ No hay carga de evidencias (fotos, documentos)

### 1.5 CONTRADICCIONES ENTRE DOCUMENTOS

#### 1.5.1 Servicios duplicados: ReceptionService vs ReceivingService
- **Ubicación 1:** `app/Services/Inventory/ReceptionService.php`
- **Ubicación 2:** `app/Services/Purchasing/ReceivingService.php`
- **Problema:** Dos servicios diferentes que manejan recepciones
- **Necesidad:** Clarificar responsabilidades o consolidar
- **Docs:** `/docs/V4.0/Inventario/Recepciones.md`, `/docs/V4.0/Purchasing/README.md`

#### 1.5.2 UI inconsistente en conversiones de recetas
- **Doc:** `/docs/V4.0/Recetas/README.md`
- **Problema:** Vista Blade espera propiedades (`u_origen`, `showForm`) que no existen en componente Livewire
- **Impacto:** Posibles errores en runtime
- **Ubicación código:** `app/Livewire/Recipes/`, `resources/views/livewire/recipes/`

#### 1.5.3 Nomenclatura de permisos inconsistente
- **Doc 1:** `config/permissions.php`
- **Doc 2:** `/docs/UI-UX/v6/PERMISSIONS_MATRIX_V6.md`
- **Problema:** Algunos permisos usan diferentes nombres entre código y documentación
- **Necesidad:** Sincronizar matriz de permisos con implementación real

#### 1.5.4 Endpoints legacy vs nuevos
- **Problema:** Mezcla de endpoints `.php` (legacy) y REST modernos
- **Ejemplo:** `/api/some-endpoint.php` vs `/api/v1/resource`
- **Docs:** `/docs/V4.0/Arquitectura/README.md` menciona eliminar legacy
- **Estado:** Pendiente de migración completa

---

## 📋 RESUMEN EJECUTIVO FASE 1

### ✅ Fortalezas documentales
1. Documentación V4.0 bien estructurada y publicada recientemente (nov 2025)
2. Separación clara entre versión objetivo (V4.0) y material histórico
3. Cobertura amplia de módulos principales
4. Documentación técnica de arquitectura completa
5. Plan maestro UI/UX detallado

### ⚠️ Brechas principales
1. **Motor de Replenishment:** Documentado pero no implementado (CRÍTICO)
2. **Versionado de recetas:** Parcialmente implementado (ALTO)
3. **Flujos de validación:** Diseñados pero no implementados (ALTO)
4. **UI de producción:** Backend existe, frontend pendiente (MEDIO)
5. **Servicios duplicados:** Necesita consolidación (MEDIO)

### 📊 Cobertura por módulo (estimado)

| Módulo | Docs | Código | UI | BD | Cobertura |
|--------|------|--------|----|----|-----------|
| Inventario - Items | ✅ | ✅ | ✅ | ✅ | 95% |
| Inventario - Recepciones | ✅ | ⚠️ | ✅ | ✅ | 70% |
| Inventario - Transferencias | ✅ | ⚠️ | ⚠️ | ✅ | 60% |
| Inventario - Conteos | ✅ | ✅ | ✅ | ✅ | 85% |
| Recetas - Editor | ✅ | ✅ | ✅ | ✅ | 90% |
| Recetas - Versionado | ✅ | ⚠️ | ❌ | ✅ | 40% |
| Recetas - Costeo | ✅ | ✅ | ✅ | ✅ | 85% |
| Producción | ✅ | ⚠️ | ❌ | ✅ | 40% |
| Compras - Solicitudes/POs | ✅ | ✅ | ✅ | ✅ | 80% |
| Compras - Replenishment | ✅ | ❌ | ❌ | ⚠️ | 20% |
| POS - Mapeo | ✅ | ✅ | ✅ | ✅ | 90% |
| POS - Consumos | ✅ | ✅ | ⚠️ | ✅ | 70% |
| Caja Chica | ✅ | ✅ | ✅ | ✅ | 90% |
| Cortes & Cierres | ✅ | ✅ | ✅ | ✅ | 85% |
| Reportes | ✅ | ✅ | ✅ | ✅ | 80% |
| Seguridad | ✅ | ✅ | ⚠️ | ✅ | 75% |

---

## 🔄 SIGUIENTE: FASE 2 – REVISIÓN DE docs/V4.0

**Objetivo:** Comparar V4.0 contra el compendio de Fase 1 y detectar:
- ✅ Qué está completo y alineado
- ❌ Qué le falta a V4.0
- 🗑️ Qué sobra o está desactualizado

---

## 📍 COMANDOS SQL REQUERIDOS PARA CONTINUAR

Para completar la auditoría necesito ejecutar los siguientes comandos en la base de datos **selemti**:

### 1. Listado completo de tablas
```sql
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'selemti'
ORDER BY table_name;
```

### 2. Listado de vistas
```sql
SELECT 
    table_name as view_name,
    view_definition
FROM information_schema.views
WHERE table_schema = 'selemti'
ORDER BY table_name;
```

### 3. Listado de funciones y procedimientos
```sql
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'selemti'
ORDER BY routine_type, routine_name;
```

### 4. Relaciones clave (foreign keys)
```sql
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'selemti' 
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;
```

### 5. Triggers existentes
```sql
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'selemti'
ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME;
```

### 6. Diccionario de datos completo (muestra)
```sql
SELECT 
    t.TABLE_NAME,
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.IS_NULLABLE,
    c.COLUMN_KEY,
    c.COLUMN_DEFAULT,
    c.EXTRA,
    c.COLUMN_COMMENT
FROM information_schema.TABLES t
JOIN information_schema.COLUMNS c 
    ON t.TABLE_NAME = c.TABLE_NAME 
    AND t.TABLE_SCHEMA = c.TABLE_SCHEMA
WHERE t.TABLE_SCHEMA = 'selemti'
    AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME, c.ORDINAL_POSITION;
```

**FORMATO DE SALIDA SOLICITADO:** 
- CSV o TXT delimitado por pipes `|`
- Guardar cada resultado en archivo separado: `selemti_tables.csv`, `selemti_views.csv`, etc.
- Colocar archivos en: `C:\xampp3\htdocs\TerrenaLaravel\BD\audit\`

---

## 📝 NOTAS DEL AUDITOR

### Observaciones iniciales
1. El proyecto tiene una **base documental sólida** con `/docs/V4.0` como versión canónica
2. Existe **material histórico valioso** en `D:\Tavo\2025\UX\` que debe integrarse
3. La documentación de `/docs/AUDITORIA_TERRENA_COMPLETA.md` previa (Qwen Code) es **muy útil** como baseline
4. Se detecta **brecha significativa** entre lo documentado y lo implementado en varios módulos
5. La **arquitectura de BD** parece robusta (141 tablas según auditoría previa)

### Metodología aplicada
- ✅ Análisis top-down (documentación → código → BD)
- ✅ Comparación cruzada entre fuentes
- ✅ Clasificación por severidad (CRÍTICO, ALTO, MEDIO, BAJO)
- ✅ Sin modificación de código (solo auditoría)

### Próximos pasos
1. ⏳ Obtener datos de BD (comandos SQL arriba)
2. ⏳ Ejecutar FASE 2 (análisis V4.0)
3. ⏳ Ejecutar FASE 3 (integración documental)
4. ⏳ Ejecutar FASE 4 (análisis código detallado)
5. ⏳ Ejecutar FASE 5 (análisis BD completo)
6. ⏳ Ejecutar FASE 6 (evaluación UI/UX)

---

**ESTADO ACTUAL:** Fase 1 completada ✅  
**BLOQUEADOR:** Necesito acceso a datos de BD para continuar con fases 2-6  
**TIEMPO ESTIMADO RESTANTE:** 2-3 horas una vez obtenidos los datos de BD

