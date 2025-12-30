# Reportes - Estado General
**Última actualización**: 28 de noviembre de 2025
**Autor**: Claude Code

---

## 📊 Resumen Ejecutivo

TerrenaLaravel cuenta con **14 controladores de reportes** organizados en:
- **10 reportes de ventas** (Sales*)
- **1 reporte de menú** (MenuUsage)
- **1 reporte de tickets abiertos** (OpenTickets)
- **2 controladores base** (Base, Index)

---

## ✅ Reportes Completados

### 1. **Ítems y Modificadores** (SalesModsController) ⭐ RECIÉN ACTUALIZADO

**Ruta**: `/reports/sales/mods`
**Estado**: ✅ **Completado y validado** (26-28 Nov 2025)
**Vista nueva**: `view=item_mod_combos` (agrupa ítem + todos sus modificadores en una sola línea, usando los grupos del catálogo aunque `ticket_item_modifier.group_id` venga nulo).

**Características**:
- ✅ 3 vistas diferentes:
  - `summary_items`: Resumen por Categoría → Grupo → Ítem
  - `summary_item_mods`: Resumen Ítems + Modificadores ⭐ principal
  - `detail`: Detalle a nivel de ticket
- ✅ 4ta vista: `item_mod_combos` (combinaciones completas de un ítem con todos sus modificadores seleccionados en el ticket).
- ✅ Filtros: sucursal, terminal, agrupación por día
- ✅ Service layer completo (`ItemModsReportService`)
- ✅ Exportación Excel/PDF
- ✅ Tests de integración (11 tests)
- ✅ Documentación completa

**Archivos**:
- Controller: `app/Http/Controllers/Reports/SalesModsController.php`
- Service: `app/Services/Reports/ItemModsReportService.php`
- Export: `app/Exports/Reports/SalesModsExport.php`
- Vista: `resources/views/reports/sales/mods.blade.php`
- Partials: `resources/views/reports/sales/partials/mods-*.blade.php` (7 archivos)
- Tests: `tests/Feature/Reports/ItemModsReportTest.php`
- Docs: `docs/REPORTS/ITEMS_MODS_STRATEGY.md`

**Validación**:
- ✅ Probado con datos reales (Nov 10-18, 2025)
- ✅ 279 registros, $6,835 en modificadores
- ✅ Filtros funcionan correctamente

---

### 2. **Mix de Ventas** (SalesMixController)

**Ruta**: `/reports/sales/mix`
**Estado**: ✅ Completado (implementado previamente)

**Características**:
- Análisis de ventas por categoría
- Filtros por fecha y sucursal
- Exportación Excel/PDF
- Gráficos de distribución

**Archivos**:
- Controller: `app/Http/Controllers/Reports/SalesMixController.php` (20KB)

---

### 3. **Tickets Abiertos** (OpenTicketsController)

**Ruta**: No documentada
**Estado**: ⚠️ Implementado pero sin validar

**Archivos**:
- Controller: `app/Http/Controllers/Reports/OpenTicketsController.php` (8KB)

---

## 📝 Reportes Existentes (Sin Validar)

### 4. **Balance de Ventas** (SalesBalanceController)

**Ruta**: `/reports/sales/balance`
**Estado**: ⚠️ Implementado pero sin validar

**Archivos**:
- Controller: `app/Http/Controllers/Reports/SalesBalanceController.php` (8KB)
- Vista: Probablemente en `resources/views/reports/sales/balance.blade.php`

**Próximos pasos**:
- Validar contra datos reales
- Documentar funcionalidad
- Agregar tests

---

### 5. **Detalle de Ventas** (SalesDetailController) ⚠️ GRANDE

**Ruta**: `/reports/sales/detail`
**Estado**: ⚠️ Implementado pero sin validar

**Archivos**:
- Controller: `app/Http/Controllers/Reports/SalesDetailController.php` (**35KB** - el más grande)

**Notas**:
- Archivo muy grande, probablemente complejo
- Requiere revisión y posible refactorización
- Candidato para Service layer

---

### 6. **Diagnósticos de Ventas** (SalesDiagController)

**Ruta**: `/reports/sales/diagnostics`
**Estado**: ⚠️ Implementado pero sin validar

**Archivos**:
- Controller: `app/Http/Controllers/Reports/SalesDiagController.php` (7KB)

---

### 7. **Cajón de Ventas** (SalesDrawerController)

**Ruta**: `/reports/sales/drawer`
**Estado**: ⚠️ Implementado pero sin validar

**Archivos**:
- Controller: `app/Http/Controllers/Reports/SalesDrawerController.php` (9KB)

**Funcionalidad probable**:
- Reporte de movimientos de cajón/caja
- Relacionado con módulo de Caja

---

### 8. **Excepciones de Ventas** (SalesExceptionsController) ⚠️ GRANDE

**Ruta**: `/reports/sales/exceptions`
**Estado**: ⚠️ Implementado pero sin validar

**Archivos**:
- Controller: `app/Http/Controllers/Reports/SalesExceptionsController.php` (**42KB** - el más grande)

**Notas**:
- Archivo MUY grande
- Probablemente maneja casos especiales/anómalos
- Requiere refactorización urgente

---

### 9. **Diario de Ventas** (SalesJournalController)

**Ruta**: `/reports/sales/journal` o `/reports/journal`
**Estado**: ⚠️ Implementado pero sin validar

**Archivos**:
- Controller: `app/Http/Controllers/Reports/SalesJournalController.php` (6KB)

---

### 10. **Resumen de Ventas** (SalesSummaryController) ⚠️ GRANDE

**Ruta**: `/reports/sales/summary`
**Estado**: ⚠️ Implementado pero sin validar

**Archivos**:
- Controller: `app/Http/Controllers/Reports/SalesSummaryController.php` (**26KB** - grande)

**Notas**:
- Archivo grande, probablemente complejo
- Candidato para Service layer

---

### 11. **Uso de Menú** (MenuUsageController)

**Ruta**: `/reports/menu/usage`
**Estado**: ⚠️ Implementado pero sin validar

**Archivos**:
- Controller: `app/Http/Controllers/Reports/MenuUsageController.php` (6KB)

**Funcionalidad probable**:
- Análisis de popularidad de items del menú
- Estadísticas de uso

---

## 🏗️ Arquitectura de Reportes

### Patrón Actual

```
Controller (Reports/*)
    ↓
BaseReportController (helper methods)
    ↓
PostgreSQL (public schema - POS data)
    ↓
View (resources/views/reports/*)
    ↓
Export (Excel/PDF)
```

### Patrón Mejorado (implementado en SalesMods)

```
Controller
    ↓
Service Layer (app/Services/Reports/*)
    ↓
Query Builder (filtros, agregaciones)
    ↓
Collection (procesamiento)
    ↓
View + Export
```

**Ventajas del nuevo patrón**:
- ✅ Separación de responsabilidades
- ✅ Tests más fáciles
- ✅ Código reutilizable
- ✅ Queries optimizadas
- ✅ Mejor mantenibilidad

---

## 🎯 Próximos Pasos Recomendados

### Fase 1: Validación (2-3 semanas)

**Prioridad Alta**:
1. **SalesDetailController** (35KB)
   - Validar con datos reales
   - Refactorizar a Service layer
   - Documentar funcionalidad

2. **SalesExceptionsController** (42KB)
   - Entender lógica de excepciones
   - Refactorizar (archivo muy grande)
   - Crear Service layer

3. **SalesSummaryController** (26KB)
   - Validar totales vs otros reportes
   - Refactorizar a Service layer

**Prioridad Media**:
4. **SalesBalanceController**
5. **SalesDrawerController**
6. **SalesDiagController**

**Prioridad Baja**:
7. **SalesJournalController**
8. **MenuUsageController**
9. **OpenTicketsController**

### Fase 2: Refactorización (3-4 semanas)

Para cada reporte:
1. Crear Service layer (siguiendo patrón de `ItemModsReportService`)
2. Mover lógica de negocio del Controller al Service
3. Optimizar queries (usar Query Builder)
4. Documentar en `docs/REPORTS/{nombre}_STRATEGY.md`

### Fase 3: Testing (2 semanas)

1. Crear tests de integración para cada reporte
2. Validar contra datos conocidos
3. Comparar con JasperReports (si aplica)

### Fase 4: Mejoras UX (1-2 semanas)

1. Unificar interfaz de usuario
2. Mejorar filtros
3. Agregar gráficos interactivos
4. Optimizar exportaciones

---

## 📈 Métricas de Código

| Controlador | Tamaño | Complejidad | Prioridad Refactor |
|-------------|--------|-------------|-------------------|
| SalesExceptionsController | 42KB | ⚠️ Muy Alta | 🔴 Urgente |
| SalesDetailController | 35KB | ⚠️ Alta | 🔴 Urgente |
| SalesSummaryController | 26KB | ⚠️ Alta | 🟡 Media |
| SalesMixController | 21KB | ⚠️ Media | 🟡 Media |
| BaseReportController | 13KB | ℹ️ Baja | 🟢 Baja |
| SalesModsController | 12KB | ✅ Baja | ✅ **Ya refactorizado** |
| SalesDrawerController | 10KB | ℹ️ Baja | 🟢 Baja |
| SalesBalanceController | 9KB | ℹ️ Baja | 🟢 Baja |
| OpenTicketsController | 8KB | ℹ️ Baja | 🟢 Baja |
| SalesDiagController | 7KB | ℹ️ Baja | 🟢 Baja |
| MenuUsageController | 6KB | ℹ️ Baja | 🟢 Baja |
| SalesJournalController | 6KB | ℹ️ Baja | 🟢 Baja |

**Totales**:
- Total de líneas de código: ~200KB
- Reportes sin refactorizar: 10/11 (91%)
- Reportes sin validar: 10/11 (91%)
- Reportes sin tests: 10/11 (91%)

---

## 🔗 Referencias

- **CLAUDE.md**: Documentación general del proyecto
- **ITEMS_MODS_STRATEGY.md**: Estrategia del reporte de Ítems y Modificadores
- **BaseReportController.php**: Métodos helper comunes
- **ItemModsReportService.php**: Ejemplo de Service layer

---

## 📝 Notas Importantes

1. **Base de datos**: Todos los reportes consultan PostgreSQL 9.5 (schema `public`)
2. **Filtros comunes**: fecha_inicio, fecha_fin, sucursal, terminal
3. **Exportaciones**: Excel (xlsx) y PDF estándar
4. **Criterios de filtrado**: `paid = true`, `voided = false`, `closing_date`
5. **Performance**: Algunos reportes pueden ser lentos con rangos grandes

---

**Última validación**: 28-Nov-2025
**Próxima revisión**: Diciembre 2025
**Responsable**: Equipo de desarrollo
