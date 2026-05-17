# Codex Task — E2E Ronda 2: Paso POS en TransactionalFlowSeeder

## Contexto

La corrida E2E actual (apertura → recepciones → producción → traspaso → conteo) no genera
movimientos `VENTA_POS`. El tipo de movimiento más importante del restaurante no se prueba.

Esta tarea agrega un paso final `seedPosConsumo()` al seeder que invoca
`PosConsumptionService::confirmTicket()` con tickets sintéticos basados en los platillos
del mapping POS, usando el stock generado por los pasos anteriores.

**IMPORTANTE — Invariantes críticas:**
- `public.*` es READ ONLY — FloreantPOS en producción
- `selemti.pos_ticket_item_processed` es la tabla de control de procesado — sí es escribible
- Los tickets sintéticos NO deben insertarse en `public.ticket` ni `public.orders`
- `PosConsumptionService` tiene métodos protegidos `ticketItemsForProcessing()` y
  `modifiersForTicketItem()` diseñados exactamente para inyectar datos sin leer `public.*`

---

## Arquitectura del paso POS

### Cómo funciona PosConsumptionService

El servicio fue diseñado con dos métodos protegidos que se pueden sobreescribir:

```php
protected function ticketItemsForProcessing(int $ticketId): Collection
{
    // Por defecto lee public.orders_item — NO usar en tests ni seeders
}

protected function modifiersForTicketItem(int $ticketItemId): Collection
{
    // Por defecto lee public.ticket_item_modifier
}
```

Para la corrida E2E, crear una subclase que inyecte datos sintéticos
exactamente igual que hace `PosConsumptionServiceTest`.

### Estructura de un ticket sintético

```php
// Ticket item (simula una fila de public.orders_item)
(object) [
    'id'         => 9001,       // ticket_item_id único
    'item_id'    => 2,          // menu_item_id (de pos_menu_item_recipe_mapping)
    'item_count' => 2,          // cantidad ordenada
]

// Modifier de ese ticket item (simula public.ticket_item_modifier)
(object) [
    'id'            => 1,
    'item_id'       => 555,     // menu_modifier_id (de pos_modifier_inv_mapping)
    'item_count'    => 1,
    'modifier_name' => 'Salsa Roja',
]
```

---

## Implementación requerida

### 1. Clase SyntheticPosConsumptionService (interna al seeder)

Agregar como clase privada al final del archivo del seeder, o como archivo separado en
`database/seeders/E2E/`:

```php
use App\Services\Inventory\PosConsumptionService;
use App\Services\Pos\PosModifierService;
use App\Services\Inventory\UomConversionService;
use Illuminate\Support\Collection;

class SyntheticPosConsumptionService extends PosConsumptionService
{
    public function __construct(
        PosModifierService $modifierService,
        UomConversionService $uomService,
        private readonly array $syntheticItems,
        private readonly array $syntheticModifiers,
    ) {
        parent::__construct($modifierService, $uomService);
    }

    protected function ticketItemsForProcessing(int $ticketId): Collection
    {
        return collect($this->syntheticItems[$ticketId] ?? []);
    }

    protected function modifiersForTicketItem(int $ticketItemId): Collection
    {
        return collect($this->syntheticModifiers[$ticketItemId] ?? []);
    }

    protected function dispatchIngestedEvent(int $ticketId): void
    {
        // No-op en corrida E2E — no hay listeners de eventos en seeds
    }
}
```

### 2. Método `seedPosConsumo()` en TransactionalFlowSeeder

```php
private function seedPosConsumo(
    PosModifierService $modifierSvc,
    UomConversionService $uomSvc,
): void {
    if ($this->alreadyRan('pos_consumo')) {
        $this->command?->info('  ➜ POS consumo: ya existe, omitiendo.');
        return;
    }

    // Leer el mapping POS que sembró MasterDataSeeder
    $menuMappings = DB::connection('pgsql')
        ->table('selemti.pos_menu_item_recipe_mapping')
        ->where('activo', true)
        ->get();

    if ($menuMappings->isEmpty()) {
        $this->command?->warn('  ⚠ No hay pos_menu_item_recipe_mapping — omitiendo POS.');
        return;
    }

    // Leer modifier mappings activos para construir modificadores sintéticos
    $modifierMappings = DB::connection('pgsql')
        ->table('selemti.pos_modifier_inv_mapping')
        ->where('activo', true)
        ->get()
        ->keyBy('menu_modifier_id');

    $totalMovimientos = 0;
    $ticketId = 90001; // ID base para tickets sintéticos E2E

    foreach ($menuMappings as $mapping) {
        $ticketItemId = $ticketId * 10 + 1;

        // Construir ticket item sintético: 2 órdenes de este platillo
        $syntheticItems = [
            $ticketId => [
                (object) [
                    'id'         => $ticketItemId,
                    'item_id'    => $mapping->menu_item_id,
                    'item_count' => 2,
                ],
            ],
        ];

        // Agregar UN modifier ADICIONAL si existe alguno en el mapping
        // (para probar el flujo completo, no solo la receta base)
        $syntheticModifiers = [];
        $firstModifier = $modifierMappings->first(fn($m) =>
            $m->tipo_efecto === 'ADICIONAL' && $m->item_id !== null
        );
        if ($firstModifier) {
            $syntheticModifiers[$ticketItemId] = [
                (object) [
                    'id'            => 1,
                    'item_id'       => $firstModifier->menu_modifier_id,
                    'item_count'    => 1,
                    'modifier_name' => $firstModifier->modifier_name_trim,
                ],
            ];
        }

        $svc = new SyntheticPosConsumptionService(
            $modifierSvc,
            $uomSvc,
            $syntheticItems,
            $syntheticModifiers,
        );

        $summary = $svc->confirmTicket($ticketId, userId: $this->userId);
        $totalMovimientos += $summary['recipe_movements'] + $summary['modifier_movements'];

        if (! empty($summary['warnings'])) {
            foreach ($summary['warnings'] as $w) {
                $this->command?->warn("  ⚠ Ticket {$ticketId}: {$w}");
            }
        }

        $ticketId++;
    }

    $this->command?->info("  ➜ POS consumo: {$menuMappings->count()} tickets → {$totalMovimientos} movimientos VENTA_POS.");
}
```

### 3. Registrar el paso en `run()`

```php
public function run(
    ReceptionService $receptionSvc,
    ProductionService $productionSvc,
    TransferService $transferSvc,
    InventoryCountService $countSvc,
    PosModifierService $modifierSvc,          // ← agregar
    UomConversionService $uomSvc,             // ← agregar
): void {
    // ...
    $this->seedPosConsumo($modifierSvc, $uomSvc);
}
```

---

## Escenarios sintéticos mínimos a cubrir

| Ticket | Platillo | Modifiers | Qué valida |
|--------|----------|-----------|------------|
| 90001 | menu_item_id=2 (Picada) | Sin modifier | Receta base descontada |
| 90002 | menu_item_id=8 (Chilaquiles) | 1 ADICIONAL (Extra proteína) | Receta base + modifier ADICIONAL |
| 90003 | menu_item_id=2 (Picada) | 1 SELECTOR (Salsa Roja) | SELECTOR define qué salsa descontar |

Si los menu_item_ids de producción no son 2, 8, etc., leerlos del mapping real en BD.

---

## Verificación post-implementación

```bash
php artisan db:seed --class="Database\\Seeders\\E2E\\MasterDataSeeder"
php artisan db:seed --class="Database\\Seeders\\E2E\\TransactionalFlowSeeder"
```

```sql
-- Debe existir el tipo VENTA_POS en mov_inv
SELECT tipo, COUNT(*) FROM selemti.mov_inv
WHERE tipo = 'VENTA_POS'
GROUP BY tipo;

-- Tickets marcados como procesados
SELECT COUNT(*) FROM selemti.pos_ticket_item_processed;

-- Stock no negativo tras consumo POS
SELECT COUNT(*) FROM selemti.inventory_batch WHERE cantidad_actual < 0;

-- Movimientos por tipo — deben aparecer los 9 tipos canónicos
SELECT tipo, COUNT(*) FROM selemti.mov_inv GROUP BY tipo ORDER BY tipo;
```

**Criterio de éxito:**
- Al menos 1 movimiento `VENTA_POS` en `mov_inv`
- `pos_ticket_item_processed` tiene filas para los tickets sintéticos
- 0 lotes con `cantidad_actual < 0`
- `php artisan test` pasa sin regresiones (los tests existentes de PosConsumptionServiceTest deben seguir pasando)
