# TAREA PARA CODEX - Refactorización de Reportes de Ventas
**Fecha**: 28 de noviembre de 2025
**Prioridad**: 🔴 ALTA
**Tiempo estimado**: 6-8 horas
**Tipo**: BACKEND - Refactorización y Service Layer

---

## 🎯 OBJETIVO

Refactorizar los **3 reportes más complejos** del sistema siguiendo el patrón establecido en `ItemModsReportService`.

**Meta de refactorización**:
- ✅ Reducir controladores a < 200 líneas cada uno
- ✅ Mover lógica de negocio a Service layers
- ✅ Eliminar código duplicado
- ✅ Optimizar queries
- ✅ Mantener funcionalidad 100% compatible

---

## ⚠️ PRERREQUISITO CRÍTICO

**ANTES DE EMPEZAR**: Espera a que QWEN complete los 3 análisis:
- `docs/CODE_REVIEW/SALES_EXCEPTIONS_ANALYSIS.md`
- `docs/CODE_REVIEW/SALES_DETAIL_ANALYSIS.md`
- `docs/CODE_REVIEW/SALES_SUMMARY_ANALYSIS.md`

**Lee completamente estos análisis antes de codificar**.

---

## 📋 REPORTES A REFACTORIZAR (en orden)

### 1. SalesExceptionsController (42KB) 🔴 PRIMERA PRIORIDAD

**Ubicación**: `app/Http/Controllers/Reports/SalesExceptionsController.php`
**Service a crear**: `app/Services/Reports/SalesExceptionsReportService.php`
**Export a crear/actualizar**: `app/Exports/Reports/SalesExceptionsExport.php`

### 2. SalesDetailController (35KB) 🔴 SEGUNDA PRIORIDAD

**Ubicación**: `app/Http/Controllers/Reports/SalesDetailController.php`
**Service a crear**: `app/Services/Reports/SalesDetailReportService.php`
**Export a crear/actualizar**: `app/Exports/Reports/SalesDetailExport.php`

### 3. SalesSummaryController (26KB) 🟡 TERCERA PRIORIDAD

**Ubicación**: `app/Http/Controllers/Reports/SalesSummaryController.php`
**Service a crear**: `app/Services/Reports/SalesSummaryReportService.php`
**Export a crear/actualizar**: `app/Exports/Reports/SalesSummaryExport.php`

---

## 🏗️ PATRÓN DE REFERENCIA (ItemModsReportService)

**ESTUDIA ESTOS ARCHIVOS PRIMERO**:

### Archivo de referencia #1: ItemModsReportService
**Ubicación**: `app/Services/Reports/ItemModsReportService.php`

**Patrón a replicar**:
```php
<?php

namespace App\Services\Reports;

use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class ItemModsReportService
{
    /**
     * Obtiene datos según la vista solicitada
     */
    public function fetch(
        Carbon $startDate,
        Carbon $endDate,
        array $filters = []
    ): Collection {
        $view = $filters['view'] ?? 'default';

        return match ($view) {
            'vista1' => $this->fetchVista1(...),
            'vista2' => $this->fetchVista2(...),
            default => $this->fetchDefault(...),
        };
    }

    /**
     * Calcula KPIs según la vista
     */
    public function summarize(Collection $data, string $view): array
    {
        return match ($view) {
            'vista1' => $this->summarizeVista1($data),
            'vista2' => $this->summarizeVista2($data),
            default => [],
        };
    }

    protected function fetchVista1(...): Collection
    {
        // Query usando Query Builder (NO DB::select)
        return collect(DB::connection('pgsql')
            ->table('public.tabla')
            ->select(...)
            ->where(...)
            ->get());
    }

    protected function summarizeVista1(Collection $data): array
    {
        return [
            'total_x' => $data->sum('campo_x'),
            'total_y' => $data->count(),
            // ... más KPIs
        ];
    }
}
```

### Archivo de referencia #2: SalesModsController (refactorizado)
**Ubicación**: `app/Http/Controllers/Reports/SalesModsController.php`

**Patrón del controlador**:
```php
<?php

class SalesModsController extends BaseReportController
{
    public function __construct(
        protected ItemModsReportService $service
    ) {
        parent::__construct();
    }

    public function show(Request $request): View
    {
        [$start, $end, $filters] = $this->resolveFilters($request);

        $dataset = $this->service->fetch($start, $end, $filters);
        $summary = $this->service->summarize($dataset, $filters['view']);

        return view('reports.sales.mods', [
            'startDate' => $start,
            'endDate' => $end,
            'rows' => $dataset,
            'summary' => $summary,
            // ...
        ]);
    }

    public function exportExcel(Request $request): BinaryFileResponse
    {
        [$start, $end, $filters] = $this->resolveFilters($request);

        $dataset = $this->service->fetch($start, $end, $filters);
        $summary = $this->service->summarize($dataset, $filters['view']);

        $export = new SalesModsExport($start, $end, $dataset, $summary);

        return Excel::download($export, 'filename.xlsx');
    }

    protected function resolveFilters(Request $request): array
    {
        [$start, $end] = $this->parseDateRange($request);

        $filters = [
            'view' => $request->input('view', 'default'),
            'branch_ids' => $this->normalizeFilterList($request->input('branch')),
            // ... más filtros
        ];

        return [$start, $end, $filters];
    }
}
```

---

## 📐 ARQUITECTURA OBJETIVO

```
┌─────────────────────────────────────────────────────────┐
│                   CONTROLADOR                            │
│  • Recibir request                                       │
│  • Parsear filtros                                       │
│  • Llamar al servicio                                    │
│  • Retornar vista/export                                 │
│  < 200 líneas                                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                    SERVICIO                              │
│  • fetch(): obtener datos filtrados                      │
│  • summarize(): calcular KPIs                            │
│  • Métodos protected para queries específicos            │
│  • Toda la lógica de negocio                             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              QUERY BUILDER                               │
│  • DB::connection('pgsql')->table()                      │
│  • Queries optimizados                                   │
│  • Sin SQL crudo (evitar DB::select)                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│            POSTGRESQL (public)                           │
│  • ticket, ticket_item, etc.                             │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ CHECKLIST POR REPORTE

Para **CADA** reporte refactorizado, asegúrate de:

### Service Layer:
- [ ] Crear archivo `app/Services/Reports/{Nombre}ReportService.php`
- [ ] Método `fetch(Carbon $start, Carbon $end, array $filters): Collection`
- [ ] Método `summarize(Collection $data, string $view): array`
- [ ] Métodos protected para queries específicos
- [ ] Usar Query Builder (NO `DB::select()` crudo)
- [ ] Documentación PHPDoc completa
- [ ] Manejo de filtros (branch, terminal, etc.)

### Controller:
- [ ] Reducir a < 200 líneas
- [ ] Inyectar servicio en constructor
- [ ] Método `show()` simplificado
- [ ] Método `exportExcel()` simplificado
- [ ] Método `exportPdf()` simplificado (si existe)
- [ ] Método `resolveFilters()` para parsear request
- [ ] Eliminar toda lógica de negocio

### Export (si existe):
- [ ] Actualizar constructor para recibir datos procesados
- [ ] Eliminar queries del Export
- [ ] Recibir datos del Service
- [ ] Mantener compatibilidad con formatos

### Validación:
- [ ] La funcionalidad sigue igual (0 breaking changes)
- [ ] Queries retornan mismos resultados
- [ ] KPIs coinciden con versión anterior
- [ ] Exports generan archivos idénticos

---

## 🔧 INSTRUCCIONES TÉCNICAS

### 1. Uso de Query Builder (OBLIGATORIO)

**❌ NO HACER** (SQL crudo):
```php
$results = DB::connection('pgsql')->select("
    SELECT t.*, ti.*
    FROM public.ticket t
    JOIN public.ticket_item ti ON ti.ticket_id = t.id
    WHERE t.paid = true
");
```

**✅ HACER** (Query Builder):
```php
$results = DB::connection('pgsql')
    ->table('public.ticket as t')
    ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
    ->where('t.paid', true)
    ->select('t.*', 'ti.*')
    ->get();
```

### 2. Filtros comunes

Todos los reportes deben soportar:

```php
protected function applyCommonFilters($query, array $filters)
{
    // Filtro de sucursal
    if (!empty($filters['branch_ids'])) {
        $query->whereIn('t.branch_key', $filters['branch_ids']);
    }

    // Filtro de terminal
    if (!empty($filters['terminal_ids'])) {
        $query->whereIn('t.terminal_id', $filters['terminal_ids']);
    }

    // Tickets válidos
    $query->where('t.paid', true)
          ->where('t.voided', false);

    return $query;
}
```

### 3. Estructura de KPIs

```php
protected function summarize(Collection $data): array
{
    return [
        'total_records' => $data->count(),
        'total_amount' => round($data->sum('amount'), 2),
        'total_items' => $data->pluck('item')->unique()->count(),
        'avg_ticket' => $data->avg('ticket_total'),
        // ... más KPIs según el reporte
    ];
}
```

### 4. Manejo de fechas

```php
protected function buildDateFilter(Carbon $start, Carbon $end)
{
    return [
        $start->format('Y-m-d 00:00:00'),
        $end->format('Y-m-d 23:59:59')
    ];
}

// Uso en query
$query->whereBetween('t.closing_date', $this->buildDateFilter($start, $end));
```

---

## 🧪 VALIDACIÓN DE REFACTORIZACIÓN

### Antes de hacer commit:

1. **Ejecutar con datos reales**:
```bash
php artisan tinker
$service = app(App\Services\Reports\{Nombre}ReportService::class);
$start = Carbon::parse('2025-11-10');
$end = Carbon::parse('2025-11-18');
$data = $service->fetch($start, $end, []);
$summary = $service->summarize($data, 'default');
print_r($summary);
```

2. **Comparar totales**: Los KPIs deben coincidir con la versión anterior

3. **Probar filtros**:
```php
// Con filtro de sucursal
$data = $service->fetch($start, $end, ['branch_ids' => ['PRINCIPAL']]);

// Con agrupación (si aplica)
$data = $service->fetch($start, $end, ['group_by_day' => true]);
```

4. **Probar exports**:
   - Generar Excel desde la UI
   - Verificar que el archivo se genera correctamente
   - Comparar con archivo anterior (mismas columnas, mismos totales)

---

## 📝 DOCUMENTACIÓN REQUERIDA

Para cada reporte refactorizado, crear:

### Archivo: `docs/REPORTS/{NOMBRE}_REFACTOR.md`

```markdown
# Refactorización de {Nombre del Reporte}
**Fecha**: 28-Nov-2025
**Desarrollador**: CODEX
**Basado en análisis**: QWEN

---

## Cambios Realizados

### Service Layer Creado
- `app/Services/Reports/{Nombre}ReportService.php`
- Métodos: fetch(), summarize()
- Queries optimizados con Query Builder

### Controller Simplificado
- Reducido de {X}KB a {Y}KB
- Lógica movida al servicio
- Solo maneja request/response

### Exports Actualizados
- Recibe datos procesados del servicio
- Sin queries propios

---

## Validación

### Datos de Prueba
- Rango: 2025-11-10 a 2025-11-18
- Registros originales: {X}
- Registros refactorizados: {X} ✅
- Total original: ${Y}
- Total refactorizado: ${Y} ✅

### Filtros Probados
- ✅ Filtro por sucursal
- ✅ Filtro por terminal
- ✅ Filtro por fecha
- ✅ Agrupación (si aplica)

### Exports Probados
- ✅ Excel genera archivo válido
- ✅ PDF genera archivo válido (si aplica)
- ✅ Datos coinciden con vista

---

## Métricas

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Líneas Controller | {X} | {Y} | {Z}% |
| Queries optimizados | No | Sí | ✅ |
| Service layer | No | Sí | ✅ |
| Testeable | Difícil | Fácil | ✅ |
```

---

## 🚨 REGLAS CRÍTICAS

### ✅ DEBES:
- ✅ Usar Query Builder para todos los queries
- ✅ Mantener 100% de compatibilidad con API actual
- ✅ Documentar cada cambio
- ✅ Validar con datos reales antes de commit
- ✅ Seguir el patrón de ItemModsReportService
- ✅ Reducir controladores a < 200 líneas
- ✅ Crear tests básicos (opcional pero recomendado)

### ❌ NO DEBES:
- ❌ Cambiar nombres de rutas
- ❌ Cambiar estructura de responses
- ❌ Romper exports existentes
- ❌ Modificar vistas Blade (por ahora)
- ❌ Cambiar esquema de base de datos
- ❌ Usar SQL crudo (DB::select)

---

## 📦 ENTREGA POR REPORTE

Para cada reporte completado, crear un **Pull Request separado**:

### PR #1: SalesExceptionsController
**Branch**: `codex/refactor-sales-exceptions`
**Archivos**:
- `app/Services/Reports/SalesExceptionsReportService.php` (nuevo)
- `app/Http/Controllers/Reports/SalesExceptionsController.php` (modificado)
- `app/Exports/Reports/SalesExceptionsExport.php` (modificado si existe)
- `docs/REPORTS/SALES_EXCEPTIONS_REFACTOR.md` (nuevo)
- `tests/Feature/Reports/SalesExceptionsTest.php` (nuevo, opcional)

### PR #2: SalesDetailController
**Branch**: `codex/refactor-sales-detail`
**Archivos**: [misma estructura]

### PR #3: SalesSummaryController
**Branch**: `codex/refactor-sales-summary`
**Archivos**: [misma estructura]

---

## ⏱️ TIEMPO ESTIMADO

| Reporte | Análisis inicial | Desarrollo | Testing | Total |
|---------|-----------------|------------|---------|-------|
| Exceptions | 1h | 2-3h | 1h | 4-5h |
| Detail | 1h | 2-3h | 1h | 4-5h |
| Summary | 30min | 1-2h | 30min | 2-3h |
| **TOTAL** | 2.5h | 5-8h | 2.5h | **10-13h** |

---

## 🎯 CRITERIOS DE ÉXITO

Tu trabajo será exitoso si:

✅ Los 3 controladores están < 200 líneas cada uno
✅ Los 3 servicios están creados y funcionan
✅ Todos los queries usan Query Builder
✅ La funcionalidad es 100% compatible
✅ Los exports funcionan igual que antes
✅ Documentación completa de cada refactor
✅ PRs separados y bien documentados
✅ Código sigue estándares de Laravel

---

## 🚀 ORDEN DE EJECUCIÓN

1. ✅ Espera análisis de QWEN (prerrequisito)
2. 📖 Lee los 3 análisis completos
3. 🔍 Estudia ItemModsReportService y SalesModsController
4. 🏗️ Refactoriza SalesExceptionsController (el más urgente)
5. ✅ Valida y crea PR #1
6. 🏗️ Refactoriza SalesDetailController
7. ✅ Valida y crea PR #2
8. 🏗️ Refactoriza SalesSummaryController
9. ✅ Valida y crea PR #3
10. 📝 Notifica completado

---

**Última actualización**: 28-Nov-2025
**Creado por**: Claude Code
**Para**: CODEX (agente de backend)
**Depende de**: QWEN_TASK_REPORTES_ANALISIS.md
