# COMPENDIO TÉCNICO V4.1 - Sistema Terrena

**Orquestador**: MAESTRO  
**Fecha**: 18 Noviembre 2025  
**Versión**: 4.1 (POST-REFACTOR)  
**Audiencia**: Desarrolladores, Agentes IA  
**Estado BD↔Código**: ✅ COMPLETADO

---

## 1. ¿QUÉ ES TERRENA?

Terrena es un **ERP/POS integral para restaurantes multi-sucursal** que integra gestión completa de operaciones gastronómicas desde inventario hasta ventas, producción y finanzas.

### Alcance del Sistema

```
15 módulos integrados
147 tablas selemti
106 tablas public (POS legacy)
38 vistas, 37 funciones, 20 triggers
80 modelos Eloquent
58 componentes Livewire
90% alineación BD↔Código (POST-REFACTOR)
```

---

## 2. ARQUITECTURA TÉCNICA

### 2.1 Stack Tecnológico

**Backend**: Laravel 12 + PHP 8.2 + PostgreSQL 9.5/14  
**Frontend**: Livewire 3.7 + Bootstrap 5.3 + Alpine.js 3.x  
**BD**: PostgreSQL dual schema (`public` + `selemti`)  
**Auth**: JWT + Spatie Permission  
**API**: L5-Swagger OpenAPI 3.0  

### 2.2 Arquitectura Dual de BD

```
PostgreSQL 9.5 (producción)
│
├─ public (Floreant POS - READ-ONLY DDL original)
│  ├─ ticket, ticket_item, transactions (POS core)
│  ├─ menu_item, menu_category (Catálogos POS)
│  ├─ terminal, sesion_cajon (Caja POS)
│  └─ Extensiones Terrena:
│     ├─ 32 vistas (vw_*, kds_*)
│     ├─ 100+ funciones (fn_*, f_*)
│     └─ 6 triggers (trg_selemti_*)
│
└─ selemti (Terrena - LIBRE MODIFICACIÓN)
   ├─ 147 tablas (112 activas, 35 legacy)
   ├─ 38 vistas (reportes, KPIs)
   ├─ 37 funciones (12 críticas)
   └─ 20 triggers (integración, auditoría)
```

**Regla de Oro**: `public` READ-ONLY para DDL original, solo extensiones Terrena permitidas

---

## 3. MÓDULOS DEL SISTEMA

### 3.1 Módulos P0 (Críticos)

**Inventario** (25 tablas) ⭐⭐⭐⭐⭐
- Kardex (`mov_inv`)
- Lotes (`inventory_batch`)
- Recepciones (`recepcion_cab`, `recepcion_det`)
- Transferencias (`transfer_cab`, `transfer_det`)
- Políticas stock (`stock_policy`)

**Recetas** (12 tablas) ⭐⭐⭐⭐
- Versionado (`receta_version`)
- BOM (`receta_insumo`)
- Costeo (`recipe_cost_snapshot`)
- Mapeo POS (`pos_map`)

**Producción** (10 tablas) ⭐⭐⭐⭐
- Órdenes (`production_orders`)
- Mise en place
- Mermas (`inventory_wastes`)

**Purchasing** (13 tablas) ⭐⭐⭐
- Órdenes de compra (`po_cab`, `po_det`)
- Motor Replenishment (Sprint 1)
- Cotizaciones

**POS** (13 tablas selemti + 106 public) ⭐⭐⭐⭐
- Integración Floreant POS
- Consumo tickets (`inv_consumo_pos`)
- Expansión recetas (`fn_expandir_consumo_ticket`)

### 3.2 Módulos P1 (Importantes)

**Caja** (10 tablas) ⭐⭐⭐⭐⭐
- Sesiones (`sesion_cajon`)
- Cortes (`precorte`, `postcorte`)
- Conciliación

**Caja Chica** (6 tablas) ⭐⭐⭐⭐⭐
- Fondos (`cash_funds`)
- Movimientos (`cash_fund_movements`)
- State machine completo

**Finanzas** (8 tablas) ⭐⭐⭐⭐
- Cortes diarios
- KPIs financieros

**Reports** (0 tablas propias) ⭐⭐⭐⭐
- Usa vistas de otros módulos
- 27 vistas de reportes

### 3.3 Módulos P2 (Soporte)

**Catálogos** (8 tablas) ⭐⭐⭐⭐⭐
- Unidades (`cat_unidades`)
- Proveedores (`cat_proveedores`)
- Sucursales (`cat_sucursales`)
- Almacenes (`cat_almacenes`)

**Seguridad** (15 tablas) ⭐⭐⭐⭐
- Spatie Permission
- 7 roles, 45 permisos

---

## 4. INTEGRACIÓN POS ↔ TERRENA

### 4.1 Flujo de Datos

```
1. POS crea ticket
   public.ticket → trigger: trg_assign_daily_folio
   
2. Ingesta a Terrena
   fn_ingesta_ticket() → inv_consumo_pos
   
3. Expansión de consumo
   fn_expandir_consumo_ticket() → inv_consumo_pos_det
   (usa pos_map para recetas)
   
4. Registro en inventario
   mov_inv (tipo: CONSUMO_POS)
```

### 4.2 Funciones Críticas de Integración

| Función | Propósito | Estado Doc |
|---------|-----------|------------|
| fn_expandir_consumo_ticket() | Expande ticket a ingredientes | ❌ Sprint 2 |
| fn_confirmar_consumo() | Confirma consumo en inventario | ❌ Sprint 2 |
| fn_reversar_consumo() | Reversa tickets anulados | ❌ Sprint 2 |
| assign_daily_folio() | Asigna folio único diario | ✅ OK |
| fn_normalizar_forma_pago() | Normaliza formas de pago | ✅ OK |

### 4.3 Triggers de Integración

| Trigger | Tabla | Función |
|---------|-------|---------|
| trg_assign_daily_folio | public.ticket | Folio único |
| trg_selemti_tx_ai_forma_pago | public.transactions | Normaliza pagos |
| trg_selemti_dah_ai | public.drawer_assigned_history | Actualiza sesión |

---

## 5. COSTEO Y RECETAS

### 5.1 Sistema de Versionado

```
receta (header)
  └─ receta_version (versiones)
       ├─ receta_insumo (ingredientes)
       ├─ recipe_cost_snapshot (costos históricos)
       └─ pos_map (mapeo POS ↔ receta)
```

**Función clave**: `fn_recipe_cost_at(recipe_id, fecha)` → ❌ Sprint 2

### 5.2 BOM Implosion

**Función clave**: `fn_recipes_using_item(item_id)` → ❌ Sprint 2  
**Uso**: "¿Qué recetas usan este insumo?"

**Impacto**:
- Análisis de cambios de precio
- Falta de stock cascada
- Reportes de uso

---

## 6. INVENTARIO Y KARDEX

### 6.1 Arquitectura de Inventario

```
items (catálogo maestro)
  ├─ mov_inv (kardex - TODOS los movimientos)
  │    ├─ tipo: ENTRADA (recepciones)
  │    ├─ tipo: SALIDA (consumos, transferencias)
  │    ├─ tipo: AJUSTE (conteos físicos)
  │    └─ tipo: MERMA (desperdicios)
  │
  ├─ inventory_batch (lotes - trazabilidad)
  │    └─ cost_layer (capas de costo FIFO)
  │
  └─ stock_policy (min/max por almacén)
```

### 6.2 Tipos de Movimientos

| Tipo | Origen | Afecta Stock |
|------|--------|--------------|
| ENTRADA | Recepciones, Producción | ✅ Aumenta |
| SALIDA | Consumo POS, Transferencias | ✅ Disminuye |
| AJUSTE | Conteos físicos | ✅ Ajusta |
| MERMA | Desperdicios | ✅ Disminuye |

### 6.3 Políticas de Stock

```sql
stock_policy:
  - min (mínimo recomendado)
  - max (máximo recomendado)
  - reorder_point (punto de reorden)
  - reorder_qty (cantidad a ordenar)
  - algoritmo (MIN_MAX, SMA, POS_CONSUMPTION)
```

---

## 7. MOTOR DE REPLENISHMENT (SPRINT 1)

### 7.1 Algoritmos

**Min-Max**:
```
Si stock_actual < min:
  sugerencia = max - stock_actual
```

**SMA (Simple Moving Average)**:
```
promedio_consumo_30d = SUM(mov_inv.cantidad) / 30
stock_dias = stock_actual / promedio_consumo_30d
Si stock_dias < 7:
  sugerencia = promedio_consumo_30d * 14
```

**POS Consumption**:
```
Analiza tickets expandidos (fn_expandir_consumo_ticket)
Proyecta consumo basado en forecast ventas
```

### 7.2 Tablas Nuevas (Sprint 1)

- `replenishment_config` (configuración por ítem)
- `purchase_suggestions` (sugerencias generadas)
- `purchase_suggestion_history` (auditoría)

---

## 8. STATE MACHINES

### 8.1 Recepciones (Sprint 1: INV-002)

```
BORRADOR (editable, no afecta inventario)
  ↓ validar()
VALIDADA (no editable, no afecta inventario)
  ↓ postear()
POSTEADA (irreversible, genera mov_inv + lote)
```

**Permisos**:
- `recepciones.crear` → BORRADOR
- `recepciones.validar` → VALIDADA
- `recepciones.postear` → POSTEADA

### 8.2 Transferencias (Sprint 1: INV-003)

```
PENDIENTE (creada, no ha salido de origen)
  ↓ despachar()
EN_TRANSITO (salió de origen, no llegó a destino)
  ↓ recibir()
RECIBIDA (completada, genera 2 mov_inv: SALIDA origen + ENTRADA destino)
```

**Permisos**:
- `transferencias.crear` → PENDIENTE
- `transferencias.despachar` → EN_TRANSITO
- `transferencias.recibir` → RECIBIDA

### 8.3 Caja Chica (Ya implementado)

```
SOLICITADO (captura inicial)
  ↓ aprobar()
APROBADO (puede gastarse)
  ↓ liquidar()
LIQUIDADO (cerrado con evidencias)
```

---

## 9. DEPLOYMENT Y ENTORNOS

### 9.1 Configuración Producción

**URL**: http://100.126.124.101/terrena2/  
**BD**: PostgreSQL 14+  
**Apache Alias**: `/terrena2`  
**RewriteBase**: `/terrena2/`  

**⚠️ CRÍTICO**: Assets deben cargarse con RewriteBase

### 9.2 Migraciones en Producción

```bash
# Backup BD
pg_dump -h localhost -U postgres pos > backup_$(date +%Y%m%d).sql

# Migrar
php artisan migrate

# Rollback si falla
php artisan migrate:rollback
```

### 9.3 Testing Pre-Deployment

- [ ] Tests unitarios passing (80% coverage)
- [ ] Tests integración passing
- [ ] Staging validation con datos reales
- [ ] Performance testing (queries <100ms)
- [ ] Rollback plan probado

---

## 10. CONVENCIONES

### 10.1 Nomenclatura BD

```
Tablas:
  *_cab / *_det      → Cabecera/Detalle
  cat_*              → Catálogos
  hist_* / historial_* → Históricos
  *_audit_log        → Auditoría

Campos:
  id                 → Primary Key
  *_id               → Foreign Keys
  created_at, updated_at → Timestamps
  activo             → boolean
  
Schemas:
  selemti.*          → SIEMPRE en modelos
  public.*           → POS legacy
```

### 10.2 Nomenclatura Código

```php
// Modelo Eloquent
protected $connection = 'pgsql';  // OBLIGATORIO
protected $table = 'selemti.tabla';  // OBLIGATORIO con schema

// Servicio
namespace App\Services\Modulo;
class ModuloService { }

// Livewire
namespace App\Livewire\Modulo;
class ComponenteNombre extends Component { }

// API Controller
namespace App\Http\Controllers\Api\Modulo;
class ControllerNombre extends Controller { }
```

---

## 11. FUNCIONES CRÍTICAS

### 11.1 Costeo

| Función | Módulo | Estado Doc |
|---------|--------|------------|
| fn_recipe_cost_at() | Recetas | ❌ Sprint 2 |
| fn_item_unit_cost_at() | Inventario | ❌ Sprint 2 |
| recalcular_costos_periodo() | Finanzas | ❌ Sprint 2 |

### 11.2 Integración POS

| Función | Módulo | Estado Doc |
|---------|--------|------------|
| fn_expandir_consumo_ticket() | POS | ❌ Sprint 2 |
| fn_confirmar_consumo() | POS | ❌ Sprint 2 |
| fn_reversar_consumo() | POS | ❌ Sprint 2 |

### 11.3 BOM

| Función | Módulo | Estado Doc |
|---------|--------|------------|
| fn_recipes_using_item() | Recetas | ❌ Sprint 2 |
| fn_consolidar_stock() | Inventario | ❌ Sprint 2 |

**Total**: 12 funciones críticas → Sprint 2 (20h documentación)

---

## 12. MÉTRICAS DE CALIDAD

### 12.1 Post-Refactor

```
BD ↔ Código:       90% ✅
MISMATCH:          0
FANTASMA:          0
ERROR_REF:         0
Riesgo residual:   BAJO
```

### 12.2 Cobertura

```
Tablas documentadas:  54% ⚠️
Funciones documentadas: 32% 🔴
Modelos Eloquent:     44% ⚠️
Tests:                65% ⚠️
```

### 12.3 Estado por Módulo

```
P0 (5 módulos):  90% ✅
P1 (3 módulos):  95% ✅
P2 (2 módulos):  92% ✅
Promedio:        92% ✅
```

---

## 13. ROADMAP

**Sprint 1**: Funcionalidad crítica (55h)  
**Sprint 2**: Documentación BD (51h)  
**Sprint 3**: Docs módulos (42h)  
**Sprint 4-8**: Consolidación (192h)

**Total**: 340 horas / 8 sprints / 16 semanas

---

## 14. REFERENCIAS RÁPIDAS

**Documentación**:
- `docs/V4.0/00_Orquestador/` - Documentos maestros
- `docs/V4.0/BaseDatos/` - BD completa
- `docs/V4.0/Code/` - Refactor BD↔Código
- `docs/V4.0/<Módulo>/` - Docs por módulo

**Comandos**:
```bash
# Laravel
php artisan migrate
php artisan check:db-code-consistency

# PostgreSQL
psql -h localhost -p 5433 -U postgres -d pos
\dt selemti.*
\df selemti.*

# Git
git checkout -b feature/modulo-descripcion
git commit -m "feat(modulo): descripción"
```

---

**Última actualización**: 18 Noviembre 2025  
**Versión**: 4.1 (POST-REFACTOR)  
**Responsable**: MAESTRO
