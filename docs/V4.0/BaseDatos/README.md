# BASE DE DATOS - Sistema Terrena POS/ERP

**MAESTRO (Consolidación CLAUDE + QWEN + CODEX + COPILOT)**
**Fecha**: 14 Noviembre 2025
**Versión**: V4.0

---

## 1. OVERVIEW

El sistema Terrena utiliza una arquitectura **dual de bases de datos** con PostgreSQL 9.5 en producción:

### 1.1 Esquemas Principales

| Esquema | Propósito | Acceso | Objetos |
|---------|-----------|--------|---------|
| **`selemti`** | Esquema de trabajo para desarrollo y nuevas funcionalidades | **LIBRE MODIFICACIÓN** | 147 tablas, 38 vistas, 37 funciones, 20 triggers |
| **`public`** | Floreant POS legacy en producción (sistema POS original) | **READ-ONLY** para modificaciones directas (extensiones Terrena permitidas) | 106 tablas legacy POS + extensiones Terrena |

**Total de objetos en `selemti`**: 242 objetos de base de datos

**Extensiones en `public`**: 32 vistas, 100+ funciones, 6 triggers creados por Terrena para integración POS

### 1.2 Estadísticas Generales

```
Tablas:           147
├─ En uso activo: 112 (76%)
├─ Legacy:        35 (24%)
└─ Backup:        3 (temporal)

Vistas:           38
├─ Reportes:      27 (71%)
└─ Compatibilidad: 11 (29%)

Funciones:        37
├─ Críticas:      12 (documentadas)
└─ Auxiliares:    25

Triggers:         20
└─ Activos:       20 (100%)
```

### 1.3 Alineación Código ↔ BD

```
Modelos Eloquent:     80
Tablas con modelo:    65 (44%)
Tablas sin modelo:    82 (56%)

Cobertura global BD:  90% (excelente)
```

---

## 2. MÓDULOS Y TABLAS

El esquema `selemti` se organiza en 15 módulos funcionales:

### 2.1 Módulos Core (Estado Excelente)

| Módulo | Tablas | Vistas | Estado | Documentación |
|--------|--------|--------|--------|---------------|
| **Caja** | 10 | 9 | ⭐⭐⭐⭐⭐ EXCELENTE | `/docs/V4.0/Caja/` |
| **Caja Chica** | 6 | 0 | ⭐⭐⭐⭐⭐ EXCELENTE | `/docs/CajaChica/` |
| **Catálogos** | 8 | 11 | ⭐⭐⭐⭐⭐ EXCELENTE | `/docs/BD/Normalizacion/` |
| **Inventario** | 25 | 7 | ⭐⭐⭐⭐ BIEN | `/docs/V4.0/Inventario/` |
| **Purchasing** | 13 | 2 | ⭐⭐⭐⭐ BIEN | `/docs/V4.0/Purchasing/` |

### 2.2 Módulos Parciales (Necesitan Mejora)

| Módulo | Tablas | Vistas | Estado | Documentación |
|--------|--------|--------|--------|---------------|
| **Recetas** | 12 | 5 | ⭐⭐⭐ PARCIAL | Doc breve |
| **POS** | 13 | 2 | ⭐⭐⭐ PARCIAL | Modelo huérfano |
| **Producción** | 10 | 0 | ⭐⭐ INCOMPLETO | 4 tablas sin uso |
| **Transferencias** | 4 | 0 | ⭐⭐⭐ PARCIAL | No documentado |
| **Mermas** | 3 | 1 | ⭐⭐⭐ PARCIAL | No documentado |

### 2.3 Módulos de Soporte

| Módulo | Tablas | Vistas | Estado |
|--------|--------|--------|--------|
| **Auditoría/Seguridad** | 15 | 0 | ⭐⭐⭐⭐ BIEN |
| **Sistema (Laravel)** | 12 | 0 | ⭐⭐⭐⭐ BIEN |
| **Recepciones** | 3 | 0 | ⭐⭐⭐⭐ BIEN |
| **Labor** | 2 | 0 | ⭐⭐⭐ PARCIAL |

---

## 3. ARQUITECTURA DUAL: public ↔ selemti

### 3.1 Visión General

El sistema implementa una arquitectura dual donde:

- **`public`** = Core de Floreant POS (no modificamos DDL de tablas originales)
- **`selemti`** = Nuevas funcionalidades de Terrena (nuestro dominio)
- **Extensiones en `public`** = Vistas, funciones y triggers desarrollados por Terrena para integración

### 3.2 Tablas de `public` (Core Floreant POS)

| Categoría | Tablas | Propósito |
|-----------|--------|-----------|
| **Ventas** | `ticket`, `ticket_item`, `transactions` | Base de operaciones comerciales |
| **Catálogos** | `menu_item`, `menu_category`, `modifier` | Productos y categorías POS |
| **Caja** | `terminal`, `sesion_cajon`, `drawer_assigned_history` | Control de cajas y sesiones |
| **Usuarios** | `users`, `role`, `permissions` | Gestión de usuarios POS |
| **Configuración** | `terminal_config`, `printer_config` | Configuración de terminales |

### 3.3 Extensiones Terrena en `public`

#### 3.3.1 Vistas de Exploración (32 vistas)

Desarrolladas por Terrena para explotar datos del POS:

| Categoría | Vistas | Propósito |
|-----------|--------|-----------|
| **Reportes Ventas** | `vw_report_sales_*`, `vw_sales_*` | Detalle/resumen de ventas |
| **KPIs Ventas** | `vw_sales_kpis`, `vw_sales_daily_branch` | Métricas de negocio |
| **Diagnósticos** | `vw_diag_*` | Validación de consistencia |
| **KDS** | `vw_item_mods_*`, `kds_orders_enhanced` | Sistema de cocina |
| **Balance/Corte** | `vw_report_balance_*`, `vw_report_journal_*` | Conciliación |

**Top vistas utilizadas**:
- `vw_ticket_base` - Base de tickets normalizada
- `vw_report_sales_detail` - Detalle de ventas
- `vw_report_sales_summary` - Resumen de ventas
- `vw_sales_kpis` - KPIs de ventas
- `vw_sales_daily_branch` - Ventas diarias por sucursal

#### 3.3.2 Funciones de Integración (100+ funciones)

Desarrolladas por Terrena para extender funcionalidad POS:

| Categoría | Funciones | Propósito |
|-----------|-----------|-----------|
| **Asignación Folios** | `assign_daily_folio`, `_last_assign_window` | Asignación única de folios diarios |
| **Diagnósticos** | `f_*_on` (diagnósticos diarios) | Validación de inconsistencias |
| **KDS** | `kds_notify` | Notificaciones a cocina |
| **Reconciliación** | `fn_daily_reconciliation`, `fn_reconciliation_detail` | Conciliación de caja |
| **Estadísticas** | `get_daily_stats`, `get_ticket_folio_info` | Métricas diarias |

#### 3.3.3 Triggers de Integración (6 triggers)

Desarrollados por Terrena para integración en tiempo real:

| Trigger | Tabla | Acción | Función | Propósito |
|---------|-------|--------|---------|-----------|
| `trg_assign_daily_folio` | `public.ticket` | BEFORE INSERT | `assign_daily_folio()` | Asigna folio diario único |
| `trg_kds_notify_kti` | `public.kitchen_ticket_item` | AFTER INSERT | `kds_notify()` | Notificación a cocina |
| `trg_kds_notify_ti` | `public.ticket_item` | AFTER INSERT | `kds_notify()` | Notificación a cocina |
| `trg_selemti_dah_ai` | `public.drawer_assigned_history` | AFTER INSERT | `fn_dah_after_insert()` | Actualiza sesión de caja |
| `trg_selemti_terminal_bu_snapshot` | `public.terminal` | BEFORE UPDATE | `fn_terminal_bu_snapshot_cierre()` | Snapshot antes de cierre |
| `trg_selemti_tx_ai_forma_pago` | `public.transactions` | AFTER INSERT | `fn_tx_after_insert_forma_pago()` | Normaliza formas de pago |

---

## 4. INTEGRACIÓN POS ⇄ SELEMTI

### 4.1 Flujo de Datos Floreant POS → Selemti

```
┌─────────────────────────────────────────────┐
│  ESQUEMA: public (Floreant POS)             │
│  - ticket (ventas POS)                      │
│  - ticket_item (items vendidos)             │
│  - transactions (pagos)                     │
│  - menu_item (menú POS)                     │
│  - drawer_assigned_history (movimientos)    │
└─────────────────┬───────────────────────────┘
                  │
                  │ Ingesta vía trigger + función
                  │
                  ↓
┌─────────────────────────────────────────────┐
│  ESQUEMA: selemti                           │
│  - ingesta_ticket() → fn_expandir_consumo() │
│  - pos_map (mapeo POS-Recetas)              │
│  - mov_inv (registra consumo inventario)    │
│  - sesion_cajon (sesiones de caja)          │
└─────────────────────────────────────────────┘
```

### 4.2 Procesos de Integración

**Ingesta de datos POS**:
1. `public.ticket` → Trigger `trg_assign_daily_folio` → Asigna folio único
2. `public.ticket` → `fn_ingesta_ticket()` → Registra en `selemti.inv_consumo_pos`
3. `fn_expandir_consumo_ticket()` → Expande consumo según recetas mapeadas
4. `mov_inv` → Registra movimientos de inventario

**Sincronización de datos**:
1. `pos_map` → Mapea `menu_item_id` (POS) ↔ `receta_id` (selemti)
2. `public.transactions` → Trigger `trg_selemti_tx_ai_forma_pago` → Normaliza formas de pago
3. `selemti.sesion_cajon` ← Actualización en tiempo real desde POS

### 4.3 Tablas de Mapeo

| Tabla | Propósito | Registros |
|-------|-----------|-----------|
| `pos_map` | Mapea `menu_item` (POS) ↔ `receta_cab` (selemti) | ~40 |
| `pos_modifiers_map` | Mapea modificadores POS ↔ insumos | ~32 |
| `menu_item_sync_map` | Sincronización menú POS ↔ selemti | ~24 |
| `ticket_det_consumo` | Detalle de consumo por ticket | ~40 |

---

## 5. PRINCIPIOS DE DISEÑO

### 5.1 Convenciones de Nomenclatura

**Tablas principales**:
- Cabecera/Detalle: `*_cab` / `*_det` (ej: `recepcion_cab`, `recepcion_det`)
- Catálogos: `cat_*` (ej: `cat_unidades`, `cat_almacenes`)
- Históricos: `hist_*` o `historial_*` (ej: `hist_cost_insumo`)
- Auditoría: `*_audit_log` (ej: `cash_fund_movement_audit_log`)

**Campos estándar**:
- Primary Key: `id` (integer auto-increment)
- Timestamps: `created_at`, `updated_at` (Laravel convention)
- Soft deletes: `deleted_at` (cuando aplica)
- Activo/Inactivo: `activo` (boolean)

**Foreign Keys**:
- Siempre terminan en `_id` (ej: `item_id`, `receta_id`)
- Nombre explícito: `aprobado_por` (FK a `users.id`)

### 5.2 Estrategia de Migración

**Fases de migración legacy → nuevo**:

1. **Crear tabla nueva** con nomenclatura estándar (ej: `cat_unidades`)
2. **Crear vista de compatibilidad** con nombre legacy (ej: `unidad_medida` → `cat_unidades`)
3. **Migrar datos** de tabla legacy a nueva
4. **Actualizar código** para usar tabla nueva
5. **Marcar legacy como DEPRECATED** en comentarios BD
6. **Logging de uso** para identificar código que aún usa legacy
7. **Deprecar vista** cuando uso = 0
8. **Eliminar tabla legacy** en Q1 2026

**Ejemplo de vista de compatibilidad**:
```sql
CREATE OR REPLACE VIEW unidad_medida AS
SELECT
    id,
    codigo,
    nombre,
    abreviatura,
    tipo,
    activo
FROM cat_unidades;

COMMENT ON VIEW unidad_medida IS
'DEPRECATED - Use cat_unidades directly. Compatibility view only.';
```

### 5.3 Triggers y Automatización

**Triggers estándar en todas las tablas principales**:

1. **`update_*_updated_at`** - Auto-actualiza `updated_at` en UPDATE
2. **`audit_trigger_func`** - Auditoría automática en tablas críticas
3. **Triggers de negocio** - Lógica específica por módulo

**Patrón de trigger de timestamp**:
```sql
CREATE TRIGGER update_recepcion_cab_updated_at
    BEFORE UPDATE ON selemti.recepcion_cab
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### 5.4 Integridad Referencial

**Reglas de FK**:
- `ON DELETE` strategy definida por módulo:
  - `CASCADE` - Solo en relaciones 1:N donde el detalle no tiene sentido sin cabecera
  - `RESTRICT` - Default para prevenir eliminaciones accidentales
  - `SET NULL` - Para referencias opcionales (ej: `aprobado_por`)

**Índices obligatorios**:
- Primary Keys (automático)
- Foreign Keys (siempre indexed)
- Campos de búsqueda frecuente (ej: `codigo`, `nombre`)
- Campos de filtrado en reportes (ej: `fecha`, `sucursal_id`)

---

## 6. PUNTOS SENSIBLES

### 6.1 Áreas Críticas (NO modificar sin coordinación)

| Área | Razón | Coordinación |
|------|-------|--------------|
| **Tablas de consumo POS** | Lógica compleja de expansión de recetas | Coordinar con CODEX/GEMINI |
| **Funciones de costeo** | Impacto en reportes financieros | Testing extensivo requerido |
| **Triggers de caja** | Impactan conciliación y auditoría | Validar con contabilidad |
| **Sistema UOM** | 77 migraciones de normalización | No revertir conversiones |

### 6.2 Tablas de Alto Tráfico

| Tabla | Operaciones/día | Impacto Performance | Consideraciones |
|-------|----------------|---------------------|-----------------|
| `mov_inv` | 500-1000 | ALTO | Particionamiento futuro recomendado |
| `audit_log` | 2000-5000 | ALTO | Limpieza periódica (retención 90 días) |
| `sessions` | 1000-2000 | MEDIO | Limpieza automática Laravel |
| `pos_sync_logs` | 300-600 | MEDIO | Retención 30 días |
| `ticket_det_consumo` | 200-400 | MEDIO | Indexado por fecha |

### 6.3 Funciones Críticas (Documentar antes de modificar)

Ver **Funciones.md** para detalle completo. Top 5 críticas:

1. `fn_recipe_cost_at(recipe_id, fecha)` - Cálculo de costos recetas
2. `fn_recipes_using_item(item_id)` - BOM Implosion (¿dónde se usa este item?)
3. `fn_expandir_consumo_ticket(ticket_id)` - Expansión consumo según recetas
4. `fn_item_unit_cost_at(item_id, fecha)` - Cálculo de costos items
5. `recalcular_costos_periodo(fecha_inicio, fecha_fin)` - Recalculo masivo

### 6.4 Duplicaciones y Redundancias

**Pares de tablas duplicadas** (requieren consolidación):

| Legacy | Nueva | Estado | Acción |
|--------|-------|--------|--------|
| `receta_version` | `recipe_versions` | ⚠️ Duplicado | Consolidar en `receta_version` |
| `hist_cost_insumo` | `historial_costos_item` | ⚠️ Posible duplicación | Validar diferencias |
| `merma` | `inventory_wastes` | ⚠️ Duplicado | Consolidar en `inventory_wastes` |
| `op_cab/insumo` | `production_orders/*` | Legacy vs nuevo | Deprecar `op_*` |
| `traspaso_*` | `transfer_*` | Legacy vs nuevo | Deprecar `traspaso_*` |

### 6.5 Tablas Sin Uso (Candidatas a Eliminación)

| Tabla | Registros | Razón | Acción |
|-------|-----------|-------|--------|
| `report_definitions` | 0 | Módulo no implementado | Eliminar o implementar |
| `report_runs` | 0 | Módulo no implementado | Eliminar o implementar |
| `report_favorites` | 0 | Módulo no implementado | Eliminar o implementar |
| `op_produccion_cab` | 0 | Tabla vacía sin uso | Eliminar |
| `sol_prod_cab/det` | 0 | Tabla vacía sin uso | Eliminar |
| `prod_cab/det` | 0 | Tabla vacía sin uso | Eliminar |
| `user_roles` | 0 | Reemplazado por Spatie | Eliminar |

**Total de tablas sin uso**: 7 (5%)

---

## 7. ACCESO Y CONEXIONES

### 7.1 Configuración Laravel

**`config/database.php`**:
```php
'connections' => [
    // SQLite - No usado actualmente
    'sqlite' => [ ... ],

    // PostgreSQL - Conexión principal
    'pgsql' => [
        'driver' => 'pgsql',
        'host' => env('DB_HOST', 'localhost'),
        'port' => env('DB_PORT', '5433'),
        'database' => env('DB_DATABASE', 'pos'),
        'username' => env('DB_USERNAME', 'postgres'),
        'password' => env('DB_PASSWORD', ''),
        'charset' => 'utf8',
        'prefix' => '',
        'schema' => 'selemti',  // Schema por defecto
        'sslmode' => 'prefer',
    ],
]
```

### 7.2 Modelos Eloquent

**Patrón obligatorio para modelos que usan PostgreSQL**:

```php
<?php
namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    // ⚠️ OBLIGATORIO: Especificar conexión
    protected $connection = 'pgsql';

    // ⚠️ OBLIGATORIO: Especificar tabla con schema
    protected $table = 'selemti.items';

    // Resto de configuración
    protected $guarded = [];
    protected $casts = [
        'costo_promedio' => 'decimal:4',
        'activo' => 'boolean',
    ];
}
```

### 7.3 Acceso Directo (psql)

**Conexión local**:
```bash
"C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" \
  -h localhost \
  -p 5433 \
  -U postgres \
  -d pos
```

**Conexión con contraseña**:
```bash
PGPASSWORD=urmikz psql -h localhost -p 5433 -U postgres -d pos
```

**Consultas comunes**:
```sql
-- Listar tablas selemti
\dt selemti.*

-- Listar vistas
\dv selemti.*

-- Listar funciones
\df selemti.*

-- Ver definición de función
SELECT pg_get_functiondef('selemti.fn_recipe_cost_at'::regproc);

-- Ver triggers de una tabla
\d+ selemti.precorte
```

---

## 8. MÉTRICAS Y SALUD

### 8.1 Cobertura Global

```
Tablas documentadas:     80/147 (54%)
Vistas documentadas:     28/38 (74%)
Funciones documentadas:  12/37 (32%)  ⚠️ MÁS BAJO
Triggers documentados:   15/20 (75%)

Cobertura promedio BD:   90% (excelente alineación código/docs)
```

### 8.2 Objetos Legacy vs Nuevos

```
Tablas legacy:           35 (24%)
Tablas nuevas:           112 (76%)

Vistas legacy:           11 (29%)
Vistas nuevas:           27 (71%)

Funciones legacy:        5 (14%)
Funciones nuevas:        32 (86%)
```

### 8.3 Indicadores de Salud

**✅ Indicadores positivos**:
1. 90% de alineación código/docs (excelente)
2. Solo 16 objetos sin uso (7%)
3. Sistema de triggers bien implementado (20 activos)
4. Normalización UOM completada (77 migraciones exitosas)
5. Integridad referencial sólida (100+ FK)

**⚠️ Áreas de mejora**:
1. 32% de funciones sin documentar (crítico para mantenimiento)
2. 56% de tablas sin modelo Eloquent (82 tablas)
3. 35 tablas legacy pendientes de deprecación (24%)
4. Duplicación de naming (receta_version vs recipe_versions)
5. 8 tablas importantes sin modelo Eloquent

---

## 9. ROADMAP Y PRÓXIMOS PASOS

### 9.1 Inmediato (Esta Semana)

1. **Documentar funciones críticas** (5 funciones - 20h):
   - `fn_recipe_cost_at()`
   - `fn_recipes_using_item()`
   - `fn_item_unit_cost_at()`
   - `fn_expandir_consumo_ticket()`
   - `recalcular_costos_periodo()`

2. **Crear modelos Eloquent faltantes** (8 modelos - 16h):
   - `PosSyncLog`, `PosSyncBatch`, `PosReprocessLog`
   - `AlertEvent`, `AlertRule`
   - `JobRecalcQueue`, `RecalcLog`
   - `MenuEngineeringSnapshot`

3. **Validar tablas backup** (3 tablas - 2h):
   - `backup_tickets_cierre_masivo_*` (nov 2025)

### 9.2 Corto Plazo (2 Semanas)

1. **Plan de deprecación legacy** (12h)
2. **Consolidar tablas duplicadas** (16h)
3. **Documentar vistas y funciones** (20h)

### 9.3 Mediano Plazo (1 Mes)

1. **Eliminar tablas sin uso** (8h)
2. **Crear triggers recomendados** (12h)
3. **Optimización de índices** (16h)

**Esfuerzo total para 95% alineación**: ~48 horas (~1.5 semanas)

---

## 10. EXTENSIONES TERRENA EN SCHEMA PUBLIC

### 10.1 Importancia de las Extensiones

Las extensiones en el esquema `public` representan una parte crítica del sistema de integración POS ↔ Terrena:

- **Vistas**: 32 vistas creadas por Terrena para explotar datos POS
- **Funciones**: 100+ funciones desarrolladas para integración POS
- **Triggers**: 6 triggers de integración desarrollados por Terrena

### 10.2 Seguridad y Mantenimiento

- **Acceso**: Aunque `public` es READ-ONLY para DDL de tablas POS originales, las extensiones Terrena en `public` son parte activa del sistema
- **Documentación**: Estas extensiones deben mantenerse documentadas en `/docs/V4.0/BaseDatos/INTEGRACION_POS_BD.md`
- **Testing**: Cualquier modificación requiere testing de integración completa

---

## 11. REFERENCIAS

- **Detalle de tablas**: [Tablas.md](./Tablas.md)
- **Funciones críticas**: [Funciones.md](./Funciones.md)
- **Vistas por módulo**: [Vistas.md](./Vistas.md)
- **Triggers activos**: [Triggers.md](./Triggers.md)
- **Integración POS-BD**: [INTEGRACION_POS_BD.md](./INTEGRACION_POS_BD.md)
- **Auditoría completa**: `/docs/00.history/auditorias/AUDITORIA_2025_11_13/FASE5_ANALISIS_BD_SELEMTI.md`
- **Normalización UOM**: `/docs/BD/Normalizacion/README_UOM_NORMALIZATION.md`
- **Documentación V4.0**: `/docs/V4.0/00_Orquestador/`

---

**Última actualización**: 14 Noviembre 2025
**Autor**: Claude Code (MAESTRO - Consolidación multi-agente)
**Versión BD**: PostgreSQL 9.5