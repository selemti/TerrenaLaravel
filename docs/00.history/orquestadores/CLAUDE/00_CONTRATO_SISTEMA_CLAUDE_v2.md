# CONTRATO SISTEMA TERRENA POS/ERP v2 - CLAUDE

**Orquestador**: Claude Code
**Fecha**: 14 Noviembre 2025
**Fuentes**: FASE1-FASE6 (Auditoría 13 Nov 2025)
**Estado BD**: PostgreSQL 9.5, esquema selemti (147 tablas, 38 vistas, 37 funciones, 20 triggers)

---

## 1. OBJETIVO GENERAL

Terrena es un sistema ERP/POS integral para restaurantes multi-sucursal que gestiona el ciclo operativo completo: recepción de insumos, costeo y producción de recetas, registro de ventas POS y control financiero diario (cortes de caja). Proporciona una plataforma unificada para administración de recursos, control de costos en tiempo real y toma de decisiones basada en datos operativos consolidados.

---

## 2. ALCANCE COMPLETO (15 MÓDULOS CONFIRMADOS - FASE1)

| # | Módulo | Implementación | Documentación | Prioridad |
|---|--------|----------------|---------------|-----------|
| 1 | Inventario | 85% | 80% | 🔴 CRÍTICA |
| 2 | Recetas | 75% | 70% | 🔴 CRÍTICA |
| 3 | Producción | 60% | 55% | 🟡 ALTA |
| 4 | Purchasing | 85% | 85% | 🔴 CRÍTICA |
| 5 | POS | 70% | 60% | 🟡 ALTA |
| 6 | Ventas | 80% | 75% | 🔴 CRÍTICA |
| 7 | Caja | 95% | 95% | ✅ EXCELENTE |
| 8 | Caja Chica | 100% | 100% | ✅ EXCELENTE |
| 9 | Reportes | 90% | 90% | ✅ EXCELENTE |
| 10 | Finanzas | 65% | 70% | 🟢 MEDIA |
| 11 | Base de Datos | 90% | 75% | 🟡 ALTA |
| 12 | Frontend | 80% | 75% | 🟡 ALTA |
| 13 | Seguridad | 80% | 75% | 🟡 ALTA |
| 14 | Catálogos | 90% | 85% | ✅ BIEN |
| 15 | Transferencias | 75% | 60% | 🟡 ALTA |

---

## 3. FUENTE DE VERDAD

### 3.1 Documentación Canónica

**Única fuente oficial**: `docs/V4.0/`

**Estado actual (FASE2)**:
- 19 documentos activos
- 11/15 módulos cubiertos (73%)
- Score: 76% → Objetivo: 94%

### 3.2 Auditorías de Referencia

**Ubicación**: `docs/00.history/auditorias/AUDITORIA_2025_11_13/`

- FASE1: 729 archivos analizados (486 /docs + 243 D:\Tavo\2025\UX\)
- FASE2: V4.0 con 76% score, gaps identificados
- FASE3: 44 documentos objetivo, roadmap 12 días
- FASE4: 479 archivos código, 61% cobertura, 39% huérfano
- FASE5: 147 tablas BD, 90% alineación, funciones críticas sin doc
- FASE6: UX score 6.5/10, gaps críticos en forms/notificaciones

---

## 4. ARQUITECTURA TÉCNICA

### 4.1 Stack (Confirmado FASE4)

- Laravel 12 + PHP 8.2+
- PostgreSQL 9.5 (esquema selemti)
- Livewire 3.7 beta + Alpine.js
- Bootstrap 5 (+ Tailwind CSS 3 legacy)
- Vite 4.x
- Spatie Laravel Permission
- JWT (tymon/jwt-auth)

### 4.2 Base de Datos (FASE5)

**Esquema selemti**:
- 147 tablas (65 con modelos, 82 huérfanas)
- 38 vistas (28 documentadas)
- 37 funciones (12 documentadas, 25 críticas sin doc)
- 20 triggers activos (15 documentados)
- 100+ Foreign Keys
- 35 tablas legacy pendientes deprecación

**Tablas Críticas Top 10**:
1. audit_log (224 kB)
2. sesion_cajon (152 kB)
3. items (152 kB)
4. cat_uom_conversion (112 kB)
5. mov_inv (104 kB) - Kardex
6. cash_funds (96 kB)
7. replenishment_suggestions (96 kB)
8. sessions (96 kB)
9. personal_access_tokens (96 kB)
10. auditoria (88 kB)

**Funciones Críticas NO Documentadas**:
- fn_recipe_cost_at() - Costeo recetas (CORE)
- fn_recipes_using_item() - BOM Implosion (CLAVE)
- fn_item_unit_cost_at() - Costeo items (CORE)
- fn_expandir_consumo_ticket() - Expansión consumo (CORE)
- recalcular_costos_periodo() - Recalculo masivo (CRÍTICO)

### 4.3 Código (FASE4 - 479 archivos)

- 80 modelos (75% documentados)
- 64 controladores (70% documentados)
- 34 servicios (44% documentados ⚠️)
- 58 componentes Livewire (69% documentados)
- 76 migraciones (66% documentadas)
- 167 vistas Blade (48% documentadas ⚠️)

**Código Huérfano**: 189 archivos (39%)
**Código Duplicado Crítico**:
- PosConsumptionService.php (3 ubicaciones)
- ProductionService.php (2 ubicaciones)

---

## 5. PRINCIPIOS RECTORES

### P1. Consistencia Tríada Docs-Código-BD

Todo cambio DEBE reflejarse en:
1. Documentación (docs/V4.0/) - PRIMERO
2. Código (app/) - SEGUNDO
3. Base de Datos (selemti) - TERCERO

### P2. Modularidad Estricta

Cada módulo opera independiente con interfaces claras.

### P3. Backlog Centralizado

TODO el trabajo se registra en backlog oficial.

### P4. Convenciones de Código

**Modelos**:
```php
protected $connection = 'pgsql';
protected $table = 'selemti.table_name';
protected $guarded = [];
```

**Livewire**:
```php
// Naming: App\Livewire\{Module}\{Action}
public $search = '';
wire:model.live.debounce.400ms="search"
```

### P5. Regla de Oro para Agentes IA

NO modificar carpetas/módulos fuera de asignación específica.

---

## 6. GAPS CRÍTICOS (FASE2 + FASE4 + FASE5 + FASE6)

### 6.1 Código (FASE4)

**🔴 CRÍTICO**:
- Código duplicado (PosConsumptionService x3, ProductionService x2)
- Código huérfano: 189 archivos (39%)
- Servicios sin doc: 19 (44% cobertura)
- Modelos sin doc: 20
- Livewire sin doc: 18
- Migraciones sin doc: 26
- Vistas sin doc: 87

**Esfuerzo**: 116 horas (alcanzar 80%)

### 6.2 Base de Datos (FASE5)

**🔴 CRÍTICO**:
- Funciones críticas sin doc: 12 (32% cobertura)
- Tablas sin modelo: 82 (56%)
- Tablas legacy: 35 (24%)

**Esfuerzo**: 48 horas (alcanzar 95%)

### 6.3 UI/UX (FASE6 - Score 6.5/10)

**🔴 CRÍTICO**:
- Forms sin loading states: 0% (40 forms)
- Notificaciones rotas: 70% falla silencio
- Delete sin confirmación: 50%
- Modales fragmentados: 2 patrones
- Layout shift permisos async

**Esfuerzo**: 40-50 horas (alcanzar 8.0/10)

### 6.4 Documentación (FASE2)

**Faltantes**: 25 archivos (18 alta prioridad)

**Esfuerzo**: 48 horas (alcanzar 94%)

---

## 7. ROLES Y RESPONSABILIDADES

### 7.1 Orquestador (Claude)

- Coordinar agentes en módulos diferentes
- Gestionar dependencias cross-módulo
- Aprobar cambios estructurales
- Mantener matriz de alineación
- Gestionar backlog centralizado
- Auditar consistencia pre-merge

### 7.2 Agente de Módulo

- Implementar funcionalidades en módulo asignado
- Actualizar docs/V4.0/{modulo}/
- Crear migraciones BD
- Escribir tests
- Documentar APIs
- Notificar dependencias cross-módulo

### 7.3 Auditor Técnico

- Revisar consistencia docs-código-BD
- Validar tests
- Verificar convenciones
- Detectar duplicación
- Aprobar/rechazar PRs

---

## 8. REGLAS DE GOBERNANZA

### G1. Proceso de Cambios

**Menores**: Agente → Docs → PR → Auditor → Merge
**Cross-módulo**: Propuesta → Orquestador → Coordinación → Implementación paralela → Merge
**Estructurales**: Propuesta → Análisis impacto → Aprobación → Actualización CONTRATO → Implementación

### G2. Documentación Obligatoria

Antes: Especificación docs/V4.0/
Durante: PHPDoc, comentarios, tests
Después: README, matriz, backlog

### G3. Tests Obligatorios

Cobertura mínima: 70% código nuevo

### G4. Auditoría Pre-Merge

Tests + Linter + Checklist + Aprobación

---

## 9. CRITERIOS DE ÉXITO

### 9.1 Cobertura Documental
Objetivo: ≥ 90% (actual 76%)
Meta: 44 docs, 15/15 módulos, score 94%

### 9.2 Cobertura Código
Objetivo: ≥ 80% (actual 61%)
Huérfano: < 10% (actual 39%)

### 9.3 Alineación BD
Objetivo: ≥ 95% (actual 90%)
Funciones críticas: 100% doc
Tablas legacy: ≤ 3

### 9.4 UX Score
Objetivo: ≥ 8.0 (actual 6.5)
Forms loading: 100%
Notificaciones: unificadas
Confirmaciones: 100%

### 9.5 Tests
Objetivo: ≥ 70% cobertura

---

## 10. RESTRICCIONES

### NO Hacer
- Crear nuevos módulos
- Modificar estructura docs/V4.0/ sin aprobación
- Alterar esquema public (Floreant) sin confirmación
- Inventar funcionalidades no en FASE1-FASE6
- Modificar módulos fuera de asignación

### Siempre Hacer
- Actualizar docs ANTES de codear
- Especificar $connection y $table en modelos
- Agregar loading states en forms
- Confirmaciones en deletes
- Documentar funciones BD críticas
- Crear tests

---

## 11. MÉTRICAS

**Dashboard Orquestador**:
- Cobertura Documental: 76% → 94%
- Cobertura Código: 61% → 80%
- Alineación BD: 90% → 95%
- UX Score: 6.5 → 8.0
- Test Coverage: 30% → 70%
- Código Huérfano: 39% → <10%

---

**FIN CONTRATO v2 - CLAUDE**
