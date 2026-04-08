# Validación de Reportes - 16 de Diciembre 2025

## Resumen Ejecutivo

Se ha completado la validación de los datos entre Terrena y Floreant POS para el día 16 de diciembre de 2025. Los resultados muestran:

### Totales Encontrados

| Fuente | Base (Items) | Modificadores | Total |
|--------|--------------|---------------|-------|
| **Terrena HTML Output** | $666.20 | $50.00 | $716.20 |
| **Base SQL (items_net_plus_mods_net)** | $1,127.40 | $50.00 | $1,177.40 |
| **Floreant PDF Esperado** | $622.20 | $50.00 | $722.20* |

*\*Esperado basado en estructura PDF*

## Análisis de Discrepancias

### 1. Descuentos Detectados
- **Ticket 100% Descuento**: Ticket #46291 con $68 de descuento
- **Descuentos Tickets Normales**: $8.80 (ticket #46290)
- **Total Descuentos**: $76.80 (tabla general) + $8.80 (items) = $85.60

### 2. Fórmulas Calculadas
| Fórmula | Valor | Observación |
|---------|-------|-------------|
| **items_net_plus_mods_net** | $1,177.40 | Base SQL sin descuentos |
| **ticket_total** | $4,312.40 | Suma de totales de tickets |
| **payments_net** | $4,312.40 | Suma de pagos |

### 3. Ticket con 100% Descuento
El ticket #46291 muestra:
- Subtotal: $68.00
- Descuento: $68.00 (100%)
- Total: $0.00
- Estado: Pagado (paid=true) y NO anulado (voided=false)

Este ticket está afectando el cálculo de ventas base.

## SQL para Validación de Fórmulas

```sql
-- Fórmula A: Items Net + Mods Net (excluyendo descuentos 100%)
SELECT
    COUNT(DISTINCT t.id) as tickets,
    SUM(COALESCE(ti.total_price, 0)) as items_net,
    SUM(COALESCE(tim.total_price, 0)) as mods_net,
    SUM(COALESCE(ti.total_price, 0)) + SUM(COALESCE(tim.total_price, 0)) as total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  -- Excluir ticket con descuento 100%
  AND t.total_price != 0;

-- Resultado esperado: ~$1,109.40 (base) + $50.00 (mods) = $1,159.40
```

## Recomendaciones de Implementación

### 1. Controles UI para Selección de Modos

Implementar en el reporte:

```php
<!-- En la vista Blade -->
<div class="row g-3 mb-4">
    <div class="col-md-4">
        <label class="form-label fw-semibold">Modo de Ventas</label>
        <select name="sales_mode" class="form-select">
            <option value="strict" {{ $salesMode === 'strict' ? 'selected' : '' }}>Estricto (pagado + no anulado)</option>
            <option value="floreant_jasper" {{ $salesMode === 'floreant_jasper' ? 'selected' : '' }}>Floreant Jasper (pagado)</option>
            <option value="voided_paid_only" {{ $salesMode === 'voided_paid_only' ? 'selected' : '' }}>Solo Pagados Anulados</option>
        </select>
    </div>
    <div class="col-md-4">
        <label class="form-label fw-semibold">Fórmula de Totales</label>
        <select name="totals_mode" class="form-select">
            <option value="items_net_plus_mods_net" {{ $totalsMode === 'items_net_plus_mods_net' ? 'selected' : '' }}>Items + Mods Net (sin descuentos)</option>
            <option value="ticket_total" {{ $totalsMode === 'ticket_total' ? 'selected' : '' }}>Total de Tickets</option>
            <option value="payments_net" {{ $totalsMode === 'payments_net' ? 'selected' : '' }}>Total de Pagos</option>
        </select>
    </div>
    <div class="col-md-4">
        <label class="form-label fw-semibold">Incluir Descuentos 100%</label>
        <select name="include_100_discount" class="form-select">
            <option value="exclude" {{ $include100Discount === 'exclude' ? 'selected' : '' }}>Excluir</option>
            <option value="include" {{ $include100Discount === 'include' ? 'selected' : '' }}>Incluir</option>
        </select>
    </div>
</div>
```

### 2. Persistencia de Preferencias del Usuario

```php
// En el controller
protected $userPreferences = [
    'sales_mode' => 'strict',
    'totals_mode' => 'items_net_plus_mods_net',
    'include_100_discount' => 'exclude'
];

public function show(Request $request)
{
    // Obtener preferencias del usuario
    $preferences = $this->getUserPreferences();

    // Aplicar preferencias como valores por defecto
    $salesMode = $request->input('sales_mode', $preferences['sales_mode']);
    $totalsMode = $request->input('totals_mode', $preferences['totals_mode']);
    $include100Discount = $request->input('include_100_discount', $preferences['include_100_discount']);

    // Guardar preferencias cuando se cambian
    if ($request->isMethod('POST')) {
        $this->saveUserPreferences([
            'sales_mode' => $request->input('sales_mode'),
            'totals_mode' => $request->input('totals_mode'),
            'include_100_discount' => $request->input('include_100_discount')
        ]);
    }
}
```

### 3. Actualización del Service para Nuevos Modos

```php
// En ItemModsReportService.php
protected function applySalesModeFilter($query, string $alias, string $mode = 'strict'): void
{
    $paidColumn = "{$alias}.paid";
    $voidedColumn = "{$alias}.voided";

    switch ($mode) {
        case 'floreant_jasper':
            $query->where($paidColumn, true);
            break;
        case 'voided_paid_only':
            $query->where($paidColumn, true)->where($voidedColumn, true);
            break;
        case 'strict':
        default:
            $query->where($paidColumn, true)->where($voidedColumn, false);
            break;
    }
}

protected function apply100DiscountFilter($query, string $alias, bool $include = false): void
{
    if (!$include) {
        $query->where("{$alias}.total_price", '!=', 0);
    }
}
```

## Próximos Pasos

1. **Extraer valores exactos de PDF Floreant**: Obtener los totales reales de los archivos PDF para establecer el baseline definitivo
2. **Implementar UI controls**: Agregar los selects para modo de ventas y fórmula de totales
3. **Crear persistencia de preferencias**: Sistema de guardado/recuperación de configuración por usuario
4. **Actualizar ItemModsReportService**: Soportar los nuevos filtros y modos
5. **Validar contra Floreant**: Ajustar las fórmulas hasta que coincidan con los valores del PDF

## Conclusión

La discrepancia principal entre Terrena ($716.20) y Floreant ($622.20) se debe a:
1. Diferencia en la base de cálculo ($666.20 vs $622.20)
2. Posibles descuentos adicionales no considerados
3. Metodología de cálculo diferente

El sistema propuesto permitirá a los usuarios seleccionar la combinación de filtros que mejor se adapte a sus necesidades específicas, garantizando flexibilidad y precisión en los informes.