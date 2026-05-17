# Codex Task: PosModifierService + actualizar PosConsumptionService

## Contexto del proyecto

TerrenaLaravel — Laravel 12, PostgreSQL 9.5, schema `selemti`.
`public.*` es FloreantPOS producción — READ ONLY (nunca INSERT/UPDATE/DELETE).
Todos los modelos de selemti usan `protected $connection = 'pgsql'`.

## Diseño de referencia

Ver `docs/e2e-corrida/modifier-inv-design.md` para el diseño completo.

## Tarea 1 — Modelos Eloquent nuevos

### `app/Models/Pos/PosMenuItemRecipeMapping.php`
```php
<?php
namespace App\Models\Pos;
use Illuminate\Database\Eloquent\Model;

class PosMenuItemRecipeMapping extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.pos_menu_item_recipe_mapping';
    protected $fillable = [
        'menu_item_id','menu_item_name','recipe_id','porciones_por_orden','activo'
    ];
    protected $casts = ['activo' => 'boolean', 'porciones_por_orden' => 'integer'];
}
```

### `app/Models/Pos/PosModifierInvMapping.php`
```php
<?php
namespace App\Models\Pos;
use Illuminate\Database\Eloquent\Model;

class PosModifierInvMapping extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.pos_modifier_inv_mapping';
    protected $fillable = [
        'menu_modifier_id','modifier_name_trim','menu_modifier_group_id',
        'menu_modifier_group_name','item_id','qty_por_unidad','uom',
        'qty_source','recipe_id','tipo_efecto','afecta_costo','activo'
    ];
    protected $casts = [
        'qty_por_unidad' => 'decimal:6',
        'afecta_costo' => 'boolean',
        'activo' => 'boolean',
    ];
}
```

## Tarea 2 — `app/Services/Pos/PosModifierService.php`

Servicio para lookup del mapping durante el procesamiento de tickets.

```php
<?php
namespace App\Services\Pos;

use App\Models\Pos\PosModifierInvMapping;
use App\Models\Pos\PosMenuItemRecipeMapping;
use Illuminate\Support\Facades\Cache;

class PosModifierService
{
    // Retorna el mapping para un modifier dado.
    // Primero busca por menu_modifier_id, luego por modifier_name_trim fallback.
    // Retorna null si no hay mapeo (no bloquea).
    public function findMapping(int $menuModifierId, string $modifierName): ?PosModifierInvMapping

    // Retorna el mapeo menu_item → recipe + porciones_por_orden
    public function findMenuItemMapping(int $menuItemId): ?PosMenuItemRecipeMapping

    // Carga todo el mapping en caché (calentamiento al inicio del turno)
    public function warmCache(): void

    // Invalida el caché (llamar después de editar mappings vía UI)
    public function clearCache(): void
}
```

**Implementación de `findMapping`:**
1. Buscar `PosModifierInvMapping::where('menu_modifier_id', $menuModifierId)->where('activo', true)->first()`
2. Si null → buscar `where('modifier_name_trim', trim($modifierName))->where('activo', true)->first()`
3. Si null → retornar null (sin efecto en inventario para este modifier)

## Tarea 3 — Actualizar `PosConsumptionService::confirmTicket`

**Archivo:** `app/Services/Inventory/PosConsumptionService.php`

El método debe seguir este flujo por cada `ticket_item`:

```php
public function confirmTicket(int $ticketId): array
{
    // 1. Leer ticket_items + ticket_item_modifiers desde public (READ ONLY)
    $ticketItems = DB::connection('pgsql')
        ->table('public.ticket_item')
        ->where('ticket_id', $ticketId)
        ->where('inventory_handled', false)
        ->get();

    foreach ($ticketItems as $ti) {
        // 2. Buscar mapeo menu_item → recipe
        $menuMapping = $this->modifierService->findMenuItemMapping($ti->item_id);
        
        if ($menuMapping && $menuMapping->recipe_id) {
            $porciones = $ti->item_count * $menuMapping->porciones_por_orden;
            
            // 3. Descontar ingredientes de receta base × porciones
            $this->deductRecipeIngredients(
                recipeId: $menuMapping->recipe_id,
                qty: $porciones,
                ticketItemId: $ti->id,
                ticketId: $ticketId,
                sucursalId: $sucursalId,
                almacenId: $almacenId,
                userId: $userId
            );
        }

        // 4. Procesar cada modifier del ticket_item
        $modifiers = DB::connection('pgsql')
            ->table('public.ticket_item_modifier')
            ->where('ticket_item_id', $ti->id)
            ->get();

        foreach ($modifiers as $mod) {
            // Buscar en ticket_item_modifier_relation para obtener menu_modifier_id
            $relation = DB::connection('pgsql')
                ->table('public.ticket_item_modifier_relation')
                ->where('ticket_item_id', $ti->id)
                ->where('list_order', $mod->id) // heurística — ajustar si relation tiene data
                ->first();

            $menuModifierId = $relation?->modifier_id ?? 0;
            $mapping = $this->modifierService->findMapping($menuModifierId, $mod->modifier_name);

            if (!$mapping || !$mapping->item_id || $mapping->qty_por_unidad == 0) {
                continue; // sin efecto en inventario
            }

            $qty = $this->resolveModifierQty($mapping, $mod->item_count);
            
            $this->deductInventoryItem(
                itemId: $mapping->item_id,
                qty: $qty,
                uom: $mapping->uom,
                ticketItemId: $ti->id,
                ticketId: $ticketId,
                sucursalId: $sucursalId,
                almacenId: $almacenId,
                userId: $userId
            );
        }

        // 5. Marcar ticket_item como procesado
        // NOTA: public schema es READ ONLY para escrituras de negocio.
        // Usar tabla selemti.pos_ticket_item_processed para tracking
        // en lugar de UPDATE public.ticket_item.inventory_handled
        $this->markProcessed($ti->id, $ticketId);
    }
}
```

### Método privado `deductRecipeIngredients`
- Cargar `recipe_version_items` de la versión activa (`valid_to IS NULL OR valid_to > NOW()`)
- Por cada `item_id` en la receta: llamar `deductInventoryItem`
- Para `sub_recipe_id` (sub-recetas): buscar el item producible de la sub-receta y descontarlo como ingrediente

### Método privado `resolveModifierQty`
```php
private function resolveModifierQty(PosModifierInvMapping $mapping, int $itemCount): float
{
    if ($mapping->qty_source === 'RECIPE' && $mapping->recipe_id) {
        // Tomar qty del output canónico de la receta de producción
        $recipeQty = DB::connection('pgsql')
            ->table('selemti.recipe_versions as rv')
            ->join('selemti.recipe_version_items as rvi', 'rvi.recipe_version_id', '=', 'rv.id')
            ->whereRaw('rv.recipe_id::text = ?', [(string) $mapping->recipe_id])
            ->whereNull('rv.valid_to')
            ->whereNotNull('rvi.item_id')
            ->sum('rvi.qty');
        return (float) $recipeQty * $itemCount;
    }
    return $mapping->qty_por_unidad * $itemCount;
}
```

### Método privado `deductInventoryItem`
- Buscar lote FEFO: `inventory_batch` donde `item_id=$itemId AND cantidad_actual > 0 ORDER BY caducidad ASC NULLS LAST, created_at ASC`
- Convertir qty a base UOM si es necesario via `UomConversionService`
- Decrementar `inventory_batch.cantidad_actual`
- Insertar `mov_inv` con `tipo = self::TIPO_VENTA_POS`

### Tabla de tracking (no tocar public)
Crear `selemti.pos_ticket_item_processed`:
```sql
CREATE TABLE IF NOT EXISTS selemti.pos_ticket_item_processed (
    ticket_item_id  INTEGER PRIMARY KEY,
    ticket_id       INTEGER NOT NULL,
    processed_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    user_id         INTEGER
);
```
Usar esta tabla para saber qué ticket_items ya fueron procesados (en lugar de `UPDATE public.ticket_item.inventory_handled`).

## Tarea 4 — Inyección de dependencias

En `PosConsumptionService.__construct`:
```php
public function __construct(
    private readonly PosModifierService $modifierService,
    private readonly UomConversionService $uomService,
) {}
```

## Tests mínimos requeridos

Crear `tests/Feature/Services/Pos/PosConsumptionServiceTest.php`:

1. `test_confirms_ticket_deducts_base_recipe_ingredients` — verifica que un ticket_item sin modifiers descuenta los ingredientes de la receta base
2. `test_confirms_ticket_deducts_modifier_items` — verifica que un modifier con mapping activo genera mov_inv
3. `test_confirms_ticket_skips_null_mapping` — modifier sin mapping no genera mov_inv ni excepción
4. `test_modifier_qty_source_recipe_derives_from_recipe` — qty_source=RECIPE toma la cantidad de la receta

## Archivos a crear/modificar

- **Crear:** `app/Models/Pos/PosMenuItemRecipeMapping.php`
- **Crear:** `app/Models/Pos/PosModifierInvMapping.php`
- **Crear:** `app/Services/Pos/PosModifierService.php`
- **Modificar:** `app/Services/Inventory/PosConsumptionService.php`
- **Crear:** tabla `selemti.pos_ticket_item_processed` (via migración inline o Gemini)
- **Crear:** `tests/Feature/Services/Pos/PosConsumptionServiceTest.php`

## Restricciones críticas

- **NUNCA** `INSERT/UPDATE/DELETE` en `public.*`
- Todos los modelos nuevos: `protected $connection = 'pgsql'`
- Si un modifier no tiene mapping → `continue` (no lanzar excepción, solo log)
- Si un menu_item no tiene recipe_mapping → log warning, no bloquear el ticket
- Todo el flujo de descuento dentro de `DB::transaction()`
