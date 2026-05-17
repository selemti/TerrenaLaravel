# PROMPT GEMINI — Error #2: Vista faltante `vw_item_last_price_pref`

## Contexto

TerrenaLaravel es un ERP de restaurante en Laravel 12 + PostgreSQL 9.5.

**Reglas críticas:**
- SOLO trabajar en schema `selemti` — nunca tocar `public` (es FloreantPOS, READ ONLY)
- PostgreSQL 9.5: NO usar `ADD COLUMN IF NOT EXISTS`; usar `DO $$ BEGIN ... EXCEPTION WHEN duplicate_column THEN NULL; END $$;`
- Usar `CREATE OR REPLACE VIEW` para vistas

---

## Problema

El componente Livewire `app/Livewire/Inventory/ItemsManage.php` hace un JOIN contra la vista
`selemti.vw_item_last_price_pref` (línea ~387) pero esta vista NO EXISTE en la BD local.

El query que la usa es:

```php
$itemsQuery = DB::connection('pgsql')
    ->table(DB::raw('selemti.items as i'))
    ->leftJoin(DB::raw('selemti.vw_item_last_price_pref as lp'), 'lp.item_id', '=', 'i.id')
    ->leftJoin(DB::raw('selemti.item_vendor as pv'), function ($join) {
        $join->on('pv.item_id', '=', 'i.id');
        $join->on(DB::raw('pv.vendor_id::text'), '=', 'lp.vendor_id');
        $join->where('pv.preferente', true);
    })
    ->select([
        // ...
        'lp.price as preferente_price',
        'lp.pack_qty as preferente_pack_qty',
        'lp.pack_uom as preferente_pack_uom',
        'lp.effective_from as preferente_effective_from',
    ]);
```

---

## Tablas disponibles en selemti (verificar con \d si hay duda)

- `selemti.items` — columnas clave: `id` (varchar), `item_code`, `nombre`, `unidad_medida_id`, `unidad_compra_id`, `costo_promedio`
- `selemti.item_vendor` — relación ítem-proveedor: `item_id`, `vendor_id`, `preferente` (bool), `presentacion`
- `selemti.vendor_quote_lines` — líneas de cotización: `item_id`, `vendor_id` (o via quote header), `unit_price`, `pack_qty`, `pack_uom`, `effective_date` (o similar)
- `selemti.vendor_quotes` — cotizaciones: `id`, `vendor_id`, `fecha`, `estado`
- `selemti.purchase_order_lines` — líneas de PO: `item_id`, `precio_unitario`, `qty`, `uom`
- `selemti.purchase_orders` — órdenes de compra: `id`, `vendor_id`, `fecha_emision`, `estado`

---

## Tarea

**Explorar** las tablas `vendor_quote_lines`, `vendor_quotes`, `purchase_order_lines`, `purchase_orders`
en la BD local (schema `selemti`) con `\d selemti.tabla` para ver columnas reales.

**Crear** la vista `selemti.vw_item_last_price_pref` que retorne por cada `item_id`:
- el **último precio de compra** conocido (de cotización aprobada o PO emitida)
- `vendor_id` del proveedor (como text)
- `price` — precio unitario
- `pack_qty` — cantidad por paquete (puede ser NULL)
- `pack_uom` — UOM del paquete (puede ser NULL)
- `effective_from` — fecha de vigencia del precio

La vista debe usar `DISTINCT ON (item_id)` o `ROW_NUMBER()` para devolver UN solo registro por ítem
(el más reciente).

**Ejemplo de estructura esperada:**

```sql
CREATE OR REPLACE VIEW selemti.vw_item_last_price_pref AS
SELECT DISTINCT ON (lq.item_id)
    lq.item_id,
    q.vendor_id::text AS vendor_id,
    lq.unit_price AS price,
    lq.pack_qty,
    lq.pack_uom,
    lq.effective_date AS effective_from
FROM selemti.vendor_quote_lines lq
JOIN selemti.vendor_quotes q ON q.id = lq.quote_id
WHERE q.estado = 'APROBADA'
ORDER BY lq.item_id, lq.effective_date DESC NULLS LAST;
```

> **Nota:** Ajustar nombres de columnas según lo que encuentres en `\d`. La estructura anterior
> es una guía, no un mandato literal.

**Si `vendor_quote_lines` no tiene precios**, usar `purchase_order_lines` como fuente alternativa:

```sql
-- Alternativa con POs
CREATE OR REPLACE VIEW selemti.vw_item_last_price_pref AS
SELECT DISTINCT ON (pol.item_id)
    pol.item_id,
    po.vendor_id::text AS vendor_id,
    pol.precio_unitario AS price,
    pol.qty AS pack_qty,
    pol.uom AS pack_uom,
    po.fecha_emision AS effective_from
FROM selemti.purchase_order_lines pol
JOIN selemti.purchase_orders po ON po.id = pol.order_id
WHERE po.estado IN ('EMITIDA', 'RECIBIDA', 'PARCIAL')
ORDER BY pol.item_id, po.fecha_emision DESC NULLS LAST;
```

---

## Verificación

Después de crear la vista, ejecutar:

```sql
-- Debe retornar filas (o vacío si no hay cotizaciones/POs — eso está bien)
SELECT * FROM selemti.vw_item_last_price_pref LIMIT 10;

-- Debe ejecutar sin errores (el JOIN LEFT no debe romper aunque la vista esté vacía)
SELECT i.id, i.nombre, lp.price, lp.effective_from
FROM selemti.items i
LEFT JOIN selemti.vw_item_last_price_pref lp ON lp.item_id = i.id
LIMIT 10;
```

Reportar el resultado de ambas queries.
