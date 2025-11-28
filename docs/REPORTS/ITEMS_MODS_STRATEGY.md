# Estrategia: Reporte Concentrado de Ítems + Modificadores
**Fecha**: 26 de noviembre de 2025
**Autor**: Claude Code
**Estado**: Diseño aprobado para implementación

---

## 1. ANÁLISIS DEL CÓDIGO EXISTENTE

### Reporte actual (SalesModsController)
- **Función de BD**: `public.f_item_mods_on(date)`
- **Retorna**: folio_date, branch_key, terminal_id, ticket_id, ticket_item_id, item_name, modifier_name, qty_item, mods_count, mods_total_amount
- **Limitaciones**:
  - Un registro por ticket_item (no agrega)
  - No incluye categoría ni grupo
  - No permite agrupar por día
  - No tiene vista de resumen de ítems sin modificadores

### Estructura de base de datos (PostgreSQL 9.5)

**Tablas principales**:
```
ticket
├── id, folio_date, branch_key, terminal_id
├── closing_date, paid, voided
└── total_price

ticket_item
├── id, ticket_id, item_id
├── item_name, category_name, group_name
├── item_price, item_quantity, item_count
└── total_price, discount

ticket_item_modifier
├── id, ticket_item_id
├── item_id (FK to menu_modifier.id)
├── group_id (FK to menu_modifier_group.id)
├── modifier_name, modifier_price
├── item_count (cantidad del modificador)
└── total_price

menu_item
├── id, name, group_id
└── price

menu_group
├── id, name, category_id

menu_category
├── id, name

menu_modifier
├── id, name, group_id, price, extra_price

menu_modifier_group
├── id, name
```

---

## 2. ESTRATEGIA DE CONSULTAS

### 2.1 Base de Tickets Válidos (común para todas las vistas)

```sql
-- CTE reutilizable
WITH valid_tickets AS (
    SELECT
        t.id,
        t.folio_date,
        t.branch_key,
        t.terminal_id,
        t.closing_date
    FROM public.ticket t
    WHERE t.closing_date BETWEEN :start_date AND :end_date
      AND t.paid = true
      AND t.voided = false
      AND (:branch_ids IS NULL OR t.branch_key = ANY(:branch_ids))
      AND (:terminal_ids IS NULL OR t.terminal_id = ANY(:terminal_ids))
)
```

**Criterios de filtrado** (reutilizando lógica de Mix de Ventas):
- `paid = true` (tickets pagados)
- `voided = false` (no anulados)
- `closing_date` (fecha de cierre, NO created_date)
- Filtro opcional por sucursal(es)
- Filtro opcional por terminal(es)

---

### 2.2 Vista A: summary_items (Resumen por Ítem)

**Objetivo**: Agrupar ventas por Categoría → Grupo → Menú Item

**Query**:
```sql
WITH valid_tickets AS (...),
item_sales AS (
    SELECT
        ti.category_name AS categoria,
        ti.group_name AS grupo_menu,
        ti.item_name AS menu_item,
        ti.item_price AS precio_item,
        SUM(COALESCE(ti.item_quantity, ti.item_count, 0)) AS unidades_vendidas,
        SUM(ti.total_price) AS ingreso_bruto_item,
        SUM(COALESCE(ti.discount, 0)) AS descuento_item,
        SUM(ti.total_price - COALESCE(ti.discount, 0)) AS ingreso_neto_item
    FROM valid_tickets vt
    INNER JOIN public.ticket_item ti ON ti.ticket_id = vt.id
    GROUP BY ti.category_name, ti.group_name, ti.item_name, ti.item_price
    ORDER BY categoria, grupo_menu, menu_item
)
SELECT * FROM item_sales;
```

**Campos de salida**:
- `categoria` - Categoría del menú (ej: "Bebidas", "Alimentos")
- `grupo_menu` - Grupo del menú (ej: "Ensaladas", "Pastas")
- `menu_item` - Nombre del ítem
- `precio_item` - Precio base del ítem
- `unidades_vendidas` - Suma de cantidades vendidas
- `ingreso_bruto_item` - Ingreso total antes de descuentos
- `descuento_item` - Total de descuentos aplicados
- `ingreso_neto_item` - Ingreso después de descuentos

---

### 2.3 Vista B: summary_item_mods (Resumen Ítems + Modificadores) ⭐ PRINCIPAL

**Objetivo**: Agrupar por Categoría → Grupo → Item → Grupo Modificador → Modificador

**Query (SIN agrupación por día)**:
```sql
WITH valid_tickets AS (...),
item_mod_sales AS (
    SELECT
        ti.category_name AS categoria,
        ti.group_name AS grupo_menu,
        ti.item_name AS menu_item,
        mgr.name AS grupo_modificador,
        tim.modifier_name AS modificador,
        tim.modifier_price AS precio_extra_mod,
        vt.branch_key AS sucursal,
        vt.terminal_id AS terminal,
        -- Unidades del ítem (NO del modificador)
        SUM(COALESCE(ti.item_quantity, ti.item_count, 0)) AS unidades_item,
        -- Selecciones del modificador (cantidad de veces elegido)
        SUM(COALESCE(tim.item_count, 0)) AS selecciones_modificador,
        -- Monto adicional por modificador
        SUM(COALESCE(tim.modifier_price, 0) * COALESCE(tim.item_count, 0)) AS monto_extra_modificador
    FROM valid_tickets vt
    INNER JOIN public.ticket_item ti ON ti.ticket_id = vt.id
    INNER JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
    LEFT JOIN public.menu_modifier mm ON mm.id = tim.item_id
    LEFT JOIN public.menu_modifier_group mgr ON mgr.id = COALESCE(tim.group_id, mm.group_id)
    WHERE tim.modifier_name IS NOT NULL
    GROUP BY
        ti.category_name,
        ti.group_name,
        ti.item_name,
        mgr.name,
        tim.modifier_name,
        tim.modifier_price,
        vt.branch_key,
        vt.terminal_id
    ORDER BY categoria, grupo_menu, menu_item, grupo_modificador, modificador
)
SELECT * FROM item_mod_sales;
```

**Query (CON agrupación por día - group_by_day=1)**:
```sql
-- Agregar vt.folio_date en el SELECT y GROUP BY
SELECT
    vt.folio_date AS fecha,  -- ← AGREGAR ESTO
    ti.category_name AS categoria,
    ti.group_name AS grupo_menu,
    ti.item_name AS menu_item,
    mgr.name AS grupo_modificador,
    tim.modifier_name AS modificador,
    tim.modifier_price AS precio_extra_mod,
    vt.branch_key AS sucursal,
    vt.terminal_id AS terminal,
    SUM(COALESCE(ti.item_quantity, ti.item_count, 0)) AS unidades_item,
    SUM(COALESCE(tim.item_count, 0)) AS selecciones_modificador,
    SUM(COALESCE(tim.modifier_price, 0) * COALESCE(tim.item_count, 0)) AS monto_extra_modificador
FROM valid_tickets vt
INNER JOIN public.ticket_item ti ON ti.ticket_id = vt.id
INNER JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
LEFT JOIN public.menu_modifier mm ON mm.id = tim.item_id
LEFT JOIN public.menu_modifier_group mgr ON mgr.id = COALESCE(tim.group_id, mm.group_id)
WHERE tim.modifier_name IS NOT NULL
GROUP BY
    vt.folio_date,  -- ← AGREGAR ESTO
    ti.category_name,
    ti.group_name,
    ti.item_name,
    mgr.name,
    tim.modifier_name,
    tim.modifier_price,
    vt.branch_key,
    vt.terminal_id
ORDER BY fecha, categoria, grupo_menu, menu_item, grupo_modificador, modificador;
```

**Campos de salida**:
- `fecha` (solo si group_by_day=1)
- `categoria`, `grupo_menu`, `menu_item`
- `grupo_modificador` - Nombre del grupo de modificadores (ej: "Salsas", "Toppings")
- `modificador` - Nombre del modificador específico (ej: "Salsa Roja", "Extra Queso")
- `precio_extra_mod` - Precio unitario del modificador
- `sucursal` - Clave de la sucursal
- `terminal` - ID del terminal
- `unidades_item` - Unidades vendidas del ítem base
- `selecciones_modificador` - Número de veces que se eligió ese modificador
- `monto_extra_modificador` - Monto total adicional generado por ese modificador

**Ejemplo de resultado**:
```
categoria | grupo_menu | menu_item | grupo_modificador | modificador | precio_extra_mod | unidades_item | selecciones_modificador | monto_extra_modificador
----------|------------|-----------|-------------------|-------------|------------------|---------------|------------------------|------------------------
Picadas   | Picadas    | Picada    | Salsas            | Roja        | 0.00             | 125           | 50                     | 0.00
Picadas   | Picadas    | Picada    | Salsas            | Verde       | 15.00            | 125           | 75                     | 1,125.00
```

---

### 2.4 Vista C: detail (Detalle a nivel de ticket)

**Objetivo**: Trazabilidad fina, un registro por ticket-item-modifier

**Query**:
```sql
WITH valid_tickets AS (...)
SELECT
    vt.folio_date AS fecha,
    ti.item_name AS item,
    tim.modifier_name AS modificador,
    COALESCE(ti.item_quantity, ti.item_count, 0) AS cantidad_item,
    COALESCE(tim.item_count, 0) AS selecciones,
    COALESCE(tim.modifier_price, 0) * COALESCE(tim.item_count, 0) AS monto_extra,
    vt.branch_key AS sucursal,
    vt.terminal_id AS terminal,
    vt.id AS ticket_id,
    ti.id AS ticket_item_id
FROM valid_tickets vt
INNER JOIN public.ticket_item ti ON ti.ticket_id = vt.id
INNER JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE tim.modifier_name IS NOT NULL
ORDER BY vt.folio_date DESC, vt.id DESC, ti.id, tim.id;
```

**Campos de salida**:
- `fecha`, `item`, `modificador`
- `cantidad_item` - Cantidad del ítem en ese ticket
- `selecciones` - Veces que se eligió el modificador
- `monto_extra` - Monto adicional del modificador
- `sucursal`, `terminal`, `ticket_id`, `ticket_item_id`

---

## 3. KPIs EXISTENTES (mantener compatibilidad)

```php
$summary = [
    'total_items' => count(unique item_name),
    'total_modifiers' => count(unique modifier_name),
    'total_combinations' => count(distinct item+modifier pairs),
    'total_amount' => sum(monto_extra_modificador),
    'total_selections' => sum(selecciones_modificador),
    'avg_amount_per_selection' => total_amount / total_selections,
    'top_modifiers' => [
        ['modifier' => 'X', 'times_selected' => N, 'amount' => $M],
        // ... top 5 por monto
    ],
];
```

---

## 4. ARQUITECTURA DE IMPLEMENTACIÓN

### 4.1 Estructura de archivos

```
app/
├── Services/
│   └── Reports/
│       └── ItemModsReportService.php (NUEVO)
│
├── Http/
│   └── Controllers/
│       └── Reports/
│           └── SalesModsController.php (ACTUALIZAR)
│
├── Exports/
│   └── Reports/
│       └── ItemModsDetailExport.php (NUEVO)
│
resources/
└── views/
    └── reports/
        └── sales/
            ├── mods.blade.php (ACTUALIZAR)
            └── exports/
                └── mods.blade.php (ACTUALIZAR)

tests/
└── Feature/
    └── Reports/
        └── ItemModsReportTest.php (NUEVO)
```

### 4.2 Service Layer

**`app/Services/Reports/ItemModsReportService.php`**:

```php
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
        $view = $filters['view'] ?? 'summary_item_mods';
        $groupByDay = (bool) ($filters['group_by_day'] ?? false);
        $branchIds = $filters['branch_ids'] ?? null;
        $terminalIds = $filters['terminal_ids'] ?? null;

        return match ($view) {
            'summary_items' => $this->fetchSummaryItems(...),
            'summary_item_mods' => $this->fetchSummaryItemMods(...),
            'detail' => $this->fetchDetail(...),
            default => throw new \InvalidArgumentException("Invalid view: {$view}"),
        };
    }

    protected function buildValidTicketsCTE(Carbon $start, Carbon $end, $branchIds, $terminalIds): string
    {
        // Genera el CTE de tickets válidos
    }

    protected function fetchSummaryItems(...): Collection { }
    protected function fetchSummaryItemMods(...): Collection { }
    protected function fetchDetail(...): Collection { }

    public function summarize(Collection $data, string $view): array
    {
        // Calcula KPIs según la vista
    }
}
```

### 4.3 Controlador actualizado

**`app/Http/Controllers/Reports/SalesModsController.php`**:

```php
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
            'view' => $filters['view'],
            'groupByDay' => $filters['group_by_day'],
            'startDate' => $start,
            'endDate' => $end,
            'rows' => $dataset,
            'summary' => $summary,
            // ...
        ]);
    }

    protected function resolveFilters(Request $request): array
    {
        [$start, $end] = $this->parseDateRange($request);

        $filters = [
            'view' => $request->input('view', 'summary_item_mods'),
            'group_by_day' => (bool) $request->input('group_by_day', false),
            'branch_ids' => $this->normalizeFilterList($request->input('branch')),
            'terminal_ids' => $this->normalizeFilterList($request->input('terminal')),
        ];

        return [$start, $end, $filters];
    }
}
```

---

## 5. VALIDACIÓN CONTRA JASPERREPORT

### Test de integridad

```php
/** @test */
public function item_sales_match_jasper_report()
{
    // Dado un rango de fechas conocido
    $startDate = Carbon::parse('2025-11-01');
    $endDate = Carbon::parse('2025-11-07');

    // Cuando obtengo summary_items
    $result = $this->service->fetch($startDate, $endDate, ['view' => 'summary_items']);

    // Y comparo con totales esperados del Jasper "Item Sales"
    $totalUnits = $result->sum('unidades_vendidas');
    $totalAmount = $result->sum('ingreso_neto_item');

    $this->assertEquals(EXPECTED_UNITS_FROM_JASPER, $totalUnits);
    $this->assertEquals(EXPECTED_AMOUNT_FROM_JASPER, $totalAmount, 0.01);
}

/** @test */
public function modifier_sales_match_jasper_report()
{
    // Similar al anterior pero para "Modifier Sales"
    $result = $this->service->fetch($startDate, $endDate, ['view' => 'summary_item_mods']);

    $totalSelections = $result->sum('selecciones_modificador');
    $totalExtraAmount = $result->sum('monto_extra_modificador');

    $this->assertEquals(EXPECTED_SELECTIONS_FROM_JASPER, $totalSelections);
    $this->assertEquals(EXPECTED_EXTRA_FROM_JASPER, $totalExtraAmount, 0.01);
}

/** @test */
public function filters_by_branch_work_correctly()
{
    // Filtrar por una sucursal específica
    $result = $this->service->fetch($startDate, $endDate, [
        'branch_ids' => ['SUC1'],
        'view' => 'summary_item_mods',
    ]);

    // Todos los registros deben ser de esa sucursal
    $this->assertTrue($result->every(fn($row) => $row->sucursal === 'SUC1'));
}

/** @test */
public function group_by_day_adds_date_column()
{
    $result = $this->service->fetch($startDate, $endDate, [
        'group_by_day' => true,
        'view' => 'summary_item_mods',
    ]);

    // Debe tener columna 'fecha'
    $this->assertNotNull($result->first()->fecha);

    // Debe haber múltiples fechas
    $uniqueDates = $result->pluck('fecha')->unique()->count();
    $this->assertGreaterThan(1, $uniqueDates);
}
```

---

## 6. COMPATIBILIDAD CON EXPORTACIONES

### Excel (SalesModsExport)

```php
// ACTUALIZAR para soportar las 3 vistas
class SalesModsExport implements FromCollection, WithHeadings
{
    public function collection()
    {
        return $this->dataset; // Ya procesado por el servicio
    }

    public function headings(): array
    {
        return match ($this->view) {
            'summary_items' => [
                'Categoría', 'Grupo menú', 'Menú Item', 'Precio ítem',
                'Unidades vendidas', 'Ingreso bruto', 'Descuento', 'Ingreso neto'
            ],
            'summary_item_mods' => [
                'Categoría', 'Grupo menú', 'Menú Item', 'Grupo modificador',
                'Modificador', 'Precio extra', 'Unidades ítem',
                'Selecciones modificador', 'Monto extra modificador'
            ],
            'detail' => [
                'Fecha', 'Ítem', 'Modificador', 'Cantidad ítem',
                'Selecciones', 'Monto extra', 'Sucursal', 'Terminal'
            ],
        };
    }
}
```

---

## 7. INTERFAZ DE USUARIO

### Filtros adicionales

```blade
<!-- Agregar selector de vista -->
<div class="col-md-2">
    <label class="form-label fw-semibold">Vista</label>
    <select name="view" class="form-select">
        <option value="summary_items">Resumen ítems</option>
        <option value="summary_item_mods" selected>Ítems + modificadores</option>
        <option value="detail">Detalle completo</option>
    </select>
</div>

<!-- Agregar checkbox de agrupar por día -->
<div class="col-md-2">
    <div class="form-check mt-4">
        <input class="form-check-input" type="checkbox" name="group_by_day" value="1" id="groupByDay">
        <label class="form-check-label" for="groupByDay">
            Agrupar por día
        </label>
    </div>
</div>

<!-- Agregar selector de terminal -->
<div class="col-md-3">
    <label class="form-label fw-semibold">Terminales</label>
    <select name="terminal[]" class="form-select" multiple>
        <option value="">Todas</option>
        @foreach($terminals as $t)
            <option value="{{ $t->id }}">Terminal {{ $t->id }}</option>
        @endforeach
    </select>
</div>
```

---

## 8. VENTAJAS DE ESTA ESTRATEGIA

✅ **Reutiliza lógica de filtrado**: Mismo CTE que Mix de Ventas (paid=true, voided=false)
✅ **Sin SQL manual**: Todo usando Query Builder de Laravel
✅ **Flexible**: 3 vistas diferentes con un solo servicio
✅ **Escalable**: Fácil agregar más agrupaciones o filtros
✅ **Testeable**: Queries estructurados permiten tests de integración
✅ **Compatible**: Mantiene KPIs y exports existentes
✅ **Validable**: Tests específicos vs JasperReport

---

## 9. PRÓXIMOS PASOS

1. ✅ Crear `ItemModsReportService.php`
2. ✅ Actualizar `SalesModsController.php`
3. ✅ Actualizar vista `mods.blade.php`
4. ✅ Actualizar `SalesModsExport.php`
5. ✅ Crear tests de integración
6. ✅ Validar contra JasperReport con datos reales
7. ✅ Documentar en README

---

**FIN DE LA ESTRATEGIA**
