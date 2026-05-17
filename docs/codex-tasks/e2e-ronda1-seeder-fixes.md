# Codex Task — E2E Ronda 1: Fixes críticos en TransactionalFlowSeeder

## Contexto

La corrida E2E (MasterDataSeeder + TransactionalFlowSeeder) fue revisada por dos agentes
adversariales (antigravity + adversarial-review) y se detectaron 4 blockers que impiden
que la corrida sea válida como prueba de integración:

1. El seeder no es idempotente — duplica lotes y movimientos en cada corrida
2. `seedProduccion()` usa el primer input como output — los ítems PROD-* nunca se generan
3. `userId = 13` hardcodeado — revienta en ambiente limpio
4. `APERTURA` no está registrado en `cat_tipo_mov_inv`

**IMPORTANTE — Invariantes críticas del proyecto:**
- Nunca escribir en `public.*` — es FloreantPOS en producción
- Nunca agregar `public` a `DB_SCHEMA` en phpunit.xml
- Toda escritura es en `selemti.*`

---

## Fix 1 — Idempotencia de TransactionalFlowSeeder

**Archivo:** `database/seeders/E2E/TransactionalFlowSeeder.php`

El seeder debe ser seguro de re-ejecutar sin duplicar datos. Estrategia: usar una marca
de control basada en `mov_inv` con `ref_tipo = 'E2E_SEEDER'` y un `ref_id` único por paso.

### Cambios requeridos

**a) Agregar método `alreadyRan(string $step): bool`:**

```php
private function alreadyRan(string $step): bool
{
    return DB::connection('pgsql')
        ->table('selemti.mov_inv')
        ->where('ref_tipo', 'E2E_SEEDER')
        ->where('ref_id', crc32($step))  // deterministic int
        ->exists();
}
```

**b) En cada método seed, envolver con guard:**

```php
private function seedApertura(): void
{
    if ($this->alreadyRan('apertura')) {
        $this->command?->info('  ➜ Apertura: ya existe, omitiendo.');
        return;
    }
    // ... resto del código
}
```

Aplicar el mismo guard en: `seedRecepciones()`, `seedProduccion()`, `seedTraspaso()`, `seedConteo()`.

**c) En `seedApertura()`, al insertar en `mov_inv`, usar `ref_tipo = 'E2E_SEEDER'` y
`ref_id = crc32('apertura')` en la fila de control (una fila extra de tipo APERTURA
sirve como marca).**

**Alternativa más simple**: al inicio de `run()`, verificar si ya existe cualquier
`mov_inv WHERE tipo = 'APERTURA'` y preguntar al usuario si desea continuar:

```php
$existingApertura = DB::connection('pgsql')
    ->table('selemti.mov_inv')
    ->where('tipo', 'APERTURA')
    ->exists();

if ($existingApertura) {
    if (! $this->command?->confirm('Ya existe una corrida E2E. ¿Limpiar y re-ejecutar?', false)) {
        $this->command?->info('Corrida omitida.');
        return;
    }
    $this->limpiarCorrida();
}
```

Con `limpiarCorrida()` que elimina en orden FK-safe:
```php
private function limpiarCorrida(): void
{
    DB::connection('pgsql')->statement(<<<'SQL'
        DELETE FROM selemti.pos_ticket_item_processed WHERE user_id = :uid;
        DELETE FROM selemti.mov_inv WHERE tipo IN ('APERTURA','RECEPCION_COMPRA','PRODUCCION_SALIDA',
            'PRODUCCION_ENTRADA','MERMA','TRASPASO_SALIDA','TRASPASO_ENTRADA',
            'AJUSTE_ENTRADA','AJUSTE_SALIDA','VENTA_POS');
        DELETE FROM selemti.inventory_batch WHERE lote_proveedor LIKE 'E2E-%' OR lote_proveedor LIKE 'APERTURA-%';
    SQL, ['uid' => $this->userId]);
    // También limpiar production_orders, traspasos, conteos creados por E2E
}
```

**Preferir esta segunda alternativa** — más simple y más explícita.

---

## Fix 2 — Producción genera el ítem PROD-* correcto como output

**Archivo:** `database/seeders/E2E/TransactionalFlowSeeder.php` — método `seedProduccion()`
**Archivo:** `database/seeders/E2E/RestaurantDataArrays.php` — sección `recetas`

### Problema actual

```php
// BUG: usa el primer ingrediente como output
$firstInput = $ingredientes[0];
$outputItemId = $firstInput['item_id'];
```

### Solución

**a) Agregar campo `item_producido_codigo` a cada receta PROD_* en RestaurantDataArrays.php:**

```php
'recetas' => [
    [
        'codigo'               => 'REC-PROD-001',
        'nombre'               => 'Salsa Roja Base',
        'tipo'                 => 'PROD_SALSA',
        'item_producido_codigo' => 'PROD-001',  // ← AGREGAR este campo
        'porciones'            => 5.0,
        'uom_salida'           => 'KG',
        // ...
    ],
    // repetir para todas las recetas PROD_*
]
```

**b) En `seedProduccion()`, resolver el item producido desde el campo:**

```php
foreach ($recetasProd as $receta) {
    $itemProducidoCodigo = $receta['item_producido_codigo'] ?? null;
    if (! $itemProducidoCodigo) {
        $this->command?->warn("  ⚠ Receta {$receta['codigo']} sin item_producido_codigo — omitida.");
        continue;
    }

    // Resolver item_id del producible
    $outputItemId = DB::connection('pgsql')
        ->table('selemti.items')
        ->where('item_code', $itemProducidoCodigo)
        ->value('id');

    if (! $outputItemId) {
        $this->command?->warn("  ⚠ Item producido {$itemProducidoCodigo} no encontrado.");
        continue;
    }

    // Resolver recipe_id
    $recipeId = DB::connection('pgsql')
        ->table('selemti.recipes')
        ->where('codigo', $receta['codigo'])
        ->value('id');

    // Llamar ProductionService con el output correcto
    $orderId = $productionSvc->createOrder(
        header: [
            'recipe_id'    => $recipeId,
            'sucursal_id'  => $this->sucursalId,
            'almacen_id'   => $this->almGenId,
            'fecha_inicio' => now()->subDays(10),
            'user_id'      => $this->userId,
        ],
        inputs: $inputs,      // ingredientes de la receta
        outputs: [[
            'item_id'   => $outputItemId,
            'qty'       => $receta['porciones'],
            'uom'       => $receta['uom_salida'],
        ]],
        wastes: []
    );
}
```

**c) Verificar que después de `seedProduccion()` existan lotes en `inventory_batch`
para los ítems PROD-001 a PROD-009** (al menos 1 lote por producible).

---

## Fix 3 — userId dinámico

**Archivo:** `database/seeders/E2E/TransactionalFlowSeeder.php`

Reemplazar:
```php
private int $userId = 13;
```

Por resolución dinámica en `run()`:
```php
$this->userId = DB::connection('pgsql')
    ->table('selemti.users')
    ->where('activo', true)
    ->orderBy('id')
    ->value('id');

if (! $this->userId) {
    throw new \RuntimeException('No hay usuarios activos en selemti.users. Ejecutar UsersSeeder primero.');
}
```

---

## Fix 4 — Agregar APERTURA a cat_tipo_mov_inv

**Archivo:** nueva migración o agregar al seeder `CatTipoMovInvSeeder`

`cat_tipo_mov_inv` debe incluir el tipo `APERTURA` para que KardexService lo clasifique
correctamente con signo +1.

```php
// En CatTipoMovInvSeeder o en la migración phase0
DB::connection('pgsql')->table('selemti.cat_tipo_mov_inv')->updateOrInsert(
    ['clave' => 'APERTURA'],
    [
        'clave'        => 'APERTURA',
        'nombre'       => 'Carga inicial de inventario',
        'signo'        => 1,
        'afecta_costo' => true,
        'activo'       => true,
    ]
);
```

También verificar que los siguientes tipos estén registrados (todos deben existir):
`RECEPCION_COMPRA`, `PRODUCCION_ENTRADA`, `PRODUCCION_SALIDA`, `MERMA`,
`TRASPASO_ENTRADA`, `TRASPASO_SALIDA`, `AJUSTE_ENTRADA`, `AJUSTE_SALIDA`, `VENTA_POS`.

---

## Verificación post-fix

```bash
php artisan db:seed --class="Database\\Seeders\\E2E\\MasterDataSeeder"
php artisan db:seed --class="Database\\Seeders\\E2E\\TransactionalFlowSeeder"
# Segunda corrida — debe omitir todo o preguntar
php artisan db:seed --class="Database\\Seeders\\E2E\\TransactionalFlowSeeder"
```

```sql
-- Verificar que PROD-* tienen lotes generados por producción
SELECT i.item_code, SUM(b.cantidad_actual) as stock
FROM selemti.inventory_batch b
JOIN selemti.items i ON i.id = b.item_id
WHERE i.item_code LIKE 'PROD-%'
GROUP BY i.item_code;

-- Verificar tipos canónicos en cat_tipo_mov_inv
SELECT clave, signo FROM selemti.cat_tipo_mov_inv ORDER BY signo DESC, clave;

-- Movimientos por tipo
SELECT tipo, COUNT(*) FROM selemti.mov_inv GROUP BY tipo ORDER BY tipo;
```

**Criterio de éxito:**
- PROD-* items tienen stock > 0 en `inventory_batch`
- Segunda corrida del seeder no duplica movimientos
- `cat_tipo_mov_inv` incluye APERTURA con signo=1
- `php artisan test` pasa sin regresiones
